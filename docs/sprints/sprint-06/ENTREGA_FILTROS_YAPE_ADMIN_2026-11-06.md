# Entrega GameOn: filtros, Yape y aprobación de gestores

## Alcance implementado

- Ajustes visuales posteriores a la revisión en emulador: selector de tema compartido en deportista, gestor y ADM; preferencia guardada por cuenta; filtros de deportes con separación; ficha de cancha en pantalla propia con vista previa y carga de imagen; formularios del perfil con campos de ancho completo y paleta del tema; calendario, listado de canchas y resumen de pago adaptados al tema. Se eliminó el texto técnico de estado de PayPal de la interfaz, manteniendo esta limitación en la documentación.
- Búsqueda de centros por nombre, dirección o deporte, con chips compactos de deporte. Se conservó el pie de navegación y el tema visual.
- Cada gestor aprobado puede abrir **Mi código Yape** desde Panel o Cuenta, subir o cambiar la imagen QR, indicar el titular y el celular y guardarlos para todas sus canchas.
- El deportista ve el QR y el importe, sube una imagen de evidencia y crea una reserva `pendiente` mediante una RPC. La hora se ocupa hasta aprobación o rechazo. La RPC verifica identidad, archivo, horario, solapamientos y calcula el importe en el servidor.
- El gestor consulta la captura mediante URL firmada temporal y decide después de comprobar el ingreso en su propia cuenta Yape. Si rechaza, la hora se libera. El deportista ve sus reservas y un historial básico de pagos asociados.
- Hay avisos persistidos en Supabase para deportista y gestor. Son **avisos dentro de la aplicación**; su entrega push exige una función backend y configuración FCM adicionales.
- Nuevos gestores esperan aprobación, pueden subir hasta tres imágenes privadas y el administrador con rol `ADM` puede revisar, aprobar o rechazar. Gestores existentes permanecen activos.
- PayPal conserva el flujo anterior. Está etiquetado como prueba porque su destinatario no está vinculado a la cuenta del gestor ni puede verificarse la función remota en este repositorio. No se solicitan secretos PayPal en Flutter.

## Despliegue necesario antes de la prueba integral

El primer intento en SQL Editor devolvió `42710: policy "gestor_evidencias_lectura" already exists`. Se revisó la migración para que reemplace dentro de una transacción las políticas y triggers propios si ya existen. El segundo intento con el archivo completo actualizado devolvió **"Success. No rows returned"** según el usuario el 06/11/2026. El panel puede mostrar "Potential issue detected" porque el SQL reemplaza políticas/triggers y revoca acceso a la RPC antigua. No incluye `DROP TABLE`, `TRUNCATE`, `DELETE` ni borra reservas o evidencias.

1. Ejecutar `bd/migraciones/202611060001_administracion_yape.sql` **después** de `202610300001_gestor_movil.sql` y `202610300002_doble_rol_gestor.sql`. El inventario remoto del 06/11 confirma las tablas, la política `select_all_reservas`, las políticas de gestor y `gestor-imagenes`; la migración no se ejecuta automáticamente desde Flutter. El inventario no describe funciones ni triggers, por lo que conviene inspeccionarlos antes de ejecutar.
2. Crear o identificar la cuenta Auth que tendrá rol ADM. Con el UUID exacto, ejecutar desde SQL Editor con permisos de administrador:

   ```sql
   insert into public.roles_aplicacion(auth_id, rol)
   values ('UUID_REAL_DE_AUTH_USERS'::uuid, 'ADM')
   on conflict (auth_id) do update set rol = excluded.rol;
   ```

   Nunca permitir que el cliente móvil inserte en `roles_aplicacion`. El usuario inicia sesión con la opción Admin o cambia desde su perfil.
3. Verificar que Supabase Storage permita los buckets privados `gestor-solicitudes` y `yape-evidencias`, y que `gestor-imagenes` público ya existe para el QR. Probar con dos cuentas deportivas, un gestor y un administrador.
4. Comprobación realizada por el usuario el 06/11/2026: la búsqueda de reservas solapadas desde esa fecha devolvió **cero filas**. Se detectaron las reservas históricas 144 y 146 de la misma área el 25/09/2025; la restricción GiST de esta migración solo abarca desde el 06/11/2026 y no altera las reservas antiguas. Si aparecen solapamientos nuevos antes del despliegue, el SQL se detendrá sin borrarlos. La migración de reprogramación (`gameon_mobile/supabase/migrations/202610230001_reprogramar_reserva.sql`) contiene una restricción de todo el historial y no debe ejecutarse después sin adaptar su instrucción `add constraint`.
5. Verificar Cloud Functions de Firebase y variables `SUPABASE_URL` / `SUPABASE_KEY` antes de declarar que existen notificaciones push. No confundir la bandeja de avisos de Supabase con un push al teléfono.

## Pruebas de aceptación recomendadas

1. Buscar «fútbol» y comprobar que aparecen centros con áreas activas de ese deporte. Elegir un chip y combinarlo con nombre de centro.
2. Registrar un gestor nuevo, iniciar sesión como gestor y adjuntar 1–3 imágenes. Ver que no puede crear centros antes de aprobación.
3. Entrar como ADM, revisar las imágenes y aprobar. Reingresar o actualizar estado desde el gestor; configurar QR Yape.
4. Como deportista, pagar fuera de la app al QR, adjuntar captura y verificar que la reserva figura pendiente y la franja queda ocupada.
5. Confirmar en la cuenta real del gestor el ingreso, aprobar desde la agenda y comprobar la reserva confirmada y el aviso del deportista. Repetir con rechazo y comprobar que la franja se libera.
6. Reintentar simultáneamente la misma franja con otra cuenta: solo debe aceptarse una reserva Yape. Probar acceso ajeno a imágenes privadas y a funciones ADM: debe denegarse.

## Límites conocidos

- Una captura de pantalla no demuestra el pago; la confirmación humana en Yape es obligatoria. Si otro usuario reserva mientras el primero paga fuera de la app y antes de enviar evidencia, el primero podría necesitar devolución manual. Definir una retención temporal con vencimiento en una siguiente iteración.
- Los avisos de esta entrega son persistentes en la app; el push a gestores y deportistas todavía requiere despliegue backend. El asistente virtual, PDF de constancia y comprobante tributario quedan fuera del alcance solicitado.
- El inventario remoto muestra `select_all_reservas` con lectura `true`. Eso permite que el calendario y la agenda existentes vean horarios, pero también podría exponer otras columnas de reservas a quienes tengan permiso SELECT. Antes de publicar datos de pagos, separar disponibilidad pública de detalles privados mediante políticas/RPC específicas.
- `usuarios_instalaciones` ya tiene columnas `paypal_client_id`, `paypal_client_secret` y `paypal_enabled`. Su existencia no prueba que la función externa use esas credenciales ni que el dinero llegue al gestor. No introducir el secreto en la aplicación móvil.
- El historial actual usa los datos de cada reserva y no es un libro contable de múltiples movimientos, comisiones o devoluciones.
- PayPal usa una función externa no versionada aquí. No se comprobó cobro real ni cuenta de destino. La incorporación de vendedores PayPal exige solución de plataforma y secretos únicamente en servidor.
