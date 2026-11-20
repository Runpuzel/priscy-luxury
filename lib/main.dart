import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/config/app_bootstrap.dart';
import 'core/config/app_config.dart';
import 'core/router/unified_router.dart';
import 'core/theme/app_theme.dart';
import 'data/providers.dart';

/// Unified production app: ONE build, ONE login, role-based routing.
///
/// - Everyone signs in at /account.
/// - Admins are auto-redirected to /admin (dashboard).
/// - Customers stay in the storefront.
///
/// Split builds still work for backward compatibility:
/// - `flutter build web --target lib/main_store.dart --release -o build/store`
/// - `flutter build web --target lib/main_admin.dart --release -o build/admin`
Future<void> main() async {
  final bootstrap = await AppBootstrap.initialize();
  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(
          bootstrap.sharedPreferences,
        ),
      ],
      child: const PriscyUnifiedApp(),
    ),
  );
}

class PriscyUnifiedApp extends ConsumerWidget {
  const PriscyUnifiedApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(unifiedRouterProvider);
    return MaterialApp.router(
      title: '${AppConfig.brandName} — Premium Ghana Footwear',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.storefrontTheme,
      routerConfig: router,
    );
  }
}
