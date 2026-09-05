# Estimación de los Sprints 1 y 2

## Método

El equipo usa Planning Poker con la escala de Fibonacci `1, 2, 3, 5, 8`. Cada integrante vota antes de revelar las estimaciones. Cuando existe diferencia, las personas con la estimación menor y mayor explican sus supuestos y el equipo vuelve a votar.

## Registro preparado para ratificación del equipo

La tabla contiene una propuesta técnica para realizar la sesión. Antes de entregar el taller, Sebastián Fuentes, Gabriela Gutierrez y Mayra Chire deben votar en conjunto y reemplazar cualquier valor que no coincida con la conversación real. La discrepancia solo puede presentarse como evidencia después de esa ratificación.

| Elemento | Sebastián | Gabriela | Mayra | Consenso propuesto | Discrepancia | Hallazgo que debe validar el equipo |
|---|---:|---:|---:|---:|---|---|
| TD-01 Arquitectura base | 2 | 2 | 3 | 2 | 2 frente a 3 | Confirmar si la configuración de CI ya está operativa en `develop`. |
| US-01 Registro con correo | 3 | 8 | 5 | 5 | 3 frente a 8 | La estimación alta incluye validación del correo mediante enlace; esa función se separó del registro básico. |
| US-02 Inicio de sesión | 3 | 3 | 5 | 3 | 3 frente a 5 | Verificar si el almacenamiento seguro de la sesión forma parte de esta historia o de una tarea técnica. |
| TD-02 Capa de datos y caché | 3 | 2 | 3 | 2 | 2 frente a 3 | Acordar el alcance de la caché para el Sprint 2. |
| US-03 Lista de instalaciones | 5 | 5 | 8 | 5 | 5 frente a 8 | La estimación alta considera paginación; el Sprint 2 solo necesita hasta 100 elementos. |
| US-04 Detalle de instalación | 3 | 3 | 5 | 3 | 3 frente a 5 | Confirmar qué fotografías y servicios devuelve el servicio inicial. |
| US-05 Filtro por deporte | 3 | 5 | 3 | 3 | 3 frente a 5 | El filtro se ejecutará sobre el servicio; no incluye filtros combinados por precio o distancia. |

## Resultado esperado de la sesión

El principal punto que debe discutirse es US-01. La diferencia entre 3 y 8 puntos revela dos alcances distintos: registro básico o registro con verificación mediante enlace. La propuesta divide el segundo alcance para mantener US-01 en 5 puntos y evitar trabajo no acordado dentro del Sprint 1.
