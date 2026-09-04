# GameOn Network

Aplicación móvil orientada a deportistas amateur que busca facilitar la búsqueda de instalaciones deportivas, consulta de disponibilidad, coordinación de actividades y gestión de reservas desde un solo lugar.

Proyecto desarrollado para el curso **SI-988 · Soluciones Móviles II** de la Escuela Profesional de Ingeniería de Sistemas de la Universidad Privada de Tacna.

---

## Información del proyecto

| Campo | Detalle |
|---|---|
| Proyecto | GameOn Network |
| Equipo | GameOn Team |
| Curso | SI-988 · Soluciones Móviles II |
| Universidad | Universidad Privada de Tacna |
| Facultad | Facultad de Ingeniería |
| Escuela | Ingeniería de Sistemas |
| Modalidad | Aplicación móvil |
| Estado | En desarrollo |

---

## Problema

Actualmente, los deportistas amateur pueden encontrar dificultades para localizar instalaciones deportivas, conocer su disponibilidad, comparar alternativas y coordinar actividades.

La información suele encontrarse dispersa entre redes sociales, llamadas telefónicas, grupos de mensajería, recomendaciones y consultas directas a los establecimientos.

Esto puede generar pérdida de tiempo, dificultad para coordinar partidos y poca visibilidad sobre las instalaciones deportivas disponibles.

---

## Propuesta de solución

**GameOn Network** busca centralizar la información relacionada con actividades e instalaciones deportivas mediante una aplicación móvil.

La aplicación permitirá progresivamente:

- Visualizar instalaciones deportivas cercanas.
- Buscar espacios según el deporte.
- Consultar información de las instalaciones.
- Revisar horarios y disponibilidad.
- Gestionar reservas.
- Consultar las reservas realizadas.
- Recibir notificaciones y recordatorios.
- Facilitar la coordinación entre deportistas.

Como funcionalidad futura se contempla permitir la creación de partidos abiertos para encontrar otros jugadores interesados en participar.

---

## ¿Por qué una aplicación móvil?

GameOn Network requiere capacidades propias de los dispositivos móviles que permiten mejorar la experiencia del usuario.

Entre ellas se consideran:

- Geolocalización.
- Visualización de instalaciones cercanas mediante mapas.
- Notificaciones.
- Acceso desde cualquier lugar.
- Uso durante el desplazamiento del usuario.
- Posible integración futura con cámara y otras capacidades del dispositivo.

Estas características permiten justificar el desarrollo de una aplicación móvil frente a una solución exclusivamente web.

---

## Público objetivo

El público objetivo principal está compuesto por:

**Deportistas amateur de Tacna** que practican fútbol, vóley, básquet, pádel u otras disciplinas y requieren encontrar instalaciones o coordinar actividades deportivas.

También se considera como usuario del sistema al:

**Administrador de una instalación deportiva**, encargado de registrar y gestionar información relacionada con sus espacios deportivos.

---

## MVP

Para mantener un alcance viable durante el curso, el producto mínimo viable contempla inicialmente:

1. Registro e inicio de sesión.
2. Perfil básico del usuario.
3. Visualización de instalaciones deportivas.
4. Geolocalización y mapa.
5. Búsqueda y filtros por deporte.
6. Información de cada instalación.
7. Consulta de disponibilidad.
8. Reserva de instalaciones.
9. Consulta de reservas realizadas.
10. Notificaciones y recordatorios.

Las funcionalidades adicionales serán evaluadas de acuerdo con el avance de los sprints.

---

## Equipo Scrum

| Integrante | Rol Scrum | Área principal |
|---|---|---|
| Sebastián Fuentes | Product Owner | Desarrollo móvil y diseño UI/UX |
| Gabriela Gutierrez | Scrum Master | Backend y base de datos |
| Mayra Chire | Developer | Pruebas e integración |

---

## Organización del repositorio

```text
pro_moviles_ii_capicodex/
│
├── .github/
│   └── workflows/
│       └── ci.yml
│
├── app/
│
├── docs/
│   ├── arquitectura/
│   ├── decisiones/
│   ├── entorno/
│   ├── equipo/
│   │   ├── EQUIPO.md
│   │   └── ACUERDOS.md
│   │
│   ├── evidencias/
│   │   └── S01/
│   │
│   ├── producto/
│   │   ├── LEAN_CANVAS.md
│   │   ├── VALIDACION.md
│   │   └── VISION.md
│   │
│   └── sprints/
│
├── src/
├── test/
├── .gitignore
├── CONTRIBUTING.md
└── README.md