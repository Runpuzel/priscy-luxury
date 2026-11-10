import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/providers.dart';
import '../config/app_config.dart';
import '../theme/app_colors.dart';
import '../utils/whatsapp_helper.dart';

class StoreScaffold extends ConsumerWidget {
  const StoreScaffold({
    super.key,
    required this.body,
    this.bottomStickyBar,
    this.includeFooter = true,
  });

  final Widget body;
  final Widget? bottomStickyBar;
  final bool includeFooter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartCount = ref.watch(cartItemCountProvider);
    final customer = ref.watch(customerAuthProvider).valueOrNull;
    final settings =
        ref.watch(siteSettingsProvider).valueOrNull ?? const _DefaultSiteMeta();
    final width = MediaQuery.sizeOf(context).width;
    final isDesktop = width >= 940;

    return Scaffold(
      drawer: isDesktop
          ? null
          : Drawer(
              backgroundColor: AppColors.background,
              child: SafeArea(
                child: ListView(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppConfig.brandName,
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            AppConfig.slogan,
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.mutedText,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(),
                    _DrawerLink(icon: Icons.home_outlined, label: 'Home', path: '/'),
                    _DrawerLink(
                      icon: Icons.grid_view_rounded,
                      label: 'Shop All Styles',
                      path: '/catalogue',
                    ),
                    _DrawerLink(
                      icon: Icons.female_rounded,
                      label: 'Women\'s Collection',
                      path: '/catalogue?audience=women',
                    ),
                    _DrawerLink(
                      icon: Icons.male_rounded,
                      label: 'Men\'s Collection',
                      path: '/catalogue?audience=men',
                    ),
                    _DrawerLink(
                      icon: Icons.child_care_rounded,
                      label: 'Children\'s Collection',
                      path: '/catalogue?audience=children',
                    ),
                    _DrawerLink(
                      icon: Icons.local_shipping_outlined,
                      label: 'Track My Order',
                      path: '/track',
                    ),
                    _DrawerLink(
                      icon: Icons.person_outline_rounded,
                      label: customer != null
                          ? 'Account (${customer.fullName})'
                          : 'Sign In / Account',
                      path: '/account',
                    ),
                    const Divider(),
                    _DrawerLink(
                      icon: Icons.info_outline_rounded,
                      label: 'About Us',
                      path: '/pages/about',
                    ),
                    _DrawerLink(
                      icon: Icons.swap_horiz_rounded,
                      label: 'Delivery & Exchanges',
                      path: '/pages/delivery',
                    ),
                    _DrawerLink(
                      icon: Icons.support_agent_rounded,
                      label: 'Contact Us',
                      path: '/pages/contact',
                    ),
                  ],
                ),
              ),
            ),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(98),
        child: Column(
          children: [
            // Top announcement strip
            Container(
              width: double.infinity,
              height: 32,
              color: AppColors.espresso,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              alignment: Alignment.center,
              child: Text(
                'Nationwide Ghana Delivery (3–5 Days) • Pay Securely via Mobile Money • WhatsApp: ${settings is _DefaultSiteMeta ? AppConfig.supportPhoneLocal : (settings as dynamic).phone}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.sand,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            // Sticky main header
            Expanded(
              child: Material(
                color: AppColors.surface,
                elevation: 1,
                shadowColor: AppColors.espresso.withAlpha(20),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1240),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Row(
                        children: [
                          if (!isDesktop)
                            Builder(
                              builder: (ctx) => IconButton(
                                tooltip: 'Open Menu',
                                onPressed: () => Scaffold.of(ctx).openDrawer(),
                                icon: const Icon(Icons.menu_rounded),
                              ),
                            ),
                          InkWell(
                            onTap: () => context.go('/'),
                            borderRadius: BorderRadius.circular(8),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 6,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 34,
                                    height: 34,
                                    decoration: BoxDecoration(
                                      color: AppColors.espresso,
                                      borderRadius: BorderRadius.circular(9),
                                    ),
                                    alignment: Alignment.center,
                                    child: const Text(
                                      'PL',
                                      style: TextStyle(
                                        color: AppColors.gold,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    width < 400
                                        ? 'Priscy Luxury'
                                        : AppConfig.brandName,
                                    style: Theme.of(context)
                                        .appBarTheme
                                        .titleTextStyle,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          if (isDesktop) ...[
                            const SizedBox(width: 28),
                            _HeaderNavButton(label: 'Home', path: '/'),
                            _HeaderNavButton(
                              label: 'Catalogue',
                              path: '/catalogue',
                            ),
                            _HeaderNavButton(
                              label: 'Women',
                              path: '/catalogue?audience=women',
                            ),
                            _HeaderNavButton(
                              label: 'Men',
                              path: '/catalogue?audience=men',
                            ),
                            _HeaderNavButton(
                              label: 'Children',
                              path: '/catalogue?audience=children',
                            ),
                            _HeaderNavButton(
                              label: 'Track Order',
                              path: '/track',
                            ),
                          ],
                          const Spacer(),
                          IconButton(
                            tooltip: 'Search Footwear',
                            onPressed: () => _showSearchDialog(context),
                            icon: const Icon(Icons.search_rounded),
                          ),
                          IconButton(
                            tooltip: customer != null
                                ? 'My Account'
                                : 'Sign In / Account',
                            onPressed: () => context.go('/account'),
                            icon: Icon(
                              customer != null
                                  ? Icons.person_rounded
                                  : Icons.person_outline_rounded,
                            ),
                          ),
                          IconButton(
                            tooltip: 'Shopping Cart',
                            onPressed: () => context.go('/cart'),
                            icon: Badge(
                              isLabelVisible: cartCount > 0,
                              backgroundColor: AppColors.rose,
                              label: Text('$cartCount'),
                              child: const Icon(Icons.shopping_bag_outlined),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      body: SelectionArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              body,
              if (includeFooter) const _StoreFooter(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: bottomStickyBar,
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'store-whatsapp-fab',
        backgroundColor: AppColors.whatsappGreen,
        foregroundColor: Colors.white,
        onPressed: () {
          WhatsAppHelper.openUrl(WhatsAppHelper.buildSupportChatUrl());
        },
        icon: const Icon(Icons.chat_rounded, size: 20),
        label: const Text(
          'WhatsApp Us',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  void _showSearchDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Search Priscy Luxury'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Search slides, leather sandals, kids...',
            prefixIcon: Icon(Icons.search_rounded),
          ),
          onSubmitted: (val) {
            Navigator.of(ctx).pop();
            if (val.trim().isNotEmpty) {
              context.go('/catalogue?q=${Uri.encodeComponent(val.trim())}');
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final q = controller.text.trim();
              Navigator.of(ctx).pop();
              context.go(
                q.isEmpty
                    ? '/catalogue'
                    : '/catalogue?q=${Uri.encodeComponent(q)}',
              );
            },
            child: const Text('Search'),
          ),
        ],
      ),
    );
  }
}

class _DefaultSiteMeta {
  const _DefaultSiteMeta();
}

class _HeaderNavButton extends StatelessWidget {
  const _HeaderNavButton({required this.label, required this.path});
  final String label;
  final String path;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: () => context.go(path),
      style: TextButton.styleFrom(
        foregroundColor: AppColors.espresso,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
      child: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
      ),
    );
  }
}

class _DrawerLink extends StatelessWidget {
  const _DrawerLink({
    required this.icon,
    required this.label,
    required this.path,
  });
  final IconData icon;
  final String label;
  final String path;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.espresso),
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
      onTap: () {
        Navigator.of(context).pop();
        context.go(path);
      },
    );
  }
}

class _StoreFooter extends StatelessWidget {
  const _StoreFooter();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.espressoDark,
      margin: const EdgeInsets.only(top: 56),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 48),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 48,
                runSpacing: 32,
                children: [
                  SizedBox(
                    width: 310,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppConfig.brandName,
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(color: AppColors.gold),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          AppConfig.slogan,
                          style: TextStyle(color: AppColors.sand, fontSize: 14),
                        ),
                        const SizedBox(height: 14),
                        const Text(
                          'Phone & WhatsApp: ${AppConfig.supportPhoneLocal}\nEmail: ${AppConfig.supportEmail}\nKumasi & Nationwide Ghana Delivery',
                          style: TextStyle(
                            color: Color(0xFFD0C3B6),
                            fontSize: 13,
                            height: 1.6,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _FooterColumn(
                    heading: 'Shop Collection',
                    links: const [
                      ('All Footwear', '/catalogue'),
                      ('Flat Sandals', '/catalogue?category=flat-sandals'),
                      ('Slides & Slippers', '/catalogue?category=slides-slippers'),
                      ('Leather Sandals', '/catalogue?category=leather-sandals'),
                      ('Best Sellers', '/catalogue?bestSellers=true'),
                    ],
                  ),
                  _FooterColumn(
                    heading: 'Customer Care',
                    links: const [
                      ('Track Your Order', '/track'),
                      ('Delivery Information', '/pages/delivery'),
                      ('Returns & Exchanges', '/pages/returns'),
                      ('About Us', '/pages/about'),
                      ('Contact Us', '/pages/contact'),
                    ],
                  ),
                  _FooterColumn(
                    heading: 'Legal & Policies',
                    links: const [
                      ('Privacy Policy', '/pages/privacy'),
                      ('Terms & Conditions', '/pages/terms'),
                      ('Customer Account', '/account'),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 36),
              const Divider(color: Color(0xFF47352B)),
              const SizedBox(height: 16),
              Wrap(
                spacing: 16,
                runSpacing: 8,
                alignment: WrapAlignment.spaceBetween,
                children: [
                  const Text(
                    '© 2026 Priscy Luxury Slippers • Prepared for Priscilla Adutwum, Ghana.',
                    style: TextStyle(color: Color(0xFFB5A495), fontSize: 12),
                  ),
                  const Text(
                    'Secured by Paystack Mobile Money (MTN MoMo • Telecel Cash • AT Money)',
                    style: TextStyle(color: AppColors.gold, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FooterColumn extends StatelessWidget {
  const _FooterColumn({required this.heading, required this.links});
  final String heading;
  final List<(String, String)> links;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 190,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            heading,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 12),
          for (final (label, path) in links)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: InkWell(
                onTap: () => context.go(path),
                child: Text(
                  label,
                  style: const TextStyle(
                    color: Color(0xFFD5C7B8),
                    fontSize: 13,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
