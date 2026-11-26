-- Allow Egyptian mobile + landline on customer phone fields / search.
-- Safe to re-run.

create or replace function public.is_egyptian_customer_phone(p_digits text)
returns boolean
language sql
immutable
set search_path = ''
as $$
  select
    -- Mobile: 01[0125] + 8 digits
    coalesce(p_digits, '') ~ '^01[0125][0-9]{8}$'
    -- Landline with area code: 0 + [2-9] + 6..8 digits (total 8..10)
    or coalesce(p_digits, '') ~ '^0[2-9][0-9]{6,8}$'
    -- Local landline without area code: 7..8 digits not starting with 0/1
    or coalesce(p_digits, '') ~ '^[2-9][0-9]{6,7}$';
$$;

revoke all on function public.is_egyptian_customer_phone(text) from public, anon;
grant execute on function public.is_egyptian_customer_phone(text)
  to authenticated, service_role;


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
  p_branch text default null
)
returns table (
  source text,
  user_id uuid,
  pos_customer_id bigint,
  full_name text,
  phone text,
  phone2 text,
  phone3 text,
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
  digits text := public.normalize_egyptian_phone(p_phone);
  digits2 text := case
    when btrim(coalesce(p_phone2, '')) = '' then null
    else public.normalize_egyptian_phone(p_phone2)
  end;
  digits3 text := case
    when btrim(coalesce(p_phone3, '')) = '' then null
    else public.normalize_egyptian_phone(p_phone3)
  end;
  ctype text := lower(btrim(coalesce(p_customer_type, 'regular')));
  zone_id text := nullif(btrim(coalesce(p_fujitsu_zone_id, '')), '');
  customer public.pos_customers;
  addr_line text := nullif(btrim(coalesce(p_address, '')), '');
  new_addr_id bigint;
begin
  if not public.is_order_taker() then
    raise exception 'not_allowed' using errcode = '42501';
  end if;
  if btrim(coalesce(p_full_name, '')) = '' then
    raise exception 'name_required' using errcode = '22023';
  end if;
  if not public.is_egyptian_customer_phone(digits)
     or (digits2 is not null and not public.is_egyptian_customer_phone(digits2))
     or (digits3 is not null and not public.is_egyptian_customer_phone(digits3)) then
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
      phone2, phone3, notes, customer_type, governorate, city, building, floor,
      apartment, latitude, longitude, fujitsu_zone_id, synced_to_fujitsu
    )
    values (
      nextval('public.pos_customers_app_id_seq'),
      btrim(p_full_name),
      digits,
      addr_line,
      nullif(btrim(coalesce(p_zone, '')), ''),
      'safeer_app',
      now()::timestamp,
      digits2,
      digits3,
      nullif(btrim(coalesce(p_notes, '')), ''),
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

    if addr_line is not null or nullif(btrim(coalesce(p_zone, '')), '') is not null then
      insert into public.customer_addresses (
        pos_customer_id, address, zone, branch, governorate, city,
        building, floor, apartment, latitude, longitude, fujitsu_zone_id,
        is_primary
      ) values (
        customer.id,
        coalesce(addr_line, 'بدون عنوان'),
        nullif(btrim(coalesce(p_zone, '')), ''),
        nullif(btrim(coalesce(p_branch, '')), ''),
        nullif(btrim(coalesce(p_governorate, '')), ''),
        nullif(btrim(coalesce(p_city, '')), ''),
        nullif(btrim(coalesce(p_building, '')), ''),
        nullif(btrim(coalesce(p_floor, '')), ''),
        nullif(btrim(coalesce(p_apartment, '')), ''),
        p_latitude,
        p_longitude,
        zone_id,
        true
      );
    end if;
  else
    update public.pos_customers c
    set phone2 = coalesce(digits2, c.phone2),
        phone3 = coalesce(digits3, c.phone3),
        notes = coalesce(nullif(btrim(coalesce(p_notes, '')), ''), c.notes),
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
        address = coalesce(c.address, addr_line),
        zone = coalesce(c.zone, nullif(btrim(coalesce(p_zone, '')), '')),
        fujitsu_zone_id = case
          when c.zone is null then coalesce(c.fujitsu_zone_id, zone_id)
          else c.fujitsu_zone_id
        end,
        synced_to_fujitsu = case
          when digits2 is distinct from c.phone2
            or digits3 is distinct from c.phone3
            or addr_line is not null
          then false
          else c.synced_to_fujitsu
        end
    where c.id = customer.id
    returning * into customer;

    if addr_line is not null and not exists (
      select 1 from public.customer_addresses a
      where a.pos_customer_id = customer.id
        and a.address = addr_line
    ) then
      insert into public.customer_addresses (
        pos_customer_id, address, zone, branch, governorate, city,
        building, floor, apartment, latitude, longitude, fujitsu_zone_id,
        is_primary
      ) values (
        customer.id,
        addr_line,
        nullif(btrim(coalesce(p_zone, '')), ''),
        nullif(btrim(coalesce(p_branch, '')), ''),
        nullif(btrim(coalesce(p_governorate, '')), ''),
        nullif(btrim(coalesce(p_city, '')), ''),
        nullif(btrim(coalesce(p_building, '')), ''),
        nullif(btrim(coalesce(p_floor, '')), ''),
        nullif(btrim(coalesce(p_apartment, '')), ''),
        p_latitude,
        p_longitude,
        zone_id,
        not exists (
          select 1 from public.customer_addresses x
          where x.pos_customer_id = customer.id and x.is_primary
        )
      )
      returning id into new_addr_id;
    end if;
  end if;

  return query select 'pos'::text, null::uuid, customer.id,
    customer.full_name, customer.phone, customer.phone2, customer.phone3,
    customer.notes, customer.address, customer.zone, customer.fujitsu_zone_id,
    customer.fujitsu_customer_no;
end;
$$;

create or replace function public.update_phone_order_customer_details(
  p_pos_customer_id bigint,
  p_full_name text default null,
  p_phone text default null,
  p_phone2 text default null,
  p_phone3 text default null,
  p_notes text default null
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  digits text;
  digits2 text;
  digits3 text;
  customer public.pos_customers;
begin
  if not public.is_order_taker() then
    raise exception 'not_allowed' using errcode = '42501';
  end if;

  digits := case
    when btrim(coalesce(p_phone, '')) = '' then null
    else public.normalize_egyptian_phone(p_phone)
  end;
  digits2 := case
    when p_phone2 is null then null
    when btrim(p_phone2) = '' then ''
    else public.normalize_egyptian_phone(p_phone2)
  end;
  digits3 := case
    when p_phone3 is null then null
    when btrim(p_phone3) = '' then ''
    else public.normalize_egyptian_phone(p_phone3)
  end;

  if digits is not null and not public.is_egyptian_customer_phone(digits) then
    raise exception 'invalid_phone' using errcode = '22023';
  end if;
  if digits2 is not null and digits2 <> '' and not public.is_egyptian_customer_phone(digits2) then
    raise exception 'invalid_phone' using errcode = '22023';
  end if;
  if digits3 is not null and digits3 <> '' and not public.is_egyptian_customer_phone(digits3) then
    raise exception 'invalid_phone' using errcode = '22023';
  end if;

  update public.pos_customers c
  set full_name = coalesce(nullif(btrim(coalesce(p_full_name, '')), ''), c.full_name),
      phone = coalesce(digits, c.phone),
      phone2 = case
        when digits2 is null then c.phone2
        when digits2 = '' then null
        else digits2
      end,
      phone3 = case
        when digits3 is null then c.phone3
        when digits3 = '' then null
        else digits3
      end,
      notes = case
        when p_notes is null then c.notes
        else nullif(btrim(p_notes), '')
      end,
      synced_to_fujitsu = false,
      last_seen = now()::timestamp
  where c.id = p_pos_customer_id
  returning * into customer;

  if not found then
    raise exception 'customer_not_found' using errcode = 'P0002';
  end if;

  return jsonb_build_object(
    'source', 'pos',
    'pos_customer_id', customer.id,
    'full_name', customer.full_name,
    'phone', customer.phone,
    'phone2', customer.phone2,
    'phone3', customer.phone3,
    'notes', customer.notes,
    'fujitsu_customer_no', customer.fujitsu_customer_no,
    'fujitsu_zone_id', customer.fujitsu_zone_id,
    'address', customer.address,
    'zone', customer.zone
  );
end;
$$;
