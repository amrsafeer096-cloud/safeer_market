-- Up to 5 customer phones + international normalize/search.
-- Safe to re-run.

alter table public.pos_customers
  add column if not exists phone4 text,
  add column if not exists phone5 text;

comment on column public.pos_customers.phone4 is
  'Optional 4th customer phone (Egypt local or +E.164 international).';
comment on column public.pos_customers.phone5 is
  'Optional 5th customer phone (Egypt local or +E.164 international).';

-- Comparable digit key: Egypt local → 20… ; +E.164 / 00… → country+national.
create or replace function public.normalize_customer_phone(p_phone text)
returns text
language plpgsql
immutable
set search_path = ''
as $$
declare
  raw text := btrim(coalesce(p_phone, ''));
  d text;
  egypt text;
begin
  if raw = '' then
    return '';
  end if;

  if raw like '+%' then
    d := regexp_replace(raw, '\D', '', 'g');
    return d;
  end if;

  if raw like '00%' then
    d := regexp_replace(substr(raw, 3), '\D', '', 'g');
    return d;
  end if;

  egypt := public.normalize_egyptian_phone(raw);
  if egypt ~ '^01[0125][0-9]{8}$'
     or egypt ~ '^0[2-9][0-9]{6,8}$'
     or egypt ~ '^[2-9][0-9]{6,7}$' then
    if egypt like '0%' then
      return '20' || substr(egypt, 2);
    end if;
    return '20' || egypt;
  end if;

  -- Non-Egyptian bare digits: keep as-is for LIKE matching.
  return regexp_replace(raw, '\D', '', 'g');
end;
$$;

revoke all on function public.normalize_customer_phone(text) from public, anon;
grant execute on function public.normalize_customer_phone(text)
  to authenticated, service_role;

create or replace function public.distinct_customer_phone(
  p_primary text,
  p_candidate text
)
returns text
language sql
immutable
set search_path = ''
as $$
  select case
    when btrim(coalesce(p_candidate, '')) = '' then null
    when public.normalize_customer_phone(p_candidate) = '' then null
    when public.normalize_customer_phone(p_candidate)
       = public.normalize_customer_phone(p_primary) then null
    else btrim(p_candidate)
  end;
$$;

-- Pack up to 5 phones into distinct slots (preserves storage form).
create or replace function public.pack_customer_phones(
  p1 text, p2 text, p3 text, p4 text, p5 text
)
returns text[]
language plpgsql
immutable
set search_path = ''
as $$
declare
  src text[] := array[p1, p2, p3, p4, p5];
  out text[] := array[]::text[];
  item text;
  key text;
  seen text[] := array[]::text[];
begin
  foreach item in array src loop
    if btrim(coalesce(item, '')) = '' then
      continue;
    end if;
    key := public.normalize_customer_phone(item);
    if key = '' then
      continue;
    end if;
    if key = any (seen) then
      continue;
    end if;
    seen := array_append(seen, key);
    out := array_append(out, btrim(item));
  end loop;
  return out;
end;
$$;

revoke all on function public.pack_customer_phones(text, text, text, text, text)
  from public, anon;
grant execute on function public.pack_customer_phones(text, text, text, text, text)
  to authenticated, service_role;


-- Return-type changes require drop (create or replace cannot add OUT cols).
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
        'search_phone_order_customers',
        'admin_search_customers'
      )
  loop
    execute 'drop function if exists ' || r.sig || ' cascade';
  end loop;
end;
$$;

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
  p_phone5 text default null
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
      building, floor, apartment, latitude, longitude, fujitsu_zone_id,
      synced_to_fujitsu
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


create or replace function public.update_phone_order_customer_details(
  p_pos_customer_id bigint,
  p_full_name text default null,
  p_phone text default null,
  p_phone2 text default null,
  p_phone3 text default null,
  p_notes text default null,
  p_phone4 text default null,
  p_phone5 text default null
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  customer public.pos_customers;
  packed text[];
  has_phones boolean := p_phone is not null
    or p_phone2 is not null
    or p_phone3 is not null
    or p_phone4 is not null
    or p_phone5 is not null;
begin
  if not public.is_order_taker() then
    raise exception 'not_allowed' using errcode = '42501';
  end if;

  select * into customer
  from public.pos_customers c
  where c.id = p_pos_customer_id;
  if not found then
    raise exception 'customer_not_found' using errcode = 'P0002';
  end if;

  if has_phones then
    packed := public.pack_customer_phones(
      coalesce(p_phone, customer.phone),
      case when p_phone2 is null then customer.phone2
           when btrim(p_phone2) = '' then null
           else p_phone2 end,
      case when p_phone3 is null then customer.phone3
           when btrim(p_phone3) = '' then null
           else p_phone3 end,
      case when p_phone4 is null then customer.phone4
           when btrim(p_phone4) = '' then null
           else p_phone4 end,
      case when p_phone5 is null then customer.phone5
           when btrim(p_phone5) = '' then null
           else p_phone5 end
    );
    if coalesce(array_length(packed, 1), 0) < 1 then
      raise exception 'invalid_phone' using errcode = '22023';
    end if;
  end if;

  update public.pos_customers c
  set full_name = coalesce(nullif(btrim(coalesce(p_full_name, '')), ''), c.full_name),
      phone = case when has_phones then packed[1] else c.phone end,
      phone2 = case when has_phones then packed[2] else c.phone2 end,
      phone3 = case when has_phones then packed[3] else c.phone3 end,
      phone4 = case when has_phones then packed[4] else c.phone4 end,
      phone5 = case when has_phones then packed[5] else c.phone5 end,
      notes = case
        when p_notes is null then c.notes
        else nullif(btrim(p_notes), '')
      end,
      synced_to_fujitsu = case when has_phones then false else c.synced_to_fujitsu end,
      last_seen = now()::timestamp
  where c.id = p_pos_customer_id
  returning * into customer;

  return jsonb_build_object(
    'source', case when customer.profile_id is not null then 'app' else 'pos' end,
    'user_id', customer.profile_id,
    'pos_customer_id', customer.id,
    'full_name', customer.full_name,
    'phone', customer.phone,
    'phone2', customer.phone2,
    'phone3', customer.phone3,
    'phone4', customer.phone4,
    'phone5', customer.phone5,
    'notes', customer.notes,
    'fujitsu_customer_no', customer.fujitsu_customer_no,
    'fujitsu_zone_id', customer.fujitsu_zone_id,
    'address', customer.address,
    'zone', customer.zone
  );
end;
$$;


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
  phone4 text,
  phone5 text,
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
  digits text := public.normalize_customer_phone(p_query);
  egypt_digits text := public.normalize_egyptian_phone(p_query);
  by_phone boolean;
  by_fujitsu boolean;
  name_like text;
  lim integer := least(greatest(coalesce(p_limit, 20), 1), 50);
begin
  if not public.is_order_taker() then
    raise exception 'not_allowed' using errcode = '42501';
  end if;
  if length(q) < 2 then
    return;
  end if;
  by_phone := length(coalesce(nullif(digits, ''), egypt_digits)) >= 3
              and q !~ '[^\d\s+()-]';
  by_fujitsu := length(regexp_replace(q, '\D', '', 'g')) >= 4
               and q !~ '[^\d\s+()-]';
  name_like := '%' || replace(replace(replace(q, '\', '\\'), '%', '\%'), '_', '\_') || '%';

  return query
  with pos_hits as (
    select
      c.*,
      coalesce(c.profile_id, p_by_phone.id) as linked_user_id,
      row_number() over (
        partition by public.normalize_customer_phone(c.phone)
        order by
          (c.fujitsu_customer_no is not null) desc,
          (c.profile_id is not null) desc,
          c.last_seen desc nulls last,
          c.id desc
      ) as rn
    from public.pos_customers c
    left join public.profiles p_by_phone
      on c.profile_id is null
     and public.normalize_customer_phone(p_by_phone.phone)
       = public.normalize_customer_phone(c.phone)
    where case
      when by_phone or by_fujitsu then
        (
          by_phone and (
            public.normalize_customer_phone(c.phone) like '%' || digits || '%'
            or public.normalize_customer_phone(coalesce(c.phone2, '')) like '%' || digits || '%'
            or public.normalize_customer_phone(coalesce(c.phone3, '')) like '%' || digits || '%'
            or public.normalize_customer_phone(coalesce(c.phone4, '')) like '%' || digits || '%'
            or public.normalize_customer_phone(coalesce(c.phone5, '')) like '%' || digits || '%'
            or c.phone like egypt_digits || '%'
            or coalesce(c.phone2, '') like egypt_digits || '%'
            or coalesce(c.phone3, '') like egypt_digits || '%'
            or coalesce(c.phone4, '') like egypt_digits || '%'
            or coalesce(c.phone5, '') like egypt_digits || '%'
          )
        )
        or (
          by_fujitsu and c.fujitsu_customer_no is not null
          and c.fujitsu_customer_no::text like '%'
            || regexp_replace(q, '\D', '', 'g') || '%'
        )
      else c.full_name ilike name_like
    end
  ),
  pos_unique as (
    select * from pos_hits where rn = 1 limit lim
  ),
  app_only as (
    select p.*
    from public.profiles p
    where case
      when by_phone then
        public.normalize_customer_phone(p.phone) like '%' || digits || '%'
        or public.normalize_egyptian_phone(p.phone) like '%' || egypt_digits || '%'
      else p.full_name ilike name_like
    end
      and not exists (
        select 1 from public.pos_customers c
        where c.profile_id = p.id
           or public.normalize_customer_phone(c.phone)
              = public.normalize_customer_phone(p.phone)
           or public.normalize_customer_phone(coalesce(c.phone2, ''))
              = public.normalize_customer_phone(p.phone)
           or public.normalize_customer_phone(coalesce(c.phone3, ''))
              = public.normalize_customer_phone(p.phone)
           or public.normalize_customer_phone(coalesce(c.phone4, ''))
              = public.normalize_customer_phone(p.phone)
           or public.normalize_customer_phone(coalesce(c.phone5, ''))
              = public.normalize_customer_phone(p.phone)
      )
    limit lim
  )
  select
    case when pu.linked_user_id is not null then 'app' else 'pos' end,
    pu.linked_user_id,
    pu.id,
    pu.full_name,
    pu.phone, pu.phone2, pu.phone3, pu.phone4, pu.phone5,
    pu.notes,
    pu.address,
    pu.zone,
    pu.fujitsu_zone_id,
    pu.fujitsu_customer_no
  from pos_unique pu
  union all
  select
    'app'::text,
    ao.id,
    null::bigint,
    ao.full_name,
    ao.phone,
    null::text, null::text, null::text, null::text,
    null::text,
    a.line,
    a.region,
    null::text,
    null::bigint
  from app_only ao
  left join lateral (
    select concat_ws('، ', nullif(ad.region, ''), nullif(ad.street, ''),
                     nullif(ad.building, '')) as line,
           ad.region
    from public.addresses ad
    where ad.user_id = ao.id
    order by ad.created_at desc
    limit 1
  ) a on true;
end;
$$;

revoke execute on function public.search_phone_order_customers(text, integer)
  from public, anon;
grant execute on function public.search_phone_order_customers(text, integer)
  to authenticated;


create or replace function public.admin_search_customers(
  p_query text default '',
  p_limit integer default 40
)
returns table (
  id bigint,
  full_name text,
  phone text,
  phone2 text,
  phone3 text,
  phone4 text,
  phone5 text,
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
  digits text := public.normalize_customer_phone(p_query);
  egypt_digits text := public.normalize_egyptian_phone(p_query);
  lim integer := least(greatest(coalesce(p_limit, 40), 1), 100);
begin
  if not public.is_order_taker() then
    raise exception 'forbidden' using errcode = '42501';
  end if;

  return query
  with ranked as (
    select
      c.*,
      row_number() over (
        partition by public.normalize_customer_phone(c.phone)
        order by
          (c.fujitsu_customer_no is not null) desc,
          (c.profile_id is not null) desc,
          c.last_seen desc nulls last,
          c.id desc
      ) as rn
    from public.pos_customers c
    where q = ''
       or c.full_name ilike '%' || q || '%'
       or c.address ilike '%' || q || '%'
       or (length(coalesce(nullif(digits, ''), egypt_digits)) >= 3
           and (
             public.normalize_customer_phone(c.phone) like '%' || digits || '%'
             or public.normalize_customer_phone(coalesce(c.phone2, '')) like '%' || digits || '%'
             or public.normalize_customer_phone(coalesce(c.phone3, '')) like '%' || digits || '%'
             or public.normalize_customer_phone(coalesce(c.phone4, '')) like '%' || digits || '%'
             or public.normalize_customer_phone(coalesce(c.phone5, '')) like '%' || digits || '%'
             or c.phone like '%' || egypt_digits || '%'
             or coalesce(c.phone2, '') like '%' || egypt_digits || '%'
             or coalesce(c.phone3, '') like '%' || egypt_digits || '%'
             or coalesce(c.phone4, '') like '%' || egypt_digits || '%'
             or coalesce(c.phone5, '') like '%' || egypt_digits || '%'
           ))
  )
  select
    r.id::bigint,
    r.full_name::text,
    r.phone::text,
    r.phone2::text,
    r.phone3::text,
    r.phone4::text,
    r.phone5::text,
    r.address::text,
    r.zone::text,
    r.customer_type::text,
    r.governorate::text,
    r.city::text,
    r.building::text,
    r.floor::text,
    r.apartment::text,
    r.latitude,
    r.longitude,
    s.cnt,
    s.spent,
    s.last_at
  from ranked r
  left join lateral (
    select count(*)::bigint as cnt,
           coalesce(sum(o.total_amount)
             filter (where o.status <> 'cancelled'), 0)::numeric as spent,
           max(o.created_at) as last_at
    from public.orders o
    where o.pos_customer_id = r.id
       or (r.profile_id is not null and o.user_id = r.profile_id)
  ) s on true
  where r.rn = 1
  order by case when q = '' then r.last_seen end desc nulls last,
           r.full_name
  limit lim;
end;
$$;

-- Patch get_phone_order_customer_details to return phone4/phone5.
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
  linked_pos bigint;
  linked_user uuid;
begin
  if not public.is_order_taker() then
    raise exception 'not_allowed' using errcode = '42501';
  end if;
  if p_pos_customer_id is null and p_user_id is null then
    raise exception 'customer_required' using errcode = '22023';
  end if;

  linked_pos := p_pos_customer_id;
  linked_user := p_user_id;

  if linked_pos is null and linked_user is not null then
    select c.id into linked_pos
    from public.pos_customers c
    where c.profile_id = linked_user
    limit 1;
  end if;

  if linked_user is null and linked_pos is not null then
    select c.profile_id into linked_user
    from public.pos_customers c
    where c.id = linked_pos;
  end if;

  if linked_pos is not null then
    select jsonb_build_object(
      'source', case when coalesce(c.profile_id, linked_user) is not null
                     then 'app' else 'pos' end,
      'user_id', coalesce(c.profile_id, linked_user),
      'pos_customer_id', c.id,
      'full_name', c.full_name,
      'phone', c.phone,
      'phone2', c.phone2,
      'phone3', c.phone3,
      'phone4', c.phone4,
      'phone5', c.phone5,
      'notes', c.notes,
      'fujitsu_customer_no', c.fujitsu_customer_no,
      'fujitsu_zone_id', c.fujitsu_zone_id,
      'address', c.address,
      'zone', c.zone
    ) into cust
    from public.pos_customers c
    where c.id = linked_pos;

    select coalesce(jsonb_agg(x.obj order by x.sort_primary desc, x.sort_id), '[]'::jsonb)
    into addrs
    from (
      select
        row_to_json(ca)::jsonb || jsonb_build_object('source_table', 'customer_addresses') as obj,
        ca.is_primary as sort_primary,
        ca.created_at as sort_id
      from public.customer_addresses ca
      where ca.pos_customer_id = linked_pos
         or (linked_user is not null and ca.user_id = linked_user)
      union all
      select
        jsonb_build_object(
          'id', ad.id,
          'pos_customer_id', linked_pos,
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
      where linked_user is not null and ad.user_id = linked_user
    ) x;
  else
    select jsonb_build_object(
      'source', 'app',
      'user_id', p.id,
      'pos_customer_id', null,
      'full_name', p.full_name,
      'phone', p.phone,
      'phone2', null,
      'phone3', null,
      'phone4', null,
      'phone5', null,
      'notes', null,
      'fujitsu_customer_no', null,
      'fujitsu_zone_id', null
    ) into cust
    from public.profiles p
    where p.id = linked_user;

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
      where ad.user_id = linked_user
      union all
      select
        row_to_json(ca)::jsonb || jsonb_build_object('source_table', 'customer_addresses'),
        ca.is_primary,
        ca.created_at
      from public.customer_addresses ca
      where ca.user_id = linked_user
    ) x;
  end if;

  if cust is null then
    raise exception 'customer_not_found' using errcode = 'P0002';
  end if;

  return jsonb_build_object('customer', cust, 'addresses', coalesce(addrs, '[]'::jsonb));
end;
$$;

revoke all on function public.create_phone_order_customer(
  text, text, text, text, text, text, text, text, text, text, text,
  double precision, double precision, text, text, text, text, text, text
) from public, anon;
grant execute on function public.create_phone_order_customer(
  text, text, text, text, text, text, text, text, text, text, text,
  double precision, double precision, text, text, text, text, text, text
) to authenticated, service_role;

revoke execute on function public.search_phone_order_customers(text, integer)
  from public, anon;
grant execute on function public.search_phone_order_customers(text, integer)
  to authenticated;

revoke execute on function public.admin_search_customers(text, integer)
  from public, anon;
grant execute on function public.admin_search_customers(text, integer)
  to authenticated;

revoke execute on function public.get_phone_order_customer_details(bigint, uuid)
  from public, anon;
grant execute on function public.get_phone_order_customer_details(bigint, uuid)
  to authenticated;

notify pgrst, 'reload schema';
