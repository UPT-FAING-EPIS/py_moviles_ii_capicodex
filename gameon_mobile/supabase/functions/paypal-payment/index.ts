import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const headers = { "Content-Type": "application/json" };
const reply = (value: unknown, status = 200) => new Response(JSON.stringify(value), { status, headers });
const url = Deno.env.get("SUPABASE_URL")!;
const publicKey = Deno.env.get("SUPABASE_ANON_KEY")!;
const adminKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const api = "https://api-m.paypal.com";

async function paypalToken(clientId: string, secret: string): Promise<string> {
  const result = await fetch(`${api}/v1/oauth2/token`, {
    method: "POST",
    headers: {
      Authorization: `Basic ${btoa(`${clientId}:${secret}`)}`,
      "Content-Type": "application/x-www-form-urlencoded",
    },
    body: "grant_type=client_credentials",
  });
  const data = await result.json();
  if (!result.ok || !data.access_token) throw new Error("Las credenciales Live del gestor no pudieron autenticarse en PayPal.");
  return data.access_token as string;
}

async function paypalRequest(path: string, token: string, method = "GET", body?: object, requestId?: string) {
  const response = await fetch(`${api}${path}`, {
    method,
    headers: {
      Authorization: `Bearer ${token}`,
      "Content-Type": "application/json",
      Prefer: "return=representation",
      ...(requestId ? { "PayPal-Request-Id": requestId } : {}),
    },
    ...(body ? { body: JSON.stringify(body) } : {}),
  });
  const data = await response.json();
  if (!response.ok) {
    console.error("PayPal API error:", response.status, data?.name, data?.details);
    throw new Error(data?.message ?? "PayPal rechazó la operación.");
  }
  return data;
}

Deno.serve(async (request) => {
  if (request.method !== "POST") return reply({ error: "Método no permitido" }, 405);
  if (!url || !publicKey || !adminKey) return reply({ error: "Servidor sin configurar" }, 503);
  const authorization = request.headers.get("Authorization") ?? "";
  if (!authorization.startsWith("Bearer ")) return reply({ error: "Inicia sesión" }, 401);
  const userDb = createClient(url, publicKey, { global: { headers: { Authorization: authorization } } });
  const admin = createClient(url, adminKey);
  const { data: userData, error: authError } = await userDb.auth.getUser(authorization.slice(7));
  if (authError || !userData.user) return reply({ error: "Sesión inválida" }, 401);
  let reservationId: number | undefined;
  try {
    const body = await request.json();
    if (body.action === "create") {
      const { data: area, error: areaError } = await admin.from("areas_deportivas")
        .select("tarifa_por_hora").eq("id", body.areaId).single();
      if (areaError || !area) throw new Error("Cancha no disponible.");
      const start = String(body.inicio).split(":").map(Number);
      const end = String(body.fin).split(":").map(Number);
      const minutes = (end[0] * 60 + end[1]) - (start[0] * 60 + start[1]);
      if (!Number.isInteger(minutes) || minutes <= 0 || minutes % 30 !== 0 || minutes > 720)
        throw new Error("Horario inválido.");
      const rateResponse = await fetch("https://api.frankfurter.dev/v2/rate/USD/PEN");
      if (!rateResponse.ok) throw new Error("No se pudo consultar el tipo de cambio. Intenta más tarde.");
      const quote = await rateResponse.json();
      const penPerUsd = Number(quote.rate);
      const quoteDate = Date.parse(String(quote.date));
      if (!Number.isFinite(penPerUsd) || penPerUsd <= 0 ||
          !Number.isFinite(quoteDate) || Date.now() - quoteDate > 7 * 86400000)
        throw new Error("Tipo de cambio actualizado no disponible.");
      const { data: intent, error } = await admin.rpc("paypal_iniciar_reserva", {
        p_comprador_auth_id: userData.user.id,
        p_area_id: body.areaId, p_fecha: body.fecha,
        p_inicio: body.inicio, p_fin: body.fin,
        p_tipo_cambio_pen: penPerUsd,
      });
      if (error) throw new Error(error.message);
      reservationId = intent.reserva_id;
      const { data: credentials, error: credentialsError } = await admin.rpc("paypal_credenciales_servidor", {
        p_gestor_id: intent.gestor_id,
      });
      if (credentialsError || !credentials?.client_id || !credentials?.secret) throw new Error("El gestor no ha configurado PayPal Live.");
      const token = await paypalToken(credentials.client_id, credentials.secret);
      const amount = Number(intent.monto_usd).toFixed(2);
      const order = await paypalRequest("/v2/checkout/orders", token, "POST", {
        intent: "CAPTURE",
        purchase_units: [{
          reference_id: String(reservationId),
          custom_id: String(reservationId),
          description: `Reserva GameOn #${reservationId}`,
          amount: { currency_code: "USD", value: amount },
        }],
        payment_source: { paypal: { experience_context: {
          return_url: `${url}/functions/v1/paypal-payment/return?result=success`,
          cancel_url: `${url}/functions/v1/paypal-payment/return?result=cancel`,
          user_action: "PAY_NOW",
        } } },
      }, `gameon-create-${reservationId}`);
      const approval = order.links?.find((link: { rel: string }) => link.rel === "payer-action" || link.rel === "approve")?.href;
      if (!order.id || !approval) throw new Error("PayPal no devolvió el enlace para aprobar la orden.");
      const { error: attachError } = await admin.rpc("paypal_asociar_orden", { p_reserva: reservationId, p_order: order.id });
      if (attachError) throw new Error(attachError.message);
      return reply({ orderId: order.id, approvalUrl: approval, amountUsd: amount, reservationId, exchangeRate: penPerUsd });
    }
    if (body.action === "capture" || body.action === "cancel" || body.action === "recover") {
      const query = admin.from("paypal_intentos_reserva")
        .select("reserva_id,comprador_auth_id,gestor_id,monto_usd,order_id,estado,capture_id");
      const { data: intent, error } = await (body.action === "recover"
        ? query.eq("reserva_id", body.reservationId)
        : query.eq("order_id", body.orderId)).maybeSingle();
      if (error || !intent || intent.comprador_auth_id !== userData.user.id) return reply({ error: "Orden no autorizada" }, 403);
      if (intent.estado === "completado") return reply({ success: true, reservationId: intent.reserva_id });
      if (intent.estado !== "pendiente") return reply({ error: "Orden sin pago pendiente" }, 409);
      const { data: credentials, error: credentialsError } = await admin.rpc("paypal_credenciales_servidor", { p_gestor_id: intent.gestor_id });
      if (credentialsError || !credentials) throw new Error("No se pudo verificar la cuenta del gestor.");
      const token = await paypalToken(credentials.client_id, credentials.secret);
      let order = await paypalRequest(`/v2/checkout/orders/${encodeURIComponent(intent.order_id)}`, token);
      if (body.action === "cancel") {
        if (order.status === "CREATED" || order.status === "PAYER_ACTION_REQUIRED" || order.status === "SAVED") {
          await admin.rpc("paypal_cancelar_servidor", { p_reserva: intent.reserva_id, p_order: intent.order_id });
          return reply({ cancelled: true });
        }
        return reply({ cancelled: false, status: order.status });
      }
      if (order.status === "APPROVED") {
        order = await paypalRequest(`/v2/checkout/orders/${encodeURIComponent(intent.order_id)}/capture`, token, "POST", {}, `gameon-capture-${intent.reserva_id}`);
      }
      const purchase = order.purchase_units?.[0];
      const capture = purchase?.payments?.captures?.[0];
      if (order.status !== "COMPLETED" || capture?.status !== "COMPLETED" ||
          purchase?.custom_id !== String(intent.reserva_id) ||
          capture.amount?.currency_code !== "USD" ||
          Number(capture.amount?.value).toFixed(2) !== Number(intent.monto_usd).toFixed(2)) {
        return reply({ error: "PayPal aún no confirma el pago completo. Reintenta la verificación." }, 409);
      }
      const { data: saved, error: saveError } = await admin.rpc("paypal_confirmar_servidor", {
        p_reserva: intent.reserva_id, p_order: intent.order_id,
        p_capture: capture.id, p_monto_usd: intent.monto_usd,
      });
      if (saveError) throw new Error(saveError.message);
      return reply({ success: true, reservationId: saved, captureId: capture.id });
    }
    return reply({ error: "Operación desconocida" }, 400);
  } catch (error) {
    if (reservationId) {
      await admin.rpc("paypal_fallar_reserva", { p_reserva: reservationId });
    }
    console.error("PayPal checkout:", error instanceof Error ? error.message : error);
    return reply({ error: error instanceof Error ? error.message : "Error de pago" }, 400);
  }
});
