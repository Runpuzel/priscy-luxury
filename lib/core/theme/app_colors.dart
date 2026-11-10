import 'package:flutter/material.dart';

/// Brand palette recommended in Section 12 of the Technical Plan:
/// - Deep Espresso Brown: #3B2A20
/// - Warm Sand:           #F3E9DC
/// - Soft Gold Accent:    #C9A24B
/// - Off-White Background:#FAF7F2
/// - Rose Accent:         #B5485D
class AppColors {
  const AppColors._();

  static const Color espresso = Color(0xFF3B2A20);
  static const Color espressoDark = Color(0xFF241812);
  static const Color sand = Color(0xFFF3E9DC);
  static const Color sandDeep = Color(0xFFE6D5BF);
  static const Color gold = Color(0xFFC9A24B);
  static const Color goldLight = Color(0xFFF7EED7);
  static const Color background = Color(0xFFFAF7F2);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color rose = Color(0xFFB5485D);
  static const Color roseSoft = Color(0xFFFBE9ED);

  static const Color ink = Color(0xFF231915);
  static const Color mutedText = Color(0xFF6B584C);
  static const Color border = Color(0xFFE5DACB);

  static const Color success = Color(0xFF236B48);
  static const Color successSoft = Color(0xFFE6F4EC);
  static const Color warning = Color(0xFF9C6514);
  static const Color warningSoft = Color(0xFFFEF4E2);
  static const Color danger = Color(0xFFB42318);
  static const Color dangerSoft = Color(0xFFFEE4E2);
  static const Color whatsappGreen = Color(0xFF1FAF54);

  /// Maps product variant colour names to visual swatch colours.
  static Color swatchForName(String name) {
    switch (name.trim().toLowerCase()) {
      case 'espresso':
      case 'brown':
      case 'dark brown':
        return const Color(0xFF3B2A20);
      case 'gold':
      case 'metallic gold':
        return const Color(0xFFC9A24B);
      case 'sand':
      case 'beige':
      case 'cream':
      case 'ivory':
        return const Color(0xFFE8D8C3);
      case 'tan':
      case 'camel':
      case 'cognac':
        return const Color(0xFFB67642);
      case 'black':
        return const Color(0xFF1C1B1A);
      case 'rose':
      case 'blush':
      case 'pink':
        return const Color(0xFFB5485D);
      case 'olive':
      case 'green':
        return const Color(0xFF556B45);
      case 'white':
        return const Color(0xFFF8F6F2);
      default:
        return const Color(0xFF8C7362);
    }
  }
}
