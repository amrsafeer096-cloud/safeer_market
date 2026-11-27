-- Multi-address 2-way Fujitsu sync support:
-- * synced_to_fujitsu queue flag on customer_addresses
-- * unique fujitsu_address_id for idempotent pull/push
-- * upsert_customer_address always enqueues reverse sync

alter table public.customer_addresses
  add column if not exists synced_to_fujitsu boolean not null default true;

alter table public.customer_addresses
  add column if not exists landmark text;

-- Full UNIQUE (not partial) so PostgREST upsert on_conflict=fujitsu_address_id works.
-- NULLs are still allowed multiple times under a standard UNIQUE constraint.
alter table public.customer_addresses
  drop constraint if exists customer_addresses_fujitsu_address_id_key;
alter table public.customer_addresses
  add constraint customer_addresses_fujitsu_address_id_key
  unique (fujitsu_address_id);

create index if not exists customer_addresses_synced_false_idx
  on public.customer_addresses (synced_to_fujitsu)
  where synced_to_fujitsu = false;

create index if not exists customer_addresses_pos_fujitsu_idx
  on public.customer_addresses (pos_customer_id, fujitsu_address_id);

-- ---------------------------------------------------------------------------
-- upsert_customer_address: always mark synced_to_fujitsu=false so the daemon
-- can insert/update dbo.CustomerAddresses and write AddressId back.
-- ---------------------------------------------------------------------------
create or replace function public.upsert_customer_address(
  p_pos_customer_id bigint default null,
  p_user_id uuid default null,
  p_address_id bigint default null,
  p_address text default null,
  p_zone text default null,
  p_branch text default null,
  p_governorate text default null,
  p_city text default null,
  p_building text default null,
  p_floor text default null,
  p_apartment text default null,
  p_latitude double precision default null,
  p_longitude double precision default null,
  p_fujitsu_zone_id text default null,
  p_is_primary boolean default false
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  line text;
  row public.customer_addresses;
begin
  if not public.is_order_taker() then
    raise exception 'not_allowed' using errcode = '42501';
  end if;
  if p_pos_customer_id is null and p_user_id is null then
    raise exception 'customer_required' using errcode = '22023';
  end if;

  line := nullif(btrim(coalesce(p_address, '')), '');
  if line is null then
    line := concat_ws('، ',
      case when nullif(btrim(coalesce(p_building, '')), '') is not null
        then 'مبنى ' || btrim(p_building) end,
      case when nullif(btrim(coalesce(p_floor, '')), '') is not null
        then 'الدور ' || btrim(p_floor) end,
      case when nullif(btrim(coalesce(p_apartment, '')), '') is not null
        then 'شقة ' || btrim(p_apartment) end,
      nullif(btrim(coalesce(p_zone, '')), ''),
      nullif(btrim(coalesce(p_city, '')), ''),
      nullif(btrim(coalesce(p_governorate, '')), '')
    );
  end if;
  if line is null or line = '' then
    raise exception 'address_required' using errcode = '22023';
  end if;

  if p_is_primary then
    update public.customer_addresses
    set is_primary = false
    where (p_pos_customer_id is not null and pos_customer_id = p_pos_customer_id)
       or (p_user_id is not null and user_id = p_user_id);
  end if;

  if p_address_id is not null then
    update public.customer_addresses a
    set address = line,
        zone = nullif(btrim(coalesce(p_zone, '')), ''),
        branch = nullif(btrim(coalesce(p_branch, '')), ''),
        governorate = nullif(btrim(coalesce(p_governorate, '')), ''),
        city = nullif(btrim(coalesce(p_city, '')), ''),
        building = nullif(btrim(coalesce(p_building, '')), ''),
        floor = nullif(btrim(coalesce(p_floor, '')), ''),
        apartment = nullif(btrim(coalesce(p_apartment, '')), ''),
        latitude = coalesce(p_latitude, a.latitude),
        longitude = coalesce(p_longitude, a.longitude),
        fujitsu_zone_id = coalesce(
          nullif(btrim(coalesce(p_fujitsu_zone_id, '')), ''), a.fujitsu_zone_id),
        is_primary = p_is_primary or a.is_primary,
        updated_at = now(),
        -- Text change clears Fujitsu id so reverse sync inserts a fresh row;
        -- other edits keep the id and push an UPDATE.
        fujitsu_address_id = case
          when a.address is distinct from line then null
          else a.fujitsu_address_id
        end,
        synced_to_fujitsu = false
    where a.id = p_address_id
      and (
        (p_pos_customer_id is not null and a.pos_customer_id = p_pos_customer_id)
        or (p_user_id is not null and a.user_id = p_user_id)
      )
    returning * into row;

    if not found then
      raise exception 'address_not_found' using errcode = 'P0002';
    end if;
  else
    insert into public.customer_addresses (
      pos_customer_id, user_id, address, zone, branch, governorate, city,
      building, floor, apartment, latitude, longitude, fujitsu_zone_id,
      is_primary, synced_to_fujitsu
    ) values (
      p_pos_customer_id,
      p_user_id,
      line,
      nullif(btrim(coalesce(p_zone, '')), ''),
      nullif(btrim(coalesce(p_branch, '')), ''),
      nullif(btrim(coalesce(p_governorate, '')), ''),
      nullif(btrim(coalesce(p_city, '')), ''),
      nullif(btrim(coalesce(p_building, '')), ''),
      nullif(btrim(coalesce(p_floor, '')), ''),
      nullif(btrim(coalesce(p_apartment, '')), ''),
      p_latitude,
      p_longitude,
      nullif(btrim(coalesce(p_fujitsu_zone_id, '')), ''),
      p_is_primary,
      false
    )
    returning * into row;
  end if;

  -- Mirror primary (or sole) address onto pos_customers for legacy search UI.
  if p_pos_customer_id is not null and row.is_primary then
    update public.pos_customers
    set address = row.address,
        zone = row.zone,
        governorate = row.governorate,
        city = row.city,
        building = row.building,
        floor = row.floor,
        apartment = row.apartment,
        latitude = row.latitude,
        longitude = row.longitude,
        fujitsu_zone_id = coalesce(row.fujitsu_zone_id, fujitsu_zone_id),
        synced_to_fujitsu = false
    where id = p_pos_customer_id;
  elsif p_pos_customer_id is not null then
    -- Non-primary edits still need the customer linked; do not flip customer
    -- synced flag unless primary — address row itself is queued above.
    null;
  end if;

  return row_to_json(row)::jsonb;
end;
$$;

revoke execute on function public.upsert_customer_address(
  bigint, uuid, bigint, text, text, text, text, text, text, text, text,
  double precision, double precision, text, boolean) from public, anon;
grant execute on function public.upsert_customer_address(
  bigint, uuid, bigint, text, text, text, text, text, text, text, text,
  double precision, double precision, text, boolean) to authenticated;
