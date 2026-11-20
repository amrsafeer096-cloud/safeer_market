-- =============================================================================
-- Safeer Market: ONE combined, re-runnable script for the missing schema/RPC
-- errors
--   1. Could not find the 'prep_completed_at' column of 'orders'
--   2. Could not find the function public.admin_search_customers(p_limit, p_query)
--   3. Could not find the function public.admin_list_dashboard_users
-- Paste all of it into the Supabase SQL Editor and run it. Safe to run twice.
--
-- It contains, in order (sources in supabase/migrations/):
--   A. orders columns             20261119100000_orders_prep_completed_at.sql
--   B. pos_customers details      20261119000000_phone_order_customer_details.sql (section 1)
--   C. role helpers + role check  is_admin / is_order_taker / profiles_role_check
--   D. permissions, dashboard users, customers, staff
--                                 20261119200000_reports_and_system_management.sql
-- The delivery-zone / Fujitsu pieces are a separate migration:
--   20261119210000_delivery_zones_fujitsu.sql
-- =============================================================================


-- A. Orders -------------------------------------------------------------------

alter table public.orders
  add column if not exists prep_completed_at timestamptz,
  add column if not exists preparer_name text,
  add column if not exists driver_name text,
  add column if not exists taker_name text,
  add column if not exists order_source text not null default 'app';

comment on column public.orders.prep_completed_at is
  'When preparation was marked complete (stops the 20-minute prep countdown).';

alter table public.orders
  add column if not exists pos_customer_id bigint
    references public.pos_customers (id) on delete set null;


-- B. Customer details used by admin_search_customers ---------------------------

alter table public.pos_customers
  add column if not exists phone2 text,
  add column if not exists customer_type text not null default 'regular',
  add column if not exists governorate text,
  add column if not exists city text,
  add column if not exists building text,
  add column if not exists floor text,
  add column if not exists apartment text,
  add column if not exists latitude double precision,
  add column if not exists longitude double precision;

alter table public.pos_customers
  drop constraint if exists pos_customers_customer_type_check;
alter table public.pos_customers
  add constraint pos_customers_customer_type_check
    check (customer_type in ('regular', 'vip'));


-- C. Role helpers --------------------------------------------------------------

-- Dashboard staff roles: the original check only allowed customer / driver /
-- warehouse / admin, but «كاشير» (cashier) is used by the dashboard too.
-- NOT VALID: new and changed rows are checked, existing rows are left alone.
alter table public.profiles drop constraint if exists profiles_role_check;
alter table public.profiles
  add constraint profiles_role_check
  check (role in ('customer', 'driver', 'warehouse', 'cashier', 'admin'))
  not valid;

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

create or replace function public.is_order_taker()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1 from public.profiles
    where id = auth.uid() and role in ('admin', 'warehouse', 'cashier')
  );
$$;


-- D1. Permissions ---------------------------------------------------------------

create table if not exists public.admin_permissions (
  user_id uuid primary key references public.profiles (id) on delete cascade,
  permissions text[] not null default '{}',
  updated_at timestamptz not null default now(),
  updated_by uuid
);

alter table public.admin_permissions enable row level security;

drop policy if exists "admin_permissions_select" on public.admin_permissions;
create policy "admin_permissions_select" on public.admin_permissions
  for select to authenticated
  using (user_id = (select auth.uid()) or public.is_admin());

drop policy if exists "admin_permissions_admin_write" on public.admin_permissions;
create policy "admin_permissions_admin_write" on public.admin_permissions
  for all to authenticated
  using (public.is_admin())
  with check (public.is_admin());

alter table public.profiles
  add column if not exists staff_disabled boolean not null default false,
  add column if not exists disabled_role text;

create or replace function public.all_admin_permissions()
returns text[]
language sql
immutable
as $$
  select array[
    'view_reports',
    'manage_customers',
    'delete_customers',
    'manage_preparers',
    'manage_drivers',
    'manage_users',
    'manage_zones',
    'approve_subscriptions'
  ]::text[];
$$;

create or replace function public.has_permission(p_permission text)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select public.is_admin()
    or exists (
      select 1
      from public.profiles p
      join public.admin_permissions a on a.user_id = p.id
      where p.id = auth.uid()
        and p.role in ('warehouse', 'cashier')
        and not p.staff_disabled
        and p_permission = any (a.permissions)
    );
$$;

create or replace function public.my_permissions()
returns text[]
language sql
stable
security definer
set search_path = ''
as $$
  select case
    when public.is_admin() then public.all_admin_permissions()
    else coalesce((
      select a.permissions
      from public.profiles p
      join public.admin_permissions a on a.user_id = p.id
      where p.id = auth.uid()
        and p.role in ('warehouse', 'cashier')
        and not p.staff_disabled
    ), '{}'::text[])
  end;
$$;

create or replace function public.admin_get_permissions(p_user_id uuid)
returns text[]
language plpgsql
stable
security definer
set search_path = ''
as $$
begin
  if not public.is_admin() then
    raise exception 'admin_required' using errcode = '42501';
  end if;
  return coalesce(
    (select a.permissions from public.admin_permissions a
     where a.user_id = p_user_id),
    '{}'::text[]);
end;
$$;

create or replace function public.admin_set_permissions(
  p_user_id uuid,
  p_permissions text[]
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  cleaned text[];
begin
  if not public.is_admin() then
    raise exception 'admin_required' using errcode = '42501';
  end if;
  if not exists (select 1 from public.profiles where id = p_user_id) then
    raise exception 'user_not_found' using errcode = '22023';
  end if;

  select coalesce(array_agg(distinct x order by x), '{}'::text[])
    into cleaned
  from unnest(coalesce(p_permissions, '{}'::text[])) as x
  where x = any (public.all_admin_permissions());

  insert into public.admin_permissions (user_id, permissions, updated_by)
  values (p_user_id, cleaned, auth.uid())
  on conflict (user_id) do update
  set permissions = excluded.permissions,
      updated_at = now(),
      updated_by = excluded.updated_by;
end;
$$;


-- D2. Roles: admins may change them (admin_set_user_role raises a
--     transaction-local flag after checking the caller) ------------------------

create or replace function public.protect_profile_role()
returns trigger
language plpgsql
as $$
begin
  if auth.role() in ('anon', 'authenticated') then
    if tg_op = 'INSERT' then
      new.role := 'customer';
    elsif new.role is distinct from old.role
      and coalesce(current_setting('app.role_change_allowed', true), '') <> 'on'
      and not public.is_admin() then
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

-- Subscription plans may also be activated by staff allowed to approve them.
create or replace function public.protect_subscription_columns()
returns trigger
language plpgsql
as $$
begin
  if TG_OP = 'UPDATE'
     and auth.role() in ('anon', 'authenticated')
     and not public.has_permission('approve_subscriptions') then
    new.subscription_plan := old.subscription_plan;
    new.subscription_expiry := old.subscription_expiry;
  end if;
  return new;
end;
$$;

create or replace function public.list_pending_subscriptions()
returns table (
  id uuid,
  full_name text,
  phone text,
  pending_subscription_tier text,
  subscription_receipt_url text,
  subscription_status text
)
language plpgsql
security definer
set search_path = public
as $$
begin
  if not public.has_permission('approve_subscriptions') then
    raise exception 'forbidden';
  end if;

  return query
  select
    p.id,
    p.full_name,
    p.phone,
    p.pending_subscription_tier,
    p.subscription_receipt_url,
    p.subscription_status
  from public.profiles p
  where p.subscription_status = 'pending_verification'
  order by p.full_name nulls last, p.phone nulls last;
end;
$$;

create or replace function public.approve_subscription_request(p_user_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  tier text;
  plan text;
begin
  if not public.has_permission('approve_subscriptions') then
    raise exception 'forbidden';
  end if;
  if p_user_id is null then
    raise exception 'user_required';
  end if;

  select p.pending_subscription_tier
  into tier
  from public.profiles p
  where p.id = p_user_id
    and p.subscription_status = 'pending_verification'
  for update;

  if tier is null then
    raise exception 'no_pending_subscription';
  end if;

  plan := case tier when 'vip' then 'pro' else 'prime' end;

  update public.profiles p
  set subscription_plan = plan,
      subscription_expiry =
        case
          when p.subscription_plan = plan and p.subscription_expiry > now()
            then p.subscription_expiry
          else now()
        end + interval '30 days',
      subscription_status = 'active',
      pending_subscription_tier = null
  where p.id = p_user_id;
end;
$$;


-- D3. Dashboard users -----------------------------------------------------------

create or replace function public.admin_list_dashboard_users()
returns table (
  id uuid,
  full_name text,
  phone text,
  email text,
  role text,
  is_disabled boolean
)
language plpgsql
stable
security definer
set search_path = ''
as $$
begin
  if not public.has_permission('manage_users') then
    raise exception 'forbidden' using errcode = '42501';
  end if;

  return query
  select
    p.id,
    p.full_name::text,
    p.phone::text,
    u.email::text,
    case when p.staff_disabled
         then coalesce(p.disabled_role, 'cashier')
         else p.role::text end,
    p.staff_disabled
  from public.profiles p
  left join auth.users u on u.id = p.id
  where p.role in ('admin', 'warehouse', 'cashier') or p.staff_disabled
  order by p.staff_disabled, p.full_name nulls last;
end;
$$;

create or replace function public.admin_find_accounts(p_query text)
returns table (
  id uuid,
  full_name text,
  phone text,
  email text
)
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  q text := btrim(coalesce(p_query, ''));
  digits text := regexp_replace(btrim(coalesce(p_query, '')), '\D', '', 'g');
begin
  if not public.has_permission('manage_users') then
    raise exception 'forbidden' using errcode = '42501';
  end if;
  if length(q) < 2 then
    return;
  end if;

  return query
  select p.id, p.full_name::text, p.phone::text, u.email::text
  from public.profiles p
  left join auth.users u on u.id = p.id
  where p.role = 'customer'
    and not p.staff_disabled
    and (
      p.full_name ilike '%' || q || '%'
      or u.email ilike '%' || q || '%'
      or (length(digits) >= 3
          and regexp_replace(coalesce(p.phone, ''), '\D', '', 'g')
              like '%' || digits || '%')
    )
  order by p.full_name nulls last
  limit 15;
end;
$$;

create or replace function public.admin_set_user_role(
  p_user_id uuid,
  p_role text,
  p_full_name text default null,
  p_disabled boolean default false
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  target public.profiles;
  new_role text := lower(btrim(coalesce(p_role, '')));
  new_name text := nullif(btrim(coalesce(p_full_name, '')), '');
begin
  if not public.has_permission('manage_users') then
    raise exception 'forbidden' using errcode = '42501';
  end if;
  if p_user_id = auth.uid() then
    raise exception 'cannot_change_self' using errcode = '42501';
  end if;
  if new_role not in ('admin', 'warehouse', 'cashier') then
    raise exception 'invalid_role' using errcode = '22023';
  end if;

  select * into target from public.profiles where id = p_user_id for update;
  if not found then
    raise exception 'user_not_found' using errcode = '22023';
  end if;

  -- Only an administrator touches administrators.
  if (new_role = 'admin' or target.role = 'admin'
      or target.disabled_role = 'admin')
     and not public.is_admin() then
    raise exception 'admin_required' using errcode = '42501';
  end if;

  perform set_config('app.role_change_allowed', 'on', true);

  if p_disabled then
    update public.profiles
    set disabled_role = new_role,
        role = 'customer',
        staff_disabled = true,
        full_name = coalesce(new_name, full_name)
    where id = p_user_id;
  else
    update public.profiles
    set role = new_role,
        staff_disabled = false,
        disabled_role = null,
        full_name = coalesce(new_name, full_name)
    where id = p_user_id;
  end if;

  perform set_config('app.role_change_allowed', 'off', true);
end;
$$;


-- D4. Customers -------------------------------------------------------------------

create or replace function public.admin_search_customers(
  p_query text default '',
  p_limit integer default 40
)
returns table (
  id bigint,
  full_name text,
  phone text,
  phone2 text,
  address text,
  zone text,
  customer_type text,
  governorate text,
  city text,
  building text,
  floor text,
  apartment text,
  latitude double precision,
  longitude double precision,
  orders_count bigint,
  total_spent numeric,
  last_order_at timestamptz
)
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  q text := btrim(coalesce(p_query, ''));
  digits text := regexp_replace(btrim(coalesce(p_query, '')), '\D', '', 'g');
  lim integer := least(greatest(coalesce(p_limit, 40), 1), 100);
begin
  if not public.is_order_taker() then
    raise exception 'forbidden' using errcode = '42501';
  end if;

  return query
  select
    c.id::bigint,
    c.full_name::text,
    c.phone::text,
    c.phone2::text,
    c.address::text,
    c.zone::text,
    c.customer_type::text,
    c.governorate::text,
    c.city::text,
    c.building::text,
    c.floor::text,
    c.apartment::text,
    c.latitude,
    c.longitude,
    s.cnt,
    s.spent,
    s.last_at
  from public.pos_customers c
  left join lateral (
    select count(*)::bigint as cnt,
           coalesce(sum(o.total_amount)
             filter (where o.status <> 'cancelled'), 0)::numeric as spent,
           max(o.created_at) as last_at
    from public.orders o
    where o.pos_customer_id = c.id
  ) s on true
  where q = ''
     or c.full_name ilike '%' || q || '%'
     or c.address ilike '%' || q || '%'
     or (length(digits) >= 3
         and (c.phone like '%' || digits || '%'
              or coalesce(c.phone2, '') like '%' || digits || '%'))
  order by case when q = '' then c.last_seen end desc nulls last,
           c.full_name
  limit lim;
end;
$$;

create or replace function public.admin_delete_customer(p_id bigint)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  if not public.has_permission('delete_customers') then
    raise exception 'forbidden' using errcode = '42501';
  end if;
  -- Phone orders point at the customer; orders must keep one.
  if exists (select 1 from public.orders o where o.pos_customer_id = p_id) then
    raise exception 'customer_has_orders' using errcode = '23503';
  end if;
  delete from public.pos_customers where id = p_id;
end;
$$;


-- D5. Preparers and drivers --------------------------------------------------------

do $$
begin
  if to_regclass('public.staff') is null then
    create table public.staff (
      id uuid primary key default gen_random_uuid(),
      name text not null,
      role text not null,
      phone text,
      created_at timestamptz not null default now()
    );
    alter table public.staff enable row level security;
    create policy "staff_select_authenticated" on public.staff
      for select to authenticated using (true);
  else
    alter table public.staff add column if not exists phone text;
    -- admin_add_staff inserts without an id.
    if exists (
      select 1 from information_schema.columns
      where table_schema = 'public' and table_name = 'staff'
        and column_name = 'id' and data_type = 'uuid'
        and column_default is null
    ) then
      alter table public.staff alter column id set default gen_random_uuid();
    end if;
  end if;
end;
$$;

create or replace function public.admin_add_staff(
  p_name text,
  p_role text,
  p_phone text default null
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  staff_role text := lower(btrim(coalesce(p_role, '')));
begin
  if staff_role not in ('preparer', 'driver') then
    raise exception 'invalid_role' using errcode = '22023';
  end if;
  if not public.has_permission(
       case staff_role when 'preparer' then 'manage_preparers'
                       else 'manage_drivers' end) then
    raise exception 'forbidden' using errcode = '42501';
  end if;
  if btrim(coalesce(p_name, '')) = '' then
    raise exception 'name_required' using errcode = '22023';
  end if;

  insert into public.staff (name, role, phone)
  values (btrim(p_name), staff_role, nullif(btrim(coalesce(p_phone, '')), ''));
end;
$$;

create or replace function public.admin_delete_staff(p_id text)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  staff_role text;
begin
  select s.role into staff_role from public.staff s where s.id::text = p_id;
  if not found then
    raise exception 'staff_not_found' using errcode = '22023';
  end if;
  if not public.has_permission(
       case staff_role when 'preparer' then 'manage_preparers'
                       when 'driver' then 'manage_drivers'
                       else 'manage_users' end) then
    raise exception 'forbidden' using errcode = '42501';
  end if;
  delete from public.staff s where s.id::text = p_id;
end;
$$;


-- D6. Legacy zones table (only when it exists) ----------------------------------

do $$
begin
  if to_regclass('public.areas') is not null then
    drop policy if exists "areas_manage" on public.areas;
    create policy "areas_manage" on public.areas
      for all to authenticated
      using (public.has_permission('manage_zones'))
      with check (public.has_permission('manage_zones'));
  end if;
end;
$$;


-- E. Grants ------------------------------------------------------------------------

revoke all on function public.has_permission(text) from public, anon;
revoke all on function public.my_permissions() from public, anon;
revoke all on function public.admin_get_permissions(uuid) from public, anon;
revoke all on function public.admin_set_permissions(uuid, text[])
  from public, anon;
revoke all on function public.admin_list_dashboard_users() from public, anon;
revoke all on function public.admin_find_accounts(text) from public, anon;
revoke all on function public.admin_set_user_role(uuid, text, text, boolean)
  from public, anon;
revoke all on function public.admin_search_customers(text, integer)
  from public, anon;
revoke all on function public.admin_delete_customer(bigint) from public, anon;
revoke all on function public.admin_add_staff(text, text, text)
  from public, anon;
revoke all on function public.admin_delete_staff(text) from public, anon;
revoke all on function public.list_pending_subscriptions() from public, anon;
revoke all on function public.approve_subscription_request(uuid)
  from public, anon;

grant execute on function public.has_permission(text) to authenticated;
grant execute on function public.my_permissions() to authenticated;
grant execute on function public.admin_get_permissions(uuid) to authenticated;
grant execute on function public.admin_set_permissions(uuid, text[])
  to authenticated;
grant execute on function public.admin_list_dashboard_users() to authenticated;
grant execute on function public.admin_find_accounts(text) to authenticated;
grant execute on function public.admin_set_user_role(uuid, text, text, boolean)
  to authenticated;
grant execute on function public.admin_search_customers(text, integer)
  to authenticated;
grant execute on function public.admin_delete_customer(bigint)
  to authenticated;
grant execute on function public.admin_add_staff(text, text, text)
  to authenticated;
grant execute on function public.admin_delete_staff(text) to authenticated;
grant execute on function public.list_pending_subscriptions()
  to authenticated;
grant execute on function public.approve_subscription_request(uuid)
  to authenticated;

notify pgrst, 'reload schema';
