import 'main_store.dart' as store;

/// Default entry point so running `flutter run -d chrome` without `--target`
/// launches the customer storefront cleanly.
///
/// Production builds use explicit targets per Section 11:
/// - `flutter build web --target lib/main_store.dart --release -o build/store`
/// - `flutter build web --target lib/main_admin.dart --release -o build/admin`
Future<void> main() => store.main();
