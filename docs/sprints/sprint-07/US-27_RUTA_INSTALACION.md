# US-27 · Abrir la ruta hacia una instalación

La ficha de la instalación, accesible desde Inicio, Mapa y Favoritos, incluye la opción **Cómo llegar**.

1. Selecciona **Cómo llegar**. GameOn comprueba que las coordenadas registradas sean finitas y estén dentro de los rangos geográficos. El par `0, 0` indica una ubicación sin configurar.
2. El diálogo explica que se compartirán las coordenadas de la instalación y que Google Maps puede usar la ubicación del dispositivo para calcular el recorrido. **Cancelar** o cerrar el diálogo conserva la ficha.
3. **Abrir ruta** entrega al sistema un enlace HTTPS de indicaciones. Se abre Google Maps si el sistema tiene la aplicación asociada al enlace. El navegador puede abrir el mismo enlace cuando Maps no está instalado. Si falla la apertura, se muestra un mensaje y se permite volver a intentar.

El enlace contiene únicamente `api=1` y `destination=<latitud>,<longitud>`. GameOn deja que Google Maps determine el origen de acuerdo con sus propios permisos. El flujo funciona también para visitantes.

## Verificación

Desde `gameon_mobile`:

```sh
flutter test test/features/home/ruta_instalacion_test.dart
```

En Android, abre la ficha de una instalación con ubicación registrada. Pulsa **Cómo llegar** y cancela para comprobar que sigues en GameOn. Repite el flujo, confirma y comprueba que el destino coincide con el de la ficha. Vuelve a GameOn con el botón Atrás del dispositivo.
