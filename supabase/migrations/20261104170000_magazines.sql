-- Promotional magazines («المجلات»): a cover, a PDF and the date range the
-- magazine is on offer. Customers see only magazines whose range covers
-- today; administrators (profiles.role = 'admin') manage them. Safe to
-- re-run, and repairs a partially created table.

-- Security definer so policies can call it without recursing into profiles RLS.
create or replace function public.is_admin()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1 from public.profiles
    where id = auth.uid() and role = 'admin'
  );
$$;

create table if not exists public.magazines (
  id uuid primary key default gen_random_uuid()
);

alter table public.magazines
  add column if not exists title text not null default '',
  add column if not exists cover_image_url text not null default '',
  add column if not exists pdf_url text not null default '',
  add column if not exists start_date date not null default current_date,
  add column if not exists end_date date not null default (current_date + 30),
  add column if not exists created_at timestamptz not null default now();

alter table public.magazines drop constraint if exists magazines_dates_check;
alter table public.magazines
  add constraint magazines_dates_check check (end_date >= start_date);

create index if not exists magazines_dates_idx
  on public.magazines (start_date, end_date);

alter table public.magazines enable row level security;

grant select on public.magazines to anon, authenticated;
grant insert, update, delete on public.magazines to authenticated;

drop policy if exists "magazines_public_select_current" on public.magazines;
create policy "magazines_public_select_current" on public.magazines
  for select to anon, authenticated
  using (current_date between start_date and end_date);

drop policy if exists "magazines_admin_all" on public.magazines;
create policy "magazines_admin_all" on public.magazines
  for all to authenticated
  using (public.is_admin())
  with check (public.is_admin());

-- Covers and PDFs live in a public bucket; only administrators write to it.
insert into storage.buckets (id, name, public)
values ('magazines', 'magazines', true)
on conflict (id) do update set public = excluded.public;

drop policy if exists "magazines_bucket_public_read" on storage.objects;
create policy "magazines_bucket_public_read" on storage.objects
  for select to anon, authenticated
  using (bucket_id = 'magazines');

drop policy if exists "magazines_bucket_admin_write" on storage.objects;
create policy "magazines_bucket_admin_write" on storage.objects
  for all to authenticated
  using (bucket_id = 'magazines' and public.is_admin())
  with check (bucket_id = 'magazines' and public.is_admin());
