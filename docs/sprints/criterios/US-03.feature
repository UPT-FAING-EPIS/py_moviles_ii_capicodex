# language: es
Característica: Lista de instalaciones deportivas
  Como deportista amateur
  Quiero ver instalaciones deportivas disponibles
  Para elegir una opción adecuada

  Escenario: La lista tiene instalaciones
    Dado que el usuario ha iniciado sesión
    Y existen al menos 3 instalaciones disponibles
    Cuando abre la pantalla de instalaciones
    Entonces ve el nombre, deporte principal, imagen y distancia de cada instalación
    Y la lista carga en menos de 1,5 segundos con 100 elementos

  Escenario: La lista está vacía
    Dado que el usuario ha iniciado sesión
    Y no existen instalaciones disponibles
    Cuando abre la pantalla de instalaciones
    Entonces ve un mensaje que explica que no hay resultados
    Y ve una acción para cambiar la búsqueda o actualizar

  Escenario: La lista se abre sin conexión
    Dado que el dispositivo no tiene conexión a internet
    Y existe una lista guardada de la última sesión
    Cuando abre la pantalla de instalaciones
    Entonces ve las instalaciones guardadas
    Y ve un aviso de que los datos podrían estar desactualizados
    Y ve un botón para reintentar

  Escenario: El servidor falla al cargar la lista
    Dado que el servicio de instalaciones responde con un error 500
    Cuando el usuario abre la pantalla de instalaciones
    Entonces ve un mensaje de error comprensible sin detalles técnicos
    Y ve un botón para reintentar
