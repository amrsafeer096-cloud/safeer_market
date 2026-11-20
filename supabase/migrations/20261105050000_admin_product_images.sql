-- Lets administrators change product photos (and the active switch) from the
-- app. Without an UPDATE policy, RLS makes the app's
-- `update({'image_url': ...})` match zero rows without any error, so the
-- upload "succeeded" but the product kept its old link. Safe to re-run, and
-- also fine to paste into the Supabase SQL Editor.
--
-- The import scripts use the service-role key, which bypasses RLS.

alter table public.products enable row level security;

-- Everyone keeps reading the catalog.
grant select on public.products to anon, authenticated;
drop policy if exists "products_public_select" on public.products;
create policy "products_public_select" on public.products
  for select to anon, authenticated
  using (true);

-- Only administrators change products.
grant update on public.products to authenticated;
drop policy if exists "products_admin_update" on public.products;
create policy "products_admin_update" on public.products
  for update to authenticated
  using (public.is_admin())
  with check (public.is_admin());

-- Photos live in the public product_images bucket; only administrators write
-- to it (insert, and update for replacing a photo with the same name).
insert into storage.buckets (id, name, public)
values ('product_images', 'product_images', true)
on conflict (id) do update set public = excluded.public;

drop policy if exists "product_images_public_read" on storage.objects;
create policy "product_images_public_read" on storage.objects
  for select to anon, authenticated
  using (bucket_id = 'product_images');

drop policy if exists "product_images_admin_write" on storage.objects;
create policy "product_images_admin_write" on storage.objects
  for all to authenticated
  using (bucket_id = 'product_images' and public.is_admin())
  with check (bucket_id = 'product_images' and public.is_admin());
