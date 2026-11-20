import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/widgets/admin_scaffold.dart';
import '../../../data/models/models.dart';
import '../../../data/providers.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final metricsAsync = ref.watch(adminDashboardMetricsProvider);

    return AdminScaffold(
      title: 'Store Overview',
      currentPath: '/',
      actions: [
        FilledButton.icon(
          onPressed: () => context.go('/orders/manual-new'),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.gold,
            foregroundColor: AppColors.espressoDark,
          ),
          icon: const Icon(Icons.add_rounded, size: 18),
          label: const Text('New WhatsApp Order'),
        ),
      ],
      body: metricsAsync.when(
        loading: () => const Padding(
          padding: EdgeInsets.all(64),
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (e, _) => Text('Error loading metrics: $e'),
        data: (m) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top KPI Cards (Section 6.2)
              Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  _KpiCard(
                    label: 'Today\'s Orders',
                    value: '${m.todaysOrders}',
                    subtitle: 'Website & WhatsApp',
                    icon: Icons.shopping_bag_outlined,
                    onTap: () => context.go('/orders'),
                  ),
                  _KpiCard(
                    label: 'Revenue (7 Days)',
                    value: CurrencyFormatter.formatGhs(m.revenueThisWeek),
                    subtitle: 'Paid Mobile Money orders',
                    icon: Icons.payments_outlined,
                    onTap: () => context.go('/reports'),
                  ),
                  _KpiCard(
                    label: 'Revenue (This Month)',
                    value: CurrencyFormatter.formatGhs(m.revenueThisMonth),
                    subtitle: 'Confirmed revenue',
                    icon: Icons.trending_up_rounded,
                    onTap: () => context.go('/reports'),
                  ),
                  _KpiCard(
                    label: 'Orders to Dispatch',
                    value: '${m.pendingOrdersCount}',
                    subtitle: 'Confirmed & Processing',
                    icon: Icons.local_shipping_outlined,
                    accent: m.pendingOrdersCount > 0 ? AppColors.warning : null,
                    onTap: () => context.go('/orders'),
                  ),
                  _KpiCard(
                    label: 'Low-Stock Variants',
                    value: '${m.lowStockItems.length}',
                    subtitle: 'At or below alert threshold',
                    icon: Icons.warning_amber_rounded,
                    accent: m.lowStockItems.isNotEmpty ? AppColors.rose : null,
                    onTap: () => context.go('/stock'),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // 7-day Revenue Chart + Best Sellers
              LayoutBuilder(
                builder: (context, constraints) {
                  final wide = constraints.maxWidth >= 900;
                  final chartPanel = _SevenDaySalesChart(points: m.dailySales);
                  final bestSellersPanel =
                      _BestSellersPanel(products: m.bestSellers);

                  if (wide) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 6, child: chartPanel),
                        const SizedBox(width: 20),
                        Expanded(flex: 5, child: bestSellersPanel),
                      ],
                    );
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      chartPanel,
                      const SizedBox(height: 20),
                      bestSellersPanel,
                    ],
                  );
                },
              ),
              const SizedBox(height: 24),
              // Low-stock alerts with 1-tap +5 restock
              _LowStockAlertsCard(items: m.lowStockItems.take(10).toList()),
            ],
          );
        },
      ),
    );
  }
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({
    required this.label,
    required this.value,
    required this.subtitle,
    required this.icon,
    this.accent,
    this.onTap,
  });

  final String label;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color? accent;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final tint = accent ?? AppColors.espresso;
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        width: 225,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.mutedText,
                  ),
                ),
                Icon(icon, color: tint, size: 20),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: tint,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 11.5, color: AppColors.mutedText),
            ),
          ],
        ),
      ),
    );
  }
}

class _SevenDaySalesChart extends StatelessWidget {
  const _SevenDaySalesChart({required this.points});
  final List<DailySalesPoint> points;

  @override
  Widget build(BuildContext context) {
    final maxRev = points.fold<double>(
      500,
      (m, p) => p.revenue > m ? p.revenue * 1.2 : m,
    );

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Last 7 Days Revenue (GHS)',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 220,
            child: BarChart(
              BarChartData(
                maxY: maxRev,
                borderData: FlBorderData(show: false),
                gridData: const FlGridData(show: true, drawVerticalLine: false),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 48,
                      getTitlesWidget: (val, meta) => Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: Text(
                          val.toInt().toString(),
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.mutedText,
                          ),
                        ),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      getTitlesWidget: (val, meta) {
                        final idx = val.toInt();
                        if (idx < 0 || idx >= points.length) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            points[idx].label,
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                barGroups: [
                  for (var i = 0; i < points.length; i++)
                    BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: points[i].revenue,
                          width: 22,
                          color: AppColors.espresso,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(6),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BestSellersPanel extends StatelessWidget {
  const _BestSellersPanel({required this.products});
  final List<Product> products;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Top Selling Styles',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          for (final p in products)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          p.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13.5,
                          ),
                        ),
                        Text(
                          CurrencyFormatter.formatGhs(p.basePrice),
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.mutedText,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.sand,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      '${p.unitsSold} sold',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.espresso,
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

class _LowStockAlertsCard extends ConsumerWidget {
  const _LowStockAlertsCard({required this.items});
  final List<LowStockAlertItem> items;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Low-Stock & Sold-Out Variants',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              TextButton(
                onPressed: () => context.go('/stock'),
                child: const Text('Open Full Stock Grid →'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (items.isEmpty)
            const Text('All variants are well stocked.')
          else
            for (final alert in items)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${alert.product.name} — EU ${alert.variant.size}, ${alert.variant.colour}',
                        style: const TextStyle(fontSize: 13.5),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: alert.variant.availableQty == 0
                            ? AppColors.dangerSoft
                            : AppColors.roseSoft,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        '${alert.variant.availableQty} left',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                          color: alert.variant.availableQty == 0
                              ? AppColors.danger
                              : AppColors.rose,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    OutlinedButton(
                      onPressed: () async {
                        await ref
                            .read(productRepositoryProvider)
                            .adjustVariantStock(
                              variantId: alert.variant.id,
                              delta: 5,
                              reason: 'restock:quick_dashboard',
                            );
                        ref.read(dataRefreshTriggerProvider.notifier).state++;
                      },
                      child: const Text('+5 Restock'),
                    ),
                  ],
                ),
              ),
        ],
      ),
    );
  }
}
