-- Home screen brand/company ad banners («إعلانات الشركات»): a full-bleed
-- image, a title and the product-name keyword whose products open when the
-- banner is tapped. Everyone reads active banners; administrators manage
-- them from the app. Safe to re-run; needs public.is_admin() from the
-- magazines migration.

create table if not exists public.home_banners (
  id uuid primary key default gen_random_uuid()
);

alter table public.home_banners
  add column if not exists title text not null default '',
  add column if not exists image_url text not null default '',
  add column if not exists brand_query text not null default '',
  add column if not exists sort_order integer not null default 0,
  add column if not exists is_active boolean not null default true,
  add column if not exists created_at timestamptz not null default now();

create index if not exists home_banners_order_idx
  on public.home_banners (is_active, sort_order, created_at);

alter table public.home_banners enable row level security;

grant select on public.home_banners to anon, authenticated;
grant insert, update, delete on public.home_banners to authenticated;

drop policy if exists "home_banners_public_select_active" on public.home_banners;
create policy "home_banners_public_select_active" on public.home_banners
  for select to anon, authenticated
  using (is_active);

drop policy if exists "home_banners_admin_all" on public.home_banners;
create policy "home_banners_admin_all" on public.home_banners
  for all to authenticated
  using (public.is_admin())
  with check (public.is_admin());

-- Banner images live in a public bucket; only administrators write to it.
insert into storage.buckets (id, name, public)
values ('banners', 'banners', true)
on conflict (id) do update set public = excluded.public;

drop policy if exists "banners_bucket_public_read" on storage.objects;
create policy "banners_bucket_public_read" on storage.objects
  for select to anon, authenticated
  using (bucket_id = 'banners');

drop policy if exists "banners_bucket_admin_write" on storage.objects;
create policy "banners_bucket_admin_write" on storage.objects
  for all to authenticated
  using (bucket_id = 'banners' and public.is_admin())
  with check (bucket_id = 'banners' and public.is_admin());
