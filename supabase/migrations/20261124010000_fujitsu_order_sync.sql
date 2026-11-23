-- Fujitsu POS delivery order sync columns on public.orders.
-- Used by sync_orders_to_fujitsu.py + prep-receipt QR.
-- Safe to re-run.

alter table public.orders
  add column if not exists fujitsu_order_id text,
  add column if not exists fujitsu_customer_no bigint,
  add column if not exists fujitsu_address_id bigint,
  add column if not exists fujitsu_synced_at timestamptz,
  add column if not exists fujitsu_sync_error text;

create index if not exists orders_fujitsu_pending_idx
  on public.orders (preparer_name, fujitsu_order_id)
  where fujitsu_order_id is null
    and preparer_name is not null
    and btrim(preparer_name) <> '';

create unique index if not exists orders_fujitsu_order_id_uidx
  on public.orders (fujitsu_order_id)
  where fujitsu_order_id is not null;

-- Prep receipt QR prefers real Fujitsu ids when the bridge has synced.
create or replace function public.get_order_prep_receipt(p_order_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  r_order public.orders%rowtype;
  r_zone text;
  r_phone2 text;
  r_qr text;
  r_items jsonb;
  r_fee text;
  r_order_no text;
  r_customer_no text;
  r_address_id text;
  r_waiting boolean := false;
begin
  if auth.uid() is null then
    raise exception 'Not signed in' using errcode = '28000';
  end if;

  select * into r_order from public.orders where id = p_order_id;
  if not found then
    raise exception 'Order not found' using errcode = 'P0002';
  end if;

  if r_order.preparer_name is null or btrim(r_order.preparer_name) = '' then
    raise exception 'اختر المحضر أولاً قبل طباعة الإيصال'
      using errcode = 'P0001';
  end if;

  -- Prefer Fujitsu ids written by the local Python bridge.
  -- Until then Flutter shows «جاري تسجيل الطلب على الكاشير...» and polls.
  if r_order.fujitsu_order_id is null or btrim(r_order.fujitsu_order_id) = '' then
    r_waiting := true;
    r_order_no := '';
    r_customer_no := coalesce(r_order.fujitsu_customer_no::text, '0');
    r_address_id := coalesce(r_order.fujitsu_address_id::text, '0');
    r_qr := null;
  else
    r_order_no := btrim(r_order.fujitsu_order_id);
    r_customer_no := coalesce(r_order.fujitsu_customer_no::text, '0');
    r_address_id := coalesce(r_order.fujitsu_address_id::text, '0');
    r_fee := trim(to_char(coalesce(r_order.delivery_fee, 0), 'FM999999990.00'));
    r_qr := format(
      'DlvOrd,001,0,%s,0,0,%s,%s,0,%s',
      r_order_no,
      r_customer_no,
      r_address_id,
      r_fee
    );
  end if;

  if r_fee is null then
    r_fee := trim(to_char(coalesce(r_order.delivery_fee, 0), 'FM999999990.00'));
  end if;

  if r_order.pos_customer_id is not null then
    select nullif(btrim(pc.phone2), '') into r_phone2
    from public.pos_customers pc
    where pc.id = r_order.pos_customer_id;
  end if;

  r_zone := nullif(btrim(coalesce(r_order.fujitsu_zone_id, '')), '');

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
    'receipt_number', coalesce(nullif(r_order_no, ''), r_order.pos_receipt_number),
    'qr_payload', r_qr,
    'waiting_fujitsu', r_waiting,
    'fujitsu_order_id', r_order.fujitsu_order_id,
    'fujitsu_customer_no', r_order.fujitsu_customer_no,
    'fujitsu_address_id', r_order.fujitsu_address_id,
    'fujitsu_sync_error', r_order.fujitsu_sync_error,
    'branch_code', '001',
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
