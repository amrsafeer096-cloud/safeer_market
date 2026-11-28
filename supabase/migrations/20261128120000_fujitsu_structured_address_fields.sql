-- Fujitsu / TrustyDelivery structured address parity:
-- * street + notes on customer_addresses (+ street/landmark on pos_customers)
-- * drop ALL create_phone_order_customer / upsert_customer_address overloads
--   so PostgREST never hits PGRST203
-- * RPCs persist building/street/landmark/floor/apartment/zone/city/governorate/
--   branch/notes + composed full address

alter table public.customer_addresses
  add column if not exists street text;

alter table public.customer_addresses
  add column if not exists notes text;

alter table public.pos_customers
  add column if not exists street text;

alter table public.pos_customers
  add column if not exists landmark text;

-- ---------------------------------------------------------------------------
-- Drop every overload (PGRST203 guard)
-- ---------------------------------------------------------------------------
do $$
declare
  r record;
begin
  for r in
    select p.oid::regprocedure as sig
    from pg_proc p
    join pg_namespace n on n.oid = p.pronamespace
    where n.nspname = 'public'
      and p.proname in (
        'create_phone_order_customer',
        'upsert_customer_address'
      )
  loop
    execute 'drop function if exists ' || r.sig || ' cascade';
  end loop;
end;
$$;

-- ---------------------------------------------------------------------------
-- compose helper (Fujitsu formula)
-- ---------------------------------------------------------------------------
create or replace function public.compose_fujitsu_address(
  p_building text default null,
  p_street text default null,
  p_landmark text default null,
  p_floor text default null,
  p_apartment text default null,
  p_zone text default null,
  p_city text default null,
  p_governorate text default null
)
returns text
language plpgsql
immutable
as $$
declare
  street_part text;
  landmark_part text;
  parts text[] := array[]::text[];
begin
  if nullif(btrim(coalesce(p_building, '')), '') is not null then
    parts := parts || btrim(p_building);
  end if;

  if nullif(btrim(coalesce(p_street, '')), '') is not null then
    street_part := btrim(p_street);
    if street_part = 'ش'
       or street_part ~ '^ش[[:space:].]' then
      null;
    else
      street_part := 'ش ' || street_part;
    end if;
    parts := parts || street_part;
  end if;

  if nullif(btrim(coalesce(p_landmark, '')), '') is not null then
    landmark_part := btrim(p_landmark);
    if landmark_part ~ '^ع\.م' then
      null;
    else
      landmark_part := 'ع.م ' || landmark_part;
    end if;
    parts := parts || landmark_part;
  end if;

  if nullif(btrim(coalesce(p_floor, '')), '') is not null then
    parts := parts || ('الدور ' || btrim(p_floor));
  end if;
  if nullif(btrim(coalesce(p_apartment, '')), '') is not null then
    parts := parts || ('شقة ' || btrim(p_apartment));
  end if;
  if nullif(btrim(coalesce(p_zone, '')), '') is not null then
    parts := parts || btrim(p_zone);
  end if;
  if nullif(btrim(coalesce(p_city, '')), '') is not null then
    parts := parts || btrim(p_city);
  end if;
  if nullif(btrim(coalesce(p_governorate, '')), '') is not null then
    parts := parts || btrim(p_governorate);
  end if;

  if coalesce(array_length(parts, 1), 0) = 0 then
    return null;
  end if;
  return array_to_string(parts, ' - ');
end;
$$;

-- ---------------------------------------------------------------------------
-- upsert_customer_address
-- ---------------------------------------------------------------------------
create or replace function public.upsert_customer_address(
  p_pos_customer_id bigint default null,
  p_user_id uuid default null,
  p_address_id bigint default null,
  p_address text default null,
  p_zone text default null,
  p_branch text default null,
  p_governorate text default null,
  p_city text default null,
  p_building text default null,
  p_floor text default null,
  p_apartment text default null,
  p_latitude double precision default null,
  p_longitude double precision default null,
  p_fujitsu_zone_id text default null,
  p_is_primary boolean default false,
  p_street text default null,
  p_landmark text default null,
  p_notes text default null
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  line text;
  row public.customer_addresses;
begin
  if not public.is_order_taker() then
    raise exception 'not_allowed' using errcode = '42501';
  end if;
  if p_pos_customer_id is null and p_user_id is null then
    raise exception 'customer_required' using errcode = '22023';
  end if;

  line := nullif(btrim(coalesce(p_address, '')), '');
  if line is null then
    line := public.compose_fujitsu_address(
      p_building, p_street, p_landmark, p_floor, p_apartment,
      p_zone, p_city, p_governorate
    );
  end if;
  if line is null or line = '' then
    raise exception 'address_required' using errcode = '22023';
  end if;

  if p_is_primary then
    update public.customer_addresses
    set is_primary = false
    where (p_pos_customer_id is not null and pos_customer_id = p_pos_customer_id)
       or (p_user_id is not null and user_id = p_user_id);
  end if;

  if p_address_id is not null then
    update public.customer_addresses a
    set address = line,
        zone = nullif(btrim(coalesce(p_zone, '')), ''),
        branch = nullif(btrim(coalesce(p_branch, '')), ''),
        governorate = nullif(btrim(coalesce(p_governorate, '')), ''),
        city = nullif(btrim(coalesce(p_city, '')), ''),
        building = nullif(btrim(coalesce(p_building, '')), ''),
        street = nullif(btrim(coalesce(p_street, '')), ''),
        landmark = nullif(btrim(coalesce(p_landmark, '')), ''),
        floor = nullif(btrim(coalesce(p_floor, '')), ''),
        apartment = nullif(btrim(coalesce(p_apartment, '')), ''),
        notes = nullif(btrim(coalesce(p_notes, '')), ''),
        latitude = coalesce(p_latitude, a.latitude),
        longitude = coalesce(p_longitude, a.longitude),
        fujitsu_zone_id = coalesce(
          nullif(btrim(coalesce(p_fujitsu_zone_id, '')), ''), a.fujitsu_zone_id),
        is_primary = p_is_primary or a.is_primary,
        updated_at = now(),
        fujitsu_address_id = case
          when a.address is distinct from line then null
          else a.fujitsu_address_id
        end,
        synced_to_fujitsu = false
    where a.id = p_address_id
      and (
        (p_pos_customer_id is not null and a.pos_customer_id = p_pos_customer_id)
        or (p_user_id is not null and a.user_id = p_user_id)
      )
    returning * into row;

    if not found then
      raise exception 'address_not_found' using errcode = 'P0002';
    end if;
  else
    insert into public.customer_addresses (
      pos_customer_id, user_id, address, zone, branch, governorate, city,
      building, street, landmark, floor, apartment, notes,
      latitude, longitude, fujitsu_zone_id,
      is_primary, synced_to_fujitsu
    ) values (
      p_pos_customer_id,
      p_user_id,
      line,
      nullif(btrim(coalesce(p_zone, '')), ''),
      nullif(btrim(coalesce(p_branch, '')), ''),
      nullif(btrim(coalesce(p_governorate, '')), ''),
      nullif(btrim(coalesce(p_city, '')), ''),
      nullif(btrim(coalesce(p_building, '')), ''),
      nullif(btrim(coalesce(p_street, '')), ''),
      nullif(btrim(coalesce(p_landmark, '')), ''),
      nullif(btrim(coalesce(p_floor, '')), ''),
      nullif(btrim(coalesce(p_apartment, '')), ''),
      nullif(btrim(coalesce(p_notes, '')), ''),
      p_latitude,
      p_longitude,
      nullif(btrim(coalesce(p_fujitsu_zone_id, '')), ''),
      p_is_primary,
      false
    )
    returning * into row;
  end if;

  if p_pos_customer_id is not null and row.is_primary then
    update public.pos_customers
    set address = row.address,
        zone = row.zone,
        governorate = row.governorate,
        city = row.city,
        building = row.building,
        street = row.street,
        landmark = row.landmark,
        floor = row.floor,
        apartment = row.apartment,
        latitude = row.latitude,
        longitude = row.longitude,
        fujitsu_zone_id = coalesce(row.fujitsu_zone_id, fujitsu_zone_id),
        synced_to_fujitsu = false
    where id = p_pos_customer_id;
  end if;

  return row_to_json(row)::jsonb;
end;
$$;

revoke execute on function public.upsert_customer_address(
  bigint, uuid, bigint, text, text, text, text, text, text, text, text,
  double precision, double precision, text, boolean, text, text, text
) from public, anon;
grant execute on function public.upsert_customer_address(
  bigint, uuid, bigint, text, text, text, text, text, text, text, text,
  double precision, double precision, text, boolean, text, text, text
) to authenticated;

-- ---------------------------------------------------------------------------
-- create_phone_order_customer (single signature)
-- ---------------------------------------------------------------------------
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
  p_fujitsu_zone_id text default null,
  p_phone3 text default null,
  p_notes text default null,
  p_branch text default null,
  p_phone4 text default null,
  p_phone5 text default null,
  p_street text default null,
  p_landmark text default null
)
returns table (
  source text,
  user_id uuid,
  pos_customer_id bigint,
  full_name text,
  phone text,
  phone2 text,
  phone3 text,
  phone4 text,
  phone5 text,
  notes text,
  address text,
  zone text,
  fujitsu_zone_id text,
  fujitsu_customer_no bigint
)
language plpgsql
security definer
set search_path = ''
as $$
declare
  packed text[];
  digits text;
  ctype text := lower(btrim(coalesce(p_customer_type, 'regular')));
  zone_id text := nullif(btrim(coalesce(p_fujitsu_zone_id, '')), '');
  customer public.pos_customers;
  addr_line text := nullif(btrim(coalesce(p_address, '')), '');
begin
  if not public.is_order_taker() then
    raise exception 'not_allowed' using errcode = '42501';
  end if;
  if btrim(coalesce(p_full_name, '')) = '' then
    raise exception 'name_required' using errcode = '22023';
  end if;

  packed := public.pack_customer_phones(p_phone, p_phone2, p_phone3, p_phone4, p_phone5);
  if coalesce(array_length(packed, 1), 0) < 1 then
    raise exception 'invalid_phone' using errcode = '22023';
  end if;
  digits := public.normalize_customer_phone(packed[1]);
  if digits = '' then
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

  if addr_line is null then
    addr_line := public.compose_fujitsu_address(
      p_building, p_street, p_landmark, p_floor, p_apartment,
      p_zone, p_city, p_governorate
    );
  end if;

  select * into customer
  from public.pos_customers c
  where public.normalize_customer_phone(c.phone) = digits
     or public.normalize_customer_phone(coalesce(c.phone2, '')) = digits
     or public.normalize_customer_phone(coalesce(c.phone3, '')) = digits
     or public.normalize_customer_phone(coalesce(c.phone4, '')) = digits
     or public.normalize_customer_phone(coalesce(c.phone5, '')) = digits
  order by
    (c.fujitsu_customer_no is not null) desc,
    c.last_seen desc nulls last,
    c.id desc
  limit 1;

  if not found then
    insert into public.pos_customers (
      id, full_name, phone, address, zone, source_system, last_seen,
      phone2, phone3, phone4, phone5, notes, customer_type, governorate, city,
      building, street, landmark, floor, apartment, latitude, longitude,
      fujitsu_zone_id, synced_to_fujitsu
    )
    values (
      nextval('public.pos_customers_app_id_seq'),
      btrim(p_full_name),
      packed[1],
      addr_line,
      nullif(btrim(coalesce(p_zone, '')), ''),
      'safeer_app',
      now()::timestamp,
      packed[2], packed[3], packed[4], packed[5],
      nullif(btrim(coalesce(p_notes, '')), ''),
      ctype,
      nullif(btrim(coalesce(p_governorate, '')), ''),
      nullif(btrim(coalesce(p_city, '')), ''),
      nullif(btrim(coalesce(p_building, '')), ''),
      nullif(btrim(coalesce(p_street, '')), ''),
      nullif(btrim(coalesce(p_landmark, '')), ''),
      nullif(btrim(coalesce(p_floor, '')), ''),
      nullif(btrim(coalesce(p_apartment, '')), ''),
      p_latitude,
      p_longitude,
      zone_id,
      false
    )
    returning * into customer;

    if addr_line is not null or nullif(btrim(coalesce(p_zone, '')), '') is not null then
      insert into public.customer_addresses (
        pos_customer_id, address, zone, branch, governorate, city,
        building, street, landmark, floor, apartment, notes,
        latitude, longitude, fujitsu_zone_id,
        is_primary, synced_to_fujitsu
      ) values (
        customer.id,
        coalesce(addr_line, 'بدون عنوان'),
        nullif(btrim(coalesce(p_zone, '')), ''),
        nullif(btrim(coalesce(p_branch, '')), ''),
        nullif(btrim(coalesce(p_governorate, '')), ''),
        nullif(btrim(coalesce(p_city, '')), ''),
        nullif(btrim(coalesce(p_building, '')), ''),
        nullif(btrim(coalesce(p_street, '')), ''),
        nullif(btrim(coalesce(p_landmark, '')), ''),
        nullif(btrim(coalesce(p_floor, '')), ''),
        nullif(btrim(coalesce(p_apartment, '')), ''),
        nullif(btrim(coalesce(p_notes, '')), ''),
        p_latitude,
        p_longitude,
        zone_id,
        true,
        false
      );
    end if;
  else
    update public.pos_customers c
    set phone = packed[1],
        phone2 = packed[2],
        phone3 = packed[3],
        phone4 = packed[4],
        phone5 = packed[5],
        notes = coalesce(nullif(btrim(coalesce(p_notes, '')), ''), c.notes),
        customer_type = case when ctype = 'vip' then 'vip'
                             else c.customer_type end,
        governorate = coalesce(
          nullif(btrim(coalesce(p_governorate, '')), ''), c.governorate),
        city = coalesce(nullif(btrim(coalesce(p_city, '')), ''), c.city),
        building = coalesce(
          nullif(btrim(coalesce(p_building, '')), ''), c.building),
        street = coalesce(
          nullif(btrim(coalesce(p_street, '')), ''), c.street),
        landmark = coalesce(
          nullif(btrim(coalesce(p_landmark, '')), ''), c.landmark),
        floor = coalesce(nullif(btrim(coalesce(p_floor, '')), ''), c.floor),
        apartment = coalesce(
          nullif(btrim(coalesce(p_apartment, '')), ''), c.apartment),
        latitude = coalesce(p_latitude, c.latitude),
        longitude = coalesce(p_longitude, c.longitude),
        address = coalesce(c.address, addr_line),
        zone = coalesce(c.zone, nullif(btrim(coalesce(p_zone, '')), '')),
        fujitsu_zone_id = case
          when c.zone is null then coalesce(c.fujitsu_zone_id, zone_id)
          else c.fujitsu_zone_id
        end,
        synced_to_fujitsu = false,
        last_seen = now()::timestamp
    where c.id = customer.id
    returning * into customer;

    if addr_line is not null and not exists (
      select 1 from public.customer_addresses a
      where a.pos_customer_id = customer.id
        and a.address = addr_line
    ) then
      insert into public.customer_addresses (
        pos_customer_id, address, zone, branch, governorate, city,
        building, street, landmark, floor, apartment, notes,
        latitude, longitude, fujitsu_zone_id,
        is_primary, synced_to_fujitsu
      ) values (
        customer.id,
        addr_line,
        nullif(btrim(coalesce(p_zone, '')), ''),
        nullif(btrim(coalesce(p_branch, '')), ''),
        nullif(btrim(coalesce(p_governorate, '')), ''),
        nullif(btrim(coalesce(p_city, '')), ''),
        nullif(btrim(coalesce(p_building, '')), ''),
        nullif(btrim(coalesce(p_street, '')), ''),
        nullif(btrim(coalesce(p_landmark, '')), ''),
        nullif(btrim(coalesce(p_floor, '')), ''),
        nullif(btrim(coalesce(p_apartment, '')), ''),
        nullif(btrim(coalesce(p_notes, '')), ''),
        p_latitude,
        p_longitude,
        zone_id,
        not exists (
          select 1 from public.customer_addresses x
          where x.pos_customer_id = customer.id and x.is_primary
        ),
        false
      );
    end if;
  end if;

  return query select
    case when customer.profile_id is not null then 'app' else 'pos' end,
    customer.profile_id,
    customer.id,
    customer.full_name,
    customer.phone, customer.phone2, customer.phone3, customer.phone4, customer.phone5,
    customer.notes, customer.address, customer.zone, customer.fujitsu_zone_id,
    customer.fujitsu_customer_no;
end;
$$;

revoke all on function public.create_phone_order_customer(
  text, text, text, text, text, text, text, text, text, text, text,
  double precision, double precision, text, text, text, text, text, text,
  text, text
) from public, anon;
grant execute on function public.create_phone_order_customer(
  text, text, text, text, text, text, text, text, text, text, text,
  double precision, double precision, text, text, text, text, text, text,
  text, text
) to authenticated, service_role;
