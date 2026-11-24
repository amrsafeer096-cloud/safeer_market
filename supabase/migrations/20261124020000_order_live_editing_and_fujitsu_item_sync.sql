-- Live order editing during preparation + Fujitsu item re-sync flags.
-- Safe to re-run. Run in Supabase SQL Editor.

alter table public.orders
  add column if not exists is_being_edited boolean not null default false,
  add column if not exists editing_started_by text,
  add column if not exists items_updated_at timestamptz,
  add column if not exists fujitsu_items_synced_at timestamptz;

comment on column public.orders.is_being_edited is
  'True while customer/taker has the live edit sheet open.';
comment on column public.orders.editing_started_by is
  'Who opened the edit sheet: customer | taker | admin.';
comment on column public.orders.items_updated_at is
  'When order_items were last confirmed via live edit.';
comment on column public.orders.fujitsu_items_synced_at is
  'When hd_order_items was last rebuilt from Supabase items.';

create index if not exists orders_fujitsu_items_resync_idx
  on public.orders (items_updated_at)
  where fujitsu_order_id is not null
    and items_updated_at is not null
    and coalesce(is_being_edited, false) = false;

-- Editable while still in prep pipeline (before ready / delivery / cancel).
create or replace function public.order_status_allows_live_edit(p_status text)
returns boolean
language sql
immutable
as $$
  select lower(trim(coalesce(p_status, ''))) in (
    'pending', 'new', 'confirmed', 'preparing', 'processing'
  );
$$;

create or replace function public.order_allows_live_edit(p_order public.orders)
returns boolean
language sql
stable
as $$
  select public.order_status_allows_live_edit(p_order.status)
     and p_order.prep_completed_at is null
     and lower(trim(coalesce(p_order.status, ''))) not in (
       'ready_for_delivery', 'out_for_delivery', 'delivered',
       'completed', 'cancelled', 'canceled'
     );
$$;

-- Owner or staff (admin / order taker).
create or replace function public.can_live_edit_order(p_order_id uuid)
returns boolean
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  r public.orders%rowtype;
begin
  if auth.uid() is null then
    return false;
  end if;
  select * into r from public.orders where id = p_order_id;
  if not found then
    return false;
  end if;
  if not public.order_allows_live_edit(r) then
    return false;
  end if;
  if r.user_id = auth.uid() then
    return true;
  end if;
  return public.is_admin() or public.is_order_taker();
end;
$$;

revoke all on function public.can_live_edit_order(uuid) from public, anon;
grant execute on function public.can_live_edit_order(uuid) to authenticated;

-- RLS: customer/staff may flip editing flags + items_updated_at while editable.
drop policy if exists "orders_live_edit_flags" on public.orders;
create policy "orders_live_edit_flags"
  on public.orders
  for update
  to authenticated
  using (
    public.order_allows_live_edit(orders)
    and (
      user_id = auth.uid()
      or public.is_admin()
      or public.is_order_taker()
    )
  )
  with check (
    public.order_status_allows_live_edit(status)
    and (
      user_id = auth.uid()
      or public.is_admin()
      or public.is_order_taker()
    )
  );

-- order_items: allow mutate while parent order is editable by caller.
drop policy if exists "order_items_live_edit_insert" on public.order_items;
create policy "order_items_live_edit_insert"
  on public.order_items
  for insert
  to authenticated
  with check (public.can_live_edit_order(order_id));

drop policy if exists "order_items_live_edit_update" on public.order_items;
create policy "order_items_live_edit_update"
  on public.order_items
  for update
  to authenticated
  using (public.can_live_edit_order(order_id))
  with check (public.can_live_edit_order(order_id));

drop policy if exists "order_items_live_edit_delete" on public.order_items;
create policy "order_items_live_edit_delete"
  on public.order_items
  for delete
  to authenticated
  using (public.can_live_edit_order(order_id));

-- Begin edit lock.
create or replace function public.begin_order_edit(
  p_order_id uuid,
  p_started_by text default 'customer'
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  r public.orders%rowtype;
  who text := lower(trim(coalesce(p_started_by, 'customer')));
begin
  if auth.uid() is null then
    raise exception 'Not signed in' using errcode = '28000';
  end if;
  if who not in ('customer', 'taker', 'admin') then
    who := 'customer';
  end if;

  select * into r from public.orders where id = p_order_id for update;
  if not found then
    raise exception 'Order not found' using errcode = 'P0002';
  end if;
  if not public.can_live_edit_order(p_order_id) then
    raise exception 'لا يمكن تعديل هذا الطلب الآن' using errcode = 'P0001';
  end if;

  update public.orders
  set is_being_edited = true,
      editing_started_by = who
  where id = p_order_id;

  return jsonb_build_object(
    'order_id', p_order_id,
    'is_being_edited', true,
    'editing_started_by', who
  );
end;
$$;

-- Cancel / discard edit lock.
create or replace function public.cancel_order_edit(p_order_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if auth.uid() is null then
    raise exception 'Not signed in' using errcode = '28000';
  end if;
  if not (
    exists (
      select 1 from public.orders o
      where o.id = p_order_id
        and (
          o.user_id = auth.uid()
          or public.is_admin()
          or public.is_order_taker()
        )
    )
  ) then
    raise exception 'Not allowed' using errcode = '42501';
  end if;

  update public.orders
  set is_being_edited = false,
      editing_started_by = null
  where id = p_order_id;
end;
$$;

-- Apply confirmed item list; recalculate total; clear lock; stamp items_updated_at.
-- p_items: [{ "product_id": uuid, "quantity": int, "price_at_time": number,
--             "weight_in_grams": int|null }]
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

    insert into public.order_items (
      order_id, product_id, quantity, price_at_time, weight_in_grams
    ) values (p_order_id, pid, qty, price, grams);

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

revoke all on function public.begin_order_edit(uuid, text) from public, anon;
revoke all on function public.cancel_order_edit(uuid) from public, anon;
revoke all on function public.apply_order_edit(uuid, jsonb) from public, anon;
grant execute on function public.begin_order_edit(uuid, text) to authenticated;
grant execute on function public.cancel_order_edit(uuid) to authenticated;
grant execute on function public.apply_order_edit(uuid, jsonb) to authenticated;

notify pgrst, 'reload schema';
