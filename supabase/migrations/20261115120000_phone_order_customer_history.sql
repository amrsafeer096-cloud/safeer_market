-- Customer purchase history for «تلقي الطلبات»: frequent + recent items
-- and the lines of the caller's most recent order (repeat last order).
-- Matches by user_id, pos_customer_id, or normalized Egyptian phone so app
-- and POS phone-order customers share one history when the number matches.

drop function if exists public.phone_order_customer_history(uuid, bigint, text, integer);

create or replace function public.phone_order_customer_history(
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
  items jsonb := '[]'::jsonb;
  last_items jsonb := '[]'::jsonb;
begin
  if not public.is_order_taker() then
    raise exception 'not_allowed' using errcode = '42501';
  end if;

  if p_user_id is null
     and p_pos_customer_id is null
     and (digits is null or digits = '') then
    return jsonb_build_object(
      'items', '[]'::jsonb,
      'last_order_items', '[]'::jsonb
    );
  end if;

  with matched_orders as (
    select o.id, o.created_at
    from public.orders o
    where (p_user_id is not null and o.user_id = p_user_id)
       or (p_pos_customer_id is not null and o.pos_customer_id = p_pos_customer_id)
       or (
            digits is not null
            and digits <> ''
            and public.normalize_egyptian_phone(o.customer_phone) = digits
          )
  ),
  last_order as (
    select mo.id
    from matched_orders mo
    order by mo.created_at desc
    limit 1
  ),
  last_lines as (
    select
      oi.product_id,
      oi.quantity,
      oi.weight_in_grams,
      p.name,
      p.price,
      p.discount_price,
      p.image_url,
      p.unit,
      p.barcode,
      p.stock_quantity,
      p.is_active,
      coalesce(p.is_weight_based, false) as is_weight_based
    from public.order_items oi
    join last_order lo on lo.id = oi.order_id
    join public.products p on p.id = oi.product_id
    where coalesce(p.is_active, true)
  ),
  agg as (
    select
      oi.product_id,
      count(distinct oi.order_id)::int as times_ordered,
      sum(oi.quantity)::numeric as total_quantity,
      max(mo.created_at) as last_ordered_at
    from public.order_items oi
    join matched_orders mo on mo.id = oi.order_id
    group by oi.product_id
  ),
  last_per_product as (
    select distinct on (oi.product_id)
      oi.product_id,
      oi.quantity as last_quantity,
      oi.weight_in_grams as last_weight_in_grams
    from public.order_items oi
    join matched_orders mo on mo.id = oi.order_id
    order by oi.product_id, mo.created_at desc
  ),
  history as (
    select
      a.product_id,
      a.times_ordered,
      a.total_quantity,
      a.last_ordered_at,
      lp.last_quantity,
      lp.last_weight_in_grams,
      p.name,
      p.price,
      p.discount_price,
      p.image_url,
      p.unit,
      p.barcode,
      p.stock_quantity,
      p.is_active,
      coalesce(p.is_weight_based, false) as is_weight_based
    from agg a
    join last_per_product lp on lp.product_id = a.product_id
    join public.products p on p.id = a.product_id
    where coalesce(p.is_active, true)
    order by a.times_ordered desc, a.last_ordered_at desc
    limit lim
  )
  select
    coalesce(
      (select jsonb_agg(to_jsonb(h) order by h.times_ordered desc, h.last_ordered_at desc)
       from history h),
      '[]'::jsonb
    ),
    coalesce(
      (select jsonb_agg(to_jsonb(l)) from last_lines l),
      '[]'::jsonb
    )
  into items, last_items;

  return jsonb_build_object(
    'items', coalesce(items, '[]'::jsonb),
    'last_order_items', coalesce(last_items, '[]'::jsonb)
  );
end;
$$;

revoke execute on function public.phone_order_customer_history(
  uuid, bigint, text, integer
) from public, anon;
grant execute on function public.phone_order_customer_history(
  uuid, bigint, text, integer
) to authenticated, service_role;

create index if not exists orders_pos_customer_id_idx
  on public.orders (pos_customer_id)
  where pos_customer_id is not null;

create index if not exists orders_user_id_idx
  on public.orders (user_id)
  where user_id is not null;
