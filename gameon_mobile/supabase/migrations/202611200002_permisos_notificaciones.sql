-- La tabla se creó desde una migración; los roles de la API requieren
-- privilegios explícitos además de las políticas RLS ya definidas.
grant select, insert, update on table public.notificaciones to authenticated;
grant usage, select on sequence public.notificaciones_id_seq to authenticated;
