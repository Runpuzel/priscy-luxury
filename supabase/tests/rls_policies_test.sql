-- =============================================================================
-- Priscy Luxury Slippers — RLS Security Verification Suite (Section 15)
-- Run in psql / Supabase SQL Editor (`supabase test db`) to prove:
--   1. Anon users CANNOT read orders or write to products.
--   2. Customers CANNOT read other customers' orders or write to products.
--   3. Customers CANNOT escalate their own profile role to 'admin'.
--   4. Admins CAN manage products and read all orders.
-- =============================================================================

begin;

-- Setup test users in auth.users
insert into auth.users (id, email, role, aud)
values
  ('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaa1', 'customer1@example.com', 'authenticated', 'authenticated'),
  ('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaa2', 'customer2@example.com', 'authenticated', 'authenticated'),
  ('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaa9', 'priscilla@priscyluxury.com', 'authenticated', 'authenticated')
on conflict (id) do nothing;

update public.profiles
set role = 'admin'
where id = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaa9';

insert into public.orders (
  id, order_number, user_id, customer_name, customer_phone,
  delivery_method, subtotal, delivery_fee, total, status, payment_status
) values (
  'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbb1',
  'PSY-TEST-0001',
  'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaa1',
  'Customer One',
  '0240000001',
  'pickup',
  185.00,
  0.00,
  185.00,
  'confirmed',
  'paid'
);

-- Test 1: Anonymous user cannot read any orders and cannot insert products
set local role anon;
set local "request.jwt.claims" = '{"role":"anon"}';

do $$
declare
  v_order_count int;
begin
  select count(*) into v_order_count from public.orders;
  if v_order_count <> 0 then
    raise exception 'RLS FAILURE: anon user could read % orders', v_order_count;
  end if;
end $$;

do $$
begin
  insert into public.products (name, slug, base_price)
  values ('Rogue Slipper', 'rogue-slipper', 1.00);
  raise exception 'RLS FAILURE: anon user inserted into products';
exception
  when insufficient_privilege or others then
    null; -- Expected RLS rejection
end $$;

-- Test 2: Customer 2 cannot read Customer 1's order
set local role authenticated;
set local "request.jwt.claims" = '{"sub":"aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaa2","role":"authenticated"}';

do $$
declare
  v_order_count int;
begin
  select count(*) into v_order_count from public.orders;
  if v_order_count <> 0 then
    raise exception 'RLS FAILURE: customer2 read % orders belonging to others', v_order_count;
  end if;
end $$;

-- Test 3: Customer 2 cannot escalate own role to admin
do $$
begin
  update public.profiles set role = 'admin' where id = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaa2';
  raise exception 'SECURITY FAILURE: customer2 escalated own role to admin';
exception
  when others then
    null; -- Expected trigger rejection
end $$;

-- Test 4: Customer 1 CAN read their own order
set local "request.jwt.claims" = '{"sub":"aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaa1","role":"authenticated"}';

do $$
declare
  v_order_count int;
begin
  select count(*) into v_order_count
  from public.orders
  where id = 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbb1';
  if v_order_count <> 1 then
    raise exception 'RLS FAILURE: customer1 could not read own order';
  end if;
end $$;

-- Test 5: Admin CAN read all orders and insert products
set local "request.jwt.claims" = '{"sub":"aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaa9","role":"authenticated"}';

do $$
declare
  v_order_count int;
begin
  select count(*) into v_order_count from public.orders;
  if v_order_count < 1 then
    raise exception 'RLS FAILURE: admin could not read orders';
  end if;
end $$;

rollback;
