import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/whatsapp_helper.dart';
import '../../../core/widgets/product_card.dart';
import '../../../core/widgets/product_image_view.dart';
import '../../../core/widgets/store_scaffold.dart';
import '../../../data/models/models.dart';
import '../../../data/providers.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(storeProductsProvider);
    final categoriesAsync = ref.watch(categoriesProvider);
    final settingsAsync = ref.watch(siteSettingsProvider);
    final settings = settingsAsync.valueOrNull ?? const SiteSettings();

    return StoreScaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _HeroBanner(settings: settings),
          const _TrustBadgesStrip(),
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1200),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 44),
                    _SectionHeader(
                      eyebrow: 'SHOP BY CATEGORY',
                      title: 'Handcrafted Styles for Every Occasion',
                      trailingLabel: 'View All',
                      onTrailingTap: () => context.go('/catalogue'),
                    ),
                    const SizedBox(height: 18),
                    categoriesAsync.when(
                      data: (cats) => _CategoryTilesRow(categories: cats),
                      loading: () => const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: CircularProgressIndicator(),
                        ),
                      ),
                      error: (e, _) => Text('Unable to load categories: $e'),
                    ),
                    const SizedBox(height: 44),
                    const _AudienceShortcutsSection(),
                    const SizedBox(height: 48),
                    productsAsync.when(
                      data: (products) {
                        final bestSellers = List<Product>.from(products)
                          ..sort((a, b) => b.unitsSold.compareTo(a.unitsSold));
                        final newest = List<Product>.from(products)
                          ..sort(
                            (a, b) => (b.createdAt ?? DateTime(2026))
                                .compareTo(a.createdAt ?? DateTime(2026)),
                          );

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _SectionHeader(
                              eyebrow: 'MOST LOVED ACROSS GHANA',
                              title: 'Best Sellers',
                              trailingLabel: 'See All Best Sellers',
                              onTrailingTap: () =>
                                  context.go('/catalogue?bestSellers=true'),
                            ),
                            const SizedBox(height: 18),
                            _ResponsiveProductGrid(
                              products: bestSellers.take(4).toList(),
                            ),
                            const SizedBox(height: 52),
                            _BrandStoryStrip(settings: settings),
                            const SizedBox(height: 52),
                            _SectionHeader(
                              eyebrow: 'FRESH FOR LAUNCH',
                              title: 'New Arrivals',
                              trailingLabel: 'Browse All 20 Styles',
                              onTrailingTap: () =>
                                  context.go('/catalogue?sort=newest'),
                            ),
                            const SizedBox(height: 18),
                            _ResponsiveProductGrid(
                              products: newest.take(8).toList(),
                            ),
                          ],
                        );
                      },
                      loading: () => const Padding(
                        padding: EdgeInsets.symmetric(vertical: 48),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                      error: (e, _) => Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text('Error loading products: $e'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroBanner extends StatelessWidget {
  const _HeroBanner({required this.settings});
  final SiteSettings settings;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isWide = width >= 860;

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.espressoDark, AppColors.espresso],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: EdgeInsets.symmetric(
        horizontal: 20,
        vertical: isWide ? 56 : 36,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: isWide
              ? Row(
                  children: [
                    Expanded(flex: 6, child: _HeroCopy(settings: settings)),
                    const SizedBox(width: 36),
                    Expanded(
                      flex: 5,
                      child: SizedBox(
                        height: 390,
                        child: ProductImageView(
                          imageUrl: settings.heroBannerUrl,
                          altText: 'Priscy Luxury Slippers Hero Showcase',
                          borderRadius: 20,
                        ),
                      ),
                    ),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _HeroCopy(settings: settings),
                    const SizedBox(height: 24),
                    SizedBox(
                      height: 250,
                      child: ProductImageView(
                        imageUrl: settings.heroBannerUrl,
                        altText: 'Priscy Luxury Slippers Hero Showcase',
                        borderRadius: 16,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _HeroCopy extends StatelessWidget {
  const _HeroCopy({required this.settings});
  final SiteSettings settings;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.gold.withAlpha(38),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.gold.withAlpha(110)),
          ),
          child: Text(
            settings.slogan.toUpperCase(),
            style: const TextStyle(
              color: AppColors.gold,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.7,
            ),
          ),
        ),
        const SizedBox(height: 18),
        Text(
          settings.heroHeadline,
          style: Theme.of(context).textTheme.displaySmall?.copyWith(
                color: Colors.white,
                height: 1.15,
              ),
        ),
        const SizedBox(height: 14),
        Text(
          settings.heroSubheadline,
          style: const TextStyle(
            color: AppColors.sand,
            fontSize: 15.5,
            height: 1.55,
          ),
        ),
        const SizedBox(height: 26),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            ElevatedButton.icon(
              onPressed: () => context.go('/catalogue'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.gold,
                foregroundColor: AppColors.espressoDark,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              ),
              icon: const Icon(Icons.shopping_bag_outlined, size: 19),
              label: Text(
                settings.heroCtaLabel,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            OutlinedButton.icon(
              onPressed: () {
                WhatsAppHelper.openUrl(WhatsAppHelper.buildSupportChatUrl());
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: AppColors.sand),
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              ),
              icon: const Icon(Icons.chat_outlined, size: 18),
              label: const Text('Order via WhatsApp'),
            ),
          ],
        ),
      ],
    );
  }
}

class _TrustBadgesStrip extends StatelessWidget {
  const _TrustBadgesStrip();

  @override
  Widget build(BuildContext context) {
    const items = [
      (
        Icons.phone_android_rounded,
        'Mobile Money Checkout',
        'MTN MoMo, Telecel Cash & AT Money via Paystack'
      ),
      (
        Icons.local_shipping_outlined,
        'Nationwide Delivery (3–5 Days)',
        'Kumasi 1–2 days, Accra & all 16 regions'
      ),
      (
        Icons.storefront_outlined,
        'Free Kumasi Pickup',
        'Collect in Kumasi once payment is confirmed'
      ),
      (
        Icons.swap_horiz_rounded,
        'Easy Size & Colour Exchange',
        'Hassle-free unworn exchanges within 3 days'
      ),
    ];

    return Container(
      color: AppColors.sand,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Wrap(
            spacing: 24,
            runSpacing: 16,
            alignment: WrapAlignment.spaceBetween,
            children: [
              for (final (icon, title, subtitle) in items)
                SizedBox(
                  width: 265,
                  child: Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(icon, color: AppColors.espresso, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                                color: AppColors.espresso,
                              ),
                            ),
                            Text(
                              subtitle,
                              style: const TextStyle(
                                fontSize: 11.5,
                                color: AppColors.mutedText,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.eyebrow,
    required this.title,
    this.trailingLabel,
    this.onTrailingTap,
  });

  final String eyebrow;
  final String title;
  final String? trailingLabel;
  final VoidCallback? onTrailingTap;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.end,
      runSpacing: 8,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              eyebrow,
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.1,
                color: AppColors.gold,
              ),
            ),
            const SizedBox(height: 4),
            Text(title, style: Theme.of(context).textTheme.headlineMedium),
          ],
        ),
        if (trailingLabel != null && onTrailingTap != null)
          TextButton.icon(
            onPressed: onTrailingTap,
            icon: Text(trailingLabel!),
            label: const Icon(Icons.arrow_forward_rounded, size: 17),
          ),
      ],
    );
  }
}

class _CategoryTilesRow extends StatelessWidget {
  const _CategoryTilesRow({required this.categories});
  final List<Category> categories;

  static const _catImages = {
    'flat-sandals':
        'https://images.unsplash.com/photo-1543163521-1bf539c55dd2?auto=format&fit=crop&w=800&q=80',
    'slides-slippers':
        'https://images.unsplash.com/photo-1603487742131-4160ec999306?auto=format&fit=crop&w=800&q=80',
    'leather-sandals':
        'https://images.unsplash.com/photo-1562273138-f46be4ebdf33?auto=format&fit=crop&w=800&q=80',
  };

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 720;
        final tileWidth = isMobile
            ? constraints.maxWidth
            : (constraints.maxWidth - 32) / 3;

        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: categories.map((cat) {
            final img = _catImages[cat.slug] ?? _catImages.values.first;
            return InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => context.go('/catalogue?category=${cat.slug}'),
              child: SizedBox(
                width: tileWidth,
                height: 190,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ProductImageView(
                      imageUrl: img,
                      altText: cat.name,
                      borderRadius: 16,
                    ),
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: LinearGradient(
                          colors: [
                            AppColors.espressoDark.withAlpha(205),
                            AppColors.espressoDark.withAlpha(50),
                          ],
                          begin: Alignment.bottomLeft,
                          end: Alignment.topRight,
                        ),
                      ),
                      padding: const EdgeInsets.all(20),
                      alignment: Alignment.bottomLeft,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            cat.name,
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(color: Colors.white),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Explore Styles →',
                            style: TextStyle(
                              color: AppColors.gold,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

class _AudienceShortcutsSection extends StatelessWidget {
  const _AudienceShortcutsSection();

  @override
  Widget build(BuildContext context) {
    const audiences = [
      (
        'Women',
        'Elegant slides, minimalist toe-rings & evening flats',
        '/catalogue?audience=women',
        Icons.female_rounded
      ),
      (
        'Men',
        'Handcrafted leather crossovers, mules & palm slippers',
        '/catalogue?audience=men',
        Icons.male_rounded
      ),
      (
        'Children',
        'Supportive Sunday sandals & cushioned everyday slides',
        '/catalogue?audience=children',
        Icons.child_care_rounded
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Wrap(
        spacing: 20,
        runSpacing: 16,
        alignment: WrapAlignment.spaceAround,
        children: [
          for (final (title, desc, route, icon) in audiences)
            SizedBox(
              width: 340,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => context.go(route),
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 25,
                        backgroundColor: AppColors.sand,
                        child: Icon(icon, color: AppColors.espresso, size: 26),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Shop $title',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                                color: AppColors.espresso,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              desc,
                              style: const TextStyle(
                                fontSize: 12.5,
                                color: AppColors.mutedText,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: AppColors.espresso,
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _BrandStoryStrip extends StatelessWidget {
  const _BrandStoryStrip({required this.settings});
  final SiteSettings settings;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 36),
      decoration: BoxDecoration(
        color: AppColors.sand,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.sandDeep),
      ),
      child: Column(
        children: [
          const Text(
            'OUR HERITAGE',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
              color: AppColors.espresso,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            settings.brandStoryTitle,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 12),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 740),
            child: Text(
              settings.brandStoryBody,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
          const SizedBox(height: 20),
          OutlinedButton(
            onPressed: () => context.go('/pages/about'),
            child: const Text('Read the Priscy Luxury Story'),
          ),
        ],
      ),
    );
  }
}

class _ResponsiveProductGrid extends StatelessWidget {
  const _ResponsiveProductGrid({required this.products});
  final List<Product> products;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final cols = w >= 1020
            ? 4
            : w >= 700
                ? 3
                : 2;
        final aspect = w < 430 ? 0.63 : 0.72;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: products.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: cols,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: aspect,
          ),
          itemBuilder: (context, index) => ProductCard(product: products[index]),
        );
      },
    );
  }
}
