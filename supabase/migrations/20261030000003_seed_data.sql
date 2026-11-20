-- =============================================================================
-- Priscy Luxury Slippers — Launch Seed Data (Categories, 20 Styles, Zones, Pages)
-- Migration: 20261030000003_seed_data.sql
-- =============================================================================

-- 1. Categories
insert into public.categories (id, name, slug, sort_order) values
  ('11111111-1111-4111-8111-111111111101', 'Flat Sandals', 'flat-sandals', 1),
  ('11111111-1111-4111-8111-111111111102', 'Slides & Slippers', 'slides-slippers', 2),
  ('11111111-1111-4111-8111-111111111103', 'Leather Sandals', 'leather-sandals', 3)
on conflict (slug) do nothing;

-- 2. Delivery Zones across Ghana
insert into public.delivery_zones (id, region, city, fee, est_days_min, est_days_max, is_active) values
  ('22222222-2222-4222-8222-222222222201', 'Ashanti Region', 'Kumasi', 20.00, 1, 2, true),
  ('22222222-2222-4222-8222-222222222202', 'Greater Accra', 'Accra & Tema', 35.00, 3, 4, true),
  ('22222222-2222-4222-8222-222222222203', 'Western & Central', 'Takoradi & Cape Coast', 45.00, 3, 5, true),
  ('22222222-2222-4222-8222-222222222204', 'Eastern & Volta', 'Koforidua & Ho', 45.00, 3, 5, true),
  ('22222222-2222-4222-8222-222222222205', 'Rest of Ghana', 'Nationwide Courier / VIP Parcel', 55.00, 3, 5, true)
on conflict (id) do nothing;

-- 3. Site Settings
insert into public.site_settings (key, value) values
  ('general', '{
    "brand_name": "Priscy Luxury Slippers",
    "owner_name": "Priscilla Adutwum",
    "slogan": "Premium quality, affordable prices, unbeatable style!",
    "phone": "0550571248",
    "whatsapp_number": "233550571248",
    "email": "adupriscytwum@gmail.com",
    "currency": "GHS",
    "pickup_address": "Adum / Kejetia Showroom Pickup Point, Kumasi, Ashanti Region",
    "low_stock_threshold": 3
  }'::jsonb),
  ('hero', '{
    "headline": "Handcrafted Elegance for Every Step Across Ghana",
    "subheadline": "Premium quality, affordable prices, unbeatable style! Discover cushioned slides, artisan leather sandals, and effortless flats for women, men, and children.",
    "cta_label": "Shop the Launch Collection",
    "banner_url": "https://images.unsplash.com/photo-1543163521-1bf539c55dd2?auto=format&fit=crop&w=1400&q=80"
  }'::jsonb),
  ('brand_story', '{
    "title": "Designed for Comfort, Built to Last",
    "body": "Born in Kumasi and loved across Ghana, Priscy Luxury Slippers pairs supple leathers, cushioned footbeds, and timeless silhouettes that take you effortlessly from weekday errands to weekend celebrations."
  }'::jsonb)
on conflict (key) do nothing;

-- 4. Static Pages
insert into public.pages (slug, title, body_markdown) values
  ('about', 'About Priscy Luxury Slippers',
'## Premium Quality, Affordable Prices, Unbeatable Style!

Founded by **Priscilla Adutwum**, **Priscy Luxury Slippers** is a Ghanaian footwear brand reimagined for modern everyday elegance. We curate and craft durable flat sandals, plush slides, and classic leather sandals for **women, men, and children**.

### Why Ghanaian Shoppers Love Us
- **All-Day Cushioning:** Soft, supportive footbeds tailored for warm climates and busy days.
- **Honest Pricing in GHS:** Luxury craftsmanship without the luxury markup.
- **Nationwide Reach:** Fast dispatch from Kumasi to Accra and every region in Ghana.
- **Personal Service:** Order seamlessly online with Mobile Money or chat directly with us on WhatsApp at **0550571248**.'),

  ('contact', 'Contact Us',
'## Get in Touch

We would love to help you choose the right size, style, or delivery option.

- **Phone & WhatsApp:** 0550571248 (`+233 55 057 1248`)
- **Email:** adupriscytwum@gmail.com
- **Pickup Location:** Adum / Kejetia Pickup Point, Kumasi (arranged upon order confirmation)
- **Customer Care Hours:** Monday – Saturday, 8:00 AM – 7:00 PM GMT'),

  ('delivery', 'Delivery Information',
'## Nationwide Delivery Across Ghana

We deliver across all regions of Ghana within **3 to 5 working days** (and often **1 to 2 working days** within Kumasi).

### Delivery Zones & Estimated Timelines
- **Kumasi (Ashanti Region):** 1 – 2 working days
- **Accra & Tema (Greater Accra):** 3 – 4 working days
- **Rest of Ghana (VIP / STC / Courier):** 3 – 5 working days
- **Showroom / Local Pickup (Kumasi):** Free — ready after payment confirmation

### Important Delivery Policy
- **Payment Before Delivery:** All orders are confirmed and dispatched after full Mobile Money payment is verified.
- **WhatsApp Updates:** You will receive updates for **Order Received**, **Payment Confirmed**, **Dispatched**, and **Delivered**.'),

  ('returns', 'Returns & Exchange Policy',
'## Size & Colour Exchange Policy

We want every pair from **Priscy Luxury Slippers** to fit beautifully.

### Exchanges Allowed
- **Size and colour exchanges are allowed** within **3 days** of receiving your order.
- Footwear must be **unworn outdoors**, clean, and in its original packaging.
- Subject to variant availability; if your requested size/colour is unavailable, you may exchange for another style of equal value.
- Return and re-dispatch delivery fees are borne by the buyer unless we sent an incorrect item.

### No Cash Refunds
- **Payments are strictly non-refundable.** Once Mobile Money payment is completed, orders qualify for size/colour exchange only.'),

  ('privacy', 'Privacy Policy',
'## Privacy Policy (Ghana Data Protection Act Compliance)

**Priscy Luxury Slippers** respects your privacy in accordance with **Ghana''s Data Protection Act, 2012 (Act 843)**.

### What We Collect
- Your name, Mobile Money / phone number, WhatsApp number, and delivery address solely to process, deliver, and support your orders.
- Payment details are handled directly on **Paystack''s secure hosted page** and never stored on our servers.

### Your Rights
- You may request access to, correction of, or deletion of your personal profile data at any time by emailing **adupriscytwum@gmail.com** or messaging **0550571248**.'),

  ('terms', 'Terms & Conditions',
'## Terms & Conditions

1. **Currency & Pricing:** All prices are listed in **Ghana Cedis (GHS)** and verified server-side at checkout.
2. **Stock Reservation:** Starting Mobile Money checkout reserves your chosen pair for **15 minutes**. Unpaid reservations expire automatically.
3. **Order Confirmation:** An order—whether placed on the website or via WhatsApp—is confirmed only after full Mobile Money payment is verified.
4. **Exchanges & Non-Refundable Payments:** Payments are non-refundable. Eligible unworn items may be exchanged for size or colour within 3 days of delivery.')
on conflict (slug) do nothing;

-- 5. 20 Launch Products
insert into public.products (id, category_id, name, slug, description, base_price, audience, is_active, is_featured) values
  ('33333333-3333-4333-8333-333333333301', '11111111-1111-4111-8111-111111111102', 'Adowa Gold-Buckle Luxury Slide', 'adowa-gold-buckle-slide', 'Supple faux-calfskin upper finished with a brushed gold buckle and contoured memory footbed.', 185.00, 'women', true, true),
  ('33333333-3333-4333-8333-333333333302', '11111111-1111-4111-8111-111111111103', 'Kumasi Royal Crossover Leather Sandal', 'kumasi-royal-crossover-leather', 'Hand-stitched full-grain leather straps with a durable non-slip rubber outsole built for everyday wear.', 260.00, 'men', true, true),
  ('33333333-3333-4333-8333-333333333303', '11111111-1111-4111-8111-111111111101', 'Osu Minimalist Toe-Ring Flat', 'osu-minimalist-toe-ring-flat', 'Sleek asymmetric strap and soft toe-ring silhouette ideal for dresses, kaftans, and smart-casual looks.', 165.00, 'women', true, true),
  ('33333333-3333-4333-8333-333333333304', '11111111-1111-4111-8111-111111111102', 'Cantonments Quilted Cloud Slipper', 'cantonments-quilted-cloud-slipper', 'Plush diamond-quilted wide band over a featherlight cushioned sole for effortless glamour.', 195.00, 'women', true, true),
  ('33333333-3333-4333-8333-333333333305', '11111111-1111-4111-8111-111111111103', 'Ashanti Heritage Double-Strap Leather', 'ashanti-heritage-double-strap', 'Rich espresso vegetable-tanned leather with twin adjustable brass buckles and cork-cushion support.', 280.00, 'men', true, true),
  ('33333333-3333-4333-8333-333333333306', '11111111-1111-4111-8111-111111111101', 'Aburi Woven Raffia & Leather Flat', 'aburi-woven-raffia-flat', 'Breathable woven texture trimmed in smooth tan leather for warm afternoons and weekend brunches.', 175.00, 'women', true, false),
  ('33333333-3333-4333-8333-333333333307', '11111111-1111-4111-8111-111111111102', 'Labadi Resort H-Band Slide', 'labadi-resort-h-band-slide', 'Iconic H-cutout resort slide crafted with reinforced edge stitching and padded heel comfort.', 190.00, 'women', true, true),
  ('33333333-3333-4333-8333-333333333308', '11111111-1111-4111-8111-111111111103', 'Manhyia Classic Men''s Palm Slipper', 'manhyia-classic-palm-slipper', 'Traditional Ghanaian gentleman''s leather palm slipper elevated with a modern orthopaedic insole.', 270.00, 'men', true, true),
  ('33333333-3333-4333-8333-333333333309', '11111111-1111-4111-8111-111111111101', 'Sankofa Junior Comfort Ankle Sandal', 'sankofa-junior-ankle-sandal', 'Easy hook-and-loop ankle strap with flexible grip soles for active children at church and parties.', 125.00, 'children', true, true),
  ('33333333-3333-4333-8333-333333333310', '11111111-1111-4111-8111-111111111102', 'Little Royals Cushioned Kids Slide', 'little-royals-kids-slide', 'Soft moulded footbed and wipe-clean strap built to keep growing feet comfortable all day.', 110.00, 'children', true, false),
  ('33333333-3333-4333-8333-333333333311', '11111111-1111-4111-8111-111111111101', 'East Legon Braided Metallic Flat', 'east-legon-braided-metallic-flat', 'Delicate hand-braided straps in soft gold and rose shimmer for weddings, engagements, and dinners.', 210.00, 'women', true, false),
  ('33333333-3333-4333-8333-333333333312', '11111111-1111-4111-8111-111111111103', 'Airport City Executive Leather Mule', 'airport-city-leather-mule', 'Clean open-back leather slip-on pairing sharp tailoring with Friday traditional wear.', 295.00, 'men', true, false),
  ('33333333-3333-4333-8333-333333333313', '11111111-1111-4111-8111-111111111102', 'Volta Everyday Unisex Cushion Slide', 'volta-everyday-unisex-slide', 'Water-resistant contoured EVA + leather-grain strap made for effortless indoor-outdoor wear.', 145.00, 'unisex', true, false),
  ('33333333-3333-4333-8333-333333333314', '11111111-1111-4111-8111-111111111101', 'Ahodwo Pearl-Studded Evening Flat', 'ahodwo-pearl-evening-flat', 'Subtle pearl accents set along satin-lined straps for graceful occasion wear without heel fatigue.', 220.00, 'women', true, false),
  ('33333333-3333-4333-8333-333333333315', '11111111-1111-4111-8111-111111111103', 'Nhyiaeso Woven Leather Fisherman Sandal', 'nhyiaeso-woven-leather-sandal', 'Interlaced genuine leather straps with breathable side cutouts and stitched welt durability.', 275.00, 'men', true, false),
  ('33333333-3333-4333-8333-333333333316', '11111111-1111-4111-8111-111111111102', 'Spintex Knot-Bow Velvet Touch Slide', 'spintex-knot-bow-slide', 'Sculpted knot bow upper in rich sand and rose tones over a non-marking rubber sole.', 180.00, 'women', true, false),
  ('33333333-3333-4333-8333-333333333317', '11111111-1111-4111-8111-111111111103', 'Junior Heritage Leather Sunday Sandal', 'junior-heritage-leather-sandal', 'Smart stitched leather sandal for boys and girls with cushioned arch support.', 140.00, 'children', true, false),
  ('33333333-3333-4333-8333-333333333318', '11111111-1111-4111-8111-111111111101', 'Tema Harbour Cross-Band Everyday Flat', 'tema-harbour-cross-band-flat', 'Ultra-flexible everyday cross-band sandal crafted for commuters and market-to-office versatility.', 155.00, 'women', true, false),
  ('33333333-3333-4333-8333-333333333319', '11111111-1111-4111-8111-111111111102', 'Bantama Luxe Croc-Embossed Slide', 'bantama-croc-embossed-slide', 'Subtle croc-embossed strap with tonal stitching and sweat-resistant microfibre lining.', 205.00, 'unisex', true, false),
  ('33333333-3333-4333-8333-333333333320', '11111111-1111-4111-8111-111111111103', 'Asokwa Signature Gold-Trim Leather Sandal', 'asokwa-signature-gold-leather', 'Our flagship artisan leather sandal featuring hand-burnished edges and a signature gold heel emblem.', 310.00, 'women', true, true)
on conflict (slug) do nothing;

-- 6. Product Images (one primary + secondary lifestyle shot for key products)
insert into public.product_images (product_id, url, sort_order) values
  ('33333333-3333-4333-8333-333333333301', 'https://images.unsplash.com/photo-1603487742131-4160ec999306?auto=format&fit=crop&w=900&q=80', 0),
  ('33333333-3333-4333-8333-333333333302', 'https://images.unsplash.com/photo-1562273138-f46be4ebdf33?auto=format&fit=crop&w=900&q=80', 0),
  ('33333333-3333-4333-8333-333333333303', 'https://images.unsplash.com/photo-1543163521-1bf539c55dd2?auto=format&fit=crop&w=900&q=80', 0),
  ('33333333-3333-4333-8333-333333333304', 'https://images.unsplash.com/photo-1595950653106-6c9ebd614d3a?auto=format&fit=crop&w=900&q=80', 0),
  ('33333333-3333-4333-8333-333333333305', 'https://images.unsplash.com/photo-1531310197839-ccf54634509e?auto=format&fit=crop&w=900&q=80', 0),
  ('33333333-3333-4333-8333-333333333306', 'https://images.unsplash.com/photo-1515347619252-60a4bf4fff4f?auto=format&fit=crop&w=900&q=80', 0),
  ('33333333-3333-4333-8333-333333333307', 'https://images.unsplash.com/photo-1603487742131-4160ec999306?auto=format&fit=crop&w=900&q=80', 0),
  ('33333333-3333-4333-8333-333333333308', 'https://images.unsplash.com/photo-1562273138-f46be4ebdf33?auto=format&fit=crop&w=900&q=80', 0),
  ('33333333-3333-4333-8333-333333333309', 'https://images.unsplash.com/photo-1514989940723-e8e51635b782?auto=format&fit=crop&w=900&q=80', 0),
  ('33333333-3333-4333-8333-333333333310', 'https://images.unsplash.com/photo-1514989940723-e8e51635b782?auto=format&fit=crop&w=900&q=80', 0),
  ('33333333-3333-4333-8333-333333333311', 'https://images.unsplash.com/photo-1543163521-1bf539c55dd2?auto=format&fit=crop&w=900&q=80', 0),
  ('33333333-3333-4333-8333-333333333312', 'https://images.unsplash.com/photo-1531310197839-ccf54634509e?auto=format&fit=crop&w=900&q=80', 0),
  ('33333333-3333-4333-8333-333333333313', 'https://images.unsplash.com/photo-1603487742131-4160ec999306?auto=format&fit=crop&w=900&q=80', 0),
  ('33333333-3333-4333-8333-333333333314', 'https://images.unsplash.com/photo-1515347619252-60a4bf4fff4f?auto=format&fit=crop&w=900&q=80', 0),
  ('33333333-3333-4333-8333-333333333315', 'https://images.unsplash.com/photo-1562273138-f46be4ebdf33?auto=format&fit=crop&w=900&q=80', 0),
  ('33333333-3333-4333-8333-333333333316', 'https://images.unsplash.com/photo-1595950653106-6c9ebd614d3a?auto=format&fit=crop&w=900&q=80', 0),
  ('33333333-3333-4333-8333-333333333317', 'https://images.unsplash.com/photo-1514989940723-e8e51635b782?auto=format&fit=crop&w=900&q=80', 0),
  ('33333333-3333-4333-8333-333333333318', 'https://images.unsplash.com/photo-1543163521-1bf539c55dd2?auto=format&fit=crop&w=900&q=80', 0),
  ('33333333-3333-4333-8333-333333333319', 'https://images.unsplash.com/photo-1531310197839-ccf54634509e?auto=format&fit=crop&w=900&q=80', 0),
  ('33333333-3333-4333-8333-333333333320', 'https://images.unsplash.com/photo-1603487742131-4160ec999306?auto=format&fit=crop&w=900&q=80', 0);

-- 7. Generate Variants (Sizes × Colours) Across All 20 Products
insert into public.product_variants (product_id, size, colour, sku, stock_qty, reserved_qty)
select
  p.id,
  sz.size_label,
  col.colour_label,
  upper(left(p.slug, 6)) || '-' || sz.size_label || '-' || upper(left(col.colour_label, 3)),
  case
    when sz.ord = 1 and col.ord = 1 then 8
    when sz.ord = 2 and col.ord = 1 then 2 -- low-stock example
    when sz.ord = 3 and col.ord = 2 then 0 -- out-of-stock example
    else 5
  end,
  0
from public.products p
cross join lateral (
  select *
  from (
    values
      ('women', '37', 1), ('women', '38', 2), ('women', '39', 3), ('women', '40', 4), ('women', '41', 5),
      ('men', '41', 1), ('men', '42', 2), ('men', '43', 3), ('men', '44', 4), ('men', '45', 5),
      ('children', '30', 1), ('children', '32', 2), ('children', '34', 3),
      ('unisex', '39', 1), ('unisex', '41', 2), ('unisex', '43', 3)
  ) as s(aud, size_label, ord)
  where s.aud = p.audience::text
) sz
cross join (
  values
    ('Espresso', 1),
    ('Gold', 2),
    ('Sand', 3)
) as col(colour_label, ord)
on conflict (product_id, size, colour) do nothing;

-- 8. Approved Initial Reviews
insert into public.reviews (product_id, reviewer_name, rating, comment, is_approved) values
  ('33333333-3333-4333-8333-333333333301', 'Akosua Mensah (Kumasi)', 5, 'Super soft footbed and the gold buckle looks even richer in person! Delivered to Ahodwo next day.', true),
  ('33333333-3333-4333-8333-333333333302', 'Kwame Boateng (Accra)', 5, 'Genuine leather quality at a very fair GHS price. Wore them with my kaftan all Sunday.', true),
  ('33333333-3333-4333-8333-333333333303', 'Efua Ofori (Tema)', 4, 'True to size EU 39 and very classy. WhatsApp updates kept me informed throughout.', true),
  ('33333333-3333-4333-8333-333333333309', 'Ama Serwaa (Kumasi)', 5, 'My daughter loves her Sankofa sandals—sturdy strap and easy to clean.', true);
