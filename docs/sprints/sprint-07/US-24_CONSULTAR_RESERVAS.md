# US-24 · Consultar las reservas de instalaciones administradas

Historia: https://github.com/UPT-FAING-EPIS/py_moviles_ii_capicodex/issues/24
Rama: `feature/US-24-consultar-reservas`.

## Comportamiento

Se conserva la agenda del gestor, la selección de fecha y los filtros de centro,
deporte y estado. Cada tarjeta añade el código de reserva para organizar la
atención sin identificar al cliente. El filtro de estado acepta mayúsculas y
minúsculas usadas por las reservas existentes. La consulta recupera todas las
páginas de 200 registros, ordenadas por fecha descendente, hora e identificador.

## Autorización y minimización

`consultar_reservas_gestor` obtiene el gestor activo con `gestor_actual()` y
`auth.uid()`. Los IDs de áreas enviados por la app solo filtran: cada reserva se
une a su instalación y debe pertenecer al gestor de la sesión. Una cuenta sin
perfil gestor activo recibe `42501`; una lista de áreas ajenas o vacía no
devuelve filas. El rol anónimo no tiene permiso de ejecución.

La función usa `SECURITY DEFINER`, nombres de tablas cualificados y `search_path`
vacío. Devuelve exclusivamente código de reserva, área, fecha, inicio, fin,
estado, monto pagado y método de pago. No consulta datos personales del cliente
ni devuelve su ID, nombre, correo, teléfono o identificadores de cobro.
No amplía permisos de lectura sobre tablas ni cambia las políticas existentes
de deportistas, pagos, registro de instalaciones o reprogramación.

## Despliegue

Aplicar `bd/migraciones/202611120001_consultar_reservas_gestor.sql` en Supabase
**antes de distribuir esta versión móvil**, después de la migración de gestor
`202610300001_gestor_movil.sql`. La función depende de las tablas existentes y
de `gestor_actual()`. La migración no se ejecuta automáticamente desde la app.
No se ha modificado la base remota durante esta implementación.

Los bootstrap de `gameon_mobile/supabase/tests` son únicamente para bases vacías
de prueba; nunca deben ejecutarse en producción.

## Verificación

- Resultado local: 55 pruebas Flutter aprobadas; análisis estático del servicio,
  vista y pruebas del gestor sin observaciones; `flutter build web --no-pub`
  completado. El build avisa de incompatibilidad Wasm de geolocator_web y una
  fuente Cupertino no declarada; no impiden la compilación JavaScript.
- Pruebas Dart: RPC utilizada, propagación de acceso denegado, lista vacía y
  recuperación de 201 reservas sin truncamiento.
- Pruebas SQL ejecutadas en PostgreSQL embebido (PGlite): aislamiento entre dos
  gestores, múltiples instalaciones propias, áreas ajenas, fecha, orden,
  paginación, proyección mínima, cuentas inactivas/no gestoras y acceso anónimo.
- Workflow `reservas-gestor-sql.yml` repite el contrato en PostgreSQL 17 aislado.
- Se corrigieron el import de paquete y las respuestas HTTP simuladas de la
  prueba preexistente US-20; no cambia su lógica de producción.
- Revisión manual sugerida: ingresar como gestor, abrir Reservas, cambiar fecha
  y filtros, verificar código, horario, estado y monto; repetir con otro gestor.

La aprobación del Pull Request por una persona distinta del autor sigue siendo
un requisito humano pendiente; no queda satisfecha por las pruebas automáticas.
