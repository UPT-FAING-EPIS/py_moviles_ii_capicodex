# Envío de notificaciones FCM

La Edge Function recibe un webhook al crear una fila en `notificaciones`, busca
el token del destinatario en `usuarios_deportistas` y envía el aviso mediante
Firebase Cloud Messaging HTTP v1.

## Secretos requeridos

- `FIREBASE_SERVICE_ACCOUNT_JSON`: JSON completo de la cuenta de servicio.
- `PUSH_WEBHOOK_SECRET`: cadena aleatoria para validar el webhook.

## Webhook de base de datos

Crear un Database Webhook sobre `public.notificaciones` con evento `INSERT`.
Usar la URL desplegada de `send-fcm-notification` y el header
`x-gameon-webhook-secret` con el valor de `PUSH_WEBHOOK_SECRET`.
