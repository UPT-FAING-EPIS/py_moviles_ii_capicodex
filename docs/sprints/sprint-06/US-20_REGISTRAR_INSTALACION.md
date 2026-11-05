# US-20 – Como administrador quiero registrar una instalación para publicarla en el catálogo (#18)

## Contexto
- **Épica**: Administración
- **Sprint**: 6
- **Puntos**: 8 | **Valor**: 4 / 5 | **Riesgo**: 5 / 5
- **Dato personal**: Sí: contacto del administrador (`telefono`, `email`)
- **Seguridad**: Sí: rol y autorización (`usuario_instalacion_id` / `public.gestor_actual()`)

## Criterios de aceptación verificados
- **Solo un administrador autorizado registra datos obligatorios y ubicación válida**:
  - Se verifica que el administrador cuente con identificador de gestor autorizado (`gestorId > 0`) tanto en la vista (`_centroDialog` en `GestorView`) como en la capa de servicio (`GestorService.validarDatosInstalacion` y `GestorService.guardarCentro`), además de la política RLS `gestor_crea_centros` en Supabase (`usuario_instalacion_id = (select public.gestor_actual())`).
  - Se validan todos los datos obligatorios antes de publicar la instalación en `instituciones_deportivas`: nombre del centro, dirección, tarifa por hora mayor a 0, datos de contacto del administrador (teléfono y correo electrónico con formato válido) y RUC de 11 dígitos numéricos cuando se consigna.
  - Se valida que la ubicación geográfica (`latitud` en `[-90, 90]` y `longitud` en `[-180, 180]`, distinta de `(0, 0)`) haya sido marcada válidamente en el selector de mapa (`CentroUbicacionPicker`).

## Componentes actualizados
- `gameon_mobile/lib/features/gestor/services/gestor_service.dart`
- `gameon_mobile/lib/features/gestor/views/gestor_view.dart`
- `gameon_mobile/test/features/gestor/registro_instalacion_test.dart`
