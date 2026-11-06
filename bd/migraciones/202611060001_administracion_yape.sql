-- Aplicar después de las migraciones de gestor móvil. Ejecutar en una transacción.
-- ADM se concede manualmente con el UUID de auth.users, nunca desde el cliente.
begin;

create table if not exists public.roles_aplicacion (
  auth_id uuid primary key references auth.users(id) on delete cascade,
  rol text not null check (rol = 'ADM'),
  creado_en timestamptz not null default now()
);
alter table public.roles_aplicacion enable row level security;
revoke all on public.roles_aplicacion from anon, authenticated;

create or replace function public.es_admin() returns boolean
language sql stable security definer set search_path = '' as $$
  select exists(select 1 from public.roles_aplicacion
    where auth_id = (select auth.uid()) and rol = 'ADM');
$$;
revoke all on function public.es_admin() from public;
grant execute on function public.es_admin() to authenticated;

-- Los gestores anteriores conservan estado=1. Desde esta migración, alta=pendiente.
create or replace function public.crear_gestor_movil()
returns trigger language plpgsql security definer set search_path = '' as $$
begin
  if new.raw_user_meta_data->>'tipo_cuenta' = 'gestor' then
    insert into public.usuarios_instalaciones
      (username, auth_id, tipo_usuario, estado, nombre_negocio, ruc)
    values ('movil_' || left(replace(new.id::text, '-', ''), 32), new.id,
      'gestor', 0,
      nullif(left(trim(new.raw_user_meta_data->>'nombre_institucion'), 100), ''),
      nullif(left(trim(new.raw_user_meta_data->>'ruc'), 11), ''));
  end if;
  return new;
end;
$$;
-- El inventario de tablas no incluye triggers: asegurar que el alta nueva use
-- la función que deja la solicitud en estado pendiente.
drop trigger if exists crear_gestor_movil_auth on auth.users;
create trigger crear_gestor_movil_auth after insert on auth.users
  for each row execute function public.crear_gestor_movil();

create or replace function public.solicitar_gestor_actual(p_nombre text, p_ruc text)
returns integer language plpgsql security definer set search_path = '' as $$
declare v_id integer;
begin
  if (select auth.uid()) is null then raise exception 'Inicia sesión' using errcode='42501'; end if;
  if length(trim(coalesce(p_nombre, ''))) not between 1 and 100
    or coalesce(p_ruc,'') !~ '^[0-9]{11}$' then
    raise exception 'Nombre o RUC inválido' using errcode='22023';
  end if;
  insert into public.usuarios_instalaciones
    (username, auth_id, tipo_usuario, estado, nombre_negocio, ruc)
  values ('movil_' || left(replace((select auth.uid())::text, '-', ''), 32),
    (select auth.uid()), 'gestor', 0, trim(p_nombre), p_ruc)
  on conflict (auth_id) do update set
    nombre_negocio = excluded.nombre_negocio, ruc = excluded.ruc
  where public.usuarios_instalaciones.estado = 0;
  select id into v_id from public.usuarios_instalaciones
    where auth_id = (select auth.uid());
  return v_id;
end;
$$;
revoke all on function public.solicitar_gestor_actual(text,text) from public;
grant execute on function public.solicitar_gestor_actual(text,text) to authenticated;
-- La RPC anterior creaba gestores activos sin revisión; impedir ese bypass.
do $$
begin
  if to_regprocedure('public.registrar_gestor_actual(text,text)') is not null then
    revoke all on function public.registrar_gestor_actual(text,text) from public, authenticated;
  end if;
end;
$$;

create or replace function public.estado_gestor_actual() returns integer
language sql stable security definer set search_path = '' as $$
  select estado from public.usuarios_instalaciones where auth_id = (select auth.uid()) limit 1;
$$;
revoke all on function public.estado_gestor_actual() from public;
grant execute on function public.estado_gestor_actual() to authenticated;

create or replace function public.solicitudes_gestor_actual() returns integer
language sql stable security definer set search_path = '' as $$
  select id from public.usuarios_instalaciones
  where auth_id=(select auth.uid()) and estado=0 limit 1;
$$;
revoke all on function public.solicitudes_gestor_actual() from public;
grant execute on function public.solicitudes_gestor_actual() to authenticated;

create or replace function public.gestor_id_propio() returns integer
language sql stable security definer set search_path = '' as $$
  select id from public.usuarios_instalaciones where auth_id=(select auth.uid()) limit 1;
$$;
revoke all on function public.gestor_id_propio() from public;
grant execute on function public.gestor_id_propio() to authenticated;

create or replace function public.gestor_aprobado(p_id integer) returns boolean
language sql stable security definer set search_path = '' as $$
  select exists(select 1 from public.usuarios_instalaciones
    where id=p_id and estado=1);
$$;
revoke all on function public.gestor_aprobado(integer) from public;
grant execute on function public.gestor_aprobado(integer) to authenticated;

create table if not exists public.gestor_evidencias (
  id bigint generated always as identity primary key,
  gestor_id integer not null references public.usuarios_instalaciones(id) on delete cascade,
  ruta text not null unique,
  creado_en timestamptz not null default now()
);
alter table public.gestor_evidencias enable row level security;
-- Las políticas con estos nombres pueden existir de un intento anterior.
-- Se reemplazan dentro de la misma transacción, sin tocar las evidencias.
drop policy if exists gestor_evidencias_lectura on public.gestor_evidencias;
create policy gestor_evidencias_lectura on public.gestor_evidencias
  for select to authenticated using (public.es_admin() or gestor_id = public.gestor_id_propio());
drop policy if exists gestor_evidencias_alta on public.gestor_evidencias;
create policy gestor_evidencias_alta on public.gestor_evidencias
  for insert to authenticated with check (
    gestor_id = public.solicitudes_gestor_actual()
    and ruta like (select auth.uid())::text || '/%'
    and exists (select 1 from storage.objects where bucket_id = 'gestor-solicitudes' and name = ruta));
grant select, insert on public.gestor_evidencias to authenticated;
grant usage, select on sequence public.gestor_evidencias_id_seq to authenticated;

create or replace function public.limitar_evidencias_gestor() returns trigger
language plpgsql security definer set search_path = '' as $$
begin
  perform pg_advisory_xact_lock(new.gestor_id, 61006);
  if (select count(*) from public.gestor_evidencias where gestor_id=new.gestor_id) >= 3 then
    raise exception 'Máximo tres evidencias por solicitud' using errcode='22023';
  end if;
  return new;
end;
$$;
drop trigger if exists limitar_evidencias_gestor on public.gestor_evidencias;
create trigger limitar_evidencias_gestor before insert on public.gestor_evidencias
  for each row execute function public.limitar_evidencias_gestor();

insert into storage.buckets(id,name,public) values
  ('gestor-solicitudes','gestor-solicitudes',false),
  ('yape-evidencias','yape-evidencias',false)
on conflict (id) do update set public=false;
drop policy if exists gestor_solicitud_subir on storage.objects;
create policy gestor_solicitud_subir on storage.objects for insert to authenticated
  with check (bucket_id='gestor-solicitudes'
    and (storage.foldername(name))[1]=(select auth.uid())::text
    and public.solicitudes_gestor_actual() is not null);
drop policy if exists gestor_solicitud_ver on storage.objects;
create policy gestor_solicitud_ver on storage.objects for select to authenticated
  using (bucket_id='gestor-solicitudes' and
    ((storage.foldername(name))[1]=(select auth.uid())::text or public.es_admin()));
drop policy if exists gestor_solicitud_borrar on storage.objects;
create policy gestor_solicitud_borrar on storage.objects for delete to authenticated
  using (bucket_id='gestor-solicitudes' and
    (storage.foldername(name))[1]=(select auth.uid())::text and
    not exists(select 1 from public.gestor_evidencias e where e.ruta=name));

create or replace function public.solicitudes_gestor() returns jsonb
language plpgsql stable security definer set search_path = '' as $$
declare v_result jsonb;
begin
  if not public.es_admin() then raise exception 'Acceso denegado' using errcode='42501'; end if;
  select coalesce(jsonb_agg(jsonb_build_object(
    'id', g.id, 'nombre', g.nombre_negocio, 'ruc', g.ruc, 'estado', g.estado,
    'evidencias', (select coalesce(jsonb_agg(e.ruta), '[]'::jsonb)
      from public.gestor_evidencias e where e.gestor_id=g.id)
  ) order by g.id desc), '[]'::jsonb) into v_result
  from public.usuarios_instalaciones g where g.estado in (0,-1);
  return v_result;
end;
$$;
revoke all on function public.solicitudes_gestor() from public;
grant execute on function public.solicitudes_gestor() to authenticated;

create or replace function public.resolver_solicitud_gestor(p_id integer, p_aprobar boolean)
returns void language plpgsql security definer set search_path = '' as $$
begin
  if not public.es_admin() then raise exception 'Acceso denegado' using errcode='42501'; end if;
  if p_aprobar and not exists(select 1 from public.gestor_evidencias where gestor_id=p_id) then
    raise exception 'Se requiere al menos una evidencia' using errcode='22023';
  end if;
  update public.usuarios_instalaciones set estado=case when p_aprobar then 1 else -1 end
  where id=p_id and estado=0;
  if not found then raise exception 'Solicitud no pendiente' using errcode='22023'; end if;
end;
$$;
revoke all on function public.resolver_solicitud_gestor(integer,boolean) from public;
grant execute on function public.resolver_solicitud_gestor(integer,boolean) to authenticated;

-- Configuración de cobro por gestor, visible a deportistas autenticados.
create table if not exists public.gestor_cobros (
  gestor_id integer primary key references public.usuarios_instalaciones(id) on delete cascade,
  yape_qr_url text not null,
  yape_titular text not null,
  yape_celular text not null,
  actualizado_en timestamptz not null default now()
);
alter table public.gestor_cobros enable row level security;
drop policy if exists gestor_cobros_ver on public.gestor_cobros;
create policy gestor_cobros_ver on public.gestor_cobros for select to authenticated
  using (public.gestor_aprobado(gestor_id));
drop policy if exists gestor_cobros_crear on public.gestor_cobros;
create policy gestor_cobros_crear on public.gestor_cobros for insert to authenticated
  with check (gestor_id=public.gestor_actual());
drop policy if exists gestor_cobros_editar on public.gestor_cobros;
create policy gestor_cobros_editar on public.gestor_cobros for update to authenticated
  using (gestor_id=public.gestor_actual()) with check (gestor_id=public.gestor_actual());
grant select, insert, update on public.gestor_cobros to authenticated;

create table if not exists public.avisos_reserva (
  id bigint generated always as identity primary key,
  destinatario uuid not null references auth.users(id) on delete cascade,
  reserva_id integer not null references public.reservas(id) on delete cascade,
  mensaje text not null,
  leido boolean not null default false,
  creado_en timestamptz not null default now()
);
alter table public.avisos_reserva enable row level security;
drop policy if exists aviso_propio_ver on public.avisos_reserva;
create policy aviso_propio_ver on public.avisos_reserva for select to authenticated
  using (destinatario=(select auth.uid()));
drop policy if exists aviso_propio_marcar on public.avisos_reserva;
create policy aviso_propio_marcar on public.avisos_reserva for update to authenticated
  using (destinatario=(select auth.uid())) with check (destinatario=(select auth.uid()));
grant select on public.avisos_reserva to authenticated;
grant update(leido) on public.avisos_reserva to authenticated;

alter table public.reservas add column if not exists yape_evidencia_ruta text;
alter table public.reservas add column if not exists yape_monto_esperado numeric(12,2);
-- También protege las reservas creadas por el flujo anterior, si la migración
-- de reprogramación aún no instaló la restricción. El inventario encontró
-- solapamientos históricos (25/09/2025): no se borran ni impiden desplegar.
-- La fecha fija es la fecha de incorporación de esta regla; no usar now() en
-- una restricción parcial porque su predicado debe ser inmutable.
create extension if not exists btree_gist;
do $$
begin
  if not exists (select 1 from pg_constraint
    where conrelid='public.reservas'::regclass and conname='reservas_sin_solapamiento') then
    alter table public.reservas add constraint reservas_sin_solapamiento
      exclude using gist (area_deportiva_id with =,
        tsrange(fecha + hora_inicio, fecha + hora_fin, '[)') with &&)
      where (fecha >= date '2026-11-06' and lower(estado) <> 'cancelada');
  end if;
end;
$$;
-- La política remota select_all_reservas ya da lectura para la agenda y el
-- calendario. Se mantiene sin cambios para no romper el flujo existente.

create or replace function public.puede_ver_yape(p_ruta text) returns boolean
language sql stable security definer set search_path = '' as $$
  select exists(select 1 from public.reservas r
    join public.areas_deportivas a on a.id=r.area_deportiva_id
    join public.instituciones_deportivas i on i.id=a.institucion_deportiva_id
    where r.yape_evidencia_ruta=p_ruta and
      i.usuario_instalacion_id=public.gestor_actual());
$$;
revoke all on function public.puede_ver_yape(text) from public;
grant execute on function public.puede_ver_yape(text) to authenticated;

drop policy if exists yape_evidencia_subir on storage.objects;
create policy yape_evidencia_subir on storage.objects for insert to authenticated
  with check (bucket_id='yape-evidencias'
    and (storage.foldername(name))[1]=(select auth.uid())::text);
drop policy if exists yape_evidencia_ver on storage.objects;
create policy yape_evidencia_ver on storage.objects for select to authenticated
  using (bucket_id='yape-evidencias' and (
    (storage.foldername(name))[1]=(select auth.uid())::text or public.es_admin()
    or public.puede_ver_yape(name)));
drop policy if exists yape_evidencia_borrar on storage.objects;
create policy yape_evidencia_borrar on storage.objects for delete to authenticated
  using (bucket_id='yape-evidencias' and
    (storage.foldername(name))[1]=(select auth.uid())::text and
    not exists(select 1 from public.reservas r where r.yape_evidencia_ruta=name));

create or replace function public.crear_reserva_yape(
  p_area_id integer, p_fecha date, p_inicio time, p_fin time, p_ruta text
) returns integer language plpgsql security definer set search_path = '' as $$
declare v_usuario integer; v_tarifa numeric; v_id integer; v_dia text; v_gestor uuid;
begin
  select id into v_usuario from public.usuarios_deportistas where auth_id=(select auth.uid());
  if v_usuario is null then raise exception 'Inicia sesión como deportista' using errcode='42501'; end if;
  if p_fecha < (now() at time zone 'America/Lima')::date or p_inicio >= p_fin
    or (p_fecha + p_inicio) <= (now() at time zone 'America/Lima') then
    raise exception 'Horario inválido' using errcode='22023';
  end if;
  select a.tarifa_por_hora into v_tarifa from public.areas_deportivas a
    join public.instituciones_deportivas i on i.id=a.institucion_deportiva_id
    join public.gestor_cobros c on c.gestor_id=i.usuario_instalacion_id
    where a.id=p_area_id and lower(a.estado)='activa' and i.estado=1;
  if v_tarifa is null then raise exception 'El centro no configuró Yape' using errcode='22023'; end if;
  if p_ruta not like (select auth.uid())::text || '/%'
    or not exists(select 1 from storage.objects where bucket_id='yape-evidencias' and name=p_ruta) then
    raise exception 'Falta la evidencia del pago' using errcode='22023';
  end if;
  v_dia := (array['domingo','lunes','martes','miércoles','jueves','viernes','sábado'])
    [extract(dow from p_fecha)::integer + 1];
  if not exists(select 1 from public.areas_horarios h where h.area_deportiva_id=p_area_id
    and lower(h.dia) in (v_dia, replace(v_dia,'é','e')) and h.disponible=1
    and h.hora_apertura<=p_inicio and h.hora_cierre>=p_fin) then
    raise exception 'Fuera del horario disponible' using errcode='22023';
  end if;
  perform pg_advisory_xact_lock(p_area_id, p_fecha - date '2000-01-01');
  if exists(select 1 from public.reservas r where r.area_deportiva_id=p_area_id
    and r.fecha=p_fecha and lower(r.estado) <> 'cancelada'
    and r.hora_inicio<p_fin and r.hora_fin>p_inicio) then
    raise exception 'Horario ocupado' using errcode='23P01';
  end if;
  insert into public.reservas(id_usuario,area_deportiva_id,fecha,hora_inicio,hora_fin,
    estado,metodo_pago,yape_evidencia_ruta,yape_monto_esperado)
  values(v_usuario,p_area_id,p_fecha,p_inicio,p_fin,'pendiente','yape',p_ruta,
    round(v_tarifa * (extract(epoch from (p_fin-p_inicio))/3600),2)) returning id into v_id;
  select g.auth_id into v_gestor from public.areas_deportivas a
    join public.instituciones_deportivas i on i.id=a.institucion_deportiva_id
    join public.usuarios_instalaciones g on g.id=i.usuario_instalacion_id
    where a.id=p_area_id;
  insert into public.avisos_reserva(destinatario,reserva_id,mensaje)
  values ((select auth.uid()),v_id,'Enviaste la evidencia Yape. Espera la revisión del gestor.'),
    (v_gestor,v_id,'Nueva reserva Yape pendiente de revisar. Verifica el ingreso en tu cuenta.');
  return v_id;
end;
$$;
revoke all on function public.crear_reserva_yape(integer,date,time,time,text) from public;
grant execute on function public.crear_reserva_yape(integer,date,time,time,text) to authenticated;

create or replace function public.resolver_reserva_yape(p_id integer, p_aprobar boolean)
returns integer language plpgsql security definer set search_path = '' as $$
declare v_usuario integer; v_auth uuid;
begin
  update public.reservas r set estado=case when p_aprobar then 'confirmada' else 'cancelada' end,
    monto_pagado=case when p_aprobar then r.yape_monto_esperado else null end
  from public.areas_deportivas a, public.instituciones_deportivas i
  where r.id=p_id and r.area_deportiva_id=a.id and a.institucion_deportiva_id=i.id
    and i.usuario_instalacion_id=public.gestor_actual()
    and lower(r.estado)='pendiente' and lower(r.metodo_pago)='yape'
  returning r.id_usuario into v_usuario;
  if v_usuario is null then raise exception 'Reserva no pendiente o sin autorización' using errcode='42501'; end if;
  select auth_id into v_auth from public.usuarios_deportistas where id=v_usuario;
  insert into public.avisos_reserva(destinatario,reserva_id,mensaje)
  values (v_auth,p_id,case when p_aprobar then
    'El gestor confirmó tu pago Yape y tu reserva.' else
    'El gestor rechazó la evidencia Yape. Tu horario fue liberado.' end);
  return v_usuario;
end;
$$;
revoke all on function public.resolver_reserva_yape(integer,boolean) from public;
grant execute on function public.resolver_reserva_yape(integer,boolean) to authenticated;

commit;
