-- Una reserva presencial puede pertenecer a un cliente sin cuenta GameOn.
-- Esas reservas no tienen destinatario de notificación y por tanto no deben
-- ejecutar el flujo de avisos diseñado para deportistas autenticados.
create or replace function public.notificar_evento_reserva()
returns trigger language plpgsql security definer set search_path = '' as $$
declare
  v_deportista_auth uuid;
  v_gestor_auth uuid;
  v_area text;
  v_es_yape boolean;
  v_estado text;
begin
  if new.id_usuario is null then
    return new;
  end if;

  select auth_id into v_deportista_auth
  from public.usuarios_deportistas where id = new.id_usuario;

  select g.auth_id, coalesce(a.nombre_area, 'la cancha')
    into v_gestor_auth, v_area
  from public.areas_deportivas a
  join public.instituciones_deportivas i on i.id = a.institucion_deportiva_id
  join public.usuarios_instalaciones g on g.id = i.usuario_instalacion_id
  where a.id = new.area_deportiva_id;

  v_es_yape := lower(coalesce(new.metodo_pago, '')) = 'yape';
  v_estado := lower(coalesce(new.estado, 'pendiente'));

  if tg_op = 'INSERT' then
    if v_es_yape then
      insert into public.notificaciones(destinatario_auth_id, usuario_id, titulo, mensaje, tipo, referencia_id)
      values (v_deportista_auth, new.id_usuario, 'Evidencia Yape enviada',
              'Tu pago para $v_area está pendiente de revisión.', 'pago', new.id);
      if v_gestor_auth is not null then
        insert into public.notificaciones(destinatario_auth_id, titulo, mensaje, tipo, referencia_id)
        values (v_gestor_auth, 'Pago Yape por verificar',
                'Recibiste una evidencia de pago para $v_area.', 'pago', new.id);
      end if;
    else
      insert into public.notificaciones(destinatario_auth_id, usuario_id, titulo, mensaje, tipo, referencia_id)
      values (v_deportista_auth, new.id_usuario,
              case when v_estado = 'confirmada' then 'Reserva confirmada' else 'Reserva registrada' end,
              'Tu reserva para $v_area fue registrada.', 'reserva', new.id);
      if v_gestor_auth is not null then
        insert into public.notificaciones(destinatario_auth_id, titulo, mensaje, tipo, referencia_id)
        values (v_gestor_auth, 'Nueva reserva',
                'Tienes una nueva reserva para $v_area.', 'reserva', new.id);
      end if;
    end if;
  elsif tg_op = 'UPDATE' and old.estado is distinct from new.estado then
    insert into public.notificaciones(destinatario_auth_id, usuario_id, titulo, mensaje, tipo, referencia_id)
    values (v_deportista_auth, new.id_usuario,
            case when v_estado = 'confirmada' then 'Reserva confirmada'
                 when v_estado = 'cancelada' then 'Reserva rechazada'
                 else 'Reserva actualizada' end,
            'El estado de tu reserva para $v_area ahora es: ' || coalesce(new.estado, 'actualizado') || '.',
            'reserva', new.id);
    if v_gestor_auth is not null then
      insert into public.notificaciones(destinatario_auth_id, titulo, mensaje, tipo, referencia_id)
      values (v_gestor_auth, 'Reserva actualizada',
              'La reserva de $v_area quedó ' || coalesce(new.estado, 'actualizada') || '.',
              'reserva', new.id);
    end if;
  end if;
  return new;
end;
$$;
