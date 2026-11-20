-- Every product that still needs a photo, for the admin «منتجات جديدة» list:
-- image_url missing, not an http(s) link (same rule as the app's
-- Product.hasValidImageUrl), or a Storage link whose file doesn't exist.
-- In stock first, then by name. Security definer to look into
-- storage.objects; returns nothing for anyone but admins.

create or replace function public.products_missing_image()
returns setof public.products
language sql
stable
security definer
set search_path = ''
as $$
  select p.*
  from public.products p
  where public.is_admin()
    and (
      p.image_url is null
      or p.image_url !~* '^\s*https?://[^\s/]'
      or (
        p.image_url ~ '/storage/v1/object/public/[^/]+/'
        and not exists (
          select 1
          from storage.objects o
          where o.bucket_id = substring(
                  p.image_url from '/storage/v1/object/public/([^/]+)/')
            and o.name = substring(
                  p.image_url from '/storage/v1/object/public/[^/]+/([^?#]+)')
        )
      )
    )
  order by
    (coalesce(p.is_active, true) and coalesce(p.stock_quantity, 0) > 0) desc,
    p.name,
    p.id;
$$;

revoke execute on function public.products_missing_image() from public, anon;
grant execute on function public.products_missing_image() to authenticated;
