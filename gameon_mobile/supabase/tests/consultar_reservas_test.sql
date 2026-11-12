begin;
set local role authenticated;
select set_config('request.jwt.claim.sub','00000000-0000-0000-0000-000000000001',true);
do $$
declare total integer; payload jsonb;
begin
  select count(*) into total from public.consultar_reservas_gestor(array[10,20,30]::bigint[]);
  assert total = 2, 'Solo instalaciones propias, incluso enviando áreas ajenas';
  select count(*) into total from public.consultar_reservas_gestor(array[20]::bigint[]);
  assert total = 0, 'Área ajena denegada';
  select count(*) into total from public.consultar_reservas_gestor(array[]::bigint[]);
  assert total = 0, 'Sin áreas no devuelve reservas';
  select to_jsonb(r) into payload from public.consultar_reservas_gestor(array[10,30]::bigint[], '2026-11-12') r;
  assert payload->>'id' = '1', 'Filtro por fecha';
  assert (select count(*) from jsonb_object_keys(payload)) = 8
    and payload ?& array['id','area_deportiva_id','fecha','hora_inicio','hora_fin','estado','monto_pagado','metodo_pago'],
    'Proyección mínima sin identidad del cliente ni datos de cobro';
  select to_jsonb(r) into payload from public.consultar_reservas_gestor(array[10,30]::bigint[], null, 1, 1) r;
  assert payload->>'id' = '1', 'Paginación y orden estable';
  begin
    perform public.consultar_reservas_gestor(array[10]::bigint[], null, -1);
    raise exception 'Aceptó offset inválido';
  exception when invalid_parameter_value then null; end;
end;
$$;
select set_config('request.jwt.claim.sub','00000000-0000-0000-0000-000000000002',true);
do $$ begin
  assert (select array_agg(id) from public.consultar_reservas_gestor(array[10,20,30]::bigint[])) = array[2]::bigint[], 'Segundo gestor aislado';
end $$;
do $$
declare uid text;
begin
  foreach uid in array array['00000000-0000-0000-0000-000000000003','00000000-0000-0000-0000-000000000004',''] loop
    perform set_config('request.jwt.claim.sub',uid,true);
    begin
      perform public.consultar_reservas_gestor(array[10]::bigint[]);
      raise exception 'Aceptó cuenta inactiva, no gestora o sin sesión';
    exception when insufficient_privilege then null; end;
  end loop;
end $$;
reset role;
do $$ begin
  assert not has_function_privilege('anon','public.consultar_reservas_gestor(bigint[],date,integer,integer)','EXECUTE'), 'Anónimo sin permiso';
end $$;
rollback;
