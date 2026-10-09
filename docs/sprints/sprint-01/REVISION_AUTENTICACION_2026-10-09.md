# Revisión de autenticación y persistencia para el seguimiento del Sprint 1

Fecha de revisión: 9 de octubre de 2026  
Responsable de la revisión: Gabriela Gutierrez Mamani

## Alcance revisado

Se revisó la rama `release/sprint-1-presentacion` y el archivo recibido `gameon_mobile-master (1).zip`. La revisión fue estática: no se ejecutó la aplicación, no se creó una cuenta de prueba y no se verificó una instalación Android.

## Hallazgos comprobables

| Aspecto | Evidencia en la rama de entrega | Estado de la revisión |
| --- | --- | --- |
| Registro e inicio de sesión | `lib/features/perfil/viewmodels/perfil_viewmodel.dart` llama a `supabase.auth.signUp` y `supabase.auth.signInWithPassword`. | Implementación presente; flujo real pendiente de prueba. |
| Restauración de sesión | `lib/features/perfil/views/session_gate.dart` espera a `sesionRestaurada`; `lib/features/perfil/services/session_local_storage.dart` guarda solo el ID del usuario, mientras Supabase administra el token. | Implementación presente; persistencia tras cerrar y abrir la app pendiente de prueba. |
| Inicio de servicios | `lib/main.dart` inicializa Supabase y luego intenta inicializar Firebase. | Configuración presente; requiere valores reales de entorno para ejecutar. |
| Pruebas y análisis de CI | `.github/workflows/ci.yml` ejecuta `flutter analyze` y `flutter test` sobre archivos del módulo `home`; `test/` contiene una prueba de `home_viewmodel`. | El flujo de autenticación no tiene una prueba automatizada identificada en esta rama. |
| Código recibido en ZIP | El ZIP contiene una aplicación Flutter GameOn, pero los archivos de autenticación examinados difieren de los de la rama de entrega y el ZIP no incluye historial Git. | Sirve como referencia de código, pero no demuestra autoría, integración ni resultado de pruebas. |

## Verificación pendiente

1. Ejecutar `flutter pub get`, `flutter analyze` y `flutter test` en la rama de entrega, y conservar los resultados.
2. Configurar los valores públicos necesarios de Supabase mediante `--dart-define`, sin publicar credenciales privadas.
3. Probar en Android: registro, cierre de sesión, inicio de sesión y restauración de sesión después de reiniciar la app.
4. Registrar el resultado de cada paso en el issue o PR correspondiente, con capturas que no muestren contraseñas.
5. Acordar con el equipo si se agregan pruebas de autenticación y si CI debe analizar más archivos de la aplicación.

Esta revisión documenta lo observado el 9 de octubre. No sustituye los avances individuales ni la captura del tablero correspondientes a una sesión de daily anterior.
