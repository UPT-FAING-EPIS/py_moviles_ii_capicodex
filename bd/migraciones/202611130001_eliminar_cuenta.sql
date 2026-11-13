-- US-30: eliminación de cuenta con borrado de datos personales.
-- Esta migración debe aplicarse con el rol propietario de la base de datos.
begin;

-- El comprobante conserva únicamente que hubo una solicitud y cuándo ocurrió;
-- no incluye usuario, correo ni otro dato que permita identificar a la persona.
create table if not exists public.solicitudes_eliminacion_cuenta (
  id uuid primary key default gen_random_uuid(),
  solicitada_en timestamptz not null default now()
);

revoke all on public.solicitudes_eliminacion_cuenta from public, anon, authenticated;

create or replace function public.eliminar_cuenta_actual()
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_auth_id uuid := auth.uid();
  v_usuario_id integer;
  v_gestor_id integer;
  v_solicitud_id uuid;
begin
  if v_auth_id is null then
    raise exception 'Inicia sesión para eliminar tu cuenta' using errcode = '42501';
  end if;

  -- Se crea un comprobante no vinculable antes de borrar los datos personales.
  insert into public.solicitudes_eliminacion_cuenta default values
  returning id into v_solicitud_id;

  select id into v_usuario_id
  from public.usuarios_deportistas
  where auth_id = v_auth_id;

  if v_usuario_id is not null then
    -- Compatibilidad con las relaciones históricas que no tienen ON DELETE
    -- CASCADE. Las relaciones recientes (favoritos, historial y
    -- calificaciones) se borran además por sus cascadas.
    delete from public.amistades
      where usuario_solicitante_id = v_usuario_id
         or usuario_receptor_id = v_usuario_id;
    delete from public.equipo_miembros
      where usuario_id = v_usuario_id
         or equipo_id in (
           select id from public.equipos where creador_id = v_usuario_id
         );
    delete from public.equipos where creador_id = v_usuario_id;
    delete from public.usuarios_deportes where usuario_id = v_usuario_id;
    delete from public.instalaciones_ocupaciones
      where usuario_reserva_id = v_usuario_id
         or creado_por_usuario_id = v_usuario_id;
    delete from public.reservas where id_usuario = v_usuario_id;
    delete from public.usuarios_deportistas where id = v_usuario_id;
  end if;

  select id into v_gestor_id
  from public.usuarios_instalaciones where auth_id = v_auth_id;

  if v_gestor_id is not null then
    -- Si la cuenta habilitó el rol gestor, sus centros y dependencias también
    -- son datos de la cuenta. Se eliminan en orden para admitir FKs restrictivas.
    delete from public.reservas r
      using public.areas_deportivas a, public.instituciones_deportivas i
      where r.area_deportiva_id = a.id
        and a.institucion_deportiva_id = i.id
        and i.usuario_instalacion_id = v_gestor_id;
    delete from public.instalaciones_ocupaciones o
      using public.instituciones_deportivas i
      where o.institucion_deportiva_id = i.id
        and i.usuario_instalacion_id = v_gestor_id;
    delete from public.areas_horarios h
      using public.areas_deportivas a, public.instituciones_deportivas i
      where h.area_deportiva_id = a.id
        and a.institucion_deportiva_id = i.id
        and i.usuario_instalacion_id = v_gestor_id;
    delete from public.instituciones_deportes d
      using public.instituciones_deportivas i
      where d.institucion_deportiva_id = i.id
        and i.usuario_instalacion_id = v_gestor_id;
    delete from public.areas_deportivas a
      using public.instituciones_deportivas i
      where a.institucion_deportiva_id = i.id
        and i.usuario_instalacion_id = v_gestor_id;
    delete from public.horarios_atencion h
      using public.instituciones_deportivas i
      where h.institucion_deportiva_id = i.id
        and i.usuario_instalacion_id = v_gestor_id;
    delete from public.instituciones_deportivas
      where usuario_instalacion_id = v_gestor_id;
    delete from public.usuarios_instalaciones where id = v_gestor_id;
  end if;

  -- El usuario solamente puede borrar su propia identidad: v_auth_id procede
  -- de auth.uid(), nunca de un parámetro enviado por el cliente.
  delete from auth.users where id = v_auth_id;
  return v_solicitud_id;
end;
$$;

revoke all on function public.eliminar_cuenta_actual() from public, anon;
grant execute on function public.eliminar_cuenta_actual() to authenticated;

commit;
