-- Miembros del canal administrativo compartido. Solo un ADM puede consultar
-- la lista; las cuentas normales nunca reciben los identificadores.
create or replace function public.admin_canal_miembros()
returns jsonb language sql stable security definer set search_path = '' as $$
  select case when public.es_admin() then
    coalesce((select jsonb_agg(auth_id::text order by auth_id::text)
      from public.roles_aplicacion where rol='ADM'),'[]'::jsonb)
  else '[]'::jsonb end;
$$;
revoke all on function public.admin_canal_miembros() from public;
grant execute on function public.admin_canal_miembros() to authenticated;
