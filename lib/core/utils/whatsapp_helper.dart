import 'package:url_launcher/url_launcher.dart';

import '../../data/models/models.dart';
import '../config/app_config.dart';
import 'currency_formatter.dart';
import 'validators.dart';

class WhatsAppHelper {
  const WhatsAppHelper._();

  /// Builds a prefilled WhatsApp URL for ordering the current cart from the store
  /// (Section 6.1: `https://wa.me/233550571248?text=...`).
  static String buildCartOrderUrl({
    required List<CartItem> items,
    String storeWhatsapp = AppConfig.whatsappDigits,
    DeliveryMethod? deliveryMethod,
    DeliveryZone? zone,
    String? customerName,
    String? notes,
  }) {
    final subtotal = items.fold<double>(0, (s, i) => s + i.lineTotal);
    final fee =
        deliveryMethod == DeliveryMethod.pickup ? 0.0 : (zone?.fee ?? 0.0);
    final total = subtotal + fee;

    final lines = <String>[
      'Hello Priscy Luxury Slippers! I would like to place an order:',
      '',
      for (final item in items)
        '• ${item.productName} — Size ${item.size}, ${item.colour} × ${item.quantity} (${CurrencyFormatter.formatGhs(item.lineTotal)})',
      '',
      'Subtotal: ${CurrencyFormatter.formatGhs(subtotal)}',
      if (zone != null && deliveryMethod == DeliveryMethod.delivery)
        'Delivery (${zone.displayName}): ${CurrencyFormatter.formatGhs(fee)}',
      if (deliveryMethod == DeliveryMethod.pickup)
        'Delivery Method: Kumasi Showroom Pickup (Free)',
      'Estimated Total: *${CurrencyFormatter.formatGhs(total)}*',
      if (customerName != null && customerName.trim().isNotEmpty)
        'Customer Name: ${customerName.trim()}',
      if (notes != null && notes.trim().isNotEmpty) 'Notes: ${notes.trim()}',
      '',
      'Please send me a Mobile Money payment link to confirm my order.',
    ];

    final digits = Validators.normalizeGhanaPhone(storeWhatsapp);
    final encoded = Uri.encodeComponent(lines.join('\n'));
    return 'https://wa.me/$digits?text=$encoded';
  }

  /// Builds a quick WhatsApp inquiry/order URL for a single product & variant.
  static String buildSingleProductOrderUrl({
    required Product product,
    ProductVariant? variant,
    int quantity = 1,
    String storeWhatsapp = AppConfig.whatsappDigits,
  }) {
    final price = variant != null
        ? variant.effectivePrice(product.basePrice)
        : product.basePrice;
    final variantText = variant != null
        ? 'Size ${variant.size}, Colour ${variant.colour}'
        : 'Please help me pick a size & colour';
    final text = [
      'Hello Priscy Luxury Slippers! I want to order:',
      '• *${product.name}* ($variantText) × $quantity',
      '• Price: *${CurrencyFormatter.formatGhs(price * quantity)}*',
      '',
      'Is this available for Mobile Money payment?',
    ].join('\n');

    final digits = Validators.normalizeGhanaPhone(storeWhatsapp);
    return 'https://wa.me/$digits?text=${Uri.encodeComponent(text)}';
  }

  /// Builds a general customer support WhatsApp chat link.
  static String buildSupportChatUrl({
    String storeWhatsapp = AppConfig.whatsappDigits,
    String message =
        'Hello Priscy Luxury Slippers! I have a question about your footwear collection.',
  }) {
    final digits = Validators.normalizeGhanaPhone(storeWhatsapp);
    return 'https://wa.me/$digits?text=${Uri.encodeComponent(message)}';
  }

  /// Builds the 1-tap owner -> customer WhatsApp update link in Admin (Sections 6.2 & 10).
  static String buildAdminOrderStatusUpdateUrl({
    required Order order,
    String storeBaseUrl = AppConfig.storeBaseUrl,
    String? customPaymentUrl,
  }) {
    final customerDigits = Validators.normalizeGhanaPhone(
      (order.customerWhatsapp != null && order.customerWhatsapp!.trim().isNotEmpty)
          ? order.customerWhatsapp!
          : order.customerPhone,
    );
    final cleanBase = storeBaseUrl.replaceAll(RegExp(r'/$'), '');
    final trackingUrl =
        '$cleanBase/track?order=${Uri.encodeComponent(order.orderNumber)}&token=${Uri.encodeComponent(order.trackingToken)}';

    String body;
    switch (order.status) {
      case OrderStatus.pendingPayment:
        final payLink = customPaymentUrl ?? trackingUrl;
        body =
            'Hello ${order.customerName}, thank you for ordering from *Priscy Luxury Slippers*! '
            'Your order *${order.orderNumber}* (${CurrencyFormatter.formatGhs(order.total)}) is reserved for 15 minutes. '
            'Complete your Mobile Money payment here: $payLink';
      case OrderStatus.confirmed:
        body =
            'Hello ${order.customerName}, *Order Received & Payment Confirmed*! '
            'Thank you for your payment of *${CurrencyFormatter.formatGhs(order.total)}* for order *${order.orderNumber}*. '
            'We are preparing your pair now. Track your order anytime: $trackingUrl';
      case OrderStatus.processing:
        body =
            'Hello ${order.customerName}, your Priscy Luxury Slippers order *${order.orderNumber}* is now being carefully packed for ${order.deliveryMethod == DeliveryMethod.pickup ? 'Kumasi pickup' : 'dispatch'}. '
            'Track progress: $trackingUrl';
      case OrderStatus.dispatched:
        body =
            'Hello ${order.customerName}, exciting news! *Your order ${order.orderNumber} has been dispatched* '
            '${order.region != null ? 'to ${order.city ?? order.region}' : ''}. '
            'Track delivery details here: $trackingUrl';
      case OrderStatus.delivered:
        body =
            'Hello ${order.customerName}, your Priscy Luxury Slippers order *${order.orderNumber}* has been marked *Delivered*! '
            'Thank you for shopping with us—we would love your review on our website: $cleanBase';
      case OrderStatus.cancelled:
        body =
            'Hello ${order.customerName}, your order *${order.orderNumber}* at Priscy Luxury Slippers has been cancelled. '
            'Reply to this message if you would like help placing a new order.';
    }

    return 'https://wa.me/$customerDigits?text=${Uri.encodeComponent(body)}';
  }

  static Future<bool> openUrl(String url, {bool sameTab = false}) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return false;
    return launchUrl(
      uri,
      mode: sameTab ? LaunchMode.platformDefault : LaunchMode.externalApplication,
      webOnlyWindowName: sameTab ? '_self' : '_blank',
    );
  }
}
