# Configuración del Sprint Board

## Nombre y acceso

- Nombre: `Sprint Board - GameOn Network`.
- Ubicación: GitHub Projects, asociado al repositorio del equipo.
- Visibilidad: privada.
- Acceso docente: lectura.

## Campos personalizados

| Campo | Tipo | Uso |
|---|---|---|
| Sprint | Texto o iteración | Sprint previsto del elemento |
| Puntos | Número | Estimación relativa acordada |
| Riesgo | Número | Nivel de 1 a 5 |
| Dato personal | Texto | Dato tratado o `No` |

## Columnas y límites WIP

| Columna | Límite | Política de entrada |
|---|---:|---|
| Product Backlog | Sin límite | Issue definido y priorizado |
| Sprint Backlog | 10 puntos para Sprint 1 | Elemento seleccionado durante el Planning |
| En progreso | WIP 3 | La persona responsable no tiene otra historia en progreso |
| En revisión | WIP 3 | Pull Request abierto, CI en verde y autoprueba en emulador |
| En pruebas | WIP 2 | Pull Request aprobado por una persona distinta del autor |
| Listo | Sin límite | Todos los criterios de aceptación verificados y Definition of Done cumplida |

## Automatizaciones recomendadas

- Al abrir un Pull Request vinculado, mover el issue a `En revisión (WIP 3)`.
- Al fusionar el Pull Request, mover el issue a `En pruebas (WIP 2)`; no mover directamente a Listo.
- Cerrar el issue únicamente después de registrar la evidencia de los criterios y la Definition of Done.

## Convención para los issues

- Título: `<id> - <historia o elemento>`.
- Cuerpo: épica, tipo, criterios, valor, riesgo, puntos, dato personal, seguridad y Sprint previsto.
- Responsable: una persona inicial.
- Rama: `feature/<US-xx>-descripcion`, `chore/<descripcion>` o `fix/<descripcion>`.
- Pull Request: vinculado con `Closes #<número>` cuando el elemento llegue a Listo.
