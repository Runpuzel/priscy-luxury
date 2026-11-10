import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/providers.dart';
import '../config/app_config.dart';
import '../theme/app_colors.dart';

class AdminScaffold extends ConsumerWidget {
  const AdminScaffold({
    super.key,
    required this.title,
    required this.currentPath,
    required this.body,
    this.actions,
  });

  final String title;
  final String currentPath;
  final Widget body;
  final List<Widget>? actions;

  static const _navItems = <(IconData, String, String)>[
    (Icons.dashboard_outlined, 'Dashboard', '/'),
    (Icons.receipt_long_outlined, 'Orders', '/orders'),
    (Icons.add_shopping_cart_rounded, 'Manual WhatsApp Order', '/orders/manual-new'),
    (Icons.checkroom_rounded, 'Products & Pricing', '/products'),
    (Icons.inventory_2_outlined, 'Variants, Stock & CSV', '/stock'),
    (Icons.reviews_outlined, 'Reviews Moderation', '/reviews'),
    (Icons.local_shipping_outlined, 'Delivery Zones', '/delivery'),
    (Icons.edit_note_rounded, 'Content & Pages', '/content'),
    (Icons.bar_chart_rounded, 'Sales Reports', '/reports'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final width = MediaQuery.sizeOf(context).width;
    final isWide = width >= 960;
    final admin = ref.watch(adminAuthProvider).valueOrNull;

    Widget buildNavPanel({required bool closeDrawerOnTap}) {
      return Container(
        width: 260,
        color: AppColors.espressoDark,
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: AppColors.gold,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          alignment: Alignment.center,
                          child: const Text(
                            'PL',
                            style: TextStyle(
                              color: AppColors.espressoDark,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text(
                            'Priscy Admin',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 17,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      admin?.fullName ?? AppConfig.ownerName,
                      style: const TextStyle(
                        color: AppColors.sand,
                        fontSize: 12,
                      ),
                    ),
                    if (AppConfig.isDemoMode) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.gold.withAlpha(45),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'DEMO DATA MODE',
                          style: TextStyle(
                            color: AppColors.gold,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const Divider(color: Color(0xFF47352B), height: 1),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  children: [
                    for (final (icon, label, path) in _navItems)
                      _AdminNavTile(
                        icon: icon,
                        label: label,
                        selected: path == '/'
                            ? currentPath == '/'
                            : currentPath.startsWith(path),
                        onTap: () {
                          if (closeDrawerOnTap) Navigator.of(context).pop();
                          context.go(path);
                        },
                      ),
                  ],
                ),
              ),
              const Divider(color: Color(0xFF47352B), height: 1),
              ListTile(
                leading: const Icon(Icons.logout_rounded, color: AppColors.sand),
                title: const Text(
                  'Sign Out',
                  style: TextStyle(color: AppColors.sand, fontSize: 13),
                ),
                onTap: () async {
                  await ref.read(adminAuthProvider.notifier).signOut();
                  if (context.mounted) context.go('/login');
                },
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      drawer: isWide ? null : Drawer(child: buildNavPanel(closeDrawerOnTap: true)),
      body: Row(
        children: [
          if (isWide) buildNavPanel(closeDrawerOnTap: false),
          Expanded(
            child: Column(
              children: [
                Material(
                  color: AppColors.surface,
                  elevation: 1,
                  shadowColor: AppColors.espresso.withAlpha(18),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        if (!isWide)
                          Builder(
                            builder: (ctx) => IconButton(
                              onPressed: () => Scaffold.of(ctx).openDrawer(),
                              icon: const Icon(Icons.menu_rounded),
                            ),
                          ),
                        Expanded(
                          child: Text(
                            title,
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                        ),
                        IconButton(
                          tooltip: 'Refresh Data',
                          onPressed: () {
                            ref.read(dataRefreshTriggerProvider.notifier).state++;
                          },
                          icon: const Icon(Icons.refresh_rounded),
                        ),
                        if (actions != null) ...actions!,
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: SelectionArea(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Align(
                        alignment: Alignment.topLeft,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 1240),
                          child: body,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminNavTile extends StatelessWidget {
  const _AdminNavTile({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      child: Material(
        color: selected ? AppColors.espresso : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: selected ? AppColors.gold : const Color(0xFFD5C7B8),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: selected ? Colors.white : const Color(0xFFD5C7B8),
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                      fontSize: 13.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
