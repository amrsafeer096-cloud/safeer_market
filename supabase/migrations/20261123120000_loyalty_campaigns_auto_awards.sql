-- Automatic loyalty: +10 per delivered order, +100 weekly (4+ orders),
-- and admin-defined campaigns. Credits the same profiles.loyalty_points
-- balance the customer sees in the app. Safe to re-run.

-- Allow «نقاط الولاء» on the notifications log.
alter table public.app_notifications
  drop constraint if exists app_notifications_type_check;

alter table public.app_notifications
  add constraint app_notifications_type_check
  check (type in (
    'general', 'promo', 'magazine', 'order', 'support_chat', 'loyalty'
  ));

-- ---------------------------------------------------------------------------
-- Tables
-- ---------------------------------------------------------------------------

create table if not exists public.loyalty_campaigns (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  body text not null default '',
  points_reward integer not null check (points_reward > 0),
  required_orders integer not null check (required_orders > 0),
  start_date timestamptz not null,
  end_date timestamptz not null,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  check (end_date > start_date)
);

create index if not exists loyalty_campaigns_active_window_idx
  on public.loyalty_campaigns (is_active, start_date, end_date);

create table if not exists public.loyalty_campaign_awards (
  campaign_id uuid not null
    references public.loyalty_campaigns (id) on delete cascade,
  user_id uuid not null references public.profiles (id) on delete cascade,
  awarded_at timestamptz not null default now(),
  primary key (campaign_id, user_id)
);

create index if not exists loyalty_campaign_awards_user_idx
  on public.loyalty_campaign_awards (user_id);

create table if not exists public.loyalty_weekly_awards (
  user_id uuid not null references public.profiles (id) on delete cascade,
  week_key text not null,
  awarded_at timestamptz not null default now(),
  primary key (user_id, week_key)
);

create table if not exists public.loyalty_order_awards (
  order_id uuid primary key references public.orders (id) on delete cascade,
  user_id uuid not null references public.profiles (id) on delete cascade,
  points integer not null check (points > 0),
  awarded_at timestamptz not null default now()
);

create index if not exists loyalty_order_awards_user_idx
  on public.loyalty_order_awards (user_id);

alter table public.loyalty_campaigns enable row level security;
alter table public.loyalty_campaign_awards enable row level security;
alter table public.loyalty_weekly_awards enable row level security;
alter table public.loyalty_order_awards enable row level security;

-- Staff (admin / warehouse / cashier) manage campaigns; customers can read
-- active ones (optional transparency).
drop policy if exists "loyalty_campaigns_staff_all" on public.loyalty_campaigns;
create policy "loyalty_campaigns_staff_all"
  on public.loyalty_campaigns
  for all to authenticated
  using (
    public.is_admin()
    or public.has_permission('manage_users')
    or exists (
      select 1 from public.profiles p
      where p.id = auth.uid()
        and p.role in ('admin', 'warehouse', 'cashier')
        and not coalesce(p.staff_disabled, false)
    )
  )
  with check (
    public.is_admin()
    or public.has_permission('manage_users')
    or exists (
      select 1 from public.profiles p
      where p.id = auth.uid()
        and p.role in ('admin', 'warehouse', 'cashier')
        and not coalesce(p.staff_disabled, false)
    )
  );

drop policy if exists "loyalty_campaigns_customer_select"
  on public.loyalty_campaigns;
create policy "loyalty_campaigns_customer_select"
  on public.loyalty_campaigns
  for select to authenticated
  using (
    is_active
    and now() between start_date and end_date
  );

drop policy if exists "loyalty_awards_own_select"
  on public.loyalty_campaign_awards;
create policy "loyalty_awards_own_select"
  on public.loyalty_campaign_awards
  for select to authenticated
  using (user_id = auth.uid() or public.is_admin());

drop policy if exists "loyalty_weekly_own_select"
  on public.loyalty_weekly_awards;
create policy "loyalty_weekly_own_select"
  on public.loyalty_weekly_awards
  for select to authenticated
  using (user_id = auth.uid() or public.is_admin());

drop policy if exists "loyalty_order_awards_own_select"
  on public.loyalty_order_awards;
create policy "loyalty_order_awards_own_select"
  on public.loyalty_order_awards
  for select to authenticated
  using (user_id = auth.uid() or public.is_admin());

grant select, insert, update on public.loyalty_campaigns to authenticated;
grant select on public.loyalty_campaign_awards to authenticated;
grant select on public.loyalty_weekly_awards to authenticated;
grant select on public.loyalty_order_awards to authenticated;

-- ---------------------------------------------------------------------------
-- Credit helper (same column the app reads: profiles.loyalty_points)
-- ---------------------------------------------------------------------------

create or replace function public._loyalty_credit_points(
  p_user_id uuid,
  p_points integer
)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if p_user_id is null or p_points is null or p_points <= 0 then
    return;
  end if;
  update public.profiles
  set loyalty_points = coalesce(loyalty_points, 0) + p_points
  where id = p_user_id;
end;
$$;

revoke all on function public._loyalty_credit_points(uuid, integer)
  from public, anon, authenticated;

-- ---------------------------------------------------------------------------
-- Trigger: orders → delivered / completed
-- ---------------------------------------------------------------------------

create or replace function public.loyalty_on_order_delivered()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_week_key text;
  v_week_start timestamptz;
  v_week_end timestamptz;
  v_week_count integer;
  v_base_points integer := 10;
  v_weekly_bonus integer := 100;
  v_campaign record;
  v_campaign_count integer;
  v_inserted integer;
begin
  if tg_op <> 'UPDATE' then
    return new;
  end if;

  if new.user_id is null then
    return new;
  end if;

  -- Only when entering a completed state (exact schema values).
  if new.status is distinct from 'delivered'
     and new.status is distinct from 'completed' then
    return new;
  end if;

  if old.status is not distinct from 'delivered'
     or old.status is not distinct from 'completed' then
    return new;
  end if;

  -- (a) Base order reward (+10), once per order.
  insert into public.loyalty_order_awards (order_id, user_id, points)
  values (new.id, new.user_id, v_base_points)
  on conflict (order_id) do nothing;
  get diagnostics v_inserted = row_count;
  if v_inserted > 0 then
    perform public._loyalty_credit_points(new.user_id, v_base_points);
  end if;

  -- (b) Weekly bonus (+100) when 4+ completed orders this ISO week.
  v_week_key := to_char(timezone('utc', now()), 'IYYY-IW');
  v_week_start := date_trunc('week', timezone('utc', now()));
  v_week_end := v_week_start + interval '1 week';

  select count(*)::integer into v_week_count
  from public.orders o
  where o.user_id = new.user_id
    and o.status in ('delivered', 'completed')
    and (
      o.id = new.id
      or (
        coalesce(o.updated_at, o.created_at) >= v_week_start
        and coalesce(o.updated_at, o.created_at) < v_week_end
      )
    );

  if v_week_count > 3 then
    insert into public.loyalty_weekly_awards (user_id, week_key)
    values (new.user_id, v_week_key)
    on conflict (user_id, week_key) do nothing;
    get diagnostics v_inserted = row_count;
    if v_inserted > 0 then
      perform public._loyalty_credit_points(new.user_id, v_weekly_bonus);
    end if;
  end if;

  -- (c) Active custom campaigns.
  for v_campaign in
    select *
    from public.loyalty_campaigns c
    where c.is_active
      and now() between c.start_date and c.end_date
  loop
    select count(*)::integer into v_campaign_count
    from public.orders o
    where o.user_id = new.user_id
      and o.status in ('delivered', 'completed')
      and (
        o.id = new.id
        or (
          coalesce(o.updated_at, o.created_at) >= v_campaign.start_date
          and coalesce(o.updated_at, o.created_at) <= v_campaign.end_date
        )
      );

    if v_campaign_count >= v_campaign.required_orders then
      insert into public.loyalty_campaign_awards (campaign_id, user_id)
      values (v_campaign.id, new.user_id)
      on conflict (campaign_id, user_id) do nothing;
      get diagnostics v_inserted = row_count;
      if v_inserted > 0 then
        perform public._loyalty_credit_points(
          new.user_id, v_campaign.points_reward
        );
      end if;
    end if;
  end loop;

  return new;
end;
$$;

drop trigger if exists trg_loyalty_on_order_delivered on public.orders;
create trigger trg_loyalty_on_order_delivered
  after update of status on public.orders
  for each row
  execute function public.loyalty_on_order_delivered();

notify pgrst, 'reload schema';
