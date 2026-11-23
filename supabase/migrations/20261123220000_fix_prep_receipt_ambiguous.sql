-- Fix ambiguous day_key + require preparer before receipt.
-- Replaces get_order_prep_receipt. Safe to re-run.
-- Run this in Supabase SQL Editor (replaces the broken function).

alter table public.orders
  add column if not exists pos_receipt_number text,
  add column if not exists fujitsu_zone_id text,
  add column if not exists pos_branch_code text;

create unique index if not exists orders_pos_receipt_number_uidx
  on public.orders (pos_receipt_number)
  where pos_receipt_number is not null;

-- Rename counter column so it can never clash with a PL/pgSQL variable.
create table if not exists public.pos_receipt_counters (
  receipt_day text primary key,
  last_seq integer not null default 0
);

do $$
begin
  if exists (
    select 1 from information_schema.columns
    where table_schema = 'public'
      and table_name = 'pos_receipt_counters'
      and column_name = 'day_key'
  ) and not exists (
    select 1 from information_schema.columns
    where table_schema = 'public'
      and table_name = 'pos_receipt_counters'
      and column_name = 'receipt_day'
  ) then
    alter table public.pos_receipt_counters rename column day_key to receipt_day;
  end if;
end;
$$;

alter table public.pos_receipt_counters enable row level security;
revoke all on public.pos_receipt_counters from public, anon, authenticated;

create or replace function public.get_order_prep_receipt(p_order_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  r_order public.orders%rowtype;
  r_day text;
  r_seq integer;
  r_number text;
  r_zone text;
  r_customer text;
  r_branch text;
  r_fee text;
  r_phone2 text;
  r_qr text;
  r_items jsonb;
begin
  if auth.uid() is null then
    raise exception 'Not signed in' using errcode = '28000';
  end if;

  select * into r_order from public.orders where id = p_order_id;
  if not found then
    raise exception 'Order not found' using errcode = 'P0002';
  end if;

  -- Receipt only after a preparer is assigned.
  if r_order.preparer_name is null
     or btrim(r_order.preparer_name) = '' then
    raise exception 'اختر المحضر أولاً قبل طباعة الإيصال'
      using errcode = 'P0001';
  end if;

  -- Sequential POS number: YYMMDD + 6 digits (once per order).
  if r_order.pos_receipt_number is null
     or btrim(r_order.pos_receipt_number) = '' then
    r_day := to_char(
      timezone('Africa/Cairo', coalesce(r_order.created_at, now())),
      'YYMMDD'
    );

    insert into public.pos_receipt_counters (receipt_day, last_seq)
    values (r_day, 0)
    on conflict (receipt_day) do nothing;

    update public.pos_receipt_counters
    set last_seq = last_seq + 1
    where receipt_day = r_day
    returning last_seq into r_seq;

    r_number := r_day || lpad(r_seq::text, 6, '0');

    update public.orders
    set pos_receipt_number = r_number
    where id = r_order.id
      and (pos_receipt_number is null or btrim(pos_receipt_number) = '')
    returning pos_receipt_number into r_number;

    if r_number is null then
      select pos_receipt_number into r_number
      from public.orders where id = r_order.id;
    end if;

    r_order.pos_receipt_number := r_number;
  end if;

  r_branch := coalesce(nullif(btrim(r_order.pos_branch_code), ''), '001');

  r_zone := nullif(btrim(coalesce(r_order.fujitsu_zone_id, '')), '');
  if r_zone is null and r_order.pos_customer_id is not null then
    select nullif(btrim(pc.fujitsu_zone_id), '')
      into r_zone
    from public.pos_customers pc
    where pc.id = r_order.pos_customer_id;
  end if;
  if r_zone is null and r_order.delivery_area is not null then
    select dz.fujitsu_zone_id::text
      into r_zone
    from public.delivery_zones dz
    where dz.name = r_order.delivery_area
       or dz.fujitsu_zone_id::text = r_order.delivery_area
    limit 1;
  end if;
  r_zone := coalesce(r_zone, '0');

  r_customer := coalesce(r_order.pos_customer_id::text, '0');

  if r_order.pos_customer_id is not null then
    select nullif(btrim(pc.phone2), '') into r_phone2
    from public.pos_customers pc
    where pc.id = r_order.pos_customer_id;
  end if;

  r_fee := trim(to_char(coalesce(r_order.delivery_fee, 0), 'FM999999990.00'));

  r_qr := format(
    'DlvOrd,%s,0,%s,0,0,%s,%s,0,%s',
    r_branch,
    r_order.pos_receipt_number,
    r_customer,
    r_zone,
    r_fee
  );

  select coalesce(
    jsonb_agg(
      jsonb_build_object(
        'id', oi.id,
        'quantity', oi.quantity,
        'unit_price', oi.price_at_time,
        'weight_in_grams', oi.weight_in_grams,
        'product_name', coalesce(p.name, 'منتج'),
        'barcode', p.barcode,
        'list_price', p.price,
        'discount_price', p.discount_price,
        'category_name', coalesce(nullif(btrim(p.category), ''), 'أصناف')
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
    'receipt_number', r_order.pos_receipt_number,
    'qr_payload', r_qr,
    'branch_code', r_branch,
    'branch_name', 'حي الزهور',
    'store_name', 'سفير ماركت',
    'created_at', r_order.created_at,
    'taker_name', r_order.taker_name,
    'preparer_name', r_order.preparer_name,
    'customer_name', r_order.customer_name,
    'customer_phone', r_order.customer_phone,
    'customer_phone2', r_phone2,
    'address', r_order.address_details,
    'delivery_area', r_order.delivery_area,
    'payment_method', r_order.payment_method,
    'delivery_fee', coalesce(r_order.delivery_fee, 0),
    'total_amount', coalesce(r_order.total_amount, 0),
    'pos_customer_id', r_order.pos_customer_id,
    'fujitsu_zone_id', r_zone,
    'items', r_items
  );
end;
$$;

revoke all on function public.get_order_prep_receipt(uuid) from public, anon;
grant execute on function public.get_order_prep_receipt(uuid) to authenticated;

notify pgrst, 'reload schema';
