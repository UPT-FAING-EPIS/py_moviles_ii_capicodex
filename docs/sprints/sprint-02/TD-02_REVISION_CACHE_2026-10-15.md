# TD-02 · Revisión de la lectura de instalaciones y caché

Fecha: 15 de octubre de 2026  
Issue: #2 · Sprint 02  
Responsable asignada: LuzkalidGM

## Trabajo realizado

Se revisó estáticamente el flujo de lectura de instalaciones para identificar el punto de incorporación de la caché requerida por TD-02. No se ejecutó la aplicación ni se comprobó el comportamiento en Android durante esta revisión.

## Evidencia revisada

| Rama y archivo | Observación |
|---|---|
| `main`: `gameon_mobile/lib/features/home/viewmodels/home_viewmodel.dart` | `fetchInstituciones()` consulta directamente `instituciones_deportivas` en Supabase, filtra `estado = 1`, transforma la respuesta y propaga los errores. En este método no se identificó lectura ni escritura de una caché persistente. |
| `release/sprint-1-presentacion`: `lib/features/home/data/repositories/instituciones_repository_impl.dart` | Existe un repositorio que delega en la fuente remota y convierte DTO a entidad. En la implementación examinada no hay una fuente local ni recuperación de la última respuesta válida. |
| `release/sprint-1-presentacion`: `lib/features/home/viewmodels/home_viewmodel.dart` | Maneja carga, resultado vacío, éxito y error con una acción de reintento. El reintento por sí solo no aporta lectura sin conexión. |

Las ramas utilizan estructuras diferentes. Antes de implementar se debe definir la base de integración con el equipo para evitar modificar una copia que no se use en la entrega.

## Siguiente trabajo para el issue #2

1. Incorporar una fuente local persistente detrás del repositorio de instalaciones.
2. Guardar únicamente los datos del catálogo necesarios para lectura; no guardar tokens ni datos de autenticación dentro de esta caché.
3. Reemplazar la última respuesta almacenada solo después de recibir y validar una respuesta remota correcta. Una lista vacía válida también debe reemplazar los datos anteriores.
4. Ante un error remoto, recuperar la última respuesta válida. Si no existe caché, conservar el estado de error con reintento.
5. Permitir actualizar la información al recuperar conexión y distinguir en la interfaz cuándo se muestran datos guardados.

## Comprobaciones pendientes

| Caso | Resultado esperado | Estado |
|---|---|---|
| Primera carga con conexión | Se muestran instalaciones y se persiste la respuesta válida. | Pendiente |
| Reinicio de la app sin conexión después de una carga correcta | Se recupera el catálogo guardado. | Pendiente |
| Primera apertura sin conexión y sin caché | Se muestra un error recuperable con reintento. | Pendiente |
| Fallo remoto después de una carga correcta | La última respuesta válida se conserva. | Pendiente |
| Respuesta remota vacía válida | Se muestra el estado vacío y se actualiza la caché. | Pendiente |
| Recuperación de conexión y reintento | Se muestra y guarda la nueva respuesta. | Pendiente |
| Datos locales dañados | El fallo se maneja sin cerrar la aplicación. | Pendiente |

## Alcance del avance

Este commit aporta revisión técnica y criterios de verificación al issue #2. No implementa todavía la caché, no acredita pruebas funcionales y no completa la Definition of Done. No modifica las historias asignadas a otros integrantes.
