-- Una cuenta rechazada puede corregir el formulario y volver a solicitar la
-- afiliación. El nuevo centro queda pendiente sin eliminar el historial.
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
  on conflict (auth_id) do update set
    nombre_negocio = excluded.nombre_negocio,
    ruc = excluded.ruc,
    estado = case when public.usuarios_instalaciones.estado = -1 then 0
                  else public.usuarios_instalaciones.estado end
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
    nullif(trim(p_telefono),''),nullif(trim(p_email,''),''),nullif(trim(p_descripcion,''),''),nullif(trim(p_imagen_ruta,''),'')
  ) returning id into v_solicitud;
  perform public.registrar_auditoria('SOLICITUD_CENTRO_CREADA','solicitud_centro',v_solicitud::text,
    jsonb_build_object('gestor_id',v_gestor, 'reintento', true));
  return v_solicitud;
end;
$$;
revoke all on function public.crear_solicitud_centro_actual(text,text,text,numeric,numeric,text,text,text,text) from public;
grant execute on function public.crear_solicitud_centro_actual(text,text,text,numeric,numeric,text,text,text,text) to authenticated;

-- Corrige solicitudes rechazadas antes de esta migración: anteriormente la
-- solicitud quedaba rechazada, pero el perfil gestor seguía marcado como 0.
update public.usuarios_instalaciones g
set estado = -1
where g.estado = 0
  and exists (
    select 1 from public.solicitudes_centros_deportivos s
    where s.gestor_id = g.id and s.estado = 'rechazada'
  )
  and not exists (
    select 1 from public.solicitudes_centros_deportivos s
    where s.gestor_id = g.id and s.estado = 'pendiente'
  );

-- Las decisiones posteriores también sincronizan el estado del perfil gestor.
create or replace function public.resolver_solicitud_centro(
  p_id bigint, p_aprobar boolean, p_observacion text default null
) returns void language plpgsql security definer set search_path = '' as $$
declare s public.solicitudes_centros_deportivos%rowtype;
declare v_destinatario uuid;
declare v_mensaje text;
begin
  if not public.es_admin() then raise exception 'Acceso denegado' using errcode='42501'; end if;
  select * into s from public.solicitudes_centros_deportivos where id=p_id and estado='pendiente' for update;
  if not found then raise exception 'Solicitud no pendiente' using errcode='22023'; end if;
  if not p_aprobar and nullif(trim(coalesce(p_observacion,'')),'') is null then
    raise exception 'Escribe el motivo del rechazo' using errcode='22023';
  end if;
  if p_aprobar and not exists(select 1 from public.solicitud_centro_evidencias where solicitud_id=p_id) then
    raise exception 'Se requiere al menos una evidencia' using errcode='22023';
  end if;

  update public.solicitudes_centros_deportivos
  set estado=case when p_aprobar then 'aprobada' else 'rechazada' end,
      observacion=nullif(trim(p_observacion),''), resuelto_en=now(), resuelto_por=(select auth.uid())
  where id=p_id;
  select auth_id into v_destinatario from public.usuarios_instalaciones where id=s.gestor_id;

  if p_aprobar then
    update public.usuarios_instalaciones set estado=1 where id=s.gestor_id and estado in (0,-1);
    insert into public.instituciones_deportivas(
      usuario_instalacion_id,nombre,ruc,direccion,latitud,longitud,imagen,tarifa,telefono,email,descripcion,estado
    ) values (s.gestor_id,s.nombre,s.ruc,s.direccion,s.latitud,s.longitud,s.imagen_ruta,0,
      coalesce(s.telefono,''),coalesce(s.email,''),s.descripcion,1);
    v_mensaje := 'Tu solicitud para el complejo "' || s.nombre || '" fue aprobada. Ya puedes cambiar al rol Gestor de Canchas desde Perfil y administrar tu nuevo complejo.';
  else
    -- Solo se marca rechazado si no es ya un gestor aprobado con otros centros.
    update public.usuarios_instalaciones set estado=-1 where id=s.gestor_id and estado=0;
    v_mensaje := 'Tu solicitud para el complejo "' || s.nombre || '" fue rechazada. Motivo: ' || trim(p_observacion);
  end if;

  if v_destinatario is not null then
    insert into public.notificaciones(destinatario_auth_id,titulo,mensaje,tipo,referencia_id)
    values(v_destinatario,case when p_aprobar then 'Complejo aprobado' else 'Solicitud observada' end,v_mensaje,'afiliacion',p_id);
  end if;
  perform public.registrar_auditoria(case when p_aprobar then 'SOLICITUD_CENTRO_APROBADA' else 'SOLICITUD_CENTRO_RECHAZADA' end,
    'solicitud_centro',p_id::text,jsonb_build_object('observacion',p_observacion));
end;
$$;
revoke all on function public.resolver_solicitud_centro(bigint,boolean,text) from public;
grant execute on function public.resolver_solicitud_centro(bigint,boolean,text) to authenticated;
