-- Delivery zone chosen at checkout (e.g. المقطم). orders.delivery_fee already
-- holds that zone's fee. Older orders keep null.

alter table public.orders
  add column if not exists delivery_area text;
