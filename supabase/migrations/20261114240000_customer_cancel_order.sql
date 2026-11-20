-- Customers cancel their own orders from «طلباتي» while the order is still
-- new or being prepared, and leave a reason for the dashboard. Once it is
-- ready for a driver or out for delivery, only staff can change it.
-- Safe to re-run.

alter table public.orders
  add column if not exists cancellation_reason text;

-- Customers cancel their own order: status becomes cancelled and a reason
-- is required. They cannot touch anything else (totals, address, …).
drop policy if exists "orders_customer_cancel" on public.orders;
create policy "orders_customer_cancel" on public.orders
  for update to authenticated
  using (
    user_id = (select auth.uid())
    and status in ('pending', 'new', 'preparing')
  )
  with check (
    user_id = (select auth.uid())
    and status = 'cancelled'
    and cancellation_reason is not null
    and length(btrim(cancellation_reason)) between 1 and 200
  );

-- Only status and cancellation_reason may change on a customer cancel; the
-- driver guard already skips the order's owner, so this catches anything
-- else they try to rewrite.
create or replace function public.guard_customer_order_cancel()
returns trigger
language plpgsql
as $$
begin
  if auth.role() = 'authenticated'
     and old.user_id = auth.uid()
     and not public.is_admin()
     and not public.is_warehouse()
     and not public.is_driver()
     and not public.is_order_taker()
     and (to_jsonb(new) - 'status' - 'cancellation_reason' - 'updated_at')
         is distinct from
         (to_jsonb(old) - 'status' - 'cancellation_reason' - 'updated_at')
  then
    raise exception 'Customers can only cancel an order';
  end if;
  return new;
end;
$$;

drop trigger if exists guard_customer_order_cancel on public.orders;
create trigger guard_customer_order_cancel
  before update on public.orders
  for each row execute function public.guard_customer_order_cancel();

notify pgrst, 'reload schema';
