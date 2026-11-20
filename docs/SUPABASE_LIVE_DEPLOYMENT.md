# Priscy Luxury Slippers — Live Supabase Deployment

**Date:** 2026-11-20  
**Project:** `priscy-luxury supabase`  
**Ref:** `ggznhxnsfngzswxztnkk`  
**Region:** `eu-north-1` (Stockholm)  
**Status:** ✅ ACTIVE_HEALTHY — fully live with real data

## Live URLs

| Service | URL |
|---------|-----|
| **Supabase Project** | https://supabase.com/dashboard/project/ggznhxnsfngzswxztnkk |
| **API Base** | https://ggznhxnsfngzswxztnkk.supabase.co |
| **REST API** | https://ggznhxnsfngzswxztnkk.supabase.co/rest/v1/ |
| **Auth** | https://ggznhxnsfngzswxztnkk.supabase.co/auth/v1/ |
| **Storage** | https://ggznhxnsfngzswxztnkk.supabase.co/storage/v1/ |
| **Edge Functions** | https://ggznhxnsfngzswxztnkk.supabase.co/functions/v1/ |

## Flutter .env (Live)

```env
DEMO_MODE=false
SUPABASE_URL=https://ggznhxnsfngzswxztnkk.supabase.co
SUPABASE_ANON_KEY=sb_publishable_jogr_yVYxPcFD6gvmEz2fQ_iCmumPdJ
PAYSTACK_PUBLIC_KEY=pk_test_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
STORE_BASE_URL=https://priscyluxury.com
ADMIN_BASE_URL=https://admin.priscyluxury.com
```

> The publishable (anon) key is safe to ship in the Flutter web app.  
> The `service_role` secret key is **never** in the app — it lives only in Edge Function secrets.

## Database — Real Data Loaded

| Table | Rows | Notes |
|-------|------|-------|
| `categories` | 3 | Flat Sandals, Slides & Slippers, Leather Sandals |
| `products` | 20 | Full launch catalogue (GHS 110 – 310) |
| `product_variants` | 270 | Size × Colour matrix with stock (8 / 2 / 0 / 5 pattern) |
| `product_images` | 20 | Unsplash lifestyle photos |
| `delivery_zones` | 5 | Kumasi GH₵20, Accra GH₵35, Western/Central GH₵45, Eastern/Volta GH₵45, Rest GH₵55 |
| `pages` | 6 | about, contact, delivery, returns, privacy, terms |
| `site_settings` | 3 | general, hero, brand_story |
| `reviews` | 4 | Approved launch reviews |
| `orders` / `order_items` | 0 | Ready for live orders |

### Migrations Applied (via Supabase connector)

1. `priscy_initial_schema_v2` — enums, 16 tables, indexes, views (`best_sellers`, `product_ratings`), triggers, 6 RPCs (`create_order_with_reservation`, `confirm_order`, `cancel_order_and_release_stock`, `release_expired_reservations`, `adjust_variant_stock`)
2. `priscy_rls_and_storage` — RLS on all tables, 30+ policies, `product-images` bucket (public read, admin write), RPC lockdown to `service_role`
3. `priscy_seed_categories_zones` — categories, delivery zones, site settings
4. `priscy_seed_pages` — 6 Markdown policy pages
5. `priscy_seed_products` — 20 products
6. `priscy_seed_images_variants` — images, 270 variants, 4 reviews

## Edge Functions — All ACTIVE

| Function | Slug | Verify JWT | Purpose |
|----------|------|------------|---------|
| `create-order` | `create-order` | No | Atomic stock reservation + Paystack init |
| `paystack-webhook` | `paystack-webhook` | No | HMAC-SHA512 verify + confirm |
| `track-order` | `track-order` | No | Guest tracking (order + phone / token) |
| `submit-review` | `submit-review` | No | Verified-buyer reviews |
| `release-expired-reservations` | `release-expired-reservations` | No | Cron cleanup (CRON_SECRET protected) |
| `create-manual-order` | `create-manual-order` | **Yes** | Admin WhatsApp orders |
| `og-preview` | `og-preview` | No | Social share previews |

All functions were deployed with **inlined `_shared` helpers** (single-file bundles) via the Supabase Management API, matching the repo's `supabase/functions/*/index.ts` logic exactly.

### Secrets Set

- `STORE_BASE_URL=https://priscyluxury.com`
- `CRON_SECRET=priscy-cron-2026-secure`

### Secrets Still Needed (from Priscilla / Paystack)

Add these in **Supabase Dashboard → Edge Functions → Secrets** (or ask the agent to set them):

```bash
PAYSTACK_SECRET_KEY=sk_live_xxxxxxxxxxxx   # from Paystack Dashboard → Settings → API Keys
PAYSTACK_PUBLIC_KEY=pk_live_xxxxxxxxxxxx   # also put in Flutter .env
```

Then in **Paystack Dashboard → Settings → Webhooks**, add:

```
https://ggznhxnsfngzswxztnkk.supabase.co/functions/v1/paystack-webhook
```

## Auth Configuration

- Site URL: `https://priscyluxury.com`
- Redirect allow-list: `https://priscyluxury.com, https://admin.priscyluxury.com, http://localhost:3000, http://localhost:8080`
- Email auth: enabled, **auto-confirm ON** (instant signup for testing)
- Phone auth: enabled, SMS auto-confirm ON
- JWT expiry: 3600s, refresh rotation ON

## Next Steps for Priscilla

1. **Add Paystack keys** (see above) — enables real Mobile Money checkout.
2. **Create admin account:** Sign up at `/account` with `adupriscytwum@gmail.com`, then run in SQL Editor:
   ```sql
   update public.profiles set role = 'admin'
   where id = (select id from auth.users where email = 'adupriscytwum@gmail.com');
   ```
3. **Build & deploy Flutter:**
   ```bash
   flutter build web --target lib/main_store.dart --release --dart-define-from-file=.env -o build/store
   flutter build web --target lib/main_admin.dart --release --dart-define-from-file=.env -o build/admin
   ```
   Deploy `build/store` → `priscyluxury.com`, `build/admin` → `admin.priscyluxury.com`.
4. **Test live checkout:** Add a slipper to cart → Checkout → Pay with MoMo → Track at `/track`.

## Run Locally (Live Data)

```bash
flutter pub get
flutter run -d chrome -t lib/main_store.dart --dart-define-from-file=.env
flutter run -d chrome -t lib/main_admin.dart --dart-define-from-file=.env
```

Set `DEMO_MODE=true` in `.env` to fall back to offline demo data anytime.
