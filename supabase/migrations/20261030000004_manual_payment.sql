-- =============================================================================
-- Priscy Luxury Slippers — Manual MoMo Payment + Seller Verification
-- Migration: 20261030000004_manual_payment.sql
-- Customer pays seller directly (MoMo 0550571248), submits Transaction ID,
-- seller verifies in Admin app -> order confirmed, stock deducted.
-- =============================================================================

-- NOTE: enum value must be added outside a transaction that uses it.
-- Run separately if applying via psql: ALTER TYPE public.payment_status ADD VALUE 'awaiting_verification';
-- (Already applied to live project ggznhxnsfngzswxztnkk.)

alter table public.orders add column if not exists payment_method text not null default 'manual_momo' check (payment_method in ('paystack','manual_momo'));
alter table public.orders add column if not exists manual_txn_id text;
alter table public.orders add column if not exists manual_sender_name text;
alter table public.orders add column if not exists manual_sender_phone text;
alter table public.orders add column if not exists manual_screenshot_url text;
alter table public.orders add column if not exists manual_submitted_at timestamptz;
alter table public.orders add column if not exists manual_verified_at timestamptz;
alter table public.orders add column if not exists manual_verified_by uuid references auth.users(id) on delete set null;
alter table public.orders add column if not exists manual_rejection_reason text;

create index if not exists idx_orders_awaiting_verification
  on public.orders(payment_status, manual_submitted_at desc)
  where payment_status = 'awaiting_verification';

-- Customer submits MoMo proof (called via submit-payment-proof Edge Function)
create or replace function public.submit_manual_payment_proof(
  p_order_id uuid,
  p_txn_id text,
  p_sender_name text,
  p_sender_phone text,
  p_screenshot_url text default null
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_order record;
begin
  select * into v_order from public.orders where id = p_order_id for update;
  if v_order is null then raise exception 'Order not found'; end if;
  if v_order.status not in ('pending_payment') then raise exception 'Order is not awaiting payment'; end if;
  if v_order.payment_status = 'paid' then raise exception 'Order already paid'; end if;
  if p_txn_id is null or trim(p_txn_id) = '' then raise exception 'Transaction ID is required'; end if;

  update public.orders
  set manual_txn_id = trim(p_txn_id),
      manual_sender_name = trim(p_sender_name),
      manual_sender_phone = trim(p_sender_phone),
      manual_screenshot_url = nullif(trim(coalesce(p_screenshot_url,'')),''),
      manual_submitted_at = now(),
      payment_status = 'awaiting_verification',
      manual_rejection_reason = null
  where id = p_order_id;

  insert into public.order_events (order_id, status, note)
  values (p_order_id, 'pending_payment',
    'Customer submitted manual MoMo proof (Txn: ' || trim(p_txn_id) || ') - awaiting seller verification');

  return jsonb_build_object('ok', true, 'order_id', p_order_id, 'status', 'awaiting_verification');
end;
$$;

-- Seller approves (confirm + deduct stock) or rejects (allow resubmit)
create or replace function public.verify_manual_payment(
  p_order_id uuid,
  p_approve boolean,
  p_rejection_reason text default null
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_order record;
  v_item record;
begin
  if auth.role() <> 'service_role' and not public.is_admin() then
    raise exception 'Admin privileges required';
  end if;

  select * into v_order from public.orders where id = p_order_id for update;
  if v_order is null then raise exception 'Order not found'; end if;
  if v_order.payment_status = 'paid' then
    return jsonb_build_object('status','already_paid','order_id',v_order.id);
  end if;

  if p_approve then
    for v_item in select * from public.order_items where order_id = v_order.id loop
      if v_item.variant_id is not null then
        update public.product_variants
        set stock_qty = greatest(0, stock_qty - v_item.quantity),
            reserved_qty = greatest(0, reserved_qty - v_item.quantity)
        where id = v_item.variant_id;
        insert into public.stock_movements (variant_id, change, reason)
        values (v_item.variant_id, -v_item.quantity, 'sale:' || v_order.order_number);
      end if;
    end loop;

    update public.orders
    set payment_status = 'paid', status = 'confirmed', reserved_until = null,
        manual_verified_at = now(), manual_verified_by = auth.uid()
    where id = p_order_id;

    return jsonb_build_object('status','confirmed','order_id',v_order.id,'order_number',v_order.order_number);
  else
    update public.orders
    set payment_status = 'unpaid',
        manual_rejection_reason = coalesce(nullif(trim(p_rejection_reason),''),
          'Payment could not be verified. Please check the amount and try again.'),
        manual_submitted_at = null
    where id = p_order_id;

    insert into public.order_events (order_id, status, note)
    values (p_order_id, 'pending_payment',
      'Seller rejected manual payment proof: ' || coalesce(nullif(trim(p_rejection_reason),''),'could not be verified'));

    return jsonb_build_object('status','rejected','order_id',v_order.id);
  end if;
end;
$$;

revoke all on function public.submit_manual_payment_proof(uuid, text, text, text, text) from public, anon, authenticated;
grant execute on function public.submit_manual_payment_proof(uuid, text, text, text, text) to service_role;
revoke all on function public.verify_manual_payment(uuid, boolean, text) from public, anon, authenticated;
grant execute on function public.verify_manual_payment(uuid, boolean, text) to service_role;

update public.site_settings
set value = value || '{"manual_momo_number":"0550571248","manual_momo_name":"Priscilla Adutwum","manual_momo_networks":["MTN MoMo","Telecel Cash","AT Money"],"payment_flow":"manual_verification","manual_reservation_hours":24}'::jsonb
where key = 'general';
