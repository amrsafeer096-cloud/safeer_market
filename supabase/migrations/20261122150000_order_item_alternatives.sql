-- Order item alternatives («إرسال بدائل»): up to 3 suggested products per
-- line, pending until the customer (app) or taker (phone order) picks one
-- or removes the original item. Safe to re-run.

create table if not exists public.order_item_alternatives (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null references public.orders (id) on delete cascade,
  original_order_item_id uuid not null references public.order_items (id)
    on delete cascade,
  suggested_products jsonb not null default '[]'::jsonb,
  status text not null default 'pending'
    check (status in ('pending', 'selected', 'rejected', 'removed')),
  selected_product_id uuid references public.products (id) on delete set null,
  created_by_staff_id text,
  created_at timestamptz not null default now()
);

create index if not exists order_item_alternatives_order_idx
  on public.order_item_alternatives (order_id);

create index if not exists order_item_alternatives_item_idx
  on public.order_item_alternatives (original_order_item_id);

-- Only one pending alternative set per order line.
create unique index if not exists order_item_alternatives_pending_unique
  on public.order_item_alternatives (original_order_item_id)
  where status = 'pending';

alter table public.order_item_alternatives enable row level security;

drop policy if exists "order_item_alternatives_staff_all"
  on public.order_item_alternatives;
create policy "order_item_alternatives_staff_all"
  on public.order_item_alternatives
  for all to authenticated
  using (
    public.is_admin()
    or public.has_permission('manage_users')
    or exists (
      select 1 from public.profiles p
      where p.id = auth.uid()
        and p.role in ('admin', 'warehouse', 'cashier')
        and not coalesce(p.staff_disabled, false)
    )
  )
  with check (
    public.is_admin()
    or public.has_permission('manage_users')
    or exists (
      select 1 from public.profiles p
      where p.id = auth.uid()
        and p.role in ('admin', 'warehouse', 'cashier')
        and not coalesce(p.staff_disabled, false)
    )
  );

drop policy if exists "order_item_alternatives_customer_select"
  on public.order_item_alternatives;
create policy "order_item_alternatives_customer_select"
  on public.order_item_alternatives
  for select to authenticated
  using (
    exists (
      select 1 from public.orders o
      where o.id = order_item_alternatives.order_id
        and o.user_id = auth.uid()
    )
  );

drop policy if exists "order_item_alternatives_customer_update"
  on public.order_item_alternatives;
create policy "order_item_alternatives_customer_update"
  on public.order_item_alternatives
  for update to authenticated
  using (
    exists (
      select 1 from public.orders o
      where o.id = order_item_alternatives.order_id
        and o.user_id = auth.uid()
    )
  )
  with check (
    exists (
      select 1 from public.orders o
      where o.id = order_item_alternatives.order_id
        and o.user_id = auth.uid()
    )
  );

grant select, insert, update on public.order_item_alternatives to authenticated;

create or replace function public._recalc_order_total(p_order_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  items_total numeric := 0;
  fee numeric := 0;
begin
  select coalesce(sum(
    case
      when oi.weight_in_grams is not null and oi.weight_in_grams > 0
        then round(oi.price_at_time * oi.weight_in_grams / 1000.0, 2)
      else oi.price_at_time * oi.quantity
    end
  ), 0)
  into items_total
  from public.order_items oi
  where oi.order_id = p_order_id;

  select coalesce(o.delivery_fee, 0) into fee
  from public.orders o where o.id = p_order_id;

  update public.orders
  set total_amount = items_total + fee
  where id = p_order_id;
end;
$$;

-- Staff / preparer submits up to 3 alternatives for one line.
create or replace function public.suggest_order_item_alternatives(
  p_order_id uuid,
  p_order_item_id uuid,
  p_products jsonb,
  p_staff_id text default null
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  new_id uuid;
  count int;
begin
  if auth.uid() is null then
    raise exception 'not_signed_in' using errcode = '28000';
  end if;

  if not exists (
    select 1 from public.order_items oi
    where oi.id = p_order_item_id and oi.order_id = p_order_id
  ) then
    raise exception 'order_item_not_found' using errcode = '22023';
  end if;

  count := jsonb_array_length(coalesce(p_products, '[]'::jsonb));
  if count < 1 or count > 3 then
    raise exception 'alternatives_count' using errcode = '22023';
  end if;

  -- Replace any previous pending set for this line.
  update public.order_item_alternatives
  set status = 'rejected'
  where original_order_item_id = p_order_item_id
    and status = 'pending';

  insert into public.order_item_alternatives (
    order_id, original_order_item_id, suggested_products,
    status, created_by_staff_id
  )
  values (
    p_order_id,
    p_order_item_id,
    p_products,
    'pending',
    nullif(btrim(coalesce(p_staff_id, '')), '')
  )
  returning id into new_id;

  return new_id;
end;
$$;

-- Customer or taker picks one alternative product.
create or replace function public.select_order_item_alternative(
  p_alternative_id uuid,
  p_product_id uuid
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  alt public.order_item_alternatives%rowtype;
  product public.products%rowtype;
  item public.order_items%rowtype;
  allowed boolean := false;
begin
  select * into alt from public.order_item_alternatives
  where id = p_alternative_id for update;
  if not found or alt.status <> 'pending' then
    raise exception 'alternative_not_pending' using errcode = '22023';
  end if;

  select exists (
    select 1 from public.orders o
    where o.id = alt.order_id
      and (
        o.user_id = auth.uid()
        or public.is_admin()
        or exists (
          select 1 from public.profiles p
          where p.id = auth.uid()
            and p.role in ('admin', 'warehouse', 'cashier')
            and not coalesce(p.staff_disabled, false)
        )
      )
  ) into allowed;
  if not allowed then
    raise exception 'forbidden' using errcode = '42501';
  end if;

  if not exists (
    select 1
    from jsonb_array_elements(alt.suggested_products) e
    where (e ->> 'product_id')::uuid = p_product_id
       or (e ->> 'id')::uuid = p_product_id
  ) then
    raise exception 'product_not_in_suggestions' using errcode = '22023';
  end if;

  select * into product from public.products where id = p_product_id;
  if not found then
    raise exception 'product_not_found' using errcode = '22023';
  end if;

  select * into item from public.order_items
  where id = alt.original_order_item_id for update;
  if not found then
    raise exception 'order_item_not_found' using errcode = '22023';
  end if;

  update public.order_items
  set product_id = product.id,
      price_at_time = product.price,
      weight_in_grams = case
        when coalesce(product.is_weight_based, false)
          then coalesce(nullif(weight_in_grams, 0), 250)
        else null
      end,
      quantity = case
        when coalesce(product.is_weight_based, false) then 1
        else greatest(quantity, 1)
      end
  where id = item.id;

  update public.order_item_alternatives
  set status = 'selected',
      selected_product_id = product.id
  where id = alt.id;

  perform public._recalc_order_total(alt.order_id);
end;
$$;

-- Customer or taker removes the unavailable original item.
create or replace function public.remove_order_item_with_alternative(
  p_alternative_id uuid
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  alt public.order_item_alternatives%rowtype;
  allowed boolean := false;
begin
  select * into alt from public.order_item_alternatives
  where id = p_alternative_id for update;
  if not found or alt.status <> 'pending' then
    raise exception 'alternative_not_pending' using errcode = '22023';
  end if;

  select exists (
    select 1 from public.orders o
    where o.id = alt.order_id
      and (
        o.user_id = auth.uid()
        or public.is_admin()
        or exists (
          select 1 from public.profiles p
          where p.id = auth.uid()
            and p.role in ('admin', 'warehouse', 'cashier')
            and not coalesce(p.staff_disabled, false)
        )
      )
  ) into allowed;
  if not allowed then
    raise exception 'forbidden' using errcode = '42501';
  end if;

  delete from public.order_items where id = alt.original_order_item_id;

  update public.order_item_alternatives
  set status = 'removed'
  where id = alt.id;

  perform public._recalc_order_total(alt.order_id);
end;
$$;

revoke all on function public.suggest_order_item_alternatives(uuid, uuid, jsonb, text)
  from public, anon;
revoke all on function public.select_order_item_alternative(uuid, uuid)
  from public, anon;
revoke all on function public.remove_order_item_with_alternative(uuid)
  from public, anon;
revoke all on function public._recalc_order_total(uuid)
  from public, anon, authenticated;

grant execute on function public.suggest_order_item_alternatives(uuid, uuid, jsonb, text)
  to authenticated;
grant execute on function public.select_order_item_alternative(uuid, uuid)
  to authenticated;
grant execute on function public.remove_order_item_with_alternative(uuid)
  to authenticated;

notify pgrst, 'reload schema';
