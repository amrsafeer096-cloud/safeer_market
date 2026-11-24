-- Same-day «طلب ملحق» support + has-order-today check for «تلقي الطلبات».
--
-- * orders.is_supplemental / orders.admin_note
-- * place_phone_order accepts p_is_supplemental + p_admin_note
-- * customer_has_order_today(pos_id, user_id, phone) for the taker dialog

alter table public.orders
  add column if not exists is_supplemental boolean not null default false,
  add column if not exists admin_note text;

comment on column public.orders.is_supplemental is
  'Phone-order «طلب ملحق»: free delivery follow-up on a same-day order.';
comment on column public.orders.admin_note is
  'Staff note on the order (e.g. طلب ملحق).';

-- ---------------------------------------------------------------------------
-- Same-day order check (Cairo calendar day)
-- ---------------------------------------------------------------------------
create or replace function public.customer_has_order_today(
  p_pos_customer_id bigint default null,
  p_user_id uuid default null,
  p_phone text default null
)
returns boolean
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  digits text := nullif(public.normalize_egyptian_phone(p_phone), '');
  day_start timestamptz;
  day_end timestamptz;
  found boolean := false;
begin
  if not public.is_order_taker() then
    raise exception 'not_allowed' using errcode = '42501';
  end if;
  if p_pos_customer_id is null and p_user_id is null and digits is null then
    return false;
  end if;

  day_start := date_trunc(
    'day',
    timezone('Africa/Cairo', now())
  ) at time zone 'Africa/Cairo';
  day_end := day_start + interval '1 day';

  select exists (
    select 1
    from public.orders o
    where o.created_at >= day_start
      and o.created_at < day_end
      and lower(btrim(coalesce(o.status, ''))) not in ('cancelled', 'canceled')
      and (
        (p_pos_customer_id is not null and o.pos_customer_id = p_pos_customer_id)
        or (p_user_id is not null and o.user_id = p_user_id)
        or (
          digits is not null
          and public.normalize_egyptian_phone(o.customer_phone) = digits
        )
      )
  ) into found;

  return coalesce(found, false);
end;
$$;

revoke execute on function public.customer_has_order_today(bigint, uuid, text)
  from public, anon;
grant execute on function public.customer_has_order_today(bigint, uuid, text)
  to authenticated;

-- ---------------------------------------------------------------------------
-- place_phone_order — supplemental flag + admin note
-- ---------------------------------------------------------------------------
drop function if exists public.place_phone_order(
  uuid, bigint, text, text, text, text, jsonb, numeric, text, text, text, bigint);

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

    insert into public.order_items (
      order_id, product_id, quantity, price_at_time, weight_in_grams
    ) values (
      new_order_id, product.id, qty, line_price, grams
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

revoke execute on function public.place_phone_order(
  uuid, bigint, text, text, text, text, jsonb, numeric, text, text, text, bigint,
  boolean, text) from public, anon;
grant execute on function public.place_phone_order(
  uuid, bigint, text, text, text, text, jsonb, numeric, text, text, text, bigint,
  boolean, text) to authenticated;

notify pgrst, 'reload schema';
