-- =============================================================================
-- Priscy Luxury Slippers — Row Level Security (RLS), Grants & Storage Policies
-- Migration: 20261030000002_rls_and_storage.sql
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 1. Enable RLS on ALL Public Tables
-- -----------------------------------------------------------------------------
alter table public.profiles enable row level security;
alter table public.categories enable row level security;
alter table public.products enable row level security;
alter table public.product_images enable row level security;
alter table public.product_variants enable row level security;
alter table public.delivery_zones enable row level security;
alter table public.orders enable row level security;
alter table public.order_items enable row level security;
alter table public.order_events enable row level security;
alter table public.reviews enable row level security;
alter table public.pages enable row level security;
alter table public.site_settings enable row level security;
alter table public.stock_movements enable row level security;
alter table public.saved_addresses enable row level security;
alter table public.cart_items enable row level security;
alter table public.rate_limit_logs enable row level security;

-- -----------------------------------------------------------------------------
-- 2. Categories, Products, Images, Variants (Public read active; Admin all)
-- -----------------------------------------------------------------------------
create policy "public read categories"
  on public.categories for select
  using (true);

create policy "admin manage categories"
  on public.categories for all
  using (public.is_admin())
  with check (public.is_admin());

create policy "public read active products"
  on public.products for select
  using (is_active = true or public.is_admin());

create policy "admin manage products"
  on public.products for all
  using (public.is_admin())
  with check (public.is_admin());

create policy "public read active product images"
  on public.product_images for select
  using (
    public.is_admin()
    or exists (
      select 1 from public.products p
      where p.id = product_images.product_id and p.is_active = true
    )
  );

create policy "admin manage product images"
  on public.product_images for all
  using (public.is_admin())
  with check (public.is_admin());

create policy "public read active product variants"
  on public.product_variants for select
  using (
    public.is_admin()
    or exists (
      select 1 from public.products p
      where p.id = product_variants.product_id and p.is_active = true
    )
  );

create policy "admin manage product variants"
  on public.product_variants for all
  using (public.is_admin())
  with check (public.is_admin());

-- -----------------------------------------------------------------------------
-- 3. Delivery Zones, Pages, Site Settings (Public read; Admin all)
-- -----------------------------------------------------------------------------
create policy "public read active delivery zones"
  on public.delivery_zones for select
  using (is_active = true or public.is_admin());

create policy "admin manage delivery zones"
  on public.delivery_zones for all
  using (public.is_admin())
  with check (public.is_admin());

create policy "public read pages"
  on public.pages for select
  using (true);

create policy "admin manage pages"
  on public.pages for all
  using (public.is_admin())
  with check (public.is_admin());

create policy "public read site settings"
  on public.site_settings for select
  using (true);

create policy "admin manage site settings"
  on public.site_settings for all
  using (public.is_admin())
  with check (public.is_admin());

-- -----------------------------------------------------------------------------
-- 4. Reviews (Public read approved; Verified buyer insert; Admin all)
-- -----------------------------------------------------------------------------
create policy "public read approved reviews"
  on public.reviews for select
  using (is_approved = true or user_id = auth.uid() or public.is_admin());

create policy "verified buyer insert pending review"
  on public.reviews for insert
  with check (
    auth.uid() is not null
    and user_id = auth.uid()
    and is_approved = false
    and exists (
      select 1
      from public.orders o
      join public.order_items oi on oi.order_id = o.id
      where o.user_id = auth.uid()
        and o.payment_status = 'paid'
        and oi.product_id = reviews.product_id
    )
  );

create policy "admin manage reviews"
  on public.reviews for all
  using (public.is_admin())
  with check (public.is_admin());

-- -----------------------------------------------------------------------------
-- 5. Orders, Order Items, Order Events
--    No public access; Customers read own; Admin full access.
--    Order creation & payment confirmation happen only via Edge Functions.
-- -----------------------------------------------------------------------------
create policy "customer reads own orders"
  on public.orders for select
  using ((auth.uid() is not null and user_id = auth.uid()) or public.is_admin());

create policy "admin manage orders"
  on public.orders for all
  using (public.is_admin())
  with check (public.is_admin());

create policy "customer reads own order items"
  on public.order_items for select
  using (
    public.is_admin()
    or exists (
      select 1 from public.orders o
      where o.id = order_items.order_id
        and auth.uid() is not null
        and o.user_id = auth.uid()
    )
  );

create policy "admin manage order items"
  on public.order_items for all
  using (public.is_admin())
  with check (public.is_admin());

create policy "customer reads own order events"
  on public.order_events for select
  using (
    public.is_admin()
    or exists (
      select 1 from public.orders o
      where o.id = order_events.order_id
        and auth.uid() is not null
        and o.user_id = auth.uid()
    )
  );

create policy "admin manage order events"
  on public.order_events for all
  using (public.is_admin())
  with check (public.is_admin());

-- -----------------------------------------------------------------------------
-- 6. Profiles (Customer reads/updates own row; role protected by trigger; Admin all)
-- -----------------------------------------------------------------------------
create policy "user reads own profile"
  on public.profiles for select
  using (id = auth.uid() or public.is_admin());

create policy "user updates own profile"
  on public.profiles for update
  using (id = auth.uid() or public.is_admin())
  with check (id = auth.uid() or public.is_admin());

create policy "admin manage profiles"
  on public.profiles for all
  using (public.is_admin())
  with check (public.is_admin());

-- -----------------------------------------------------------------------------
-- 7. Stock Movements (Admin only)
-- -----------------------------------------------------------------------------
create policy "admin manage stock movements"
  on public.stock_movements for all
  using (public.is_admin())
  with check (public.is_admin());

-- -----------------------------------------------------------------------------
-- 8. Saved Addresses & Cart Items (Customer own; Admin read)
-- -----------------------------------------------------------------------------
create policy "customer manage own addresses"
  on public.saved_addresses for all
  using (user_id = auth.uid() or public.is_admin())
  with check (user_id = auth.uid() or public.is_admin());

create policy "customer manage own cart items"
  on public.cart_items for all
  using (user_id = auth.uid() or public.is_admin())
  with check (user_id = auth.uid() or public.is_admin());

-- rate_limit_logs has RLS enabled and NO public/authenticated policies -> service_role only

-- -----------------------------------------------------------------------------
-- 9. Lock Down Sensitive Security-Definer RPCs to Service Role / Admin Only
-- -----------------------------------------------------------------------------
revoke all on function public.create_order_with_reservation(
  jsonb, text, text, text, text, uuid, text, text, text, text, text, uuid, text
) from public, anon, authenticated;
grant execute on function public.create_order_with_reservation(
  jsonb, text, text, text, text, uuid, text, text, text, text, text, uuid, text
) to service_role;

revoke all on function public.confirm_order(text, bigint) from public, anon, authenticated;
grant execute on function public.confirm_order(text, bigint) to service_role;

revoke all on function public.release_expired_reservations() from public, anon, authenticated;
grant execute on function public.release_expired_reservations() to service_role;

-- -----------------------------------------------------------------------------
-- 10. Storage Bucket: product-images (Public Read, Admin Write Only)
-- -----------------------------------------------------------------------------
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'product-images',
  'product-images',
  true,
  5242880,
  array['image/jpeg', 'image/png', 'image/webp']
)
on conflict (id) do update
set public = true;

create policy "public read product images bucket"
  on storage.objects for select
  using (bucket_id = 'product-images');

create policy "admin upload product images bucket"
  on storage.objects for insert
  with check (bucket_id = 'product-images' and public.is_admin());

create policy "admin update product images bucket"
  on storage.objects for update
  using (bucket_id = 'product-images' and public.is_admin())
  with check (bucket_id = 'product-images' and public.is_admin());

create policy "admin delete product images bucket"
  on storage.objects for delete
  using (bucket_id = 'product-images' and public.is_admin());

-- -----------------------------------------------------------------------------
-- 11. Optional pg_cron Schedule (Every 5 Minutes) when pg_cron is Enabled
-- -----------------------------------------------------------------------------
do $$
begin
  if exists (select 1 from pg_extension where extname = 'pg_cron') then
    perform cron.schedule(
      'priscy-release-expired-reservations',
      '*/5 * * * *',
      'select public.release_expired_reservations();'
    );
  end if;
exception
  when others then
    -- Safe no-op if pg_cron is not yet enabled; use Edge Function cron instead.
    null;
end;
$$;
