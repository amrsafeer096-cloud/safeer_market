-- products.image_url keeps pointing at Storage files that don't exist (about
-- 6% of links on 2026-11-07, after 20261105030000 had cleared them once).
-- Their text is a valid http(s) link, so no query filter can tell; customers
-- got grey placeholder cards. These triggers keep the column honest from now
-- on, whatever writes it (the app, upload_to_supabase.py, the POS sync):
--   * a link to a missing Storage file, or text that isn't an http(s) link,
--     is saved as null;
--   * deleting a Storage file clears the links to it.
-- Re-uploading the photo (app or upload_to_supabase.py) sets image_url again.

-- True when [url] names a file in a public Storage bucket that isn't there.
create or replace function public.is_missing_storage_file(url text)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select url ~ '/storage/v1/object/public/[^/]+/'
    and not exists (
      select 1
      from storage.objects o
      where o.bucket_id = substring(url from '/storage/v1/object/public/([^/]+)/')
        and o.name = substring(url from '/storage/v1/object/public/[^/]+/([^?#]+)')
    );
$$;

revoke execute on function public.is_missing_storage_file(text)
  from public, anon, authenticated;

-- 1. Clear today's dead and junk links.
update public.products
set image_url = null
where image_url is not null
  and (
    image_url !~* '^\s*https?://[^\s/]'
    or public.is_missing_storage_file(image_url)
  );

-- 2. Never save one again.
create or replace function public.products_drop_dead_image_url()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if new.image_url is not null
     and (
       new.image_url !~* '^\s*https?://[^\s/]'
       or public.is_missing_storage_file(new.image_url)
     ) then
    new.image_url := null;
  end if;
  return new;
end;
$$;

drop trigger if exists products_drop_dead_image_url on public.products;
create trigger products_drop_dead_image_url
  before insert or update of image_url on public.products
  for each row
  execute function public.products_drop_dead_image_url();

-- 3. A deleted Storage file takes its links with it.
create or replace function public.products_forget_deleted_image()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  update public.products
  set image_url = null
  where substring(image_url from '/storage/v1/object/public/([^/]+)/')
          = old.bucket_id
    and substring(image_url from '/storage/v1/object/public/[^/]+/([^?#]+)')
          = old.name;
  return old;
end;
$$;

drop trigger if exists products_forget_deleted_image on storage.objects;
create trigger products_forget_deleted_image
  after delete on storage.objects
  for each row
  execute function public.products_forget_deleted_image();

-- 4. Same rule as Product.hasValidImageUrl for the random home row
--    (in case 20261105030000 was never applied).
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
