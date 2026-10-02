# GameOn Network

Aplicación móvil Flutter orientada a deportistas amateur para descubrir instalaciones deportivas, consultar disponibilidad y gestionar actividades y reservas.

Proyecto académico del curso **SI-988 · Soluciones Móviles II** de la Escuela Profesional de Ingeniería de Sistemas de la Universidad Privada de Tacna.

## Estado de la entrega

La rama `release/sprint-1-presentacion` consolida la versión preparada para la demostración del Sprint 1.

El flujo mínimo que debe demostrarse es:

1. Abrir GameOn Network.
2. Ir a **Perfil**.
3. Seleccionar **Registrarme / Iniciar sesión**.
4. Crear una cuenta con nombre, correo y contraseña.
5. Verificar que el usuario queda autenticado y se carga su perfil.
6. Cerrar sesión.
7. Iniciar sesión nuevamente con la misma cuenta.
8. Regresar a la pantalla principal.

Este flujo corresponde a:

- **US-01:** registro mediante correo.
- **US-02:** inicio de sesión mediante correo y contraseña.
- **TD-01:** arquitectura base, configuración de entornos y CI.

## Tecnologías

- Flutter / Dart
- Provider
- Supabase Auth y base de datos
- Firebase Core, Cloud Firestore, Firebase Messaging y Storage
- Google Maps / Geolocator
- GitHub Actions

## Requisitos

- Flutter estable compatible con Dart `^3.8.1`
- Android SDK y un emulador o dispositivo Android
- Variables de entorno de Supabase proporcionadas por el equipo

## Configuración

Clonar el repositorio y cambiar a la rama de presentación:

```bash
git clone https://github.com/UPT-FAING-EPIS/py_moviles_ii_capicodex.git
cd py_moviles_ii_capicodex
git switch release/sprint-1-presentacion
flutter pub get
```

La aplicación no guarda las credenciales de Supabase en el repositorio. Para ejecutarla se deben inyectar en tiempo de compilación:

```bash
flutter run \
  --dart-define=SUPABASE_URL=<URL_REAL> \
  --dart-define=SUPABASE_ANON_KEY=<ANON_KEY_REAL>
```

Para compilar el APK:

```bash
flutter build apk --debug \
  --dart-define=SUPABASE_URL=<URL_REAL> \
  --dart-define=SUPABASE_ANON_KEY=<ANON_KEY_REAL>
```

## Verificación antes de presentar

Ejecutar:

```bash
flutter clean
flutter pub get
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
flutter build apk --debug
```

Además, probar manualmente el flujo **registro → perfil → cerrar sesión → login → home** en Android.

## Organización principal

```text
lib/
├── core/
├── features/
│   ├── chat/
│   ├── home/
│   ├── notificaciones/
│   ├── perfil/
│   └── reservas/
├── firebase_options.dart
└── main.dart

docs/
├── arquitectura/
├── decisiones/
├── equipo/
├── evidencias/
└── sprints/
```

## Seguridad

Las credenciales de Supabase se inyectan mediante `--dart-define` y no deben versionarse. Las configuraciones cliente de Firebase incluidas en Flutter no sustituyen las reglas de seguridad del backend; Firestore y Storage deben permanecer protegidos mediante reglas adecuadas.

## Equipo

| Integrante | Rol Scrum | Área principal |
|---|---|---|
| Sebastián Fuentes | Product Owner / Developer | Desarrollo móvil y UI/UX |
| Gabriela Gutierrez | Scrum Master / Developer | Backend y base de datos |
| Mayra Chire | Developer | Pruebas e integración |

## Presentación

El guion de demostración y la lista de verificación se encuentran en:

`docs/sprints/PRESENTACION_SPRINT1.md`
