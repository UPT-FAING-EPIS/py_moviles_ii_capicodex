# Presentación del Sprint 1 · GameOn Network

## Objetivo

Demostrar el incremento funcional comprometido en el Sprint 1 y evidenciar su correspondencia con el Sprint Board y los dailys.

## Historias comprometidas

### US-01 · Registro con correo

Demostrar que una persona puede ingresar nombre, correo y contraseña y crear una cuenta válida.

Criterios que deben observarse durante la demo:

- El formulario valida campos obligatorios.
- El correo debe tener formato válido.
- La contraseña no se muestra en texto plano.
- El registro exitoso crea la cuenta y carga el perfil.
- Ante un error, la contraseña no se persiste en el repositorio ni se expone en mensajes.

### US-02 · Inicio de sesión

Demostrar que un usuario registrado puede autenticarse mediante correo y contraseña.

Criterios que deben observarse:

- Las credenciales válidas generan una sesión.
- Las credenciales inválidas muestran un mensaje genérico.
- La aplicación no revela si falló específicamente el correo o la contraseña.
- El usuario autenticado puede volver a la pantalla principal.

### TD-01 · Arquitectura base, entornos y CI

Evidenciar:

- Proyecto Flutter estructurado por funcionalidades.
- Dependencias instaladas mediante `flutter pub get`.
- Variables sensibles de Supabase inyectadas mediante `--dart-define`.
- GitHub Actions ejecutando análisis, pruebas y compilación.
- Pull Request como mecanismo de integración.

## Guion de demostración

1. Mostrar brevemente el Sprint Board.
2. Indicar que el Sprint 1 prioriza US-01, US-02 y TD-01.
3. Ejecutar la aplicación en emulador o teléfono Android.
4. Mostrar la pantalla principal de GameOn Network.
5. Entrar a **Perfil**.
6. Pulsar **Registrarme / Iniciar sesión**.
7. Abrir **Crear cuenta**.
8. Registrar un usuario de prueba.
9. Mostrar el perfil autenticado.
10. Cerrar sesión.
11. Volver a **Registrarme / Iniciar sesión**.
12. Iniciar sesión con la cuenta creada.
13. Regresar al Home y mostrar que la sesión está activa.
14. Mostrar el PR y el resultado de CI.

## Datos de prueba recomendados

Usar un correo exclusivo para la demostración y no reutilizar contraseñas personales.

Ejemplo:

```text
Nombre: Usuario Demo Sprint 1
Correo: demo.gameon.<fecha>@example.com
Contraseña: una contraseña de prueba que cumpla la política
```

## Evidencias mínimas

Tomar capturas de:

1. Sprint Board antes de la presentación.
2. App abierta en Android.
3. Formulario de registro.
4. Registro exitoso / perfil autenticado.
5. Cierre de sesión.
6. Inicio de sesión exitoso.
7. Home después del login.
8. GitHub Actions en verde.
9. Pull Request de la rama de presentación.

No capturar contraseñas ni exponer credenciales administrativas del backend.

## Comandos previos

```bash
flutter clean
flutter pub get
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
flutter build apk --debug
```

Para ejecutar la versión de presentación en Android:

```bash
flutter run -d emulator-5554 --android-skip-build-dependency-validation
```

## Criterio para mover tarjetas a Listo

No mover una historia a **Listo** solo porque existe código. Debe cumplirse su Definition of Done: criterios verificados, compilación correcta, análisis y pruebas en verde, sin secretos expuestos, rama/PR vinculados, revisión por otra persona y documentación actualizada.

## Mensaje de presentación

“En el Sprint 1 priorizamos el acceso del usuario y la base técnica de la aplicación. El incremento permite registrar una cuenta con correo, autenticar a un usuario existente y mantener la sesión mediante el servicio de autenticación. El proyecto se encuentra estructurado en Flutter por funcionalidades y la integración se verifica mediante GitHub Actions y Pull Requests.”
