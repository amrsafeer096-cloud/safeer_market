-- Deduplicate customer phones + link app profiles to existing pos_customers.
-- Safe to re-run.

-- ---------------------------------------------------------------------------
-- 1. Link column: one app profile ↔ one POS customer
-- ---------------------------------------------------------------------------
alter table public.pos_customers
  add column if not exists profile_id uuid references auth.users (id) on delete set null;

create unique index if not exists pos_customers_profile_id_uidx
  on public.pos_customers (profile_id)
  where profile_id is not null;

comment on column public.pos_customers.profile_id is
  'Linked auth/profile user when this POS customer registered on the mobile app.';

-- ---------------------------------------------------------------------------
-- 2. Helpers: secondary phones must differ from primary (and each other)
-- ---------------------------------------------------------------------------
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
    when public.normalize_egyptian_phone(p_candidate)
       = public.normalize_egyptian_phone(p_primary) then null
    else public.normalize_egyptian_phone(p_candidate)
  end;
$$;

revoke all on function public.distinct_customer_phone(text, text) from public, anon;
grant execute on function public.distinct_customer_phone(text, text)
  to authenticated, service_role;

-- Clear already-duplicated secondary phones in place.
update public.pos_customers c
set phone2 = null
where c.phone2 is not null
  and public.normalize_egyptian_phone(c.phone2)
    = public.normalize_egyptian_phone(c.phone);

update public.pos_customers c
set phone3 = null
where c.phone3 is not null
  and (
    public.normalize_egyptian_phone(c.phone3)
      = public.normalize_egyptian_phone(c.phone)
    or (
      c.phone2 is not null
      and public.normalize_egyptian_phone(c.phone3)
        = public.normalize_egyptian_phone(c.phone2)
    )
  );

-- ---------------------------------------------------------------------------
-- 3. Link / merge: app profile → existing POS row by normalized phone
-- ---------------------------------------------------------------------------
create or replace function public.link_profile_to_pos_customer(
  p_user_id uuid default null
)
returns bigint
language plpgsql
security definer
set search_path = ''
as $$
declare
  uid uuid := coalesce(p_user_id, auth.uid());
  digits text;
  display_name text;
  target public.pos_customers;
  already bigint;
  jwt_role text;
  is_privileged boolean;
begin
  if uid is null then
    return null;
  end if;

  jwt_role := coalesce(
    nullif(current_setting('request.jwt.claim.role', true), ''),
    ''
  );
  if jwt_role = '' then
    begin
      jwt_role := coalesce(
        nullif(current_setting('request.jwt.claims', true), '')::jsonb ->> 'role',
        ''
      );
    exception
      when others then
        jwt_role := '';
    end;
  end if;

  -- Privileged: DB owner / service_role, or SQL Editor (no end-user JWT).
  is_privileged :=
    current_user in ('postgres', 'supabase_admin', 'service_role')
    or (
      auth.uid() is null
      and (jwt_role = '' or jwt_role = 'service_role')
    );

  -- End-users may only link themselves (or order-takers linking others).
  if not is_privileged
     and auth.uid() is distinct from uid
     and not public.is_order_taker() then
    raise exception 'not_allowed' using errcode = '42501';
  end if;

  select public.normalize_egyptian_phone(p.phone), nullif(btrim(p.full_name), '')
    into digits, display_name
  from public.profiles p
  where p.id = uid;

  if digits is null or digits = '' then
    return null;
  end if;

  -- Normalize profiles.phone to local Egyptian digits when possible.
  update public.profiles
  set phone = digits
  where id = uid
    and public.normalize_egyptian_phone(phone) is distinct from digits;

  select c.id into already
  from public.pos_customers c
  where c.profile_id = uid
  limit 1;
  if already is not null then
    return already;
  end if;

  select * into target
  from public.pos_customers c
  where c.profile_id is null
    and (
      c.phone = digits
      or coalesce(c.phone2, '') = digits
      or coalesce(c.phone3, '') = digits
    )
  order by
    (c.fujitsu_customer_no is not null) desc,
    (c.fujitsu_customer_id is not null) desc,
    c.last_seen desc nulls last,
    c.id desc
  limit 1;

  if not found then
    return null;
  end if;

  update public.pos_customers c
  set profile_id = uid,
      source_system = 'app',
      full_name = coalesce(nullif(btrim(c.full_name), ''), display_name, c.full_name),
      -- App phone becomes primary; previous primaries/secondaries kept if distinct.
      phone = digits,
      phone2 = public.distinct_customer_phone(
        digits,
        case
          when c.phone is distinct from digits then c.phone
          else c.phone2
        end
      ),
      phone3 = public.distinct_customer_phone(
        digits,
        public.distinct_customer_phone(
          coalesce(
            public.distinct_customer_phone(
              digits,
              case
                when c.phone is distinct from digits then c.phone
                else c.phone2
              end
            ),
            ''
          ),
          case
            when c.phone is distinct from digits
                 and coalesce(c.phone2, '') is distinct from digits
              then coalesce(c.phone2, c.phone3)
            else c.phone3
          end
        )
      ),
      last_seen = now()::timestamp
  where c.id = target.id
  returning * into target;

  -- Attach this user's address rows to the linked POS customer when missing.
  update public.customer_addresses ca
  set pos_customer_id = coalesce(ca.pos_customer_id, target.id)
  where ca.user_id = uid
    and ca.pos_customer_id is null;

  return target.id;
end;
$$;

revoke all on function public.link_profile_to_pos_customer(uuid) from public, anon;
grant execute on function public.link_profile_to_pos_customer(uuid)
  to authenticated, service_role;

-- Auto-link whenever a profile phone is written.
create or replace function public.profiles_link_pos_customer()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if new.phone is null or btrim(new.phone) = '' then
    return new;
  end if;
  if tg_op = 'UPDATE'
     and public.normalize_egyptian_phone(coalesce(old.phone, ''))
       = public.normalize_egyptian_phone(new.phone)
     and exists (
       select 1 from public.pos_customers c where c.profile_id = new.id
     ) then
    return new;
  end if;
  perform public.link_profile_to_pos_customer(new.id);
  return new;
end;
$$;

drop trigger if exists profiles_link_pos_customer_trg on public.profiles;
create trigger profiles_link_pos_customer_trg
  after insert or update of phone on public.profiles
  for each row
  execute function public.profiles_link_pos_customer();

-- Backfill: link existing profiles to matching POS customers (one best match).
do $$
declare
  r record;
begin
  for r in
    select p.id as user_id,
           public.normalize_egyptian_phone(p.phone) as digits
    from public.profiles p
    where p.phone is not null
      and btrim(p.phone) <> ''
      and not exists (
        select 1 from public.pos_customers c where c.profile_id = p.id
      )
  loop
    perform public.link_profile_to_pos_customer(r.user_id);
  end loop;
end;
$$;

-- ---------------------------------------------------------------------------
-- 4. create_phone_order_customer — dedupe phones + match phone2/phone3
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
  digits2 text;
  digits3 text;
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

  digits2 := public.distinct_customer_phone(digits, p_phone2);
  digits3 := public.distinct_customer_phone(
    digits,
    public.distinct_customer_phone(coalesce(digits2, ''), p_phone3)
  );

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
     or coalesce(c.phone2, '') = digits
     or coalesce(c.phone3, '') = digits
  order by
    (c.fujitsu_customer_no is not null) desc,
    c.last_seen desc nulls last,
    c.id desc
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
    set phone2 = coalesce(
          public.distinct_customer_phone(c.phone, digits2), c.phone2),
        phone3 = coalesce(
          public.distinct_customer_phone(
            c.phone,
            public.distinct_customer_phone(coalesce(c.phone2, ''), digits3)
          ),
          c.phone3),
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

  return query select
    case when customer.profile_id is not null then 'app' else 'pos' end,
    customer.profile_id,
    customer.id,
    customer.full_name, customer.phone, customer.phone2, customer.phone3,
    customer.notes, customer.address, customer.zone, customer.fujitsu_zone_id,
    customer.fujitsu_customer_no;
end;
$$;

-- ---------------------------------------------------------------------------
-- 5. update_phone_order_customer_details — never store duplicate secondaries
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
  primary_phone text;
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

  select * into customer
  from public.pos_customers c
  where c.id = p_pos_customer_id;
  if not found then
    raise exception 'customer_not_found' using errcode = 'P0002';
  end if;

  primary_phone := coalesce(digits, customer.phone);

  if digits2 is not null and digits2 <> '' then
    digits2 := coalesce(public.distinct_customer_phone(primary_phone, digits2), '');
  end if;
  if digits3 is not null and digits3 <> '' then
    digits3 := coalesce(
      public.distinct_customer_phone(
        primary_phone,
        public.distinct_customer_phone(
          case when digits2 is null then coalesce(customer.phone2, '')
               when digits2 = '' then ''
               else digits2 end,
          digits3
        )
      ),
      ''
    );
  end if;

  update public.pos_customers c
  set full_name = coalesce(nullif(btrim(coalesce(p_full_name, '')), ''), c.full_name),
      phone = coalesce(digits, c.phone),
      phone2 = case
        when digits2 is null then
          public.distinct_customer_phone(coalesce(digits, c.phone), c.phone2)
        when digits2 = '' then null
        else digits2
      end,
      phone3 = case
        when digits3 is null then
          public.distinct_customer_phone(
            coalesce(digits, c.phone),
            public.distinct_customer_phone(coalesce(c.phone2, ''), c.phone3)
          )
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

  return jsonb_build_object(
    'source', case when customer.profile_id is not null then 'app' else 'pos' end,
    'user_id', customer.profile_id,
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

-- ---------------------------------------------------------------------------
-- 6. search_phone_order_customers — one row per person (POS preferred / linked)
-- ---------------------------------------------------------------------------
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
  by_phone := length(digits) >= 3 and q !~ '[^\d\s+()-]';
  by_fujitsu := length(regexp_replace(q, '\D', '', 'g')) >= 4
               and q !~ '[^\d\s+()-]';
  name_like := '%' || replace(replace(replace(q, '\', '\\'), '%', '\%'), '_', '\_') || '%';

  return query
  with pos_hits as (
    select
      c.*,
      coalesce(c.profile_id, p_by_phone.id) as linked_user_id,
      row_number() over (
        partition by public.normalize_egyptian_phone(c.phone)
        order by
          (c.fujitsu_customer_no is not null) desc,
          (c.profile_id is not null) desc,
          c.last_seen desc nulls last,
          c.id desc
      ) as rn
    from public.pos_customers c
    left join public.profiles p_by_phone
      on c.profile_id is null
     and public.normalize_egyptian_phone(p_by_phone.phone)
       = public.normalize_egyptian_phone(c.phone)
    where case
      when by_phone or by_fujitsu then
        (
          by_phone and (
            c.phone like digits || '%'
            or coalesce(c.phone2, '') like digits || '%'
            or coalesce(c.phone3, '') like digits || '%'
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
      when by_phone then public.normalize_egyptian_phone(p.phone)
                        like '%' || digits || '%'
      else p.full_name ilike name_like
    end
      and not exists (
        select 1 from public.pos_customers c
        where c.profile_id = p.id
           or public.normalize_egyptian_phone(c.phone)
              = public.normalize_egyptian_phone(p.phone)
           or coalesce(c.phone2, '') = public.normalize_egyptian_phone(p.phone)
           or coalesce(c.phone3, '') = public.normalize_egyptian_phone(p.phone)
      )
    limit lim
  )
  select
    case when pu.linked_user_id is not null then 'app' else 'pos' end,
    pu.linked_user_id,
    pu.id,
    pu.full_name,
    pu.phone,
    public.distinct_customer_phone(pu.phone, pu.phone2),
    public.distinct_customer_phone(
      pu.phone,
      public.distinct_customer_phone(coalesce(pu.phone2, ''), pu.phone3)
    ),
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
    null::text,
    null::text,
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

-- ---------------------------------------------------------------------------
-- 7. get_phone_order_customer_details — return linked app + POS as one
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
      'phone2', public.distinct_customer_phone(c.phone, c.phone2),
      'phone3', public.distinct_customer_phone(
                  c.phone,
                  public.distinct_customer_phone(coalesce(c.phone2, ''), c.phone3)),
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

revoke execute on function public.get_phone_order_customer_details(bigint, uuid)
  from public, anon;
grant execute on function public.get_phone_order_customer_details(bigint, uuid)
  to authenticated;

-- ---------------------------------------------------------------------------
-- 8. admin_search_customers — dedupe phones in result + include linked orders
-- ---------------------------------------------------------------------------
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
  digits text := public.normalize_egyptian_phone(p_query);
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
        partition by public.normalize_egyptian_phone(c.phone)
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
       or (length(digits) >= 3
           and (c.phone like '%' || digits || '%'
                or coalesce(c.phone2, '') like '%' || digits || '%'
                or coalesce(c.phone3, '') like '%' || digits || '%'))
  )
  select
    r.id::bigint,
    r.full_name::text,
    r.phone::text,
    public.distinct_customer_phone(r.phone, r.phone2),
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

-- ---------------------------------------------------------------------------
-- 9. Past-order history — resolve linked profile ↔ POS so history is unified
-- ---------------------------------------------------------------------------
create or replace function public.phone_order_customer_orders(
  p_user_id uuid default null,
  p_pos_customer_id bigint default null,
  p_customer_phone text default null,
  p_limit integer default 40
)
returns jsonb
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  digits text := public.normalize_egyptian_phone(p_customer_phone);
  lim integer := greatest(1, least(coalesce(p_limit, 40), 100));
  result jsonb := '[]'::jsonb;
  uid uuid := p_user_id;
  pos_id bigint := p_pos_customer_id;
begin
  if not public.is_order_taker() then
    raise exception 'not_allowed' using errcode = '42501';
  end if;

  if uid is not null and pos_id is null then
    select c.id into pos_id
    from public.pos_customers c
    where c.profile_id = uid
    limit 1;
  end if;
  if pos_id is not null and uid is null then
    select c.profile_id into uid
    from public.pos_customers c
    where c.id = pos_id;
  end if;

  if uid is null
     and pos_id is null
     and (digits is null or digits = '') then
    return '[]'::jsonb;
  end if;

  select coalesce(jsonb_agg(to_jsonb(x) order by x.created_at desc), '[]'::jsonb)
  into result
  from (
    select
      o.id as order_id,
      o.fujitsu_order_id,
      o.pos_receipt_number,
      o.created_at,
      coalesce(o.total_amount, 0) as total_amount,
      coalesce(o.delivery_fee, 0) as delivery_fee,
      o.status,
      o.taker_name,
      o.preparer_name,
      o.driver_name,
      o.payment_method,
      o.customer_name,
      o.customer_phone
    from public.orders o
    where (uid is not null and o.user_id = uid)
       or (pos_id is not null and o.pos_customer_id = pos_id)
       or (
            digits is not null
            and digits <> ''
            and public.normalize_egyptian_phone(o.customer_phone) = digits
          )
    order by o.created_at desc
    limit lim
  ) x;

  return result;
end;
$$;

notify pgrst, 'reload schema';
