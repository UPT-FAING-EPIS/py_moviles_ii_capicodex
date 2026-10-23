begin;

create extension if not exists btree_gist;

-- El despliegue se detiene si ya hay reservas solapadas: no se borra ninguna.
-- También protege las inserciones del flujo existente frente a carreras.
alter table public.reservas add constraint reservas_sin_solapamiento
exclude using gist (
  area_deportiva_id with =,
  tsrange(fecha + hora_inicio, fecha + hora_fin, '[)') with &&
) where (lower(estado) <> 'cancelada');

create function public.reprogramar_reserva(
  p_reserva_id bigint, p_fecha date, p_hora_inicio time
) returns public.reservas
language plpgsql security definer set search_path = '' as $$
declare
  original public.reservas;
  resultado public.reservas;
  duracion interval;
  nuevo_fin timestamp;
  v_dia text;
begin
  if auth.uid() is null then
    raise exception 'Autenticación requerida' using errcode = '42501';
  end if;
  select r.* into original from public.reservas r
    join public.usuarios_deportistas u on u.id = r.id_usuario
    where r.id = p_reserva_id and u.auth_id::text = auth.uid()::text
    for update of r;
  if not found then
    raise exception 'Reserva no disponible para esta cuenta' using errcode = '42501';
  end if;
  if p_fecha is null or p_hora_inicio is null
     or lower(original.estado) not in ('pendiente', 'confirmada')
     or original.fecha + original.hora_inicio <= now() at time zone 'America/Lima'
     or p_fecha + p_hora_inicio <= now() at time zone 'America/Lima' then
    raise exception 'La reserva y el nuevo horario deben ser futuros y activos' using errcode = '22023';
  end if;
  duracion := original.hora_fin - original.hora_inicio;
  nuevo_fin := p_fecha + p_hora_inicio + duracion;
  if duracion <= interval '0' or nuevo_fin::date <> p_fecha then
    raise exception 'Duración u horario inválido' using errcode = '22023';
  end if;
  v_dia := (array['lunes','martes','miercoles','jueves','viernes','sabado','domingo'])
    [extract(isodow from p_fecha)::integer];
  if not exists (
    select 1 from public.areas_horarios h
    where h.area_deportiva_id = original.area_deportiva_id
      and translate(lower(h.dia), 'áéíóú', 'aeiou') = v_dia
      and h.disponible::text in ('1', 'true')
      and p_hora_inicio >= h.hora_apertura
      and nuevo_fin::time <= h.hora_cierre
  ) then
    raise exception 'Fuera del horario de atención' using errcode = '22023';
  end if;
  -- UPDATE atómico: conserva id, estado, propietario y datos de pago.
  -- La exclusión GiST vuelve a comprobar disponibilidad al escribir.
  update public.reservas set fecha = p_fecha,
    hora_inicio = p_hora_inicio, hora_fin = nuevo_fin::time
    where id = original.id returning * into resultado;
  return resultado;
end;
$$;

revoke all on function public.reprogramar_reserva(bigint, date, time) from public;
grant execute on function public.reprogramar_reserva(bigint, date, time) to authenticated;
commit;
