-- InstaPay subscription upgrades: pending verification + receipt URL on
-- profiles, customer submit RPC, admin list/approve RPCs. Admins may change
-- subscription_plan / subscription_expiry (protect trigger exception).

alter table public.profiles
  add column if not exists subscription_status text not null default 'none',
  add column if not exists subscription_receipt_url text,
  add column if not exists pending_subscription_tier text;

alter table public.profiles
  drop constraint if exists profiles_subscription_status_check;

alter table public.profiles
  add constraint profiles_subscription_status_check
  check (
    subscription_status in ('none', 'pending_verification', 'active')
  );

alter table public.profiles
  drop constraint if exists profiles_pending_subscription_tier_check;

alter table public.profiles
  add constraint profiles_pending_subscription_tier_check
  check (
    pending_subscription_tier is null
    or pending_subscription_tier in ('vip', 'prime')
  );

comment on column public.profiles.subscription_status is
  'none | pending_verification (InstaPay awaiting admin) | active paid plan.';

comment on column public.profiles.subscription_receipt_url is
  'Public URL of the InstaPay transfer screenshot for a pending upgrade.';

comment on column public.profiles.pending_subscription_tier is
  'vip (Pro) or prime while subscription_status = pending_verification.';

-- Paid plans already settled count as active.
update public.profiles
set subscription_status = 'active'
where subscription_plan in ('prime', 'pro')
  and subscription_status = 'none'
  and (subscription_expiry is null or subscription_expiry > now());

-- Customers cannot self-activate plan columns; admins and service_role can.
create or replace function public.protect_subscription_columns()
returns trigger
language plpgsql
as $$
begin
  if TG_OP = 'UPDATE'
     and auth.role() in ('anon', 'authenticated')
     and not public.is_admin() then
    new.subscription_plan := old.subscription_plan;
    new.subscription_expiry := old.subscription_expiry;
  end if;
  return new;
end;
$$;

create or replace function public.submit_subscription_instapay(
  p_tier text,
  p_receipt_url text
) returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  uid uuid := auth.uid();
  tier text := lower(trim(coalesce(p_tier, '')));
  receipt text := trim(coalesce(p_receipt_url, ''));
begin
  if uid is null then
    raise exception 'not authenticated';
  end if;
  if tier not in ('vip', 'prime') then
    raise exception 'invalid_tier';
  end if;
  if receipt = '' then
    raise exception 'receipt_required';
  end if;

  insert into public.profiles (
    id,
    subscription_status,
    subscription_receipt_url,
    pending_subscription_tier
  )
  values (uid, 'pending_verification', receipt, tier)
  on conflict (id) do update
  set subscription_status = 'pending_verification',
      subscription_receipt_url = excluded.subscription_receipt_url,
      pending_subscription_tier = excluded.pending_subscription_tier;
end;
$$;

revoke all on function public.submit_subscription_instapay(text, text)
  from public, anon;
grant execute on function public.submit_subscription_instapay(text, text)
  to authenticated;

create or replace function public.list_pending_subscriptions()
returns table (
  id uuid,
  full_name text,
  phone text,
  pending_subscription_tier text,
  subscription_receipt_url text,
  subscription_status text
)
language plpgsql
security definer
set search_path = public
as $$
begin
  if not public.is_admin() then
    raise exception 'forbidden';
  end if;

  return query
  select
    p.id,
    p.full_name,
    p.phone,
    p.pending_subscription_tier,
    p.subscription_receipt_url,
    p.subscription_status
  from public.profiles p
  where p.subscription_status = 'pending_verification'
  order by p.full_name nulls last, p.phone nulls last;
end;
$$;

revoke all on function public.list_pending_subscriptions()
  from public, anon;
grant execute on function public.list_pending_subscriptions()
  to authenticated;

create or replace function public.approve_subscription_request(p_user_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  tier text;
  plan text;
begin
  if not public.is_admin() then
    raise exception 'forbidden';
  end if;
  if p_user_id is null then
    raise exception 'user_required';
  end if;

  select p.pending_subscription_tier
  into tier
  from public.profiles p
  where p.id = p_user_id
    and p.subscription_status = 'pending_verification'
  for update;

  if tier is null then
    raise exception 'no_pending_subscription';
  end if;

  plan := case tier when 'vip' then 'pro' else 'prime' end;

  update public.profiles p
  set subscription_plan = plan,
      subscription_expiry =
        case
          when p.subscription_plan = plan and p.subscription_expiry > now()
            then p.subscription_expiry
          else now()
        end + interval '30 days',
      subscription_status = 'active',
      pending_subscription_tier = null
  where p.id = p_user_id;
end;
$$;

revoke all on function public.approve_subscription_request(uuid)
  from public, anon;
grant execute on function public.approve_subscription_request(uuid)
  to authenticated;

-- Card/Paymob settlement also marks the plan active and clears pending InstaPay.
-- Signature matches 20261116210000_order_paymob_payments.sql.
create or replace function public.settle_paymob_payment(
  p_paymob_order_id text,
  p_paymob_transaction_id text,
  p_amount_cents bigint,
  p_success boolean,
  p_pending boolean default false
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  tx public.payment_transactions;
  plan text;
begin
  select * into tx
  from public.payment_transactions t
  where t.paymob_order_id = p_paymob_order_id
  for update;

  if not found then
    return jsonb_build_object('status', 'unknown_order');
  end if;

  if tx.status = 'success' or p_pending then
    return jsonb_build_object('transaction_id', tx.id, 'status', tx.status);
  end if;

  if not p_success then
    update public.payment_transactions t
    set status = 'failed',
        paymob_transaction_id = p_paymob_transaction_id,
        updated_at = now()
    where t.id = tx.id;

    if tx.order_id is not null then
      update public.orders o
      set payment_status = 'failed',
          updated_at = now()
      where o.id = tx.order_id;
    end if;

    return jsonb_build_object('transaction_id', tx.id, 'status', 'failed');
  end if;

  if p_amount_cents is distinct from round(tx.amount * 100)::bigint then
    raise exception 'Paymob paid % cents for payment % of % %',
      p_amount_cents, tx.id, tx.amount, tx.currency;
  end if;

  update public.payment_transactions t
  set status = 'success',
      paymob_transaction_id = p_paymob_transaction_id,
      paid_at = now(),
      updated_at = now()
  where t.id = tx.id;

  if tx.order_id is not null then
    update public.orders o
    set payment_status = 'paid',
        payment_method = 'visa',
        status = case
          when o.status in ('pending', 'processing') then 'preparing'
          else o.status
        end,
        updated_at = now()
    where o.id = tx.order_id;

    return jsonb_build_object(
      'transaction_id', tx.id,
      'status', 'success',
      'order_id', tx.order_id
    );
  end if;

  plan := case tx.tier when 'vip' then 'pro' else 'prime' end;

  update public.profiles p
  set subscription_plan = plan,
      subscription_expiry =
        case
          when p.subscription_plan = plan and p.subscription_expiry > now()
            then p.subscription_expiry
          else now()
        end + interval '30 days',
      subscription_status = 'active',
      pending_subscription_tier = null
  where p.id = tx.user_id;

  if not found then
    insert into public.profiles (
      id,
      subscription_plan,
      subscription_expiry,
      subscription_status
    )
    values (tx.user_id, plan, now() + interval '30 days', 'active');
  end if;

  return jsonb_build_object('transaction_id', tx.id, 'status', 'success');
end;
$$;

revoke execute on function
  public.settle_paymob_payment(text, text, bigint, boolean, boolean)
  from public, anon, authenticated;
grant execute on function
  public.settle_paymob_payment(text, text, bigint, boolean, boolean)
  to service_role;

notify pgrst, 'reload schema';
