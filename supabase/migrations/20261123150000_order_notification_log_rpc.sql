-- Order notifications for the customer bell («الإشعارات»).
-- Adds order_id + source, and a SECURITY DEFINER RPC so staff / Edge
-- Functions can always log a row even when RLS blocks direct inserts.
-- Safe to re-run.

alter table public.app_notifications
  add column if not exists order_id uuid
    references public.orders (id) on delete set null,
  add column if not exists source text;

create index if not exists app_notifications_order_idx
  on public.app_notifications (order_id)
  where order_id is not null;

-- Keep type check in sync (loyalty was added earlier; include order).
alter table public.app_notifications
  drop constraint if exists app_notifications_type_check;

alter table public.app_notifications
  add constraint app_notifications_type_check
  check (type in (
    'general', 'promo', 'magazine', 'order', 'support_chat', 'loyalty'
  ));

create or replace function public.log_customer_order_notification(
  p_user_id uuid,
  p_title text,
  p_body text,
  p_order_id uuid default null,
  p_type text default 'order',
  p_source text default null
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  new_id uuid;
  safe_type text := coalesce(nullif(btrim(p_type), ''), 'order');
  safe_title text := left(btrim(coalesce(p_title, '')), 120);
  safe_body text := btrim(coalesce(p_body, ''));
begin
  if p_user_id is null then
    raise exception 'user_id_required' using errcode = '22023';
  end if;
  if safe_title = '' then
    raise exception 'title_required' using errcode = '22023';
  end if;
  if safe_type not in (
    'general', 'promo', 'magazine', 'order', 'support_chat', 'loyalty'
  ) then
    safe_type := 'order';
  end if;

  insert into public.app_notifications (
    title, body, type, target_user_id, order_id, source
  ) values (
    safe_title,
    safe_body,
    safe_type,
    p_user_id,
    p_order_id,
    nullif(btrim(coalesce(p_source, '')), '')
  )
  returning id into new_id;

  return new_id;
end;
$$;

revoke all on function public.log_customer_order_notification(
  uuid, text, text, uuid, text, text
) from public, anon;

grant execute on function public.log_customer_order_notification(
  uuid, text, text, uuid, text, text
) to authenticated, service_role;

notify pgrst, 'reload schema';
