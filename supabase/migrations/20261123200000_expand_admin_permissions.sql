-- Expand dashboard step permissions (menus + actions) for «الصلاحيات».
-- Safe to re-run. Existing granted keys are kept; new keys start off until
-- an admin enables them (except real admins who always have all).

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
    'send_alternatives'
  ]::text[];
$$;

notify pgrst, 'reload schema';
