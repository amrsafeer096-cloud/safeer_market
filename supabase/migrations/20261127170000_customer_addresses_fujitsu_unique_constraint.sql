-- PostgREST upsert ON CONFLICT cannot use a partial unique index
-- (WHERE fujitsu_address_id IS NOT NULL). Replace it with a normal UNIQUE
-- constraint — PostgreSQL UNIQUE already allows multiple NULLs.

drop index if exists public.customer_addresses_fujitsu_address_id_uidx;

alter table public.customer_addresses
  drop constraint if exists customer_addresses_fujitsu_address_id_key;

alter table public.customer_addresses
  add constraint customer_addresses_fujitsu_address_id_key
  unique (fujitsu_address_id);
