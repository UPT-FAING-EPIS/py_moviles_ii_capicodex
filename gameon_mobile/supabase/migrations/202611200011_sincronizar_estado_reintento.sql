-- Garantiza que el estado de la cuenta no quede "pendiente" cuando el
-- administrador ya rechazó la última solicitud de su primer complejo.
update public.usuarios_instalaciones g
set estado = -1
where g.estado = 0
  and exists (
    select 1 from public.solicitudes_centros_deportivos s
    where s.gestor_id = g.id and s.estado = 'rechazada'
  )
  and not exists (
    select 1 from public.solicitudes_centros_deportivos s
    where s.gestor_id = g.id and s.estado = 'pendiente'
  );

create or replace function public.sincronizar_estado_solicitud_centro()
returns trigger language plpgsql security definer set search_path = '' as $$
begin
  if old.estado = 'pendiente' and new.estado = 'rechazada' then
    update public.usuarios_instalaciones
    set estado = -1
    where id = new.gestor_id and estado = 0;
  elsif old.estado = 'pendiente' and new.estado = 'aprobada' then
    update public.usuarios_instalaciones
    set estado = 1
    where id = new.gestor_id and estado in (0, -1);
  end if;
  return new;
end;
$$;

drop trigger if exists sincronizar_estado_solicitud_centro_trigger
  on public.solicitudes_centros_deportivos;
create trigger sincronizar_estado_solicitud_centro_trigger
after update of estado on public.solicitudes_centros_deportivos
for each row execute function public.sincronizar_estado_solicitud_centro();
