-- Staff username / password login for the admin dashboard.
-- Adds credentials on public.staff, seeds a default admin, and exposes
-- login / add / update RPCs. Safe to re-run.

create extension if not exists pgcrypto with schema extensions;

alter table public.staff
  add column if not exists username text,
  add column if not exists password_hash text;

-- Unique usernames (nulls allowed for legacy rows until they are edited).
create unique index if not exists staff_username_unique
  on public.staff (lower(username))
  where username is not null and btrim(username) <> '';

-- Never expose password hashes to the client API.
revoke select (password_hash) on public.staff from authenticated, anon;

create or replace function public._staff_normalize_role(p_role text)
returns text
language sql
immutable
as $$
  select case lower(btrim(coalesce(p_role, '')))
    when 'admin' then 'admin'
    when 'taker' then 'taker'
    when 'cashier' then 'taker'
    when 'preparer' then 'preparer'
    when 'warehouse' then 'preparer'
    when 'driver' then 'driver'
    when 'delivery' then 'driver'
    else null
  end;
$$;

create or replace function public._staff_valid_phone(p_phone text)
returns boolean
language sql
immutable
as $$
  select coalesce(btrim(p_phone), '') ~ '^01[0125][0-9]{8}$';
$$;

create or replace function public._staff_hash_password(p_password text)
returns text
language sql
volatile
as $$
  select extensions.crypt(p_password, extensions.gen_salt('bf'));
$$;

create or replace function public._staff_password_matches(
  p_password text,
  p_hash text
)
returns boolean
language sql
immutable
as $$
  select p_hash is not null
    and p_password is not null
    and extensions.crypt(p_password, p_hash) = p_hash;
$$;

-- Default owner account so the dashboard is usable immediately.
insert into public.staff (name, role, phone, username, password_hash)
select
  'المدير',
  'admin',
  '01000000000',
  'admin',
  public._staff_hash_password('123456')
where not exists (
  select 1 from public.staff s where lower(s.username) = 'admin'
);

-- Login gate: verify username + password, return the staff row (no hash).
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

  id := row.id;
  name := row.name;
  role := public._staff_normalize_role(row.role);
  phone := row.phone;
  username := row.username;
  return next;
end;
$$;

create or replace function public.admin_add_staff(
  p_name text,
  p_role text,
  p_phone text default null,
  p_username text default null,
  p_password text default null
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
    -- admin / taker credentials are managed under «المستخدمين».
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

  insert into public.staff (name, role, phone, username, password_hash)
  values (
    btrim(p_name),
    staff_role,
    btrim(p_phone),
    uname,
    public._staff_hash_password(p_password)
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
  uname text;
begin
  select s.role into staff_role from public.staff s where s.id::text = p_id;
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

-- Keep delete, with role-aware permission for admin/taker rows.
create or replace function public.admin_delete_staff(p_id text)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  staff_role text;
begin
  select s.role into staff_role from public.staff s where s.id::text = p_id;
  if not found then
    raise exception 'staff_not_found' using errcode = '22023';
  end if;
  staff_role := public._staff_normalize_role(staff_role);
  if not public.has_permission(
       case staff_role
         when 'preparer' then 'manage_preparers'
         when 'driver' then 'manage_drivers'
         else 'manage_users'
       end) then
    raise exception 'forbidden' using errcode = '42501';
  end if;
  delete from public.staff s where s.id::text = p_id;
end;
$$;

-- Optional push-role override used when a staff member logs into the dashboard
-- on a shared device (admin / taker get new-order alerts).
create or replace function public.register_fcm_token(
  p_token text,
  p_platform text default 'android',
  p_role text default null
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user_id uuid := auth.uid();
  v_platform text := lower(coalesce(nullif(btrim(p_platform), ''), 'android'));
  v_role text;
begin
  if v_user_id is null then
    raise exception 'Not signed in' using errcode = '28000';
  end if;
  if p_token is null or length(btrim(p_token)) < 20 then
    raise exception 'Invalid token' using errcode = '22023';
  end if;
  if v_platform not in ('android', 'ios', 'web', 'windows', 'macos', 'linux')
  then
    v_platform := 'android';
  end if;

  v_role := case lower(btrim(coalesce(p_role, '')))
    when 'admin' then 'admin'
    when 'taker' then 'taker'
    when 'cashier' then 'taker'
    when 'delivery' then 'delivery'
    when 'driver' then 'delivery'
    when 'customer' then 'customer'
    else public.push_role_for(v_user_id)
  end;

  insert into public.user_fcm_tokens (user_id, token, role, platform)
  values (v_user_id, btrim(p_token), v_role, v_platform)
  on conflict (token) do update
    set user_id = excluded.user_id,
        role = excluded.role,
        platform = excluded.platform,
        updated_at = now();
end;
$$;

-- Replace the legacy 3-arg add so PostgREST exposes a single overload.
drop function if exists public.admin_add_staff(text, text, text);

revoke all on function public.staff_login(text, text) from public, anon;
revoke all on function public.admin_add_staff(text, text, text, text, text)
  from public, anon;
revoke all on function public.admin_update_staff(text, text, text, text, text)
  from public, anon;
revoke all on function public.admin_delete_staff(text) from public, anon;
revoke all on function public.register_fcm_token(text, text) from public, anon;
revoke all on function public.register_fcm_token(text, text, text)
  from public, anon;

grant execute on function public.staff_login(text, text) to authenticated;
grant execute on function public.admin_add_staff(text, text, text, text, text)
  to authenticated;
grant execute on function public.admin_update_staff(text, text, text, text, text)
  to authenticated;
grant execute on function public.admin_delete_staff(text) to authenticated;
grant execute on function public.register_fcm_token(text, text) to authenticated;
grant execute on function public.register_fcm_token(text, text, text)
  to authenticated;

notify pgrst, 'reload schema';
