-- Paymob (Egypt) payments for the paid plans.
--
-- Flow: the create-paymob-order Edge Function inserts a 'pending' row and
-- opens Paymob checkout; Paymob calls the paymob-webhook Edge Function,
-- which verifies the HMAC and calls settle_paymob_payment() below. Only the
-- service role (the Edge Functions) writes here; customers can read their
-- own rows so the app can show the outcome.
--
-- Plans live in profiles.subscription_plan / subscription_expiry
-- (20261026010000). Paymob tiers map onto them: 'vip' is the plan shown as
-- «سفير برو (VIP)», stored as 'pro'; 'prime' is 'prime'.

create table if not exists public.payment_transactions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  amount numeric(10, 2) not null check (amount > 0),
  currency text not null default 'EGP',
  tier text not null check (tier in ('vip', 'prime')),
  status text not null default 'pending'
    check (status in ('pending', 'success', 'failed')),
  payment_method text not null default 'card'
    check (payment_method in ('card', 'wallet')),
  paymob_order_id text unique,
  paymob_transaction_id text,
  paid_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists payment_transactions_user_created_idx
  on public.payment_transactions (user_id, created_at desc);

alter table public.payment_transactions enable row level security;

drop policy if exists "Users read their own payments"
  on public.payment_transactions;
create policy "Users read their own payments"
  on public.payment_transactions
  for select
  to authenticated
  using (user_id = auth.uid());

-- No insert/update/delete policies: only the service role writes.
revoke insert, update, delete on public.payment_transactions
  from anon, authenticated;

-- Applies a verified Paymob transaction to its payment and, when paid, to
-- the buyer's plan. Safe to call more than once for the same transaction
-- (Paymob retries callbacks, and both the server callback and the browser
-- redirect report it): a successful payment is applied only once.
--
-- A paid plan runs 30 days from now; renewing the same plan while it is
-- still active adds the 30 days to its current expiry instead.
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

  -- Already paid, or Paymob is still waiting (e.g. a wallet approval).
  if tx.status = 'success' or p_pending then
    return jsonb_build_object('transaction_id', tx.id, 'status', tx.status);
  end if;

  if not p_success then
    update public.payment_transactions t
    set status = 'failed',
        paymob_transaction_id = p_paymob_transaction_id,
        updated_at = now()
    where t.id = tx.id;
    return jsonb_build_object('transaction_id', tx.id, 'status', 'failed');
  end if;

  if p_amount_cents is distinct from round(tx.amount * 100)::bigint then
    raise exception 'Paymob paid % cents for payment % of % %',
      p_amount_cents, tx.id, tx.amount, tx.currency;
  end if;

  plan := case tx.tier when 'vip' then 'pro' else 'prime' end;

  update public.payment_transactions t
  set status = 'success',
      paymob_transaction_id = p_paymob_transaction_id,
      paid_at = now(),
      updated_at = now()
  where t.id = tx.id;

  update public.profiles p
  set subscription_plan = plan,
      subscription_expiry =
        case
          when p.subscription_plan = plan and p.subscription_expiry > now()
            then p.subscription_expiry
          else now()
        end + interval '30 days'
  where p.id = tx.user_id;

  if not found then
    insert into public.profiles (id, subscription_plan, subscription_expiry)
    values (tx.user_id, plan, now() + interval '30 days');
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
