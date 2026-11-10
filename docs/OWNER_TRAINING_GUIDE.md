# Priscy Luxury Slippers — Owner Operations & Training Guide

**Prepared for:** Priscilla Adutwum  
**Admin Portal URL:** `https://admin.priscyluxury.com` (or local `lib/main_admin.dart`)

---

## 1. Daily Routine (5 Minutes Every Morning)

1. Sign in to **Priscy Admin** using your admin email and password.
2. Check the **Store Overview (Dashboard)** top cards:
   - **Orders to Dispatch:** Paid orders waiting to be packed and handed to a rider/VIP parcel courier.
   - **Low-Stock Variants:** Sizes/colours with 3 or fewer pairs remaining (tap **+5 Restock** anytime new stock arrives).

---

## 2. Handling Website Orders (Confirmed -> Delivered)

Remember: **Website orders are confirmed automatically only after Paystack verifies Mobile Money payment.** Stock is deducted automatically.

1. Open **Orders** in the left menu and filter by **Confirmed**.
2. Tap **Manage** on an order:
   - Tap **Packing Slip** to view/print the customer's address, landmark, phone number, and exact EU sizes/colours.
   - Change status to **Processing** while packing, then **Dispatched** once handed to the rider or VIP/STC parcel office (enter the waybill or rider number in **Tracking Note** and tap **Save Status Update**).
3. Tap the green **Send WhatsApp Update** button—WhatsApp opens with a polite, pre-written message containing the customer's order number and live tracking link. Just tap **Send**!
4. Once delivered or picked up in Kumasi, mark the order **Delivered** and tap **Send WhatsApp Update** to thank the buyer and invite a review.

> **Cancelling Before Dispatch:** If a customer asks to cancel before dispatch, setting status to **Cancelled** automatically restores the pair back into available inventory.

---

## 3. Handling WhatsApp Orders ("Create Manual Order")

When a shopper clicks **Order on WhatsApp** from the website (or messages `0550571248` from Instagram/TikTok):

1. Open **Manual WhatsApp Order** in the left menu.
2. Select the footwear style, size/colour variant, and quantity, then tap **Add Line**.
3. Enter the customer's name, Mobile Money/WhatsApp number, and choose **Delivery** (select Kumasi, Accra, or regional zone) or **Kumasi Pickup (Free)**.
4. Tap **Create Order & Generate WhatsApp Link**:
   - The system reserves the pair for **15 minutes** and creates a Paystack Mobile Money link.
   - Tap **Send Payment Link via WhatsApp** to send the payment link in one tap. Once the customer approves the Mobile Money prompt on their phone, the order moves automatically to **Confirmed**!

---

## 4. Adding Products, Adjusting Prices & Importing CSV Stock

- **Quick Price Edit:** In **Products & Pricing**, tap the gold/sand price badge next to any slipper style to update its GHS price immediately.
- **Add / Edit a Style:** Tap **Add Product** (or **Edit**), enter the name, category (*Flat Sandals*, *Slides & Slippers*, *Leather Sandals*), audience (*Women*, *Men*, *Children*, *Unisex*), upload photos, and add size × colour variants.
- **Stock Grid & CSV Import:** Open **Variants, Stock & CSV**:
  - Use `-` / `+` / `+5` on any size × colour card for instant adjustments.
  - Tap **Import Stock CSV** to paste rows from Excel/Google Sheets (`product_slug,size,colour,stock_qty,price_override,sku`).
  - Scroll down to view the **Recent Stock History Log** showing every sale, restock, and cancellation.

---

## 5. Moderating Verified Customer Reviews

1. Open **Reviews Moderation** and switch to **Pending Approval**.
2. Every review has already been verified against a real paid order.
3. Tap **Approve** to publish it on the product page, **Hide** to unpublish, or the trash icon to remove it.

---

## 6. Editing Delivery Fees, Banners & Policy Pages

- **Delivery Zones:** Update GHS delivery fees or estimated days (e.g., Kumasi, Accra & Tema, Rest of Ghana) anytime in **Delivery Zones**.
- **Banners & Policy Pages:** Open **Content & Pages** to update the homepage hero headline, banner image, Kumasi pickup address, or any of the 6 policy pages (*About*, *Contact*, *Delivery*, *Returns & Exchanges*, *Privacy Policy*, *Terms & Conditions*).

---

## 7. Monthly Sales Reports & CSV Backups

At the end of every month, open **Sales Reports** and tap **Export Sales CSV** to save a copy of all paid orders for your business bookkeeping alongside Supabase's automated daily database backups.
