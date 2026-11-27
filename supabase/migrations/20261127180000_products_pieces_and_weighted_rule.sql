-- Per-barcode pack size from Fujitsu v_hd_items.Pieces.
-- Weighted sale is only valid when pieces <= 1 (see sync_direct + Product.isWeightBased).

alter table public.products
  add column if not exists pieces integer not null default 1;

comment on column public.products.pieces is
  'Fujitsu v_hd_items.Pieces for this barcode. >1 means pack/sack (never sold by decimal kg).';

-- Clear false weight flags on multi-piece / carton barcodes (name may still
-- contain «وزن», e.g. ارز … وزن sold as ك * 25).
update public.products
set is_weight_based = false
where coalesce(pieces, 1) > 1
   or unit ~ '^ك[[:space:]]*[*×xX][[:space:]]*[0-9]+$';
