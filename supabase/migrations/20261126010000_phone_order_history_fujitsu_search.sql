-- 1) Customer search also matches fujitsu_customer_no (digits).
-- 2) List past orders for the locked caller (left «الطلبات السابقة» tab).
-- 3) Order detail lines for the repeat-order modal.
-- Safe to re-run.

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
  -- Pure / mostly-numeric queries also match Fujitsu customer numbers.
  by_fujitsu := length(regexp_replace(q, '\D', '', 'g')) >= 4
               and q !~ '[^\d\s+()-]';
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
          and c.fujitsu_customer_no::text like '%' || regexp_replace(q, '\D', '', 'g') || '%'
        )
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
-- Past orders list for the locked customer (left history panel).
-- ---------------------------------------------------------------------------
drop function if exists public.phone_order_customer_orders(uuid, bigint, text, integer);

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
begin
  if not public.is_order_taker() then
    raise exception 'not_allowed' using errcode = '42501';
  end if;

  if p_user_id is null
     and p_pos_customer_id is null
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
    where (p_user_id is not null and o.user_id = p_user_id)
       or (p_pos_customer_id is not null and o.pos_customer_id = p_pos_customer_id)
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

revoke execute on function public.phone_order_customer_orders(uuid, bigint, text, integer)
  from public, anon;
grant execute on function public.phone_order_customer_orders(uuid, bigint, text, integer)
  to authenticated;

-- ---------------------------------------------------------------------------
-- One past order's lines (repeat-order modal).
-- ---------------------------------------------------------------------------
drop function if exists public.phone_order_customer_order_detail(uuid);

create or replace function public.phone_order_customer_order_detail(
  p_order_id uuid
)
returns jsonb
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  r_order public.orders%rowtype;
  r_items jsonb;
begin
  if not public.is_order_taker() then
    raise exception 'not_allowed' using errcode = '42501';
  end if;

  select * into r_order from public.orders where id = p_order_id;
  if not found then
    raise exception 'Order not found' using errcode = 'P0002';
  end if;

  select coalesce(
    jsonb_agg(
      jsonb_build_object(
        'product_id', oi.product_id,
        'quantity', oi.quantity,
        'weight_in_grams', oi.weight_in_grams,
        'price_at_time', oi.price_at_time,
        'name', p.name,
        'barcode', p.barcode,
        'price', p.price,
        'discount_price', p.discount_price,
        'image_url', p.image_url,
        'unit', p.unit,
        'stock_quantity', p.stock_quantity,
        'is_active', p.is_active,
        'is_weight_based', coalesce(p.is_weight_based, false)
      )
      order by coalesce(p.name, '')
    ),
    '[]'::jsonb
  )
  into r_items
  from public.order_items oi
  left join public.products p on p.id = oi.product_id
  where oi.order_id = r_order.id;

  return jsonb_build_object(
    'order_id', r_order.id,
    'fujitsu_order_id', r_order.fujitsu_order_id,
    'pos_receipt_number', r_order.pos_receipt_number,
    'created_at', r_order.created_at,
    'total_amount', coalesce(r_order.total_amount, 0),
    'delivery_fee', coalesce(r_order.delivery_fee, 0),
    'status', r_order.status,
    'taker_name', r_order.taker_name,
    'preparer_name', r_order.preparer_name,
    'driver_name', r_order.driver_name,
    'payment_method', r_order.payment_method,
    'customer_name', r_order.customer_name,
    'customer_phone', r_order.customer_phone,
    'address_details', r_order.address_details,
    'items', r_items
  );
end;
$$;

revoke execute on function public.phone_order_customer_order_detail(uuid)
  from public, anon;
grant execute on function public.phone_order_customer_order_detail(uuid)
  to authenticated;

notify pgrst, 'reload schema';
