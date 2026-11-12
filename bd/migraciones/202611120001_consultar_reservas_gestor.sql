-- US-24. Aplicar después de 202610300001_gestor_movil.sql.
begin;

-- Proyección explícita: nunca devolver id_usuario, contacto ni IDs de cobro.
-- No modifica políticas ni operaciones existentes de los deportistas.
create or replace function public.consultar_reservas_gestor(
  p_area_ids bigint[], p_fecha date default null,
  p_offset integer default 0, p_limite integer default 200
) returns table (
  id bigint, area_deportiva_id bigint, fecha date,
  hora_inicio time, hora_fin time, estado text,
  monto_pagado numeric, metodo_pago text
) language plpgsql stable security definer set search_path = '' as $$
declare v_gestor integer;
begin
  if auth.uid() is null then
    raise exception 'Inicia sesión' using errcode = '42501';
  end if;
  v_gestor := public.gestor_actual();
  if v_gestor is null then
    raise exception 'Cuenta gestora no autorizada' using errcode = '42501';
  end if;
  if p_offset is null or p_offset < 0 or p_limite is null
     or p_limite < 1 or p_limite > 200 then
    raise exception 'Paginación inválida' using errcode = '22023';
  end if;
  return query
    select r.id::bigint, r.area_deportiva_id::bigint, r.fecha,
      r.hora_inicio, r.hora_fin, r.estado::text,
      r.monto_pagado, r.metodo_pago::text
    from public.reservas r
    join public.areas_deportivas a on a.id = r.area_deportiva_id
    join public.instituciones_deportivas i on i.id = a.institucion_deportiva_id
    where i.usuario_instalacion_id = v_gestor
      and a.id = any(p_area_ids)
      and (p_fecha is null or r.fecha = p_fecha)
    order by r.fecha desc, r.hora_inicio, r.id
    limit p_limite offset p_offset;
end;
$$;
revoke all on function public.consultar_reservas_gestor(bigint[], date, integer, integer)
  from public, anon;
grant execute on function public.consultar_reservas_gestor(bigint[], date, integer, integer)
  to authenticated;
commit;
