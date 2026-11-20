import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/config/app_bootstrap.dart';
import 'core/config/app_config.dart';
import 'core/router/admin_router.dart';
import 'core/theme/app_theme.dart';
import 'data/providers.dart';

Future<void> main() async {
  final bootstrap = await AppBootstrap.initialize();
  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(
          bootstrap.sharedPreferences,
        ),
      ],
      child: const PriscyAdminApp(),
    ),
  );
}

class PriscyAdminApp extends ConsumerWidget {
  const PriscyAdminApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(adminRouterProvider);
    return MaterialApp.router(
      title: '${AppConfig.brandName} — Admin Dashboard',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.adminTheme,
      routerConfig: router,
    );
  }
}
