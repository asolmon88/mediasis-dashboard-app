# Supabase Architecture

This directory follows the application's service-oriented structure. SQL files
are grouped by the Dart service or feature that consumes them instead of by a
global timestamp sequence.

## Infrastructure services

### Products

Path: `infrastructure/services/products/`

- `01_product_variant_visibility.sql` adds variant availability and the RPCs
  consumed by Flutter's `SupabaseProductsService` through the dashboard routes
  `/api/products/variants` and `/api/products/variant-visibility`.
- `README.md` maps each database object to its dashboard API route and Flutter
  consumer.
- Product visibility uses `/api/products/product-visibility`, which calls the
  existing `show_product_at_location` and `hide_product_at_location` RPCs.

### Push notifications

Path: `infrastructure/services/push_notifications/`

- `01_new_order_push_notifications.sql` owns subscription registration,
  delivery tracking, and the RPCs used by `PushNotificationService` and
  `PushNotificationsCubit`.
- `02_new_order_push_webhook.sql` owns the order update trigger that invokes the
  `notify-new-order` Edge Function.
- `README.md` documents secrets, deployment, and verification for this feature.

## Edge Functions

Path: `functions/notify-new-order/`

The Edge Function remains under `supabase/functions` because the Supabase CLI
requires this path for local serving and deployment. It consumes the database
objects under `infrastructure/services/push_notifications/`.

Path: `functions/background-print-receipt/`

This function validates short-lived OneSignal print authorizations and returns
ESC/POS bytes to the Android and iOS notification service extensions. It uses
the service-role-only RPC under `infrastructure/services/orders/printing/`.

## Applying SQL

Apply files in numeric order within each service folder. These files are not
automatically discovered by `supabase db push`; apply them deliberately through
the Supabase SQL editor or convert the required change into a deployment
migration when using the CLI.
