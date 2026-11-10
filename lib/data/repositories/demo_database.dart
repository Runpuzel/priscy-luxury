import 'dart:convert';
import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

import '../../core/utils/stock_calculator.dart';
import '../../core/utils/validators.dart';
import '../models/models.dart';
import '../seed/demo_seed_data.dart';

/// Persistent local store used when `AppConfig.isDemoMode` is active.
/// Persists mutations into `SharedPreferences` (`localStorage` on Flutter Web)
/// so Storefront and Admin tabs stay synchronized during local evaluation.
class DemoDatabase {
  DemoDatabase(this._prefs) {
    _loadOrSeed();
  }

  final SharedPreferences _prefs;
  static const _kProducts = 'priscy_demo_products_v1';
  static const _kOrders = 'priscy_demo_orders_v1';
  static const _kReviews = 'priscy_demo_reviews_v1';
  static const _kZones = 'priscy_demo_zones_v1';
  static const _kPages = 'priscy_demo_pages_v1';
  static const _kSettings = 'priscy_demo_settings_v1';
  static const _kMovements = 'priscy_demo_movements_v1';
  static const _kAddresses = 'priscy_demo_addresses_v1';

  late List<Category> categories;
  late List<Product> products;
  late List<Order> orders;
  late List<Review> reviews;
  late List<DeliveryZone> deliveryZones;
  late List<StaticPageContent> pages;
  late SiteSettings settings;
  late List<StockMovement> stockMovements;
  late List<SavedAddress> savedAddresses;

  void _loadOrSeed() {
    categories = List<Category>.from(DemoSeedData.categories);

    products = _decodeList(_kProducts, Product.fromJson) ??
        DemoSeedData.buildProducts();
    orders =
        _decodeList(_kOrders, Order.fromJson) ?? DemoSeedData.buildSampleOrders();
    reviews = _decodeList(_kReviews, Review.fromJson) ??
        DemoSeedData.buildSampleReviews();
    deliveryZones = _decodeList(_kZones, DeliveryZone.fromJson) ??
        List<DeliveryZone>.from(DemoSeedData.deliveryZones);
    pages = _decodeList(_kPages, StaticPageContent.fromJson) ??
        DemoSeedData.buildStaticPages();
    stockMovements = _decodeList(_kMovements, StockMovement.fromJson) ??
        DemoSeedData.buildSampleMovements();
    savedAddresses = _decodeList(_kAddresses, SavedAddress.fromJson) ?? [];

    final rawSettings = _prefs.getString(_kSettings);
    if (rawSettings != null) {
      settings = SiteSettings.fromJson(
        jsonDecode(rawSettings) as Map<String, dynamic>,
      );
    } else {
      settings = DemoSeedData.siteSettings;
    }

    releaseExpiredReservations();
  }

  List<T>? _decodeList<T>(
    String key,
    T Function(Map<String, dynamic>) parser,
  ) {
    final raw = _prefs.getString(key);
    if (raw == null || raw.isEmpty) return null;
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list.whereType<Map<String, dynamic>>().map(parser).toList();
    } catch (_) {
      return null;
    }
  }

  Future<void> saveProducts() async => _prefs.setString(
        _kProducts,
        jsonEncode(products.map((e) => e.toJson()).toList()),
      );

  Future<void> saveOrders() async => _prefs.setString(
        _kOrders,
        jsonEncode(orders.map((e) => e.toJson()).toList()),
      );

  Future<void> saveReviews() async => _prefs.setString(
        _kReviews,
        jsonEncode(reviews.map((e) => e.toJson()).toList()),
      );

  Future<void> saveZones() async => _prefs.setString(
        _kZones,
        jsonEncode(deliveryZones.map((e) => e.toJson()).toList()),
      );

  Future<void> savePages() async => _prefs.setString(
        _kPages,
        jsonEncode(pages.map((e) => e.toJson()).toList()),
      );

  Future<void> saveSettings() async =>
      _prefs.setString(_kSettings, jsonEncode(settings.toJson()));

  Future<void> saveMovements() async => _prefs.setString(
        _kMovements,
        jsonEncode(stockMovements.map((e) => e.toJson()).toList()),
      );

  Future<void> saveAddresses() async => _prefs.setString(
        _kAddresses,
        jsonEncode(savedAddresses.map((e) => e.toJson()).toList()),
      );

  String nextId(String prefix) {
    final rand = Random().nextInt(900000) + 100000;
    return '$prefix-${DateTime.now().millisecondsSinceEpoch}-$rand';
  }

  String nextOrderNumber() {
    final now = DateTime.now();
    final y = now.year.toString().padLeft(4, '0');
    final m = now.month.toString().padLeft(2, '0');
    final d = now.day.toString().padLeft(2, '0');
    final seq = (orders.length + 1).toString().padLeft(4, '0');
    return 'PSY-$y$m$d-$seq';
  }

  int releaseExpiredReservations() {
    final now = DateTime.now();
    var released = 0;
    for (var i = 0; i < orders.length; i++) {
      final order = orders[i];
      if (StockAndPricingCalculator.isReservationExpired(order, now)) {
        for (final item in order.items) {
          if (item.variantId != null) {
            _mutateVariant(item.variantId!, (v) {
              return StockAndPricingCalculator.releaseUnpaidReservation(
                v,
                item.quantity,
              );
            });
          }
        }
        orders[i] = order.copyWith(
          status: OrderStatus.cancelled,
          clearReservedUntil: true,
          events: [
            ...order.events,
            OrderEvent(
              id: nextId('ev'),
              orderId: order.id,
              status: OrderStatus.cancelled,
              note: '15-minute payment reservation expired; stock released',
              createdAt: now,
            ),
          ],
        );
        released++;
      }
    }
    if (released > 0) {
      saveProducts();
      saveOrders();
    }
    return released;
  }

  void _mutateVariant(
    String variantId,
    ProductVariant Function(ProductVariant current) transform,
  ) {
    for (var pIdx = 0; pIdx < products.length; pIdx++) {
      final p = products[pIdx];
      final vIdx = p.variants.indexWhere((v) => v.id == variantId);
      if (vIdx != -1) {
        final updatedVariants = List<ProductVariant>.from(p.variants);
        updatedVariants[vIdx] = transform(updatedVariants[vIdx]);
        products[pIdx] = p.copyWith(variants: updatedVariants);
        return;
      }
    }
  }

  Product recalculateProductRatings(Product product) {
    final approved = reviews
        .where((r) => r.productId == product.id && r.isApproved)
        .toList();
    if (approved.isEmpty) {
      return product;
    }
    final avg =
        approved.fold<int>(0, (s, r) => s + r.rating) / approved.length;
    return product.copyWith(
      avgRating: double.parse(avg.toStringAsFixed(2)),
      reviewCount: approved.length,
    );
  }

  Order? findTrackableOrder({
    String? trackingToken,
    String? orderNumber,
    String? phone,
    String? reference,
  }) {
    releaseExpiredReservations();
    for (final o in orders) {
      if (trackingToken != null &&
          trackingToken.trim().isNotEmpty &&
          o.trackingToken == trackingToken.trim()) {
        return o;
      }
      if (reference != null &&
          reference.trim().isNotEmpty &&
          o.paystackReference == reference.trim()) {
        return o;
      }
      if (orderNumber != null &&
          orderNumber.trim().isNotEmpty &&
          phone != null &&
          phone.trim().isNotEmpty) {
        if (o.orderNumber.toUpperCase() == orderNumber.trim().toUpperCase() &&
            Validators.normalizeGhanaPhone(o.customerPhone) ==
                Validators.normalizeGhanaPhone(phone)) {
          return o;
        }
      }
    }
    return null;
  }
}
