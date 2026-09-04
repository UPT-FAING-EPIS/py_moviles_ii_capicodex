# Configuración del Sprint Board

## Nombre y acceso

- Nombre: `Sprint Board - GameOn Network`.
- URL: https://github.com/orgs/UPT-FAING-EPIS/projects/422/views/1
- Ubicación: GitHub Projects de `UPT-FAING-EPIS`, con `py_moviles_ii_capicodex` como repositorio predeterminado.
- Visibilidad: privada.
- Contenido importado: 35 issues abiertos del Product Backlog.
- Acceso docente: sujeto a los permisos de la organización.

## Campos personalizados

| Campo | Tipo | Uso |
|---|---|---|
| Sprint | Selección única | Sprint previsto, con opciones Sprint 1 a Sprint 7 |
| Puntos | Número | Estimación relativa acordada |
| Riesgo | Número | Nivel de 1 a 5 |
| Dato personal | Selección única | Indica `Sí` o `No` |

## Columnas y límites WIP

| Columna | Límite | Política de entrada |
|---|---:|---|
| Product Backlog | Sin límite | Issue definido y priorizado |
| Sprint Backlog | 10 puntos para Sprint 1 | Elemento seleccionado durante el Planning |
| En progreso | WIP 3 | La persona responsable no tiene otra historia en progreso |
| En revisión | WIP 3 | Pull Request abierto, CI en verde y autoprueba en emulador |
| En pruebas | WIP 2 | Pull Request aprobado por una persona distinta del autor |
| Listo | Sin límite | Todos los criterios de aceptación verificados y Definition of Done cumplida |

## Estado inicial del Sprint 1

- `TD-01` y `US-02` están en `Sprint Backlog`, con 2 y 3 puntos.
- `US-01` está en `En progreso`, con 5 puntos, responsable y rama vinculada.
- Los tres elementos tienen `Sprint 1`, riesgo y tratamiento de datos personales registrados en los campos del Project.

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
