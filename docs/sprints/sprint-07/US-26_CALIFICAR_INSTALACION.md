# US-26 · Calificar instalación tras una reserva

## Alcance implementado

- El botón de calificación se muestra únicamente en el detalle de reservas con estado `completada`.
- Cada reserva admite una sola calificación de 1 a 5 estrellas; una segunda operación actualiza la existente.
- El comentario es opcional y está limitado a 500 caracteres.
- El promedio de `instituciones_deportivas.calificacion` se recalcula después de crear, editar o eliminar una calificación.

## Seguridad

La app no tiene permisos directos sobre `calificaciones_instalaciones`. Las funciones SQL verifican una sesión válida, que el usuario sea el dueño de la reserva y que la reserva esté completada antes de guardar o leer su calificación.

## Despliegue y verificación

1. Aplicar `bd/migraciones/202611120002_calificaciones_instalaciones.sql` en el proyecto Supabase correcto.
2. Con un usuario A, intentar calificar una reserva de B y una reserva no completada: ambas operaciones deben fallar.
3. Calificar una reserva completada, editarla y confirmar que existe una sola fila y que el promedio de la instalación se actualiza.
4. Ejecutar `flutter test` y `flutter analyze --no-pub` desde `gameon_mobile`.
