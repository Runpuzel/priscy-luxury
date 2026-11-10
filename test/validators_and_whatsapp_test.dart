import 'package:flutter_test/flutter_test.dart';
import 'package:priscy_store/core/utils/validators.dart';
import 'package:priscy_store/core/utils/whatsapp_helper.dart';
import 'package:priscy_store/data/models/models.dart';

void main() {
  group('Ghana Phone Normalization, CSV Parser & WhatsApp Link Builders', () {
    test('normalizes and validates Ghanaian Mobile Money numbers', () {
      expect(Validators.normalizeGhanaPhone('0550571248'), '233550571248');
      expect(Validators.normalizeGhanaPhone('+233 24 412 3456'), '233244123456');
      expect(Validators.ghanaPhone('0550571248'), isNull);
      expect(Validators.ghanaPhone('+233501234567'), isNull);
      expect(Validators.ghanaPhone('12345'), isNotNull);
    });

    test('parses admin stock CSV rows accurately', () {
      const csv = '''
product_slug,size,colour,stock_qty,price_override,sku
adowa-gold-buckle-slide,38,Espresso,12,,ADOWA-38-ESP
kumasi-royal-crossover-leather,43,Black,7,265.00,KUMAS-43-BLK
''';
      final rows = Validators.parseCsvRows(csv);
      expect(rows.length, 2);
      expect(rows[0]['product_slug'], 'adowa-gold-buckle-slide');
      expect(rows[0]['stock_qty'], '12');
      expect(rows[1]['price_override'], '265.00');
    });

    test('builds prefilled WhatsApp cart URL targeting 233550571248', () {
      const cart = [
        CartItem(
          variantId: 'v1',
          productId: 'p1',
          productSlug: 'adowa-gold-buckle-slide',
          productName: 'Adowa Gold-Buckle Luxury Slide',
          imageUrl: '',
          size: '39',
          colour: 'Gold',
          unitPrice: 185.00,
          quantity: 1,
        ),
      ];
      final url = WhatsAppHelper.buildCartOrderUrl(items: cart);
      expect(url.startsWith('https://wa.me/233550571248?text='), isTrue);
      final decoded = Uri.decodeComponent(url.split('text=').last);
      expect(decoded, contains('Adowa Gold-Buckle Luxury Slide'));
      expect(decoded, contains('Size 39, Gold'));
    });

    test('builds 1-tap Admin WhatsApp status update URL for Dispatched orders', () {
      final order = Order(
        id: 'ord-1',
        orderNumber: 'PSY-20261101-0009',
        trackingToken: 'secret123',
        customerName: 'Akosua',
        customerPhone: '0244123456',
        deliveryMethod: DeliveryMethod.delivery,
        region: 'Greater Accra',
        city: 'Accra',
        subtotal: 185,
        deliveryFee: 35,
        total: 220,
        status: OrderStatus.dispatched,
        paymentStatus: PaymentStatus.paid,
        createdAt: DateTime(2026, 11, 1),
      );
      final url = WhatsAppHelper.buildAdminOrderStatusUpdateUrl(order: order);
      expect(url.startsWith('https://wa.me/233244123456?text='), isTrue);
      final decoded = Uri.decodeComponent(url.split('text=').last);
      expect(decoded, contains('PSY-20261101-0009 has been dispatched'));
      expect(decoded, contains('token=secret123'));
    });
  });
}
