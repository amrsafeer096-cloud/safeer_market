-- Multi-address + phone2/phone3 + notes for «تلقي الطلبات» customer modal
-- (Fujitsu Delivery-style «بيانات العميل»).
--
-- * pos_customers.phone3, notes, fujitsu_customer_no
-- * customer_addresses: many addresses per POS / app customer
-- * Backfill one address row from existing pos_customers address fields
-- * RPCs: get / update customer details, add / update address
-- * search_phone_order_customers returns phone2/phone3/notes
-- * place_phone_order accepts optional p_fujitsu_address_id

-- ---------------------------------------------------------------------------
-- 1. Columns on pos_customers
-- ---------------------------------------------------------------------------
alter table public.pos_customers
  add column if not exists phone3 text,
  add column if not exists notes text,
  add column if not exists fujitsu_customer_no bigint;

-- ---------------------------------------------------------------------------
-- 2. customer_addresses
-- ---------------------------------------------------------------------------
create table if not exists public.customer_addresses (
  id bigint generated always as identity primary key,
  pos_customer_id bigint references public.pos_customers (id) on delete cascade,
  user_id uuid references auth.users (id) on delete cascade,
  address text not null,
  zone text,
  branch text,
  governorate text,
  city text,
  building text,
  floor text,
  apartment text,
  latitude double precision,
  longitude double precision,
  fujitsu_zone_id text,
  fujitsu_address_id bigint,
  is_primary boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint customer_addresses_owner_check
    check (pos_customer_id is not null or user_id is not null)
);

create index if not exists customer_addresses_pos_idx
  on public.customer_addresses (pos_customer_id);
create index if not exists customer_addresses_user_idx
  on public.customer_addresses (user_id);

alter table public.customer_addresses enable row level security;

drop policy if exists "customer_addresses_taker_all" on public.customer_addresses;
create policy "customer_addresses_taker_all" on public.customer_addresses
  for all to authenticated
  using (public.is_order_taker())
  with check (public.is_order_taker());

-- Seed from the single address already stored on pos_customers.
insert into public.customer_addresses (
  pos_customer_id, address, zone, branch, governorate, city,
  building, floor, apartment, latitude, longitude, fujitsu_zone_id,
  is_primary
)
select
  c.id,
  coalesce(nullif(btrim(c.address), ''), 'بدون عنوان'),
  c.zone,
  null,
  c.governorate,
  c.city,
  c.building,
  c.floor,
  c.apartment,
  c.latitude,
  c.longitude,
  c.fujitsu_zone_id,
  true
from public.pos_customers c
where coalesce(nullif(btrim(c.address), ''), nullif(btrim(c.zone), '')) is not null
  and not exists (
    select 1 from public.customer_addresses a where a.pos_customer_id = c.id
  );

-- ---------------------------------------------------------------------------
-- 3. search_phone_order_customers — include phone2/phone3/notes + match them
-- ---------------------------------------------------------------------------
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
  phone2 text,
  phone3 text,
  notes text,
  address text,
  zone text,
  fujitsu_zone_id text,
  fujitsu_customer_no bigint
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
           null::text, null::text, null::text,
           a.line, a.region, null::text, null::bigint
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
           c.phone2, c.phone3, c.notes,
           c.address, c.zone, c.fujitsu_zone_id, c.fujitsu_customer_no
    from public.pos_customers c
    where case
      when by_phone then
        c.phone like digits || '%'
        or coalesce(c.phone2, '') like digits || '%'
        or coalesce(c.phone3, '') like digits || '%'
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

-- ---------------------------------------------------------------------------
-- 4. create_phone_order_customer — phone3 + notes
-- ---------------------------------------------------------------------------
drop function if exists public.create_phone_order_customer(
  text, text, text, text, text, text, text, text, text, text, text,
  double precision, double precision, text);

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
  if digits !~ '^01[0125][0-9]{8}$'
     or (digits2 is not null and digits2 !~ '^01[0125][0-9]{8}$')
     or (digits3 is not null and digits3 !~ '^01[0125][0-9]{8}$') then
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

revoke execute on function public.create_phone_order_customer(
  text, text, text, text, text, text, text, text, text, text, text,
  double precision, double precision, text, text, text, text)
  from public, anon;
grant execute on function public.create_phone_order_customer(
  text, text, text, text, text, text, text, text, text, text, text,
  double precision, double precision, text, text, text, text)
  to authenticated;

-- ---------------------------------------------------------------------------
-- 5. get_phone_order_customer_details
-- ---------------------------------------------------------------------------
create or replace function public.get_phone_order_customer_details(
  p_pos_customer_id bigint default null,
  p_user_id uuid default null
)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  cust jsonb;
  addrs jsonb;
begin
  if not public.is_order_taker() then
    raise exception 'not_allowed' using errcode = '42501';
  end if;
  if p_pos_customer_id is null and p_user_id is null then
    raise exception 'customer_required' using errcode = '22023';
  end if;

  if p_pos_customer_id is not null then
    select jsonb_build_object(
      'source', 'pos',
      'user_id', null,
      'pos_customer_id', c.id,
      'full_name', c.full_name,
      'phone', c.phone,
      'phone2', c.phone2,
      'phone3', c.phone3,
      'notes', c.notes,
      'fujitsu_customer_no', c.fujitsu_customer_no,
      'fujitsu_zone_id', c.fujitsu_zone_id
    ) into cust
    from public.pos_customers c
    where c.id = p_pos_customer_id;

    select coalesce(jsonb_agg(row_to_json(a)::jsonb order by a.is_primary desc, a.id), '[]'::jsonb)
    into addrs
    from public.customer_addresses a
    where a.pos_customer_id = p_pos_customer_id;
  else
    select jsonb_build_object(
      'source', 'app',
      'user_id', p.id,
      'pos_customer_id', null,
      'full_name', p.full_name,
      'phone', p.phone,
      'phone2', null,
      'phone3', null,
      'notes', null,
      'fujitsu_customer_no', null,
      'fujitsu_zone_id', null
    ) into cust
    from public.profiles p
    where p.id = p_user_id;

    select coalesce(jsonb_agg(x.obj order by x.sort_primary desc, x.sort_id), '[]'::jsonb)
    into addrs
    from (
      select
        jsonb_build_object(
          'id', ad.id,
          'pos_customer_id', null,
          'user_id', ad.user_id,
          'address', concat_ws('، ', nullif(ad.region, ''), nullif(ad.street, ''),
                               nullif(ad.building, ''), nullif(ad.floor_apt, '')),
          'zone', ad.region,
          'branch', null,
          'governorate', null,
          'city', null,
          'building', ad.building,
          'floor', ad.floor_apt,
          'apartment', null,
          'latitude', ad.latitude,
          'longitude', ad.longitude,
          'fujitsu_zone_id', null,
          'fujitsu_address_id', null,
          'is_primary', false,
          'source_table', 'addresses'
        ) as obj,
        false as sort_primary,
        ad.created_at as sort_id
      from public.addresses ad
      where ad.user_id = p_user_id
      union all
      select
        row_to_json(ca)::jsonb || jsonb_build_object('source_table', 'customer_addresses'),
        ca.is_primary,
        ca.created_at
      from public.customer_addresses ca
      where ca.user_id = p_user_id
    ) x;
  end if;

  if cust is null then
    raise exception 'customer_not_found' using errcode = 'P0002';
  end if;

  return jsonb_build_object('customer', cust, 'addresses', coalesce(addrs, '[]'::jsonb));
end;
$$;

revoke execute on function public.get_phone_order_customer_details(bigint, uuid)
  from public, anon;
grant execute on function public.get_phone_order_customer_details(bigint, uuid)
  to authenticated;

-- ---------------------------------------------------------------------------
-- 6. update_phone_order_customer_details (name / phones / notes)
-- ---------------------------------------------------------------------------
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

  if digits is not null and digits !~ '^01[0125][0-9]{8}$' then
    raise exception 'invalid_phone' using errcode = '22023';
  end if;
  if digits2 is not null and digits2 <> '' and digits2 !~ '^01[0125][0-9]{8}$' then
    raise exception 'invalid_phone' using errcode = '22023';
  end if;
  if digits3 is not null and digits3 <> '' and digits3 !~ '^01[0125][0-9]{8}$' then
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

revoke execute on function public.update_phone_order_customer_details(
  bigint, text, text, text, text, text) from public, anon;
grant execute on function public.update_phone_order_customer_details(
  bigint, text, text, text, text, text) to authenticated;

-- ---------------------------------------------------------------------------
-- 7. upsert_customer_address (add or edit)
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
  p_is_primary boolean default false
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
    line := concat_ws('، ',
      case when nullif(btrim(coalesce(p_building, '')), '') is not null
        then 'مبنى ' || btrim(p_building) end,
      case when nullif(btrim(coalesce(p_floor, '')), '') is not null
        then 'الدور ' || btrim(p_floor) end,
      case when nullif(btrim(coalesce(p_apartment, '')), '') is not null
        then 'شقة ' || btrim(p_apartment) end,
      nullif(btrim(coalesce(p_zone, '')), ''),
      nullif(btrim(coalesce(p_city, '')), ''),
      nullif(btrim(coalesce(p_governorate, '')), '')
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
        floor = nullif(btrim(coalesce(p_floor, '')), ''),
        apartment = nullif(btrim(coalesce(p_apartment, '')), ''),
        latitude = coalesce(p_latitude, a.latitude),
        longitude = coalesce(p_longitude, a.longitude),
        fujitsu_zone_id = coalesce(
          nullif(btrim(coalesce(p_fujitsu_zone_id, '')), ''), a.fujitsu_zone_id),
        is_primary = p_is_primary or a.is_primary,
        updated_at = now(),
        fujitsu_address_id = case
          when a.address is distinct from line then null
          else a.fujitsu_address_id
        end
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
      building, floor, apartment, latitude, longitude, fujitsu_zone_id,
      is_primary
    ) values (
      p_pos_customer_id,
      p_user_id,
      line,
      nullif(btrim(coalesce(p_zone, '')), ''),
      nullif(btrim(coalesce(p_branch, '')), ''),
      nullif(btrim(coalesce(p_governorate, '')), ''),
      nullif(btrim(coalesce(p_city, '')), ''),
      nullif(btrim(coalesce(p_building, '')), ''),
      nullif(btrim(coalesce(p_floor, '')), ''),
      nullif(btrim(coalesce(p_apartment, '')), ''),
      p_latitude,
      p_longitude,
      nullif(btrim(coalesce(p_fujitsu_zone_id, '')), ''),
      p_is_primary
    )
    returning * into row;
  end if;

  -- Mirror primary address onto pos_customers for legacy consumers.
  if p_pos_customer_id is not null and row.is_primary then
    update public.pos_customers
    set address = row.address,
        zone = row.zone,
        governorate = row.governorate,
        city = row.city,
        building = row.building,
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
  double precision, double precision, text, boolean) from public, anon;
grant execute on function public.upsert_customer_address(
  bigint, uuid, bigint, text, text, text, text, text, text, text, text,
  double precision, double precision, text, boolean) to authenticated;

-- ---------------------------------------------------------------------------
-- 8. place_phone_order — optional fujitsu_address_id (extends payment RPC)
-- ---------------------------------------------------------------------------
drop function if exists public.place_phone_order(
  uuid, bigint, text, text, text, text, jsonb, numeric, text, text, text);

create or replace function public.place_phone_order(
  p_user_id uuid,
  p_pos_customer_id bigint,
  p_customer_name text,
  p_customer_phone text,
  p_address text,
  p_area text,
  p_items jsonb,
  p_delivery_fee numeric,
  p_payment_method text default 'cash',
  p_payment_status text default null,
  p_receipt_url text default null,
  p_fujitsu_address_id bigint default null
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  new_order_id uuid;
  item jsonb;
  product public.products;
  qty integer;
  grams integer;
  unit_price numeric;
  line_price numeric;
  items_total numeric := 0;
  taker text;
  method text := lower(btrim(coalesce(p_payment_method, 'cash')));
  receipt text := nullif(btrim(coalesce(p_receipt_url, '')), '');
  pay_status text;
begin
  if not public.is_order_taker() then
    raise exception 'not_allowed' using errcode = '42501';
  end if;
  if p_user_id is null and p_pos_customer_id is null then
    raise exception 'customer_required' using errcode = '22023';
  end if;
  if jsonb_typeof(p_items) is distinct from 'array'
     or jsonb_array_length(p_items) = 0 then
    raise exception 'items_required' using errcode = '22023';
  end if;
  if p_delivery_fee is null or p_delivery_fee < 0 or p_delivery_fee > 500 then
    raise exception 'invalid_delivery_fee' using errcode = '22023';
  end if;
  if method not in ('cash', 'visa_on_delivery', 'instapay') then
    raise exception 'invalid_payment_method' using errcode = '22023';
  end if;
  if method = 'instapay' and receipt is null then
    raise exception 'receipt_required' using errcode = '22023';
  end if;
  pay_status := case when method = 'instapay' then 'paid' else 'unpaid' end;

  select full_name into taker from public.profiles where id = auth.uid();

  insert into public.orders (
    user_id, pos_customer_id, customer_name, customer_phone,
    address_details, delivery_area, delivery_fee, total_amount,
    status, payment_method, payment_status, receipt_url,
    order_source, taker_name, fujitsu_address_id
  ) values (
    p_user_id, p_pos_customer_id,
    nullif(btrim(coalesce(p_customer_name, '')), ''),
    nullif(btrim(coalesce(p_customer_phone, '')), ''),
    nullif(btrim(coalesce(p_address, '')), ''),
    nullif(btrim(coalesce(p_area, '')), ''),
    p_delivery_fee, 0,
    'pending', method, pay_status,
    case when method = 'instapay' then receipt end,
    'phone', taker, p_fujitsu_address_id
  )
  returning id into new_order_id;

  for item in select value from jsonb_array_elements(p_items) loop
    qty := (item ->> 'quantity')::integer;
    if qty is null or qty < 1 or qty > 999 then
      raise exception 'invalid_quantity' using errcode = '22023';
    end if;

    grams := null;
    if item ? 'weight_in_grams' and nullif(item ->> 'weight_in_grams', '') is not null then
      grams := (item ->> 'weight_in_grams')::integer;
      if grams is null or grams < 1 or grams > 10000 then
        raise exception 'invalid_weight' using errcode = '22023';
      end if;
      qty := 1;
    end if;

    select * into product
    from public.products
    where id = (item ->> 'product_id')::uuid;
    if not found then
      raise exception 'product_not_found' using errcode = 'P0002';
    end if;

    unit_price := case
      when product.discount_price > 0 and product.discount_price < product.price
        then product.discount_price
      else product.price
    end;

    if grams is not null then
      line_price := round(unit_price * grams / 1000.0, 2);
    else
      line_price := unit_price;
    end if;

    insert into public.order_items (
      order_id, product_id, quantity, price_at_time, weight_in_grams
    ) values (
      new_order_id, product.id, qty, line_price, grams
    );
    items_total := items_total + line_price * qty;
  end loop;

  update public.orders
  set total_amount = items_total + p_delivery_fee
  where id = new_order_id;

  if p_pos_customer_id is not null then
    update public.pos_customers
    set last_seen = now()::timestamp
    where id = p_pos_customer_id;
  end if;

  return new_order_id;
end;
$$;

revoke execute on function public.place_phone_order(
  uuid, bigint, text, text, text, text, jsonb, numeric, text, text, text, bigint)
  from public, anon;
grant execute on function public.place_phone_order(
  uuid, bigint, text, text, text, text, jsonb, numeric, text, text, text, bigint)
  to authenticated;

notify pgrst, 'reload schema';
