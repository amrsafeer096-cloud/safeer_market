-- Per-item notes (ملاحظات الصنف) on order_items + RPC / receipt support.
-- Safe to re-run.

alter table public.order_items
  add column if not exists notes text;

comment on column public.order_items.notes is
  'Optional per-line customer/taker note (ملاحظات الصنف).';


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
  p_fujitsu_address_id bigint default null,
  p_is_supplemental boolean default false,
  p_admin_note text default null
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
  item_notes text;
  unit_price numeric;
  line_price numeric;
  items_total numeric := 0;
  taker text;
  method text := lower(btrim(coalesce(p_payment_method, 'cash')));
  receipt text := nullif(btrim(coalesce(p_receipt_url, '')), '');
  pay_status text;
  note text := nullif(btrim(coalesce(p_admin_note, '')), '');
  supplemental boolean := coalesce(p_is_supplemental, false);
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

  if supplemental and note is null then
    note := 'طلب ملحق';
  end if;

  select full_name into taker from public.profiles where id = auth.uid();

  insert into public.orders (
    user_id, pos_customer_id, customer_name, customer_phone,
    address_details, delivery_area, delivery_fee, total_amount,
    status, payment_method, payment_status, receipt_url,
    order_source, taker_name, fujitsu_address_id,
    is_supplemental, admin_note
  ) values (
    p_user_id, p_pos_customer_id,
    nullif(btrim(coalesce(p_customer_name, '')), ''),
    nullif(btrim(coalesce(p_customer_phone, '')), ''),
    nullif(btrim(coalesce(p_address, '')), ''),
    nullif(btrim(coalesce(p_area, '')), ''),
    p_delivery_fee, 0,
    'pending', method, pay_status,
    case when method = 'instapay' then receipt end,
    'phone', taker, p_fujitsu_address_id,
    supplemental, note
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

    item_notes := nullif(btrim(coalesce(item ->> 'notes', '')), '');

    insert into public.order_items (
      order_id, product_id, quantity, price_at_time, weight_in_grams, notes
    ) values (
      new_order_id, product.id, qty, line_price, grams, item_notes
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

create or replace function public.apply_order_edit(
  p_order_id uuid,
  p_items jsonb
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  r public.orders%rowtype;
  item jsonb;
  pid uuid;
  qty int;
  price numeric;
  grams int;
  item_notes text;
  items_total numeric := 0;
  fee numeric := 0;
  line_count int := 0;
begin
  if auth.uid() is null then
    raise exception 'Not signed in' using errcode = '28000';
  end if;

  select * into r from public.orders where id = p_order_id for update;
  if not found then
    raise exception 'Order not found' using errcode = 'P0002';
  end if;
  if not public.can_live_edit_order(p_order_id) then
    raise exception 'لا يمكن تعديل هذا الطلب الآن' using errcode = 'P0001';
  end if;

  if p_items is null or jsonb_typeof(p_items) <> 'array' or jsonb_array_length(p_items) < 1 then
    raise exception 'يجب أن يحتوي الطلب على صنف واحد على الأقل'
      using errcode = 'P0001';
  end if;

  delete from public.order_items where order_id = p_order_id;

  for item in select * from jsonb_array_elements(p_items)
  loop
    pid := nullif(item ->> 'product_id', '')::uuid;
    if pid is null then
      raise exception 'product_id مطلوب' using errcode = 'P0001';
    end if;
    qty := greatest(1, coalesce((item ->> 'quantity')::int, 1));
    price := coalesce((item ->> 'price_at_time')::numeric, 0);
    grams := null;
    if item ? 'weight_in_grams'
       and nullif(item ->> 'weight_in_grams', '') is not null then
      grams := (item ->> 'weight_in_grams')::int;
    end if;

    item_notes := nullif(btrim(coalesce(item ->> 'notes', '')), '');

    insert into public.order_items (
      order_id, product_id, quantity, price_at_time, weight_in_grams, notes
    ) values (p_order_id, pid, qty, price, grams, item_notes);

    if grams is not null and grams > 0 then
      items_total := items_total + round(price * grams / 1000.0, 2);
    else
      items_total := items_total + (price * qty);
    end if;
    line_count := line_count + 1;
  end loop;

  fee := coalesce(r.delivery_fee, 0);

  update public.orders
  set total_amount = items_total + fee,
      is_being_edited = false,
      editing_started_by = null,
      items_updated_at = timezone('utc', now())
  where id = p_order_id;

  return jsonb_build_object(
    'order_id', p_order_id,
    'item_count', line_count,
    'items_total', items_total,
    'delivery_fee', fee,
    'total_amount', items_total + fee,
    'items_updated_at', timezone('utc', now())
  );
end;
$$;

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
      end as line_total,
      nullif(btrim(coalesce(oi.notes, '')), '') as notes
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

notify pgrst, 'reload schema';
