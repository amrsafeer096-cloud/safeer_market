-- About 9% of products.image_url pointed at Storage files that don't exist
-- (Storage answers 404 "Object not found"), so customers saw grey placeholder
-- cards. Clearing those links makes the app's filters, category counts, the
-- admin «بدون صورة» list and get_missing.py all treat them as having no photo.
-- Re-uploading with upload_to_supabase.py sets image_url again.

update public.products p
set image_url = null
where p.image_url ~ '/storage/v1/object/public/[^/]+/'
  and not exists (
    select 1
    from storage.objects o
    where o.bucket_id =
            substring(p.image_url from '/storage/v1/object/public/([^/]+)/')
      and o.name =
            substring(p.image_url from '/storage/v1/object/public/[^/]+/([^?#]+)')
  );

-- Same rule as Product.hasValidImageUrl in the app: an http(s) link.
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
    and (not p_with_image or p.image_url ~* '^\s*https?://[^\s/]')
  order by random()
  limit least(greatest(coalesce(p_limit, 20), 1), 50);
$$;

grant execute on function public.random_products(integer, boolean)
  to anon, authenticated;
