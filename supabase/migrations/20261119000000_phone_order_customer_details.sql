-- «+ عميل جديد» → «إضافة عنوان»: richer customers added from the admin
-- dashboard's «تلقي الطلبات».
--
-- * pos_customers gets phone 2, customer type (عادي / VIP), the structured
--   address (governorate, city, building, floor, apartment) and the GPS pin.
--   These are Supabase-only columns: the POS / Fujitsu sync never writes
--   them, and the pin is read by the driver app.
-- * `areas`: delivery zones (with fee) for the zone dropdown. Empty until
--   it is populated from the Fujitsu zones.
-- * create_phone_order_customer takes the new details (all optional).
-- * Phone orders copy the customer's saved pin onto orders.delivery_latitude
--   / delivery_longitude, so the driver's «ابدأ الملاحة» works for them.

-- 1. Customer details (Supabase only).
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

-- 2. Delivery zones, linked to a city and a delivery fee.
create table if not exists public.areas (
  id bigint generated always as identity primary key,
  governorate text not null default 'القاهرة',
  city text not null,
  name text not null,
  delivery_fee numeric(10, 2) check (delivery_fee is null or delivery_fee >= 0),
  -- Zone code from Fujitsu, when imported from there.
  external_code text,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  unique (city, name)
);

alter table public.areas enable row level security;

drop policy if exists "areas_select_authenticated" on public.areas;
create policy "areas_select_authenticated" on public.areas
  for select to authenticated using (true);

-- 3. create_phone_order_customer with the new details. The old 4-argument
--    version is dropped so PostgREST never sees two overloads to pick from.
drop function if exists public.create_phone_order_customer(
  text, text, text, text);

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
  p_longitude double precision default null
)
returns table (
  source text,
  user_id uuid,
  pos_customer_id bigint,
  full_name text,
  phone text,
  address text,
  zone text
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

  select * into customer
  from public.pos_customers c
  where c.phone = digits
  order by c.last_seen desc nulls last, c.id desc
  limit 1;

  if not found then
    insert into public.pos_customers (
      id, full_name, phone, address, zone, source_system, last_seen,
      phone2, customer_type, governorate, city, building, floor, apartment,
      latitude, longitude
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
      p_longitude
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
        zone = coalesce(c.zone, nullif(btrim(coalesce(p_zone, '')), ''))
    where c.id = customer.id
    returning * into customer;
  end if;

  return query select 'pos'::text, null::uuid, customer.id,
    customer.full_name, customer.phone, customer.address, customer.zone;
end;
$$;

revoke execute on function public.create_phone_order_customer(
  text, text, text, text, text, text, text, text, text, text, text,
  double precision, double precision) from public, anon;
grant execute on function public.create_phone_order_customer(
  text, text, text, text, text, text, text, text, text, text, text,
  double precision, double precision) to authenticated;

-- 4. A phone order for a customer with a saved pin carries it to the driver.
create or replace function public.orders_fill_delivery_pin()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if new.pos_customer_id is not null
     and new.delivery_latitude is null
     and new.delivery_longitude is null then
    select c.latitude, c.longitude
      into new.delivery_latitude, new.delivery_longitude
    from public.pos_customers c
    where c.id = new.pos_customer_id
      and c.latitude is not null
      and c.longitude is not null;
  end if;
  return new;
end;
$$;

drop trigger if exists orders_fill_delivery_pin on public.orders;
create trigger orders_fill_delivery_pin
  before insert on public.orders
  for each row execute function public.orders_fill_delivery_pin();

notify pgrst, 'reload schema';
