/// Compile-time and runtime configuration for Priscy Luxury Slippers.
///
/// Pass values via `--dart-define` or `--dart-define-from-file=.env`:
/// ```bash
/// flutter run -d chrome -t lib/main_store.dart --dart-define-from-file=.env
/// ```
class AppConfig {
  const AppConfig._();

  static const String brandName = 'Priscy Luxury Slippers';
  static const String ownerName = 'Priscilla Adutwum';
  static const String slogan =
      'Premium quality, affordable prices, unbeatable style!';
  static const String supportPhoneLocal = '0550571248';
  static const String whatsappDigits = '233550571248';
  static const String supportEmail = 'adupriscytwum@gmail.com';
  static const String currencyCode = 'GHS';
  static const String currencySymbol = 'GH₵';
  static const int defaultLowStockThreshold = 3;
  static const int reservationMinutes = 15;

  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: '',
  );

  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: '',
  );

  static const String paystackPublicKey = String.fromEnvironment(
    'PAYSTACK_PUBLIC_KEY',
    defaultValue: '',
  );

  static const String storeBaseUrl = String.fromEnvironment(
    'STORE_BASE_URL',
    defaultValue: 'https://priscyluxury.com',
  );

  static const String adminBaseUrl = String.fromEnvironment(
    'ADMIN_BASE_URL',
    defaultValue: 'https://admin.priscyluxury.com',
  );

  static const String _demoFlag = String.fromEnvironment(
    'DEMO_MODE',
    defaultValue: '',
  );

  /// True when live Supabase credentials are configured and DEMO_MODE is not forced on.
  static bool get useLiveSupabase =>
      supabaseUrl.trim().isNotEmpty &&
      supabaseAnonKey.trim().isNotEmpty &&
      _demoFlag.toLowerCase() != 'true';

  /// True when running with interactive pre-seeded demo data.
  static bool get isDemoMode => !useLiveSupabase;
}
