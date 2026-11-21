# Notificaciones push: despliegue y prueba

La app usa Firebase Cloud Messaging (FCM). Las notificaciones de reservas se
crean en Firestore en la colección `notificaciones`; las de chat se originan
cuando se crea un mensaje en `conversations/{conversationId}/messages`.

## Requisitos de servidor

Inicia sesión con una cuenta que tenga permisos de Firebase sobre el proyecto
`gameon-mobile` y configura estos secretos. La segunda clave debe ser la
`service_role` de Supabase, nunca la clave anónima incluida en la aplicación.

```powershell
firebase login --reauth
firebase functions:secrets:set SUPABASE_URL --project gameon-mobile
firebase functions:secrets:set SUPABASE_SERVICE_ROLE_KEY --project gameon-mobile
firebase deploy --only functions --project gameon-mobile
```

Después del despliegue, verifica que se publiquen `enviarNotificacion`,
`enviarNotificacionMensaje` y `sanearPresencia`.

## Prueba en Android físico

1. Instala una compilación nueva en dos teléfonos Android físicos e inicia
   sesión con dos cuentas distintas.
2. Acepta el permiso de notificaciones en ambos teléfonos.
3. Comprueba en Supabase que `usuarios_deportistas.fcm_token` tenga un token
   para ambas cuentas.
4. Con el primer teléfono en segundo plano, envía un mensaje desde el segundo:
   debe llegar un push que abra la conversación al tocarlo.
5. Crea una reserva confirmada y verifica el aviso de reserva; al tocarlo debe
   abrir el detalle de la reserva.
6. Repite la prueba con la app abierta: ahora se muestra una notificación local
   y también navega al tocarla.
7. Desactiva las notificaciones desde Perfil > Preferencias: el token se borra
   de Supabase y no deben enviarse nuevos push a ese dispositivo.

## Diagnóstico

```powershell
firebase functions:log --only enviarNotificacion,enviarNotificacionMensaje --project gameon-mobile
```

Los tokens FCM inválidos se limpian automáticamente de `usuarios_deportistas`.
