import '../models/models.dart';

class DemoSeedData {
  const DemoSeedData._();

  static const List<Category> categories = [
    Category(
      id: 'cat-flat-sandals',
      name: 'Flat Sandals',
      slug: 'flat-sandals',
      sortOrder: 1,
    ),
    Category(
      id: 'cat-slides-slippers',
      name: 'Slides & Slippers',
      slug: 'slides-slippers',
      sortOrder: 2,
    ),
    Category(
      id: 'cat-leather-sandals',
      name: 'Leather Sandals',
      slug: 'leather-sandals',
      sortOrder: 3,
    ),
  ];

  static const List<DeliveryZone> deliveryZones = [
    DeliveryZone(
      id: 'zone-kumasi',
      region: 'Ashanti Region',
      city: 'Kumasi (Adum, Ahodwo, KNUST, Asokwa)',
      fee: 20.00,
      estDaysMin: 1,
      estDaysMax: 2,
    ),
    DeliveryZone(
      id: 'zone-accra',
      region: 'Greater Accra',
      city: 'Accra & Tema',
      fee: 35.00,
      estDaysMin: 3,
      estDaysMax: 4,
    ),
    DeliveryZone(
      id: 'zone-western-central',
      region: 'Western & Central',
      city: 'Takoradi & Cape Coast',
      fee: 45.00,
      estDaysMin: 3,
      estDaysMax: 5,
    ),
    DeliveryZone(
      id: 'zone-eastern-volta',
      region: 'Eastern & Volta',
      city: 'Koforidua & Ho',
      fee: 45.00,
      estDaysMin: 3,
      estDaysMax: 5,
    ),
    DeliveryZone(
      id: 'zone-rest-ghana',
      region: 'Rest of Ghana',
      city: 'Sunyani, Tamale, Wa, Bolgatanga (VIP / Courier)',
      fee: 55.00,
      estDaysMin: 3,
      estDaysMax: 5,
    ),
  ];

  static const SiteSettings siteSettings = SiteSettings();

  static List<StaticPageContent> buildStaticPages() {
    final now = DateTime(2026, 10, 30);
    return [
      StaticPageContent(
        slug: 'about',
        title: 'About Priscy Luxury Slippers',
        updatedAt: now,
        bodyMarkdown: '''## Premium Quality, Affordable Prices, Unbeatable Style!

Founded by **Priscilla Adutwum**, **Priscy Luxury Slippers** is a proudly Ghanaian footwear house rebranding to bring handcrafted elegance online across every region of Ghana.

We specialize in supple **flat sandals**, plush **slides & slippers**, and enduring **leather sandals** designed for **women, men, and children**.

### Our Promise
- **Comfort First:** Contoured, cushioned footbeds built for warm weather and long days.
- **Fair Ghana Cedis Pricing:** Honest luxury without middleman markups.
- **Seamless Ordering:** Checkout online with Mobile Money or order with one tap via WhatsApp at **0550571248**.
- **Nationwide Delivery:** Reliable dispatch from Kumasi to Accra and nationwide in 3 to 5 days.''',
      ),
      StaticPageContent(
        slug: 'contact',
        title: 'Contact Us',
        updatedAt: now,
        bodyMarkdown: '''## Speak With Priscy Luxury Slippers

Need sizing guidance, bulk family orders, or delivery help? Reach out directly:

- **Phone & WhatsApp:** 0550571248 (`+233 55 057 1248`)
- **Email:** adupriscytwum@gmail.com
- **Kumasi Pickup Point:** Adum / Kejetia Showroom Pickup Point, Kumasi (shared upon order confirmation)
- **Hours:** Monday – Saturday, 8:00 AM – 7:00 PM GMT''',
      ),
      StaticPageContent(
        slug: 'delivery',
        title: 'Delivery Information',
        updatedAt: now,
        bodyMarkdown: '''## Nationwide Delivery Across Ghana

We deliver nationwide across Ghana within **3 to 5 working days** (and **1 to 2 working days** within Kumasi).

### Standard Delivery Zones
- **Kumasi (Ashanti Region):** GHS 20.00 (1 – 2 working days)
- **Accra & Tema (Greater Accra):** GHS 35.00 (3 – 4 working days)
- **Takoradi, Cape Coast, Koforidua & Ho:** GHS 45.00 (3 – 5 working days)
- **Rest of Ghana (VIP / STC / Courier):** GHS 55.00 (3 – 5 working days)
- **Kumasi Pickup:** Free (0.00 GHS) after Mobile Money confirmation

### Payment Before Delivery
All orders are confirmed and dispatched strictly after Mobile Money payment is verified. You will receive WhatsApp notifications for **Order Received**, **Payment Confirmed**, **Dispatched**, and **Delivered**.''',
      ),
      StaticPageContent(
        slug: 'returns',
        title: 'Returns & Exchange Policy',
        updatedAt: now,
        bodyMarkdown: '''## Size & Colour Exchange Policy

We want you to love the fit and feel of your Priscy Luxury Slippers.

### Exchanges Allowed
- **Size and colour exchanges are allowed** within **3 days** of delivery or pickup.
- Pairs must be **unworn outdoors**, clean, and returned in original packaging.
- Return and re-delivery courier fees are covered by the customer unless we dispatched the wrong size or style.

### Non-Refundable Payments
- **Payments are not refundable.** Completed Mobile Money payments are eligible for size, colour, or equal-value style exchange only.''',
      ),
      StaticPageContent(
        slug: 'privacy',
        title: 'Privacy Policy',
        updatedAt: now,
        bodyMarkdown: '''## Privacy Policy

**Priscy Luxury Slippers** protects your personal data in compliance with **Ghana's Data Protection Act, 2012 (Act 843)**.

### Data We Collect
- Name, Mobile Money phone number, WhatsApp number, and delivery address solely to fulfil your order and send order status updates.
- Mobile Money PINs and payment credentials are entered exclusively on **Paystack's encrypted checkout** and never touch our servers.

### Data Deletion & Access
To request a copy or deletion of your account information, email **adupriscytwum@gmail.com** or WhatsApp **0550571248**.''',
      ),
      StaticPageContent(
        slug: 'terms',
        title: 'Terms & Conditions',
        updatedAt: now,
        bodyMarkdown: '''## Terms & Conditions

1. **Prices & Currency:** All prices are quoted in **Ghana Cedis (GHS)** and verified on our server before payment initialization.
2. **15-Minute Stock Reservation:** Starting Mobile Money checkout holds your selected variant for **15 minutes**. Unpaid reservations release automatically so other shoppers are not blocked.
3. **Order Confirmation:** Both website orders and WhatsApp manual orders are confirmed only upon verified Mobile Money payment.
4. **Exchanges Only:** Payments are non-refundable; eligible unworn items may be exchanged for size or colour within 3 days.''',
      ),
    ];
  }

  static List<Product> buildProducts() {
    const specs = <_SeedSpec>[
      _SeedSpec('prod-01', 'cat-slides-slippers', 'Slides & Slippers', 'slides-slippers',
          'Adowa Gold-Buckle Luxury Slide', 'adowa-gold-buckle-slide',
          'Supple faux-calfskin upper finished with a brushed gold buckle and contoured memory footbed for effortless everyday luxury.',
          185.0, Audience.women, true, 4.9, 14, 34,
          'https://images.unsplash.com/photo-1603487742131-4160ec999306?auto=format&fit=crop&w=900&q=80',
          ['Espresso', 'Gold', 'Sand'], ['37', '38', '39', '40', '41']),
      _SeedSpec('prod-02', 'cat-leather-sandals', 'Leather Sandals', 'leather-sandals',
          'Kumasi Royal Crossover Leather Sandal', 'kumasi-royal-crossover-leather',
          'Hand-stitched full-grain leather straps paired with a durable non-slip rubber outsole tailored for kaftans and smart casual wear.',
          260.0, Audience.men, true, 4.8, 11, 29,
          'https://images.unsplash.com/photo-1562273138-f46be4ebdf33?auto=format&fit=crop&w=900&q=80',
          ['Espresso', 'Black', 'Tan'], ['41', '42', '43', '44', '45']),
      _SeedSpec('prod-03', 'cat-flat-sandals', 'Flat Sandals', 'flat-sandals',
          'Osu Minimalist Toe-Ring Flat', 'osu-minimalist-toe-ring-flat',
          'Sleek asymmetric strap and soft toe-ring silhouette ideal for dresses, linen sets, and warm weekend outings.',
          165.0, Audience.women, true, 4.7, 9, 25,
          'https://images.unsplash.com/photo-1543163521-1bf539c55dd2?auto=format&fit=crop&w=900&q=80',
          ['Sand', 'Gold', 'Black'], ['37', '38', '39', '40', '41']),
      _SeedSpec('prod-04', 'cat-slides-slippers', 'Slides & Slippers', 'slides-slippers',
          'Cantonments Quilted Cloud Slipper', 'cantonments-quilted-cloud-slipper',
          'Plush diamond-quilted wide band over a featherlight cushioned sole that pampers your feet from morning to night.',
          195.0, Audience.women, true, 4.9, 8, 22,
          'https://images.unsplash.com/photo-1595950653106-6c9ebd614d3a?auto=format&fit=crop&w=900&q=80',
          ['Rose', 'Sand', 'Black'], ['37', '38', '39', '40', '41']),
      _SeedSpec('prod-05', 'cat-leather-sandals', 'Leather Sandals', 'leather-sandals',
          'Ashanti Heritage Double-Strap Leather', 'ashanti-heritage-double-strap',
          'Rich vegetable-tanned leather with twin adjustable brass buckles and contoured arch support.',
          280.0, Audience.men, true, 5.0, 7, 19,
          'https://images.unsplash.com/photo-1531310197839-ccf54634509e?auto=format&fit=crop&w=900&q=80',
          ['Espresso', 'Tan', 'Black'], ['41', '42', '43', '44', '45']),
      _SeedSpec('prod-06', 'cat-flat-sandals', 'Flat Sandals', 'flat-sandals',
          'Aburi Woven Raffia & Leather Flat', 'aburi-woven-raffia-flat',
          'Breathable woven raffia upper trimmed in smooth tan leather for airy comfort in tropical heat.',
          175.0, Audience.women, false, 4.6, 5, 14,
          'https://images.unsplash.com/photo-1515347619252-60a4bf4fff4f?auto=format&fit=crop&w=900&q=80',
          ['Sand', 'Tan'], ['37', '38', '39', '40']),
      _SeedSpec('prod-07', 'cat-slides-slippers', 'Slides & Slippers', 'slides-slippers',
          'Labadi Resort H-Band Slide', 'labadi-resort-h-band-slide',
          'Iconic H-cutout resort slide crafted with reinforced edge stitching and a softly padded heel pad.',
          190.0, Audience.women, true, 4.8, 10, 27,
          'https://images.unsplash.com/photo-1603487742131-4160ec999306?auto=format&fit=crop&w=900&q=80',
          ['Espresso', 'Gold', 'White'], ['37', '38', '39', '40', '41']),
      _SeedSpec('prod-08', 'cat-leather-sandals', 'Leather Sandals', 'leather-sandals',
          'Manhyia Classic Men\'s Palm Slipper', 'manhyia-classic-palm-slipper',
          'Traditional Ghanaian gentleman\'s leather palm slipper elevated with an orthopaedic cushioned insole.',
          270.0, Audience.men, true, 4.9, 6, 18,
          'https://images.unsplash.com/photo-1562273138-f46be4ebdf33?auto=format&fit=crop&w=900&q=80',
          ['Black', 'Espresso', 'Tan'], ['41', '42', '43', '44', '45']),
      _SeedSpec('prod-09', 'cat-flat-sandals', 'Flat Sandals', 'flat-sandals',
          'Sankofa Junior Comfort Ankle Sandal', 'sankofa-junior-ankle-sandal',
          'Easy hook-and-loop ankle strap with flexible grip soles for active children at church, school events, and family celebrations.',
          125.0, Audience.children, true, 4.9, 6, 16,
          'https://images.unsplash.com/photo-1514989940723-e8e51635b782?auto=format&fit=crop&w=900&q=80',
          ['Espresso', 'Gold', 'Rose'], ['30', '31', '32', '33', '34']),
      _SeedSpec('prod-10', 'cat-slides-slippers', 'Slides & Slippers', 'slides-slippers',
          'Little Royals Cushioned Kids Slide', 'little-royals-kids-slide',
          'Soft moulded footbed and wipe-clean upper designed to keep growing feet cool and supported all day.',
          110.0, Audience.children, false, 4.7, 4, 12,
          'https://images.unsplash.com/photo-1514989940723-e8e51635b782?auto=format&fit=crop&w=900&q=80',
          ['Sand', 'Rose', 'Black'], ['30', '32', '34', '35']),
      _SeedSpec('prod-11', 'cat-flat-sandals', 'Flat Sandals', 'flat-sandals',
          'East Legon Braided Metallic Flat', 'east-legon-braided-metallic-flat',
          'Delicate hand-braided straps in soft gold and rose shimmer made for weddings, engagements, and evening dinners.',
          210.0, Audience.women, false, 4.8, 5, 13,
          'https://images.unsplash.com/photo-1543163521-1bf539c55dd2?auto=format&fit=crop&w=900&q=80',
          ['Gold', 'Rose', 'Sand'], ['37', '38', '39', '40', '41']),
      _SeedSpec('prod-12', 'cat-leather-sandals', 'Leather Sandals', 'leather-sandals',
          'Airport City Executive Leather Mule', 'airport-city-leather-mule',
          'Clean open-back leather slip-on pairing sharp tailoring with Friday wear effortless poise.',
          295.0, Audience.men, false, 4.8, 4, 11,
          'https://images.unsplash.com/photo-1531310197839-ccf54634509e?auto=format&fit=crop&w=900&q=80',
          ['Black', 'Espresso'], ['41', '42', '43', '44', '45']),
      _SeedSpec('prod-13', 'cat-slides-slippers', 'Slides & Slippers', 'slides-slippers',
          'Volta Everyday Unisex Cushion Slide', 'volta-everyday-unisex-slide',
          'Water-resistant contoured footbed with pebble-grain strap crafted for effortless indoor-outdoor comfort.',
          145.0, Audience.unisex, false, 4.6, 5, 15,
          'https://images.unsplash.com/photo-1603487742131-4160ec999306?auto=format&fit=crop&w=900&q=80',
          ['Black', 'Sand', 'Olive'], ['38', '39', '40', '41', '42', '43']),
      _SeedSpec('prod-14', 'cat-flat-sandals', 'Flat Sandals', 'flat-sandals',
          'Ahodwo Pearl-Studded Evening Flat', 'ahodwo-pearl-evening-flat',
          'Lustrous pearl accents set along satin-lined straps for graceful occasion wear without heel fatigue.',
          220.0, Audience.women, false, 4.9, 6, 10,
          'https://images.unsplash.com/photo-1515347619252-60a4bf4fff4f?auto=format&fit=crop&w=900&q=80',
          ['White', 'Gold', 'Rose'], ['37', '38', '39', '40', '41']),
      _SeedSpec('prod-15', 'cat-leather-sandals', 'Leather Sandals', 'leather-sandals',
          'Nhyiaeso Woven Leather Fisherman Sandal', 'nhyiaeso-woven-leather-sandal',
          'Interlaced genuine leather straps with breathable side cutouts and stitched welt durability.',
          275.0, Audience.men, false, 4.7, 3, 9,
          'https://images.unsplash.com/photo-1562273138-f46be4ebdf33?auto=format&fit=crop&w=900&q=80',
          ['Tan', 'Espresso', 'Black'], ['41', '42', '43', '44']),
      _SeedSpec('prod-16', 'cat-slides-slippers', 'Slides & Slippers', 'slides-slippers',
          'Spintex Knot-Bow Velvet Touch Slide', 'spintex-knot-bow-slide',
          'Sculpted knot bow upper in warm sand and rose tones over a non-marking flexible rubber sole.',
          180.0, Audience.women, false, 4.7, 4, 8,
          'https://images.unsplash.com/photo-1595950653106-6c9ebd614d3a?auto=format&fit=crop&w=900&q=80',
          ['Rose', 'Sand', 'Espresso'], ['37', '38', '39', '40']),
      _SeedSpec('prod-17', 'cat-leather-sandals', 'Leather Sandals', 'leather-sandals',
          'Junior Heritage Leather Sunday Sandal', 'junior-heritage-leather-sandal',
          'Smart stitched leather sandal for boys and girls with gentle arch support and scuff-resistant toe protection.',
          140.0, Audience.children, false, 4.8, 3, 9,
          'https://images.unsplash.com/photo-1514989940723-e8e51635b782?auto=format&fit=crop&w=900&q=80',
          ['Espresso', 'Black', 'Tan'], ['30', '31', '32', '33', '34']),
      _SeedSpec('prod-18', 'cat-flat-sandals', 'Flat Sandals', 'flat-sandals',
          'Tema Harbour Cross-Band Everyday Flat', 'tema-harbour-cross-band-flat',
          'Ultra-flexible everyday cross-band sandal crafted for busy days and market-to-office versatility.',
          155.0, Audience.women, false, 4.6, 4, 11,
          'https://images.unsplash.com/photo-1543163521-1bf539c55dd2?auto=format&fit=crop&w=900&q=80',
          ['Black', 'Espresso', 'Sand'], ['37', '38', '39', '40', '41']),
      _SeedSpec('prod-19', 'cat-slides-slippers', 'Slides & Slippers', 'slides-slippers',
          'Bantama Luxe Croc-Embossed Slide', 'bantama-croc-embossed-slide',
          'Subtle croc-embossed strap with tonal stitching and sweat-resistant microfibre lining.',
          205.0, Audience.unisex, false, 4.8, 5, 14,
          'https://images.unsplash.com/photo-1531310197839-ccf54634509e?auto=format&fit=crop&w=900&q=80',
          ['Espresso', 'Black', 'Gold'], ['38', '39', '40', '41', '42', '43']),
      _SeedSpec('prod-20', 'cat-leather-sandals', 'Leather Sandals', 'leather-sandals',
          'Asokwa Signature Gold-Trim Leather Sandal', 'asokwa-signature-gold-leather',
          'Our flagship artisan leather sandal featuring hand-burnished edges and a signature brushed-gold heel emblem.',
          310.0, Audience.women, true, 5.0, 9, 21,
          'https://images.unsplash.com/photo-1603487742131-4160ec999306?auto=format&fit=crop&w=900&q=80',
          ['Espresso', 'Gold', 'Sand'], ['37', '38', '39', '40', '41']),
    ];

    final products = <Product>[];
    for (var i = 0; i < specs.length; i++) {
      final s = specs[i];
      final variants = <ProductVariant>[];
      for (var cIdx = 0; cIdx < s.colours.length; cIdx++) {
        final col = s.colours[cIdx];
        for (var sIdx = 0; sIdx < s.sizes.length; sIdx++) {
          final sz = s.sizes[sIdx];
          // Give realistic varied stock: plenty on most, low stock (2) on some, 0 on one combo
          int stockQty = 6;
          if (sIdx == 1 && cIdx == 0) {
            stockQty = 2; // Triggers "Only 2 left" & low-stock dashboard alert
          } else if (sIdx == 2 && cIdx == 1 && i < 6) {
            stockQty = 0; // Demonstrates disabled out-of-stock swatch/size
          }
          variants.add(
            ProductVariant(
              id: '${s.id}-v-${sz.toLowerCase()}-${col.toLowerCase()}',
              productId: s.id,
              size: sz,
              colour: col,
              sku:
                  '${s.slug.substring(0, 5).toUpperCase()}-$sz-${col.substring(0, 3).toUpperCase()}',
              stockQty: stockQty,
              reservedQty: 0,
            ),
          );
        }
      }

      products.add(
        Product(
          id: s.id,
          categoryId: s.categoryId,
          categoryName: s.categoryName,
          categorySlug: s.categorySlug,
          name: s.name,
          slug: s.slug,
          description: s.description,
          basePrice: s.basePrice,
          audience: s.audience,
          isActive: true,
          isFeatured: s.isFeatured,
          createdAt: DateTime(2026, 10, 30).subtract(Duration(days: 20 - i)),
          avgRating: s.avgRating,
          reviewCount: s.reviewCount,
          unitsSold: s.unitsSold,
          images: [
            ProductImage(
              id: '${s.id}-img-1',
              productId: s.id,
              url: s.imageUrl,
              sortOrder: 0,
            ),
            ProductImage(
              id: '${s.id}-img-2',
              productId: s.id,
              url:
                  'https://images.unsplash.com/photo-1543163521-1bf539c55dd2?auto=format&fit=crop&w=900&q=80',
              sortOrder: 1,
            ),
          ],
          variants: variants,
        ),
      );
    }
    return products;
  }

  static List<Order> buildSampleOrders() {
    final today = DateTime(2026, 10, 30, 10, 30);
    return [
      Order(
        id: 'ord-demo-001',
        orderNumber: 'PSY-20261030-0001',
        trackingToken: 'demo-track-token-0001',
        channel: 'website',
        customerName: 'Akosua Mensah',
        customerPhone: '0244123456',
        customerWhatsapp: '0244123456',
        deliveryMethod: DeliveryMethod.delivery,
        region: 'Ashanti Region',
        city: 'Kumasi — Ahodwo',
        address: 'House 14, Cedar Crescent, Ahodwo',
        landmark: 'Near Melcom Ahodwo',
        subtotal: 370.00,
        deliveryFee: 20.00,
        total: 390.00,
        status: OrderStatus.confirmed,
        paymentStatus: PaymentStatus.paid,
        paystackReference: 'PSY-20261030-0001-MOMO',
        createdAt: today.subtract(const Duration(hours: 2)),
        items: const [
          OrderItem(
            id: 'oi-1',
            orderId: 'ord-demo-001',
            variantId: 'prod-01-v-39-gold',
            productId: 'prod-01',
            productName: 'Adowa Gold-Buckle Luxury Slide',
            size: '39',
            colour: 'Gold',
            unitPrice: 185.00,
            quantity: 2,
          ),
        ],
        events: [
          OrderEvent(
            id: 'oe-1',
            orderId: 'ord-demo-001',
            status: OrderStatus.pendingPayment,
            note: 'Order created (website)',
            createdAt: today.subtract(const Duration(hours: 2, minutes: 3)),
          ),
          OrderEvent(
            id: 'oe-2',
            orderId: 'ord-demo-001',
            status: OrderStatus.confirmed,
            note: 'Mobile Money payment verified via Paystack',
            createdAt: today.subtract(const Duration(hours: 2)),
          ),
        ],
      ),
      Order(
        id: 'ord-demo-002',
        orderNumber: 'PSY-20261029-0002',
        trackingToken: 'demo-track-token-0002',
        channel: 'website',
        customerName: 'Kwame Boateng',
        customerPhone: '0558234567',
        customerWhatsapp: '0558234567',
        deliveryMethod: DeliveryMethod.delivery,
        region: 'Greater Accra',
        city: 'East Legon, Accra',
        address: 'Boundary Road, Block B',
        landmark: 'Opposite A&C Mall',
        subtotal: 540.00,
        deliveryFee: 35.00,
        total: 575.00,
        status: OrderStatus.dispatched,
        paymentStatus: PaymentStatus.paid,
        paystackReference: 'PSY-20261029-0002-MOMO',
        createdAt: today.subtract(const Duration(days: 1, hours: 3)),
        items: const [
          OrderItem(
            id: 'oi-2',
            orderId: 'ord-demo-002',
            variantId: 'prod-02-v-43-espresso',
            productId: 'prod-02',
            productName: 'Kumasi Royal Crossover Leather Sandal',
            size: '43',
            colour: 'Espresso',
            unitPrice: 260.00,
            quantity: 1,
          ),
          OrderItem(
            id: 'oi-3',
            orderId: 'ord-demo-002',
            variantId: 'prod-05-v-43-tan',
            productId: 'prod-05',
            productName: 'Ashanti Heritage Double-Strap Leather',
            size: '43',
            colour: 'Tan',
            unitPrice: 280.00,
            quantity: 1,
          ),
        ],
        events: [
          OrderEvent(
            id: 'oe-3',
            orderId: 'ord-demo-002',
            status: OrderStatus.confirmed,
            note: 'Mobile Money payment confirmed',
            createdAt: today.subtract(const Duration(days: 1, hours: 3)),
          ),
          OrderEvent(
            id: 'oe-4',
            orderId: 'ord-demo-002',
            status: OrderStatus.dispatched,
            note: 'Handed to VIP Parcel Accra Express (Waybill #VIP-8841)',
            createdAt: today.subtract(const Duration(hours: 18)),
          ),
        ],
      ),
      Order(
        id: 'ord-demo-003',
        orderNumber: 'PSY-20261028-0003',
        trackingToken: 'demo-track-token-0003',
        channel: 'whatsapp_manual',
        customerName: 'Efua Ofori',
        customerPhone: '0209112233',
        customerWhatsapp: '0209112233',
        deliveryMethod: DeliveryMethod.pickup,
        region: 'Ashanti Region',
        city: 'Kumasi Pickup',
        subtotal: 290.00,
        deliveryFee: 0.00,
        total: 290.00,
        status: OrderStatus.delivered,
        paymentStatus: PaymentStatus.paid,
        paystackReference: 'PSY-20261028-0003-WA',
        createdAt: today.subtract(const Duration(days: 2)),
        items: const [
          OrderItem(
            id: 'oi-4',
            orderId: 'ord-demo-003',
            variantId: 'prod-03-v-39-sand',
            productId: 'prod-03',
            productName: 'Osu Minimalist Toe-Ring Flat',
            size: '39',
            colour: 'Sand',
            unitPrice: 165.00,
            quantity: 1,
          ),
          OrderItem(
            id: 'oi-5',
            orderId: 'ord-demo-003',
            variantId: 'prod-09-v-32-gold',
            productId: 'prod-09',
            productName: 'Sankofa Junior Comfort Ankle Sandal',
            size: '32',
            colour: 'Gold',
            unitPrice: 125.00,
            quantity: 1,
          ),
        ],
        events: [
          OrderEvent(
            id: 'oe-5',
            orderId: 'ord-demo-003',
            status: OrderStatus.confirmed,
            note: 'Manual WhatsApp order paid via Paystack link',
            createdAt: today.subtract(const Duration(days: 2)),
          ),
          OrderEvent(
            id: 'oe-6',
            orderId: 'ord-demo-003',
            status: OrderStatus.delivered,
            note: 'Picked up at Kumasi Showroom',
            createdAt: today.subtract(const Duration(days: 1, hours: 5)),
          ),
        ],
      ),
      Order(
        id: 'ord-demo-004',
        orderNumber: 'PSY-20261026-0004',
        trackingToken: 'demo-track-token-0004',
        channel: 'website',
        customerName: 'Nana Ama Owusu',
        customerPhone: '0543987654',
        customerWhatsapp: '0543987654',
        deliveryMethod: DeliveryMethod.delivery,
        region: 'Greater Accra',
        city: 'Cantonments, Accra',
        address: '4th Circular Road',
        subtotal: 505.00,
        deliveryFee: 35.00,
        total: 540.00,
        status: OrderStatus.delivered,
        paymentStatus: PaymentStatus.paid,
        paystackReference: 'PSY-20261026-0004-MOMO',
        createdAt: today.subtract(const Duration(days: 4)),
        items: const [
          OrderItem(
            id: 'oi-6',
            orderId: 'ord-demo-004',
            variantId: 'prod-20-v-38-gold',
            productId: 'prod-20',
            productName: 'Asokwa Signature Gold-Trim Leather Sandal',
            size: '38',
            colour: 'Gold',
            unitPrice: 310.00,
            quantity: 1,
          ),
          OrderItem(
            id: 'oi-7',
            orderId: 'ord-demo-004',
            variantId: 'prod-04-v-38-rose',
            productId: 'prod-04',
            productName: 'Cantonments Quilted Cloud Slipper',
            size: '38',
            colour: 'Rose',
            unitPrice: 195.00,
            quantity: 1,
          ),
        ],
        events: [
          OrderEvent(
            id: 'oe-7',
            orderId: 'ord-demo-004',
            status: OrderStatus.delivered,
            note: 'Delivered to customer in Cantonments',
            createdAt: today.subtract(const Duration(days: 2)),
          ),
        ],
      ),
    ];
  }

  static List<Review> buildSampleReviews() {
    final now = DateTime(2026, 10, 30);
    return [
      Review(
        id: 'rev-1',
        productId: 'prod-01',
        productName: 'Adowa Gold-Buckle Luxury Slide',
        orderId: 'ord-demo-001',
        reviewerName: 'Akosua Mensah (Kumasi)',
        rating: 5,
        comment:
            'The cushioned footbed feels incredible and the brushed gold buckle looks truly high-end. Next-day delivery in Kumasi!',
        isApproved: true,
        createdAt: now.subtract(const Duration(days: 1)),
      ),
      Review(
        id: 'rev-2',
        productId: 'prod-02',
        productName: 'Kumasi Royal Crossover Leather Sandal',
        orderId: 'ord-demo-002',
        reviewerName: 'Kwame Boateng (Accra)',
        rating: 5,
        comment:
            'Thick, supple leather and neat stitching. Fits true to EU 43 and pairs well with kaftans.',
        isApproved: true,
        createdAt: now.subtract(const Duration(days: 2)),
      ),
      Review(
        id: 'rev-3',
        productId: 'prod-03',
        productName: 'Osu Minimalist Toe-Ring Flat',
        orderId: 'ord-demo-003',
        reviewerName: 'Efua Ofori (Kumasi)',
        rating: 4,
        comment:
            'Very sleek flat sandal! Smooth Mobile Money checkout and friendly WhatsApp updates.',
        isApproved: true,
        createdAt: now.subtract(const Duration(days: 2)),
      ),
      Review(
        id: 'rev-4',
        productId: 'prod-20',
        productName: 'Asokwa Signature Gold-Trim Leather Sandal',
        orderId: 'ord-demo-004',
        reviewerName: 'Nana Ama Owusu (Accra)',
        rating: 5,
        comment:
            'Worth every pesewa! Wore them to an engagement ceremony and got compliments all evening.',
        isApproved: false, // Pending review ready for Admin moderation demo!
        createdAt: now.subtract(const Duration(hours: 6)),
      ),
    ];
  }

  static List<StockMovement> buildSampleMovements() {
    final now = DateTime(2026, 10, 30, 10, 0);
    return [
      StockMovement(
        id: 'sm-1',
        variantId: 'prod-01-v-39-gold',
        productName: 'Adowa Gold-Buckle Luxury Slide',
        size: '39',
        colour: 'Gold',
        change: -2,
        reason: 'sale:PSY-20261030-0001',
        createdAt: now.subtract(const Duration(hours: 2)),
      ),
      StockMovement(
        id: 'sm-2',
        variantId: 'prod-02-v-43-espresso',
        productName: 'Kumasi Royal Crossover Leather Sandal',
        size: '43',
        colour: 'Espresso',
        change: -1,
        reason: 'sale:PSY-20261029-0002',
        createdAt: now.subtract(const Duration(days: 1)),
      ),
      StockMovement(
        id: 'sm-3',
        variantId: 'prod-01-v-38-espresso',
        productName: 'Adowa Gold-Buckle Luxury Slide',
        size: '38',
        colour: 'Espresso',
        change: 10,
        reason: 'restock:launch_inventory',
        createdAt: now.subtract(const Duration(days: 5)),
      ),
    ];
  }
}

class _SeedSpec {
  const _SeedSpec(
    this.id,
    this.categoryId,
    this.categoryName,
    this.categorySlug,
    this.name,
    this.slug,
    this.description,
    this.basePrice,
    this.audience,
    this.isFeatured,
    this.avgRating,
    this.reviewCount,
    this.unitsSold,
    this.imageUrl,
    this.colours,
    this.sizes,
  );

  final String id;
  final String categoryId;
  final String categoryName;
  final String categorySlug;
  final String name;
  final String slug;
  final String description;
  final double basePrice;
  final Audience audience;
  final bool isFeatured;
  final double avgRating;
  final int reviewCount;
  final int unitsSold;
  final String imageUrl;
  final List<String> colours;
  final List<String> sizes;
}
