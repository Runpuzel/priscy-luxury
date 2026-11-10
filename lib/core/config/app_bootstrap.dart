import 'package:flutter/widgets.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app_config.dart';

class AppBootstrapResult {
  const AppBootstrapResult({
    required this.sharedPreferences,
    required this.supabaseInitialized,
  });

  final SharedPreferences sharedPreferences;
  final bool supabaseInitialized;
}

class AppBootstrap {
  const AppBootstrap._();

  static Future<AppBootstrapResult> initialize() async {
    WidgetsFlutterBinding.ensureInitialized();
    // Section 5: go_router with path URL strategy (e.g. /product/adowa-gold-buckle-slide)
    usePathUrlStrategy();

    final prefs = await SharedPreferences.getInstance();
    var supabaseReady = false;

    if (AppConfig.useLiveSupabase) {
      await Supabase.initialize(
        url: AppConfig.supabaseUrl,
        anonKey: AppConfig.supabaseAnonKey,
      );
      supabaseReady = true;
    }

    return AppBootstrapResult(
      sharedPreferences: prefs,
      supabaseInitialized: supabaseReady,
    );
  }
}
