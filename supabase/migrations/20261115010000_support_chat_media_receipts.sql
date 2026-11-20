-- Support chat upgrade: read receipts, attachments (image / order / voice),
-- unread_customer_count, and the support_media storage bucket.
-- Safe to re-run in the Supabase SQL Editor.

-- 1. Columns -----------------------------------------------------------------
alter table public.support_chats
  add column if not exists unread_customer_count integer not null default 0;

alter table public.support_messages
  add column if not exists status text not null default 'sent',
  add column if not exists is_read boolean not null default false,
  add column if not exists attachment_type text,
  add column if not exists attachment_url text,
  add column if not exists order_id uuid,
  add column if not exists voice_duration integer;

do $$
begin
  if not exists (
    select 1 from pg_constraint
    where conrelid = 'public.support_messages'::regclass
      and conname = 'support_messages_status_check'
  ) then
    alter table public.support_messages
      add constraint support_messages_status_check
      check (status in ('sent', 'delivered', 'read'));
  end if;
  if not exists (
    select 1 from pg_constraint
    where conrelid = 'public.support_messages'::regclass
      and conname = 'support_messages_attachment_type_check'
  ) then
    alter table public.support_messages
      add constraint support_messages_attachment_type_check
      check (
        attachment_type is null
        or attachment_type in ('image', 'order', 'voice')
      );
  end if;
end;
$$;

-- Allow empty message text when an attachment is present.
alter table public.support_messages
  drop constraint if exists support_messages_message_check;
alter table public.support_messages
  add constraint support_messages_message_check
  check (
    (
      message is not null
      and length(btrim(message)) between 1 and 2000
    )
    or attachment_type is not null
  );

-- 2. Trigger: preview text + unread counts -----------------------------------
create or replace function public.support_messages_touch_chat()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  preview text;
begin
  preview := case
    when new.attachment_type = 'image' then '📷 صورة'
    when new.attachment_type = 'voice' then '🎤 رسالة صوتية'
    when new.attachment_type = 'order' then left(coalesce(new.message, 'بخصوص طلب'), 300)
    else left(coalesce(new.message, ''), 300)
  end;

  update public.support_chats
  set last_message = nullif(btrim(preview), ''),
      updated_at = now(),
      unread_admin_count = case
        when new.sender_role = 'customer' then unread_admin_count + 1
        else unread_admin_count
      end,
      unread_customer_count = case
        when new.sender_role = 'admin' then unread_customer_count + 1
        else unread_customer_count
      end
  where id = new.chat_id;
  return new;
end;
$$;

drop trigger if exists support_messages_touch_chat on public.support_messages;
create trigger support_messages_touch_chat
  after insert on public.support_messages
  for each row execute function public.support_messages_touch_chat();

-- 3. RPCs for receipts -------------------------------------------------------
-- Mark the other party's 'sent' messages as 'delivered' when this side is
-- watching the chat.
create or replace function public.mark_support_messages_delivered(p_chat_id uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  my_role text;
begin
  if public.is_order_taker() then
    my_role := 'admin';
  elsif exists (
    select 1 from public.support_chats c
    where c.id = p_chat_id and c.user_id = auth.uid()
  ) then
    my_role := 'customer';
  else
    raise exception 'not_allowed' using errcode = '42501';
  end if;

  update public.support_messages
  set status = 'delivered'
  where chat_id = p_chat_id
    and sender_role is distinct from my_role
    and status = 'sent';
end;
$$;

-- Open the chat: mark the other party's messages read and clear unread.
create or replace function public.mark_support_chat_read(p_chat_id uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  my_role text;
begin
  if public.is_order_taker() then
    my_role := 'admin';
  elsif exists (
    select 1 from public.support_chats c
    where c.id = p_chat_id and c.user_id = auth.uid()
  ) then
    my_role := 'customer';
  else
    raise exception 'not_allowed' using errcode = '42501';
  end if;

  update public.support_messages
  set status = 'read', is_read = true
  where chat_id = p_chat_id
    and sender_role is distinct from my_role
    and (status is distinct from 'read' or is_read is distinct from true);

  if my_role = 'admin' then
    update public.support_chats
    set unread_admin_count = 0
    where id = p_chat_id and unread_admin_count > 0;
  else
    update public.support_chats
    set unread_customer_count = 0
    where id = p_chat_id and unread_customer_count > 0;
  end if;
end;
$$;

revoke execute on function public.mark_support_messages_delivered(uuid)
  from public, anon;
grant execute on function public.mark_support_messages_delivered(uuid)
  to authenticated;
revoke execute on function public.mark_support_chat_read(uuid)
  from public, anon;
grant execute on function public.mark_support_chat_read(uuid)
  to authenticated;

-- Customers may clear their own unread_customer_count (via the RPC above
-- as security definer). Staff update policy already covers admin.

-- 4. Storage bucket for images and voice notes -------------------------------
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'support_media',
  'support_media',
  true,
  15728640, -- 15 MB
  array[
    'image/jpeg', 'image/png', 'image/webp', 'image/gif',
    'audio/mpeg', 'audio/mp4', 'audio/webm', 'audio/ogg', 'audio/wav',
    'audio/x-m4a', 'audio/aac'
  ]
)
on conflict (id) do update set
  public = excluded.public,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

drop policy if exists "support_media_public_read" on storage.objects;
create policy "support_media_public_read" on storage.objects
  for select to public
  using (bucket_id = 'support_media');

drop policy if exists "support_media_auth_upload" on storage.objects;
create policy "support_media_auth_upload" on storage.objects
  for insert to authenticated
  with check (
    bucket_id = 'support_media'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

drop policy if exists "support_media_auth_update" on storage.objects;
create policy "support_media_auth_update" on storage.objects
  for update to authenticated
  using (
    bucket_id = 'support_media'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

drop policy if exists "support_media_auth_delete" on storage.objects;
create policy "support_media_auth_delete" on storage.objects
  for delete to authenticated
  using (
    bucket_id = 'support_media'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

notify pgrst, 'reload schema';
