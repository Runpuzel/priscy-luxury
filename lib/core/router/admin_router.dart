import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/providers.dart';
import '../../features/admin/auth/admin_login_screen.dart';
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

final adminRouterProvider = Provider<GoRouter>((ref) {
  final adminAsync = ref.watch(adminAuthProvider);

  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final isLoggingIn = state.matchedLocation == '/login';
      if (adminAsync.isLoading) return null;
      final admin = adminAsync.valueOrNull;

      if (admin == null || !admin.isAdmin) {
        return isLoggingIn ? null : '/login';
      }
      if (isLoggingIn) return '/';
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const AdminLoginScreen(),
      ),
      GoRoute(
        path: '/',
        builder: (context, state) => const AdminDashboardScreen(),
      ),
      GoRoute(
        path: '/orders',
        builder: (context, state) => const AdminOrdersScreen(),
      ),
      GoRoute(
        path: '/orders/manual-new',
        builder: (context, state) => const AdminManualOrderScreen(),
      ),
      GoRoute(
        path: '/orders/:id',
        builder: (context, state) => AdminOrderDetailScreen(
          orderId: state.pathParameters['id'] ?? '',
        ),
      ),
      GoRoute(
        path: '/products',
        builder: (context, state) => const AdminProductsScreen(),
      ),
      GoRoute(
        path: '/products/new',
        builder: (context, state) => const AdminProductEditorScreen(),
      ),
      GoRoute(
        path: '/products/:id',
        builder: (context, state) => AdminProductEditorScreen(
          productId: state.pathParameters['id'],
        ),
      ),
      GoRoute(
        path: '/stock',
        builder: (context, state) => const AdminStockScreen(),
      ),
      GoRoute(
        path: '/reviews',
        builder: (context, state) => const AdminReviewsScreen(),
      ),
      GoRoute(
        path: '/delivery',
        builder: (context, state) => const AdminDeliveryZonesScreen(),
      ),
      GoRoute(
        path: '/content',
        builder: (context, state) => const AdminContentScreen(),
      ),
      GoRoute(
        path: '/reports',
        builder: (context, state) => const AdminReportsScreen(),
      ),
    ],
  );
});
