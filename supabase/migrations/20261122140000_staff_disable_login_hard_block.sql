-- Hard-block disabled staff from Staff Login.
-- Disable in «المستخدمين» must flip staff.is_active AND profiles.is_active
-- (and staff_disabled) even when profile_id was never linked — match by
-- phone / email / username too. Safe to re-run; paste into SQL Editor if needed.

alter table public.staff
  add column if not exists is_active boolean not null default true,
  add column if not exists profile_id uuid references public.profiles (id)
    on delete set null;

alter table public.profiles
  add column if not exists is_active boolean not null default true;

-- Keep existing disabled profiles marked inactive.
update public.profiles
set is_active = false
where coalesce(staff_disabled, false) = true
  and coalesce(is_active, true) = true;

create or replace function public.staff_login(
  p_username text,
  p_password text
)
returns table (
  id uuid,
  name text,
  role text,
  phone text,
  username text
)
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  row public.staff%rowtype;
  profile_disabled boolean := false;
begin
  if auth.uid() is null then
    raise exception 'not_signed_in' using errcode = '28000';
  end if;
  if btrim(coalesce(p_username, '')) = '' or coalesce(p_password, '') = '' then
    raise exception 'invalid_credentials' using errcode = '22023';
  end if;

  select * into row
  from public.staff s
  where lower(s.username) = lower(btrim(p_username))
  limit 1;

  if not found
     or not public._staff_password_matches(p_password, row.password_hash) then
    raise exception 'invalid_credentials' using errcode = '22023';
  end if;

  -- Strict staff flag first.
  if coalesce(row.is_active, true) = false then
    raise exception 'account_disabled' using errcode = '42501';
  end if;

  -- Linked / matching profile (id, phone, or email local-part = username).
  select coalesce(p.staff_disabled, false)
           or coalesce(p.is_active, true) = false
    into profile_disabled
  from public.profiles p
  left join auth.users u on u.id = p.id
  where p.id = row.profile_id
     or (row.phone is not null
         and nullif(btrim(row.phone), '') is not null
         and nullif(btrim(coalesce(p.phone, '')), '') = btrim(row.phone))
     or lower(coalesce(u.email, '')) = lower(btrim(p_username))
     or lower(split_part(coalesce(u.email, ''), '@', 1))
          = lower(btrim(p_username))
  order by case when p.id = row.profile_id then 0 else 1 end
  limit 1;

  if coalesce(profile_disabled, false) then
    raise exception 'account_disabled' using errcode = '42501';
  end if;

  id := row.id;
  name := row.name;
  role := public._staff_normalize_role(row.role);
  phone := row.phone;
  username := row.username;
  return next;
end;
$$;

create or replace function public.admin_set_user_role(
  p_user_id uuid,
  p_role text,
  p_full_name text default null,
  p_disabled boolean default false
)
returns void
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  target public.profiles;
  new_role text := lower(btrim(coalesce(p_role, '')));
  new_name text := nullif(btrim(coalesce(p_full_name, '')), '');
  user_email text;
  user_phone text;
  email_local text;
begin
  if not public.has_permission('manage_users') then
    raise exception 'forbidden' using errcode = '42501';
  end if;
  if p_user_id = auth.uid() then
    raise exception 'cannot_change_self' using errcode = '42501';
  end if;
  if new_role not in ('admin', 'warehouse', 'cashier') then
    raise exception 'invalid_role' using errcode = '22023';
  end if;

  select * into target from public.profiles where id = p_user_id for update;
  if not found then
    raise exception 'user_not_found' using errcode = '22023';
  end if;

  if (new_role = 'admin' or target.role = 'admin'
      or target.disabled_role = 'admin')
     and not public.is_admin() then
    raise exception 'admin_required' using errcode = '42501';
  end if;

  select u.email into user_email from auth.users u where u.id = p_user_id;
  user_phone := nullif(btrim(coalesce(target.phone, '')), '');
  email_local := nullif(lower(split_part(coalesce(user_email, ''), '@', 1)), '');

  perform set_config('app.role_change_allowed', 'on', true);

  if p_disabled then
    update public.profiles
    set role = 'customer',
        disabled_role = case
          when target.role in ('admin', 'warehouse', 'cashier') then target.role
          else coalesce(target.disabled_role, new_role)
        end,
        staff_disabled = true,
        is_active = false,
        full_name = coalesce(new_name, full_name)
    where id = p_user_id;
  else
    update public.profiles
    set role = new_role,
        staff_disabled = false,
        disabled_role = null,
        is_active = true,
        full_name = coalesce(new_name, full_name)
    where id = p_user_id;
  end if;

  -- Sync EVERY matching staff login row (no profile_id mismatch escapes).
  update public.staff s
  set
    is_active = not p_disabled,
    profile_id = coalesce(s.profile_id, p_user_id)
  where s.profile_id = p_user_id
     or (user_phone is not null
         and nullif(btrim(coalesce(s.phone, '')), '') = user_phone)
     or (email_local is not null and lower(s.username) = email_local)
     or (user_email is not null and lower(s.username) = lower(user_email))
     or exists (
          select 1
          from public.staff linked
          where linked.id = s.id
            and linked.profile_id = p_user_id
        );

  perform set_config('app.role_change_allowed', 'off', true);
end;
$$;

create or replace function public.admin_set_staff_active(
  p_id text,
  p_active boolean
)
returns void
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  staff_role text;
  staff_profile uuid;
  staff_phone text;
  staff_username text;
begin
  select s.role, s.profile_id, s.phone, s.username
    into staff_role, staff_profile, staff_phone, staff_username
  from public.staff s where s.id::text = p_id;
  if not found then
    raise exception 'staff_not_found' using errcode = '22023';
  end if;

  staff_role := public._staff_normalize_role(staff_role);
  if staff_role in ('preparer', 'driver') then
    if not public.has_permission(
         case staff_role when 'preparer' then 'manage_preparers'
                         else 'manage_drivers' end) then
      raise exception 'forbidden' using errcode = '42501';
    end if;
  else
    if not public.has_permission('manage_users') then
      raise exception 'forbidden' using errcode = '42501';
    end if;
  end if;

  update public.staff
  set is_active = coalesce(p_active, true)
  where id::text = p_id;

  perform set_config('app.role_change_allowed', 'on', true);

  if not coalesce(p_active, true) then
    update public.profiles p
    set staff_disabled = true,
        is_active = false,
        disabled_role = case
          when p.role in ('admin', 'warehouse', 'cashier') then p.role
          else coalesce(p.disabled_role, 'cashier')
        end,
        role = case
          when p.role in ('admin', 'warehouse', 'cashier') then 'customer'
          else p.role
        end
    where p.id <> auth.uid()
      and (
        p.id = staff_profile
        or (staff_phone is not null
            and nullif(btrim(coalesce(p.phone, '')), '') = btrim(staff_phone))
        or exists (
          select 1 from auth.users u
          where u.id = p.id
            and (
              lower(split_part(coalesce(u.email, ''), '@', 1))
                = lower(coalesce(staff_username, ''))
              or lower(coalesce(u.email, '')) = lower(coalesce(staff_username, ''))
            )
        )
      );
  else
    update public.profiles p
    set staff_disabled = false,
        is_active = true,
        role = coalesce(nullif(p.disabled_role, ''), p.role),
        disabled_role = null
    where p.id <> auth.uid()
      and p.staff_disabled
      and (
        p.id = staff_profile
        or (staff_phone is not null
            and nullif(btrim(coalesce(p.phone, '')), '') = btrim(staff_phone))
        or exists (
          select 1 from auth.users u
          where u.id = p.id
            and (
              lower(split_part(coalesce(u.email, ''), '@', 1))
                = lower(coalesce(staff_username, ''))
              or lower(coalesce(u.email, '')) = lower(coalesce(staff_username, ''))
            )
        )
      );
  end if;

  perform set_config('app.role_change_allowed', 'off', true);
end;
$$;

revoke all on function public.staff_login(text, text) from public, anon;
revoke all on function public.admin_set_user_role(uuid, text, text, boolean)
  from public, anon;
revoke all on function public.admin_set_staff_active(text, boolean)
  from public, anon;

grant execute on function public.staff_login(text, text) to authenticated;
grant execute on function public.admin_set_user_role(uuid, text, text, boolean)
  to authenticated;
grant execute on function public.admin_set_staff_active(text, boolean)
  to authenticated;

notify pgrst, 'reload schema';
