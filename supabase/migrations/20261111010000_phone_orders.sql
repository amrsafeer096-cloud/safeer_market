-- Phone orders from the admin dashboard («طلبات التليفون / بحث العملاء»).
--
-- Staff look callers up among app users (profiles + their latest address)
-- and the POS customers (pos_customers, ~17k rows imported from the POS),
-- add a caller who is in neither, and place the order for them. Callers
-- without an app account have no profiles row, so orders.user_id becomes
-- optional and such orders point at pos_customers instead.
--
-- Everything goes through the security-definer functions below, callable
-- only by staff who take orders (profiles.role admin, warehouse, cashier);
-- pos_customers keeps RLS with no client policies.

-- 1. Who an order is for, readable straight off the orders row.
alter table public.orders
  add column if not exists customer_name text,
  add column if not exists customer_phone text,
  add column if not exists pos_customer_id bigint
    references public.pos_customers (id) on delete set null,
  add column if not exists order_source text not null default 'app';

alter table public.orders alter column user_id drop not null;

do $$
begin
  if not exists (
    select 1 from pg_constraint
    where conrelid = 'public.orders'::regclass
      and conname = 'orders_has_customer'
  ) then
    alter table public.orders add constraint orders_has_customer
      check (user_id is not null or pos_customer_id is not null);
  end if;
end;
$$;

-- App orders get the customer's name and phone from their profile.
create or replace function public.orders_fill_customer()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if new.user_id is not null
     and (new.customer_name is null or new.customer_phone is null) then
    select coalesce(new.customer_name, p.full_name),
           coalesce(new.customer_phone, p.phone)
      into new.customer_name, new.customer_phone
    from public.profiles p
    where p.id = new.user_id;
  end if;
  return new;
end;
$$;

drop trigger if exists orders_fill_customer on public.orders;
create trigger orders_fill_customer
  before insert on public.orders
  for each row execute function public.orders_fill_customer();

update public.orders o
set customer_name = coalesce(o.customer_name, p.full_name),
    customer_phone = coalesce(o.customer_phone, p.phone)
from public.profiles p
where p.id = o.user_id
  and (o.customer_name is null or o.customer_phone is null);

-- 2. Customers added from the dashboard: ids far above the POS's own.
create sequence if not exists public.pos_customers_app_id_seq
  start with 1000000000;

create index if not exists pos_customers_phone_prefix_idx
  on public.pos_customers (phone text_pattern_ops);

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

-- Egyptian mobile number as 01XXXXXXXXX (from +20…, 0020…, spaces…).
create or replace function public.normalize_egyptian_phone(p_phone text)
returns text
language sql
immutable
set search_path = ''
as $$
  select case
    when d like '0020%' then '0' || substr(d, 5)
    when d like '20%' and length(d) = 12 then '0' || substr(d, 3)
    when d like '1%' and length(d) = 10 then '0' || d
    else d
  end
  from (select regexp_replace(coalesce(p_phone, ''), '\D', '', 'g') as d) s;
$$;

-- Versions made by hand on production (2026-11-10) have the same argument
-- types with other names and return types, which `create or replace` can't
-- change — and they were callable by anyone, with no role check.
drop function if exists public.search_phone_order_customers(integer, text);
drop function if exists public.search_phone_order_customers(text, integer);
drop function if exists public.create_phone_order_customer(text, text, text, text);
drop function if exists public.place_phone_order(
  uuid, bigint, text, text, text, text, jsonb, numeric);

-- 3. Search: 3+ digits match phone numbers, anything else names.
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
  zone text
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
           a.line, a.region
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
           c.address, c.zone
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

-- 4. «+ عميل جديد»: adds the caller to pos_customers, or returns the
--    customer already saved under that phone number.
create or replace function public.create_phone_order_customer(
  p_full_name text,
  p_phone text,
  p_address text default null,
  p_zone text default null
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
  customer public.pos_customers;
begin
  if not public.is_order_taker() then
    raise exception 'not_allowed' using errcode = '42501';
  end if;
  if btrim(coalesce(p_full_name, '')) = '' then
    raise exception 'name_required' using errcode = '22023';
  end if;
  if digits !~ '^01[0125][0-9]{8}$' then
    raise exception 'invalid_phone' using errcode = '22023';
  end if;

  select * into customer
  from public.pos_customers c
  where c.phone = digits
  order by c.last_seen desc nulls last, c.id desc
  limit 1;

  if not found then
    insert into public.pos_customers
      (id, full_name, phone, address, zone, source_system, last_seen)
    values (
      nextval('public.pos_customers_app_id_seq'),
      btrim(p_full_name),
      digits,
      nullif(btrim(coalesce(p_address, '')), ''),
      nullif(btrim(coalesce(p_zone, '')), ''),
      'safeer_app',
      now()::timestamp
    )
    returning * into customer;
  end if;

  return query select 'pos'::text, null::uuid, customer.id,
    customer.full_name, customer.phone, customer.address, customer.zone;
end;
$$;

-- 5. «تأكيد وتسجيل الطلب»: the order and its items in one transaction,
--    priced from products (offer price when there is one, as in the app),
--    status 'pending' so it shows up as «جديد» on the dashboard.
--    p_items: [{"product_id": uuid, "quantity": int}, ...]
create or replace function public.place_phone_order(
  p_user_id uuid,
  p_pos_customer_id bigint,
  p_customer_name text,
  p_customer_phone text,
  p_address text,
  p_area text,
  p_items jsonb,
  p_delivery_fee numeric
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
  unit_price numeric;
  items_total numeric := 0;
  taker text;
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

  select full_name into taker from public.profiles where id = auth.uid();

  insert into public.orders (
    user_id, pos_customer_id, customer_name, customer_phone,
    address_details, delivery_area, delivery_fee, total_amount,
    status, payment_method, order_source, taker_name
  ) values (
    p_user_id, p_pos_customer_id,
    nullif(btrim(coalesce(p_customer_name, '')), ''),
    nullif(btrim(coalesce(p_customer_phone, '')), ''),
    nullif(btrim(coalesce(p_address, '')), ''),
    nullif(btrim(coalesce(p_area, '')), ''),
    p_delivery_fee, 0,
    'pending', 'cash_on_delivery', 'phone', taker
  )
  returning id into new_order_id;

  for item in select value from jsonb_array_elements(p_items) loop
    qty := (item ->> 'quantity')::integer;
    if qty is null or qty < 1 or qty > 999 then
      raise exception 'invalid_quantity' using errcode = '22023';
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
    insert into public.order_items (order_id, product_id, quantity, price_at_time)
    values (new_order_id, product.id, qty, unit_price);
    items_total := items_total + unit_price * qty;
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

revoke execute on function public.search_phone_order_customers(text, integer)
  from public, anon;
grant execute on function public.search_phone_order_customers(text, integer)
  to authenticated;
revoke execute on function
  public.create_phone_order_customer(text, text, text, text) from public, anon;
grant execute on function
  public.create_phone_order_customer(text, text, text, text) to authenticated;
revoke execute on function public.place_phone_order(
  uuid, bigint, text, text, text, text, jsonb, numeric) from public, anon;
grant execute on function public.place_phone_order(
  uuid, bigint, text, text, text, text, jsonb, numeric) to authenticated;

-- PostgREST answers PGRST202 for functions it hasn't seen yet.
notify pgrst, 'reload schema';
