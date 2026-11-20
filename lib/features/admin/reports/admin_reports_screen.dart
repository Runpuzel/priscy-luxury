import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/admin_scaffold.dart';
import '../../../data/models/models.dart';
import '../../../data/providers.dart';

class AdminReportsScreen extends ConsumerWidget {
  const AdminReportsScreen({super.key});

  void _openSalesCsvDialog(BuildContext context, List<Order> orders) {
    final paid =
        orders.where((o) => o.paymentStatus == PaymentStatus.paid).toList();
    final rows = <String>[
      'order_number,created_at,channel,customer_name,customer_phone,delivery_method,region,subtotal_ghs,delivery_fee_ghs,total_ghs,status',
      for (final o in paid)
        [
          o.orderNumber,
          o.createdAt.toIso8601String(),
          o.channel,
          Validators.escapeCsvCell(o.customerName),
          o.customerPhone,
          o.deliveryMethod.dbValue,
          Validators.escapeCsvCell(o.region ?? ''),
          o.subtotal.toStringAsFixed(2),
          o.deliveryFee.toStringAsFixed(2),
          o.total.toStringAsFixed(2),
          o.status.dbValue,
        ].join(','),
    ];

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Export Paid Orders CSV Report'),
        content: SizedBox(
          width: 640,
          child: SelectableText(
            rows.join('\n'),
            style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final metricsAsync = ref.watch(adminDashboardMetricsProvider);
    final orders = ref.watch(adminOrdersProvider).valueOrNull ?? const [];

    return AdminScaffold(
      title: 'Sales Reports & Analytics',
      currentPath: '/reports',
      actions: [
        ElevatedButton.icon(
          onPressed: () => _openSalesCsvDialog(context, orders),
          icon: const Icon(Icons.download_rounded, size: 18),
          label: const Text('Export Sales CSV'),
        ),
      ],
      body: metricsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Text('Error: $e'),
        data: (m) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Revenue summary strip
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                _SummaryBox(
                  title: '7-Day Paid Sales',
                  amount: CurrencyFormatter.formatGhs(m.revenueThisWeek),
                ),
                _SummaryBox(
                  title: 'Month-to-Date Sales',
                  amount: CurrencyFormatter.formatGhs(m.revenueThisMonth),
                ),
                _SummaryBox(
                  title: 'Paid Orders Total',
                  amount:
                      '${orders.where((o) => o.paymentStatus == PaymentStatus.paid).length} orders',
                ),
              ],
            ),
            const SizedBox(height: 22),
            // Category Breakdown Pie/Bar + Product Sales Table
            Container(
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
                    'Daily Revenue Trend (GHS)',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    height: 220,
                    child: LineChart(
                      LineChartData(
                        borderData: FlBorderData(show: false),
                        gridData: const FlGridData(
                          show: true,
                          drawVerticalLine: false,
                        ),
                        titlesData: FlTitlesData(
                          topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 28,
                              getTitlesWidget: (v, meta) {
                                final i = v.toInt();
                                if (i < 0 || i >= m.dailySales.length) {
                                  return const SizedBox.shrink();
                                }
                                return Padding(
                                  padding: const EdgeInsets.only(top: 6),
                                  child: Text(
                                    m.dailySales[i].label,
                                    style: const TextStyle(fontSize: 11.5),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        lineBarsData: [
                          LineChartBarData(
                            isCurved: true,
                            color: AppColors.espresso,
                            barWidth: 3,
                            dotData: const FlDotData(show: true),
                            spots: [
                              for (var i = 0; i < m.dailySales.length; i++)
                                FlSpot(i.toDouble(), m.dailySales[i].revenue),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            Wrap(
              spacing: 20,
              runSpacing: 20,
              children: [
                SizedBox(
                  width: 540,
                  child: Container(
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
                          'Sales by Product',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const Divider(height: 20),
                        for (final row in m.salesByProduct)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    '${row.productName} (${row.unitsSold} pairs)',
                                  ),
                                ),
                                Text(
                                  CurrencyFormatter.formatGhs(row.revenue),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                SizedBox(
                  width: 420,
                  child: Container(
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
                          'Sales by Category',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const Divider(height: 20),
                        for (final cat in m.salesByCategory)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '${cat.categoryName} (${cat.unitsSold} pairs)',
                                ),
                                Text(
                                  CurrencyFormatter.formatGhs(cat.revenue),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryBox extends StatelessWidget {
  const _SummaryBox({required this.title, required this.amount});
  final String title;
  final String amount;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 12.5, color: AppColors.mutedText),
          ),
          const SizedBox(height: 6),
          Text(
            amount,
            style: const TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.w800,
              color: AppColors.espresso,
            ),
          ),
        ],
      ),
    );
  }
}
