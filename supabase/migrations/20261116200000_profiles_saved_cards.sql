-- Persist masked bank cards on the customer profile (no CVV / full PAN).
-- SharedPreferences mirrors this list keyed by user id for offline reads.

alter table public.profiles
  add column if not exists saved_cards jsonb not null default '[]'::jsonb;

comment on column public.profiles.saved_cards is
  'Masked saved payment cards (last4, brand, expiry, holder, token/id). Never stores CVV or full PAN.';
