-- Products sold by the kilo. products.price is the price per kilo for these;
-- the app also treats any product whose name contains 'وزن' as weight-based.
alter table public.products
  add column if not exists is_weight_based boolean not null default false;

-- Grams the customer picked for a weight-based line (quantity is then 1 and
-- price_at_time is the price of that weight). Null for unit-based lines.
alter table public.order_items
  add column if not exists weight_in_grams integer
    check (weight_in_grams is null or weight_in_grams > 0);
