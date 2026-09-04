# language: es
Característica: Registro con correo
  Como deportista amateur
  Quiero crear una cuenta con mi correo
  Para acceder a las funciones de GameOn Network

  Escenario: Registro exitoso
    Dado que el correo "gabriela@example.com" no está registrado
    Y la contraseña cumple la política de seguridad
    Cuando la persona envía su nombre, correo y contraseña
    Entonces el servicio crea la cuenta
    Y la aplicación muestra la confirmación sin exponer la contraseña

  Escenario: Correo ya registrado
    Dado que el correo "gabriela@example.com" ya pertenece a una cuenta
    Cuando la persona intenta registrarse con ese correo
    Entonces la aplicación no crea una cuenta duplicada
    Y muestra un mensaje que permite iniciar sesión o recuperar el acceso

  Escenario: Registro sin conexión
    Dado que el dispositivo no tiene conexión a internet
    Cuando la persona intenta registrar la cuenta
    Entonces la aplicación conserva los datos no sensibles del formulario
    Y muestra una opción para reintentar sin guardar la contraseña

  Escenario: Error del servidor durante el registro
    Dado que el servicio de registro responde con un error 500
    Cuando la persona envía un formulario válido
    Entonces la aplicación muestra un mensaje comprensible sin detalles técnicos
    Y permite reintentar la operación
