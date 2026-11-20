-- Loyalty balance shown on the rewards screen and increased by the spin wheel.
-- Existing profile rows get 0. The app updates this column on the signed-in
-- user's own row, so the current profiles update policy must allow it.

alter table public.profiles
  add column if not exists loyalty_points integer not null default 0;
