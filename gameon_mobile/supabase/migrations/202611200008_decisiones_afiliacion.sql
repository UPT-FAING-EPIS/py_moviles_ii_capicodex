-- Decisiones de afiliación: aviso persistente y datos del destinatario para
-- abrir el canal administrativo de solo lectura para el solicitante.
create or replace function public.admin_solicitudes_centros() returns jsonb
language sql stable security definer set search_path = '' as $$
  select case when public.es_admin() then (
    select coalesce(jsonb_agg(jsonb_build_object(
      'id',s.id,'gestor_id',s.gestor_id,'solicitante_auth_id',g.auth_id,
      'solicitante_nombre',coalesce(nullif(trim(concat_ws(' ',u.nombre,u.apellidos)),''),g.nombre_negocio,'Solicitante'),
      'nombre',s.nombre,'ruc',s.ruc,'direccion',s.direccion,
      'latitud',s.latitud,'longitud',s.longitud,'telefono',s.telefono,'email',s.email,
      'descripcion',s.descripcion,'imagen_ruta',s.imagen_ruta,'estado',s.estado,
      'observacion',s.observacion,'creado_en',s.creado_en,
      'evidencias',(select coalesce(jsonb_agg(e.ruta order by e.id),'[]'::jsonb)
        from public.solicitud_centro_evidencias e where e.solicitud_id=s.id)
    ) order by s.creado_en desc),'[]'::jsonb)
    from public.solicitudes_centros_deportivos s
    join public.usuarios_instalaciones g on g.id=s.gestor_id
    left join public.usuarios_deportistas u on u.auth_id=g.auth_id
  ) else '[]'::jsonb end;
$$;

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
