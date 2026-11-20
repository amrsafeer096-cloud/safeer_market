-- «تلقي الطلبات»: payment method of a phone order.
--
-- * cash             كاش عند الاستلام (default)
-- * visa_on_delivery فيزا عند الاستلام: only flags the order so the driver
--                    brings the POS machine (no online gateway)
-- * instapay         إنستا باي: the transfer screenshot is uploaded to the
--                    public `payment_receipts` bucket by the dashboard and
--                    its URL is saved on orders.receipt_url; the order is
--                    saved with payment_status = 'paid'.
--
-- place_phone_order gets three optional arguments (payment method, status,
-- receipt URL). Safe to re-run.

-- 1. Columns / constraints on orders.
alter table public.orders
  add column if not exists payment_method text,
  add column if not exists payment_status text not null default 'unpaid',
  add column if not exists receipt_url text;

-- Older databases may restrict payment_method to the app's own values.
alter table public.orders
  drop constraint if exists orders_payment_method_check;

alter table public.orders
  drop constraint if exists orders_payment_status_check;
alter table public.orders
  add constraint orders_payment_status_check
  check (
    payment_status in (
      'unpaid', 'pending', 'pending_verification', 'paid', 'failed'
    )
  );

comment on column public.orders.receipt_url is
  'Public URL of the InstaPay transfer screenshot (customer app or dashboard).';

-- 2. The receipts bucket (same as 20261117020000_instapay_receipt_uploads).
--    The dashboard uploads under the signed-in staff member's own folder.
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'payment_receipts',
  'payment_receipts',
  true,
  10485760,
  array['image/jpeg', 'image/png', 'image/webp', 'image/gif', 'image/heic']
)
on conflict (id) do update set
  public = excluded.public,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

drop policy if exists "payment_receipts_public_read" on storage.objects;
create policy "payment_receipts_public_read" on storage.objects
  for select to public
  using (bucket_id = 'payment_receipts');

drop policy if exists "payment_receipts_auth_upload" on storage.objects;
create policy "payment_receipts_auth_upload" on storage.objects
  for insert to authenticated
  with check (
    bucket_id = 'payment_receipts'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

drop policy if exists "payment_receipts_auth_update" on storage.objects;
create policy "payment_receipts_auth_update" on storage.objects
  for update to authenticated
  using (
    bucket_id = 'payment_receipts'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

drop policy if exists "payment_receipts_auth_delete" on storage.objects;
create policy "payment_receipts_auth_delete" on storage.objects
  for delete to authenticated
  using (
    bucket_id = 'payment_receipts'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

-- 3. place_phone_order with the payment arguments (the old 8-argument
--    version is dropped so PostgREST never sees two overloads).
drop function if exists public.place_phone_order(
  uuid, bigint, text, text, text, text, jsonb, numeric);

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
  p_receipt_url text default null
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
  -- An InstaPay order is paid by transfer: the receipt is required.
  if method = 'instapay' and receipt is null then
    raise exception 'receipt_required' using errcode = '22023';
  end if;
  pay_status := case when method = 'instapay' then 'paid' else 'unpaid' end;

  select full_name into taker from public.profiles where id = auth.uid();

  insert into public.orders (
    user_id, pos_customer_id, customer_name, customer_phone,
    address_details, delivery_area, delivery_fee, total_amount,
    status, payment_method, payment_status, receipt_url,
    order_source, taker_name
  ) values (
    p_user_id, p_pos_customer_id,
    nullif(btrim(coalesce(p_customer_name, '')), ''),
    nullif(btrim(coalesce(p_customer_phone, '')), ''),
    nullif(btrim(coalesce(p_address, '')), ''),
    nullif(btrim(coalesce(p_area, '')), ''),
    p_delivery_fee, 0,
    'pending', method, pay_status,
    case when method = 'instapay' then receipt end,
    'phone', taker
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

    -- price_at_time is the line's unit price: for weighed items the price
    -- of the chosen weight (quantity stays 1).
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
  uuid, bigint, text, text, text, text, jsonb, numeric, text, text, text)
  from public, anon;
grant execute on function public.place_phone_order(
  uuid, bigint, text, text, text, text, jsonb, numeric, text, text, text)
  to authenticated;

notify pgrst, 'reload schema';
