-- Constancia informativa de reserva y pago, accesible al titular y al gestor del centro.
create or replace function public.constancia_reserva(p_reserva_id integer)
returns jsonb language plpgsql stable security definer set search_path = '' as $$
declare v_result jsonb;
begin
  if (select auth.uid()) is null then
    raise exception 'Inicia sesión' using errcode = '42501';
  end if;

  select jsonb_build_object(
    'id', r.id, 'cancha', a.nombre_area, 'centro', i.nombre,
    'cliente', coalesce(nullif(trim(concat_ws(' ',d.nombre,d.apellidos)),''),
      nullif(trim(r.cliente_nombre),'')),
    'fecha', r.fecha, 'hora_inicio', r.hora_inicio, 'hora_fin', r.hora_fin,
    'monto', r.monto_pagado, 'metodo', r.metodo_pago, 'estado', r.estado,
    'registrado_en', r.creado_en,
    'aprobado_en', coalesce(r.fecha_pago, aud.creado_en),
    'gestor_responsable', coalesce(
      nullif(trim(concat_ws(' ', persona_aprobadora.nombre, persona_aprobadora.apellidos)),''),
      nullif(trim(concat_ws(' ', persona_auditora.nombre, persona_auditora.apellidos)),''),
      aprobador.username, auditor.username,
      case when lower(coalesce(r.metodo_pago,'')) = 'paypal'
        then 'Confirmación automática de PayPal' end)
  ) into v_result
  from public.reservas r
  join public.areas_deportivas a on a.id = r.area_deportiva_id
  join public.instituciones_deportivas i on i.id = a.institucion_deportiva_id
  left join public.usuarios_deportistas d on d.id = r.id_usuario
  left join public.usuarios_instalaciones aprobador on aprobador.auth_id = r.aprobado_por_auth_id
  left join public.usuarios_deportistas persona_aprobadora
    on persona_aprobadora.auth_id = r.aprobado_por_auth_id
  left join lateral (
    select au.actor_auth_id, au.creado_en
    from public.auditoria_administrativa au
    where au.entidad = 'reserva' and au.entidad_id = r.id::text
      and au.accion = 'YAPE_APROBADO'
    order by au.creado_en desc limit 1
  ) aud on true
  left join public.usuarios_instalaciones auditor on auditor.auth_id = aud.actor_auth_id
  left join public.usuarios_deportistas persona_auditora
    on persona_auditora.auth_id = aud.actor_auth_id
  where r.id = p_reserva_id
    and lower(r.estado) in ('confirmada', 'completada')
    and (
      d.auth_id = (select auth.uid())
      or exists (
        select 1 from public.usuarios_instalaciones g
        where g.id = i.usuario_instalacion_id and g.auth_id = (select auth.uid())
      )
    );
  if v_result is null then
    raise exception 'Constancia no disponible para esta reserva' using errcode = '42501';
  end if;
  return v_result;
end;
$$;
revoke all on function public.constancia_reserva(integer) from public;
grant execute on function public.constancia_reserva(integer) to authenticated;

-- Registrar el instante y el gestor en las próximas decisiones Yape.
create or replace function public.resolver_reserva_yape(p_id integer, p_aprobar boolean)
returns integer language plpgsql security definer set search_path = '' as $$
declare v_usuario integer; v_auth uuid;
begin
  update public.reservas r
  set estado = case when p_aprobar then 'confirmada' else 'cancelada' end,
      monto_pagado = case when p_aprobar then r.yape_monto_esperado else null end,
      fecha_pago = case when p_aprobar then now() else null end,
      aprobado_por_auth_id = case when p_aprobar then (select auth.uid()) else null end
  from public.areas_deportivas a, public.instituciones_deportivas i
  where r.id = p_id and r.area_deportiva_id = a.id
    and a.institucion_deportiva_id = i.id
    and i.usuario_instalacion_id = public.gestor_actual()
    and lower(r.estado) = 'pendiente' and lower(r.metodo_pago) = 'yape'
  returning r.id_usuario into v_usuario;
  if v_usuario is null then
    raise exception 'Reserva no pendiente o sin autorización' using errcode = '42501';
  end if;
  select auth_id into v_auth from public.usuarios_deportistas where id = v_usuario;
  insert into public.avisos_reserva(destinatario, reserva_id, mensaje)
  values (v_auth, p_id, case when p_aprobar then
    'El gestor confirmó tu pago Yape y tu reserva.' else
    'El gestor rechazó la evidencia Yape. Tu horario fue liberado.' end);
  perform public.registrar_auditoria(
    case when p_aprobar then 'YAPE_APROBADO' else 'YAPE_RECHAZADO' end,
    'reserva', p_id::text, jsonb_build_object('usuario_deportista_id', v_usuario)
  );
  return v_usuario;
end;
$$;
revoke all on function public.resolver_reserva_yape(integer,boolean) from public;
grant execute on function public.resolver_reserva_yape(integer,boolean) to authenticated;
