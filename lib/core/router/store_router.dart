import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/store/account/account_screen.dart';
import '../../features/store/cart/cart_screen.dart';
import '../../features/store/catalogue/catalogue_screen.dart';
import '../../features/store/checkout/checkout_screen.dart';
import '../../features/store/checkout/order_confirmation_screen.dart';
import '../../features/store/checkout/paystack_demo_screen.dart';
import '../../features/store/home/home_screen.dart';
import '../../features/store/pages/holding_launch_screen.dart';
import '../../features/store/pages/static_page_screen.dart';
import '../../features/store/product/product_detail_screen.dart';
import '../../features/store/tracking/order_tracking_screen.dart';

final storeRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
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
        path: '/checkout/paystack-demo',
        builder: (context, state) {
          final qp = state.uri.queryParameters;
          return PaystackDemoScreen(
            reference: qp['ref'] ?? '',
            orderNumber: qp['order'] ?? '',
            trackingToken: qp['token'] ?? '',
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
        builder: (context, state) => const AccountScreen(),
      ),
      GoRoute(
        path: '/pages/:slug',
        builder: (context, state) => StaticPageScreen(
          slug: state.pathParameters['slug'] ?? 'about',
        ),
      ),
    ],
  );
});
