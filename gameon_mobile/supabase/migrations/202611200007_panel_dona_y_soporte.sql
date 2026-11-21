-- Dona de instituciones para el panel y lectura pública controlada del correo de soporte.
create or replace function public.admin_estadisticas(p_inicio date, p_fin date)
returns jsonb language sql stable security definer set search_path = '' as $$
  select case when public.es_admin() and p_inicio is not null and p_fin is not null and p_inicio <= p_fin then (
    with cobradas as (
      select r.fecha, i.id as institucion_id, i.nombre as institucion,
        lower(trim(coalesce(r.metodo_pago,''))) as metodo_pago,
        coalesce(nullif(r.monto_pagado,0),nullif(r.yape_monto_esperado,0),
          round(a.tarifa_por_hora*(extract(epoch from (r.hora_fin-r.hora_inicio))/3600.0),2),0) as monto
      from public.reservas r
      join public.areas_deportivas a on a.id=r.area_deportiva_id
      join public.instituciones_deportivas i on i.id=a.institucion_deportiva_id
      where r.fecha between p_inicio and p_fin
        and lower(trim(coalesce(r.estado,''))) in ('confirmada','completada','pagada')
    )
    select jsonb_build_object(
      'deportistas',(select count(*) from public.usuarios_deportistas where estado=1),
      'gestores',(select count(*) from public.usuarios_instalaciones where estado=1),
      'complejos',(select count(*) from public.instituciones_deportivas where estado=1),
      'canchas',(select count(*) from public.areas_deportivas where lower(coalesce(estado,''))='activa'),
      'solicitudes_pendientes',(select count(*) from public.solicitudes_centros_deportivos where estado='pendiente'),
      'reclamos_abiertos',(select count(*) from public.reclamos where estado not in ('respondido','cerrado')),
      'ingresos_gestores',(select coalesce(sum(monto),0) from cobradas),
      'reservas_confirmadas',(select count(*) from cobradas),
      'por_metodo',(select coalesce(jsonb_agg(jsonb_build_object('metodo',metodo,'reservas',reservas,'monto',monto) order by monto desc),'[]'::jsonb) from (
        select coalesce(nullif(initcap(metodo_pago),''),'No registrado') metodo,count(*)::integer reservas,sum(monto) monto
        from cobradas group by coalesce(nullif(initcap(metodo_pago),''),'No registrado')
      ) x),
      'por_dia',(select coalesce(jsonb_agg(jsonb_build_object('fecha',fecha,'reservas',reservas,'monto',monto) order by fecha),'[]'::jsonb) from (
        select fecha::text fecha,count(*)::integer reservas,sum(monto) monto from cobradas group by fecha
      ) x),
      'por_institucion',(select coalesce(jsonb_agg(jsonb_build_object('institucion',institucion,'reservas',reservas,'monto',monto) order by reservas desc,monto desc),'[]'::jsonb) from (
        select institucion_id,institucion,count(*)::integer reservas,sum(monto) monto
        from cobradas group by institucion_id,institucion
      ) x)
    )
  ) else '{}'::jsonb end;
$$;
revoke all on function public.admin_estadisticas(date,date) from public;
grant execute on function public.admin_estadisticas(date,date) to authenticated;

create or replace function public.obtener_correo_soporte()
returns text language sql stable security definer set search_path = '' as $$
  select coalesce((select valor from public.configuracion_general where clave='soporte_email'),'');
$$;
revoke all on function public.obtener_correo_soporte() from public;
grant execute on function public.obtener_correo_soporte() to anon, authenticated;
