create table public.paypal_intentos_reserva (
  id bigint generated always as identity primary key,
  reserva_id integer not null unique references public.reservas(id),
  comprador_auth_id uuid not null references auth.users(id),
  gestor_id integer not null references public.usuarios_instalaciones(id),
  monto_usd numeric(12,2) not null check (monto_usd > 0),
  monto_pen numeric(12,2) not null check (monto_pen > 0),
  tipo_cambio_pen numeric(14,6) not null check (tipo_cambio_pen > 0),
  order_id text unique,
  capture_id text unique,
  estado text not null default 'creando' check (estado in ('creando','pendiente','completado','fallido')),
  creado_en timestamptz not null default now()
);
alter table public.paypal_intentos_reserva enable row level security;
revoke all on public.paypal_intentos_reserva from anon, authenticated;

-- Un cliente no puede simular un pago PayPal con un INSERT/UPDATE directo.
create or replace function public.proteger_pago_paypal()
returns trigger language plpgsql set search_path = '' as $$
begin
  if new.id_usuario is not null and lower(coalesce(new.metodo_pago,''))='paypal'
    and lower(coalesce(new.estado,'')) in ('confirmada','completada')
    and (select auth.role()) is distinct from 'service_role' then
    raise exception 'El pago PayPal debe confirmarlo el servidor' using errcode='42501';
  end if;
  return new;
end;
$$;
drop trigger if exists proteger_pago_paypal on public.reservas;
create trigger proteger_pago_paypal before insert or update on public.reservas
for each row execute function public.proteger_pago_paypal();

-- La notificación de reserva se emite solo al confirmar la captura.
drop trigger if exists notificar_evento_reserva on public.reservas;
create trigger notificar_evento_reserva
after insert or update of estado on public.reservas
for each row when (not (lower(coalesce(new.metodo_pago,''))='paypal'
  and lower(coalesce(new.estado,''))='pendiente'))
execute function public.notificar_evento_reserva();

create or replace function public.paypal_iniciar_reserva(
  p_comprador_auth_id uuid,p_area_id integer,p_fecha date,p_inicio time,p_fin time,
  p_tipo_cambio_pen numeric
) returns jsonb language plpgsql security definer set search_path = '' as $$
declare v_usuario integer; v_gestor integer; v_tarifa numeric; v_id integer; v_usd numeric;
begin
  select id into v_usuario from public.usuarios_deportistas where auth_id=p_comprador_auth_id;
  if v_usuario is null then raise exception 'Inicia sesión como deportista' using errcode='42501'; end if;
  if p_tipo_cambio_pen is null or p_tipo_cambio_pen <= 0 then
    raise exception 'Cotización inválida' using errcode='22023'; end if;
  if p_fecha < (now() at time zone 'America/Lima')::date or p_fin <= p_inicio or
     extract(epoch from (p_fin-p_inicio))::integer % 1800 <> 0 then
    raise exception 'Fecha u horario inválidos' using errcode='22023';
  end if;
  select g.id,a.tarifa_por_hora into v_gestor,v_tarifa
  from public.areas_deportivas a
  join public.instituciones_deportivas i on i.id=a.institucion_deportiva_id
  join public.usuarios_instalaciones g on g.id=i.usuario_instalacion_id
  where a.id=p_area_id and g.estado=1 and lower(a.estado)='activa'
    and exists (
      select 1 from public.areas_horarios h
      where h.area_deportiva_id=a.id and h.disponible=1
        and lower(h.dia)=(array['domingo','lunes','martes','miércoles','jueves','viernes','sábado'])[extract(dow from p_fecha)::integer+1]
        and h.hora_apertura<=p_inicio and h.hora_cierre>=p_fin
    );
  if v_gestor is null or v_tarifa is null or
     not exists(select 1 from public.gestor_paypal_config where gestor_id=v_gestor) then
    raise exception 'PayPal no está disponible para esta cancha y horario' using errcode='22023';
  end if;
  v_usd := round(v_tarifa * extract(epoch from (p_fin-p_inicio))::numeric / 3600 / p_tipo_cambio_pen,2);
  if v_usd <= 0 then raise exception 'Monto inválido' using errcode='22023'; end if;
  -- Órdenes PayPal vencidas liberan el horario al iniciar una compra nueva.
  update public.reservas r set estado='cancelada'
  from public.paypal_intentos_reserva p
  where p.reserva_id=r.id and p.estado in ('creando','pendiente')
    and p.creado_en < now() - interval '24 hours' and r.estado='pendiente';
  update public.paypal_intentos_reserva set estado='fallido'
  where estado in ('creando','pendiente') and creado_en < now() - interval '24 hours';
  -- La restricción GiST de reservas evita dos compras del mismo turno en una carrera.
  insert into public.reservas(id_usuario,area_deportiva_id,fecha,hora_inicio,hora_fin,estado,metodo_pago)
  values(v_usuario,p_area_id,p_fecha,p_inicio,p_fin,'pendiente','paypal')
  returning id into v_id;
  insert into public.paypal_intentos_reserva(reserva_id,comprador_auth_id,gestor_id,monto_usd,monto_pen,tipo_cambio_pen)
  values(v_id,p_comprador_auth_id,v_gestor,v_usd,round(v_tarifa * extract(epoch from (p_fin-p_inicio))::numeric / 3600,2),p_tipo_cambio_pen);
  return jsonb_build_object('reserva_id',v_id,'gestor_id',v_gestor,'monto_usd',v_usd);
end;
$$;
revoke all on function public.paypal_iniciar_reserva(uuid,integer,date,time,time,numeric) from public,authenticated;
grant execute on function public.paypal_iniciar_reserva(uuid,integer,date,time,time,numeric) to service_role;

create or replace function public.paypal_asociar_orden(p_reserva integer,p_order text)
returns void language plpgsql security definer set search_path = '' as $$
begin
  update public.paypal_intentos_reserva set order_id=p_order,estado='pendiente'
  where reserva_id=p_reserva and estado='creando';
  if not found then raise exception 'Intento no autorizado' using errcode='42501'; end if;
end;
$$;
revoke all on function public.paypal_asociar_orden(integer,text) from public,authenticated;
grant execute on function public.paypal_asociar_orden(integer,text) to service_role;

create or replace function public.paypal_fallar_reserva(p_reserva integer)
returns void language plpgsql security definer set search_path = '' as $$
begin
  update public.reservas r set estado='cancelada' from public.paypal_intentos_reserva p
  where p.reserva_id=r.id and r.id=p_reserva
    and p.estado='creando';
  update public.paypal_intentos_reserva set estado='fallido'
  where reserva_id=p_reserva and estado='creando';
end;
$$;
revoke all on function public.paypal_fallar_reserva(integer) from public,authenticated;
grant execute on function public.paypal_fallar_reserva(integer) to service_role;

create or replace function public.paypal_cancelar_servidor(p_reserva integer,p_order text)
returns void language plpgsql security definer set search_path = '' as $$
begin
  update public.paypal_intentos_reserva set estado='fallido'
  where reserva_id=p_reserva and order_id=p_order and estado='pendiente';
  if found then
    update public.reservas set estado='cancelada' where id=p_reserva and estado='pendiente';
  end if;
end;
$$;
revoke all on function public.paypal_cancelar_servidor(integer,text) from public,authenticated;
grant execute on function public.paypal_cancelar_servidor(integer,text) to service_role;

create or replace function public.paypal_confirmar_servidor(
  p_reserva integer,p_order text,p_capture text,p_monto_usd numeric
) returns integer language plpgsql security definer set search_path = '' as $$
declare v_intento public.paypal_intentos_reserva;
begin
  select * into v_intento from public.paypal_intentos_reserva where reserva_id=p_reserva for update;
  if not found or v_intento.order_id is distinct from p_order or
     v_intento.monto_usd is distinct from p_monto_usd then
    raise exception 'El pago no corresponde con la reserva' using errcode='22023';
  end if;
  if v_intento.estado='completado' and v_intento.capture_id=p_capture then return p_reserva; end if;
  if v_intento.estado<>'pendiente' then raise exception 'Estado de pago inválido' using errcode='22023'; end if;
  update public.reservas set estado='confirmada',fecha_pago=now(),
    paypal_order_id=p_order,metodo_pago='paypal',
    monto_pagado=v_intento.monto_pen
  where id=p_reserva and estado='pendiente';
  if not found then raise exception 'Reserva ya no disponible' using errcode='22023'; end if;
  update public.paypal_intentos_reserva set estado='completado',capture_id=p_capture where id=v_intento.id;
  return p_reserva;
end;
$$;
revoke all on function public.paypal_confirmar_servidor(integer,text,text,numeric) from public,anon,authenticated;
grant execute on function public.paypal_confirmar_servidor(integer,text,text,numeric) to service_role;
