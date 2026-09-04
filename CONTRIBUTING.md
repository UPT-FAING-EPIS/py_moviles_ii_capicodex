# Convenciones del equipo · GameOn Network

## Ramas

- `main`: rama estable y protegida.
- `develop`: rama de integración.
- `feature/<US-xx>-descripcion`: desarrollo de funcionalidades.
- `fix/<descripcion>`: corrección de errores.
- `chore/<descripcion>`: tareas técnicas.

## Commits

Se utilizará Conventional Commits.

Formato:

`<tipo>(<alcance>): <descripción> [US-xx]`

Tipos permitidos:

- feat
- fix
- docs
- style
- refactor
- test
- chore

Ejemplos:

`docs(producto): agregar Lean Canvas`

`feat(maps): agregar vista inicial de instalaciones [US-01]`

`test(reservas): agregar prueba de disponibilidad [US-05]`

## Pull Requests

Todo Pull Request deberá:

- estar relacionado con una tarea o historia;
- tener el CI en verde;
- ser revisado por un integrante diferente al autor;
- cumplir con la Definition of Done;
- no contener credenciales o secretos.