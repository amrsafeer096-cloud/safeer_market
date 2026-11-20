-- InstaPay transfer screenshots: store public receipt URLs on orders and
-- allow authenticated customers to upload images under their own folder.

alter table public.orders
  drop constraint if exists orders_payment_status_check;

alter table public.orders
  add constraint orders_payment_status_check
  check (
    payment_status in (
      'unpaid',
      'pending',
      'pending_verification',
      'paid',
      'failed'
    )
  );

alter table public.orders
  add column if not exists receipt_url text;

comment on column public.orders.receipt_url is
  'Public URL of the InstaPay transfer screenshot uploaded by the customer.';

comment on column public.orders.payment_status is
  'Settlement state: COD unpaid; card pending/paid/failed; InstaPay pending_verification until admin confirms.';

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'payment_receipts',
  'payment_receipts',
  true,
  10485760, -- 10 MB
  array['image/jpeg', 'image/png', 'image/webp', 'image/gif', 'image/heic']
)
on conflict (id) do update set
  public = excluded.public,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

drop policy if exists "payment_receipts_public_read" on storage.objects;
create policy "payment_receipts_public_read" on storage.objects
  for select to public
  using (bucket_id = 'payment_receipts');

drop policy if exists "payment_receipts_auth_upload" on storage.objects;
create policy "payment_receipts_auth_upload" on storage.objects
  for insert to authenticated
  with check (
    bucket_id = 'payment_receipts'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

drop policy if exists "payment_receipts_auth_update" on storage.objects;
create policy "payment_receipts_auth_update" on storage.objects
  for update to authenticated
  using (
    bucket_id = 'payment_receipts'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

drop policy if exists "payment_receipts_auth_delete" on storage.objects;
create policy "payment_receipts_auth_delete" on storage.objects
  for delete to authenticated
  using (
    bucket_id = 'payment_receipts'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

notify pgrst, 'reload schema';
