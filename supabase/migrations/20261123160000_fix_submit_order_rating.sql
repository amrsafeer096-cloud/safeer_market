-- Fix / harden public.submit_order_rating for the Flutter RPC
-- (p_order_id, p_delivery_rating, p_product_rating, p_comment).
-- Also lets dashboard staff read ratings for Order Status + Reports.
-- Safe to re-run.

create table if not exists public.order_ratings (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null references public.orders (id) on delete cascade,
  user_id uuid not null references auth.users (id) on delete cascade,
  delivery_rating smallint not null
    check (delivery_rating between 1 and 5),
  product_rating smallint not null
    check (product_rating between 1 and 5),
  comment text,
  created_at timestamptz not null default now(),
  unique (order_id)
);

create index if not exists order_ratings_user_idx
  on public.order_ratings (user_id, created_at desc);

create index if not exists order_ratings_created_idx
  on public.order_ratings (created_at desc);

alter table public.order_ratings enable row level security;

revoke all on public.order_ratings from anon;
grant select, insert on public.order_ratings to authenticated;

-- Owner + admin / order-desk / linked staff (Order Status + Reports).
drop policy if exists "order_ratings_own_select" on public.order_ratings;
create policy "order_ratings_own_select" on public.order_ratings
  for select to authenticated
  using (
    user_id = (select auth.uid())
    or public.is_admin()
    or public.is_order_taker()
    or exists (
      select 1 from public.staff s
      where s.profile_id = auth.uid()
        and coalesce(s.is_active, true)
    )
  );

drop policy if exists "order_ratings_own_insert" on public.order_ratings;
create policy "order_ratings_own_insert" on public.order_ratings
  for insert to authenticated
  with check (
    user_id = (select auth.uid())
    and exists (
      select 1 from public.orders o
      where o.id = order_id
        and o.user_id = auth.uid()
        and lower(replace(coalesce(o.status, ''), '-', '_'))
          in ('delivered', 'completed')
    )
  );

create or replace function public.submit_order_rating(
  p_order_id uuid,
  p_delivery_rating integer,
  p_product_rating integer,
  p_comment text default null
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid := auth.uid();
  v_comment text := nullif(btrim(coalesce(p_comment, '')), '');
begin
  if v_user_id is null then
    raise exception 'Not signed in' using errcode = '28000';
  end if;
  if p_delivery_rating is null or p_delivery_rating < 1 or p_delivery_rating > 5
     or p_product_rating is null or p_product_rating < 1 or p_product_rating > 5
  then
    raise exception 'Ratings must be between 1 and 5' using errcode = '22023';
  end if;
  if v_comment is not null and char_length(v_comment) > 500 then
    raise exception 'Comment too long' using errcode = '22023';
  end if;
  if not exists (
    select 1 from public.orders
    where id = p_order_id
      and user_id = v_user_id
      and lower(replace(coalesce(status, ''), '-', '_'))
        in ('delivered', 'completed')
  ) then
    raise exception 'Order not found' using errcode = 'P0002';
  end if;

  insert into public.order_ratings (
    order_id, user_id, delivery_rating, product_rating, comment
  ) values (
    p_order_id, v_user_id, p_delivery_rating, p_product_rating, v_comment
  )
  on conflict (order_id) do update
    set delivery_rating = excluded.delivery_rating,
        product_rating = excluded.product_rating,
        comment = excluded.comment,
        created_at = now();
end;
$$;

revoke all on function public.submit_order_rating(uuid, integer, integer, text)
  from public;
grant execute on function public.submit_order_rating(uuid, integer, integer, text)
  to authenticated, anon;

notify pgrst, 'reload schema';
