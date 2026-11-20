-- Loyalty points redemption at the store's till.
--
-- The customer shows a QR code ({"user_id": ...}); a cashier (profiles.role
-- 'cashier' or 'admin') scans it, the app shows a SAFEER-NNN barcode for
-- the POS, and the cashier confirms. Every 50 points = 1 EGP.
--
-- The cashier never writes another user's profile directly: both steps go
-- through the security-definer functions below, which check the caller's
-- role and deduct atomically, so a redemption can't run twice or by anyone
-- else.

create table if not exists public.loyalty_redemptions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles (id) on delete cascade,
  cashier_id uuid references public.profiles (id) on delete set null,
  points_redeemed integer not null check (points_redeemed > 0),
  discount_amount numeric(10, 2) not null check (discount_amount > 0),
  created_at timestamptz not null default now()
);

create index if not exists loyalty_redemptions_user_created_idx
  on public.loyalty_redemptions (user_id, created_at desc);

alter table public.loyalty_redemptions enable row level security;

-- Customers see their own redemptions (and get them over Realtime);
-- cashiers the ones they made; admins all.
drop policy if exists "loyalty_redemptions_select" on public.loyalty_redemptions;
create policy "loyalty_redemptions_select" on public.loyalty_redemptions
  for select to authenticated
  using (
    user_id = (select auth.uid())
    or cashier_id = (select auth.uid())
    or public.is_admin()
  );

revoke insert, update, delete on public.loyalty_redemptions
  from anon, authenticated;

-- The customer's dialog closes when its redemption is inserted.
do $$
begin
  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'loyalty_redemptions'
  ) then
    alter publication supabase_realtime add table public.loyalty_redemptions;
  end if;
end;
$$;

create or replace function public.is_cashier()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1 from public.profiles
    where id = auth.uid() and role in ('cashier', 'admin')
  );
$$;

-- What the cashier sees after scanning: the customer's name and live
-- balance (null loyalty_points counts as 0).
create or replace function public.loyalty_customer(p_user_id uuid)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  customer public.profiles;
begin
  if not public.is_cashier() then
    raise exception 'not_allowed' using errcode = '42501';
  end if;
  select * into customer from public.profiles where id = p_user_id;
  if not found then
    raise exception 'customer_not_found' using errcode = 'P0002';
  end if;
  return jsonb_build_object(
    'user_id', customer.id,
    'full_name', customer.full_name,
    'phone', customer.phone,
    'loyalty_points', coalesce(customer.loyalty_points, 0)
  );
end;
$$;

-- Deducts p_discount_egp * 50 points from the customer and records the
-- redemption, in one transaction. Fails if the balance has dropped below
-- that since the scan. Points earned since the scan are kept.
create or replace function public.redeem_loyalty_points(
  p_user_id uuid,
  p_discount_egp integer
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  points integer;
  to_deduct integer;
  redemption_id uuid;
begin
  if not public.is_cashier() then
    raise exception 'not_allowed' using errcode = '42501';
  end if;
  if p_discount_egp is null or p_discount_egp < 1 then
    raise exception 'invalid_discount' using errcode = '22023';
  end if;

  select coalesce(loyalty_points, 0) into points
  from public.profiles
  where id = p_user_id
  for update;
  if not found then
    raise exception 'customer_not_found' using errcode = 'P0002';
  end if;

  to_deduct := p_discount_egp * 50;
  if points < to_deduct then
    raise exception 'insufficient_points' using errcode = 'P0001';
  end if;

  update public.profiles
  set loyalty_points = points - to_deduct
  where id = p_user_id;

  insert into public.loyalty_redemptions
    (user_id, cashier_id, points_redeemed, discount_amount)
  values (p_user_id, auth.uid(), to_deduct, p_discount_egp)
  returning id into redemption_id;

  return jsonb_build_object(
    'redemption_id', redemption_id,
    'points_redeemed', to_deduct,
    'discount_amount', p_discount_egp,
    'remaining_points', points - to_deduct
  );
end;
$$;

revoke execute on function public.loyalty_customer(uuid) from public, anon;
grant execute on function public.loyalty_customer(uuid) to authenticated;
revoke execute on function public.redeem_loyalty_points(uuid, integer)
  from public, anon;
grant execute on function public.redeem_loyalty_points(uuid, integer)
  to authenticated;
