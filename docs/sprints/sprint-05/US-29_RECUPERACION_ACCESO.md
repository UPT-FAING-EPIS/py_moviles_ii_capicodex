# US-29 Recuperación del acceso por correo

Issue: https://github.com/UPT-FAING-EPIS/py_moviles_ii_capicodex/issues/27

Los dos formularios de inicio de sesión abren Recuperar acceso. El usuario solicita un código, lo introduce con la nueva contraseña y su confirmación y regresa al inicio de sesión después del cambio.

## Seguridad y comportamiento

La solicitud usa Supabase Auth `/recover` y muestra el mismo mensaje genérico para cuentas existentes y no existentes. No consulta el listado de usuarios. Los errores de límites de intentos o conexión tienen mensajes neutros; no se muestran respuestas técnicas.

Antes de actualizar se verifica el código con `/verify` y `type: recovery`. Solo con el access token devuelto se llama a `/user`. El token no se persiste ni se instala como sesión de la aplicación; se solicita revocar la sesión temporal con `/logout?scope=local` al finalizar, también si falla el cambio de contraseña. No se registra correo, código, contraseña ni token en logs. No se usan claves de servicio ni credenciales administrativas. Se reutiliza la configuración pública ya existente del cliente.

Los códigos expiran y son de un solo uso conforme a la configuración de Supabase Auth. Si el código fue consumido y el cambio falla, se debe solicitar uno nuevo. Un resultado de red incierto indica probar el inicio de sesión o pedir otro código. El cierre remoto es de mejor esfuerzo: si la red falla, la app no conserva el token, pero no puede confirmar su revocación en el servidor.

## Configuración necesaria en el entorno de pruebas

En Supabase Auth, configurar la plantilla **Reset Password** para incluir el código `{{ .Token }}`. Este flujo ingresa el código en la app y no depende de enlaces profundos. Revisar SMTP, caducidad y límites de solicitudes según las políticas del proyecto; no ampliar la vigencia para eludir pruebas. El código admite entre 6 y 10 dígitos. La app valida un mínimo de 6 caracteres de contraseña, igual que el registro existente; el servidor conserva la política definitiva.

La configuración remota no se ha modificado. Con una plantilla que solo incluya un enlace, el usuario no podrá copiar el código hasta aplicar esta configuración. Probar en el entorno de pruebas: correo existente, correo no registrado, código incorrecto, vencido, reutilizado, fallo de red, nueva contraseña y rechazo de la anterior.

## Verificación

Las pruebas del servicio cubren respuesta indistinguible para cuenta inexistente, límites, token inválido, orden de verificación y cambio, uso del token, contraseña sin recortar espacios, revocación tras error y mensajes sin datos técnicos. Las pruebas de interfaz cubren validación del correo y coincidencia de contraseñas.

Pendiente: envío real en pruebas, confirmación de caducidad configurada y revisión cruzada del PR. La Definition of Done no se considera cumplida hasta completar estos pasos.
