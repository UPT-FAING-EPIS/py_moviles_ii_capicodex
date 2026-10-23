# US-13 Reprogramación de reservas

Issue: https://github.com/UPT-FAING-EPIS/py_moviles_ii_capicodex/issues/16

Desde el detalle de una reserva pendiente o confirmada se puede elegir una nueva fecha y hora y confirmar el cambio. El servidor identifica al propietario mediante `auth.uid()` y actualiza la misma fila; conserva el identificador, área, duración y pago. No se cobra nuevamente ni se inserta una segunda reserva.

## Disponibilidad y concurrencia

La función `reprogramar_reserva` comprueba el propietario, el estado, que ambos horarios sean futuros en Perú y que el nuevo intervalo esté dentro de `areas_horarios`. La restricción GiST protege de solapamientos tanto los cambios como las inserciones concurrentes del flujo de reservas existente. Usa intervalos semiabiertos y excluye las reservas canceladas. Un conflicto aborta la operación completa y conserva el horario anterior.

## Aplicación en Supabase

Revisar el esquema real y aplicar `gameon_mobile/supabase/migrations/202610230001_reprogramar_reserva.sql` mediante el proceso habitual de migraciones. Se usan las tablas y columnas referenciadas por los modelos Dart: `reservas`, `usuarios_deportistas` y `areas_horarios`; el repositorio no contiene un volcado del esquema remoto. La migración se detiene si existen solapamientos previos: deben investigarse, sin borrar reservas automáticamente. Mantener las políticas RLS del proyecto. La RPC permite ejecución solo al rol authenticated y verifica explícitamente la propiedad antes de escribir.

La migración no ha sido aplicada al entorno remoto. Antes de usar el flujo allí, verificar también las políticas de lectura de reservas y horarios. La interfaz informa si la RPC aún no está disponible.

## Verificación

`flutter test test/features/reservas/reprogramacion_service_test.dart` comprueba la llamada RPC única y la propagación de conflictos. Los scripts de `supabase/tests` prueban el cambio sin duplicados, reintentos, pago intacto, horarios contiguos, conflicto con rollback, propiedad, autenticación, estado, pasado, horario cerrado y medianoche en una base aislada. No ejecutar bootstrap sobre producción.

Pendiente: validación funcional con dos cuentas en el entorno de pruebas, revisión cruzada y aprobación del PR. Un commit no significa que la Definition of Done esté cumplida.
