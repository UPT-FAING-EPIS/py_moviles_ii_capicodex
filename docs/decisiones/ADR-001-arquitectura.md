# ADR-001 · Arquitectura de la aplicación GameOn Network

- **Estado:** aceptada
- **Fecha:** 2026-09-04
- **Decidido por:** GameOn Team

## Contexto

GameOn Network es una aplicación móvil Flutter que consume servicios remotos de Supabase y Firebase e integra geolocalización, Google Maps, notificaciones, reservas, perfiles y chat. El proyecto ya contaba con una estructura funcional basada en `models`, `viewmodels`, `services` y `views`; sin embargo, el `HomeViewModel` consultaba directamente a Supabase. Esa dependencia hacía difícil probar la lógica de presentación sin infraestructura real.

El equipo está conformado por tres integrantes y el horizonte académico es de cinco sprints. Se necesita una arquitectura que permita crecer sin introducir una cantidad desproporcionada de capas.

## Alternativas consideradas

| Alternativa | Ventajas | Desventajas | Adecuación al proyecto |
|---|---|---|---|
| MVC clásico | Simple y conocido | Facilita controladores con demasiadas responsabilidades y acoplamiento a datos | Insuficiente |
| MVVM + Repository + dominio ligero | ViewModels testeables, separación clara, proporcional al tamaño del equipo | Genera más archivos y exige disciplina | **Adecuada** |
| Clean Architecture completa | Máxima separación y escalabilidad | Sobrecarga estructural para el alcance actual y tres integrantes | Desproporcionada |

## Decisión

Se adopta **MVVM + Repository con una capa de dominio ligera**, organizada por funcionalidad.

Para la funcionalidad vertical `Visualizar instalaciones deportivas` se aplican las siguientes reglas:

1. La vista no contiene llamadas directas a Supabase.
2. El ViewModel depende únicamente de `InstitucionesRepository`, definido por el dominio.
3. El DTO `InstitucionDeportivaDto` y la entidad `InstitucionDeportiva` son clases diferentes.
4. El paso de DTO a entidad se realiza mediante `InstitucionDeportivaMapper`.
5. La implementación concreta del repositorio y el datasource pertenecen a la capa `data`.
6. El ensamblado de dependencias se realiza en `core/di/home_dependencies.dart`.
7. La lógica de estado de interfaz utiliza `Loading`, `Success`, `Empty` y `ErrorState`.

## Consecuencias

### Positivas

- El `HomeViewModel` puede probarse sin emulador y sin Supabase real.
- Cambiar Supabase por otro backend afecta principalmente la capa `data`.
- La interfaz de dominio estabiliza el contrato que consume la presentación.
- Los estados de interfaz se vuelven explícitos y verificables.

### Negativas

- Aumenta el número de archivos de la funcionalidad.
- El equipo debe revisar imports y evitar saltarse el repositorio.
- Requiere mantener el mapeo DTO ↔ entidad cuando cambie el backend.

## Costo de revertir

Medio durante los primeros sprints y alto a partir del sprint 3, debido a que nuevas funcionalidades tenderán a reutilizar este patrón.
