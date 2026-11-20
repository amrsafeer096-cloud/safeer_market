-- Align receipt RPCs with the app: both take p_viewer_role ('admin' | 'customer').
-- Safe to re-run in the Supabase SQL Editor.

-- Drop older single-arg versions if present.
drop function if exists public.mark_support_messages_delivered(uuid);
drop function if exists public.mark_support_chat_read(uuid);
drop function if exists public.mark_support_messages_read(uuid);
drop function if exists public.mark_support_messages_delivered(uuid, text);
drop function if exists public.mark_support_messages_read(uuid, text);

create or replace function public.mark_support_messages_delivered(
  p_chat_id uuid,
  p_viewer_role text
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  if p_viewer_role not in ('admin', 'customer') then
    raise exception 'invalid_role' using errcode = '22023';
  end if;

  if p_viewer_role = 'admin' then
    if not public.is_order_taker() then
      raise exception 'not_allowed' using errcode = '42501';
    end if;
  else
    if not exists (
      select 1 from public.support_chats c
      where c.id = p_chat_id and c.user_id = auth.uid()
    ) then
      raise exception 'not_allowed' using errcode = '42501';
    end if;
  end if;

  update public.support_messages
  set status = 'delivered'
  where chat_id = p_chat_id
    and sender_role is distinct from p_viewer_role
    and status = 'sent';
end;
$$;

create or replace function public.mark_support_messages_read(
  p_chat_id uuid,
  p_viewer_role text
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  if p_viewer_role not in ('admin', 'customer') then
    raise exception 'invalid_role' using errcode = '22023';
  end if;

  if p_viewer_role = 'admin' then
    if not public.is_order_taker() then
      raise exception 'not_allowed' using errcode = '42501';
    end if;
  else
    if not exists (
      select 1 from public.support_chats c
      where c.id = p_chat_id and c.user_id = auth.uid()
    ) then
      raise exception 'not_allowed' using errcode = '42501';
    end if;
  end if;

  update public.support_messages
  set status = 'read', is_read = true
  where chat_id = p_chat_id
    and sender_role is distinct from p_viewer_role
    and (status is distinct from 'read' or is_read is distinct from true);

  if p_viewer_role = 'admin' then
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

revoke execute on function public.mark_support_messages_delivered(uuid, text)
  from public, anon;
grant execute on function public.mark_support_messages_delivered(uuid, text)
  to authenticated;
revoke execute on function public.mark_support_messages_read(uuid, text)
  from public, anon;
grant execute on function public.mark_support_messages_read(uuid, text)
  to authenticated;

notify pgrst, 'reload schema';
