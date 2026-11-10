import 'package:flutter_test/flutter_test.dart';
import 'package:priscy_store/core/utils/currency_formatter.dart';
import 'package:priscy_store/core/utils/stock_calculator.dart';
import 'package:priscy_store/data/models/models.dart';

void main() {
  group('Price, Delivery Fee & Order Total Calculations', () {
    const product = Product(
      id: 'p1',
      categoryId: 'cat-1',
      name: 'Adowa Gold-Buckle Luxury Slide',
      slug: 'adowa-gold-buckle-slide',
      basePrice: 185.00,
    );

    const standardVariant = ProductVariant(
      id: 'v1',
      productId: 'p1',
      size: '39',
      colour: 'Gold',
      stockQty: 5,
    );

    const overrideVariant = ProductVariant(
      id: 'v2',
      productId: 'p1',
      size: '41',
      colour: 'Gold',
      priceOverride: 200.00,
      stockQty: 4,
    );

    test('uses basePrice unless variant specifies priceOverride', () {
      expect(
        StockAndPricingCalculator.unitPriceForVariant(product, standardVariant),
        185.00,
      );
      expect(
        StockAndPricingCalculator.unitPriceForVariant(product, overrideVariant),
        200.00,
      );
    });

    test('computes subtotal, Kumasi/Accra delivery fee, free pickup, and pesewas', () {
      const items = [
        CartItem(
          variantId: 'v1',
          productId: 'p1',
          productSlug: 'adowa-gold-buckle-slide',
          productName: 'Adowa Slide',
          imageUrl: '',
          size: '39',
          colour: 'Gold',
          unitPrice: 185.00,
          quantity: 2,
        ),
      ];
      const accraZone = DeliveryZone(
        id: 'z-accra',
        region: 'Greater Accra',
        city: 'Accra',
        fee: 35.00,
      );

      final deliverySummary = StockAndPricingCalculator.calculateOrderTotals(
        items: items,
        deliveryMethod: DeliveryMethod.delivery,
        selectedZone: accraZone,
      );
      expect(deliverySummary.subtotal, 370.00);
      expect(deliverySummary.deliveryFee, 35.00);
      expect(deliverySummary.total, 405.00);
      expect(CurrencyFormatter.toPesewas(deliverySummary.total), 40500);

      final pickupSummary = StockAndPricingCalculator.calculateOrderTotals(
        items: items,
        deliveryMethod: DeliveryMethod.pickup,
        selectedZone: accraZone,
      );
      expect(pickupSummary.deliveryFee, 0.00);
      expect(pickupSummary.total, 370.00);
    });
  });

  group('Stock Reservation, Payment Deduction & Cancellation Restoration', () {
    const initialVariant = ProductVariant(
      id: 'v-last-pair',
      productId: 'p1',
      size: '38',
      colour: 'Espresso',
      stockQty: 2,
      reservedQty: 0,
    );

    test('reserves stock for 15 minutes and blocks overselling the last pair', () {
      final afterFirstBuyer =
          StockAndPricingCalculator.reserveStock(initialVariant, 2);
      expect(afterFirstBuyer.stockQty, 2);
      expect(afterFirstBuyer.reservedQty, 2);
      expect(afterFirstBuyer.availableQty, 0);
      expect(afterFirstBuyer.isInStock, isFalse);

      // Second buyer attempting to buy while reserved must be rejected
      expect(
        () => StockAndPricingCalculator.reserveStock(afterFirstBuyer, 1),
        throwsStateError,
      );
    });

    test('deducts physical stock and clears reservation on Paystack confirmation', () {
      final reserved = StockAndPricingCalculator.reserveStock(initialVariant, 1);
      final confirmed =
          StockAndPricingCalculator.confirmReservedSale(reserved, 1);
      expect(confirmed.stockQty, 1);
      expect(confirmed.reservedQty, 0);
      expect(confirmed.availableQty, 1);
    });

    test('releases unpaid reservation on expiry and restores paid stock on cancel', () {
      final reserved = StockAndPricingCalculator.reserveStock(initialVariant, 2);
      final released =
          StockAndPricingCalculator.releaseUnpaidReservation(reserved, 2);
      expect(released.stockQty, 2);
      expect(released.reservedQty, 0);
      expect(released.availableQty, 2);

      final soldOut = StockAndPricingCalculator.confirmReservedSale(reserved, 2);
      expect(soldOut.stockQty, 0);

      final restored =
          StockAndPricingCalculator.restoreCancelledPaidOrder(soldOut, 2);
      expect(restored.stockQty, 2);
      expect(restored.availableQty, 2);
    });

    test('catalogue size & colour filter excludes out-of-stock combinations', () {
      const p1 = Product(
        id: 'p1',
        categoryId: 'cat-1',
        name: 'Style A',
        slug: 'style-a',
        basePrice: 150,
        variants: [
          ProductVariant(
            id: 'v1',
            productId: 'p1',
            size: '39',
            colour: 'Gold',
            stockQty: 0, // Out of stock!
          ),
        ],
      );
      const p2 = Product(
        id: 'p2',
        categoryId: 'cat-1',
        name: 'Style B',
        slug: 'style-b',
        basePrice: 170,
        variants: [
          ProductVariant(
            id: 'v2',
            productId: 'p2',
            size: '39',
            colour: 'Gold',
            stockQty: 3, // In stock!
          ),
        ],
      );

      final matches = StockAndPricingCalculator.filterAndSortProducts(
        products: const [p1, p2],
        size: '39',
        colour: 'Gold',
      );
      expect(matches.length, 1);
      expect(matches.first.id, 'p2');
    });
  });
}
