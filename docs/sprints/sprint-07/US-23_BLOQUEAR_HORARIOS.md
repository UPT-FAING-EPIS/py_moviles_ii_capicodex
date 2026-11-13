# US-23 – Como administrador quiero bloquear horarios no disponibles para evitar reservas inválidas (#22)

Historia: https://github.com/UPT-FAING-EPIS/py_moviles_ii_capicodex/issues/22  
Rama: `feature/US-23-bloquear-horarios`

## Contexto
- **Épica**: Administración
- **Sprint**: 7
- **Puntos**: 5 | **Valor**: 4 / 5 | **Riesgo**: 5 / 5
- **Dato personal**: No
- **Seguridad**: Sí: autorización e integridad

## Criterios de aceptación verificados
- **El bloqueo impide nuevas reservas y no elimina reservas existentes sin confirmación**:
  - **Autorización e integridad**: Se valida que solo un administrador autorizado (`gestorId > 0`) pueda registrar, modificar, bloquear o eliminar horarios tanto en `GestorView` (`_horariosDialog`, `_horarioForm`) como en `GestorService` (`validarDatosHorario`, `guardarHorario`, `cambiarDisponibilidadHorario`, `borrarHorario`), en concordancia con las políticas RLS `gestor_crea_horarios`, `gestor_edita_horarios` y `gestor_borra_horarios` sobre `public.areas_horarios`. Se verifica además que el área deportiva sea válida, el día corresponda a un día válido de la semana (`lunes` a `domingo`) y la hora de cierre sea estrictamente posterior a la hora de apertura.
  - **Impedimento de nuevas reservas**: Cuando un horario se marca como bloqueado (`disponible = 0`), tanto `GestorService.horarioPermiteReserva` como `ReservaCalendarioViewModel` (`cargarHorarios`, `diaDisponible`, `seleccionarDia`) inhabilitan el día o los turnos fuera del rango operativo, impidiendo la generación de bloques seleccionables y el registro de nuevas reservas inválidas.
  - **Conservación de reservas existentes con confirmación explícita**: Antes de aplicar un bloqueo total (`disponible = false`), un recorte de rango horario o la eliminación de un horario, `GestorService.detectarReservasAfectadasPorBloqueo` identifica las reservas activas (`pendiente`, `confirmada`) en dicho turno. Si existen reservas activas y no se ha otorgado confirmación explícita (`confirmarConReservasExistentes`), la operación se rechaza sin alterar la base de datos. En la interfaz (`GestorView`), se solicita confirmación expresa al administrador informando la cantidad de reservas activas y garantizando que el bloqueo solo afecta a nuevas reservas sin eliminar ni cancelar las reservas existentes en `public.reservas`.

## Componentes actualizados
- `gameon_mobile/lib/features/gestor/services/gestor_service.dart`
- `gameon_mobile/lib/features/gestor/views/gestor_view.dart`
- `gameon_mobile/test/features/gestor/bloqueo_horarios_test.dart`
- `.github/workflows/ci.yml`
- `docs/sprints/sprint-07/US-23_BLOQUEAR_HORARIOS.md`
