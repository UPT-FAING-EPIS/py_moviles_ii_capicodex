# language: es
Característica: Inicio de sesión
  Como usuario registrado
  Quiero iniciar sesión con mi correo y contraseña
  Para consultar instalaciones y gestionar mis reservas

  Escenario: Inicio de sesión exitoso
    Dado que existe una cuenta activa para "gabriela@example.com"
    Cuando la persona ingresa credenciales válidas
    Entonces el servicio devuelve una sesión válida
    Y la aplicación abre la pantalla principal

  Escenario: Credenciales inválidas
    Dado que existe una cuenta activa para "gabriela@example.com"
    Cuando la persona ingresa una contraseña incorrecta
    Entonces el servicio rechaza el acceso
    Y la aplicación muestra un mensaje que no revela cuál credencial falló

  Escenario: Inicio de sesión sin conexión
    Dado que el dispositivo no tiene conexión a internet
    Cuando la persona intenta iniciar sesión
    Entonces la aplicación no envía datos incompletos
    Y muestra un aviso de conexión con una opción para reintentar

  Escenario: Error del servidor durante el inicio de sesión
    Dado que el servicio de autenticación responde con un error 500
    Cuando la persona envía credenciales con formato válido
    Entonces la aplicación muestra un mensaje comprensible sin detalles técnicos
    Y no almacena la contraseña
