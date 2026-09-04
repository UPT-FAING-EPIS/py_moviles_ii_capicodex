# GameOn Mobile

App móvil Flutter para reservas deportivas y pagos seguros con PayPal.

## Características principales
- Reserva de canchas y áreas deportivas.
- Gestión de horarios y disponibilidad.
- Pago seguro integrado con PayPal (WebView embebido).
- Conversión automática de moneda (Soles a USD).
- Estados de reserva: Pendiente, Confirmada, En curso, Completada.
- Persistencia de datos de pago (monto, método, fecha, orderId).
- Experiencia de usuario moderna y profesional.

## Estructura del proyecto
- `lib/features/home/`: Pantallas y lógica de inicio.
- `lib/features/reservas/`: Lógica de reservas, ViewModels y vistas.
- `lib/features/reservas/viewmodels/`: MVVM para reservas y pagos.
- `lib/features/reservas/views/`: UI de resumen, calendario y pago.
- `lib/features/reservas/services/paypal_service.dart`: Integración con PayPal vía Supabase Edge Functions.
- `android/`, `ios/`, `web/`, `windows/`, `macos/`, `linux/`: Soporte multiplataforma.

## Instalación y ejecución
1. Instala Flutter: https://docs.flutter.dev/get-started/install
2. Clona el repositorio:
	```sh
	git clone https://github.com/nkmelndz/gameon_mobile.git
	cd gameon_mobile
	```
3. Instala dependencias:
	```sh
	flutter pub get
	```
4. Ejecuta la app:
	```sh
	flutter run --debug
	```

## Configuración de PayPal
- Sandbox: Usar credenciales de prueba en Edge Function.
- Producción: Cambiar a credenciales live y endpoint real.

## Notas técnicas
- El flujo de pago se realiza dentro de la app usando WebView.
- El overlay de carga cubre toda la pantalla durante el procesamiento de pago y reserva.
- El tipo de cambio es configurable (por defecto 3.7).

## Contacto y soporte
- Autor: 
- Issues y soporte: Usar el sistema de issues de GitHub.

---
¡Gracias por usar GameOn Mobile!
