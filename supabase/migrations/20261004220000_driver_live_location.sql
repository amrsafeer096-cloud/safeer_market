-- Live driver tracking: the driver app streams its GPS position into the
-- order it is delivering, and the customer's tracking map follows it through
-- the realtime publication added in 20261004180000_orders_realtime.sql.
-- Safe to re-run.

alter table public.orders
  add column if not exists driver_lat double precision,
  add column if not exists driver_lng double precision;

-- Same guard as 20261004200000_warehouse_lifecycle.sql, except drivers may
-- also write their position, and only while the order is out for delivery.
create or replace function public.guard_driver_order_update()
returns trigger
language plpgsql
as $$
begin
  if auth.role() <> 'authenticated' or old.user_id = auth.uid() then
    return new;
  end if;

  if public.is_driver() then
    if (to_jsonb(new) - 'status' - 'driver_id' - 'updated_at'
          - 'driver_lat' - 'driver_lng')
       is distinct from (to_jsonb(old) - 'status' - 'driver_id' - 'updated_at'
          - 'driver_lat' - 'driver_lng')
    then
      raise exception 'Drivers can only change the order status';
    end if;
    if (new.driver_lat, new.driver_lng)
         is distinct from (old.driver_lat, old.driver_lng)
       and old.status <> 'out_for_delivery'
    then
      raise exception 'The driver location is only shared while delivering';
    end if;
  end if;

  if public.is_warehouse() then
    if (to_jsonb(new) - 'status' - 'updated_at')
       is distinct from (to_jsonb(old) - 'status' - 'updated_at')
    then
      raise exception 'Warehouse staff can only change the order status';
    end if;
    if not (
      (old.status = 'pending' and new.status = 'preparing')
      or (old.status = 'preparing' and new.status = 'ready_for_delivery')
    ) then
      raise exception 'Invalid warehouse status change: % -> %',
        old.status, new.status;
    end if;
  end if;

  return new;
end;
$$;
