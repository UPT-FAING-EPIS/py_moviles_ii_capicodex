# US-18 · Registrar deportes preferidos para personalizar la búsqueda

**Fecha:** 05 de noviembre de 2026  
**Issue:** [#54](https://github.com/UPT-FAING-EPIS/py_moviles_ii_capicodex/issues/54) · Sprint 06  
**Responsable asignada:** Mayra Chire (`mayrafc`)  
**Épica:** Perfil  
**Tipo:** Historia de Usuario  
**Puntos de Historia:** 3  
**Valor:** 3 / 5  
**Riesgo:** 2 / 5  
**Dato Personal:** Sí: preferencias deportivas  
**Seguridad:** Sí: privacidad del perfil  
**Product Goal:** [Product Goal - GameOn Network](https://github.com/UPT-FAING-EPIS/py_moviles_ii_capicodex/blob/docs/taller-03/docs/producto/PRODUCT_GOAL.md)

---

## 1. Declaración de la Historia de Usuario

> **Como** usuario deportista de GameOn Network,  
> **quiero** registrar mis deportes preferidos en mi perfil,  
> **para** personalizar la búsqueda de instalaciones deportivas según mis preferencias sin afectar mis demás datos personales.

---

## 2. Trabajo Realizado y Análisis de la Solución

Se implementó y verificó la historia de usuario **US-18**, permitiendo al deportista seleccionar, eliminar y guardar sus deportes preferidos tanto desde la vista principal de su perfil (`PerfilAuthenticatedView`) como desde la edición de perfil (`EditPerfilView`), y emplear dichas preferencias para filtrar de manera personalizada las instalaciones en la pantalla de inicio (`HomeView`).

### 2.1 Selección, Eliminación y Guardado Aislado de Deportes Preferidos
1. **Persistencia aislada en `usuarios_deportes` (`EditPerfilViewModel.saveDeportesFavoritos`):**
   - Normaliza y deduplica la lista de deportes seleccionados preservando el orden elegido por el usuario.
   - Resuelve primero los identificadores en el catálogo `deportes` antes de eliminar las asociaciones previas del usuario en `usuarios_deportes` (`usuario_id = usuarioId`), garantizando que un fallo de red o del servidor no provoque pérdida de las preferencias previamente registradas.
   - No realiza escrituras ni modificaciones sobre `usuarios_deportistas` cuando el usuario únicamente gestiona sus deportes, preservando intactos `nombre`, `apellidos`, `username`, `telefono`, `fecha_nacimiento`, `genero`, `nivel_habilidad`, `imagen_perfil` y `fcm_token`.
2. **Actualización inmutable del estado en memoria (`UsuarioDeportista.copyWith` y `PerfilViewModel.updateDeportesFavoritosLocal`):**
   - Incorpora `copyWith` en `UsuarioDeportista` y `updateDeportesFavoritosLocal` en `PerfilViewModel`, actualizando de forma inmediata `deportesFavoritos` y notificando a los suscriptores sin alterar ningún otro atributo del perfil.
3. **Gestión directa desde el Perfil y Edición de Perfil:**
   - En `PerfilAuthenticatedView`, la sección **Mis Deportes** permanece siempre visible para el usuario autenticado, mostrando el botón **Registrar** / **Gestionar** que abre `DeportesSelectorSheet` para agregar o quitar deportes directamente.
   - En `EditPerfilView`, si el usuario únicamente modifica sus deportes favoritos (seleccionando en `DeportesSelectorSheet` o eliminando chips en `DeportesSelectorCard`), el guardado actualiza exclusivamente `usuarios_deportes` sin tocar `usuarios_deportistas`.

### 2.2 Personalización de la Búsqueda en Inicio (`HomeView` y `HomeViewModel`)
- `HomeViewModel.fetchInstituciones` enriquece las instalaciones activas con sus deportes asociados desde `instituciones_deportes` y `deportes`.
- `HomeTabScaffold` presenta chips de filtro rápido con los `deportesFavoritos` del usuario autenticado (`Todos` + cada deporte preferido), permitiendo filtrar la búsqueda de canchas e instalaciones según sus preferencias deportivas sin alterar el buscador por texto ni el acceso al mapa.

---

## 3. Criterios de Aceptación Verificados

| Escenario | Criterio de Aceptación | Estado | Evidencia |
|---|---|:---:|---|
| **Escenario 1: Seleccionar y guardar deportes sin afectar otros datos** | El usuario selecciona nuevos deportes y los guarda en `usuarios_deportes` sin modificar `usuarios_deportistas`. | **Verificado** | `test/features/perfil/deportes_preferidos_test.dart` (`saveDeportesFavoritos selecciona y guarda deportes en usuarios_deportes sin tocar usuarios_deportistas`). |
| **Escenario 2: Eliminar deportes individuales o todos** | El usuario elimina uno o todos sus deportes seleccionados y guarda el cambio conservando intacta su información personal. | **Verificado** | `test/features/perfil/deportes_preferidos_test.dart` (`saveDeportesFavoritos permite eliminar todos los deportes sin insertar ni afectar otros datos` y prueba de interfaz en `EditPerfilView`). |
| **Escenario 3: Protección ante fallos de red** | Si falla la consulta al catálogo de deportes, no se eliminan los deportes previamente registrados por el usuario. | **Verificado** | `test/features/perfil/deportes_preferidos_test.dart` (`si falla la consulta del catálogo de deportes no elimina los deportes previos del usuario`). |
| **Escenario 4: Gestión en interfaz (`EditPerfilView` y `PerfilAuthenticatedView`)** | El usuario selecciona, elimina y confirma sus deportes en la UI viendo reflejados sus cambios sin alterar nombre, usuario, teléfono, género ni nivel. | **Verificado** | `test/features/perfil/deportes_preferidos_test.dart` (pruebas de widgets para `EditPerfilView` y `PerfilAuthenticatedView`). |

---

## 4. Tratamiento de Datos Personales y Seguridad

1. **Privacidad del Perfil:** Las preferencias deportivas se asocian estrictamente al `usuario_id` del deportista autenticado en `usuarios_deportes`.
2. **Integridad de Datos Personales:** La actualización de preferencias deportivas está desacoplada de los campos de identidad y contacto en `usuarios_deportistas`, evitando sobrescrituras accidentales.
3. **Sin Credenciales ni Secretos Expuestos:** Se emplea únicamente el cliente configurado de Supabase sin claves privadas ni tokens hardcodeados.

---

## 5. Definition of Done (DoD)

- [x] **Criterios de aceptación verificados:** El usuario selecciona, elimina y guarda deportes sin afectar otros datos.
- [x] **Compila sin errores:** `flutter test` y `flutter analyze` ejecutados sin fallos.
- [x] **Pruebas y análisis estático en verde:** Suite completa de pruebas unitarias y de widgets en verde (48/48 tests pasando) y `flutter analyze` con 0 advertencias en todos los módulos modificados.
- [x] **Sin credenciales ni secretos:** Código y pruebas libres de secretos o tokens reales.
- [x] **Rama vinculada:** `feature/US-18-deportes-preferidos`.
- [ ] **Pull Request aprobado por una persona distinta del autor:** Listo para revisión en GitHub.
- [x] **Documentación actualizada:** Registrada en `docs/sprints/sprint-06/US-18_DEPORTES_PREFERIDOS.md`.

