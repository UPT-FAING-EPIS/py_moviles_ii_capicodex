# language: es
Característica: Filtro de instalaciones por deporte
  Como deportista amateur
  Quiero filtrar instalaciones por deporte
  Para encontrar espacios adecuados a la actividad que practicaré

  Escenario: El filtro devuelve instalaciones
    Dado que el usuario ha iniciado sesión
    Y existen instalaciones para el deporte "fútbol"
    Cuando selecciona el filtro "fútbol"
    Entonces ve únicamente instalaciones que ofrecen fútbol
    Y la pantalla muestra el filtro activo

  Escenario: El filtro no devuelve resultados
    Dado que no existen instalaciones para el deporte seleccionado
    Cuando el usuario aplica el filtro
    Entonces ve un mensaje que explica que no hay coincidencias
    Y ve una acción para limpiar el filtro

  Escenario: El filtro se aplica sin conexión
    Dado que el dispositivo no tiene conexión a internet
    Y existe una lista guardada de la última sesión
    Cuando el usuario selecciona un deporte
    Entonces la aplicación filtra los datos guardados
    Y avisa que los resultados podrían estar desactualizados

  Escenario: El servidor falla al filtrar
    Dado que el servicio de búsqueda responde con un error 500
    Cuando el usuario aplica un filtro por deporte
    Entonces ve un mensaje de error comprensible sin detalles técnicos
    Y ve un botón para reintentar
