import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/app_config.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/whatsapp_helper.dart';
import '../../../core/widgets/product_image_view.dart';
import '../../../data/providers.dart';

/// Step 0 Quick Holding Page (Section 16):
/// Brand showcase, 20-product gallery, and direct 1-tap WhatsApp order button
/// ready for immediate 1 November 2026 launch while Paystack KYC completes.
class HoldingLaunchScreen extends ConsumerWidget {
  const HoldingLaunchScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final products = ref.watch(storeProductsProvider).valueOrNull ?? const [];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              color: AppColors.espressoDark,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 48),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 920),
                  child: Column(
                    children: [
                      const Text(
                        'LAUNCH SHOWCASE • GHANA NATIONWIDE DELIVERY',
                        style: TextStyle(
                          color: AppColors.gold,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        AppConfig.brandName,
                        textAlign: TextAlign.center,
                        style: Theme.of(context)
                            .textTheme
                            .displaySmall
                            ?.copyWith(color: Colors.white),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        AppConfig.slogan,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.sand, fontSize: 16),
                      ),
                      const SizedBox(height: 22),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        alignment: WrapAlignment.center,
                        children: [
                          ElevatedButton.icon(
                            onPressed: () => WhatsAppHelper.openUrl(
                              WhatsAppHelper.buildSupportChatUrl(),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.whatsappGreen,
                            ),
                            icon: const Icon(Icons.chat_rounded),
                            label: const Text(
                              'Order Directly on WhatsApp (${AppConfig.supportPhoneLocal})',
                            ),
                          ),
                          OutlinedButton(
                            onPressed: () => context.go('/'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: const BorderSide(color: AppColors.gold),
                            ),
                            child: const Text('Enter Full Storefront'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1180),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: [
                      for (final p in products)
                        Container(
                          width: 270,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              SizedBox(
                                height: 190,
                                child: ProductImageView(
                                  imageUrl: p.primaryImageUrl,
                                  altText: p.name,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                p.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                CurrencyFormatter.formatGhs(p.basePrice),
                                style: const TextStyle(
                                  color: AppColors.espresso,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 8),
                              OutlinedButton.icon(
                                onPressed: () => WhatsAppHelper.openUrl(
                                  WhatsAppHelper.buildSingleProductOrderUrl(
                                    product: p,
                                  ),
                                ),
                                icon: const Icon(Icons.chat_outlined, size: 16),
                                label: const Text('Order on WhatsApp'),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
