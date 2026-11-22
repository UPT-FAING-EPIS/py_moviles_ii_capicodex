-- Los gestores sin credenciales completas no deben figurar con PayPal habilitado.
-- Se conservan sus demás datos; podrán activar el cobro al configurar Live.
update public.usuarios_instalaciones
set paypal_enabled = 0
where paypal_enabled = 1
  and (
    paypal_secret_id is null
    or nullif(trim(paypal_client_id), '') is null
  );
