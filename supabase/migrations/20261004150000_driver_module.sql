-- Delivery driver module: user roles, order assignment, and the row-level
-- security drivers need. Safe to re-run.

-- 1. Roles ------------------------------------------------------------------

alter table public.profiles
  add column if not exists role text not null default 'customer';

alter table public.profiles drop constraint if exists profiles_role_check;
alter table public.profiles
  add constraint profiles_role_check
  check (role in ('customer', 'driver', 'admin'));

-- Users may edit their own profile row (name, phone, fcm_token, ...), so stop
-- them from promoting themselves. The SQL editor and service role are exempt,
-- which is where roles get assigned:
--   update public.profiles set role = 'driver' where id = '<user uuid>';
create or replace function public.protect_profile_role()
returns trigger
language plpgsql
as $$
begin
  if auth.role() in ('anon', 'authenticated') then
    if tg_op = 'INSERT' then
      new.role := 'customer';
    elsif new.role is distinct from old.role then
      raise exception 'Only an administrator can change a user role';
    end if;
  end if;
  return new;
end;
$$;

drop trigger if exists protect_profile_role on public.profiles;
create trigger protect_profile_role
  before insert or update on public.profiles
  for each row execute function public.protect_profile_role();

-- Security definer so policies can call it without recursing into profiles RLS.
create or replace function public.is_driver()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1 from public.profiles
    where id = auth.uid() and role = 'driver'
  );
$$;

-- 2. Orders -----------------------------------------------------------------

-- status already exists for the admin dashboard; this is a no-op there.
alter table public.orders
  add column if not exists status text not null default 'pending';

alter table public.orders
  add column if not exists driver_id uuid
    references public.profiles (id) on delete set null;

-- Delivery pin, so drivers see the distance from the store.
alter table public.orders
  add column if not exists delivery_latitude double precision,
  add column if not exists delivery_longitude double precision;

create index if not exists orders_status_idx on public.orders (status);
create index if not exists orders_driver_id_idx on public.orders (driver_id);

-- 3. Driver access ----------------------------------------------------------

-- Drivers see unassigned pending orders and the orders they accepted.
drop policy if exists "orders_driver_select" on public.orders;
create policy "orders_driver_select" on public.orders
  for select to authenticated
  using (
    public.is_driver()
    and (status = 'pending' or driver_id = auth.uid())
  );

-- Accepting: a pending, unassigned order becomes theirs and goes out for
-- delivery. Two drivers racing for the same order: the second update matches
-- no rows because the order is no longer pending.
drop policy if exists "orders_driver_accept" on public.orders;
create policy "orders_driver_accept" on public.orders
  for update to authenticated
  using (public.is_driver() and status = 'pending' and driver_id is null)
  with check (driver_id = auth.uid() and status = 'out_for_delivery');

-- Completing their own deliveries.
drop policy if exists "orders_driver_deliver" on public.orders;
create policy "orders_driver_deliver" on public.orders
  for update to authenticated
  using (
    public.is_driver()
    and driver_id = auth.uid()
    and status = 'out_for_delivery'
  )
  with check (
    driver_id = auth.uid()
    and status in ('out_for_delivery', 'delivered')
  );

-- The policies above allow whole-row updates; drivers may only touch the
-- status and assignment of other people's orders (not totals or addresses).
create or replace function public.guard_driver_order_update()
returns trigger
language plpgsql
as $$
begin
  if auth.role() = 'authenticated'
     and old.user_id is distinct from auth.uid()
     and public.is_driver()
     and (to_jsonb(new) - 'status' - 'driver_id' - 'updated_at')
         is distinct from (to_jsonb(old) - 'status' - 'driver_id' - 'updated_at')
  then
    raise exception 'Drivers can only change the order status';
  end if;
  return new;
end;
$$;

drop trigger if exists guard_driver_order_update on public.orders;
create trigger guard_driver_order_update
  before update on public.orders
  for each row execute function public.guard_driver_order_update();

-- Customer name and phone on the orders a driver can see.
drop policy if exists "profiles_driver_select_customers" on public.profiles;
create policy "profiles_driver_select_customers" on public.profiles
  for select to authenticated
  using (
    public.is_driver()
    and exists (
      select 1 from public.orders o
      where o.user_id = profiles.id
        and (o.status = 'pending' or o.driver_id = auth.uid())
    )
  );
