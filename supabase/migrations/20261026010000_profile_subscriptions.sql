-- Subscription plan shown in the app: 'free' (default), 'prime' or 'pro'.
-- subscription_expiry is when a paid plan lapses; null means it doesn't.

alter table public.profiles
  add column if not exists subscription_plan text not null default 'free'
    check (subscription_plan in ('free', 'prime', 'pro')),
  add column if not exists subscription_expiry timestamptz;

-- The app updates the signed-in user's own profiles row, so plans must not be
-- set or edited from there. Only the dashboard / service role can change them.
create or replace function public.protect_subscription_columns()
returns trigger
language plpgsql
as $$
begin
  if auth.role() in ('anon', 'authenticated') then
    new.subscription_plan := old.subscription_plan;
    new.subscription_expiry := old.subscription_expiry;
  end if;
  return new;
end;
$$;

drop trigger if exists protect_subscription_columns on public.profiles;
create trigger protect_subscription_columns
  before insert or update on public.profiles
  for each row execute function public.protect_subscription_columns();
