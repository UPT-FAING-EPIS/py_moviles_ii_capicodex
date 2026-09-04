# Sprint Backlog 01 de GameOn Network

## Sprint Goal

Al final del Sprint 1, un deportista amateur podrá crear una cuenta e iniciar sesión con datos persistidos por el servicio de GameOn Network, con la aplicación funcionando en el emulador y verificada en al menos un teléfono Android del equipo.

## Prueba del Sprint Goal

El objetivo expresa un resultado para el usuario y no una lista de tareas. TD-01 puede cambiar de alcance sin perder el objetivo, siempre que exista una base técnica suficiente. US-01 y US-02 sostienen el flujo principal; si una de ellas no llega a Listo, el equipo debe reducir trabajo técnico o renegociar el alcance sin sustituir el objetivo por tareas inconexas.

## Fechas propuestas

| Evento | Fecha y hora |
|---|---|
| Inicio del Sprint | 7 de septiembre de 2026, 19:00 |
| Daily | Días de trabajo, 23:00, Discord, máximo 15 minutos |
| Sprint Review | 18 de septiembre de 2026, 19:00 |
| Sprint Retrospective | 18 de septiembre de 2026, 20:00 |
| Fin del Sprint | 18 de septiembre de 2026, 21:00 |

Estas fechas deben ser ratificadas por el equipo antes de iniciar el Sprint.

## Capacidad

| Concepto | Cálculo | Horas |
|---|---:|---:|
| Capacidad bruta | 3 integrantes x 10 días hábiles x 3 horas diarias | 90 |
| Eventos de Scrum | Planning, Dailies, Review y Retrospective | -8 |
| Reserva para imprevistos | 15 % de la capacidad bruta | -13,5 |
| Capacidad efectiva | 90 - 8 - 13,5 | 68,5 |

El equipo redondea la capacidad efectiva a **69 horas**. Como todavía no existe velocidad histórica, el compromiso se limita a **10 puntos**, dentro del rango conservador de 8 a 13 puntos indicado por el curso.

## Elementos seleccionados

| Elemento | Descripción | Puntos |
|---|---|---:|
| TD-01 | Configurar arquitectura base, entornos y CI | 2 |
| US-01 | Registrar una cuenta con correo | 5 |
| US-02 | Iniciar sesión con correo y contraseña | 3 |
| **Total** |  | **10** |

## Plan de entrega

| Elemento | Tarea | Responsable inicial | Evidencia esperada |
|---|---|---|---|
| TD-01 | Definir módulos y configuración por entorno | Gabriela Gutierrez | Commit de configuración y documento técnico |
| TD-01 | Ajustar el workflow de compilación, análisis y pruebas | Mayra Chire | Ejecución de GitHub Actions en verde |
| US-01 | Diseñar la pantalla y los estados de registro | Sebastián Fuentes | Captura en emulador y código de interfaz |
| US-01 | Implementar endpoint, validación y persistencia del usuario | Gabriela Gutierrez | Pruebas del servicio y Pull Request |
| US-01 | Preparar y ejecutar pruebas de criterios de aceptación | Mayra Chire | Resultado de pruebas versionado |
| US-02 | Diseñar la pantalla y mensajes de inicio de sesión | Sebastián Fuentes | Captura en emulador y código de interfaz |
| US-02 | Implementar autenticación y almacenamiento seguro de sesión | Gabriela Gutierrez | Pruebas del servicio y Pull Request |
| US-02 | Ejecutar pruebas en emulador y teléfono Android | Mayra Chire | Captura o video en `docs/evidencias/S03/` |

La responsabilidad es inicial. Todo Pull Request debe ser revisado por una persona distinta de su autor.

## Riesgos del Sprint

| Riesgo | Probabilidad | Impacto | Respuesta |
|---|---|---|---|
| El stack móvil o backend todavía no está definido en el repositorio | Alta | Alto | Resolver TD-01 antes de iniciar las pantallas. |
| La verificación de correo amplía US-01 | Media | Alto | Mantenerla fuera de US-01 y crear una historia posterior. |
| La autenticación funciona en emulador pero falla en el teléfono | Media | Alto | Probar la conectividad del dispositivo durante los primeros días. |
| El equipo supera su capacidad por falta de velocidad histórica | Alta | Medio | Mantener el compromiso en 10 puntos y aplicar el límite de WIP. |

## Acuerdo de la Daily

- Hora: 23:00 durante los días de trabajo del Sprint.
- Canal: Discord.
- Duración máxima: 15 minutos.
- Cada integrante comunica avance hacia el Sprint Goal, siguiente acción e impedimentos.
- Los impedimentos que duren más de cuatro horas se registran en el tablero.

## Definition of Done aplicada

Un elemento pasa a Listo cuando cumple sus criterios de aceptación, compila sin errores, supera las pruebas y el análisis estático, no contiene credenciales, está vinculado a una rama y a un Pull Request, tiene CI en verde, fue aprobado por una persona distinta del autor y actualiza la documentación relacionada.
