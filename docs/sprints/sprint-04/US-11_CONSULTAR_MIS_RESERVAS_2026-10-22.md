# US-11 · Consultar mis reservas

Fecha: 22 de octubre de 2026  
Issue: #11 · Sprint 04  
Responsable asignada: LuzkalidGM  
Épica: Reservas  
Puntos de historia: 5  

## Trabajo realizado

Se implementó y verificó la historia de usuario **US-11**, permitiendo a los deportistas consultar sus reservas para organizar sus actividades, asegurando la privacidad de sus datos personales y cubriendo cuatro estados de interfaz.

1. **Aislamiento y autorización de datos personales (Usuario autenticado)**:
   - Verificación de sesión activa mediante `PerfilViewModel`. Si el usuario no ha iniciado sesión, la interfaz bloquea el acceso a datos sensibles y muestra un estado claro con invitación a iniciar sesión ("Debes iniciar sesión para ver tus reservas").
   - La consulta de reservas a Supabase filtra estrictamente por el identificador del usuario autenticado (`id_usuario = idUsuario`), garantizando que cada usuario únicamente visualice su propio historial de reservas.

2. **Cobertura de los cuatro estados de interfaz**:
   - **Estado 1: Cargando (Loading)**: Indicador de progreso visual (`CircularProgressIndicator`) mientras se recuperan las reservas del usuario desde la base de datos o backend.
   - **Estado 2: Contenido / Éxito (Populated/Success)**: Renderizado de la lista interactiva de reservas mediante `ListView.builder` y `ReservaCard`. Muestra el ID de reserva, nombre del área e institución deportiva, chip de estado temático (`EstadoChip`), rango de horario (`HH:mm - HH:mm`), duración calculada en minutos/horas y monto pagado (S/.). En el encabezado se muestra el contador total de reservas activas.
   - **Estado 3: Vacío (Empty)**: Cuando el usuario autenticado no cuenta con reservas registradas, se presenta una pantalla limpia con ilustración (`Icons.event_available`), título comprensible ("¡Aún no tienes reservas!") y mensaje explicativo sobre el seguimiento de reservas futuras.
   - **Estado 4: Error (Error)**: Manejo robusto de errores de red o fallo del servidor, mostrando mensaje amigable ("Error al cargar reservas"), el detalle del error y un botón destacado para "Reintentar" la consulta.

3. **Optimización de consultas y caché**:
   - Soporte de inyección de dependencias en `ReservasListView` y `ReservasListViewModel`.
   - Precarga por lotes y caché en memoria (`_areasCache`, `_instCache`) para evitar consultas redundantes N+1 al renderizar múltiples tarjetas de reserva.
   - Botón de refresco manual en el encabezado y soporte para `RefreshIndicator` (deslizar para refrescar).

## Criterios de Aceptación Verificados

| Escenario | Criterio | Estado | Evidencia |
|---|---|---|---|
| Escenario 1: Usuario no autenticado (Autorización) | Si el usuario no ha iniciado sesión, se solicita autenticación y no se exponen reservas de ningún deportista. | Verificado | `test/features/reservas/reservas_list_view_test.dart` (Criterio 1 en verde). |
| Escenario 2: Estado de carga | Mientras se obtienen las reservas del servidor, se presenta el indicador de carga visual. | Verificado | `test/features/reservas/reservas_list_view_test.dart` (Criterio 2 - Estado 1/4 en verde). |
| Escenario 3: Estado con reservas (Éxito) | Muestra tarjetas con datos completos (área, institución, fecha, horario, duración, estado y monto) y contador total en encabezado. | Verificado | `test/features/reservas/reservas_list_view_test.dart` (Criterio 2 - Estado 2/4 en verde). |
| Escenario 4: Estado vacío | Si el usuario no tiene reservas, se muestra mensaje amigable e icono informativo sin romper la interfaz. | Verificado | `test/features/reservas/reservas_list_view_test.dart` (Criterio 2 - Estado 3/4 en verde). |
| Escenario 5: Estado de error | Ante fallo de red o conexión, se muestra mensaje amigable y botón de reintento funcional. | Verificado | `test/features/reservas/reservas_list_view_test.dart` (Criterio 2 - Estado 4/4 en verde). |
| Escenario 6: Aislamiento por usuario | La lista solo consulta y presenta registros asociados al `id_usuario` autenticado. | Verificado | `test/features/reservas/reservas_list_viewmodel_test.dart` y `reservas_list_view_test.dart` en verde. |

## Definition of Done

- [x] Criterios de aceptación verificados
- [x] Compila sin errores (`flutter test`, `flutter analyze`)
- [x] Pruebas y análisis estático en verde (15 pruebas específicas de la historia en verde, 29 pruebas totales del proyecto en verde, `flutter analyze` sin advertencias en archivos de la historia)
- [x] Sin credenciales ni secretos
- [x] Rama vinculada (`feature/US-11-consultar-reservas`)
- [ ] Pull Request aprobado por una persona distinta del autor
- [x] Documentación actualizada
