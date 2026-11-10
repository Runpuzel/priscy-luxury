# Priscy Luxury Slippers — E-commerce Web App (Flutter + Supabase)

> **Prepared for:** Priscilla Adutwum, *Priscy Luxury Slippers*  
> **Slogan:** *"Premium quality, affordable prices, unbeatable style!"*  
> **Contact / WhatsApp:** `0550571248` (`+233 55 057 1248`) • `adupriscytwum@gmail.com`

A responsive **Flutter Web customer storefront** and **Flutter Web owner admin dashboard** sharing a single typed codebase, backed by **Supabase** (Postgres, Row Level Security, Auth, Storage, and Deno Edge Functions), **Paystack Ghana Mobile Money (GHS)**, and **1-tap WhatsApp order & status workflows**.

---

## 1. Architecture & Repository Layout

```text
priscy-luxury/
├── lib/
│   ├── main_store.dart             # Customer storefront entry point
│   ├── main_admin.dart             # Owner admin dashboard entry point
│   ├── main.dart                   # Default convenience entry (-> main_store.dart)
│   ├── core/
│   │   ├── config/                 # Environment config, path URL strategy & Supabase bootstrap
│   │   ├── theme/                  # Espresso/Sand/Gold/Rose luxury palette & Playfair/Jakarta typography
│   │   ├── router/                 # GoRouter configs for Storefront & Admin (with role guard)
│   │   ├── utils/                  # GHS formatter, Ghana phone validator, stock/price calc, WhatsApp links
│   │   └── widgets/                # StoreScaffold, AdminScaffold, ProductCard, swatches, Markdown renderer
│   ├── data/
│   │   ├── models/                 # Strongly typed immutable models (Product, Variant, Order, Review, ...)
│   │   ├── seed/                   # Pre-seeded 20 Ghana footwear styles, delivery zones, orders & policies
│   │   ├── repositories/           # Dual-mode repositories (Interactive Demo Mode + Live Supabase Mode)
│   │   └── providers.dart          # Riverpod providers & persisted CartNotifier
│   └── features/
│       ├── store/                  # home, catalogue, product, cart, checkout, tracking, account, pages
│       └── admin/                  # auth, dashboard, orders, products, stock, reviews, delivery, content, reports
├── supabase/
│   ├── config.toml                 # Supabase CLI project & Edge Function configuration
│   ├── migrations/
│   │   ├── 20261030000001_initial_schema.sql   # Enums, tables, views, triggers & transactional RPCs
│   │   ├── 20261030000002_rls_and_storage.sql  # Strict RLS on every table + product-images bucket
│   │   └── 20261030000003_seed_data.sql        # 3 categories, 20 styles, Ghana delivery zones & policy pages
│   ├── functions/
│   │   ├── create-order/           # Server-side price & stock check, 15-min reservation, Paystack init
│   │   ├── paystack-webhook/       # HMAC-SHA512 signature check + API re-verify + atomic stock deduction
│   │   ├── track-order/            # Rate-limited guest order lookup (order_number + phone or secret token)
│   │   ├── submit-review/          # Rate-limited verified-buyer check + pending moderation insert
│   │   ├── release-expired-reservations/ # Cron job releasing unpaid 15-min reservations every 5 min
│   │   ├── create-manual-order/    # Admin-only manual WhatsApp order + Paystack payment link builder
│   │   └── og-preview/             # Dynamic Open Graph social preview HTML for WhatsApp/Instagram links
│   └── tests/
│       └── rls_policies_test.sql   # SQL verification suite proving RLS isolation
├── test/                           # Unit & end-to-end checkout/stock/WhatsApp tests
├── web/                            # Branded loader, SEO landing.html, robots.txt, sitemap.xml, _redirects
└── docs/
    └── OWNER_TRAINING_GUIDE.md     # Illustrated-style step-by-step operations manual for Priscilla
```

---

## 2. Quick Start — Interactive Demo Mode (Zero Setup Required)

When `SUPABASE_URL` is omitted (or `DEMO_MODE=true`), the app automatically runs in **Interactive Demo Mode** backed by browser `localStorage` (`SharedPreferences`) pre-seeded with:
- **20 luxury footwear styles** across *Flat Sandals*, *Slides & Slippers*, and *Leather Sandals* for Women, Men, and Children
- **5 Ghana delivery zones** (Kumasi, Accra & Tema, Takoradi & Cape Coast, Koforidua & Ho, Rest of Ghana) + **Free Kumasi Pickup**
- **Simulated Paystack Mobile Money checkout** (MTN MoMo, Telecel Cash, AT Money)
- **Sample trackable orders** (try Order `PSY-20261030-0001` + Phone `0244123456` on `/track`)
- **Full Admin Portal** (pre-filled with owner demo login)

```bash
flutter pub get

# Run Customer Storefront in Chrome
flutter run -d chrome -t lib/main_store.dart

# Run Owner Admin Dashboard in Chrome
flutter run -d chrome -t lib/main_admin.dart
```

---

## 3. Connecting Live Supabase & Paystack

### Step 1: Apply Database Migrations & Seed Data
```bash
supabase link --project-ref <your-supabase-project-ref>
supabase db push
```

### Step 2: Set Edge Function Secrets & Deploy Functions
> **Security Rule:** `SUPABASE_SERVICE_ROLE_KEY` and `PAYSTACK_SECRET_KEY` live **only** in Supabase Edge Function secrets—never in the Flutter web app.

```bash
supabase secrets set \
  PAYSTACK_SECRET_KEY=sk_live_xxxxxxxxxxxx \
  STORE_BASE_URL=https://priscyluxury.com \
  CRON_SECRET=choose-a-strong-random-secret

supabase functions deploy create-order
supabase functions deploy paystack-webhook
supabase functions deploy track-order
supabase functions deploy submit-review
supabase functions deploy release-expired-reservations
supabase functions deploy create-manual-order
supabase functions deploy og-preview
```

Configure your Paystack Dashboard Webhook URL to:
`https://<your-project-ref>.supabase.co/functions/v1/paystack-webhook`

### Step 3: Promote the First Owner Admin Account
Sign up with Priscilla's email once, then run in the Supabase SQL Editor:
```sql
update public.profiles
set role = 'admin'
where id = (select id from auth.users where email = 'adupriscytwum@gmail.com');
```

### Step 4: Configure `.env` & Build for Production
Copy `.env.example` to `.env`, set `DEMO_MODE=false`, and populate `SUPABASE_URL`, `SUPABASE_ANON_KEY`, and `PAYSTACK_PUBLIC_KEY`:

```bash
# Build Customer Storefront -> deploy build/store to priscyluxury.com
flutter build web --target lib/main_store.dart --release --dart-define-from-file=.env -o build/store

# Build Admin Dashboard -> deploy build/admin to admin.priscyluxury.com
flutter build web --target lib/main_admin.dart --release --dart-define-from-file=.env -o build/admin
```

---

## 4. Running Tests

```bash
# Unit & checkout integration tests
flutter test

# Database RLS security verification (against local Supabase stack)
psql "$SUPABASE_DB_URL" -f supabase/tests/rls_policies_test.sql
```
