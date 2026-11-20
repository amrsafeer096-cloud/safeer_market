-- Normalize attara / spices category spellings so the Customer App «عطارة»
-- grid query (MainCategories.attara) returns products.

update public.products
set category = 'عطارة وزن'
where btrim(category) in (
  'عطارة',
  'عطاره',
  'العطارة',
  'العطاره',
  'عطارة وزن',
  'عطاره وزن',
  'العطارة وزن'
);

update public.products
set category = 'علافة وزن'
where btrim(category) in ('علافة وزن', 'علافه وزن');
