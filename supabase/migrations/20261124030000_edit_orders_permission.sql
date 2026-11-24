-- Add granular «تعديل الطلبات» (edit_orders) to dashboard permissions.
-- Safe to re-run.
-- Defaults: cashiers (متلقي طلبات) get it ON; warehouse (تحضير) stay OFF.
-- Real admins always have every key via is_admin() / my_permissions().

create or replace function public.all_admin_permissions()
returns text[]
language sql
immutable
as $$
  select array[
    -- Navigation / screens
    'receive_orders',
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

-- Default ON for call-center / taker accounts (profiles.role = cashier).
-- Does not grant to warehouse (preparer-like) or drivers.
insert into public.admin_permissions (user_id, permissions, updated_by)
select
  p.id,
  array['edit_orders']::text[],
  null
from public.profiles p
where p.role = 'cashier'
  and coalesce(p.staff_disabled, false) = false
  and not exists (
    select 1 from public.admin_permissions a where a.user_id = p.id
  );

update public.admin_permissions a
set permissions = (
  select coalesce(array_agg(distinct x order by x), '{}'::text[])
  from unnest(
    coalesce(a.permissions, '{}'::text[]) || array['edit_orders']::text[]
  ) as x
  where x = any (public.all_admin_permissions())
),
updated_at = timezone('utc', now())
where exists (
  select 1
  from public.profiles p
  where p.id = a.user_id
    and p.role = 'cashier'
    and coalesce(p.staff_disabled, false) = false
)
and not ('edit_orders' = any (coalesce(a.permissions, '{}'::text[])));

notify pgrst, 'reload schema';
