-- Receive/return type, invoice details and the picked supplier code on mobile
-- goods receipts, plus the supplier list the app searches.
-- app_suppliers mirrors Fujitsu dbo.sys_supplier (supplierno, a_name).
-- Safe to re-run in the Supabase SQL editor.

alter table public.app_receipts
  add column if not exists transaction_type text not null default 'receive',
  add column if not exists supplier_no integer,
  add column if not exists invoice_no text,
  add column if not exists invoice_date date,
  add column if not exists document_date date not null default current_date;

alter table public.app_receipts
  drop constraint if exists app_receipts_transaction_type_check;
alter table public.app_receipts
  add constraint app_receipts_transaction_type_check
    check (transaction_type in ('receive', 'return'));

create table if not exists public.app_suppliers (
  supplier_no integer primary key,
  name text not null,
  updated_at timestamptz not null default now()
);

alter table public.app_suppliers enable row level security;

grant select on public.app_suppliers to authenticated;

drop policy if exists "app_suppliers_warehouse_select" on public.app_suppliers;
create policy "app_suppliers_warehouse_select" on public.app_suppliers
  for select to authenticated
  using (public.is_warehouse());

-- Without this the API keeps answering "Could not find the 'document_date'
-- column of 'app_receipts' in the schema cache" until it reloads on its own.
notify pgrst, 'reload schema';
