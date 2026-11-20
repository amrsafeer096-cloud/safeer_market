-- Mobile goods-receipt staging tables.
-- A later sync job turns each pending receipt into a Fujitsu GRN:
--   stk_order / stk_order_items
--   company = 1, branch = 101, transtype = 201, doctype = 2010
-- Safe to re-run in the Supabase SQL editor.

create table if not exists public.app_receipts (
  id uuid primary key default gen_random_uuid(),
  supplier_name text not null,
  status text not null default 'pending',
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  constraint app_receipts_supplier_name_not_blank
    check (char_length(btrim(supplier_name)) > 0),
  constraint app_receipts_status_check
    check (status in ('pending', 'synced', 'failed'))
);

create table if not exists public.app_receipt_items (
  id uuid primary key default gen_random_uuid(),
  receipt_id uuid not null
    references public.app_receipts (id) on delete cascade,
  barcode text not null,
  quantity integer not null,
  created_at timestamptz not null default now(),
  constraint app_receipt_items_barcode_not_blank
    check (char_length(btrim(barcode)) > 0),
  constraint app_receipt_items_quantity_positive
    check (quantity > 0)
);

create index if not exists app_receipts_pending_idx
  on public.app_receipts (created_at)
  where status = 'pending';

create index if not exists app_receipt_items_receipt_id_idx
  on public.app_receipt_items (receipt_id);

alter table public.app_receipts enable row level security;
alter table public.app_receipt_items enable row level security;

grant select, insert, delete on public.app_receipts to authenticated;
grant select, insert on public.app_receipt_items to authenticated;

-- True when the signed-in user is warehouse staff.
-- user_roles.id is the auth user id; email is accepted as a fallback.
create or replace function public.is_warehouse()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.user_roles
    where lower(btrim(role)) = 'warehouse'
      and (
        id = (select auth.uid())
        or lower(btrim(email)) = lower(btrim(coalesce(
          (select auth.jwt() ->> 'email'),
          ''
        )))
      )
  );
$$;

grant execute on function public.is_warehouse() to authenticated;

-- Warehouse staff create receipts and read the ones they created.

drop policy if exists "app_receipts_warehouse_select" on public.app_receipts;
create policy "app_receipts_warehouse_select" on public.app_receipts
  for select to authenticated
  using (public.is_warehouse() and created_by = (select auth.uid()));

drop policy if exists "app_receipts_warehouse_insert" on public.app_receipts;
create policy "app_receipts_warehouse_insert" on public.app_receipts
  for insert to authenticated
  with check (
    public.is_warehouse()
    and created_by = (select auth.uid())
    and status = 'pending'
  );

-- Lets the app undo a header when the items insert fails.
drop policy if exists "app_receipts_warehouse_delete" on public.app_receipts;
create policy "app_receipts_warehouse_delete" on public.app_receipts
  for delete to authenticated
  using (
    public.is_warehouse()
    and created_by = (select auth.uid())
    and status = 'pending'
  );

drop policy if exists "app_receipt_items_warehouse_select"
  on public.app_receipt_items;
create policy "app_receipt_items_warehouse_select" on public.app_receipt_items
  for select to authenticated
  using (
    public.is_warehouse()
    and exists (
      select 1 from public.app_receipts r
      where r.id = app_receipt_items.receipt_id
        and r.created_by = (select auth.uid())
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
        and r.created_by = (select auth.uid())
        and r.status = 'pending'
    )
  );
