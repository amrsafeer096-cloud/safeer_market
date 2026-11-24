-- Add «تحديد رسوم التوصيل» (can_set_delivery_fee) and load a staff
-- member's linked profile permissions for the dashboard (staff login is
-- separate from auth.uid(), so my_permissions() alone is not enough).
-- Safe to re-run.

create or replace function public.all_admin_permissions()
returns text[]
language sql
immutable
as $$
  select array[
    -- Navigation / screens
    'receive_orders',
    'can_set_delivery_fee',
    'order_status',
    'search_orders',
    'view_reports',
    'export_reports',
    'manage_system',
    'manage_products',
    'manage_magazines',
    'manage_support',
    'send_notifications',
    'approve_subscriptions',
    -- System management
    'manage_customers',
    'delete_customers',
    'manage_preparers',
    'manage_drivers',
    'manage_users',
    'manage_zones',
    -- Order workflow actions
    'start_prep',
    'finish_prep',
    'assign_driver',
    'cancel_order',
    'send_alternatives',
    'edit_orders'
  ]::text[];
$$;

-- Permissions for a staff-login row (by linked / matched profile), not
-- auth.uid(). Staff admins always receive the full allow-list. Matching
-- mirrors staff_login (profile_id, phone, or username ≈ email local-part).
create or replace function public.staff_member_permissions(p_staff_id uuid)
returns text[]
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  staff_role text;
  linked uuid;
  staff_phone text;
  staff_username text;
  matched uuid;
  matched_role text;
begin
  if auth.uid() is null then
    raise exception 'not_signed_in' using errcode = '28000';
  end if;

  select
    public._staff_normalize_role(s.role),
    s.profile_id,
    s.phone,
    s.username
  into staff_role, linked, staff_phone, staff_username
  from public.staff s
  where s.id = p_staff_id;

  if not found then
    return '{}'::text[];
  end if;

  if staff_role = 'admin' then
    return public.all_admin_permissions();
  end if;

  select p.id, p.role
    into matched, matched_role
  from public.profiles p
  left join auth.users u on u.id = p.id
  where p.id = linked
     or (staff_phone is not null
         and nullif(btrim(staff_phone), '') is not null
         and nullif(btrim(coalesce(p.phone, '')), '') = btrim(staff_phone))
     or lower(coalesce(u.email, '')) = lower(btrim(coalesce(staff_username, '')))
     or lower(split_part(coalesce(u.email, ''), '@', 1))
          = lower(btrim(coalesce(staff_username, '')))
  order by case when p.id = linked then 0 else 1 end
  limit 1;

  if matched is not null
     and matched_role = 'admin'
     and exists (
       select 1
       from public.profiles p
       where p.id = matched
         and coalesce(p.staff_disabled, false) = false
     ) then
    return public.all_admin_permissions();
  end if;

  if matched is null then
    return '{}'::text[];
  end if;

  return coalesce(
    (
      select a.permissions
      from public.admin_permissions a
      where a.user_id = matched
    ),
    '{}'::text[]
  );
end;
$$;

revoke all on function public.staff_member_permissions(uuid) from public, anon;
grant execute on function public.staff_member_permissions(uuid) to authenticated;

notify pgrst, 'reload schema';
