-- =============================================================================
-- Priscy Luxury Slippers — Initial Schema, Views, Triggers & Transactional RPCs
-- Migration: 20261030000001_initial_schema.sql
-- =============================================================================

create extension if not exists "pgcrypto" with schema extensions;

-- -----------------------------------------------------------------------------
-- 1. Enums
-- -----------------------------------------------------------------------------
create type public.app_role as enum ('admin', 'customer');

create type public.order_status as enum (
  'pending_payment',
  'confirmed',
  'processing',
  'dispatched',
  'delivered',
  'cancelled'
);

create type public.payment_status as enum ('unpaid', 'paid', 'failed');

create type public.audience as enum ('women', 'men', 'children', 'unisex');

-- -----------------------------------------------------------------------------
-- 2. Core Tables
-- -----------------------------------------------------------------------------
create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text,
  phone text,
  role public.app_role not null default 'customer',
  created_at timestamptz not null default now()
);

create table public.categories (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  slug text unique not null,
  sort_order int not null default 0
);

create table public.products (
  id uuid primary key default gen_random_uuid(),
  category_id uuid references public.categories(id) on delete set null,
  name text not null,
  slug text unique not null,
  description text,
  base_price numeric(10,2) not null check (base_price >= 0),
  audience public.audience not null default 'unisex',
  is_active boolean not null default true,
  is_featured boolean not null default false,
  created_at timestamptz not null default now()
);

create table public.product_images (
  id uuid primary key default gen_random_uuid(),
  product_id uuid not null references public.products(id) on delete cascade,
  url text not null,
  sort_order int not null default 0
);

create table public.product_variants (
  id uuid primary key default gen_random_uuid(),
  product_id uuid not null references public.products(id) on delete cascade,
  size text not null,
  colour text not null,
  sku text unique,
  price_override numeric(10,2) check (price_override is null or price_override >= 0),
  stock_qty int not null default 0 check (stock_qty >= 0),
  reserved_qty int not null default 0 check (reserved_qty >= 0 and reserved_qty <= stock_qty),
  unique (product_id, size, colour)
);

create table public.delivery_zones (
  id uuid primary key default gen_random_uuid(),
  region text not null,
  city text,
  fee numeric(10,2) not null check (fee >= 0),
  est_days_min int not null default 3,
  est_days_max int not null default 5,
  is_active boolean not null default true
);

create sequence if not exists public.order_daily_seq start 1;

create table public.orders (
  id uuid primary key default gen_random_uuid(),
  order_number text unique not null,
  user_id uuid references auth.users(id) on delete set null,
  tracking_token text not null default encode(extensions.gen_random_bytes(16), 'hex'),
  channel text not null default 'website' check (channel in ('website', 'whatsapp_manual')),
  customer_name text not null,
  customer_phone text not null,
  customer_whatsapp text,
  delivery_method text not null check (delivery_method in ('delivery', 'pickup')),
  region text,
  city text,
  address text,
  landmark text,
  notes text,
  subtotal numeric(10,2) not null check (subtotal >= 0),
  delivery_fee numeric(10,2) not null default 0 check (delivery_fee >= 0),
  total numeric(10,2) not null check (total >= 0),
  status public.order_status not null default 'pending_payment',
  payment_status public.payment_status not null default 'unpaid',
  paystack_reference text unique,
  reserved_until timestamptz,
  created_at timestamptz not null default now()
);

create table public.order_items (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null references public.orders(id) on delete cascade,
  variant_id uuid references public.product_variants(id) on delete set null,
  product_id uuid references public.products(id) on delete set null,
  product_name text not null,
  size text,
  colour text,
  unit_price numeric(10,2) not null check (unit_price >= 0),
  quantity int not null check (quantity > 0)
);

create table public.order_events (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null references public.orders(id) on delete cascade,
  status public.order_status not null,
  note text,
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now()
);

create table public.reviews (
  id uuid primary key default gen_random_uuid(),
  product_id uuid not null references public.products(id) on delete cascade,
  order_id uuid references public.orders(id) on delete set null,
  user_id uuid references auth.users(id) on delete set null,
  reviewer_name text not null,
  rating int not null check (rating between 1 and 5),
  comment text,
  is_approved boolean not null default false,
  created_at timestamptz not null default now(),
  unique nulls not distinct (product_id, order_id)
);

create table public.pages (
  slug text primary key,
  title text not null,
  body_markdown text not null,
  updated_at timestamptz not null default now()
);

create table public.site_settings (
  key text primary key,
  value jsonb not null
);

create table public.stock_movements (
  id uuid primary key default gen_random_uuid(),
  variant_id uuid not null references public.product_variants(id) on delete cascade,
  change int not null,
  reason text not null,
  created_at timestamptz not null default now()
);

-- Customer account convenience tables (saved addresses & synced cart)
create table public.saved_addresses (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  label text not null default 'Home',
  recipient_name text not null,
  phone text not null,
  region text not null,
  city text not null,
  address text not null,
  landmark text,
  is_default boolean not null default false,
  created_at timestamptz not null default now()
);

create table public.cart_items (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  variant_id uuid not null references public.product_variants(id) on delete cascade,
  quantity int not null check (quantity > 0),
  updated_at timestamptz not null default now(),
  unique (user_id, variant_id)
);

-- Edge Function rate limiting log
create table public.rate_limit_logs (
  id bigserial primary key,
  bucket text not null,
  identifier text not null,
  created_at timestamptz not null default now()
);

-- -----------------------------------------------------------------------------
-- 3. Indexes for Fast Mobile Queries
-- -----------------------------------------------------------------------------
create index idx_products_category on public.products(category_id) where is_active = true;
create index idx_products_audience on public.products(audience) where is_active = true;
create index idx_products_slug on public.products(slug);
create index idx_product_variants_product on public.product_variants(product_id);
create index idx_product_variants_filter on public.product_variants(size, colour);
create index idx_orders_number on public.orders(order_number);
create index idx_orders_user on public.orders(user_id);
create index idx_orders_status_created on public.orders(status, created_at desc);
create index idx_orders_reserved_until on public.orders(reserved_until)
  where status = 'pending_payment' and payment_status = 'unpaid';
create index idx_reviews_product_approved on public.reviews(product_id) where is_approved = true;
create index idx_rate_limit_lookup on public.rate_limit_logs(bucket, identifier, created_at desc);

-- -----------------------------------------------------------------------------
-- 4. Helper Functions
-- -----------------------------------------------------------------------------
create or replace function public.is_admin()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.profiles
    where id = auth.uid()
      and role = 'admin'
  );
$$;

create or replace function public.normalize_gh_phone(raw_phone text)
returns text
language plpgsql
immutable
as $$
declare
  digits text;
begin
  if raw_phone is null then
    return '';
  end if;
  digits := regexp_replace(raw_phone, '[^0-9]', '', 'g');
  if left(digits, 1) = '0' and length(digits) = 10 then
    return '233' || substring(digits from 2);
  end if;
  if length(digits) = 9 then
    return '233' || digits;
  end if;
  return digits;
end;
$$;

create or replace function public.generate_order_number()
returns text
language plpgsql
as $$
declare
  seq_val bigint;
begin
  seq_val := nextval('public.order_daily_seq');
  return 'PSY-' || to_char(now() at time zone 'Africa/Accra', 'YYYYMMDD') || '-' || lpad((seq_val % 10000)::text, 4, '0');
end;
$$;

-- -----------------------------------------------------------------------------
-- 5. Supporting Views
-- -----------------------------------------------------------------------------
create or replace view public.best_sellers as
select
  p.id as product_id,
  coalesce(sum(oi.quantity), 0)::bigint as units_sold
from public.products p
left join public.product_variants pv on pv.product_id = p.id
left join public.order_items oi on oi.variant_id = pv.id
left join public.orders o on o.id = oi.order_id and o.payment_status = 'paid'
group by p.id;

create or replace view public.product_ratings as
select
  p.id as product_id,
  coalesce(round(avg(r.rating)::numeric, 2), 0)::numeric(3,2) as avg_rating,
  count(r.id)::int as review_count
from public.products p
left join public.reviews r
  on r.product_id = p.id
  and r.is_approved = true
group by p.id;

-- -----------------------------------------------------------------------------
-- 6. Triggers
-- -----------------------------------------------------------------------------
-- Automatically create profile row when a customer signs up
create or replace function public.handle_new_auth_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, full_name, phone, role)
  values (
    new.id,
    coalesce(new.raw_user_meta_data->>'full_name', ''),
    coalesce(new.phone, new.raw_user_meta_data->>'phone', ''),
    'customer'
  )
  on conflict (id) do nothing;
  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_auth_user();

-- Prevent customers from escalating their own role
create or replace function public.prevent_role_self_escalation()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if new.role is distinct from old.role and not public.is_admin() and auth.role() <> 'service_role' then
    raise exception 'Permission denied: cannot modify account role';
  end if;
  return new;
end;
$$;

create trigger trg_profiles_prevent_role_escalation
  before update on public.profiles
  for each row execute function public.prevent_role_self_escalation();

-- Automatically log order_events when an order is created or its status changes
create or replace function public.log_order_status_change()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if tg_op = 'INSERT' then
    insert into public.order_events (order_id, status, note, created_by)
    values (new.id, new.status, 'Order created (' || new.channel || ')', auth.uid());
  elsif tg_op = 'UPDATE' and new.status is distinct from old.status then
    insert into public.order_events (order_id, status, note, created_by)
    values (new.id, new.status, 'Status changed from ' || old.status || ' to ' || new.status, auth.uid());
  end if;
  return new;
end;
$$;

create trigger trg_orders_status_event
  after insert or update on public.orders
  for each row execute function public.log_order_status_change();

-- -----------------------------------------------------------------------------
-- 7. Transactional Server RPCs (invoked by Edge Functions / Admin)
-- -----------------------------------------------------------------------------

-- Reserve stock and create order atomically
create or replace function public.create_order_with_reservation(
  p_items jsonb,
  p_customer_name text,
  p_customer_phone text,
  p_customer_whatsapp text,
  p_delivery_method text,
  p_delivery_zone_id uuid default null,
  p_region text default null,
  p_city text default null,
  p_address text default null,
  p_landmark text default null,
  p_notes text default null,
  p_user_id uuid default null,
  p_channel text default 'website'
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_item jsonb;
  v_variant record;
  v_qty int;
  v_unit_price numeric(10,2);
  v_subtotal numeric(10,2) := 0;
  v_delivery_fee numeric(10,2) := 0;
  v_total numeric(10,2);
  v_zone record;
  v_order_id uuid;
  v_order_number text;
  v_tracking_token text;
  v_region text := p_region;
  v_city text := p_city;
begin
  if jsonb_typeof(p_items) <> 'array' or jsonb_array_length(p_items) = 0 then
    raise exception 'Cart cannot be empty';
  end if;

  if p_delivery_method not in ('delivery', 'pickup') then
    raise exception 'Invalid delivery method';
  end if;

  -- Compute delivery fee from database zone if delivery is chosen
  if p_delivery_method = 'delivery' then
    if p_delivery_zone_id is not null then
      select * into v_zone
      from public.delivery_zones
      where id = p_delivery_zone_id and is_active = true;
    elsif p_region is not null then
      select * into v_zone
      from public.delivery_zones
      where lower(region) = lower(p_region) and is_active = true
      order by fee asc
      limit 1;
    end if;

    if v_zone is null then
      raise exception 'Selected delivery zone is not available';
    end if;

    v_delivery_fee := v_zone.fee;
    v_region := coalesce(p_region, v_zone.region);
    v_city := coalesce(p_city, v_zone.city);
  else
    v_delivery_fee := 0;
  end if;

  -- First pass: lock variants in deterministic order, validate stock & compute subtotal
  for v_item in
    select value
    from jsonb_array_elements(p_items)
    order by (value->>'variant_id')
  loop
    v_qty := (v_item->>'quantity')::int;
    if v_qty is null or v_qty <= 0 then
      raise exception 'Invalid item quantity';
    end if;

    select
      pv.id,
      pv.product_id,
      pv.size,
      pv.colour,
      pv.price_override,
      pv.stock_qty,
      pv.reserved_qty,
      p.name as product_name,
      p.base_price,
      p.is_active
    into v_variant
    from public.product_variants pv
    join public.products p on p.id = pv.product_id
    where pv.id = (v_item->>'variant_id')::uuid
    for update of pv;

    if v_variant is null or not v_variant.is_active then
      raise exception 'One or more products are no longer available';
    end if;

    if (v_variant.stock_qty - v_variant.reserved_qty) < v_qty then
      raise exception 'Insufficient stock for % (% / %)',
        v_variant.product_name, v_variant.size, v_variant.colour;
    end if;

    v_unit_price := coalesce(v_variant.price_override, v_variant.base_price);
    v_subtotal := v_subtotal + (v_unit_price * v_qty);
  end loop;

  v_total := v_subtotal + v_delivery_fee;
  v_order_number := public.generate_order_number();

  insert into public.orders (
    order_number,
    user_id,
    channel,
    customer_name,
    customer_phone,
    customer_whatsapp,
    delivery_method,
    region,
    city,
    address,
    landmark,
    notes,
    subtotal,
    delivery_fee,
    total,
    status,
    payment_status,
    reserved_until
  )
  values (
    v_order_number,
    p_user_id,
    coalesce(p_channel, 'website'),
    trim(p_customer_name),
    trim(p_customer_phone),
    coalesce(nullif(trim(p_customer_whatsapp), ''), trim(p_customer_phone)),
    p_delivery_method,
    v_region,
    v_city,
    p_address,
    p_landmark,
    p_notes,
    v_subtotal,
    v_delivery_fee,
    v_total,
    'pending_payment',
    'unpaid',
    now() + interval '15 minutes'
  )
  returning id, tracking_token into v_order_id, v_tracking_token;

  -- Second pass: insert snapshots & reserve stock
  for v_item in select value from jsonb_array_elements(p_items)
  loop
    v_qty := (v_item->>'quantity')::int;

    select
      pv.id,
      pv.product_id,
      pv.size,
      pv.colour,
      coalesce(pv.price_override, p.base_price) as unit_price,
      p.name as product_name
    into v_variant
    from public.product_variants pv
    join public.products p on p.id = pv.product_id
    where pv.id = (v_item->>'variant_id')::uuid;

    update public.product_variants
    set reserved_qty = reserved_qty + v_qty
    where id = v_variant.id;

    insert into public.order_items (
      order_id,
      variant_id,
      product_id,
      product_name,
      size,
      colour,
      unit_price,
      quantity
    )
    values (
      v_order_id,
      v_variant.id,
      v_variant.product_id,
      v_variant.product_name,
      v_variant.size,
      v_variant.colour,
      v_variant.unit_price,
      v_qty
    );
  end loop;

  return jsonb_build_object(
    'order_id', v_order_id,
    'order_number', v_order_number,
    'tracking_token', v_tracking_token,
    'subtotal', v_subtotal,
    'delivery_fee', v_delivery_fee,
    'total', v_total
  );
end;
$$;

-- Confirm payment idempotently, deduct stock & log stock_movements
create or replace function public.confirm_order(
  p_reference text,
  p_amount_pesewas bigint default null
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_order record;
  v_item record;
  v_expected_pesewas bigint;
begin
  select * into v_order
  from public.orders
  where paystack_reference = p_reference
  for update;

  if v_order is null then
    raise exception 'Order not found for reference %', p_reference;
  end if;

  -- Idempotency: duplicate webhook returns cleanly
  if v_order.payment_status = 'paid' then
    return jsonb_build_object(
      'status', 'already_paid',
      'order_id', v_order.id,
      'order_number', v_order.order_number
    );
  end if;

  v_expected_pesewas := round(v_order.total * 100)::bigint;
  if p_amount_pesewas is not null and p_amount_pesewas <> v_expected_pesewas then
    raise exception 'Amount mismatch: expected % pesewas, received %',
      v_expected_pesewas, p_amount_pesewas;
  end if;

  -- Deduct stock for every line item
  for v_item in
    select * from public.order_items where order_id = v_order.id
  loop
    if v_item.variant_id is not null then
      if v_order.status = 'cancelled' then
        -- Late payment after reservation expired: deduct from remaining available stock if possible
        update public.product_variants
        set stock_qty = greatest(0, stock_qty - v_item.quantity)
        where id = v_item.variant_id;
      else
        update public.product_variants
        set
          stock_qty = greatest(0, stock_qty - v_item.quantity),
          reserved_qty = greatest(0, reserved_qty - v_item.quantity)
        where id = v_item.variant_id;
      end if;

      insert into public.stock_movements (variant_id, change, reason)
      values (v_item.variant_id, -v_item.quantity, 'sale:' || v_order.order_number);
    end if;
  end loop;

  update public.orders
  set
    payment_status = 'paid',
    status = 'confirmed',
    reserved_until = null
  where id = v_order.id;

  return jsonb_build_object(
    'status', 'confirmed',
    'order_id', v_order.id,
    'order_number', v_order.order_number
  );
end;
$$;

-- Cancel an order before dispatch and restore stock / release reservation
create or replace function public.cancel_order_and_release_stock(
  p_order_id uuid,
  p_reason text default 'cancelled'
)
returns void
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

  select * into v_order
  from public.orders
  where id = p_order_id
  for update;

  if v_order is null or v_order.status in ('cancelled', 'dispatched', 'delivered') then
    return;
  end if;

  for v_item in
    select * from public.order_items where order_id = v_order.id
  loop
    if v_item.variant_id is not null then
      if v_order.payment_status = 'paid' then
        update public.product_variants
        set stock_qty = stock_qty + v_item.quantity
        where id = v_item.variant_id;

        insert into public.stock_movements (variant_id, change, reason)
        values (v_item.variant_id, v_item.quantity, 'cancel:' || coalesce(p_reason, v_order.order_number));
      else
        update public.product_variants
        set reserved_qty = greatest(0, reserved_qty - v_item.quantity)
        where id = v_item.variant_id;
      end if;
    end if;
  end loop;

  update public.orders
  set
    status = 'cancelled',
    reserved_until = null
  where id = v_order.id;
end;
$$;

-- Scheduled cleanup: cancel unpaid orders older than 15 minutes and release reserved stock
create or replace function public.release_expired_reservations()
returns int
language plpgsql
security definer
set search_path = public
as $$
declare
  v_order record;
  v_count int := 0;
begin
  for v_order in
    select id
    from public.orders
    where status = 'pending_payment'
      and payment_status = 'unpaid'
      and reserved_until is not null
      and reserved_until < now()
    for update skip locked
  loop
    perform public.cancel_order_and_release_stock(v_order.id, 'reservation_expired');
    v_count := v_count + 1;
  end loop;

  -- Prune old rate limit logs older than 24h
  delete from public.rate_limit_logs where created_at < now() - interval '24 hours';

  return v_count;
end;
$$;

-- Admin stock adjustment with audit log
create or replace function public.adjust_variant_stock(
  p_variant_id uuid,
  p_change int,
  p_reason text default 'adjustment'
)
returns int
language plpgsql
security definer
set search_path = public
as $$
declare
  v_new_qty int;
begin
  if auth.role() <> 'service_role' and not public.is_admin() then
    raise exception 'Admin privileges required';
  end if;

  update public.product_variants
  set stock_qty = greatest(reserved_qty, stock_qty + p_change)
  where id = p_variant_id
  returning stock_qty into v_new_qty;

  if v_new_qty is null then
    raise exception 'Variant not found';
  end if;

  insert into public.stock_movements (variant_id, change, reason)
  values (p_variant_id, p_change, p_reason);

  return v_new_qty;
end;
$$;
