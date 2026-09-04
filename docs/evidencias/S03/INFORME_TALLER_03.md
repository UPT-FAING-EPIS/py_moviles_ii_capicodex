# Informe del Taller de Laboratorio 03

## Datos del equipo

- Curso: SI-988 Soluciones Móviles II
- Producto: GameOn Network
- Equipo: GameOn Team
- Integrantes: Sebastián Fuentes, Gabriela Gutierrez y Mayra Chire
- Repositorio: https://github.com/UPT-FAING-EPIS/py_moviles_ii_capicodex
- Etiqueta de entrega: https://github.com/UPT-FAING-EPIS/py_moviles_ii_capicodex/tree/taller-03

## Procedimiento

El equipo formuló un Product Goal a partir de la visión del producto y delimitó el MVP alrededor de la búsqueda, disponibilidad y reserva de instalaciones deportivas. Después construyó un Product Backlog de más de 25 elementos, registró valor, riesgo, puntos, datos personales y requisitos de seguridad, y aplicó un índice ponderado para ordenar el trabajo.

Las historias previstas para los Sprints 1 y 2 se revisaron con INVEST. Sus criterios de aceptación se expresaron en Gherkin. Las historias que presentan instalaciones incluyen los estados con datos, vacío, sin conexión y error del servidor.

El Sprint 1 se planificó con una capacidad efectiva estimada de 69 horas y un compromiso conservador de 10 puntos. El Sprint Goal se redactó antes de seleccionar los elementos. El plan distribuye el trabajo entre los tres integrantes y conserva la revisión cruzada exigida por la Definition of Done.

## Resultados y evidencias

| N.º | Resultado | Evidencia versionada | Estado antes de publicar |
|---:|---|---|---|
| 1 | Product Goal formulado | https://github.com/UPT-FAING-EPIS/py_moviles_ii_capicodex/blob/taller-03/docs/producto/PRODUCT_GOAL.md | Preparado |
| 2 | Product Backlog con al menos 25 elementos | https://github.com/UPT-FAING-EPIS/py_moviles_ii_capicodex/blob/taller-03/docs/sprints/PRODUCT_BACKLOG.csv | Preparado |
| 3 | Backlog ordenado por valor y riesgo | https://github.com/UPT-FAING-EPIS/py_moviles_ii_capicodex/blob/taller-03/docs/evidencias/S03/salidas/priorizacion_backlog.txt | Preparado |
| 4 | Cero elementos de 13 puntos o más | https://github.com/UPT-FAING-EPIS/py_moviles_ii_capicodex/blob/taller-03/docs/evidencias/S03/salidas/priorizacion_backlog.txt | Preparado |
| 5 | Historias de los Sprints 1 y 2 refinadas con INVEST | https://github.com/UPT-FAING-EPIS/py_moviles_ii_capicodex/blob/taller-03/docs/sprints/REFINAMIENTO.md | Preparado |
| 6 | Criterios de aceptación en Gherkin | https://github.com/UPT-FAING-EPIS/py_moviles_ii_capicodex/tree/taller-03/docs/sprints/criterios | Preparado |
| 7 | Inventario de datos personales | https://github.com/UPT-FAING-EPIS/py_moviles_ii_capicodex/blob/taller-03/docs/sprints/PRODUCT_BACKLOG.csv | Preparado |
| 8 | Planning Poker con discrepancia documentada | https://github.com/UPT-FAING-EPIS/py_moviles_ii_capicodex/blob/taller-03/docs/sprints/ESTIMACION.md | Requiere ratificación del equipo |
| 9 | Capacidad del Sprint calculada | https://github.com/UPT-FAING-EPIS/py_moviles_ii_capicodex/blob/taller-03/docs/sprints/sprint-01/SPRINT_BACKLOG.md | Preparado |
| 10 | Sprint Goal formulado y probado | https://github.com/UPT-FAING-EPIS/py_moviles_ii_capicodex/blob/taller-03/docs/sprints/sprint-01/SPRINT_BACKLOG.md | Preparado |
| 11 | Sprint Backlog con plan de entrega y Daily | https://github.com/UPT-FAING-EPIS/py_moviles_ii_capicodex/blob/taller-03/docs/sprints/sprint-01/SPRINT_BACKLOG.md | Preparado |
| 12 | Tablero con límites WIP y políticas | https://github.com/UPT-FAING-EPIS/py_moviles_ii_capicodex/blob/taller-03/docs/evidencias/S03/tablero-wip.png | Pendiente en GitHub |
| 13 | Sprint 1 iniciado con una historia y rama | https://github.com/UPT-FAING-EPIS/py_moviles_ii_capicodex/blob/taller-03/docs/evidencias/S03/sprint-01-inicio.png | Pendiente en GitHub |

## Conclusiones

1. Redactar el Sprint Goal antes de seleccionar elementos permitió limitar el Sprint 1 al flujo de registro e inicio de sesión. Si una tarea técnica cambia, el equipo puede ajustar el plan sin perder el resultado esperado para el usuario.
2. La diferencia propuesta para US-01 muestra por qué el Planning Poker debe discutir supuestos. Incluir la verificación por enlace cambia el alcance y la estimación; separarla mantiene la historia abordable y reduce el riesgo de retrabajo.
3. Los límites WIP obligan al equipo a terminar y revisar el trabajo antes de iniciar más historias. Con tres integrantes, el límite de tres elementos en progreso evita que cada persona acumule tareas sin producir un incremento verificable.

## Referencias

- Schwaber, K. y Sutherland, J. (2020). The Scrum Guide. https://scrumguides.org/
- Cohn, M. (2004). User Stories Applied: For Agile Software Development. Addison-Wesley.
- Wake, B. INVEST in Good Stories, and SMART Tasks. https://xp123.com/articles/invest-in-good-stories-and-smart-tasks/
- Cucumber. Gherkin Reference. https://cucumber.io/docs/gherkin/reference/
- GitHub. About Projects. https://docs.github.com/issues/planning-and-tracking-with-projects/learning-about-projects/about-projects

## Anexos

- Anexo A: Product Backlog en formato XLSX.
- Anexo B: criterios Gherkin versionados en `docs/sprints/criterios/`.
- Anexo C: registro de estimación en `docs/sprints/ESTIMACION.md`.
- Anexo D: Sprint Backlog en `docs/sprints/sprint-01/SPRINT_BACKLOG.md`.
- Anexo E: captura del tablero con límites WIP, pendiente de generar después de configurar GitHub Projects.
