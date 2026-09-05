# Refinamiento de historias de los Sprints 1 y 2

## Criterios INVEST

| Historia | Independiente | Negociable | Valiosa | Estimable | Pequeña | Verificable | Resultado |
|---|---|---|---|---|---|---|---|
| US-01 Registro con correo | Sí | Sí | Sí | Sí | Sí, 5 puntos | Sí | Cumple |
| US-02 Inicio de sesión | Sí | Sí | Sí | Sí | Sí, 3 puntos | Sí | Cumple |
| US-03 Lista de instalaciones | Sí | Sí | Sí | Sí | Sí, 5 puntos | Sí | Cumple |
| US-04 Detalle de instalación | Sí | Sí | Sí | Sí | Sí, 3 puntos | Sí | Cumple |
| US-05 Filtro por deporte | Sí | Sí | Sí | Sí | Sí, 3 puntos | Sí | Cumple |

## Decisiones del refinamiento

### US-01 Registro con correo

La historia incluye validación local, rechazo de correos duplicados y mensajes seguros. El envío de un enlace de verificación se mantiene como una historia separada para que US-01 conserve un tamaño abordable.

### US-02 Inicio de sesión

La historia cubre autenticación por correo y contraseña. La recuperación de contraseña corresponde a US-29 y no forma parte del Sprint 1.

### US-03 Lista de instalaciones

La lista muestra nombre, deporte principal, imagen referencial y distancia cuando la ubicación está disponible. Incluye los estados con datos, vacío, sin conexión y error del servidor.

### US-04 Detalle de instalación

El detalle contiene dirección, deportes, horarios, servicios, tarifa y fotografías. La reserva se implementará en historias posteriores.

### US-05 Filtro por deporte

La historia permite seleccionar un deporte y limpiar el filtro. Los filtros por precio, distancia y disponibilidad se mantienen separados para evitar una historia de 13 puntos o más.

## Dependencias identificadas

- US-01 y US-02 dependen de TD-01 para la estructura inicial de la aplicación y del servicio.
- US-03, US-04 y US-05 dependen de TD-02 para el acceso a datos y el comportamiento sin conexión.
- US-04 requiere que US-03 permita seleccionar una instalación.
- US-05 reutiliza la lista implementada por US-03.
