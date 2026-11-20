-- products.category holds the product's group (e.g. 'جبن تترباك', 'منظفات').
-- The app maps these onto its fixed main categories and pages through their
-- in-stock products, filtering with exact matches.

-- Imported values can carry stray spaces ('منظفات ' vs 'منظفات'), which would
-- split one group in two and break exact-match filtering.
update public.products
set category = nullif(btrim(category), '')
where category is distinct from nullif(btrim(category), '');

create or replace function public.products_normalize_category()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.category := nullif(btrim(new.category), '');
  return new;
end;
$$;

drop trigger if exists products_normalize_category on public.products;
create trigger products_normalize_category
  before insert or update of category on public.products
  for each row execute function public.products_normalize_category();

-- Category pages filter by category and sort by name.
create index if not exists products_category_name_idx
  on public.products (category, name);
