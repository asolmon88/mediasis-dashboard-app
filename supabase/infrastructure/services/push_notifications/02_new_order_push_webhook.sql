-- Connects eligible order updates to the notify-new-order Edge Function.

create or replace function mediasis.notify_new_order_edge_function()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_webhook_secret text;
begin
  select decrypted_secret
  into v_webhook_secret
  from vault.decrypted_secrets
  where name = 'ONESIGNAL_NEW_ORDER_WEBHOOK_SECRET'
  limit 1;

  if nullif(trim(v_webhook_secret), '') is null then
    raise warning
      'New-order notification skipped: Vault secret ONESIGNAL_NEW_ORDER_WEBHOOK_SECRET is missing';
    return new;
  end if;

  perform net.http_post(
    url := 'https://server.mediasis.cr/functions/v1/notify-new-order',
    body := jsonb_build_object(
      'type', tg_op,
      'table', tg_table_name,
      'schema', tg_table_schema,
      'record', to_jsonb(new),
      'old_record', to_jsonb(old)
    ),
    params := '{}'::jsonb,
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'x-mediasis-webhook-secret', v_webhook_secret
    ),
    timeout_milliseconds := 5000
  );

  return new;
exception
  when others then
    -- Push delivery must never block or roll back an order update.
    raise warning 'New-order notification webhook could not be queued: %', sqlerrm;
    return new;
end;
$$;

revoke all on function mediasis.notify_new_order_edge_function()
  from public, anon, authenticated;

drop trigger if exists notify_new_order_on_order_update on mediasis.orders;

create trigger notify_new_order_on_order_update
after update of
  order_status,
  products_payment_status,
  products_payment_intent_id,
  delivery_payment_status,
  delivery_method,
  tracking_link,
  uber_delivery_id
on mediasis.orders
for each row
when (
  old.order_status is distinct from new.order_status
  or old.products_payment_status is distinct from new.products_payment_status
  or old.products_payment_intent_id is distinct from new.products_payment_intent_id
  or old.delivery_payment_status is distinct from new.delivery_payment_status
  or old.delivery_method is distinct from new.delivery_method
  or old.tracking_link is distinct from new.tracking_link
  or old.uber_delivery_id is distinct from new.uber_delivery_id
)
execute function mediasis.notify_new_order_edge_function();
