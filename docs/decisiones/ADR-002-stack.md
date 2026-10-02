# ADR-002 · Stack tecnológico de GameOn Network

- **Estado:** aceptada
- **Fecha:** 2026-09-04
- **Decidido por:** GameOn Team

## Contexto

El equipo debe seleccionar un stack móvil mediante criterios ponderados y evidencia. GameOn Network ya dispone de una aplicación funcional en Flutter y requiere geolocalización, Google Maps, cámara, notificaciones, almacenamiento, reservas y conexión a servicios remotos.

## Evaluación

El alcance actual del producto en el curso es **Android**. El criterio «Viabilidad sin macOS» se mantiene porque forma parte de la matriz obligatoria de la guía; en este proyecto no representa una necesidad de desarrollar para iOS.

La matriz completa se encuentra en `evaluacion_stacks.csv`. Con una escala de 1 a 5, los resultados ponderados son:

| Stack | Puntaje |
|---|---:|
| Flutter | **4.90** |
| Nativo | 3.85 |
| React Native | 3.75 |
| Kotlin Multiplatform | 3.25 |

## Dos finalistas para la prueba de humo

1. **Flutter** — stack del proyecto actual.
2. **React Native** — alternativa multiplataforma madura y razonable para comparación.

### Capacidad crítica seleccionada

**Mapa y geolocalización.** Es una capacidad central de GameOn porque permite visualizar instalaciones deportivas cercanas y su ubicación.

### Resultado de la prueba de humo

La ejecución real debe registrarse en `docs/evidencias/S02/` con captura o video de ambos stacks. El proyecto Flutter ya contiene integración con `google_maps_flutter` y `geolocator`; la evidencia de la ejecución debe obtenerse en el laboratorio. React Native deberá ejecutar un prototipo mínimo equivalente durante la prueba de 30 minutos.

> No se declara una prueba de humo como aprobada sin captura o video real.

## Decisión

Se continúa con **Flutter** porque:

- GameOn ya posee una base funcional implementada en este stack.
- El equipo cuenta con experiencia directa sobre el proyecto.
- Las capacidades críticas ya tienen dependencias integradas.
- Cambiar de stack provocaría una reimplementación extensa sin aportar valor proporcional al curso.

## Plan de salida

Si Flutter dejara de ser viable para el alcance Android del proyecto, se considerará una migración hacia Kotlin/Android nativo o React Native cuando ocurra alguno de estos escenarios:

- una dependencia crítica deje de mantenerse y no exista reemplazo razonable;
- aparezcan restricciones de rendimiento demostrables mediante mediciones;
- Android requiera una capacidad crítica que no pueda resolverse de forma estable en Flutter;
- el equipo responsable del mantenimiento cambie y tenga competencias significativamente mayores en otro stack.

### Qué puede reutilizarse

- Requerimientos, historias de usuario y criterios de aceptación.
- Diseño visual y flujos de navegación.
- Contratos de API y esquema de datos.
- Backend Supabase/Firebase.
- Casos de prueba, reglas de negocio y documentación ADR.

### Qué debe reescribirse

- Vistas y navegación.
- ViewModels dependientes de Dart.
- Integraciones con paquetes Flutter.
- Configuración de compilación y CI específica del stack.

El costo de salida se considera **alto**, dado que la mayor parte de la interfaz móvil está implementada en Flutter.
