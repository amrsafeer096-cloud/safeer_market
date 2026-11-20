-- Order lifecycle: customer → warehouse → driver.
--   pending → preparing → ready_for_delivery → out_for_delivery → delivered
-- Adds the warehouse role and hands drivers only ready_for_delivery orders.
-- Safe to re-run.

-- 1. Warehouse role ---------------------------------------------------------

alter table public.profiles drop constraint if exists profiles_role_check;
alter table public.profiles
  add constraint profiles_role_check
  check (role in ('customer', 'driver', 'warehouse', 'admin'));

-- Assign from the SQL editor:
--   update public.profiles set role = 'warehouse' where id = '<user uuid>';
create or replace function public.is_warehouse()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1 from public.profiles
    where id = auth.uid() and role = 'warehouse'
  );
$$;

-- "processing" was the admin dashboard's name for preparing.
update public.orders set status = 'preparing' where status = 'processing';

-- 2. Warehouse access -------------------------------------------------------

drop policy if exists "orders_warehouse_select" on public.orders;
create policy "orders_warehouse_select" on public.orders
  for select to authenticated
  using (public.is_warehouse() and status in ('pending', 'preparing'));

-- Only the two warehouse steps; anything else matches no rows.
drop policy if exists "orders_warehouse_advance" on public.orders;
create policy "orders_warehouse_advance" on public.orders
  for update to authenticated
  using (public.is_warehouse() and status in ('pending', 'preparing'))
  with check (status in ('preparing', 'ready_for_delivery'));

-- The items to pick for those orders.
drop policy if exists "order_items_warehouse_select" on public.order_items;
create policy "order_items_warehouse_select" on public.order_items
  for select to authenticated
  using (
    public.is_warehouse()
    and exists (
      select 1 from public.orders o
      where o.id = order_items.order_id
        and o.status in ('pending', 'preparing')
    )
  );

drop policy if exists "profiles_warehouse_select_customers" on public.profiles;
create policy "profiles_warehouse_select_customers" on public.profiles
  for select to authenticated
  using (
    public.is_warehouse()
    and exists (
      select 1 from public.orders o
      where o.user_id = profiles.id
        and o.status in ('pending', 'preparing')
    )
  );

-- Drivers and warehouse staff may only move the status (drivers also the
-- assignment) of other people's orders, and only one step forward.
create or replace function public.guard_driver_order_update()
returns trigger
language plpgsql
as $$
begin
  if auth.role() <> 'authenticated' or old.user_id = auth.uid() then
    return new;
  end if;

  if public.is_driver()
     and (to_jsonb(new) - 'status' - 'driver_id' - 'updated_at')
         is distinct from (to_jsonb(old) - 'status' - 'driver_id' - 'updated_at')
  then
    raise exception 'Drivers can only change the order status';
  end if;

  if public.is_warehouse() then
    if (to_jsonb(new) - 'status' - 'updated_at')
       is distinct from (to_jsonb(old) - 'status' - 'updated_at')
    then
      raise exception 'Warehouse staff can only change the order status';
    end if;
    if not (
      (old.status = 'pending' and new.status = 'preparing')
      or (old.status = 'preparing' and new.status = 'ready_for_delivery')
    ) then
      raise exception 'Invalid warehouse status change: % -> %',
        old.status, new.status;
    end if;
  end if;

  return new;
end;
$$;

-- 3. Drivers now start at ready_for_delivery --------------------------------

drop policy if exists "orders_driver_select" on public.orders;
create policy "orders_driver_select" on public.orders
  for select to authenticated
  using (
    public.is_driver()
    and (
      (status = 'ready_for_delivery' and driver_id is null)
      or driver_id = auth.uid()
    )
  );

drop policy if exists "orders_driver_accept" on public.orders;
create policy "orders_driver_accept" on public.orders
  for update to authenticated
  using (
    public.is_driver()
    and status = 'ready_for_delivery'
    and driver_id is null
  )
  with check (driver_id = auth.uid() and status = 'out_for_delivery');

drop policy if exists "profiles_driver_select_customers" on public.profiles;
create policy "profiles_driver_select_customers" on public.profiles
  for select to authenticated
  using (
    public.is_driver()
    and exists (
      select 1 from public.orders o
      where o.user_id = profiles.id
        and (
          (o.status = 'ready_for_delivery' and o.driver_id is null)
          or o.driver_id = auth.uid()
        )
    )
  );
