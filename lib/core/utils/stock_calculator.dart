import '../../data/models/models.dart';
import '../config/app_config.dart';

class OrderPricingSummary {
  const OrderPricingSummary({
    required this.subtotal,
    required this.deliveryFee,
    required this.total,
  });

  final double subtotal;
  final double deliveryFee;
  final double total;
}

/// Pure, deterministic pricing, filtering & stock-reservation calculations
/// shared by repositories and covered by unit tests (Sections 7, 10 & 15).
class StockAndPricingCalculator {
  const StockAndPricingCalculator._();

  static double unitPriceForVariant(Product product, ProductVariant variant) {
    return variant.priceOverride ?? product.basePrice;
  }

  static double calculateSubtotal(List<CartItem> items) {
    final raw = items.fold<double>(
      0,
      (sum, item) => sum + (item.unitPrice * item.quantity),
    );
    return double.parse(raw.toStringAsFixed(2));
  }

  static double calculateDeliveryFee({
    required DeliveryMethod deliveryMethod,
    DeliveryZone? selectedZone,
  }) {
    if (deliveryMethod == DeliveryMethod.pickup) return 0;
    if (selectedZone == null) return 0;
    return double.parse(selectedZone.fee.toStringAsFixed(2));
  }

  static OrderPricingSummary calculateOrderTotals({
    required List<CartItem> items,
    required DeliveryMethod deliveryMethod,
    DeliveryZone? selectedZone,
  }) {
    final subtotal = calculateSubtotal(items);
    final fee = calculateDeliveryFee(
      deliveryMethod: deliveryMethod,
      selectedZone: selectedZone,
    );
    final total = double.parse((subtotal + fee).toStringAsFixed(2));
    return OrderPricingSummary(
      subtotal: subtotal,
      deliveryFee: fee,
      total: total,
    );
  }

  /// Reserves `quantity` units for 15 minutes when starting checkout.
  /// Throws [StateError] if available stock is insufficient.
  static ProductVariant reserveStock(ProductVariant variant, int quantity) {
    if (quantity <= 0) {
      throw ArgumentError.value(quantity, 'quantity', 'Must be positive');
    }
    if (variant.availableQty < quantity) {
      throw StateError(
        'Only ${variant.availableQty} left in size ${variant.size} (${variant.colour}).',
      );
    }
    return variant.copyWith(reservedQty: variant.reservedQty + quantity);
  }

  /// Deducts physical stock and releases the reservation once payment succeeds.
  static ProductVariant confirmReservedSale(
    ProductVariant variant,
    int quantity,
  ) {
    final nextStock = (variant.stockQty - quantity).clamp(0, 1000000);
    final nextReserved = (variant.reservedQty - quantity).clamp(0, nextStock);
    return variant.copyWith(stockQty: nextStock, reservedQty: nextReserved);
  }

  /// Releases an unpaid 15-minute reservation without altering `stockQty`.
  static ProductVariant releaseUnpaidReservation(
    ProductVariant variant,
    int quantity,
  ) {
    final nextReserved =
        (variant.reservedQty - quantity).clamp(0, variant.stockQty);
    return variant.copyWith(reservedQty: nextReserved);
  }

  /// Restores stock when a paid order is cancelled prior to dispatch (Section 7).
  static ProductVariant restoreCancelledPaidOrder(
    ProductVariant variant,
    int quantity,
  ) {
    return variant.copyWith(stockQty: variant.stockQty + quantity);
  }

  static bool isReservationExpired(Order order, DateTime now) {
    return order.status == OrderStatus.pendingPayment &&
        order.paymentStatus == PaymentStatus.unpaid &&
        order.reservedUntil != null &&
        order.reservedUntil!.isBefore(now);
  }

  static bool isLowStock(
    ProductVariant variant, {
    int threshold = AppConfig.defaultLowStockThreshold,
  }) {
    return variant.availableQty <= threshold;
  }

  /// Live stock status text for the product detail page (Section 6.1).
  static String liveStockMessage(
    ProductVariant? variant, {
    int lowThreshold = AppConfig.defaultLowStockThreshold,
  }) {
    if (variant == null) return 'Select a colour and size to check stock';
    final available = variant.availableQty;
    if (available <= 0) return 'Out of stock in this combination';
    if (available <= lowThreshold) return 'Only $available left — order soon!';
    return 'In stock ($available available — ships in 3–5 days)';
  }

  /// Filters catalogue products so size/colour filters ONLY show products with
  /// an **in-stock** variant matching that choice (Section 6.1).
  static List<Product> filterAndSortProducts({
    required List<Product> products,
    String? categorySlug,
    Audience? audience,
    String? size,
    String? colour,
    bool bestSellersOnly = false,
    String? searchQuery,
    CatalogueSort sort = CatalogueSort.bestSelling,
  }) {
    final normalizedQuery = searchQuery?.trim().toLowerCase() ?? '';
    final filtered = products.where((p) {
      if (!p.isActive) return false;

      if (categorySlug != null &&
          categorySlug.isNotEmpty &&
          p.categorySlug != categorySlug &&
          p.categoryId != categorySlug) {
        return false;
      }

      if (audience != null) {
        if (p.audience != audience && p.audience != Audience.unisex) {
          return false;
        }
      }

      if (bestSellersOnly && !p.isFeatured && p.unitsSold <= 0) {
        return false;
      }

      if (normalizedQuery.isNotEmpty) {
        final hay =
            '${p.name} ${p.description} ${p.categoryName ?? ''}'.toLowerCase();
        if (!hay.contains(normalizedQuery)) return false;
      }

      if ((size != null && size.isNotEmpty) ||
          (colour != null && colour.isNotEmpty)) {
        final hasMatchingInStock = p.variants.any((v) {
          if (!v.isInStock) return false;
          final sizeOk = size == null || size.isEmpty || v.size == size;
          final colourOk = colour == null ||
              colour.isEmpty ||
              v.colour.toLowerCase() == colour.toLowerCase();
          return sizeOk && colourOk;
        });
        if (!hasMatchingInStock) return false;
      }

      return true;
    }).toList();

    switch (sort) {
      case CatalogueSort.newest:
        filtered.sort(
          (a, b) => (b.createdAt ?? DateTime(2026))
              .compareTo(a.createdAt ?? DateTime(2026)),
        );
      case CatalogueSort.priceLowToHigh:
        filtered.sort((a, b) => a.basePrice.compareTo(b.basePrice));
      case CatalogueSort.priceHighToLow:
        filtered.sort((a, b) => b.basePrice.compareTo(a.basePrice));
      case CatalogueSort.bestSelling:
        filtered.sort((a, b) {
          final bySold = b.unitsSold.compareTo(a.unitsSold);
          if (bySold != 0) return bySold;
          if (a.isFeatured != b.isFeatured) return a.isFeatured ? -1 : 1;
          return a.name.compareTo(b.name);
        });
    }

    return filtered;
  }
}
