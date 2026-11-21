-- Push notifications (FCM v1) for every signed-in device.
--
-- 1. user_fcm_tokens: one row per device token, with the owner's push role
--    (admin / taker / delivery / customer) and platform (android / ios /
--    web / windows / macos). The app registers through register_fcm_token();
--    the role always comes from profiles, never from the client.
-- 2. Triggers on orders (insert, status change) and app_notifications
--    (insert) post the row to the send-push Edge Function with pg_net, which
--    fans it out to the matching tokens.
-- 3. orders.delivery_map_url: an optional saved Google Maps pin link, so an
--    order without GPS coordinates can still get the map navigation button.
--
-- One-time setup (SQL Editor), with your project ref and a random secret
-- that is also set as the PUSH_WEBHOOK_SECRET Edge Function secret:
--   select vault.create_secret(
--     'https://<project-ref>.supabase.co/functions/v1/send-push',
--     'push_webhook_url');
--   select vault.create_secret('<random-secret>', 'push_webhook_secret');
-- Until both exist the triggers do nothing. Safe to re-run.

create extension if not exists pg_net with schema extensions;

alter table public.orders
  add column if not exists delivery_map_url text;

-- ------------------------------------------------------------ tokens

create table if not exists public.user_fcm_tokens (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  token text not null unique,
  role text not null default 'customer'
    check (role in ('admin', 'taker', 'delivery', 'customer')),
  platform text not null default 'android'
    check (platform in ('android', 'ios', 'web', 'windows', 'macos', 'linux')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists user_fcm_tokens_user_idx
  on public.user_fcm_tokens (user_id);
create index if not exists user_fcm_tokens_role_idx
  on public.user_fcm_tokens (role);

alter table public.user_fcm_tokens enable row level security;

revoke all on public.user_fcm_tokens from anon;
grant select, delete on public.user_fcm_tokens to authenticated;

drop policy if exists "user_fcm_tokens_own_select" on public.user_fcm_tokens;
create policy "user_fcm_tokens_own_select" on public.user_fcm_tokens
  for select to authenticated
  using (user_id = (select auth.uid()));

drop policy if exists "user_fcm_tokens_own_delete" on public.user_fcm_tokens;
create policy "user_fcm_tokens_own_delete" on public.user_fcm_tokens
  for delete to authenticated
  using (user_id = (select auth.uid()));

-- profiles.role → push audience. Warehouse staff and cashiers take phone
-- orders (see is_order_taker), drivers deliver.
create or replace function public.push_role_for(p_user_id uuid)
returns text
language sql
stable
security definer
set search_path = ''
as $$
  select case lower(coalesce(
    (select role from public.profiles where id = p_user_id), 'customer'))
    when 'admin' then 'admin'
    when 'warehouse' then 'taker'
    when 'cashier' then 'taker'
    when 'driver' then 'delivery'
    else 'customer'
  end;
$$;

-- Saves this device's token for the caller. A token moves to whoever signed
-- in last on the device, so a shared phone never alerts the previous user.
create or replace function public.register_fcm_token(
  p_token text,
  p_platform text default 'android'
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user_id uuid := auth.uid();
  v_platform text := lower(coalesce(nullif(btrim(p_platform), ''), 'android'));
begin
  if v_user_id is null then
    raise exception 'Not signed in' using errcode = '28000';
  end if;
  if p_token is null or length(btrim(p_token)) < 20 then
    raise exception 'Invalid token' using errcode = '22023';
  end if;
  if v_platform not in ('android', 'ios', 'web', 'windows', 'macos', 'linux')
  then
    v_platform := 'android';
  end if;

  insert into public.user_fcm_tokens (user_id, token, role, platform)
  values (v_user_id, btrim(p_token), public.push_role_for(v_user_id), v_platform)
  on conflict (token) do update
    set user_id = excluded.user_id,
        role = excluded.role,
        platform = excluded.platform,
        updated_at = now();
end;
$$;

create or replace function public.unregister_fcm_token(p_token text)
returns void
language sql
security definer
set search_path = ''
as $$
  delete from public.user_fcm_tokens
  where token = btrim(p_token) and user_id = auth.uid();
$$;

revoke all on function public.register_fcm_token(text, text) from public, anon;
revoke all on function public.unregister_fcm_token(text) from public, anon;
revoke all on function public.push_role_for(uuid) from public, anon, authenticated;
grant execute on function public.register_fcm_token(text, text) to authenticated;
grant execute on function public.unregister_fcm_token(text) to authenticated;

-- A promoted / demoted user's devices follow their new role.
create or replace function public.sync_fcm_token_roles()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  update public.user_fcm_tokens
  set role = public.push_role_for(new.id), updated_at = now()
  where user_id = new.id;
  return new;
end;
$$;

drop trigger if exists profiles_sync_fcm_token_roles on public.profiles;
create trigger profiles_sync_fcm_token_roles
  after update of role on public.profiles
  for each row
  when (old.role is distinct from new.role)
  execute function public.sync_fcm_token_roles();

-- ------------------------------------------------------------ dispatch

-- Posts the changed row to send-push in the same shape as a Supabase
-- Database Webhook. pg_net is asynchronous and errors are swallowed, so a
-- push problem can never block placing an order or sending a notification.
create or replace function public.dispatch_push_webhook()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_url text;
  v_secret text;
begin
  select decrypted_secret into v_url
  from vault.decrypted_secrets where name = 'push_webhook_url' limit 1;
  select decrypted_secret into v_secret
  from vault.decrypted_secrets where name = 'push_webhook_secret' limit 1;
  if v_url is null or v_secret is null then
    return new;
  end if;

  perform net.http_post(
    url := v_url,
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'x-push-secret', v_secret
    ),
    body := jsonb_build_object(
      'type', tg_op,
      'table', tg_table_name,
      'schema', tg_table_schema,
      'record', to_jsonb(new),
      'old_record', case when tg_op = 'UPDATE' then to_jsonb(old) end
    ),
    timeout_milliseconds := 5000
  );
  return new;
exception when others then
  raise warning 'dispatch_push_webhook: %', sqlerrm;
  return new;
end;
$$;

revoke all on function public.dispatch_push_webhook() from public, anon, authenticated;

drop trigger if exists orders_push_on_insert on public.orders;
create trigger orders_push_on_insert
  after insert on public.orders
  for each row
  execute function public.dispatch_push_webhook();

drop trigger if exists orders_push_on_status on public.orders;
create trigger orders_push_on_status
  after update of status on public.orders
  for each row
  when (old.status is distinct from new.status)
  execute function public.dispatch_push_webhook();

drop trigger if exists app_notifications_push_on_insert
  on public.app_notifications;
create trigger app_notifications_push_on_insert
  after insert on public.app_notifications
  for each row
  execute function public.dispatch_push_webhook();

notify pgrst, 'reload schema';
