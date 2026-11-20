-- A random sample of in-stock products for the home screen's
-- «منتجات طازجة مختارة» row. PostgREST can't order by random(), so the
-- sampling happens here. In stock matches the app: is_active (null counts as
-- true) and stock_quantity above zero (null counts as 0).
create or replace function public.random_products(p_limit integer default 20)
returns setof public.products
language sql
volatile
security invoker
set search_path = ''
as $$
  select p.*
  from public.products p
  where coalesce(p.is_active, true)
    and coalesce(p.stock_quantity, 0) > 0
  order by random()
  limit least(greatest(coalesce(p_limit, 20), 1), 50);
$$;

grant execute on function public.random_products
  to anon, authenticated;
