-- Fixes found on production (2026-11-08):
--   * public.addresses had RLS switched off, plus legacy INSERT/SELECT
--     policies and no UPDATE policy — with RLS on, saving a map pin matched
--     zero rows («تعذر حفظ موقع العنوان»). 20261009233000 was never applied.
--   * addresses.user_id references profiles(id), but nothing creates a
--     profiles row on sign-up; a user without one can't add an address.
--   * profiles.loyalty_points is nullable there, with no default.

-- 1. addresses: own rows for every signed-in user; admins manage all.
alter table public.addresses enable row level security;
alter table public.addresses alter column user_id set default auth.uid();

drop policy if exists "Allow authenticated users to insert their own addresses"
  on public.addresses;
drop policy if exists "Allow authenticated users to select their own addresses"
  on public.addresses;
drop policy if exists "Enable insert for users based on user_id"
  on public.addresses;
drop policy if exists "addresses_select_own" on public.addresses;
drop policy if exists "addresses_insert_own" on public.addresses;
drop policy if exists "addresses_update_own" on public.addresses;
drop policy if exists "addresses_delete_own" on public.addresses;
drop policy if exists "addresses_admin_all" on public.addresses;

create policy "addresses_select_own" on public.addresses
  for select to authenticated
  using ((select auth.uid()) = user_id);

create policy "addresses_insert_own" on public.addresses
  for insert to authenticated
  with check ((select auth.uid()) = user_id);

create policy "addresses_update_own" on public.addresses
  for update to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);

create policy "addresses_delete_own" on public.addresses
  for delete to authenticated
  using ((select auth.uid()) = user_id);

create policy "addresses_admin_all" on public.addresses
  for all to authenticated
  using (public.is_admin())
  with check (public.is_admin());

-- 2. Every user has a profiles row: backfill, then create one on sign-up.
insert into public.profiles (id)
select u.id
from auth.users u
where not exists (select 1 from public.profiles p where p.id = u.id)
on conflict (id) do nothing;

create or replace function public.create_profile_for_new_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.profiles (id) values (new.id)
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists create_profile_for_new_user on auth.users;
create trigger create_profile_for_new_user
  after insert on auth.users
  for each row execute function public.create_profile_for_new_user();

-- 3. loyalty_points: never null.
update public.profiles set loyalty_points = 0 where loyalty_points is null;
alter table public.profiles
  alter column loyalty_points set default 0,
  alter column loyalty_points set not null;
