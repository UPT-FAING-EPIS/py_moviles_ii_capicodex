begin;
insert into public.usuarios_deportistas values
 (1, '11111111-1111-1111-1111-111111111111'),
 (2, '22222222-2222-2222-2222-222222222222');
insert into public.areas_horarios
select 1, unnest(array['Lunes','Martes','Miércoles','Jueves','Viernes','Sábado','Domingo']), 1, '08:00', '23:00';
insert into public.reservas(id,id_usuario,area_deportiva_id,fecha,hora_inicio,hora_fin,estado,monto_pagado,metodo_pago) values
 (16,1,1,current_date + 30,'10:00','11:00','Confirmada',60,'paypal'),
 (17,2,1,current_date + 30,'18:00','19:00','Confirmada',60,'paypal'),
 (18,1,1,current_date + 30,'20:00','21:00','Cancelada',60,'paypal');
select set_config('request.jwt.claim.sub','11111111-1111-1111-1111-111111111111',true);
do $$
declare r public.reservas; total integer;
begin
  r := public.reprogramar_reserva(16, current_date + 30, '12:00');
  select count(*) into total from public.reservas;
  assert r.id = 16 and total = 3, 'No debe insertar otra reserva';
  assert r.hora_fin = '13:00' and r.monto_pagado = 60 and r.metodo_pago = 'paypal';
  r := public.reprogramar_reserva(16, current_date + 30, '12:00');
  assert r.id = 16, 'Reintentar no duplica';
  begin
    perform public.reprogramar_reserva(16, current_date + 30, '18:30');
    raise exception 'Debe rechazar solapamiento';
  exception when exclusion_violation then null; end;
  assert (select hora_inicio = '12:00' from public.reservas where id = 16), 'Conflicto conserva horario';
  begin
    perform public.reprogramar_reserva(17, current_date + 30, '15:00');
    raise exception 'Debe rechazar reserva ajena';
  exception when insufficient_privilege then null; end;
  begin
    perform public.reprogramar_reserva(18, current_date + 30, '15:00');
    raise exception 'Debe rechazar reserva cancelada';
  exception when invalid_parameter_value then null; end;
  begin
    perform public.reprogramar_reserva(16, current_date - 1, '15:00');
    raise exception 'Debe rechazar fecha pasada';
  exception when invalid_parameter_value then null; end;
  begin
    perform public.reprogramar_reserva(16, current_date + 30, '23:30');
    raise exception 'Debe rechazar cruce de medianoche';
  exception when invalid_parameter_value then null; end;
  begin
    perform public.reprogramar_reserva(16, current_date + 30, '07:00');
    raise exception 'Debe rechazar horario cerrado';
  exception when invalid_parameter_value then null; end;
  -- El extremo final no bloquea el inicio del siguiente turno.
  r := public.reprogramar_reserva(16, current_date + 30, '17:00');
  assert r.hora_fin = '18:00';
  -- Una reserva cancelada libera el horario, sin importar las mayúsculas.
  r := public.reprogramar_reserva(16, current_date + 30, '20:00');
  assert r.hora_inicio = '20:00';
  perform set_config('request.jwt.claim.sub','',true);
  begin
    perform public.reprogramar_reserva(16, current_date + 30, '15:00');
    raise exception 'Debe exigir autenticación';
  exception when insufficient_privilege then null; end;
end $$;
rollback;
