-- random_products() can now keep only products that have a photo, so the
-- customer home screen's random row stays full instead of losing the
-- photo-less picks after sampling. Admins call it without p_with_image.

drop function if exists public.random_products(integer);

create or replace function public.random_products(
  p_limit integer default 20,
  p_with_image boolean default false
)
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
    and (not p_with_image or p.image_url ~ '\S')
  order by random()
  limit least(greatest(coalesce(p_limit, 20), 1), 50);
$$;

grant execute on function public.random_products(integer, boolean)
  to anon, authenticated;
