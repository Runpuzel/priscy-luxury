import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/config/app_config.dart';
import '../core/utils/stock_calculator.dart';
import 'models/models.dart';
import 'repositories/auth_repository.dart';
import 'repositories/content_repository.dart';
import 'repositories/demo_database.dart';
import 'repositories/order_repository.dart';
import 'repositories/product_repository.dart';
import 'repositories/review_repository.dart';

// -----------------------------------------------------------------------------
// Infrastructure & Repository Providers
// -----------------------------------------------------------------------------

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('sharedPreferencesProvider must be overridden in main');
});

final demoDatabaseProvider = Provider<DemoDatabase>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return DemoDatabase(prefs);
});

final productRepositoryProvider = Provider<ProductRepository>((ref) {
  return ProductRepository(demoDb: ref.watch(demoDatabaseProvider));
});

final orderRepositoryProvider = Provider<OrderRepository>((ref) {
  return OrderRepository(demoDb: ref.watch(demoDatabaseProvider));
});

final reviewRepositoryProvider = Provider<ReviewRepository>((ref) {
  return ReviewRepository(demoDb: ref.watch(demoDatabaseProvider));
});

final contentRepositoryProvider = Provider<ContentRepository>((ref) {
  return ContentRepository(demoDb: ref.watch(demoDatabaseProvider));
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    demoDb: ref.watch(demoDatabaseProvider),
    prefs: ref.watch(sharedPreferencesProvider),
  );
});

// -----------------------------------------------------------------------------
// Data Refresh Trigger & Storefront Async Providers
// -----------------------------------------------------------------------------

/// Incrementing this counter refreshes product, order, review, and report queries.
final dataRefreshTriggerProvider = StateProvider<int>((ref) => 0);

final categoriesProvider = FutureProvider<List<Category>>((ref) async {
  ref.watch(dataRefreshTriggerProvider);
  return ref.watch(productRepositoryProvider).fetchCategories();
});

final storeProductsProvider = FutureProvider<List<Product>>((ref) async {
  ref.watch(dataRefreshTriggerProvider);
  return ref.watch(productRepositoryProvider).fetchProducts(includeInactive: false);
});

final adminProductsProvider = FutureProvider<List<Product>>((ref) async {
  ref.watch(dataRefreshTriggerProvider);
  return ref.watch(productRepositoryProvider).fetchProducts(includeInactive: true);
});

final productBySlugProvider =
    FutureProvider.family<Product?, String>((ref, slug) async {
  ref.watch(dataRefreshTriggerProvider);
  return ref.watch(productRepositoryProvider).fetchProductBySlug(slug);
});

final productReviewsProvider =
    FutureProvider.family<List<Review>, String>((ref, productId) async {
  ref.watch(dataRefreshTriggerProvider);
  return ref.watch(reviewRepositoryProvider).fetchApprovedReviews(productId);
});

final deliveryZonesProvider = FutureProvider<List<DeliveryZone>>((ref) async {
  ref.watch(dataRefreshTriggerProvider);
  return ref.watch(contentRepositoryProvider).fetchDeliveryZones();
});

final adminDeliveryZonesProvider =
    FutureProvider<List<DeliveryZone>>((ref) async {
  ref.watch(dataRefreshTriggerProvider);
  return ref
      .watch(contentRepositoryProvider)
      .fetchDeliveryZones(includeInactive: true);
});

final siteSettingsProvider = FutureProvider<SiteSettings>((ref) async {
  ref.watch(dataRefreshTriggerProvider);
  return ref.watch(contentRepositoryProvider).fetchSiteSettings();
});

final staticPagesProvider =
    FutureProvider<List<StaticPageContent>>((ref) async {
  ref.watch(dataRefreshTriggerProvider);
  return ref.watch(contentRepositoryProvider).fetchAllPages();
});

final pageBySlugProvider =
    FutureProvider.family<StaticPageContent?, String>((ref, slug) async {
  ref.watch(dataRefreshTriggerProvider);
  return ref.watch(contentRepositoryProvider).fetchPageBySlug(slug);
});

// -----------------------------------------------------------------------------
// Cart StateNotifier (Saved on Device + Synced to Account if Signed In)
// -----------------------------------------------------------------------------

class CartNotifier extends StateNotifier<List<CartItem>> {
  CartNotifier(this._prefs, this._ref) : super(const []) {
    _restoreFromLocalStorage();
  }

  final SharedPreferences _prefs;
  final Ref _ref;
  static const _kCartStorageKey = 'priscy_cart_items_v1';

  void _restoreFromLocalStorage() {
    final raw = _prefs.getString(_kCartStorageKey);
    if (raw == null || raw.isEmpty) return;
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      state = decoded
          .whereType<Map<String, dynamic>>()
          .map(CartItem.fromJson)
          .toList();
    } catch (_) {
      state = const [];
    }
  }

  Future<void> _persist() async {
    await _prefs.setString(
      _kCartStorageKey,
      jsonEncode(state.map((e) => e.toJson()).toList()),
    );

    // Sync to Supabase `cart_items` table when customer is signed in on live mode
    if (AppConfig.useLiveSupabase) {
      final customer = _ref.read(customerAuthProvider).valueOrNull;
      if (customer != null) {
        final client = Supabase.instance.client;
        await client.from('cart_items').delete().eq('user_id', customer.id);
        for (final item in state) {
          await client.from('cart_items').upsert({
            'user_id': customer.id,
            'variant_id': item.variantId,
            'quantity': item.quantity,
          });
        }
      }
    }
  }

  void addItem({
    required Product product,
    required ProductVariant variant,
    int quantity = 1,
  }) {
    final maxAvail = variant.availableQty;
    if (maxAvail <= 0) return;

    final unitPrice =
        StockAndPricingCalculator.unitPriceForVariant(product, variant);
    final idx = state.indexWhere((i) => i.variantId == variant.id);

    if (idx != -1) {
      final existing = state[idx];
      final nextQty = (existing.quantity + quantity).clamp(1, maxAvail);
      final updated = List<CartItem>.from(state);
      updated[idx] = existing.copyWith(
        quantity: nextQty,
        unitPrice: unitPrice,
        maxAvailable: maxAvail,
      );
      state = updated;
    } else {
      state = [
        ...state,
        CartItem(
          variantId: variant.id,
          productId: product.id,
          productSlug: product.slug,
          productName: product.name,
          imageUrl: product.primaryImageUrl,
          size: variant.size,
          colour: variant.colour,
          unitPrice: unitPrice,
          quantity: quantity.clamp(1, maxAvail),
          maxAvailable: maxAvail,
        ),
      ];
    }
    _persist();
  }

  void updateQuantity(String variantId, int quantity) {
    if (quantity <= 0) {
      removeItem(variantId);
      return;
    }
    state = [
      for (final item in state)
        if (item.variantId == variantId)
          item.copyWith(quantity: quantity.clamp(1, item.maxAvailable))
        else
          item,
    ];
    _persist();
  }

  void removeItem(String variantId) {
    state = state.where((i) => i.variantId != variantId).toList();
    _persist();
  }

  void clearCart() {
    state = const [];
    _persist();
  }
}

final cartProvider = StateNotifierProvider<CartNotifier, List<CartItem>>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return CartNotifier(prefs, ref);
});

final cartItemCountProvider = Provider<int>((ref) {
  final items = ref.watch(cartProvider);
  return items.fold<int>(0, (sum, i) => sum + i.quantity);
});

final cartSubtotalProvider = Provider<double>((ref) {
  final items = ref.watch(cartProvider);
  return StockAndPricingCalculator.calculateSubtotal(items);
});

// -----------------------------------------------------------------------------
// Customer & Admin Auth State Notifiers
// -----------------------------------------------------------------------------

class CustomerAuthNotifier extends AsyncNotifier<UserProfile?> {
  @override
  Future<UserProfile?> build() async {
    return ref.watch(authRepositoryProvider).getCurrentCustomer();
  }

  Future<void> signIn(String email, String password) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref
          .read(authRepositoryProvider)
          .signInCustomer(email: email, password: password),
    );
  }

  Future<void> signUp({
    required String fullName,
    required String phone,
    required String email,
    required String password,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(authRepositoryProvider).signUpCustomer(
            fullName: fullName,
            phone: phone,
            email: email,
            password: password,
          ),
    );
  }

  Future<void> signOut() async {
    await ref.read(authRepositoryProvider).signOutCustomer();
    state = const AsyncData(null);
  }
}

final customerAuthProvider =
    AsyncNotifierProvider<CustomerAuthNotifier, UserProfile?>(
  CustomerAuthNotifier.new,
);

class AdminAuthNotifier extends AsyncNotifier<UserProfile?> {
  @override
  Future<UserProfile?> build() async {
    return ref.watch(authRepositoryProvider).getCurrentAdmin();
  }

  Future<void> signIn(String email, String password) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref
          .read(authRepositoryProvider)
          .signInAdmin(email: email, password: password),
    );
  }

  Future<void> signOut() async {
    await ref.read(authRepositoryProvider).signOutAdmin();
    state = const AsyncData(null);
  }
}

final adminAuthProvider =
    AsyncNotifierProvider<AdminAuthNotifier, UserProfile?>(
  AdminAuthNotifier.new,
);

// -----------------------------------------------------------------------------
// Admin Data Providers
// -----------------------------------------------------------------------------

final adminOrdersFilterProvider = StateProvider<OrderStatus?>((ref) => null);

final adminOrdersProvider = FutureProvider<List<Order>>((ref) async {
  ref.watch(dataRefreshTriggerProvider);
  final statusFilter = ref.watch(adminOrdersFilterProvider);
  return ref
      .watch(orderRepositoryProvider)
      .fetchAdminOrders(statusFilter: statusFilter);
});

final adminOrderByIdProvider =
    FutureProvider.family<Order?, String>((ref, orderId) async {
  ref.watch(dataRefreshTriggerProvider);
  return ref.watch(orderRepositoryProvider).fetchAdminOrderById(orderId);
});

final adminReviewsProvider = FutureProvider<List<Review>>((ref) async {
  ref.watch(dataRefreshTriggerProvider);
  return ref.watch(reviewRepositoryProvider).fetchAllReviewsForAdmin();
});

final adminStockMovementsProvider =
    FutureProvider<List<StockMovement>>((ref) async {
  ref.watch(dataRefreshTriggerProvider);
  return ref.watch(productRepositoryProvider).fetchStockMovements();
});

final adminDashboardMetricsProvider =
    FutureProvider<DashboardMetrics>((ref) async {
  ref.watch(dataRefreshTriggerProvider);
  final products = await ref.watch(adminProductsProvider.future);
  final settings = await ref.watch(siteSettingsProvider.future);
  return ref.watch(orderRepositoryProvider).computeDashboardMetrics(
        products,
        settings.lowStockThreshold,
      );
});
