import {onDocumentCreated} from "firebase-functions/v2/firestore";
import {onSchedule} from "firebase-functions/v2/scheduler";
import {initializeApp} from "firebase-admin/app";
import {getMessaging} from "firebase-admin/messaging";
import {getFirestore, Timestamp} from "firebase-admin/firestore";
import {createClient} from "@supabase/supabase-js";

// 🔹 Inicializar Firebase Admin
initializeApp();

// 🔔 Cloud Function que se activa al crear un documento en "notificaciones"
export const enviarNotificacion = onDocumentCreated(
  "notificaciones/{docId}",
  async (event) => {
    const notificacion = event.data?.data();

    if (!notificacion) {
      console.log("⚠️ Documento vacío o inválido.");
      return;
    }

    console.log("🆕 Nueva notificación detectada:", notificacion);

    const usuarioIdRaw = notificacion.usuario_id;
    const usuarioId = typeof usuarioIdRaw === "string" ?
      parseInt(usuarioIdRaw, 10) :
      usuarioIdRaw;

    if (!usuarioId || Number.isNaN(usuarioId)) {
      console.error("❌ La notificación no tiene usuario_id válido.");
      return;
    }

    // 🔹 Inicializar cliente de Supabase en tiempo de ejecución
    const supabaseUrl: string = process.env.SUPABASE_URL || "";
    const supabaseKey: string = process.env.SUPABASE_KEY || "";
    if (!supabaseUrl || !supabaseKey) {
      console.error("❌ SUPABASE_URL o SUPABASE_KEY no están definidos.");
      return;
    }
    const supabase = createClient(supabaseUrl, supabaseKey);

    // 🔍 Obtener el token FCM desde Supabase
    const {data: usuario, error} = await supabase
      .from("usuarios_deportistas")
      .select("fcm_token")
      .eq("id", usuarioId)
      .single();

    if (error) {
      console.error("❌ Error al obtener el usuario desde Supabase:", error);
      return;
    }

    if (!usuario?.fcm_token) {
      console.warn("⚠️ El usuario no tiene token FCM registrado.");
      return;
    }

    // 🚀 Enviar la notificación con Firebase Cloud Messaging
    const message = {
      token: usuario.fcm_token,
      notification: {
        title: String(notificacion.titulo ?? "Nueva notificación"),
        body: String(notificacion.mensaje ?? ""),
      },
      data: {
        tipo: String(notificacion.tipo ?? "general"),
        referencia_id: String(notificacion.referencia_id ?? ""),
      },
    };

    try {
      const response = await getMessaging().send(message);
      console.log("✅ Notificación enviada correctamente:", response);
    } catch (err) {
      console.error("❌ Error al enviar la notificación:", err);
    }
  }
);

// 🔔 Cloud Function que envía notificación cuando un cliente recibe un mensaje
export const enviarNotificacionMensaje = onDocumentCreated(
  "conversations/{conversationId}/messages/{messageId}",
  async (event) => {
    const mensaje = event.data?.data();
    const conversationId = event.params.conversationId;

    if (!mensaje) {
      console.log("⚠️ Mensaje vacío o inválido.");
      return;
    }

    console.log("📨 Nuevo mensaje detectado:", mensaje);

    const senderId = mensaje.sender_id as string;
    const senderNombre = mensaje.sender_nombre as string;
    const content = mensaje.content as string;

    // 🔹 Obtener la conversación para identificar al destinatario
    const db = getFirestore();
    const conversationDoc = await db
      .collection("conversations")
      .doc(conversationId)
      .get();

    if (!conversationDoc.exists) {
      console.error("❌ Conversación no encontrada.");
      return;
    }

    const conversationData = conversationDoc.data();
    const participantIds = conversationData?.participant_ids as string[] || [];

    // 🔹 Identificar al destinatario (el que NO es el remitente)
    const recipientId = participantIds.find((id) => id !== senderId);

    if (!recipientId || recipientId === "bot_assistant") {
      console.log("⚠️ No hay destinatario válido o es el bot.");
      return;
    }

    console.log(`🔍 Buscando usuario con auth_id: ${recipientId}`);

    // 🔹 Inicializar cliente de Supabase
    const supabaseUrl: string = process.env.SUPABASE_URL || "";
    const supabaseKey: string = process.env.SUPABASE_KEY || "";
    if (supabaseUrl == "" || supabaseKey == "") {
      console.error("❌ SUPABASE_URL o SUPABASE_KEY no están definidos.");
      return;
    }
    const supabase = createClient(supabaseUrl, supabaseKey);

    // 🔍 Obtener el token FCM del destinatario desde Supabase
    const {data: usuario, error} = await supabase
      .from("usuarios_deportistas")
      .select("fcm_token, id, nombre, auth_id")
      .eq("auth_id", recipientId)
      .single();

    if (error) {
      console.error("❌ Error al obtener el usuario desde Supabase:", error);
      console.error(`❌ Buscando auth_id: ${recipientId}`);
      return;
    }

    if (!usuario?.fcm_token) {
      console.warn("⚠️ El destinatario no tiene token FCM registrado.");
      return;
    }

    // 🚀 Enviar la notificación push
    const message = {
      token: usuario.fcm_token,
      notification: {
        title: senderNombre,
        body: content,
      },
      data: {
        tipo: "mensaje",
        conversation_id: conversationId,
        sender_id: senderId,
      },
    };

    try {
      const response = await getMessaging().send(message);
      console.log("✅ Notificación de mensaje enviada correctamente:", response);
    } catch (err) {
      console.error("❌ Error al enviar la notificación:", err);
    }
  }
);

export const sanearPresencia = onSchedule(
  {schedule: "every 1 minutes"},
  async () => {
    const db = getFirestore();
    const envThreshold = process.env.PRESENCE_THRESHOLD_MS || "90000";
    const thresholdMs = Number(envThreshold);
    const cutoff = Timestamp.fromMillis(Date.now() - thresholdMs);
    const snapshot = await db
      .collection("users")
      .where("last_seen", "<", cutoff)
      .get();
    if (snapshot.empty) return;
    const batch = db.batch();
    for (const doc of snapshot.docs) {
      const data = doc.data() as {is_online?: boolean};
      if (data.is_online === true) {
        batch.update(doc.ref, {is_online: false});
      }
    }
    await batch.commit();
  }
);
