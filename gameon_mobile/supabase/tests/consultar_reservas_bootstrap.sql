-- Solo base aislada; reproduce el contrato de gestor_actual de US-20.
create schema auth;
create role authenticated;
create role anon;
create function auth.uid() returns uuid language sql stable as $$
  select nullif(current_setting('request.jwt.claim.sub', true), '')::uuid;
$$;
create table public.usuarios_instalaciones(id integer primary key, auth_id uuid, estado integer);
create function public.gestor_actual() returns integer
language sql stable security definer set search_path = '' as $$
  select id from public.usuarios_instalaciones
  where auth_id = auth.uid() and estado = 1 limit 1;
$$;
create table public.instituciones_deportivas(id integer primary key, usuario_instalacion_id integer);
create table public.areas_deportivas(id integer primary key, institucion_deportiva_id integer);
create table public.reservas(
  id integer primary key, area_deportiva_id integer, id_usuario integer,
  fecha date, hora_inicio time, hora_fin time, estado varchar,
  monto_pagado numeric, metodo_pago varchar, culqi_charge_id varchar
);
insert into public.usuarios_instalaciones values
  (1, '00000000-0000-0000-0000-000000000001', 1),
  (2, '00000000-0000-0000-0000-000000000002', 1),
  (3, '00000000-0000-0000-0000-000000000003', 0);
insert into public.instituciones_deportivas values (1,1),(2,2),(3,1);
insert into public.areas_deportivas values (10,1),(20,2),(30,3);
insert into public.reservas values
  (1,10,100,'2026-11-12','09:00','10:00','confirmada',50,'paypal','privado'),
  (2,20,200,'2026-11-12','10:00','11:00','pendiente',null,null,'privado'),
  (3,30,300,'2026-11-13','11:00','12:00','cancelada',50,'paypal','privado');
