# language: es
Característica: Detalle de una instalación deportiva
  Como deportista amateur
  Quiero consultar el detalle de una instalación
  Para decidir si satisface mis necesidades

  Escenario: El detalle tiene datos
    Dado que el usuario seleccionó una instalación disponible
    Cuando abre su detalle
    Entonces ve nombre, dirección, deportes, horarios, servicios, tarifa y fotografías
    Y puede volver a la lista sin perder su posición

  Escenario: El detalle no tiene información complementaria
    Dado que la instalación existe pero no tiene fotografías ni servicios registrados
    Cuando el usuario abre su detalle
    Entonces ve los datos básicos disponibles
    Y ve una indicación clara en los campos sin información

  Escenario: El detalle se abre sin conexión
    Dado que el dispositivo no tiene conexión a internet
    Y el detalle fue guardado en una sesión anterior
    Cuando el usuario abre la instalación
    Entonces ve la información guardada
    Y ve un aviso de que los datos podrían estar desactualizados
    Y ve un botón para reintentar

  Escenario: El servidor falla al cargar el detalle
    Dado que el servicio responde con un error 500
    Cuando el usuario abre el detalle de una instalación
    Entonces ve un mensaje de error comprensible sin detalles técnicos
    Y ve un botón para reintentar
