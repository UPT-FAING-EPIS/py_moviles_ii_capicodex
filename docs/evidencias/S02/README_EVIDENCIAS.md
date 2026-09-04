# Evidencias reales pendientes de capturar · Taller 02

Los archivos de código y documentación ya están preparados. Las siguientes evidencias deben generarse mediante ejecución real; no deben sustituirse por imágenes simuladas.

## E01 · Prueba de humo Flutter

Ejecutar un mapa/geolocalización en Flutter sobre Android y guardar captura o video como:

`01_prueba_humo_flutter.png`

## E02 · Prueba de humo React Native

Ejecutar el prototipo equivalente en React Native sobre Android y guardar:

`02_prueba_humo_react_native.png`

## E03 · Funcionalidad vertical en dispositivo/emulador

Capturar la pantalla de instalaciones deportivas funcionando:

`03_funcionalidad_vertical_success.png`

También registrar los estados cuando sea posible:

- `04_estado_loading.png`
- `05_estado_empty.png`
- `06_estado_error_retry.png`

## E04 · Pruebas del ViewModel

Ejecutar:

```bash
flutter test test/features/home/viewmodels/home_viewmodel_test.dart
```

Guardar salida en:

`salidas/flutter_test_viewmodel.txt`

Y una captura opcional:

`07_pruebas_viewmodel.png`

## E05 · CI en verde

Después del push, guardar captura de GitHub Actions:

`08_ci_verde.png`

## E06 · Protección de main

Guardar captura de Settings → Branches/Rulesets donde se observe PR obligatorio, CI requerida y al menos una aprobación:

`09_main_protegida.png`

## E07 · Pull Request y tag

Agregar al informe la URL del PR hacia `develop` y la URL del tag `taller-02`.
