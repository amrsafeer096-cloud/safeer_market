-- POS barcodes can arrive space-padded (SQL Server char columns), which breaks
-- exact barcode search. Trim existing values; rows whose trimmed barcode
-- collides with another row are left alone rather than violating the unique
-- index, and need a manual merge.

update public.products p
set barcode = nullif(btrim(p.barcode), '')
where p.barcode is not null
  and p.barcode <> btrim(p.barcode)
  and not exists (
    select 1
    from public.products other
    where other.id <> p.id
      and btrim(other.barcode) = btrim(p.barcode)
  );
