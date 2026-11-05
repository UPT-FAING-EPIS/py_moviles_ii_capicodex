# US-17 y US-19: Perfil y favoritos

## Cambios entregados

- El formulario de edición conserva las validaciones existentes y exige una confirmación explícita cuando cambia el usuario, teléfono o fecha de nacimiento.
- La migración `202611050001_perfil_y_favoritos.sql` registra cada actualización de perfil con los campos modificados.
- Desde el detalle de una instalación, una persona autenticada puede agregarla o quitarla de sus favoritos.
- La pantalla **Perfil > Mis favoritos** muestra únicamente las instalaciones de la cuenta autenticada.

## Base de datos

Antes de publicar la app, ejecutar la migración en el proyecto Supabase correspondiente. Esta crea las tablas `actualizaciones_perfil` e `instituciones_favoritas`, sus políticas RLS y el trigger de auditoría. Las políticas vinculan cada registro a `auth.uid()`, por lo que ninguna cuenta puede consultar o alterar los favoritos de otra.

## Verificación

Ejecutado desde `gameon_mobile`:

```text
flutter analyze
flutter test
```

Las pruebas terminaron correctamente. El análisis conserva avisos informativos preexistentes en otras áreas del proyecto.
