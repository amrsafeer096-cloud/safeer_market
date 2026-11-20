-- Broadcast order changes so the customer's orders screen updates live when a
-- driver accepts or delivers. Without this, `.stream()` in the app only ever
-- returns the initial snapshot. Safe to re-run.

do $$
begin
  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'orders'
  ) then
    alter publication supabase_realtime add table public.orders;
  end if;
end;
$$;

-- Realtime checks RLS against the full row, and the stream filters on
-- user_id, so UPDATE events must carry every column, not just the key.
alter table public.orders replica identity full;
