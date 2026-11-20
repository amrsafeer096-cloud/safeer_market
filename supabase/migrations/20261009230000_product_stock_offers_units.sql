-- Unit of sale shown on product cards ('قطعة', 'وزن', 'كرتونة').
--
-- Stock, discounts and the active flag use the table's existing columns
-- (stock_quantity, discount_price, is_active); nothing here touches them.

alter table public.products
  add column if not exists unit text not null default 'قطعة';
