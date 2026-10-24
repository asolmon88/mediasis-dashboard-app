# New-order push notification backend

These files are intentionally prepared for manual deployment. Applying the
SQL or deploying the Edge Function changes the production Supabase
project, so review and upload each part separately.

## 1. Apply the database SQL

Run the contents of:

`supabase/infrastructure/services/push_notifications/01_new_order_push_notifications.sql`

The SQL creates:

- `mediasis.new_order_push_subscriptions`, a private per-device registry.
- `mediasis.new_order_push_deliveries`, an idempotent delivery log.
- Authenticated RPCs to register and disable a device subscription.
- Service-role-only RPCs used by the Edge Function to claim and complete sends.

No database trigger is created by this first SQL file.

## 2. Configure Edge Function secrets

The following two secrets should already exist:

- `ONESIGNAL_NEW_ORDER_APP_ID`
- `ONESIGNAL_NEW_ORDER_REST_API_KEY`

Background receipt printing additionally requires:

- `BACKGROUND_PRINT_SIGNING_SECRET`

Use the same random value of at least 32 bytes for both Edge Functions. It
signs a ten-minute, order-specific authorization and is never bundled in the
application.

Generate a new random value of at least 32 bytes and save it as:

- `ONESIGNAL_NEW_ORDER_WEBHOOK_SECRET`

Do not place any of these values in source control. The webhook secret must be
copied later into the database webhook's `x-mediasis-webhook-secret` header.

## 3. Deploy the Edge Function

Create a function named `notify-new-order` using:

`supabase/functions/notify-new-order/index.ts`

JWT verification must be disabled because the caller is a database webhook.
The function authenticates the request using the private webhook header
instead. The repository's `supabase/config.toml` contains this setting for CLI
deployment.

CLI equivalent:

```bash
supabase functions deploy notify-new-order --no-verify-jwt
supabase functions deploy background-print-receipt --no-verify-jwt
```

Apply
`supabase/infrastructure/services/orders/printing/02_background_receipt_print_data.sql`
before deploying `background-print-receipt`. Its RPC is restricted to
`service_role`.

Do not create the database webhook until the function is deployed and its URL
returns `401 Invalid webhook secret` for an unauthenticated POST. That response
confirms the function is reachable and enforcing its private header.

## 4. Create the UPDATE-only database webhook

The current Supabase dashboard does not expose the Database Webhooks screen, so
the equivalent webhook is installed as a PostgreSQL trigger.

First, save the same webhook secret in Supabase Vault. Replace the placeholder
locally before running this statement in SQL Editor:

```sql
select vault.create_secret(
  'PASTE_THE_SAME_WEBHOOK_SECRET_HERE',
  'ONESIGNAL_NEW_ORDER_WEBHOOK_SECRET',
  'Shared secret for the new-order Edge Function database trigger'
);
```

Edge Function Secrets and Vault are separate stores. The value must match the
existing Edge Function secret exactly. Do not save the real value in this
repository.

Then run:

`supabase/infrastructure/services/push_notifications/02_new_order_push_webhook.sql`

This creates `mediasis.notify_new_order_edge_function()` and the
`notify_new_order_on_order_update` trigger. The trigger:

- Fires on `UPDATE` only, never `INSERT`.
- Queues HTTP asynchronously through `pg_net`.
- Fires only when a field used by `mediasis.is_order_paid(...)` changes.
- Reads the private request header from Vault.
- Catches all webhook errors so notifications can never roll back an order.

The Edge Function sends only when an UPDATE changes the result of the exact
seven-argument `mediasis.is_order_paid(...)` overload from `false` to `true`. It
calls that database function for both `old_record` and the freshly reloaded
order, so payment and courier rules remain centralized in the database.

Every event is re-read from the database. The webhook payload alone is never
trusted to authorize a notification.

## 5. Verification before mobile integration

Until the Flutter app registers a OneSignal subscription, an eligible order
will complete with `no_subscribers`; this is expected.

After mobile registration is implemented:

1. Use a test device and location.
2. Confirm one enabled row exists in
   `mediasis.new_order_push_subscriptions`.
3. Update a test order through each payment/assignment stage.
4. Confirm no push is sent before all relevant conditions are met.
5. Confirm exactly one row appears in `mediasis.new_order_push_deliveries`.
6. Confirm later updates to the same order do not send another push.

Function responses and failures are available under **Edge Function Logs**.
Database webhook request history is available through Supabase's `net` schema.
