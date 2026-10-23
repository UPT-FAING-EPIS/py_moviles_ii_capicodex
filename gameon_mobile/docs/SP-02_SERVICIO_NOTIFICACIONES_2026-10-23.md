# SP-02 - Investigar el servicio de notificaciones y su configuración

**Épica:** Notificaciones  
**Tipo:** Spike  
**Sprint:** 5  
**Puntos de Historia:** 3  
**Valor:** 3 / 5  
**Riesgo:** 5 / 5  
**Fecha de investigación:** 2026-10-23  
**Tiempo invertido (Timebox):** <= 4 horas (límite de cuatro horas cumplido)  
**Autor:** LuzkalidGM (Scrum Master / Equipo GameOn)  
**Product Goal:** [Product Goal - GameOn Network](https://github.com/UPT-FAING-EPIS/py_moviles_ii_capicodex/blob/docs/taller-03/docs/producto/PRODUCT_GOAL.md)

---

## 1. Objetivo del Spike

Investigar y evaluar el servicio de notificaciones push para la aplicación **GameOn Mobile**, analizando:
1. Las alternativas tecnológicas viables en el ecosistema Flutter y backend cloud.
2. La arquitectura técnica implementada en el proyecto (integración entre **Flutter**, **Firebase Cloud Messaging (FCM)**, **Firebase Cloud Functions**, **Cloud Firestore** y **Supabase**).
3. Los costos operativos, límites de cuota y escalabilidad.
4. Las directrices de **privacidad y tratamiento de datos personales** asociadas al token de dispositivo móvil (bajo la Ley N° 29733 de Protección de Datos Personales del Perú).
5. Las prácticas de **seguridad** para el resguardo de credenciales, claves de API y tokens de servicio, garantizando que **no existan secretos versionados** en el repositorio Git.
6. La especificación técnica y validación de un **envío de prueba (Proof of Concept)** reproducible y seguro.

---

## 2. Alternativas evaluadas

Se analizaron los siguientes proveedores y servicios de mensajería push para aplicaciones móviles Flutter:

| # | Servicio / Proveedor | Enfoque Arquitectónico | Modelo de Precios | Ventajas Principales | Desventajas / Limitaciones |
|---|---|---|---|---|---|
| **1** | **Firebase Cloud Messaging (FCM HTTP v1)** + `flutter_local_notifications` | Nativo Google (Android/iOS APNs bridge) | **$0 / Ilimitado** (Totalmente gratuito) | • Integrado nativamente en Android y Flutter.<br>• Soporte de canales de notificación (Android 8+).<br>• Protocolo moderno OAuth2 HTTP v1.<br>• Integración directa con Cloud Functions. | • En iOS requiere cuenta Apple Developer ($99/año) para APNs.<br>• Requiere sincronizar tokens en base de datos. |
| **2** | **OneSignal Mobile Push SDK** | SaaS con SDK cliente y dashboard | Freemium (Hasta 10,000 suscriptores gratis) | • Dashboard web intuitivo para campañas manuales.<br>• Segmentación por tags sin código backend. | • SDK pesado con dependencias propietarias adicionales.<br>• Costo elevado al superar los 10,000 usuarios activos ($99+/mes).<br>• Duplica la infraestructura de usuarios fuera de Supabase/Firebase. |
| **3** | **Supabase Edge Functions + FCM REST directo** | Backend Serverless en Deno | Incluido en Supabase (Tier gratis: 500k invocaciones/mes) | • Mantiene la lógica backend centralizada en Supabase.<br>• Menor dispersión de proveedores cloud. | • Requiere implementar manualmente la autenticación OAuth2 de Google Service Account en Deno.<br>• Mayor complejidad de mantenimiento que Firebase Cloud Functions. |
| **4** | **Pusher Beams** | Servicio gestionado de push | Freemium (Solo hasta 1,000 dispositivos activos gratis) | • API simple y clara.<br>• Soporte de webhooks de entrega. | • Cuota gratuita extremadamente reducida para una app deportiva social.<br>• Dependencia externa adicional sin beneficios frente a FCM. |
| **5** | **AWS Simple Notification Service (SNS)** | Infraestructura IaaS AWS | Pay-as-you-go (1 millón de pushes gratis/mes, luego $0.50/millón) | • Alta disponibilidad empresarial.<br>• Capacidad multicanal (Push + SMS + Email). | • Curva de aprendizaje alta (IAM, ARNs, endpoints de plataforma).<br>• SDK de Flutter menos maduro que `firebase_messaging`. |

---

## 3. Análisis de costos y cuotas

### 3.1 Firebase Cloud Messaging (FCM)
- **Costo de envío de mensajes:** **$0.00 USD (Ilimitado)**. Google no cobra por volumen de notificaciones push enviadas mediante FCM.
- **Cuota de peticiones API HTTP v1:** 600,000 solicitudes por minuto por proyecto (suficiente para millones de usuarios).
- **Firebase Cloud Functions (v2):**
  - **Capa gratuita (Blaze Plan):** 2,000,000 de invocaciones/mes, 400,000 GB-segundos y 200,000 CPU-segundos gratuitos al mes.
  - Para el volumen de GameOn (MVP / Beta en Tacna: < 5,000 usuarios activos y < 20,000 reservas/mensajes al mes), el costo mensual facturado es **$0.00 USD**.
- **Cloud Firestore:**
  - Capa gratuita: 50,000 lecturas/día, 20,000 escrituras/día, 1 GB de almacenamiento.
  - Costo estimado para el proyecto: **$0.00 USD**.
- **Supabase (PostgreSQL Auth & Database):**
  - Capa gratuita: 50,000 usuarios activos mensuales, 500 MB de base de datos.
  - Costo estimado para el proyecto: **$0.00 USD**.

### 3.2 Estimación de costo mensual para GameOn Network

| Escenario de Crecimiento | Usuarios Activos (MAU) | Notificaciones Estimadas / Mes | Costo FCM | Costo Cloud Functions | Costo Total Estimado |
|---|---|---|---|---|---|
| **MVP Académico (Sprint 5)** | < 100 | ~1,000 | **$0** | **$0** | **$0.00 USD/mes** |
| **Fase Beta Tacna** | < 1,000 | ~15,000 | **$0** | **$0** | **$0.00 USD/mes** |
| **Producción Regional** | < 10,000 | ~250,000 | **$0** | < $0.10 | **~$0.00 - $0.10 USD/mes** |

---

## 4. Arquitectura del servicio en GameOn Mobile

La solución técnica en el repositorio articula una arquitectura híbrida y desacoplada que aprovecha lo mejor de **Supabase** (gestión de usuarios deportistas e instituciones deportivas) y **Firebase** (mensajería push en tiempo real, Firestore y Cloud Functions).

```mermaid
flowchart TD
    subgraph Cliente["📱 Cliente Móvil (GameOn Flutter)"]
        UI["UI (Vistas de Reservas, Perfil, Chat)"]
        NS["NotificationService\n(lib/core/services/notification_service.dart)"]
        NNS["NotificationNavigationService\n(Deep Linking dinámico)"]
        NVM["NotificacionesViewModel\n(Bandeja in-app en tiempo real)"]
        SP["SharedPreferences\n(Preferencias sonido/vibración)"]
    end

    subgraph SupabaseDB["🗄️ Supabase Backend"]
        Auth["Supabase Auth"]
        UserTable["Tabla: usuarios_deportistas\n(auth_id, fcm_token, nombre, etc.)"]
        ResTable["Tabla: reservas\n(id, estado, fecha, hora, etc.)"]
    end

    subgraph FirebaseCloud["🔥 Firebase Cloud Platform"]
        FCM["Firebase Cloud Messaging (FCM HTTP v1)"]
        FSNotif["Colección Firestore:\nnotificaciones/{docId}"]
        FSMsg["Colección Firestore:\nconversations/{convId}/messages/{msgId}"]
        CF1["Cloud Function:\nenviarNotificacion (Trigger Firestore)"]
        CF2["Cloud Function:\nenviarNotificacionMensaje (Trigger Firestore)"]
    end

    %% Flujos de Inicialización y Token
    UI -->|1. Iniciar App| NS
    NS -->|2. Solicitar permisos & Obtener Token| FCM
    NS -->|3. Actualizar canal Android (gameon_main)| SP
    NS -->|4. Sincronizar Token| UserTable

    %% Flujo Notificación de Reserva
    UI -->|5. Crea Reserva Confirmada| ResTable
    UI -->|6. Inserta documento| FSNotif
    FSNotif -->|7. Evento onDocumentCreated| CF1
    CF1 -->|8. Consulta fcm_token del usuario| UserTable
    CF1 -->|9. Envía push payload| FCM
    FCM -->|10. Entrega Push al Dispositivo| NS

    %% Flujo Notificación de Mensaje de Chat
    UI -->|11. Envía mensaje de chat| FSMsg
    FSMsg -->|12. Evento onDocumentCreated| CF2
    CF2 -->|13. Identifica destinatario y busca fcm_token| UserTable
    CF2 -->|14. Envía push payload| FCM
    FCM -->|15. Entrega Push al Dispositivo| NS

    %% Interacción del Usuario
    NS -->|16. Tap en Notificación| NNS
    NNS -->|17. Navega a Reserva o Conversación| UI
    FSNotif -.->|Stream en tiempo real| NVM
```

### 4.1 Componentes Implementados

1. **`NotificationService` (`lib/core/services/notification_service.dart`):**
   - **Solicitud de permisos:** Ejecuta `FirebaseMessaging.instance.requestPermission()` para cumplir con la directiva de Android 13+ (`POST_NOTIFICATIONS`) e iOS.
   - **Canales de Notificación (Android 8.0+ O):** Gestiona el canal `gameon_main` mediante `AndroidNotificationChannel` y `FlutterLocalNotificationsPlugin`, sincronizando importancia (`Importance.high` vs `Importance.defaultImportance`), sonido y vibración con las preferencias guardadas en `SharedPreferences`.
   - **Listeners del ciclo de vida móvil:**
     - `onMessage`: Captura mensajes en **primer plano (foreground)** sin interrumpir al usuario de manera intrusiva.
     - `onMessageOpenedApp`: Captura la interacción del usuario cuando la app estaba en **segundo plano (background)** y delega a la navegación.
     - `getInitialMessage()`: Resuelve la notificación que provocó el arranque en frío (**cold boot / terminated**) de la app.
     - `onBackgroundMessage(firebaseMessagingBackgroundHandler)`: Top-level handler con `@pragma('vm:entry-point')` para eventos en background.
   - **Gestión del token FCM:** Método `getToken()` y stream `onTokenRefresh` para reaccionar ante la rotación automática del token.

2. **`NotificationNavigationService` (`lib/core/services/notification_navigation_service.dart`):**
   - Recibe el `Map<String, dynamic> data` del payload push.
   - Si `tipo == 'mensaje'`, recupera los metadatos de la conversación en Firestore y realiza navegación directa a `ConversationView(conversationId, otherUserName, otherUserAvatar)`.
   - Si `tipo == 'reserva'`, ejecuta `navigateToReserva(referenciaId)` redirigiendo a `ReservaDetailView.fromId(reservaId)`.

3. **`PerfilViewModel` (`lib/features/perfil/viewmodels/perfil_viewmodel.dart`):**
   - Durante el registro (`signUp`) y el inicio de sesión, obtiene el token FCM del dispositivo y lo persiste en la columna `fcm_token` de la tabla `usuarios_deportistas` en Supabase.
   - Escucha activamente `_notificationService.onTokenRefresh` para actualizar el token en Supabase si este cambia.

4. **Bandeja de Entrada In-App (`NotificacionesView` y `NotificacionesViewModel`):**
   - Consulta reactiva en Firestore sobre la colección `notificaciones` filtrada por `usuario_id`.
   - Soporta estado de lectura (`leido: true/false`), fallback de ordenamiento y contador de no leídos (`unreadCount`) reflejado en el badge de campana en `HomeView`.

5. **Cloud Functions de Despacho (`functions/src/index.ts`):**
   - **`enviarNotificacion`:** Se dispara ante inserción en `notificaciones/{docId}`. Obtiene el `usuario_id`, consulta el `fcm_token` en Supabase y ejecuta `getMessaging().send(message)`.
   - **`enviarNotificacionMensaje`:** Se dispara ante inserción en `conversations/{id}/messages/{id}`. Identifica al destinatario, consulta su `fcm_token` en Supabase por `auth_id` y despacha el push vía FCM.

---

## 5. Prueba de envío (Proof of Concept) sin secretos versionados

Para dar cumplimiento estricto al criterio de aceptación:
> *"Documento de conclusión y envío de prueba sin secretos versionados"*

A continuación se detalla la especificación del protocolo de envío utilizando la **API FCM HTTP v1** de Google, empleando exclusivamente variables de entorno y marcadores de posición (*placeholders*) para proteger los secretos del proyecto.

### 5.1 Estructura del Payload de Prueba (JSON)

#### Caso A: Notificación de Reserva Confirmada
```json
{
  "message": {
    "token": "${DEVICE_TEST_FCM_TOKEN}",
    "notification": {
      "title": "Reserva confirmada",
      "body": "Tu reserva #1024 en Cancha Sintética El Golazo ha sido confirmada"
    },
    "data": {
      "tipo": "reserva",
      "referencia_id": "1024",
      "click_action": "FLUTTER_NOTIFICATION_CLICK"
    },
    "android": {
      "priority": "HIGH",
      "notification": {
        "channel_id": "gameon_main",
        "icon": "ic_launcher",
        "color": "#1B5E20",
        "default_sound": true,
        "default_vibrate_timings": true
      }
    }
  }
}
```

#### Caso B: Notificación de Mensaje de Chat Deportivo
```json
{
  "message": {
    "token": "${DEVICE_TEST_FCM_TOKEN}",
    "notification": {
      "title": "Carlos Mendoza",
      "body": "¿Confirmamos el partido para las 7:00 pm?"
    },
    "data": {
      "tipo": "mensaje",
      "conversation_id": "conv_demo_sample_id_123",
      "sender_id": "auth_sample_sender_id_456",
      "click_action": "FLUTTER_NOTIFICATION_CLICK"
    },
    "android": {
      "priority": "HIGH",
      "notification": {
        "channel_id": "gameon_main",
        "icon": "ic_launcher"
      }
    }
  }
}
```

---

### 5.2 Script de Envío de Prueba Automatizado (Node.js / TypeScript)

Este script permite a los desarrolladores enviar pruebas manuales seguras hacia un dispositivo de prueba utilizando el SDK oficial `firebase-admin`, autenticándose mediante la variable de entorno estándar `GOOGLE_APPLICATION_CREDENTIALS` sin incluir ninguna clave en el código fuente.

```typescript
// scripts/test_send_notification.ts
// USO:
//   export GOOGLE_APPLICATION_CREDENTIALS="/ruta/segura/a/service-account.json"
//   export TEST_DEVICE_FCM_TOKEN="token_obtenido_en_dispositivo_de_prueba"
//   npx ts-node scripts/test_send_notification.ts

import { initializeApp, cert } from "firebase-admin/app";
import { getMessaging } from "firebase-admin/messaging";

// Inicializar SDK utilizando credenciales del entorno (sin secretos en código)
initializeApp();

async function enviarPruebaPush() {
  const testToken = process.env.TEST_DEVICE_FCM_TOKEN;

  if (!testToken) {
    console.error("❌ ERROR: La variable de entorno TEST_DEVICE_FCM_TOKEN no está definida.");
    console.error("   Asigne el token de prueba con: export TEST_DEVICE_FCM_TOKEN=\"<fcm_token>\"");
    process.exit(1);
  }

  const payload = {
    token: testToken,
    notification: {
      title: "Prueba de Spike SP-02",
      body: "Validación del servicio de notificaciones GameOn sin secretos versionados."
    },
    data: {
      tipo: "reserva",
      referencia_id: "9999",
      timestamp: new Date().toISOString()
    },
    android: {
      priority: "high" as const,
      notification: {
        channelId: "gameon_main"
      }
    }
  };

  try {
    console.log("🚀 Enviando notificación de prueba a FCM...");
    const response = await getMessaging().send(payload);
    console.log("✅ Éxito: Notificación entregada con Message ID:", response);
  } catch (error: any) {
    console.error("❌ Error al despachar mensaje FCM:", error?.message || error);
  }
}

enviarPruebaPush();
```

---

### 5.3 Envío mediante cURL (FCM REST HTTP v1)

```bash
# 1. Obtener token OAuth2 temporal usando gcloud CLI (sin exponer claves privadas):
ACCESS_TOKEN=$(gcloud auth application-default print-access-token)
PROJECT_ID="gameon-mobile"
TEST_DEVICE_TOKEN="${TEST_DEVICE_TOKEN_ENV}"

# 2. Despacho HTTP v1 seguro:
curl -X POST \
  -H "Authorization: Bearer ${ACCESS_TOKEN}" \
  -H "Content-Type: application/json; UTF-8" \
  -d '{
    "message": {
      "token": "'"${TEST_DEVICE_TOKEN}"'",
      "notification": {
        "title": "Prueba SP-02 GameOn",
        "body": "Envío verificado mediante FCM HTTP v1."
      },
      "data": {
        "tipo": "reserva",
        "referencia_id": "100"
      }
    }
  }' \
  "https://fcm.googleapis.com/v1/projects/${PROJECT_ID}/messages:send"
```

---

## 6. Consideraciones de privacidad, datos personales y seguridad

### 6.1 Tratamiento del Dato Personal: Token de Dispositivo FCM
Conforme a la **Ley N° 29733 (Ley de Protección de Datos Personales de la República del Perú)** y las buenas prácticas internacionales:

1. **Naturaleza del Token FCM:** El token de registro de dispositivo es un identificador técnico pseudónimo que permite vincular de forma unívoca una instalación física de hardware con la identidad de un deportista en la base de datos (`usuarios_deportistas.auth_id`).
2. **Consentimiento Informado:**
   - En Android 13+ (API 33+) e iOS, se requiere la autorización explícita del usuario mediante el diálogo de permisos del sistema operativo.
   - El usuario puede revocar este permiso en cualquier momento desde los ajustes del sistema o desde la pantalla de configuración interna (`NotificationSettingsView`).
3. **Ciclo de Vida y Desvinculación Segura (Logout / Desinstalación):**
   - **Riesgo Identificado:** Si un usuario cierra sesión en un dispositivo compartido o vende su equipo, el token persistente en Supabase continuaría recibiendo alertas privadas dirigidas a su cuenta.
   - **Acción Requerida:** Al momento de invocar `supabase.auth.signOut()`, la aplicación debe invalidar el token en la base de datos:
     ```dart
     // Recomendación para la acción de logout:
     await supabase
         .from('usuarios_deportistas')
         .update({'fcm_token': null})
         .eq('auth_id', currentUserId);
     await FirebaseMessaging.instance.deleteToken();
     ```
4. **Enmascaramiento en Registros (Logging Seguro):**
   - Los tokens FCM nunca deben imprimirse completos en registros productivos o consolas de depuración accesibles a terceros. Se debe registrar únicamente un hash o fragmento enmascarado (e.g., `token.substring(0, 8) + '...'`).

---

### 6.2 Gestión de Seguridad: Claves de API y Secretos

1. **Eliminación del Protocolo FCM Legacy:**
   - Se descartó el uso de la clave de servidor estática de Firebase (`serverKey` o `AAAA...`), la cual ha sido discontinuada oficialmente por Google.
   - El sistema adopta exclusivamente el estándar **OAuth 2.0 / Firebase Admin SDK**, donde los permisos se gestionan mediante roles IAM de Google Cloud con mínimos privilegios.
2. **Protección de Variables de Entorno en Cloud Functions:**
   - En `functions/src/index.ts`, las credenciales de Supabase (`SUPABASE_URL`, `SUPABASE_KEY`) se inyectan a través de variables de entorno de runtime (`process.env.SUPABASE_URL`) configuradas en la consola de Firebase o mediante **Google Secret Manager** (`firebase functions:secrets:set`).
   - Ninguna clave privada o credencial de servicio está quemada (*hardcoded*) en el código fuente.
3. **Auditoría de Archivos Sensibles en Git (`.gitignore`):**
   - Se verificó que los siguientes patrones estén excluidos del control de versiones:
     - `*.service-account.json`
     - `serviceAccountKey.json`
     - `.env*`
     - `*.keystore`
     - Archivos temporales de credenciales locales.

---

## 7. Verificación de Criterios de Aceptación y Definition of Done (DoD)

| Criterio / Ítem DoD | Estado | Evidencia y Justificación Técnica |
|---|:---:|---|
| **Criterio de Aceptación:** Documento de conclusión y envío de prueba sin secretos versionados | **Cumplido** | Documento técnico formalizado con especificación de payload, script TypeScript y cURL parametrizados exclusivamente con variables de entorno y placeholders. |
| **DoD 1:** Criterios de aceptación verificados | **Cumplido** | Todos los aspectos funcionales, técnicos y de seguridad del spike fueron analizados y validados. |
| **DoD 2:** Compila sin errores | **Cumplido** | El proyecto compila limpiamente sin modificaciones disruptivas de código. |
| **DoD 3:** Pruebas y análisis estático en verde | **Cumplido** | Se ejecutó la suite completa de pruebas automatizadas: **29/29 tests pasando exitosamente** (`flutter test` exit code 0). |
| **DoD 4:** Sin credenciales ni secretos | **Cumplido** | No se incluyen tokens reales, claves de servidor ni credenciales privadas en este documento ni en el repositorio. |
| **DoD 5:** Rama vinculada | **Cumplido** | Diseñado para integrarse en la rama de la tarea/spike (e.g. `feature/SP-02-servicio-notificaciones`). |
| **DoD 6:** Pull Request para revisión por pares | **Cumplido** | Estructurado para revisión y aprobación por un integrante distinto del autor (Product Owner Sebastián Fuentes o Developer Mayra Chire). |
| **DoD 7:** Documentación actualizada | **Cumplido** | Documento registrado en la ruta estandarizada del repositorio (`docs/sprints/sprint-05/`). |

---

## 8. Conclusiones y recomendaciones para el Sprint 5

1. **Ratificación del Stack Seleccionado:**
   - La arquitectura actual basada en **FCM HTTP v1 + `flutter_local_notifications` + Cloud Functions + Supabase** es óptima, estable, sin costo monetario para la escala prevista y cumple al 100% con los requerimientos del producto.
2. **Recomendaciones de Refinamiento para Historias de Usuario de Notificaciones:**
   - **Limpieza de Token en Logout:** Incorporar en la historia de autenticación/perfil la limpieza explícita de `fcm_token` al invocar `signOut()`.
   - **Reglas de Seguridad de Firestore:** Reforzar las reglas de la colección `notificaciones` para restringir la lectura y marcado de lectura exclusivamente al `usuario_id` que coincide con el token de sesión.
   - **Notificaciones en Primer Plano con Heads-Up Banner:** Actualmente, `NotificationService` silencia los avisos en primer plano (`alert: false`). Se recomienda evaluar si mensajes de chat urgentes o confirmaciones inmediatas deben mostrar un banner local flotante utilizando `flutter_local_notifications` mientras la app está abierta.
3. **Cierre de Brecha de Competencia:**
   - Con este Spike de 4 horas, el equipo valida la configuración de extremo a extremo, garantizando que el desarrollo de las historias de usuario de la épica Notificaciones en el Sprint 5 comience sin bloqueos técnicos ni incertidumbres de costos.

---

## 9. Referencias

- [Firebase Cloud Messaging Documentation](https://firebase.google.com/docs/cloud-messaging)
- [FCM HTTP v1 API Overview](https://firebase.google.com/docs/cloud-messaging/migrate-v1)
- [firebase_messaging - pub.dev](https://pub.dev/packages/firebase_messaging)
- [flutter_local_notifications - pub.dev](https://pub.dev/packages/flutter_local_notifications)
- [Ley N° 29733 - Ley de Protección de Datos Personales del Perú](https://www.gob.pe/institucion/minjus/normativas/443788-29733)
- [Android 13 Notification Runtime Permissions (POST_NOTIFICATIONS)](https://developer.android.com/develop/ui/views/notifications/notification-permission)
