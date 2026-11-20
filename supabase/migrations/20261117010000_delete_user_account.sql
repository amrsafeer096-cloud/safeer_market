-- Lets a signed-in customer permanently delete their account from the app.
-- Wipes personal data, then removes the auth.users row (cascades related FKs).

create or replace function public.delete_user_account()
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  uid uuid := auth.uid();
begin
  if uid is null then
    raise exception 'not_authenticated';
  end if;

  -- Personal rows that may not cascade from auth.users.
  begin
    delete from public.addresses where user_id = uid;
  exception
    when undefined_table then null;
  end;

  begin
    delete from public.user_favorites where user_id = uid;
  exception
    when undefined_table then null;
  end;

  begin
    delete from public.favorites where user_id = uid;
  exception
    when undefined_table then null;
  end;

  -- Soft-clear profile PII if the row isn't cascaded yet.
  begin
    update public.profiles
    set
      full_name = 'Deleted User',
      phone = null,
      avatar_url = null,
      fcm_token = null,
      saved_cards = '[]'::jsonb,
      loyalty_points = 0
    where id = uid;
  exception
    when undefined_column then
      update public.profiles
      set full_name = 'Deleted User', phone = null
      where id = uid;
    when undefined_table then null;
  end;

  delete from auth.users where id = uid;
end;
$$;

revoke all on function public.delete_user_account() from public;
grant execute on function public.delete_user_account() to authenticated;
