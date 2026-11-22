-- Reservas presenciales: el cliente puede no tener cuenta en GameOn.
alter table public.reservas alter column id_usuario drop not null;
alter table public.reservas add column if not exists cliente_nombre text;
alter table public.reservas add column if not exists cliente_telefono text;
alter table public.reservas add column if not exists registrado_por_auth_id uuid references auth.users(id);
alter table public.reservas add column if not exists aprobado_por_auth_id uuid references auth.users(id);

create or replace function public.crear_reserva_directa_gestor(
  p_area_id integer,
  p_fecha date,
  p_hora_inicio time,
  p_hora_fin time,
  p_cliente_nombre text default null,
  p_cliente_telefono text default null,
  p_monto numeric default null,
  p_metodo_pago text default 'efectivo'
) returns integer language plpgsql security definer set search_path = '' as $$
declare v_reserva integer;
begin
  if (select auth.uid()) is null then raise exception 'Inicia sesión' using errcode='42501'; end if;
  if p_hora_fin <= p_hora_inicio then raise exception 'El horario final debe ser posterior al inicial' using errcode='22023'; end if;
  if coalesce(p_monto, 0) < 0 then raise exception 'El monto no es válido' using errcode='22023'; end if;
  if lower(coalesce(p_metodo_pago,'')) not in ('efectivo','yape','paypal') then
    raise exception 'Método de pago no válido' using errcode='22023';
  end if;
  if not exists (
    select 1
    from public.areas_deportivas a
    join public.instituciones_deportivas i on i.id=a.institucion_deportiva_id
    join public.usuarios_instalaciones g on g.id=i.usuario_instalacion_id
    where a.id=p_area_id and g.auth_id=(select auth.uid()) and g.estado=1
  ) then raise exception 'No puedes reservar una cancha que no administras' using errcode='42501'; end if;
  if exists (
    select 1 from public.reservas r
    where r.area_deportiva_id=p_area_id and r.fecha=p_fecha
      and lower(coalesce(r.estado,'')) <> 'cancelada'
      and r.hora_inicio < p_hora_fin and r.hora_fin > p_hora_inicio
  ) then raise exception 'Ese horario ya fue reservado' using errcode='23P01'; end if;

  insert into public.reservas(
    id_usuario,area_deportiva_id,fecha,hora_inicio,hora_fin,estado,
    monto_pagado,metodo_pago,fecha_pago,cliente_nombre,cliente_telefono,
    registrado_por_auth_id,aprobado_por_auth_id
  ) values (
    null,p_area_id,p_fecha,p_hora_inicio,p_hora_fin,'confirmada',
    coalesce(p_monto,0),lower(p_metodo_pago),now(),nullif(trim(p_cliente_nombre),''),
    nullif(trim(p_cliente_telefono),''),(select auth.uid()),(select auth.uid())
  ) returning id into v_reserva;
  return v_reserva;
end;
$$;
revoke all on function public.crear_reserva_directa_gestor(integer,date,time,time,text,text,numeric,text) from public;
grant execute on function public.crear_reserva_directa_gestor(integer,date,time,time,text,text,numeric,text) to authenticated;
