-- «إتمام تجهيز الطلب»: the admin dashboard stamps when preparation finished.
-- The order stays «تحضير» (status = preparing) until a driver is assigned and
-- «بدء التوصيل» moves it to «للطيار»; the 20-minute prep clock stops here.
alter table public.orders
  add column if not exists prep_completed_at timestamptz;

comment on column public.orders.prep_completed_at is
  'When preparation was marked complete (stops the 20-minute prep countdown).';

notify pgrst, 'reload schema';
