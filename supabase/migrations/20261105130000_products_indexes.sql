-- Indexes behind the app's hot product queries. Safe to re-run.
--
-- * category pages: filter on category / category_id and is_active, sort by
--   name, page with range()
-- * «منتجات جديدة»: newest first
-- * customer lists: only rows whose image_url is an http(s) link (the same
--   regex the app sends as `image_url=imatch.^\s*https?://[^\s/]`)
-- * offers: rows with a discount_price

create index if not exists products_category_active_idx
  on public.products (category_id, is_active);

create index if not exists products_category_name_idx
  on public.products (category, is_active, name);

create index if not exists products_created_at_desc_idx
  on public.products (created_at desc);

create index if not exists products_image_url_idx
  on public.products (image_url);

-- Partial index: the customer-visible, sellable rows.
create index if not exists products_sellable_with_image_idx
  on public.products (category_id, name)
  where image_url ~* '^\s*https?://[^\s/]'
    and is_active is distinct from false
    and stock_quantity > 0;

create index if not exists products_discounted_idx
  on public.products (discount_price)
  where discount_price is not null;

analyze public.products;
