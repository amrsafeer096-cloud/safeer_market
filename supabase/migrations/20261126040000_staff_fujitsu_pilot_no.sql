-- staff.fujitsu_pilot_no for sal_cashier (jobtype=2) pilots → hd_orders.PilotNo.
-- Safe to re-run (column may already exist in some environments).

alter table public.staff
  add column if not exists fujitsu_pilot_no integer;

create unique index if not exists staff_fujitsu_pilot_no_uidx
  on public.staff (fujitsu_pilot_no)
  where fujitsu_pilot_no is not null;
