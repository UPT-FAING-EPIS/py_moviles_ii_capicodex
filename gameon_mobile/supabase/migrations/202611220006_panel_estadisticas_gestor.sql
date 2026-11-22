-- Estadísticas por gestor y, opcionalmente, por uno de sus centros.
-- Sigue el cálculo histórico del panel administrativo: si falta un monto,
-- se estima con la tarifa actual del área y la duración reservada.
create or replace function public.gestor_estadisticas(
  p_inicio date, p_fin date, p_centro_id integer default null
) returns jsonb language plpgsql stable security definer set search_path = '' as $$
declare v_gestor integer; v_result jsonb;
begin
  v_gestor := public.gestor_actual();
  if v_gestor is null then
    raise exception 'Acceso exclusivo para gestores' using errcode = '42501';
  end if;
  if p_inicio is null or p_fin is null or p_inicio > p_fin then
    raise exception 'Rango de fechas inválido' using errcode = '22023';
  end if;
  if p_centro_id is not null and not exists (
    select 1 from public.instituciones_deportivas i
    where i.id = p_centro_id and i.usuario_instalacion_id = v_gestor
  ) then
    raise exception 'El complejo no pertenece al gestor' using errcode = '42501';
  end if;

  with cobradas as (
    select r.fecha, i.id as institucion_id, i.nombre as institucion,
      lower(trim(coalesce(r.metodo_pago,''))) as metodo_pago,
      coalesce(nullif(r.monto_pagado,0), nullif(r.yape_monto_esperado,0),
        round(a.tarifa_por_hora *
          (extract(epoch from (r.hora_fin-r.hora_inicio))/3600.0),2),0) as monto
    from public.reservas r
    join public.areas_deportivas a on a.id = r.area_deportiva_id
    join public.instituciones_deportivas i on i.id = a.institucion_deportiva_id
    where i.usuario_instalacion_id = v_gestor
      and (p_centro_id is null or i.id = p_centro_id)
      and r.fecha between p_inicio and p_fin
      and lower(trim(coalesce(r.estado,''))) in ('confirmada','completada','pagada')
  )
  select jsonb_build_object(
    'ingresos', (select coalesce(sum(monto),0) from cobradas),
    'reservas', (select count(*) from cobradas),
    'por_metodo', (select coalesce(jsonb_agg(jsonb_build_object(
      'metodo', metodo, 'reservas', reservas, 'monto', monto) order by monto desc), '[]'::jsonb)
      from (select coalesce(nullif(initcap(metodo_pago),''),'No registrado') metodo,
        count(*)::integer reservas, sum(monto) monto from cobradas
        group by coalesce(nullif(initcap(metodo_pago),''),'No registrado')) x),
    'por_dia', (select coalesce(jsonb_agg(jsonb_build_object(
      'fecha', fecha, 'reservas', reservas, 'monto', monto) order by fecha), '[]'::jsonb)
      from (select fecha::text fecha, count(*)::integer reservas, sum(monto) monto
        from cobradas group by fecha) x),
    'por_institucion', (select coalesce(jsonb_agg(jsonb_build_object(
      'institucion', institucion, 'reservas', reservas, 'monto', monto)
      order by reservas desc, monto desc), '[]'::jsonb)
      from (select institucion_id, institucion, count(*)::integer reservas,
        sum(monto) monto from cobradas group by institucion_id,institucion) x)
  ) into v_result;
  return v_result;
end;
$$;
revoke all on function public.gestor_estadisticas(date,date,integer) from public;
grant execute on function public.gestor_estadisticas(date,date,integer) to authenticated;
