-- Columns written by tools/pos_sync, which mirrors names and prices from the
-- Fujitsu POS (SQL Server) into products. The sync upserts on barcode, so it
-- must be unique; multiple NULLs are still allowed for products that were
-- created in the app and never came from the POS.

alter table public.products
  add column if not exists barcode text,
  add column if not exists pos_item_ean text,
  add column if not exists pos_synced_at timestamptz;

create unique index if not exists products_barcode_key
  on public.products (barcode);

create index if not exists products_pos_item_ean_idx
  on public.products (pos_item_ean);
