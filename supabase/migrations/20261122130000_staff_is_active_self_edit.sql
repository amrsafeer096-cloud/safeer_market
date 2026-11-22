-- Staff is_active + profile link; login rejects disabled accounts; disable
-- toggles stay in sync between profiles and staff. Safe to re-run.

alter table public.staff
  add column if not exists is_active boolean not null default true,
  add column if not exists profile_id uuid references public.profiles (id)
    on delete set null;

create index if not exists staff_profile_id_idx
  on public.staff (profile_id)
  where profile_id is not null;

-- Link the seeded admin staff row to the first admin profile when possible.
update public.staff s
set profile_id = p.id
from (
  select id from public.profiles
  where role = 'admin' and not coalesce(staff_disabled, false)
  limit 1
) p
where lower(s.username) = 'admin'
  and s.profile_id is null;

-- OUT columns changed: must drop before recreate.
drop function if exists public.admin_list_dashboard_users();

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

  if not coalesce(row.is_active, true) then
    raise exception 'account_disabled' using errcode = '42501';
  end if;

  if row.profile_id is not null then
    select coalesce(p.staff_disabled, false) into profile_disabled
    from public.profiles p
    where p.id = row.profile_id;
    if coalesce(profile_disabled, false) then
      raise exception 'account_disabled' using errcode = '42501';
    end if;
  end if;

  id := row.id;
  name := row.name;
  role := public._staff_normalize_role(row.role);
  phone := row.phone;
  username := row.username;
  return next;
end;
$$;

-- Dashboard user list includes linked staff login fields.
create or replace function public.admin_list_dashboard_users()
returns table (
  id uuid,
  full_name text,
  phone text,
  email text,
  role text,
  is_disabled boolean,
  staff_id uuid,
  staff_username text,
  staff_phone text
)
language plpgsql
stable
security definer
set search_path = ''
as $$
begin
  if not public.has_permission('manage_users') then
    raise exception 'forbidden' using errcode = '42501';
  end if;

  return query
  select
    p.id,
    p.full_name::text,
    coalesce(s.phone, p.phone)::text,
    u.email::text,
    case when p.staff_disabled
         then coalesce(p.disabled_role, 'cashier')
         else p.role::text end,
    p.staff_disabled,
    s.id,
    s.username::text,
    s.phone::text
  from public.profiles p
  left join auth.users u on u.id = p.id
  left join lateral (
    select st.id, st.username, st.phone
    from public.staff st
    where st.profile_id = p.id
       or (lower(st.username) = 'admin' and p.role = 'admin')
    order by case when st.profile_id = p.id then 0 else 1 end
    limit 1
  ) s on true
  where p.role in ('admin', 'warehouse', 'cashier') or p.staff_disabled
  order by p.staff_disabled, p.full_name nulls last;
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
set search_path = ''
as $$
declare
  target public.profiles;
  new_role text := lower(btrim(coalesce(p_role, '')));
  new_name text := nullif(btrim(coalesce(p_full_name, '')), '');
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

  perform set_config('app.role_change_allowed', 'on', true);

  if p_disabled then
    update public.profiles
    set role = 'customer',
        disabled_role = case
          when target.role in ('admin', 'warehouse', 'cashier') then target.role
          else coalesce(target.disabled_role, new_role)
        end,
        staff_disabled = true,
        full_name = coalesce(new_name, full_name)
    where id = p_user_id;
  else
    update public.profiles
    set role = new_role,
        staff_disabled = false,
        disabled_role = null,
        full_name = coalesce(new_name, full_name)
    where id = p_user_id;
  end if;

  -- Keep staff login credentials in sync with the profile disable flag.
  update public.staff
  set is_active = not p_disabled
  where profile_id = p_user_id
     or (lower(username) = 'admin' and new_role = 'admin'
         and exists (
           select 1 from public.profiles pr
           where pr.id = p_user_id and pr.role = 'admin'
         ));

  perform set_config('app.role_change_allowed', 'off', true);
end;
$$;

create or replace function public.admin_add_staff(
  p_name text,
  p_role text,
  p_phone text default null,
  p_username text default null,
  p_password text default null,
  p_profile_id uuid default null
)
returns uuid
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  staff_role text := public._staff_normalize_role(p_role);
  new_id uuid;
  uname text := lower(btrim(coalesce(p_username, '')));
begin
  if staff_role is null then
    raise exception 'invalid_role' using errcode = '22023';
  end if;

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

  if btrim(coalesce(p_name, '')) = '' then
    raise exception 'name_required' using errcode = '22023';
  end if;
  if not public._staff_valid_phone(p_phone) then
    raise exception 'invalid_phone' using errcode = '22023';
  end if;
  if uname = '' or length(uname) < 3 then
    raise exception 'username_required' using errcode = '22023';
  end if;
  if coalesce(p_password, '') = '' or length(p_password) < 4 then
    raise exception 'password_required' using errcode = '22023';
  end if;

  insert into public.staff (
    name, role, phone, username, password_hash, is_active, profile_id
  )
  values (
    btrim(p_name),
    staff_role,
    btrim(p_phone),
    uname,
    public._staff_hash_password(p_password),
    true,
    p_profile_id
  )
  returning id into new_id;

  return new_id;
end;
$$;

create or replace function public.admin_update_staff(
  p_id text,
  p_name text default null,
  p_phone text default null,
  p_username text default null,
  p_password text default null
)
returns void
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  staff_role text;
  staff_profile uuid;
  uname text;
  is_self boolean := false;
begin
  select s.role, s.profile_id
    into staff_role, staff_profile
  from public.staff s where s.id::text = p_id;
  if not found then
    raise exception 'staff_not_found' using errcode = '22023';
  end if;

  staff_role := public._staff_normalize_role(staff_role);
  is_self := staff_profile is not null and staff_profile = auth.uid();

  -- Own credentials, or manage_* permission for that staff role.
  if not is_self then
    if staff_role in ('preparer', 'driver') then
      if not public.has_permission(
           case staff_role when 'preparer' then 'manage_preparers'
                           else 'manage_drivers' end) then
        raise exception 'forbidden' using errcode = '42501';
      end if;
    else
      if not public.has_permission('manage_users')
         and not (public.is_admin() and staff_role = 'admin') then
        raise exception 'forbidden' using errcode = '42501';
      end if;
    end if;
  end if;

  if p_phone is not null and not public._staff_valid_phone(p_phone) then
    raise exception 'invalid_phone' using errcode = '22023';
  end if;

  if p_username is not null then
    uname := lower(btrim(p_username));
    if uname = '' or length(uname) < 3 then
      raise exception 'username_required' using errcode = '22023';
    end if;
  end if;

  if p_password is not null and (p_password = '' or length(p_password) < 4) then
    raise exception 'password_required' using errcode = '22023';
  end if;

  update public.staff s
  set
    name = coalesce(nullif(btrim(coalesce(p_name, '')), ''), s.name),
    phone = case
      when p_phone is null then s.phone
      else btrim(p_phone)
    end,
    username = case
      when p_username is null then s.username
      else uname
    end,
    password_hash = case
      when p_password is null or p_password = '' then s.password_hash
      else public._staff_hash_password(p_password)
    end
  where s.id::text = p_id;
end;
$$;

-- Enable / disable preparers and drivers (and any staff row) for login.
create or replace function public.admin_set_staff_active(
  p_id text,
  p_active boolean
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  staff_role text;
  staff_profile uuid;
begin
  select s.role, s.profile_id into staff_role, staff_profile
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

  if staff_profile is not null then
    perform set_config('app.role_change_allowed', 'on', true);
    if not coalesce(p_active, true) then
      update public.profiles
      set staff_disabled = true,
          disabled_role = case
            when role in ('admin', 'warehouse', 'cashier') then role
            else coalesce(disabled_role, 'cashier')
          end,
          role = case
            when role in ('admin', 'warehouse', 'cashier') then 'customer'
            else role
          end
      where id = staff_profile
        and id <> auth.uid();
    else
      update public.profiles
      set staff_disabled = false,
          role = coalesce(disabled_role, role),
          disabled_role = null
      where id = staff_profile
        and id <> auth.uid()
        and staff_disabled;
    end if;
    perform set_config('app.role_change_allowed', 'off', true);
  end if;
end;
$$;

drop function if exists public.admin_add_staff(text, text, text, text, text);

revoke all on function public.staff_login(text, text) from public, anon;
revoke all on function public.admin_list_dashboard_users() from public, anon;
revoke all on function public.admin_set_user_role(uuid, text, text, boolean)
  from public, anon;
revoke all on function public.admin_add_staff(text, text, text, text, text, uuid)
  from public, anon;
revoke all on function public.admin_update_staff(text, text, text, text, text)
  from public, anon;
revoke all on function public.admin_set_staff_active(text, boolean)
  from public, anon;

grant execute on function public.staff_login(text, text) to authenticated;
grant execute on function public.admin_list_dashboard_users() to authenticated;
grant execute on function public.admin_set_user_role(uuid, text, text, boolean)
  to authenticated;
grant execute on function public.admin_add_staff(text, text, text, text, text, uuid)
  to authenticated;
grant execute on function public.admin_update_staff(text, text, text, text, text)
  to authenticated;
grant execute on function public.admin_set_staff_active(text, boolean)
  to authenticated;

notify pgrst, 'reload schema';
