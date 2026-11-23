-- POS prep-receipt number + QR payload for cashier scan (DlvOrd,…).
-- Allocates YYMMDD###### once per order. Safe to re-run.

alter table public.orders
  add column if not exists pos_receipt_number text,
  add column if not exists fujitsu_zone_id text,
  add column if not exists pos_branch_code text;

create unique index if not exists orders_pos_receipt_number_uidx
  on public.orders (pos_receipt_number)
  where pos_receipt_number is not null;

create table if not exists public.pos_receipt_counters (
  day_key text primary key,
  last_seq integer not null default 0
);

alter table public.pos_receipt_counters enable row level security;

-- Staff / Edge allocate via SECURITY DEFINER only.
revoke all on public.pos_receipt_counters from public, anon, authenticated;

/**
 * Ensures the order has a POS receipt number and returns everything the
 * Flutter prep-receipt printer needs (QR payload + display fields).
 */
create or replace function public.get_order_prep_receipt(p_order_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  o public.orders%rowtype;
  v_day_key text;
  v_next_seq integer;
  v_receipt text;
  v_zone_code text;
  v_customer_code text;
  v_branch text;
  v_fee text;
  v_phone2 text;
  v_qr text;
  v_items jsonb;
begin
  if auth.uid() is null then
    raise exception 'Not signed in' using errcode = '28000';
  end if;

  select * into o from public.orders where id = p_order_id;
  if not found then
    raise exception 'Order not found' using errcode = 'P0002';
  end if;

  -- Allocate receipt number once: YYMMDD + 6-digit daily sequence.
  if o.pos_receipt_number is null or btrim(o.pos_receipt_number) = '' then
    v_day_key := to_char(
      timezone('Africa/Cairo', coalesce(o.created_at, now())),
      'YYMMDD'
    );
    insert into public.pos_receipt_counters (day_key, last_seq)
    values (v_day_key, 1)
    on conflict (day_key) do update
      set last_seq = pos_receipt_counters.last_seq + 1
    returning pos_receipt_counters.last_seq into v_next_seq;

    v_receipt := v_day_key || lpad(v_next_seq::text, 6, '0');
    update public.orders
    set pos_receipt_number = v_receipt
    where id = o.id
      and (pos_receipt_number is null or btrim(pos_receipt_number) = '')
    returning pos_receipt_number into v_receipt;

    -- Race: another session won — re-read.
    if v_receipt is null then
      select pos_receipt_number into v_receipt
      from public.orders where id = o.id;
    end if;
    o.pos_receipt_number := v_receipt;
  end if;

  v_branch := coalesce(nullif(btrim(o.pos_branch_code), ''), '001');

  -- Zone: order column → pos_customers → match delivery_area name.
  v_zone_code := nullif(btrim(coalesce(o.fujitsu_zone_id, '')), '');
  if v_zone_code is null and o.pos_customer_id is not null then
    select nullif(btrim(c.fujitsu_zone_id), '')
      into v_zone_code
    from public.pos_customers c
    where c.id = o.pos_customer_id;
  end if;
  if v_zone_code is null and o.delivery_area is not null then
    select z.fujitsu_zone_id::text
      into v_zone_code
    from public.delivery_zones z
    where z.name = o.delivery_area
       or z.fujitsu_zone_id::text = o.delivery_area
    limit 1;
  end if;
  v_zone_code := coalesce(v_zone_code, '0');

  v_customer_code := coalesce(o.pos_customer_id::text, '0');

  if o.pos_customer_id is not null then
    select nullif(btrim(c.phone2), '') into v_phone2
    from public.pos_customers c where c.id = o.pos_customer_id;
  end if;

  v_fee := trim(to_char(coalesce(o.delivery_fee, 0), 'FM999999990.00'));

  -- Exact cashier QR shape:
  -- DlvOrd,{branch},0,{receipt},0,0,{customerId},{zone},0,{fee}
  v_qr := format(
    'DlvOrd,%s,0,%s,0,0,%s,%s,0,%s',
    v_branch,
    o.pos_receipt_number,
    v_customer_code,
    v_zone_code,
    v_fee
  );

  select coalesce(jsonb_agg(row_to_json(x)::jsonb order by x.sort_name), '[]'::jsonb)
    into v_items
  from (
    select
      oi.id,
      oi.quantity,
      oi.price_at_time as unit_price,
      oi.weight_in_grams,
      p.name as product_name,
      p.barcode,
      p.price as list_price,
      p.discount_price,
      coalesce(nullif(btrim(p.category), ''), 'أصناف') as category_name,
      p.name as sort_name
    from public.order_items oi
    left join public.products p on p.id = oi.product_id
    where oi.order_id = o.id
  ) x;

  return jsonb_build_object(
    'order_id', o.id,
    'receipt_number', o.pos_receipt_number,
    'qr_payload', v_qr,
    'branch_code', v_branch,
    'branch_name', 'حي الزهور',
    'store_name', 'سفير ماركت',
    'created_at', o.created_at,
    'taker_name', o.taker_name,
    'preparer_name', o.preparer_name,
    'customer_name', o.customer_name,
    'customer_phone', o.customer_phone,
    'customer_phone2', v_phone2,
    'address', o.address_details,
    'delivery_area', o.delivery_area,
    'payment_method', o.payment_method,
    'delivery_fee', coalesce(o.delivery_fee, 0),
    'total_amount', coalesce(o.total_amount, 0),
    'pos_customer_id', o.pos_customer_id,
    'fujitsu_zone_id', v_zone_code,
    'items', v_items
  );
end;
$$;

revoke all on function public.get_order_prep_receipt(uuid) from public, anon;
grant execute on function public.get_order_prep_receipt(uuid) to authenticated;

notify pgrst, 'reload schema';
