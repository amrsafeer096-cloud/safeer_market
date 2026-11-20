-- Mobile receipts are now saved as drafts (status 'مبدئي') with the ERP's
-- column set: supplier_id, supplier_name, invoice_no, invoice_date,
-- document_date, status. The app no longer sends created_by.
-- Safe to re-run in the Supabase SQL editor.

alter table public.app_receipts
  drop constraint if exists app_receipts_status_check;

grant select, insert, delete on public.app_receipts to authenticated;
grant select, insert on public.app_receipt_items to authenticated;

drop policy if exists "app_receipts_warehouse_select" on public.app_receipts;
create policy "app_receipts_warehouse_select" on public.app_receipts
  for select to authenticated
  using (public.is_warehouse());

drop policy if exists "app_receipts_warehouse_insert" on public.app_receipts;
create policy "app_receipts_warehouse_insert" on public.app_receipts
  for insert to authenticated
  with check (public.is_warehouse() and status = 'مبدئي');

-- Lets the app undo a header when the items insert fails.
drop policy if exists "app_receipts_warehouse_delete" on public.app_receipts;
create policy "app_receipts_warehouse_delete" on public.app_receipts
  for delete to authenticated
  using (public.is_warehouse() and status = 'مبدئي');

drop policy if exists "app_receipt_items_warehouse_select"
  on public.app_receipt_items;
create policy "app_receipt_items_warehouse_select" on public.app_receipt_items
  for select to authenticated
  using (
    public.is_warehouse()
    and exists (
      select 1 from public.app_receipts r
      where r.id = app_receipt_items.receipt_id
    )
  );

drop policy if exists "app_receipt_items_warehouse_insert"
  on public.app_receipt_items;
create policy "app_receipt_items_warehouse_insert" on public.app_receipt_items
  for insert to authenticated
  with check (
    public.is_warehouse()
    and exists (
      select 1 from public.app_receipts r
      where r.id = receipt_id
        and r.status = 'مبدئي'
    )
  );

notify pgrst, 'reload schema';
