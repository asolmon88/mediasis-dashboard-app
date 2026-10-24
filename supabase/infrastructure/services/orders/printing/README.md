# Receipt printing

`01_receipt_print_data.sql` exposes the order-app receipt contract to the
authenticated dashboard. The function validates ownership of the requested
location and order before resolving the order-app domain, loading the existing
receipt payload, and merging the order cashback summary.

The Flutter app consumes this through:

`GET /api/orders/receipt-print-data?order_id=...&business_location_id=...`

Receipt/customer payloads are used in memory and are never stored on the
device. Visual receipts are rendered from the canonical order-app print page,
converted to ESC/POS raster bytes, and cached briefly in the private
`receipt-print-renders` Storage bucket created by
`03_receipt_render_cache.sql`.

Apply `00_receipt_print_sanitizer.sql` before the receipt-data functions. It
normalizes response strings to printable ASCII without modifying stored order
data, preventing unsupported Unicode characters from rejecting a print job.

The dashboard and Supabase Edge Functions must share
`RECEIPT_RENDER_INTERNAL_SECRET`. Edge Functions also require
`DASHBOARD_API_BASE_URL`. The Vercel dashboard should define
`ORDER_APP_BASE_URL` as the canonical order-app origin for legacy relative
receipt URLs. Deploy both `notify-new-order` and `background-print-receipt`
after applying the cache-bucket SQL.

Example configuration and deployment:

```bash
supabase secrets set \
  RECEIPT_RENDER_INTERNAL_SECRET='replace-with-a-strong-secret' \
  DASHBOARD_API_BASE_URL='https://dashboard.mediasis.cr'
supabase functions deploy background-print-receipt
supabase functions deploy notify-new-order
```
