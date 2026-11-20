-- Live customer support («محادثة فورية مع خدمة العملاء» in the app,
-- «الشكاوى والمحادثات» on the admin dashboard).
--
-- One open chat per customer. Customers read and write only their own chat;
-- order takers (profiles.role admin, warehouse, cashier — see
-- public.is_order_taker() in 20261111010000_phone_orders.sql) see every chat
-- and reply as 'admin'. The chat's last_message, updated_at and
-- unread_admin_count are kept by a trigger on support_messages, so
-- customers never update support_chats themselves and two devices sending
-- at once can't lose a count.
--
-- Written to also upgrade tables created by hand from the dashboard.

create table if not exists public.support_chats (
  id uuid primary key default gen_random_uuid()
);

alter table public.support_chats
  add column if not exists user_id uuid
    references auth.users (id) on delete cascade default auth.uid(),
  add column if not exists customer_name text,
  add column if not exists customer_phone text,
  add column if not exists status text not null default 'open',
  add column if not exists last_message text,
  add column if not exists unread_admin_count integer not null default 0,
  add column if not exists created_at timestamptz not null default now(),
  add column if not exists updated_at timestamptz not null default now();

do $$
begin
  if not exists (
    select 1 from pg_constraint
    where conrelid = 'public.support_chats'::regclass
      and conname = 'support_chats_status_check'
  ) then
    alter table public.support_chats add constraint support_chats_status_check
      check (status in ('open', 'closed'));
  end if;
end;
$$;

-- Find-or-create in the app relies on this: a second insert for the same
-- customer fails instead of opening a duplicate chat.
create unique index if not exists support_chats_one_open_per_user
  on public.support_chats (user_id) where status = 'open';
create index if not exists support_chats_status_updated_idx
  on public.support_chats (status, updated_at desc);

create table if not exists public.support_messages (
  id uuid primary key default gen_random_uuid()
);

alter table public.support_messages
  add column if not exists chat_id uuid
    references public.support_chats (id) on delete cascade,
  add column if not exists sender_id uuid
    references auth.users (id) on delete set null default auth.uid(),
  add column if not exists sender_role text not null default 'customer',
  add column if not exists message text,
  add column if not exists created_at timestamptz not null default now();

do $$
begin
  if not exists (
    select 1 from pg_constraint
    where conrelid = 'public.support_messages'::regclass
      and conname = 'support_messages_sender_role_check'
  ) then
    alter table public.support_messages
      add constraint support_messages_sender_role_check
      check (sender_role in ('customer', 'admin'));
  end if;
  if not exists (
    select 1 from pg_constraint
    where conrelid = 'public.support_messages'::regclass
      and conname = 'support_messages_message_check'
  ) then
    alter table public.support_messages
      add constraint support_messages_message_check
      check (length(btrim(message)) between 1 and 2000) not valid;
  end if;
end;
$$;

create index if not exists support_messages_chat_created_idx
  on public.support_messages (chat_id, created_at);

-- 1. Row level security.
alter table public.support_chats enable row level security;
alter table public.support_messages enable row level security;

drop policy if exists "support_chats_select" on public.support_chats;
create policy "support_chats_select" on public.support_chats
  for select to authenticated
  using (user_id = (select auth.uid()) or public.is_order_taker());

drop policy if exists "support_chats_insert_own" on public.support_chats;
create policy "support_chats_insert_own" on public.support_chats
  for insert to authenticated
  with check (
    user_id = (select auth.uid())
    and status = 'open'
    and unread_admin_count = 0
  );

-- Staff mark chats read (unread_admin_count = 0) and close them.
drop policy if exists "support_chats_update_staff" on public.support_chats;
create policy "support_chats_update_staff" on public.support_chats
  for update to authenticated
  using (public.is_order_taker())
  with check (public.is_order_taker());

drop policy if exists "support_messages_select" on public.support_messages;
create policy "support_messages_select" on public.support_messages
  for select to authenticated
  using (
    public.is_order_taker()
    or exists (
      select 1 from public.support_chats c
      where c.id = chat_id and c.user_id = (select auth.uid())
    )
  );

drop policy if exists "support_messages_insert" on public.support_messages;
create policy "support_messages_insert" on public.support_messages
  for insert to authenticated
  with check (
    sender_id = (select auth.uid())
    and (
      (
        sender_role = 'customer'
        and exists (
          select 1 from public.support_chats c
          where c.id = chat_id
            and c.user_id = (select auth.uid())
            and c.status = 'open'
        )
      )
      or (sender_role = 'admin' and public.is_order_taker())
    )
  );

revoke update, delete on public.support_messages from anon, authenticated;
revoke delete on public.support_chats from anon, authenticated;

-- 2. Every message updates its chat for the dashboard list and badges.
create or replace function public.support_messages_touch_chat()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  update public.support_chats
  set last_message = left(new.message, 300),
      updated_at = now(),
      unread_admin_count = case
        when new.sender_role = 'customer' then unread_admin_count + 1
        else 0
      end
  where id = new.chat_id;
  return new;
end;
$$;

drop trigger if exists support_messages_touch_chat on public.support_messages;
create trigger support_messages_touch_chat
  after insert on public.support_messages
  for each row execute function public.support_messages_touch_chat();

-- 3. Realtime: the chat screen streams messages, the dashboard streams
--    chats. Realtime checks RLS against the full row.
do $$
begin
  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'support_chats'
  ) then
    alter publication supabase_realtime add table public.support_chats;
  end if;
  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'support_messages'
  ) then
    alter publication supabase_realtime add table public.support_messages;
  end if;
end;
$$;

alter table public.support_chats replica identity full;
alter table public.support_messages replica identity full;

notify pgrst, 'reload schema';
