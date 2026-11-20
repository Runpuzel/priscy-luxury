import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/providers.dart';
import '../../features/admin/content/admin_content_screen.dart';
import '../../features/admin/dashboard/admin_dashboard_screen.dart';
import '../../features/admin/delivery/admin_delivery_zones_screen.dart';
import '../../features/admin/orders/admin_manual_order_screen.dart';
import '../../features/admin/orders/admin_order_detail_screen.dart';
import '../../features/admin/orders/admin_orders_screen.dart';
import '../../features/admin/products/admin_product_editor_screen.dart';
import '../../features/admin/products/admin_products_screen.dart';
import '../../features/admin/reports/admin_reports_screen.dart';
import '../../features/admin/reviews/admin_reviews_screen.dart';
import '../../features/admin/stock/admin_stock_screen.dart';
import '../../features/auth/unified_login_screen.dart';
import '../../features/store/account/account_screen.dart';
import '../../features/store/cart/cart_screen.dart';
import '../../features/store/catalogue/catalogue_screen.dart';
import '../../features/store/checkout/checkout_screen.dart';
import '../../features/store/checkout/manual_payment_screen.dart';
import '../../features/store/checkout/order_confirmation_screen.dart';
import '../../features/store/home/home_screen.dart';
import '../../features/store/pages/holding_launch_screen.dart';
import '../../features/store/pages/static_page_screen.dart';
import '../../features/store/product/product_detail_screen.dart';
import '../../features/store/tracking/order_tracking_screen.dart';

/// Unified router: ONE app, ONE login, role-based routing.
///
/// - Everyone signs in at /account (UnifiedLoginScreen).
/// - Admins are auto-redirected to /admin (dashboard).
/// - Customers stay in the storefront.
/// - /admin/* routes are guarded: non-admins are sent to /account.
final unifiedRouterProvider = Provider<GoRouter>((ref) {
  final customerAsync = ref.watch(customerAuthProvider);

  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final location = state.matchedLocation;
      final isAdminRoute = location == '/admin' || location.startsWith('/admin/');
      final isAccountRoute = location == '/account';

      if (customerAsync.isLoading) return null;
      final profile = customerAsync.valueOrNull;
      final isAdmin = profile != null && profile.isAdmin;

      // Admins visiting the login page go straight to the dashboard.
      if (isAccountRoute && isAdmin) {
        return '/admin';
      }

      // Guard admin routes: only admins may enter.
      if (isAdminRoute) {
        if (profile == null) {
          return '/account?return=/admin';
        }
        if (!isAdmin) {
          return '/account';
        }
      }

      return null;
    },
    routes: [
      // ---- Storefront ----
      GoRoute(
        path: '/',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/launch',
        builder: (context, state) => const HoldingLaunchScreen(),
      ),
      GoRoute(
        path: '/catalogue',
        builder: (context, state) {
          final qp = state.uri.queryParameters;
          return CatalogueScreen(
            initialCategory: qp['category'],
            initialAudience: qp['audience'],
            initialSize: qp['size'],
            initialColour: qp['colour'],
            initialSort: qp['sort'],
            initialBestSellers: qp['bestSellers'] == 'true',
            initialQuery: qp['q'],
          );
        },
      ),
      GoRoute(
        path: '/product/:slug',
        builder: (context, state) => ProductDetailScreen(
          slug: state.pathParameters['slug'] ?? '',
        ),
      ),
      GoRoute(
        path: '/cart',
        builder: (context, state) => const CartScreen(),
      ),
      GoRoute(
        path: '/checkout',
        builder: (context, state) => const CheckoutScreen(),
      ),
      GoRoute(
        path: '/checkout/manual-payment',
        builder: (context, state) {
          final qp = state.uri.queryParameters;
          return ManualPaymentScreen(
            orderId: qp['id'],
            orderNumber: qp['order'],
            trackingToken: qp['token'],
          );
        },
      ),
      GoRoute(
        path: '/order/confirmation',
        builder: (context, state) {
          final qp = state.uri.queryParameters;
          return OrderConfirmationScreen(
            reference: qp['ref'],
            orderNumber: qp['order'],
            trackingToken: qp['token'],
          );
        },
      ),
      GoRoute(
        path: '/track',
        builder: (context, state) {
          final qp = state.uri.queryParameters;
          return OrderTrackingScreen(
            initialOrderNumber: qp['order'],
            initialToken: qp['token'],
          );
        },
      ),
      GoRoute(
        path: '/account',
        builder: (context, state) => AccountScreen(
          returnTo: state.uri.queryParameters['return'],
        ),
      ),
      GoRoute(
        path: '/pages/:slug',
        builder: (context, state) => StaticPageScreen(
          slug: state.pathParameters['slug'] ?? 'about',
        ),
      ),

      // ---- Admin (same app, hidden from customers) ----
      GoRoute(
        path: '/admin',
        builder: (context, state) => const AdminDashboardScreen(),
      ),
      GoRoute(
        path: '/admin/orders',
        builder: (context, state) => const AdminOrdersScreen(),
      ),
      GoRoute(
        path: '/admin/orders/manual-new',
        builder: (context, state) => const AdminManualOrderScreen(),
      ),
      GoRoute(
        path: '/admin/orders/:id',
        builder: (context, state) => AdminOrderDetailScreen(
          orderId: state.pathParameters['id'] ?? '',
        ),
      ),
      GoRoute(
        path: '/admin/products',
        builder: (context, state) => const AdminProductsScreen(),
      ),
      GoRoute(
        path: '/admin/products/new',
        builder: (context, state) => const AdminProductEditorScreen(),
      ),
      GoRoute(
        path: '/admin/products/:id',
        builder: (context, state) => AdminProductEditorScreen(
          productId: state.pathParameters['id'],
        ),
      ),
      GoRoute(
        path: '/admin/stock',
        builder: (context, state) => const AdminStockScreen(),
      ),
      GoRoute(
        path: '/admin/reviews',
        builder: (context, state) => const AdminReviewsScreen(),
      ),
      GoRoute(
        path: '/admin/delivery',
        builder: (context, state) => const AdminDeliveryZonesScreen(),
      ),
      GoRoute(
        path: '/admin/content',
        builder: (context, state) => const AdminContentScreen(),
      ),
      GoRoute(
        path: '/admin/reports',
        builder: (context, state) => const AdminReportsScreen(),
      ),
      GoRoute(
        path: '/admin/login',
        builder: (context, state) => const UnifiedLoginScreen(),
      ),
    ],
  );
});
