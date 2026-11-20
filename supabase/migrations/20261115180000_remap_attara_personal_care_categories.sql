-- Remap / normalize product category spellings after the app regrouped
-- «عطارة» and moved diapers under «عناية شخصية».
--
-- `products.category` stores the *subcategory* label (e.g. «عطارة وزن»),
-- not the home main-category title. Main grouping lives in the Flutter
-- MainCategories map. This script only:
--   1) normalizes known spelling variants to the canonical subcategory
--      strings the app filters on;
--   2) leaves those rows under their subcategory so «عطارة» / «عناية شخصية»
--      tabs keep working.

-- Attara / nuts / baking supplies aliases → canonical subcategory.
update public.products
set category = 'تسالي و مكسرات وزن'
where btrim(category) in ('تسالي ومكسرات وزن', 'تسالي و مكسرات وزن');

update public.products
set category = 'عطارة وزن'
where btrim(category) in ('عطارة وزن', 'عطاره وزن');

update public.products
set category = 'علافة وزن'
where btrim(category) in ('علافة وزن', 'علافه وزن');

update public.products
set category = 'مستلزمات حلويات وبودر'
where btrim(category) = 'مستلزمات حلويات وبودر';

update public.products
set category = 'ياميش رمضان'
where btrim(category) = 'ياميش رمضان';

-- Diapers / pads spelling variants → canonical (now under عناية شخصية).
update public.products
set category = 'حافضات و فوط صحية'
where btrim(category) in (
  'حافضات و فوط صحية',
  'حفاضات و فوط صحية',
  'حفاضات وفوط صحية',
  'حافضات وفوط صحية'
);

-- Optional visibility: how many rows sit in the remapped groups.
-- select category, count(*) from public.products
-- where category in (
--   'عطارة وزن', 'علافة وزن', 'مستلزمات حلويات وبودر',
--   'تسالي و مكسرات وزن', 'ياميش رمضان', 'حافضات و فوط صحية'
-- )
-- group by category;
