-- In-app notifications: the bell on the home screen and «الإشعارات».
--
-- Administrators broadcast from «إرسال إشعارات» on the dashboard
-- (target_user_id null = every customer, guests included); a row with a
-- target_user_id is for that customer only. Each device remembers when it
-- last opened the list (last_read_notifications_at), so there is no
-- per-user read state here. Safe to re-run, and upgrades a table created
-- by hand.

create table if not exists public.app_notifications (
  id uuid primary key default gen_random_uuid()
);

alter table public.app_notifications
  add column if not exists title text not null default '',
  add column if not exists body text not null default '',
  add column if not exists type text not null default 'general',
  add column if not exists image_url text,
  add column if not exists target_user_id uuid
    references auth.users (id) on delete cascade,
  add column if not exists created_by uuid
    references auth.users (id) on delete set null default auth.uid(),
  add column if not exists created_at timestamptz not null default now();

do $$
begin
  if not exists (
    select 1 from pg_constraint
    where conrelid = 'public.app_notifications'::regclass
      and conname = 'app_notifications_type_check'
  ) then
    alter table public.app_notifications
      add constraint app_notifications_type_check
      check (type in ('general', 'promo', 'magazine', 'order')) not valid;
  end if;
  if not exists (
    select 1 from pg_constraint
    where conrelid = 'public.app_notifications'::regclass
      and conname = 'app_notifications_title_check'
  ) then
    alter table public.app_notifications
      add constraint app_notifications_title_check
      check (length(btrim(title)) between 1 and 120) not valid;
  end if;
end;
$$;

create index if not exists app_notifications_created_idx
  on public.app_notifications (created_at desc);
create index if not exists app_notifications_target_created_idx
  on public.app_notifications (target_user_id, created_at desc);

alter table public.app_notifications enable row level security;

grant select on public.app_notifications to anon, authenticated;
grant insert, delete on public.app_notifications to authenticated;
revoke update on public.app_notifications from anon, authenticated;

-- Broadcasts for everyone, targeted rows for their customer; admins see
-- all of them for the history on the dashboard.
drop policy if exists "app_notifications_select" on public.app_notifications;
create policy "app_notifications_select" on public.app_notifications
  for select to anon, authenticated
  using (
    target_user_id is null
    or target_user_id = (select auth.uid())
    or public.is_admin()
  );

drop policy if exists "app_notifications_admin_insert" on public.app_notifications;
create policy "app_notifications_admin_insert" on public.app_notifications
  for insert to authenticated
  with check (public.is_admin());

drop policy if exists "app_notifications_admin_delete" on public.app_notifications;
create policy "app_notifications_admin_delete" on public.app_notifications
  for delete to authenticated
  using (public.is_admin());

-- The bell's red dot and the list update live. Realtime checks RLS against
-- the full row, and deletes must carry it to leave the list.
do $$
begin
  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'app_notifications'
  ) then
    alter publication supabase_realtime add table public.app_notifications;
  end if;
end;
$$;

alter table public.app_notifications replica identity full;

notify pgrst, 'reload schema';
