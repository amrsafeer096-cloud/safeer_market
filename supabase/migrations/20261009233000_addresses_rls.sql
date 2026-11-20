-- Customers manage only their own saved addresses. The app inserts with
-- user_id = the signed-in user's id, reads with .eq('user_id', ...), updates
-- the map pin, and deletes.

alter table public.addresses enable row level security;

-- Fills user_id if a client ever omits it.
alter table public.addresses alter column user_id set default auth.uid();

drop policy if exists "addresses_select_own" on public.addresses;
create policy "addresses_select_own" on public.addresses
  for select to authenticated
  using ((select auth.uid()) = user_id);

drop policy if exists "addresses_insert_own" on public.addresses;
create policy "addresses_insert_own" on public.addresses
  for insert to authenticated
  with check ((select auth.uid()) = user_id);

drop policy if exists "addresses_update_own" on public.addresses;
create policy "addresses_update_own" on public.addresses
  for update to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);

drop policy if exists "addresses_delete_own" on public.addresses;
create policy "addresses_delete_own" on public.addresses
  for delete to authenticated
  using ((select auth.uid()) = user_id);
