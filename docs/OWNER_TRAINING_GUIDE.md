# Priscy Luxury Slippers — Owner Operations & Training Guide

**Prepared for:** Priscilla Adutwum
**Admin Portal URL:** `https://admin.priscyluxury.com` (or local `lib/main_admin.dart`)
**Admin login:** Sign in at the **same login as customers** (`/account`) with `adupriscytwum@gmail.com` (temp password `PriscyAdmin2026!` — change it immediately). After sign-in you are auto-redirected to the Admin Dashboard (`/admin`). A gold **Admin** badge appears in the header.

---

## How the Whole System Works

```
CUSTOMER (Storefront)                    SELLER (You, Admin Dashboard)
─────────────────────                    ─────────────────────────────
1. Browse catalogue                      Dashboard: sales, low stock
2. Register / Sign In (REQUIRED)         Orders: verify payments, pack, dispatch
3. Add to cart → Checkout                Products: styles, prices, photos
4. Pay MoMo to 0550571248                Stock: size × colour grid, CSV import
5. Submit Transaction ID                 Reviews: approve customer reviews
6. Track order live                      Delivery: Ghana zone fees
                                         Content: banners, policy pages
                                         Reports: sales charts + CSV export
```

**Payment flow (manual MoMo only — no Paystack):**
1. Customer pays you directly on MoMo **0550571248 (Priscilla Adutwum)**
2. Customer submits Transaction ID in the app → order shows **⏳ Awaiting Verification**
3. You check your MoMo account → **Approve** in Admin → order becomes **Confirmed**, stock deducted
4. Customer gets WhatsApp confirmation automatically

**Registration rule:** Customers **must register/sign in before purchasing**. Guests can browse and add to cart, but Checkout asks them to create a free account first. This keeps every order linked to a real customer for tracking and reviews.

---

## 1. Daily Routine (5 Minutes Every Morning)

1. Sign in to **Priscy Admin** using your admin email and password.
2. Check the **Store Overview (Dashboard)** top cards:
   - **⏳ Payments to Verify:** Manual MoMo proofs waiting for your approval (tap to review).
   - **Orders to Dispatch:** Paid orders waiting to be packed and handed to a rider/VIP parcel courier.
   - **Low-Stock Variants:** Sizes/colours with 3 or fewer pairs remaining (tap **+5 Restock** anytime new stock arrives).

---

## 2. Verifying Manual MoMo Payments (The Most Important Step!)

**Website orders are confirmed ONLY after YOU verify the MoMo payment.** Stock is deducted when you approve.

1. Open **Orders** — a purple banner shows how many payments await verification. Tap **Review Queue** (or the **⏳ Awaiting Verification** filter chip).
2. Tap **Manage** on an order. The purple **Manual MoMo Payment** panel shows:
   - Expected amount, customer Transaction ID, sender name/phone, submission time
3. Check your MoMo account (MTN/Telecel/AT) for that Transaction ID and exact amount.
4. **If it matches:** Tap **✅ Approve & Confirm Order** → order becomes Confirmed, stock deducted, customer gets WhatsApp confirmation.
5. **If it doesn't match:** Enter a rejection reason (e.g. *"Amount mismatch — expected GH₵205.00"*) and tap **Reject Proof** → customer is asked to re-submit.

> **Tip:** You can also tap **Ask Customer on WhatsApp** from the panel to confirm details before approving.

---

## 3. Handling Website Orders (Confirmed -> Delivered)

1. Open **Orders** and filter by **Confirmed**.
2. Tap **Manage** on an order:
   - Tap **Packing Slip** to view/print the customer's address, landmark, phone number, and exact EU sizes/colours.
   - Change status to **Processing** while packing, then **Dispatched** once handed to the rider or VIP/STC parcel office (enter the waybill or rider number in **Tracking Note** and tap **Save Status Update**).
3. Tap the green **Send WhatsApp Update** button — WhatsApp opens with a polite, pre-written message containing the customer's order number and live tracking link. Just tap **Send**!
4. Once delivered or picked up in Kumasi, mark the order **Delivered** and tap **Send WhatsApp Update** to thank the buyer and invite a review.

> **Cancelling Before Dispatch:** If a customer asks to cancel before dispatch, setting status to **Cancelled** automatically restores the pair back into available inventory.

---

## 4. Handling WhatsApp Orders ("Create Manual Order")

When a shopper clicks **Order on WhatsApp** from the website (or messages `0550571248` from Instagram/TikTok):

1. Open **Manual WhatsApp Order** in the left menu.
2. Select the footwear style, size/colour variant, and quantity, then tap **Add Line**.
3. Enter the customer's name, Mobile Money/WhatsApp number, and choose **Delivery** (select Kumasi, Accra, or regional zone) or **Kumasi Pickup (Free)**.
4. Tap **Create Order & Generate WhatsApp Link**:
   - The system reserves the pair for **24 hours** and creates manual MoMo payment instructions.
   - Tap **Send Payment Instructions via WhatsApp** to send the MoMo number + proof link in one tap.
   - When the customer submits their Transaction ID, verify it in **Orders → ⏳ Awaiting Verification** (same as website orders).

---

## 5. Adding Products, Adjusting Prices & Importing CSV Stock

- **Quick Price Edit:** In **Products & Pricing**, tap the gold/sand price badge next to any slipper style to update its GHS price immediately.
- **Add / Edit a Style:** Tap **Add Product** (or **Edit**), enter the name, category (*Flat Sandals*, *Slides & Slippers*, *Leather Sandals*), audience (*Women*, *Men*, *Children*, *Unisex*), upload photos, and add size × colour variants.
- **Stock Grid & CSV Import:** Open **Variants, Stock & CSV**:
  - Use `-` / `+` / `+5` on any size × colour card for instant adjustments.
  - Tap **Import Stock CSV** to paste rows from Excel/Google Sheets (`product_slug,size,colour,stock_qty,price_override,sku`).
  - Scroll down to view the **Recent Stock History Log** showing every sale, restock, and cancellation.

---

## 6. Moderating Verified Customer Reviews

1. Open **Reviews Moderation** and switch to **Pending Approval**.
2. Every review has already been verified against a real paid order.
3. Tap **Approve** to publish it on the product page, **Hide** to unpublish, or the trash icon to remove it.

---

## 7. Editing Delivery Fees, Banners & Policy Pages

- **Delivery Zones:** Update GHS delivery fees or estimated days (e.g., Kumasi, Accra & Tema, Rest of Ghana) anytime in **Delivery Zones**.
- **Banners & Policy Pages:** Open **Content & Pages** to update the homepage hero headline, banner image, Kumasi pickup address, or any of the 6 policy pages (*About*, *Contact*, *Delivery*, *Returns & Exchanges*, *Privacy Policy*, *Terms & Conditions*).

---

## 8. Monthly Sales Reports & CSV Backups

At the end of every month, open **Sales Reports** and tap **Export Sales CSV** to save a copy of all paid orders for your business bookkeeping alongside Supabase's automated daily database backups.

---

## How to View Any Order (Quick Reference)

| What you want | Where to go |
|---|---|
| Payments waiting for verification | **Orders → ⏳ Awaiting Verification** chip (or purple banner) |
| All orders | **Orders → All** |
| One order's full details | **Orders → Manage** (customer, items, timeline, proof) |
| Print packing slip | **Manage → Packing Slip** |
| Message customer | **Manage → Send WhatsApp Update** (green button) |
| Customer's live tracking view | Share the order's tracking link from WhatsApp message |
| Today's sales | **Dashboard** top cards + **Reports** charts |
