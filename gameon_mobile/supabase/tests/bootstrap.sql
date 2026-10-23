-- Esquema mínimo aislado para comprobar el contrato usado por la app.
-- Ejecutar únicamente en una base de pruebas vacía.
create schema auth;
create role authenticated;
create function auth.uid() returns uuid language sql stable as $$
  select nullif(current_setting('request.jwt.claim.sub', true), '')::uuid;
$$;
create table public.usuarios_deportistas(id bigint primary key, auth_id uuid not null);
create table public.areas_horarios(
  area_deportiva_id bigint, dia text, disponible integer,
  hora_apertura time, hora_cierre time
);
create table public.reservas(
  id bigint primary key, id_usuario bigint not null,
  area_deportiva_id bigint not null, fecha date not null,
  hora_inicio time not null, hora_fin time not null, estado text not null,
  creado_en timestamp default now(), monto_pagado numeric, metodo_pago text
);
