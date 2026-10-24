insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'receipt-print-renders',
  'receipt-print-renders',
  false,
  5242880,
  array['application/vnd.mediasis.escpos']
)
on conflict (id) do update set
  public = excluded.public,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

-- No storage.objects policies are created. Access remains service-role only.
