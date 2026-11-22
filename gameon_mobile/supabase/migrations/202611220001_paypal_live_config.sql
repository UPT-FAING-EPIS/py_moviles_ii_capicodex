-- Credenciales por gestor, cifradas por Supabase Vault. Ningún cliente recibe el secret.
create schema if not exists vault;
create extension if not exists supabase_vault with schema vault;

create table if not exists public.gestor_paypal_config (
  gestor_id integer primary key references public.usuarios_instalaciones(id) on delete cascade,
  client_id text not null,
  secret_id uuid not null,
  actualizado_en timestamptz not null default now()
);
alter table public.gestor_paypal_config enable row level security;
revoke all on public.gestor_paypal_config from anon, authenticated;

create or replace function public.configurar_paypal_gestor(p_client_id text, p_secret text)
returns void language plpgsql security definer set search_path = '' as $$
declare v_gestor integer; v_secret_id uuid;
begin
  select id into v_gestor from public.usuarios_instalaciones
  where auth_id = (select auth.uid()) and estado = 1;
  if v_gestor is null then raise exception 'Gestor no autorizado' using errcode='42501'; end if;
  if length(trim(coalesce(p_client_id,''))) < 20 or length(trim(coalesce(p_secret,''))) < 20 then
    raise exception 'Credenciales PayPal Live inválidas' using errcode='22023';
  end if;
  select secret_id into v_secret_id from public.gestor_paypal_config where gestor_id = v_gestor;
  if v_secret_id is null then
    v_secret_id := vault.create_secret(trim(p_secret), 'paypal-live-gestor-' || v_gestor::text);
  else
    perform vault.update_secret(v_secret_id, trim(p_secret));
  end if;
  insert into public.gestor_paypal_config(gestor_id,client_id,secret_id,actualizado_en)
  values(v_gestor,trim(p_client_id),v_secret_id,now())
  on conflict(gestor_id) do update set client_id=excluded.client_id,secret_id=excluded.secret_id,actualizado_en=now();
end;
$$;
revoke all on function public.configurar_paypal_gestor(text,text) from public;
grant execute on function public.configurar_paypal_gestor(text,text) to authenticated;

create or replace function public.estado_paypal_gestor()
returns jsonb language sql stable security definer set search_path = '' as $$
  select jsonb_build_object('configurado',exists(
    select 1 from public.gestor_paypal_config p join public.usuarios_instalaciones g on g.id=p.gestor_id
    where g.auth_id=(select auth.uid())
  ));
$$;
revoke all on function public.estado_paypal_gestor() from public;
grant execute on function public.estado_paypal_gestor() to authenticated;

-- La Edge Function utiliza la service role; nunca conceder esta lectura al cliente.
create or replace function public.paypal_credenciales_servidor(p_gestor_id integer)
returns jsonb language sql stable security definer set search_path = '' as $$
  select jsonb_build_object('client_id',p.client_id,'secret',s.decrypted_secret)
  from public.gestor_paypal_config p join vault.decrypted_secrets s on s.id=p.secret_id
  where p.gestor_id=p_gestor_id;
$$;
revoke all on function public.paypal_credenciales_servidor(integer) from public, anon, authenticated;
grant execute on function public.paypal_credenciales_servidor(integer) to service_role;
