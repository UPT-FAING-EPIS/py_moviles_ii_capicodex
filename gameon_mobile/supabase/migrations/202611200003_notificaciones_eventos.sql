-- Destinatario unificado: deportistas y gestores comparten auth.users,
-- pero no la misma tabla de perfil.
alter table public.notificaciones
  add column if not exists destinatario_auth_id uuid references auth.users(id);

update public.notificaciones n
set destinatario_auth_id = u.auth_id
from public.usuarios_deportistas u
where n.usuario_id = u.id and n.destinatario_auth_id is null;

alter table public.notificaciones
  alter column usuario_id drop not null,
  alter column destinatario_auth_id set not null;

alter table public.usuarios_instalaciones
  add column if not exists fcm_token text;

drop policy if exists "Usuarios leen sus notificaciones" on public.notificaciones;
drop policy if exists "Usuarios crean sus notificaciones" on public.notificaciones;
drop policy if exists "Usuarios actualizan sus notificaciones" on public.notificaciones;

create policy "Destinatario lee sus notificaciones"
  on public.notificaciones for select to authenticated
  using (destinatario_auth_id = (select auth.uid()));

create policy "Destinatario actualiza sus notificaciones"
  on public.notificaciones for update to authenticated
  using (destinatario_auth_id = (select auth.uid()))
  with check (destinatario_auth_id = (select auth.uid()));

-- Mantiene una sola operación segura para registrar el token tanto si la
-- cuenta es deportista, gestora o tiene ambos roles.
create or replace function public.registrar_token_fcm(p_token text)
returns void language plpgsql security definer set search_path = '' as $$
begin
  if (select auth.uid()) is null then
    raise exception 'Inicia sesión' using errcode = '42501';
  end if;
  update public.usuarios_deportistas set fcm_token = nullif(trim(p_token), '')
    where auth_id = (select auth.uid());
  update public.usuarios_instalaciones set fcm_token = nullif(trim(p_token), '')
    where auth_id = (select auth.uid());
end;
$$;
revoke all on function public.registrar_token_fcm(text) from public;
grant execute on function public.registrar_token_fcm(text) to authenticated;

-- Registro persistente utilizado por chats y por la respuesta del asistente.
create or replace function public.crear_notificacion(
  p_destinatario uuid,
  p_titulo text,
  p_mensaje text,
  p_tipo text default 'general',
  p_referencia_id bigint default null
) returns bigint language plpgsql security definer set search_path = '' as $$
declare v_id bigint;
begin
  if (select auth.uid()) is null then
    raise exception 'Inicia sesión' using errcode = '42501';
  end if;
  if p_destinatario is null or length(trim(coalesce(p_titulo, ''))) = 0 then
    raise exception 'Notificación inválida' using errcode = '22023';
  end if;
  insert into public.notificaciones(destinatario_auth_id, titulo, mensaje, tipo, referencia_id)
  values (p_destinatario, left(trim(p_titulo), 120), left(coalesce(p_mensaje, ''), 500),
          coalesce(nullif(trim(p_tipo), ''), 'general'), p_referencia_id)
  returning id into v_id;
  return v_id;
end;
$$;
revoke all on function public.crear_notificacion(uuid, text, text, text, bigint) from public;
grant execute on function public.crear_notificacion(uuid, text, text, text, bigint) to authenticated;

-- Los flujos de reserva y Yape pasan por SQL/RPC; este trigger cubre todos
-- sin depender de una pantalla concreta de Flutter.
create or replace function public.notificar_evento_reserva()
returns trigger language plpgsql security definer set search_path = '' as $$
declare
  v_deportista_auth uuid;
  v_gestor_auth uuid;
  v_area text;
  v_es_yape boolean;
  v_estado text;
begin
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

drop trigger if exists notificar_evento_reserva on public.reservas;
create trigger notificar_evento_reserva
after insert or update of estado on public.reservas
for each row execute function public.notificar_evento_reserva();
