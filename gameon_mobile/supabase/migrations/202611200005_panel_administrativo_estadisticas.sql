-- Indicadores administrativos, detalle de cuentas y aviso de afiliaciones.
create or replace function public.admin_estadisticas(p_inicio date, p_fin date)
returns jsonb language plpgsql stable security definer set search_path = '' as $$
declare v_result jsonb;
begin
  if not public.es_admin() then
    raise exception 'Acceso denegado' using errcode='42501';
  end if;
  if p_inicio is null or p_fin is null or p_inicio > p_fin then
    raise exception 'Rango de fechas inválido' using errcode='22023';
  end if;

  select jsonb_build_object(
    'deportistas', (select count(*) from public.usuarios_deportistas where estado=1),
    'gestores', (select count(*) from public.usuarios_instalaciones where estado=1),
    'complejos', (select count(*) from public.instituciones_deportivas where estado=1),
    'canchas', (select count(*) from public.areas_deportivas where lower(coalesce(estado,''))='activa'),
    'solicitudes_pendientes', (select count(*) from public.solicitudes_centros_deportivos where estado='pendiente'),
    'reclamos_abiertos', (select count(*) from public.reclamos where estado not in ('respondido','cerrado')),
    'ingresos_gestores', (
      select coalesce(sum(coalesce(r.monto_pagado,r.yape_monto_esperado,0)),0)
      from public.reservas r
      where r.fecha between p_inicio and p_fin
        and lower(trim(coalesce(r.estado,''))) in ('confirmada','completada','pagada')
    ),
    'reservas_confirmadas', (
      select count(*) from public.reservas r
      where r.fecha between p_inicio and p_fin
        and lower(trim(coalesce(r.estado,''))) in ('confirmada','completada','pagada')
    ),
    'por_metodo', (
      select coalesce(jsonb_agg(jsonb_build_object(
        'metodo',x.metodo,'reservas',x.reservas,'monto',x.monto
      ) order by x.monto desc),'[]'::jsonb)
      from (
        select coalesce(nullif(initcap(lower(r.metodo_pago)),''),'Otro') as metodo,
          count(*)::integer as reservas,
          coalesce(sum(coalesce(r.monto_pagado,r.yape_monto_esperado,0)),0) as monto
        from public.reservas r
        where r.fecha between p_inicio and p_fin
          and lower(trim(coalesce(r.estado,''))) in ('confirmada','completada','pagada')
        group by coalesce(nullif(initcap(lower(r.metodo_pago)),''),'Otro')
      ) x
    ),
    'por_dia', (
      select coalesce(jsonb_agg(jsonb_build_object(
        'fecha',x.fecha,'reservas',x.reservas,'monto',x.monto
      ) order by x.fecha),'[]'::jsonb)
      from (
        select r.fecha::text as fecha, count(*)::integer as reservas,
          coalesce(sum(coalesce(r.monto_pagado,r.yape_monto_esperado,0)),0) as monto
        from public.reservas r
        where r.fecha between p_inicio and p_fin
          and lower(trim(coalesce(r.estado,''))) in ('confirmada','completada','pagada')
        group by r.fecha
      ) x
    )
  ) into v_result;
  return v_result;
end;
$$;
revoke all on function public.admin_estadisticas(date,date) from public;
grant execute on function public.admin_estadisticas(date,date) to authenticated;

create or replace function public.admin_detalle_usuario(p_usuario_id integer)
returns jsonb language sql stable security definer set search_path = '' as $$
  select case when public.es_admin() then (
    select jsonb_build_object(
      'usuario', jsonb_build_object(
        'id',u.id,'nombre',trim(coalesce(u.nombre,'') || ' ' || coalesce(u.apellidos,'')),
        'username',u.username,'telefono',u.telefono,'estado',u.estado
      ),
      'gestor', (
        select coalesce(jsonb_agg(jsonb_build_object(
          'id',g.id,'nombre_negocio',g.nombre_negocio,'ruc',g.ruc,'estado',g.estado,
          'centros', (
            select coalesce(jsonb_agg(jsonb_build_object(
              'id',i.id,'nombre',i.nombre,'direccion',i.direccion,'latitud',i.latitud,
              'longitud',i.longitud,'telefono',i.telefono,'email',i.email,'descripcion',i.descripcion,
              'canchas', (
                select coalesce(jsonb_agg(jsonb_build_object(
                  'id',a.id,'nombre',a.nombre_area,'deporte',d.nombre,'tarifa',a.tarifa_por_hora,'estado',a.estado
                ) order by a.nombre_area),'[]'::jsonb)
                from public.areas_deportivas a left join public.deportes d on d.id=a.deporte_id
                where a.institucion_deportiva_id=i.id
              )
            ) order by i.nombre),'[]'::jsonb)
            from public.instituciones_deportivas i where i.usuario_instalacion_id=g.id
          )
        ) order by g.id),'[]'::jsonb)
        from public.usuarios_instalaciones g where g.auth_id=u.auth_id
      ),
      'reservas', (
        select coalesce(jsonb_agg(jsonb_build_object(
          'id',r.id,'fecha',r.fecha,'inicio',r.hora_inicio,'fin',r.hora_fin,'estado',r.estado,
          'metodo',r.metodo_pago,'monto',coalesce(r.monto_pagado,r.yape_monto_esperado,0),
          'cancha',a.nombre_area,'complejo',i.nombre,'direccion',i.direccion
        ) order by r.fecha desc,r.hora_inicio desc),'[]'::jsonb)
        from public.reservas r
        join public.areas_deportivas a on a.id=r.area_deportiva_id
        join public.instituciones_deportivas i on i.id=a.institucion_deportiva_id
        where r.id_usuario=u.id
      )
    ) from public.usuarios_deportistas u where u.id=p_usuario_id
  ) else null end;
$$;
revoke all on function public.admin_detalle_usuario(integer) from public;
grant execute on function public.admin_detalle_usuario(integer) to authenticated;

-- La solicitud llega también al centro de notificaciones de cada administrador.
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
  on conflict (auth_id) do update set nombre_negocio=excluded.nombre_negocio, ruc=excluded.ruc
  where public.usuarios_instalaciones.estado in (0,-1);
  select id into v_gestor from public.usuarios_instalaciones where auth_id=(select auth.uid());
  if exists(select 1 from public.solicitudes_centros_deportivos where gestor_id=v_gestor and estado='pendiente') then
    raise exception 'Ya tienes una solicitud de centro en revisión' using errcode='22023';
  end if;
  insert into public.solicitudes_centros_deportivos(
    gestor_id,nombre,ruc,direccion,latitud,longitud,telefono,email,descripcion,imagen_ruta
  ) values (
    v_gestor,left(trim(p_nombre),150),p_ruc,trim(p_direccion),p_latitud,p_longitud,
    nullif(trim(p_telefono),''),nullif(trim(p_email),''),nullif(trim(p_descripcion),''),nullif(trim(p_imagen_ruta),'')
  ) returning id into v_solicitud;
  insert into public.notificaciones(destinatario_auth_id,titulo,mensaje,tipo,referencia_id)
  select r.auth_id,'Nueva solicitud de afiliación',
    'El complejo "' || left(trim(p_nombre),90) || '" requiere revisión.','afiliacion',v_solicitud
  from public.roles_aplicacion r where r.rol='ADM';
  perform public.registrar_auditoria('SOLICITUD_CENTRO_CREADA','solicitud_centro',v_solicitud::text,
    jsonb_build_object('gestor_id',v_gestor));
  return v_solicitud;
end;
$$;
revoke all on function public.crear_solicitud_centro_actual(text,text,text,numeric,numeric,text,text,text,text) from public;
grant execute on function public.crear_solicitud_centro_actual(text,text,text,numeric,numeric,text,text,text,text) to authenticated;
