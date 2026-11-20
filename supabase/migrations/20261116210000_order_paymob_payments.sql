-- Grocery order payments via Paymob.
-- Extends payment_transactions for order_id settlements and adds
-- orders.payment_status so the admin dashboard can show prepaid Visa orders.

alter table public.orders
  add column if not exists payment_status text not null default 'unpaid'
    check (payment_status in ('unpaid', 'pending', 'paid', 'failed'));

comment on column public.orders.payment_status is
  'Settlement state for card/Paymob payments. COD stays unpaid.';

-- Allow subscription rows (tier set) and grocery rows (order_id set).
alter table public.payment_transactions
  alter column tier drop not null;

alter table public.payment_transactions
  drop constraint if exists payment_transactions_tier_check;

alter table public.payment_transactions
  add constraint payment_transactions_tier_check
  check (tier is null or tier in ('vip', 'prime'));

alter table public.payment_transactions
  add column if not exists order_id uuid references public.orders (id) on delete set null;

create index if not exists payment_transactions_order_id_idx
  on public.payment_transactions (order_id)
  where order_id is not null;

alter table public.payment_transactions
  drop constraint if exists payment_transactions_purpose_chk;

alter table public.payment_transactions
  add constraint payment_transactions_purpose_chk
  check (
    (order_id is not null and tier is null)
    or (order_id is null and tier is not null)
  );

-- Settle Paymob callbacks for both subscriptions and grocery orders.
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

  -- Grocery order: mark paid by Visa and move into the warehouse queue.
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

  -- Subscription path (unchanged).
  plan := case tx.tier when 'vip' then 'pro' else 'prime' end;

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
