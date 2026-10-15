# US-04 · Detalle de una instalación deportiva

Fecha: 15 de octubre de 2026  
Issue: #30 · Sprint 02  
Responsable asignada: mayrafc

## Trabajo realizado

Se implementó y completó la historia de usuario **US-04**, permitiendo a los deportistas amateurs consultar el detalle completo de una instalación deportiva para decidir si les conviene.

1. **Datos completos de la instalación**:
   - Visualización de nombre, dirección, tarifa, calificación, información de contacto y descripción.
   - Visualización de deportes disponibles mediante chips temáticos.
   - Visualización de horarios de atención por día.
   - Incorporación de galería de fotografías de la instalación y sus áreas deportivas.
   - Incorporación de catálogo de servicios e instalaciones complementarias (iluminación nocturna, estacionamiento, vestuarios, wifi, cafetería, césped sintético).
   - Retorno a la lista de instalaciones (`Navigator.pop`) conservando la posición de desplazamiento previa.

2. **Manejo de instalaciones sin información complementaria**:
   - Cuando una instalación no tiene fotografías ni servicios registrados, se muestran claramente los datos básicos disponibles y mensajes informativos claros ("Sin fotografías registradas", "Sin servicios registrados", "Sin horarios registrados", "Sin deportes registrados") sin romper la interfaz.

3. **Lectura y persistencia sin conexión (Caché local)**:
   - Persistencia local de los datos de la instalación (horarios, deportes, servicios, fotografías y marca temporal) mediante `SharedPreferences`.
   - Si el dispositivo pierde la conexión pero el detalle fue guardado en una sesión previa, se recupera y muestra la información guardada.
   - Se muestra un banner visible de advertencia informando que los datos podrían estar desactualizados con un botón de reintento.

4. **Manejo de errores del servidor (500 o fallos de red sin caché)**:
   - Captura de fallos remotos presentando un mensaje amigable y comprensible para el usuario, sin exponer trazas técnicas, códigos 500 ni detalles internos de la base de datos.
   - Botón de reintento para volver a consultar la información.

## Criterios de Aceptación Verificados (US-04.feature)

| Escenario | Criterio | Estado | Evidencia |
|---|---|---|---|
| Escenario 1: El detalle tiene datos | Dado que el usuario seleccionó una instalación disponible, ve nombre, dirección, deportes, horarios, servicios, tarifa y fotografías, y puede volver a la lista sin perder su posición. | Verificado | `test/features/home/institucion_detail_view_test.dart` (Escenario 1 en verde). |
| Escenario 2: El detalle no tiene información complementaria | Cuando no tiene fotografías ni servicios registrados, ve datos básicos e indicación clara en campos sin información. | Verificado | `test/features/home/institucion_detail_view_test.dart` (Escenario 2 en verde). |
| Escenario 3: El detalle se abre sin conexión | Cuando no hay conexión y el detalle fue guardado previamente, ve la información guardada, un aviso de datos desactualizados y un botón para reintentar. | Verificado | `test/features/home/institucion_detail_view_test.dart` y `institucion_detail_viewmodel_test.dart` en verde. |
| Escenario 4: El servidor falla al cargar el detalle | Ante error 500 o fallo remoto, ve un mensaje de error comprensible sin detalles técnicos y un botón para reintentar. | Verificado | `test/features/home/institucion_detail_view_test.dart` (Escenario 4 en verde). |

## Definition of Done

- [x] Criterios de aceptación verificados
- [x] Compila sin errores (`flutter build apk --debug`)
- [x] Pruebas y análisis estático en verde (9 pruebas en verde, `flutter analyze` sin advertencias en archivos de la historia)
- [x] Sin credenciales ni secretos
- [x] Rama vinculada (`feature/US-04-detalle-instalacion`)
- [ ] Pull Request aprobado por una persona distinta del autor
- [x] Documentación actualizada
