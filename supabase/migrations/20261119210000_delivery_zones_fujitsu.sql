-- Delivery zones from Fujitsu (`delivery_zones`) drive the «المنطقة»
-- dropdown of «إضافة عنوان» and «إدارة النظام ← المناطق».
--
-- * delivery_zones: fujitsu_zone_id, governorate, city, name, delivery_fee
--   (+ is_active). Created here when it doesn't exist yet; an existing table
--   is kept and only gets what is missing.
-- * pos_customers: fujitsu_zone_id (the zone picked for the customer) and
--   synced_to_fujitsu. Customers created from the dashboard are stored with
--   synced_to_fujitsu = false so the Fujitsu sync picks them up. Existing
--   rows (imported from the POS) are marked as synced.
-- * search_phone_order_customers / create_phone_order_customer return the
--   customer's fujitsu_zone_id, so choosing the customer applies the zone's
--   delivery fee to the order.
--
-- Run after 20261119000000_phone_order_customer_details.sql and
-- 20261119200000_reports_and_system_management.sql.

-- 1. Zones.
create table if not exists public.delivery_zones (
  fujitsu_zone_id text primary key,
  governorate text not null default 'القاهرة',
  city text not null,
  name text not null,
  delivery_fee numeric(10, 2) check (delivery_fee is null or delivery_fee >= 0)
);

alter table public.delivery_zones
  add column if not exists is_active boolean not null default true,
  add column if not exists created_at timestamptz not null default now();

alter table public.delivery_zones enable row level security;

drop policy if exists "delivery_zones_select_authenticated"
  on public.delivery_zones;
create policy "delivery_zones_select_authenticated" on public.delivery_zones
  for select to authenticated using (true);

-- Add / edit / delete: administrators and users granted `manage_zones`.
drop policy if exists "delivery_zones_manage" on public.delivery_zones;
create policy "delivery_zones_manage" on public.delivery_zones
  for all to authenticated
  using (public.has_permission('manage_zones'))
  with check (public.has_permission('manage_zones'));

grant select, insert, update, delete on public.delivery_zones to authenticated;

-- 2. Customer columns (Supabase side; text so any zone-id type fits).
alter table public.pos_customers
  add column if not exists fujitsu_zone_id text,
  add column if not exists synced_to_fujitsu boolean not null default true;

-- 3. Search returns the zone id too (the return type changes, so drop first).
drop function if exists public.search_phone_order_customers(text, integer);

create or replace function public.search_phone_order_customers(
  p_query text,
  p_limit integer default 20
)
returns table (
  source text,
  user_id uuid,
  pos_customer_id bigint,
  full_name text,
  phone text,
  address text,
  zone text,
  fujitsu_zone_id text
)
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  q text := btrim(coalesce(p_query, ''));
  digits text := public.normalize_egyptian_phone(p_query);
  by_phone boolean;
  name_like text;
  lim integer := least(greatest(coalesce(p_limit, 20), 1), 50);
begin
  if not public.is_order_taker() then
    raise exception 'not_allowed' using errcode = '42501';
  end if;
  if length(q) < 2 then
    return;
  end if;
  by_phone := length(digits) >= 3 and q !~ '[^\d\s+()-]';
  name_like := '%' || replace(replace(replace(q, '\', '\\'), '%', '\%'), '_', '\_') || '%';

  return query
  (
    select 'app'::text, p.id, null::bigint, p.full_name, p.phone,
           a.line, a.region, null::text
    from public.profiles p
    left join lateral (
      select concat_ws('، ', nullif(ad.region, ''), nullif(ad.street, ''),
                       nullif(ad.building, '')) as line,
             ad.region
      from public.addresses ad
      where ad.user_id = p.id
      order by ad.created_at desc
      limit 1
    ) a on true
    where case
      when by_phone then public.normalize_egyptian_phone(p.phone) like '%' || digits || '%'
      else p.full_name ilike name_like
    end
    limit lim
  )
  union all
  (
    select 'pos'::text, null::uuid, c.id, c.full_name, c.phone,
           c.address, c.zone, c.fujitsu_zone_id
    from public.pos_customers c
    where case
      when by_phone then c.phone like digits || '%'
      else c.full_name ilike name_like
    end
    order by c.last_seen desc nulls last, c.id desc
    limit lim
  );
end;
$$;

revoke execute on function public.search_phone_order_customers(text, integer)
  from public, anon;
grant execute on function public.search_phone_order_customers(text, integer)
  to authenticated;

-- 4. «+ عميل جديد»: stores the zone's Fujitsu id, and marks a NEW customer
--    synced_to_fujitsu = false.
drop function if exists public.create_phone_order_customer(
  text, text, text, text, text, text, text, text, text, text, text,
  double precision, double precision);

create or replace function public.create_phone_order_customer(
  p_full_name text,
  p_phone text,
  p_address text default null,
  p_zone text default null,
  p_phone2 text default null,
  p_customer_type text default 'regular',
  p_governorate text default null,
  p_city text default null,
  p_building text default null,
  p_floor text default null,
  p_apartment text default null,
  p_latitude double precision default null,
  p_longitude double precision default null,
  p_fujitsu_zone_id text default null
)
returns table (
  source text,
  user_id uuid,
  pos_customer_id bigint,
  full_name text,
  phone text,
  address text,
  zone text,
  fujitsu_zone_id text
)
language plpgsql
security definer
set search_path = ''
as $$
declare
  digits text := public.normalize_egyptian_phone(p_phone);
  digits2 text := case
    when btrim(coalesce(p_phone2, '')) = '' then null
    else public.normalize_egyptian_phone(p_phone2)
  end;
  ctype text := lower(btrim(coalesce(p_customer_type, 'regular')));
  zone_id text := nullif(btrim(coalesce(p_fujitsu_zone_id, '')), '');
  customer public.pos_customers;
begin
  if not public.is_order_taker() then
    raise exception 'not_allowed' using errcode = '42501';
  end if;
  if btrim(coalesce(p_full_name, '')) = '' then
    raise exception 'name_required' using errcode = '22023';
  end if;
  if digits !~ '^01[0125][0-9]{8}$'
     or (digits2 is not null and digits2 !~ '^01[0125][0-9]{8}$') then
    raise exception 'invalid_phone' using errcode = '22023';
  end if;
  if ctype not in ('regular', 'vip') then
    raise exception 'invalid_customer_type' using errcode = '22023';
  end if;
  if (p_latitude is null) <> (p_longitude is null)
     or p_latitude not between -90 and 90
     or p_longitude not between -180 and 180 then
    raise exception 'invalid_location' using errcode = '22023';
  end if;
  if zone_id is not null and not exists (
    select 1 from public.delivery_zones z
    where z.fujitsu_zone_id::text = zone_id
  ) then
    raise exception 'invalid_zone' using errcode = '22023';
  end if;

  select * into customer
  from public.pos_customers c
  where c.phone = digits
  order by c.last_seen desc nulls last, c.id desc
  limit 1;

  if not found then
    insert into public.pos_customers (
      id, full_name, phone, address, zone, source_system, last_seen,
      phone2, customer_type, governorate, city, building, floor, apartment,
      latitude, longitude, fujitsu_zone_id, synced_to_fujitsu
    )
    values (
      nextval('public.pos_customers_app_id_seq'),
      btrim(p_full_name),
      digits,
      nullif(btrim(coalesce(p_address, '')), ''),
      nullif(btrim(coalesce(p_zone, '')), ''),
      'safeer_app',
      now()::timestamp,
      digits2,
      ctype,
      nullif(btrim(coalesce(p_governorate, '')), ''),
      nullif(btrim(coalesce(p_city, '')), ''),
      nullif(btrim(coalesce(p_building, '')), ''),
      nullif(btrim(coalesce(p_floor, '')), ''),
      nullif(btrim(coalesce(p_apartment, '')), ''),
      p_latitude,
      p_longitude,
      zone_id,
      false
    )
    returning * into customer;
  else
    -- The caller already exists: fill in what we now know (never replacing
    -- the POS's own name, phone, address or zone).
    update public.pos_customers c
    set phone2 = coalesce(digits2, c.phone2),
        customer_type = case when ctype = 'vip' then 'vip'
                             else c.customer_type end,
        governorate = coalesce(
          nullif(btrim(coalesce(p_governorate, '')), ''), c.governorate),
        city = coalesce(nullif(btrim(coalesce(p_city, '')), ''), c.city),
        building = coalesce(
          nullif(btrim(coalesce(p_building, '')), ''), c.building),
        floor = coalesce(nullif(btrim(coalesce(p_floor, '')), ''), c.floor),
        apartment = coalesce(
          nullif(btrim(coalesce(p_apartment, '')), ''), c.apartment),
        latitude = coalesce(p_latitude, c.latitude),
        longitude = coalesce(p_longitude, c.longitude),
        address = coalesce(
          c.address, nullif(btrim(coalesce(p_address, '')), '')),
        zone = coalesce(c.zone, nullif(btrim(coalesce(p_zone, '')), '')),
        -- The zone id follows the zone: only set while the customer has none.
        fujitsu_zone_id = case
          when c.zone is null then coalesce(c.fujitsu_zone_id, zone_id)
          else c.fujitsu_zone_id
        end
    where c.id = customer.id
    returning * into customer;
  end if;

  return query select 'pos'::text, null::uuid, customer.id,
    customer.full_name, customer.phone, customer.address, customer.zone,
    customer.fujitsu_zone_id;
end;
$$;

revoke execute on function public.create_phone_order_customer(
  text, text, text, text, text, text, text, text, text, text, text,
  double precision, double precision, text) from public, anon;
grant execute on function public.create_phone_order_customer(
  text, text, text, text, text, text, text, text, text, text, text,
  double precision, double precision, text) to authenticated;

notify pgrst, 'reload schema';
