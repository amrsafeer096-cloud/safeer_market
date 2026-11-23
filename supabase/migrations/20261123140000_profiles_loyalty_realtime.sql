-- Ensure profiles.loyalty_points changes reach the customer app via Realtime
-- (Home badge + loyalty header). Safe to re-run.

do $$
begin
  if not exists (
    select 1
    from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'profiles'
  ) then
    alter publication supabase_realtime add table public.profiles;
  end if;
end $$;

alter table public.profiles replica identity full;

notify pgrst, 'reload schema';
