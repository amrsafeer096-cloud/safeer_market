-- «طلباتي»: an expanded order card lists the products in the order, so
-- customers read the order_items of their own orders. Safe to re-run.
-- Row level security is left as it is: checkout and the dashboard read and
-- write order_items under the policies already in place.

grant select on public.order_items to authenticated;

drop policy if exists "order_items_customer_select" on public.order_items;
create policy "order_items_customer_select" on public.order_items
  for select to authenticated
  using (
    exists (
      select 1 from public.orders o
      where o.id = order_items.order_id
        and o.user_id = (select auth.uid())
    )
  );
