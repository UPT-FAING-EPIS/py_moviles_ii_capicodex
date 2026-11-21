import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { GoogleAuth } from "npm:google-auth-library@9.15.1";

type WebhookPayload = {
  record?: Record<string, unknown>;
  usuario_id?: number | string;
  destinatario_auth_id?: string;
  titulo?: string;
  mensaje?: string;
  tipo?: string;
  referencia_id?: number | string;
};

const jsonHeaders = { "Content-Type": "application/json" };

Deno.serve(async (request) => {
  if (request.method !== "POST") {
    return new Response(JSON.stringify({ error: "Método no permitido" }), { status: 405, headers: jsonHeaders });
  }

  const expectedSecret = Deno.env.get("PUSH_WEBHOOK_SECRET");
  if (!expectedSecret || request.headers.get("x-gameon-webhook-secret") !== expectedSecret) {
    return new Response(JSON.stringify({ error: "No autorizado" }), { status: 401, headers: jsonHeaders });
  }

  const payload = await request.json() as WebhookPayload;
  const notification = payload.record ?? payload;
  const userId = Number(notification.usuario_id);
  const recipientAuthId = String(notification.destinatario_auth_id ?? "");
  if ((!Number.isInteger(userId) || userId <= 0) && !recipientAuthId) {
    return new Response(JSON.stringify({ error: "Destinatario inválido" }), { status: 400, headers: jsonHeaders });
  }

  const supabaseUrl = Deno.env.get("SUPABASE_URL");
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  const serviceAccountRaw = Deno.env.get("FIREBASE_SERVICE_ACCOUNT_JSON");
  if (!supabaseUrl || !serviceRoleKey || !serviceAccountRaw) {
    console.error("Faltan secretos requeridos para enviar FCM.");
    return new Response(JSON.stringify({ error: "Configuración incompleta" }), { status: 500, headers: jsonHeaders });
  }

  const supabase = createClient(supabaseUrl, serviceRoleKey);
  const athleteQuery = recipientAuthId
    ? supabase.from("usuarios_deportistas").select("fcm_token").eq("auth_id", recipientAuthId).maybeSingle()
    : supabase.from("usuarios_deportistas").select("fcm_token").eq("id", userId).maybeSingle();
  const { data: athlete, error: athleteError } = await athleteQuery;
  if (athleteError) {
    console.error("No se pudo consultar el token de deportista:", athleteError);
    return new Response(JSON.stringify({ error: "No se pudo consultar el destinatario" }), { status: 500, headers: jsonHeaders });
  }
  const { data: manager, error: managerError } = recipientAuthId
    ? await supabase.from("usuarios_instalaciones").select("fcm_token").eq("auth_id", recipientAuthId).maybeSingle()
    : { data: null, error: null };
  if (managerError) {
    console.error("No se pudo consultar el token de gestor:", managerError);
    return new Response(JSON.stringify({ error: "No se pudo consultar el destinatario" }), { status: 500, headers: jsonHeaders });
  }
  const token = athlete?.fcm_token ?? manager?.fcm_token;
  if (!token) {
    return new Response(JSON.stringify({ sent: false, reason: "Sin token FCM" }), { status: 200, headers: jsonHeaders });
  }

  let serviceAccount: { project_id: string };
  try {
    serviceAccount = JSON.parse(serviceAccountRaw);
  } catch {
    return new Response(JSON.stringify({ error: "Credencial Firebase inválida" }), { status: 500, headers: jsonHeaders });
  }

  const auth = new GoogleAuth({
    credentials: JSON.parse(serviceAccountRaw),
    scopes: ["https://www.googleapis.com/auth/firebase.messaging"],
  });
  const accessToken = await auth.getAccessToken();
  const fcmResponse = await fetch(
    `https://fcm.googleapis.com/v1/projects/${serviceAccount.project_id}/messages:send`,
    {
      method: "POST",
      headers: { "Authorization": `Bearer ${accessToken}`, "Content-Type": "application/json" },
      body: JSON.stringify({
        message: {
          token,
          notification: {
            title: String(notification.titulo ?? "Nueva notificación"),
            body: String(notification.mensaje ?? ""),
          },
          data: {
            tipo: String(notification.tipo ?? "general"),
            referencia_id: String(notification.referencia_id ?? ""),
          },
          android: { priority: "high" },
        },
      }),
    },
  );

  if (!fcmResponse.ok) {
    const errorText = await fcmResponse.text();
    console.error("FCM rechazó el envío:", errorText);
    if (errorText.includes("UNREGISTERED") || errorText.includes("INVALID_ARGUMENT")) {
      if (recipientAuthId) {
        await Promise.all([
          supabase.from("usuarios_deportistas").update({ fcm_token: null }).eq("auth_id", recipientAuthId),
          supabase.from("usuarios_instalaciones").update({ fcm_token: null }).eq("auth_id", recipientAuthId),
        ]);
      } else {
        await supabase.from("usuarios_deportistas").update({ fcm_token: null }).eq("id", userId);
      }
    }
    return new Response(JSON.stringify({ error: "Firebase rechazó el envío" }), { status: 502, headers: jsonHeaders });
  }

  return new Response(JSON.stringify({ sent: true, result: await fcmResponse.json() }), { status: 200, headers: jsonHeaders });
});
