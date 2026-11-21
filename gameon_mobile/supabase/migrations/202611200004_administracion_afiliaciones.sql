-- Administración, afiliación de complejos y trazabilidad.
create table if not exists public.solicitudes_centros_deportivos (
  id bigint generated always as identity primary key,
  gestor_id integer not null references public.usuarios_instalaciones(id) on delete cascade,
  nombre varchar(150) not null,
  ruc varchar(11) not null,
  direccion text not null,
  latitud numeric(10,7) not null,
  longitud numeric(10,7) not null,
  telefono varchar(30),
  email varchar(150),
  descripcion text,
  imagen_ruta text,
  estado varchar(16) not null default 'pendiente'
    check (estado in ('pendiente', 'aprobada', 'rechazada')),
  observacion text,
  creado_en timestamptz not null default now(),
  resuelto_en timestamptz,
  resuelto_por uuid references auth.users(id)
);
alter table public.solicitudes_centros_deportivos enable row level security;

create table if not exists public.solicitud_centro_evidencias (
  id bigint generated always as identity primary key,
  solicitud_id bigint not null references public.solicitudes_centros_deportivos(id) on delete cascade,
  ruta text not null unique,
  creado_en timestamptz not null default now()
);
alter table public.solicitud_centro_evidencias enable row level security;

create table if not exists public.auditoria_administrativa (
  id bigint generated always as identity primary key,
  actor_auth_id uuid references auth.users(id),
  accion varchar(80) not null,
  entidad varchar(80) not null,
  entidad_id text not null,
  detalle jsonb not null default '{}'::jsonb,
  creado_en timestamptz not null default now()
);
alter table public.auditoria_administrativa enable row level security;

create table if not exists public.reclamos (
  id bigint generated always as identity primary key,
  auth_id uuid references auth.users(id) on delete set null,
  tipo varchar(12) not null check (tipo in ('Reclamo', 'Queja')),
  nombre text not null,
  documento text not null,
  email text not null,
  telefono text,
  direccion text,
  detalle text not null,
  estado varchar(16) not null default 'recibido'
    check (estado in ('recibido', 'en_revision', 'respondido', 'cerrado')),
  respuesta text,
  respondido_por uuid references auth.users(id),
  creado_en timestamptz not null default now(),
  respondido_en timestamptz
);
alter table public.reclamos enable row level security;

create table if not exists public.configuracion_general (
  clave varchar(80) primary key,
  valor text not null,
  actualizado_por uuid references auth.users(id),
  actualizado_en timestamptz not null default now()
);
alter table public.configuracion_general enable row level security;
insert into public.configuracion_general(clave, valor)
values ('soporte_email', ''), ('mensaje_bienvenida', 'Bienvenido a GameOn')
on conflict (clave) do nothing;

create or replace function public.registrar_auditoria(
  p_accion text, p_entidad text, p_entidad_id text, p_detalle jsonb default '{}'::jsonb
) returns void language plpgsql security definer set search_path = '' as $$
begin
  insert into public.auditoria_administrativa(actor_auth_id, accion, entidad, entidad_id, detalle)
  values ((select auth.uid()), p_accion, p_entidad, p_entidad_id, coalesce(p_detalle, '{}'::jsonb));
end;
$$;

-- Cualquier cuenta autenticada puede remitir una solicitud de centro; solo el
-- administrador puede leer y resolver solicitudes ajenas.
create policy "Solicitante ve sus centros pendientes"
  on public.solicitudes_centros_deportivos for select to authenticated
  using (gestor_id = (select public.gestor_id_propio()) or public.es_admin());
create policy "Admin lee evidencias de centros"
  on public.solicitud_centro_evidencias for select to authenticated
  using (public.es_admin() or exists (
    select 1 from public.solicitudes_centros_deportivos s
    where s.id = solicitud_id and s.gestor_id = public.gestor_id_propio()
  ));
create policy "Admin lee auditoría"
  on public.auditoria_administrativa for select to authenticated using (public.es_admin());
create policy "Admin lee reclamos"
  on public.reclamos for select to authenticated using (public.es_admin() or auth_id = (select auth.uid()));
create policy "Admin lee configuración"
  on public.configuracion_general for select to authenticated using (public.es_admin());

grant select on public.solicitudes_centros_deportivos, public.solicitud_centro_evidencias,
  public.auditoria_administrativa, public.reclamos, public.configuracion_general to authenticated;
grant usage, select on sequence public.solicitudes_centros_deportivos_id_seq,
  public.solicitud_centro_evidencias_id_seq, public.auditoria_administrativa_id_seq,
  public.reclamos_id_seq to authenticated;

create or replace function public.crear_solicitud_centro_actual(
  p_nombre text, p_ruc text, p_direccion text, p_latitud numeric, p_longitud numeric,
  p_telefono text default null, p_email text default null, p_descripcion text default null,
  p_imagen_ruta text default null
) returns bigint language plpgsql security definer set search_path = '' as $$
declare v_gestor integer; v_solicitud bigint;
begin
  if (select auth.uid()) is null then raise exception 'Inicia sesión' using errcode='42501'; end if;
  if length(trim(coalesce(p_nombre,''))) < 3 or coalesce(p_ruc,'') !~ '^[0-9]{11}$'
     or length(trim(coalesce(p_direccion,''))) < 5 or p_latitud is null or p_longitud is null then
    raise exception 'Completa los datos obligatorios del centro' using errcode='22023';
  end if;
  insert into public.usuarios_instalaciones(username, auth_id, tipo_usuario, estado, nombre_negocio, ruc)
  values ('movil_' || left(replace((select auth.uid())::text, '-', ''), 32),
    (select auth.uid()), 'gestor', 0, left(trim(p_nombre),100), p_ruc)
  on conflict (auth_id) do update set nombre_negocio = excluded.nombre_negocio, ruc = excluded.ruc
  where public.usuarios_instalaciones.estado in (0, -1);
  select id into v_gestor from public.usuarios_instalaciones where auth_id = (select auth.uid());
  if exists (select 1 from public.solicitudes_centros_deportivos
      where gestor_id=v_gestor and estado='pendiente') then
    raise exception 'Ya tienes una solicitud de centro en revisión' using errcode='22023';
  end if;
  insert into public.solicitudes_centros_deportivos(
    gestor_id,nombre,ruc,direccion,latitud,longitud,telefono,email,descripcion,imagen_ruta
  ) values (
    v_gestor,left(trim(p_nombre),150),p_ruc,trim(p_direccion),p_latitud,p_longitud,
    nullif(trim(p_telefono),''),nullif(trim(p_email),''),nullif(trim(p_descripcion),''),nullif(trim(p_imagen_ruta),'')
  ) returning id into v_solicitud;
  perform public.registrar_auditoria('SOLICITUD_CENTRO_CREADA','solicitud_centro',v_solicitud::text,
    jsonb_build_object('gestor_id',v_gestor));
  return v_solicitud;
end;
$$;
revoke all on function public.crear_solicitud_centro_actual(text,text,text,numeric,numeric,text,text,text,text) from public;
grant execute on function public.crear_solicitud_centro_actual(text,text,text,numeric,numeric,text,text,text,text) to authenticated;

create or replace function public.agregar_evidencia_solicitud_centro(p_solicitud_id bigint, p_ruta text)
returns void language plpgsql security definer set search_path = '' as $$
begin
  if not exists (select 1 from public.solicitudes_centros_deportivos
    where id=p_solicitud_id and gestor_id=public.gestor_id_propio() and estado='pendiente') then
    raise exception 'Solicitud no disponible' using errcode='42501';
  end if;
  if p_ruta not like (select auth.uid())::text || '/%' then
    raise exception 'Archivo inválido' using errcode='22023';
  end if;
  if (select count(*) from public.solicitud_centro_evidencias where solicitud_id=p_solicitud_id) >= 3 then
    raise exception 'Máximo tres evidencias por solicitud' using errcode='22023';
  end if;
  insert into public.solicitud_centro_evidencias(solicitud_id,ruta) values(p_solicitud_id,p_ruta);
end;
$$;
revoke all on function public.agregar_evidencia_solicitud_centro(bigint,text) from public;
grant execute on function public.agregar_evidencia_solicitud_centro(bigint,text) to authenticated;

-- Un gestor ya aprobado también puede adjuntar evidencias cuando solicita un
-- segundo complejo. La política anterior solo aceptaba cuentas pendientes.
drop policy if exists gestor_solicitud_subir on storage.objects;
create policy gestor_solicitud_subir on storage.objects for insert to authenticated
  with check (bucket_id='gestor-solicitudes'
    and (storage.foldername(name))[1]=(select auth.uid())::text
    and public.gestor_id_propio() is not null);

create or replace function public.resolver_solicitud_centro(
  p_id bigint, p_aprobar boolean, p_observacion text default null
) returns void language plpgsql security definer set search_path = '' as $$
declare s public.solicitudes_centros_deportivos%rowtype;
begin
  if not public.es_admin() then raise exception 'Acceso denegado' using errcode='42501'; end if;
  select * into s from public.solicitudes_centros_deportivos where id=p_id and estado='pendiente' for update;
  if not found then raise exception 'Solicitud no pendiente' using errcode='22023'; end if;
  if p_aprobar and not exists(select 1 from public.solicitud_centro_evidencias where solicitud_id=p_id) then
    raise exception 'Se requiere al menos una evidencia' using errcode='22023';
  end if;
  update public.solicitudes_centros_deportivos set estado=case when p_aprobar then 'aprobada' else 'rechazada' end,
    observacion=nullif(trim(p_observacion),''), resuelto_en=now(), resuelto_por=(select auth.uid()) where id=p_id;
  if p_aprobar then
    update public.usuarios_instalaciones set estado=1 where id=s.gestor_id and estado in (0,-1);
    insert into public.instituciones_deportivas(
      usuario_instalacion_id,nombre,ruc,direccion,latitud,longitud,imagen,tarifa,telefono,email,descripcion,estado
    ) values (s.gestor_id,s.nombre,s.ruc,s.direccion,s.latitud,s.longitud,s.imagen_ruta,0,
      coalesce(s.telefono,''),coalesce(s.email,''),s.descripcion,1);
  end if;
  perform public.registrar_auditoria(case when p_aprobar then 'SOLICITUD_CENTRO_APROBADA' else 'SOLICITUD_CENTRO_RECHAZADA' end,
    'solicitud_centro',p_id::text,jsonb_build_object('observacion',p_observacion));
end;
$$;
revoke all on function public.resolver_solicitud_centro(bigint,boolean,text) from public;
grant execute on function public.resolver_solicitud_centro(bigint,boolean,text) to authenticated;

create or replace function public.admin_resumen() returns jsonb
language sql stable security definer set search_path = '' as $$
  select case when public.es_admin() then jsonb_build_object(
    'deportistas', (select count(*) from public.usuarios_deportistas),
    'gestores_pendientes', (select count(*) from public.usuarios_instalaciones where estado=0),
    'centros_pendientes', (select count(*) from public.solicitudes_centros_deportivos where estado='pendiente'),
    'canchas', (select count(*) from public.areas_deportivas),
    'reservas_pendientes', (select count(*) from public.reservas where lower(estado)='pendiente'),
    'yape_pendiente', (select count(*) from public.reservas where lower(estado)='pendiente' and lower(coalesce(metodo_pago,''))='yape'),
    'reclamos_abiertos', (select count(*) from public.reclamos where estado not in ('respondido','cerrado'))
  ) else null end;
$$;
revoke all on function public.admin_resumen() from public;
grant execute on function public.admin_resumen() to authenticated;

create or replace function public.admin_solicitudes_centros() returns jsonb
language sql stable security definer set search_path = '' as $$
  select case when public.es_admin() then (
    select coalesce(jsonb_agg(jsonb_build_object(
    'id',s.id,'gestor_id',s.gestor_id,'nombre',s.nombre,'ruc',s.ruc,'direccion',s.direccion,
    'latitud',s.latitud,'longitud',s.longitud,'telefono',s.telefono,'email',s.email,
    'descripcion',s.descripcion,'imagen_ruta',s.imagen_ruta,'estado',s.estado,
    'observacion',s.observacion,'creado_en',s.creado_en,
    'evidencias',(select coalesce(jsonb_agg(e.ruta order by e.id),'[]'::jsonb)
      from public.solicitud_centro_evidencias e where e.solicitud_id=s.id)
    ) order by s.creado_en desc),'[]'::jsonb)
    from public.solicitudes_centros_deportivos s
  ) else '[]'::jsonb end;
$$;
revoke all on function public.admin_solicitudes_centros() from public;
grant execute on function public.admin_solicitudes_centros() to authenticated;

-- Las solicitudes nuevas se revisan como afiliación de centro; evita mostrar
-- dos tarjetas para el mismo solicitante en el panel administrativo.
create or replace function public.solicitudes_gestor() returns jsonb
language plpgsql stable security definer set search_path = '' as $$
declare v_result jsonb;
begin
  if not public.es_admin() then raise exception 'Acceso denegado' using errcode='42501'; end if;
  select coalesce(jsonb_agg(jsonb_build_object(
    'id', g.id, 'nombre', g.nombre_negocio, 'ruc', g.ruc, 'estado', g.estado,
    'evidencias', (select coalesce(jsonb_agg(e.ruta), '[]'::jsonb) from public.gestor_evidencias e where e.gestor_id=g.id)
  ) order by g.id desc), '[]'::jsonb) into v_result
  from public.usuarios_instalaciones g
  where g.estado in (0,-1)
    and not exists (select 1 from public.solicitudes_centros_deportivos s where s.gestor_id=g.id);
  return v_result;
end;
$$;

create or replace function public.registrar_reclamo(
  p_tipo text,p_nombre text,p_documento text,p_email text,p_telefono text,p_direccion text,p_detalle text
) returns bigint language plpgsql security definer set search_path = '' as $$
declare v_id bigint;
begin
  if p_tipo not in ('Reclamo','Queja') or length(trim(coalesce(p_nombre,'')))=0
     or length(trim(coalesce(p_documento,'')))=0 or length(trim(coalesce(p_email,'')))=0
     or length(trim(coalesce(p_detalle,'')))=0 then raise exception 'Completa los datos obligatorios' using errcode='22023'; end if;
  insert into public.reclamos(auth_id,tipo,nombre,documento,email,telefono,direccion,detalle)
  values ((select auth.uid()),p_tipo,trim(p_nombre),trim(p_documento),trim(p_email),nullif(trim(p_telefono),''),nullif(trim(p_direccion),''),trim(p_detalle))
  returning id into v_id;
  return v_id;
end;
$$;
revoke all on function public.registrar_reclamo(text,text,text,text,text,text,text) from public;
grant execute on function public.registrar_reclamo(text,text,text,text,text,text,text) to anon, authenticated;

create or replace function public.admin_resolver_reclamo(p_id bigint,p_estado text,p_respuesta text default null)
returns void language plpgsql security definer set search_path = '' as $$
begin
  if not public.es_admin() then raise exception 'Acceso denegado' using errcode='42501'; end if;
  if p_estado not in ('recibido','en_revision','respondido','cerrado') then raise exception 'Estado inválido' using errcode='22023'; end if;
  update public.reclamos set estado=p_estado,respuesta=nullif(trim(p_respuesta),''),respondido_por=(select auth.uid()),respondido_en=now() where id=p_id;
  if not found then raise exception 'Reclamo inexistente' using errcode='22023'; end if;
  perform public.registrar_auditoria('RECLAMO_ACTUALIZADO','reclamo',p_id::text,jsonb_build_object('estado',p_estado));
end;
$$;
revoke all on function public.admin_resolver_reclamo(bigint,text,text) from public;
grant execute on function public.admin_resolver_reclamo(bigint,text,text) to authenticated;

create or replace function public.admin_usuarios() returns jsonb
language sql stable security definer set search_path = '' as $$
  select case when public.es_admin() then (
    select coalesce(jsonb_agg(jsonb_build_object(
    'id',u.id,'auth_id',u.auth_id,'nombre',trim(coalesce(u.nombre,'') || ' ' || coalesce(u.apellidos,'')),
    'username',u.username,'telefono',u.telefono,'estado',u.estado,
    'es_admin',exists(select 1 from public.roles_aplicacion r where r.auth_id=u.auth_id and r.rol='ADM'),
    'es_gestor',exists(select 1 from public.usuarios_instalaciones g where g.auth_id=u.auth_id and g.estado=1)
    ) order by u.id desc),'[]'::jsonb)
    from public.usuarios_deportistas u
  ) else '[]'::jsonb end;
$$;
revoke all on function public.admin_usuarios() from public;
grant execute on function public.admin_usuarios() to authenticated;

create or replace function public.admin_cambiar_estado_usuario(p_id integer,p_activo boolean)
returns void language plpgsql security definer set search_path = '' as $$
begin
  if not public.es_admin() then raise exception 'Acceso denegado' using errcode='42501'; end if;
  update public.usuarios_deportistas set estado=case when p_activo then 1 else 0 end where id=p_id;
  if not found then raise exception 'Usuario inexistente' using errcode='22023'; end if;
  perform public.registrar_auditoria(case when p_activo then 'USUARIO_ACTIVADO' else 'USUARIO_DESACTIVADO' end,'usuario',p_id::text);
end;
$$;
revoke all on function public.admin_cambiar_estado_usuario(integer,boolean) from public;
grant execute on function public.admin_cambiar_estado_usuario(integer,boolean) to authenticated;

create or replace function public.admin_asignar_administrador(p_auth_id uuid,p_activo boolean)
returns void language plpgsql security definer set search_path = '' as $$
begin
  if not public.es_admin() then raise exception 'Acceso denegado' using errcode='42501'; end if;
  if p_auth_id=(select auth.uid()) and not p_activo then raise exception 'No puedes quitar tu propio acceso administrativo' using errcode='22023'; end if;
  if p_activo then
    insert into public.roles_aplicacion(auth_id,rol) values(p_auth_id,'ADM') on conflict(auth_id) do update set rol='ADM';
  else
    delete from public.roles_aplicacion where auth_id=p_auth_id and rol='ADM';
  end if;
  perform public.registrar_auditoria(case when p_activo then 'ROL_ADM_ASIGNADO' else 'ROL_ADM_RETIRADO' end,'usuario',p_auth_id::text);
end;
$$;
revoke all on function public.admin_asignar_administrador(uuid,boolean) from public;
grant execute on function public.admin_asignar_administrador(uuid,boolean) to authenticated;

create or replace function public.admin_reclamos() returns jsonb
language sql stable security definer set search_path = '' as $$
  select case when public.es_admin() then (
    select coalesce(jsonb_agg(to_jsonb(r) order by r.creado_en desc),'[]'::jsonb)
    from public.reclamos r
  ) else '[]'::jsonb end;
$$;
revoke all on function public.admin_reclamos() from public;
grant execute on function public.admin_reclamos() to authenticated;

create or replace function public.admin_auditoria() returns jsonb
language sql stable security definer set search_path = '' as $$
  select case when public.es_admin() then (
    select coalesce(jsonb_agg(to_jsonb(a) order by a.creado_en desc),'[]'::jsonb)
    from public.auditoria_administrativa a
  ) else '[]'::jsonb end;
$$;
revoke all on function public.admin_auditoria() from public;
grant execute on function public.admin_auditoria() to authenticated;

create or replace function public.admin_guardar_configuracion(p_clave text,p_valor text)
returns void language plpgsql security definer set search_path = '' as $$
begin
  if not public.es_admin() then raise exception 'Acceso denegado' using errcode='42501'; end if;
  if p_clave not in ('soporte_email','mensaje_bienvenida') then
    raise exception 'Parámetro no permitido' using errcode='22023';
  end if;
  insert into public.configuracion_general(clave,valor,actualizado_por,actualizado_en)
  values(p_clave,coalesce(p_valor,''),(select auth.uid()),now())
  on conflict(clave) do update set valor=excluded.valor,actualizado_por=excluded.actualizado_por,actualizado_en=now();
  perform public.registrar_auditoria('CONFIGURACION_ACTUALIZADA','configuracion',p_clave);
end;
$$;
revoke all on function public.admin_guardar_configuracion(text,text) from public;
grant execute on function public.admin_guardar_configuracion(text,text) to authenticated;

-- Mantiene trazabilidad también para solicitudes de gestor creadas por el
-- flujo anterior y para la decisión de pagos Yape.
create or replace function public.resolver_solicitud_gestor(p_id integer, p_aprobar boolean)
returns void language plpgsql security definer set search_path = '' as $$
begin
  if not public.es_admin() then raise exception 'Acceso denegado' using errcode='42501'; end if;
  if p_aprobar and not exists(select 1 from public.gestor_evidencias where gestor_id=p_id) then
    raise exception 'Se requiere al menos una evidencia' using errcode='22023'; end if;
  update public.usuarios_instalaciones set estado=case when p_aprobar then 1 else -1 end
    where id=p_id and estado=0;
  if not found then raise exception 'Solicitud no pendiente' using errcode='22023'; end if;
  perform public.registrar_auditoria(
    case when p_aprobar then 'GESTOR_APROBADO' else 'GESTOR_RECHAZADO' end,
    'gestor',p_id::text
  );
end;
$$;
revoke all on function public.resolver_solicitud_gestor(integer,boolean) from public;
grant execute on function public.resolver_solicitud_gestor(integer,boolean) to authenticated;

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
  perform public.registrar_auditoria(
    case when p_aprobar then 'YAPE_APROBADO' else 'YAPE_RECHAZADO' end,
    'reserva',p_id::text,jsonb_build_object('usuario_deportista_id',v_usuario)
  );
  return v_usuario;
end;
$$;
revoke all on function public.resolver_reserva_yape(integer,boolean) from public;
grant execute on function public.resolver_reserva_yape(integer,boolean) to authenticated;
