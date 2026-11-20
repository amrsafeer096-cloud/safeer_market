-- Categories are products.category_id -> categories.id. An optional
-- sub_category (e.g. 'معلبات') groups products within a category.

alter table public.products
  add column if not exists sub_category text;

update public.products
set sub_category = nullif(trim(sub_category), '')
where sub_category is distinct from nullif(trim(sub_category), '');

-- Category pages filter by category_id (+ sub_category) and sort by name.
create index if not exists products_category_id_sub_category_name_idx
  on public.products (category_id, sub_category, name);

-- Distinct sub-categories of one category, for the category screen's filter
-- chips. PostgREST has no DISTINCT, and pulling every row of a large
-- category just to dedupe it client-side would be capped at max-rows anyway.
create or replace function public.product_sub_categories(
  p_category_id public.products.category_id%type
)
returns setof text
language sql
stable
security invoker
set search_path = ''
as $$
  select distinct p.sub_category
  from public.products p
  where p.category_id = p_category_id
    and p.sub_category is not null
  order by p.sub_category;
$$;

grant execute on function public.product_sub_categories
  to anon, authenticated;
