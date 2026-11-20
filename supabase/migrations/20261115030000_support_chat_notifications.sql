-- Support chat notifications + client receipt UPDATEs.
-- Safe to re-run in the Supabase SQL Editor.

-- 1. Allow type = 'support_chat' on app_notifications ---------------------------
alter table public.app_notifications
  drop constraint if exists app_notifications_type_check;

alter table public.app_notifications
  add constraint app_notifications_type_check
  check (type in ('general', 'promo', 'magazine', 'order', 'support_chat'));

-- 2. Compatibility alias (optional column; app prefers unread_customer_count) -
alter table public.support_chats
  add column if not exists unread_user_count integer not null default 0;

-- Keep unread_user_count mirrored with unread_customer_count.
create or replace function public.support_chats_mirror_user_unread()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  new.unread_user_count := coalesce(new.unread_customer_count, 0);
  return new;
end;
$$;

drop trigger if exists support_chats_mirror_user_unread on public.support_chats;
create trigger support_chats_mirror_user_unread
  before insert or update of unread_customer_count on public.support_chats
  for each row execute function public.support_chats_mirror_user_unread();

update public.support_chats
set unread_user_count = coalesce(unread_customer_count, 0)
where unread_user_count is distinct from coalesce(unread_customer_count, 0);

-- 3. Client may UPDATE receipt columns on messages they can see ----------------
grant update (status, is_read) on public.support_messages to authenticated;

drop policy if exists "support_messages_update_receipts" on public.support_messages;
create policy "support_messages_update_receipts" on public.support_messages
  for update to authenticated
  using (
    public.is_order_taker()
    or exists (
      select 1 from public.support_chats c
      where c.id = chat_id and c.user_id = (select auth.uid())
    )
  )
  with check (
    public.is_order_taker()
    or exists (
      select 1 from public.support_chats c
      where c.id = chat_id and c.user_id = (select auth.uid())
    )
  );

-- Customers may clear their own unread badge; staff keep full chat updates.
drop policy if exists "support_chats_update_own_unread" on public.support_chats;
create policy "support_chats_update_own_unread" on public.support_chats
  for update to authenticated
  using (user_id = (select auth.uid()))
  with check (user_id = (select auth.uid()));

-- 4. Admin reply → targeted app_notifications row (bell + deep link) ----------
create or replace function public.notify_customer_of_support_reply()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user_id uuid;
  v_preview text;
begin
  if new.sender_role is distinct from 'admin' then
    return new;
  end if;

  select c.user_id into v_user_id
  from public.support_chats c
  where c.id = new.chat_id;

  if v_user_id is null then
    return new;
  end if;

  v_preview := case
    when new.attachment_type = 'image' then '📷 صورة'
    when new.attachment_type = 'voice' then '🎤 رسالة صوتية'
    when new.attachment_type = 'order' then left(coalesce(new.message, 'بخصوص طلب'), 120)
    else left(coalesce(new.message, 'رسالة جديدة من خدمة العملاء'), 120)
  end;

  insert into public.app_notifications (title, body, type, target_user_id)
  values (
    'رد من خدمة العملاء',
    nullif(btrim(v_preview), ''),
    'support_chat',
    v_user_id
  );

  return new;
end;
$$;

drop trigger if exists support_messages_notify_customer on public.support_messages;
create trigger support_messages_notify_customer
  after insert on public.support_messages
  for each row execute function public.notify_customer_of_support_reply();

notify pgrst, 'reload schema';
