-- Unifica credenciales PayPal en usuarios_instalaciones y Vault.
-- Compatible tanto si las migraciones 001/002 ya se aplicaron como si no.
alter table public.usuarios_instalaciones
  add column if not exists paypal_secret_id uuid;

-- Si hubo configuración mediante la pantalla nueva, conservarla.
update public.usuarios_instalaciones g
set paypal_client_id = p.client_id,
    paypal_secret_id = p.secret_id,
    paypal_enabled = 1,
    paypal_sandbox = 0
from public.gestor_paypal_config p
where g.id = p.gestor_id;

-- Las claves preexistentes se cifran y se retiran de la columna en claro.
do $$
declare v_gestor record;
begin
  for v_gestor in
    select id, paypal_client_secret
    from public.usuarios_instalaciones
    where paypal_secret_id is null
      and nullif(trim(paypal_client_secret), '') is not null
  loop
    update public.usuarios_instalaciones
    set paypal_secret_id = vault.create_secret(v_gestor.paypal_client_secret),
        paypal_client_secret = null
    where id = v_gestor.id;
  end loop;
end;
$$;
update public.usuarios_instalaciones
set paypal_client_secret = null
where paypal_secret_id is not null and paypal_client_secret is not null;

drop function if exists public.estado_paypal_gestor();
drop function if exists public.paypal_credenciales_servidor(integer);
drop table public.gestor_paypal_config;

-- Esta vista preserva la consulta de disponibilidad de la migración 002;
-- no guarda otra copia de las credenciales.
create view public.gestor_paypal_config as
select id as gestor_id, paypal_client_id as client_id, paypal_secret_id as secret_id
from public.usuarios_instalaciones
where paypal_enabled = 1 and coalesce(paypal_sandbox, 0) = 0
  and nullif(trim(paypal_client_id), '') is not null and paypal_secret_id is not null;
revoke all on public.gestor_paypal_config from public, anon, authenticated;
grant select on public.gestor_paypal_config to service_role;

create or replace function public.configurar_paypal_gestor(p_client_id text, p_secret text)
returns void language plpgsql security definer set search_path = '' as $$
declare v_gestor integer; v_secret_id uuid;
begin
  select id, paypal_secret_id into v_gestor, v_secret_id
  from public.usuarios_instalaciones
  where auth_id = (select auth.uid()) and estado = 1;
  if v_gestor is null then raise exception 'Gestor no autorizado' using errcode='42501'; end if;
  if length(trim(coalesce(p_client_id,''))) < 20 or length(trim(coalesce(p_secret,''))) < 20 then
    raise exception 'Credenciales PayPal Live inválidas' using errcode='22023';
  end if;
  if v_secret_id is null then
    v_secret_id := vault.create_secret(trim(p_secret));
  else
    perform vault.update_secret(v_secret_id, trim(p_secret));
  end if;
  update public.usuarios_instalaciones
  set paypal_client_id=trim(p_client_id), paypal_client_secret=null,
      paypal_secret_id=v_secret_id, paypal_enabled=1, paypal_sandbox=0
  where id=v_gestor;
end;
$$;
revoke all on function public.configurar_paypal_gestor(text,text) from public;
grant execute on function public.configurar_paypal_gestor(text,text) to authenticated;

create or replace function public.estado_paypal_gestor()
returns jsonb language sql stable security definer set search_path = '' as $$
  select jsonb_build_object('configurado',exists(
    select 1 from public.gestor_paypal_config p
    join public.usuarios_instalaciones g on g.id=p.gestor_id
    where g.auth_id=(select auth.uid())
  ));
$$;
revoke all on function public.estado_paypal_gestor() from public;
grant execute on function public.estado_paypal_gestor() to authenticated;

create or replace function public.paypal_credenciales_servidor(p_gestor_id integer)
returns jsonb language sql stable security definer set search_path = '' as $$
  select jsonb_build_object('client_id',p.client_id,'secret',s.decrypted_secret)
  from public.gestor_paypal_config p
  join vault.decrypted_secrets s on s.id=p.secret_id
  where p.gestor_id=p_gestor_id;
$$;
revoke all on function public.paypal_credenciales_servidor(integer) from public, anon, authenticated;
grant execute on function public.paypal_credenciales_servidor(integer) to service_role;

-- Reutiliza también el identificador de captura que ya existe en reservas.
create or replace function public.sincronizar_captura_paypal()
returns trigger language plpgsql security definer set search_path = '' as $$
begin
  if new.estado = 'completado' and new.capture_id is not null then
    update public.reservas set paypal_capture_id = new.capture_id
    where id = new.reserva_id;
  end if;
  return new;
end;
$$;
create trigger sincronizar_captura_paypal
after update of estado on public.paypal_intentos_reserva
for each row when (new.estado = 'completado')
execute function public.sincronizar_captura_paypal();
