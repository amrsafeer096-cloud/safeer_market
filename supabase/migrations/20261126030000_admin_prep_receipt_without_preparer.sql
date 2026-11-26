-- Allow admins to load/print the prep receipt before a preparer is assigned.
-- Preparers / takers still require preparer_name. Safe to re-run.

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
  r_order_source int := 0;
  r_commit_prices int := 0;
  r_pilot_no int := 0;
begin
  if auth.uid() is null then
    raise exception 'Not signed in' using errcode = '28000';
  end if;

  select * into r_order from public.orders where id = p_order_id;
  if not found then
    raise exception 'Order not found' using errcode = 'P0002';
  end if;

  -- Non-admins must pick a preparer first; admins may print immediately.
  if (r_order.preparer_name is null or btrim(r_order.preparer_name) = '')
     and not public.is_admin() then
    raise exception 'اختر المحضر أولاً قبل طباعة الإيصال'
      using errcode = 'P0001';
  end if;

  -- Trusty OrderSource: 0 = call center / phone, 1 = online / app.
  r_order_source := case
    when lower(btrim(coalesce(r_order.order_source, ''))) in ('app', 'online', '1')
      then 1
    else 0
  end;

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
      'DlvOrd,001,01,%s,%s,%s,%s,%s,%s,%s',
      r_order_no,
      r_order_source,
      r_commit_prices,
      r_customer_no,
      r_address_id,
      r_pilot_no,
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

  select coalesce(jsonb_agg(to_jsonb(x) order by x.product_name), '[]'::jsonb)
  into r_items
  from (
    select
      oi.id,
      coalesce(p.name, 'منتج') as product_name,
      p.barcode,
      coalesce(nullif(btrim(p.category), ''), 'أصناف') as category_name,
      p.price as list_price,
      p.discount_price,
      (
        oi.weight_in_grams is not null
        and oi.weight_in_grams > 0
      ) as is_weight_based,
      oi.weight_in_grams,
      case
        when oi.weight_in_grams is not null and oi.weight_in_grams > 0
          then 1
        else oi.quantity
      end as quantity,
      case
        when oi.weight_in_grams is not null and oi.weight_in_grams > 0
          then round(
            oi.price_at_time * 1000.0 / nullif(oi.weight_in_grams, 0),
            4
          )
        else oi.price_at_time
      end as unit_price,
      case
        when oi.weight_in_grams is not null and oi.weight_in_grams > 0
          then oi.price_at_time
        else oi.price_at_time * oi.quantity
      end as line_total
    from public.order_items oi
    left join public.products p on p.id = oi.product_id
    where oi.order_id = r_order.id
  ) x;

  return jsonb_build_object(
    'order_id', r_order.id,
    'receipt_number', coalesce(nullif(r_order_no, ''), r_order.pos_receipt_number),
    'qr_payload', r_qr,
    'waiting_fujitsu', r_waiting,
    'fujitsu_order_id', r_order.fujitsu_order_id,
    'fujitsu_customer_no', r_order.fujitsu_customer_no,
    'fujitsu_address_id', r_order.fujitsu_address_id,
    'fujitsu_sync_error', r_order.fujitsu_sync_error,
    'order_source', r_order.order_source,
    'order_source_code', r_order_source,
    'commit_prices', r_commit_prices,
    'pilot_no', r_pilot_no,
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
