-- Lets the signed-in customer mark their own grocery order as paid by Visa
-- after a successful client-side Paymob checkout (no Edge Function write).

create or replace function public.mark_order_paid_visa(p_order_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  o public.orders;
begin
  if auth.uid() is null then
    raise exception 'not_signed_in';
  end if;

  select * into o
  from public.orders
  where id = p_order_id
  for update;

  if not found then
    return jsonb_build_object('status', 'not_found');
  end if;

  if o.user_id is distinct from auth.uid() then
    raise exception 'forbidden';
  end if;

  if o.payment_status = 'paid' and o.payment_method = 'visa' then
    return jsonb_build_object('status', 'already_paid', 'order_id', o.id);
  end if;

  update public.orders
  set payment_status = 'paid',
      payment_method = 'visa',
      status = case
        when status in ('pending', 'processing', 'new') then 'preparing'
        else status
      end,
      updated_at = now()
  where id = o.id;

  return jsonb_build_object('status', 'paid', 'order_id', o.id);
end;
$$;

revoke execute on function public.mark_order_paid_visa(uuid)
  from public, anon;
grant execute on function public.mark_order_paid_visa(uuid)
  to authenticated;

notify pgrst, 'reload schema';
