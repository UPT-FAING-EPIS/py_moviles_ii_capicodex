-- WARNING: This schema is for context only and is not meant to be run.
-- Table order and constraints may not be valid for execution.

CREATE TABLE public.amistades (
  id integer NOT NULL DEFAULT nextval('amistades_id_seq'::regclass),
  usuario_solicitante_id integer NOT NULL,
  usuario_receptor_id integer NOT NULL,
  estado character varying NOT NULL DEFAULT 'pendiente'::character varying,
  fecha_solicitud timestamp without time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
  fecha_respuesta timestamp without time zone,
  CONSTRAINT amistades_pkey PRIMARY KEY (id),
  CONSTRAINT amistades_ibfk_1 FOREIGN KEY (usuario_solicitante_id) REFERENCES public.usuarios_deportistas(id),
  CONSTRAINT amistades_ibfk_2 FOREIGN KEY (usuario_receptor_id) REFERENCES public.usuarios_deportistas(id)
);
CREATE TABLE public.areas_deportivas (
  id integer NOT NULL DEFAULT nextval('areas_deportivas_id_seq'::regclass),
  institucion_deportiva_id integer NOT NULL,
  deporte_id integer NOT NULL,
  nombre_area character varying NOT NULL,
  descripcion text,
  capacidad_jugadores integer,
  tarifa_por_hora numeric NOT NULL,
  estado character varying DEFAULT 'activa'::character varying,
  imagen_area character varying,
  creado_en timestamp without time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT areas_deportivas_pkey PRIMARY KEY (id),
  CONSTRAINT areas_deportivas_ibfk_1 FOREIGN KEY (institucion_deportiva_id) REFERENCES public.instituciones_deportivas(id),
  CONSTRAINT areas_deportivas_ibfk_2 FOREIGN KEY (deporte_id) REFERENCES public.deportes(id)
);
CREATE TABLE public.areas_horarios (
  id integer NOT NULL DEFAULT nextval('areas_horarios_id_seq'::regclass),
  area_deportiva_id integer NOT NULL,
  dia character varying NOT NULL,
  hora_apertura time without time zone NOT NULL,
  hora_cierre time without time zone NOT NULL,
  disponible smallint DEFAULT 1,
  CONSTRAINT areas_horarios_pkey PRIMARY KEY (id),
  CONSTRAINT areas_horarios_ibfk_1 FOREIGN KEY (area_deportiva_id) REFERENCES public.areas_deportivas(id)
);
CREATE TABLE public.deportes (
  id integer NOT NULL DEFAULT nextval('deportes_id_seq'::regclass),
  nombre character varying NOT NULL,
  CONSTRAINT deportes_pkey PRIMARY KEY (id)
);
CREATE TABLE public.equipo_miembros (
  id integer NOT NULL DEFAULT nextval('equipo_miembros_id_seq'::regclass),
  equipo_id integer NOT NULL,
  usuario_id integer NOT NULL,
  rol character varying NOT NULL DEFAULT 'miembro'::character varying,
  fecha_union timestamp without time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT equipo_miembros_pkey PRIMARY KEY (id),
  CONSTRAINT equipo_miembros_ibfk_1 FOREIGN KEY (equipo_id) REFERENCES public.equipos(id),
  CONSTRAINT equipo_miembros_ibfk_2 FOREIGN KEY (usuario_id) REFERENCES public.usuarios_deportistas(id)
);
CREATE TABLE public.equipos (
  id integer NOT NULL DEFAULT nextval('equipos_id_seq'::regclass),
  nombre character varying NOT NULL,
  descripcion text,
  deporte_id integer NOT NULL,
  creador_id integer NOT NULL,
  limite_miembros integer NOT NULL DEFAULT 10,
  privado smallint NOT NULL DEFAULT 0,
  estado smallint NOT NULL DEFAULT 1,
  creado_en timestamp without time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT equipos_pkey PRIMARY KEY (id),
  CONSTRAINT equipos_ibfk_1 FOREIGN KEY (deporte_id) REFERENCES public.deportes(id),
  CONSTRAINT equipos_ibfk_2 FOREIGN KEY (creador_id) REFERENCES public.usuarios_deportistas(id)
);
CREATE TABLE public.horarios_atencion (
  id integer NOT NULL DEFAULT nextval('horarios_atencion_id_seq'::regclass),
  institucion_deportiva_id integer NOT NULL,
  dia character varying NOT NULL,
  hora_apertura time without time zone NOT NULL,
  hora_cierre time without time zone NOT NULL,
  CONSTRAINT horarios_atencion_pkey PRIMARY KEY (id),
  CONSTRAINT horarios_atencion_ibfk_1 FOREIGN KEY (institucion_deportiva_id) REFERENCES public.instituciones_deportivas(id)
);
CREATE TABLE public.instalaciones_ocupaciones (
  id integer NOT NULL DEFAULT nextval('instalaciones_ocupaciones_id_seq'::regclass),
  institucion_deportiva_id integer NOT NULL,
  fecha date NOT NULL,
  hora_inicio time without time zone NOT NULL,
  hora_fin time without time zone NOT NULL,
  tipo_ocupacion character varying NOT NULL,
  estado character varying DEFAULT 'reservado'::character varying,
  usuario_reserva_id integer,
  equipo_local_id integer,
  equipo_visitante_id integer,
  torneo_partido_id integer,
  torneo_id integer,
  descripcion text,
  costo numeric DEFAULT 0.00,
  creado_por_usuario_id integer NOT NULL,
  fecha_creacion timestamp without time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
  ultima_actualizacion timestamp without time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
  trial454 character,
  CONSTRAINT instalaciones_ocupaciones_pkey PRIMARY KEY (id),
  CONSTRAINT ocupaciones_ibfk_1 FOREIGN KEY (institucion_deportiva_id) REFERENCES public.instituciones_deportivas(id),
  CONSTRAINT ocupaciones_ibfk_2 FOREIGN KEY (usuario_reserva_id) REFERENCES public.usuarios_deportistas(id),
  CONSTRAINT ocupaciones_ibfk_3 FOREIGN KEY (equipo_local_id) REFERENCES public.equipos(id),
  CONSTRAINT ocupaciones_ibfk_4 FOREIGN KEY (equipo_visitante_id) REFERENCES public.equipos(id),
  CONSTRAINT ocupaciones_ibfk_5 FOREIGN KEY (torneo_partido_id) REFERENCES public.torneos_partidos(id),
  CONSTRAINT ocupaciones_ibfk_6 FOREIGN KEY (torneo_id) REFERENCES public.torneos(id),
  CONSTRAINT ocupaciones_ibfk_7 FOREIGN KEY (creado_por_usuario_id) REFERENCES public.usuarios_deportistas(id)
);
CREATE TABLE public.instituciones_deportes (
  institucion_deportiva_id integer NOT NULL,
  deporte_id integer NOT NULL,
  CONSTRAINT instituciones_deportes_pkey PRIMARY KEY (institucion_deportiva_id, deporte_id),
  CONSTRAINT instituciones_deportes_ibfk_1 FOREIGN KEY (institucion_deportiva_id) REFERENCES public.instituciones_deportivas(id),
  CONSTRAINT instituciones_deportes_ibfk_2 FOREIGN KEY (deporte_id) REFERENCES public.deportes(id)
);
CREATE TABLE public.instituciones_deportivas (
  id integer NOT NULL DEFAULT nextval('instituciones_deportivas_id_seq'::regclass),
  usuario_instalacion_id integer NOT NULL,
  nombre character varying NOT NULL,
  ruc character varying,
  direccion character varying NOT NULL,
  latitud numeric NOT NULL,
  longitud numeric NOT NULL,
  imagen character varying,
  tarifa numeric NOT NULL,
  calificacion numeric DEFAULT 0.00,
  telefono character varying NOT NULL,
  email character varying NOT NULL,
  descripcion text,
  estado smallint NOT NULL DEFAULT 1,
  creado_en timestamp without time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
  fecha_registro timestamp without time zone,
  CONSTRAINT instituciones_deportivas_pkey PRIMARY KEY (id),
  CONSTRAINT instituciones_deportivas_ibfk_1 FOREIGN KEY (usuario_instalacion_id) REFERENCES public.usuarios_instalaciones(id)
);
CREATE TABLE public.password_recovery_tokens (
  id integer NOT NULL DEFAULT nextval('password_recovery_tokens_id_seq'::regclass),
  user_type character varying NOT NULL,
  user_id integer NOT NULL,
  email character varying NOT NULL,
  token character varying NOT NULL,
  expires_at timestamp without time zone NOT NULL,
  used smallint NOT NULL DEFAULT 0,
  created_at timestamp without time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
  used_at timestamp without time zone,
  CONSTRAINT password_recovery_tokens_pkey PRIMARY KEY (id)
);
CREATE TABLE public.reservas (
  id integer NOT NULL DEFAULT nextval('reservas_id_seq'::regclass),
  id_usuario integer NOT NULL,
  area_deportiva_id integer NOT NULL,
  fecha date NOT NULL,
  hora_inicio time without time zone NOT NULL,
  hora_fin time without time zone NOT NULL,
  estado character varying NOT NULL DEFAULT 'pendiente'::character varying,
  creado_en timestamp without time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
  culqi_charge_id character varying,
  culqi_order_id character varying,
  monto_pagado numeric,
  metodo_pago character varying DEFAULT 'culqi'::character varying,
  paypal_payment_id character varying,
  paypal_payer_id character varying,
  paypal_order_id text,
  paypal_capture_id text,
  fecha_pago timestamp with time zone,
  CONSTRAINT reservas_pkey PRIMARY KEY (id),
  CONSTRAINT reservas_ibfk_area FOREIGN KEY (area_deportiva_id) REFERENCES public.areas_deportivas(id),
  CONSTRAINT reservas_ibfk_usuario FOREIGN KEY (id_usuario) REFERENCES public.usuarios_deportistas(id)
);
CREATE TABLE public.solicitudes_registro (
  id integer NOT NULL DEFAULT nextval('solicitudes_registro_id_seq'::regclass),
  nombre_institucion character varying NOT NULL,
  ruc character varying NOT NULL,
  email character varying NOT NULL,
  password character varying NOT NULL,
  documento_path character varying NOT NULL,
  estado character varying NOT NULL DEFAULT 'pendiente'::character varying,
  motivo_rechazo text,
  fecha_solicitud timestamp without time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
  fecha_revision timestamp without time zone,
  revisado_por integer,
  CONSTRAINT solicitudes_registro_pkey PRIMARY KEY (id)
);
CREATE TABLE public.torneos (
  id integer NOT NULL DEFAULT nextval('torneos_id_seq'::regclass),
  nombre character varying NOT NULL,
  descripcion text,
  deporte_id integer NOT NULL,
  organizador_tipo character varying NOT NULL,
  organizador_id integer NOT NULL,
  institucion_sede_id integer NOT NULL,
  max_equipos integer NOT NULL DEFAULT 16,
  equipos_inscritos integer NOT NULL DEFAULT 0,
  fecha_inicio date NOT NULL,
  fecha_fin date,
  fecha_inscripcion_inicio date NOT NULL,
  fecha_inscripcion_fin date NOT NULL,
  estado character varying NOT NULL DEFAULT 'proximo'::character varying,
  modalidad character varying NOT NULL DEFAULT 'eliminacion_simple'::character varying,
  premio_1 character varying,
  premio_2 character varying,
  premio_3 character varying,
  costo_inscripcion numeric DEFAULT 0.00,
  imagen_torneo character varying,
  creado_en timestamp without time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
  actualizado_en timestamp without time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT torneos_pkey PRIMARY KEY (id),
  CONSTRAINT torneos_ibfk_1 FOREIGN KEY (deporte_id) REFERENCES public.deportes(id),
  CONSTRAINT torneos_ibfk_2 FOREIGN KEY (institucion_sede_id) REFERENCES public.instituciones_deportivas(id)
);
CREATE TABLE public.torneos_equipos (
  id integer NOT NULL DEFAULT nextval('torneos_equipos_id_seq'::regclass),
  torneo_id integer NOT NULL,
  equipo_id integer NOT NULL,
  inscrito_por_usuario_id integer NOT NULL,
  fecha_inscripcion timestamp without time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
  estado_inscripcion character varying DEFAULT 'pendiente'::character varying,
  metodo_pago character varying,
  transaction_id character varying,
  payer_id character varying,
  monto_pagado numeric DEFAULT 0.00,
  comentarios text,
  CONSTRAINT torneos_equipos_pkey PRIMARY KEY (id),
  CONSTRAINT torneos_equipos_ibfk_1 FOREIGN KEY (torneo_id) REFERENCES public.torneos(id),
  CONSTRAINT torneos_equipos_ibfk_2 FOREIGN KEY (equipo_id) REFERENCES public.equipos(id),
  CONSTRAINT torneos_equipos_ibfk_3 FOREIGN KEY (inscrito_por_usuario_id) REFERENCES public.usuarios_deportistas(id)
);
CREATE TABLE public.torneos_estadisticas (
  id integer NOT NULL DEFAULT nextval('torneos_estadisticas_id_seq'::regclass),
  torneo_id integer NOT NULL,
  equipo_id integer NOT NULL,
  partidos_jugados integer DEFAULT 0,
  partidos_ganados integer DEFAULT 0,
  partidos_perdidos integer DEFAULT 0,
  partidos_empatados integer DEFAULT 0,
  goles_favor integer DEFAULT 0,
  goles_contra integer DEFAULT 0,
  puntos integer DEFAULT 0,
  posicion_final integer,
  CONSTRAINT torneos_estadisticas_pkey PRIMARY KEY (id),
  CONSTRAINT torneos_estadisticas_ibfk_1 FOREIGN KEY (torneo_id) REFERENCES public.torneos(id),
  CONSTRAINT torneos_estadisticas_ibfk_2 FOREIGN KEY (equipo_id) REFERENCES public.equipos(id)
);
CREATE TABLE public.torneos_partidos (
  id integer NOT NULL DEFAULT nextval('torneos_partidos_id_seq'::regclass),
  torneo_id integer NOT NULL,
  area_deportiva_id integer,
  equipo_local_id integer,
  equipo_visitante_id integer,
  fase character varying NOT NULL,
  numero_partido integer,
  ronda integer,
  descripcion_partido character varying,
  numero_grupo integer,
  fecha_partido timestamp without time zone NOT NULL,
  resultado_local integer,
  resultado_visitante integer,
  equipo_ganador_id integer,
  estado_partido character varying DEFAULT 'programado'::character varying,
  observaciones text,
  creado_en timestamp without time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT torneos_partidos_pkey PRIMARY KEY (id),
  CONSTRAINT torneos_partidos_ibfk_1 FOREIGN KEY (torneo_id) REFERENCES public.torneos(id),
  CONSTRAINT torneos_partidos_ibfk_2 FOREIGN KEY (equipo_local_id) REFERENCES public.equipos(id),
  CONSTRAINT torneos_partidos_ibfk_3 FOREIGN KEY (equipo_visitante_id) REFERENCES public.equipos(id),
  CONSTRAINT torneos_partidos_ibfk_4 FOREIGN KEY (equipo_ganador_id) REFERENCES public.equipos(id),
  CONSTRAINT torneos_partidos_ibfk_area FOREIGN KEY (area_deportiva_id) REFERENCES public.areas_deportivas(id)
);
CREATE TABLE public.torneos_partidos_asistencias (
  id integer NOT NULL DEFAULT nextval('torneos_partidos_asistencias_id_seq'::regclass),
  partido_id integer NOT NULL,
  jugador_id integer NOT NULL,
  equipo_id integer NOT NULL,
  gol_id integer,
  CONSTRAINT torneos_partidos_asistencias_pkey PRIMARY KEY (id),
  CONSTRAINT torneos_partidos_asistencias_ibfk_1 FOREIGN KEY (partido_id) REFERENCES public.torneos_partidos(id),
  CONSTRAINT torneos_partidos_asistencias_ibfk_2 FOREIGN KEY (jugador_id) REFERENCES public.usuarios_deportistas(id),
  CONSTRAINT torneos_partidos_asistencias_ibfk_3 FOREIGN KEY (equipo_id) REFERENCES public.equipos(id),
  CONSTRAINT torneos_partidos_asistencias_ibfk_4 FOREIGN KEY (gol_id) REFERENCES public.torneos_partidos_goleadores(id)
);
CREATE TABLE public.torneos_partidos_estadisticas (
  id integer NOT NULL DEFAULT nextval('torneos_partidos_estadisticas_id_seq'::regclass),
  partido_id integer NOT NULL,
  equipo_id integer NOT NULL,
  goles integer DEFAULT 0,
  tarjetas_amarillas integer DEFAULT 0,
  tarjetas_rojas integer DEFAULT 0,
  mvp_jugador_id integer,
  CONSTRAINT torneos_partidos_estadisticas_pkey PRIMARY KEY (id),
  CONSTRAINT torneos_partidos_estadisticas_ibfk_1 FOREIGN KEY (partido_id) REFERENCES public.torneos_partidos(id),
  CONSTRAINT torneos_partidos_estadisticas_ibfk_2 FOREIGN KEY (equipo_id) REFERENCES public.equipos(id),
  CONSTRAINT torneos_partidos_estadisticas_ibfk_3 FOREIGN KEY (mvp_jugador_id) REFERENCES public.usuarios_deportistas(id)
);
CREATE TABLE public.torneos_partidos_goleadores (
  id integer NOT NULL DEFAULT nextval('torneos_partidos_goleadores_id_seq'::regclass),
  partido_id integer NOT NULL,
  jugador_id integer NOT NULL,
  equipo_id integer NOT NULL,
  minuto_gol integer,
  tipo_gol character varying DEFAULT 'normal'::character varying,
  CONSTRAINT torneos_partidos_goleadores_pkey PRIMARY KEY (id),
  CONSTRAINT torneos_partidos_goleadores_ibfk_1 FOREIGN KEY (partido_id) REFERENCES public.torneos_partidos(id),
  CONSTRAINT torneos_partidos_goleadores_ibfk_2 FOREIGN KEY (jugador_id) REFERENCES public.usuarios_deportistas(id),
  CONSTRAINT torneos_partidos_goleadores_ibfk_3 FOREIGN KEY (equipo_id) REFERENCES public.equipos(id)
);
CREATE TABLE public.usuarios_deportes (
  usuario_id integer NOT NULL,
  deporte_id integer NOT NULL,
  CONSTRAINT usuarios_deportes_pkey PRIMARY KEY (usuario_id, deporte_id),
  CONSTRAINT usuarios_deportes_ibfk_1 FOREIGN KEY (usuario_id) REFERENCES public.usuarios_deportistas(id),
  CONSTRAINT usuarios_deportes_ibfk_2 FOREIGN KEY (deporte_id) REFERENCES public.deportes(id)
);
CREATE TABLE public.usuarios_deportistas (
  id integer NOT NULL DEFAULT nextval('usuarios_deportistas_id_seq'::regclass),
  nombre character varying NOT NULL DEFAULT '0'::character varying,
  apellidos character varying,
  telefono character varying,
  fecha_nacimiento date,
  genero character varying NOT NULL,
  nivel_habilidad character varying NOT NULL,
  estado smallint NOT NULL DEFAULT 1,
  creado_en timestamp without time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
  auth_id uuid DEFAULT gen_random_uuid() UNIQUE,
  fcm_token character varying,
  username character varying NOT NULL UNIQUE CHECK (username::text ~ '^[a-z0-9_]{3,30}$'::text),
  imagen_perfil text,
  CONSTRAINT usuarios_deportistas_pkey PRIMARY KEY (id),
  CONSTRAINT usuarios_deportistas_auth_id_fkey FOREIGN KEY (auth_id) REFERENCES auth.users(id)
);
CREATE TABLE public.usuarios_instalaciones (
  id integer NOT NULL DEFAULT nextval('usuarios_instalaciones_id_seq'::regclass),
  username character varying NOT NULL,
  password character varying NOT NULL DEFAULT md5(((gen_random_uuid())::text || (clock_timestamp())::text)),
  estado smallint NOT NULL DEFAULT 1,
  created_at timestamp without time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
  tipo_usuario character varying,
  culqi_public_key character varying,
  culqi_secret_key character varying,
  culqi_enabled smallint DEFAULT 0,
  paypal_client_id character varying,
  paypal_client_secret character varying,
  paypal_enabled smallint DEFAULT 0,
  paypal_sandbox smallint DEFAULT 1,
  auth_id uuid UNIQUE,
  nombre_negocio character varying,
  ruc character varying,
  CONSTRAINT usuarios_instalaciones_pkey PRIMARY KEY (id),
  CONSTRAINT usuarios_instalaciones_auth_id_fkey FOREIGN KEY (auth_id) REFERENCES auth.users(id)
);