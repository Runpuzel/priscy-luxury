import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/whatsapp_helper.dart';
import '../../../core/widgets/admin_scaffold.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../data/models/models.dart';
import '../../../data/providers.dart';

class AdminOrdersScreen extends ConsumerStatefulWidget {
  const AdminOrdersScreen({super.key});

  @override
  ConsumerState<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends ConsumerState<AdminOrdersScreen> {
  final _searchCtrl = TextEditingController();
  DateTimeRange? _dateRange;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activeStatus = ref.watch(adminOrdersFilterProvider);
    final ordersAsync = ref.watch(adminOrdersProvider);

    return AdminScaffold(
      title: 'Orders Management',
      currentPath: '/orders',
      actions: [
        ElevatedButton.icon(
          onPressed: () => context.go('/orders/manual-new'),
          icon: const Icon(Icons.add_rounded, size: 18),
          label: const Text('Create Manual Order'),
        ),
      ],
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Status filter chips + Date filter + Search
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ChoiceChip(
                      label: const Text('All'),
                      selected: activeStatus == null,
                      onSelected: (_) => ref
                          .read(adminOrdersFilterProvider.notifier)
                          .state = null,
                    ),
                    for (final st in OrderStatus.values)
                      ChoiceChip(
                        label: Text(st.label),
                        selected: activeStatus == st,
                        onSelected: (_) => ref
                            .read(adminOrdersFilterProvider.notifier)
                            .state = st,
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    SizedBox(
                      width: 280,
                      child: TextField(
                        controller: _searchCtrl,
                        onChanged: (_) => setState(() {}),
                        decoration: const InputDecoration(
                          hintText: 'Search order #, customer, phone...',
                          prefixIcon: Icon(Icons.search_rounded),
                          isDense: true,
                        ),
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: () async {
                        final picked = await showDateRangePicker(
                          context: context,
                          firstDate: DateTime(2025),
                          lastDate: DateTime(2028),
                          initialDateRange: _dateRange,
                        );
                        if (picked != null) {
                          setState(() => _dateRange = picked);
                        }
                      },
                      icon: const Icon(Icons.calendar_today_outlined, size: 16),
                      label: Text(
                        _dateRange == null
                            ? 'Filter by Date'
                            : '${CurrencyFormatter.formatDate(_dateRange!.start)} – ${CurrencyFormatter.formatDate(_dateRange!.end)}',
                      ),
                    ),
                    if (_dateRange != null)
                      TextButton(
                        onPressed: () => setState(() => _dateRange = null),
                        child: const Text('Clear Dates'),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          ordersAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(48),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => Text('Error loading orders: $e'),
            data: (orders) {
              final q = _searchCtrl.text.trim().toLowerCase();
              final filtered = orders.where((o) {
                if (_dateRange != null) {
                  final endDay = _dateRange!.end.add(const Duration(days: 1));
                  if (o.createdAt.isBefore(_dateRange!.start) ||
                      o.createdAt.isAfter(endDay)) {
                    return false;
                  }
                }
                if (q.isNotEmpty) {
                  final hay =
                      '${o.orderNumber} ${o.customerName} ${o.customerPhone} ${o.city ?? ''}'
                          .toLowerCase();
                  if (!hay.contains(q)) return false;
                }
                return true;
              }).toList();

              if (filtered.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(40),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: const Center(
                    child: Text('No orders match the selected filters.'),
                  ),
                );
              }

              return Column(
                children: [
                  for (final order in filtered)
                    Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Wrap(
                        alignment: WrapAlignment.spaceBetween,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 16,
                        runSpacing: 12,
                        children: [
                          SizedBox(
                            width: 240,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  order.orderNumber,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 15,
                                  ),
                                ),
                                Text(
                                  '${CurrencyFormatter.formatDateTime(order.createdAt)} • ${order.channel == 'whatsapp_manual' ? 'WhatsApp' : 'Website'}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.mutedText,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(
                            width: 220,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  order.customerName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  '${order.customerPhone} • ${order.city ?? order.deliveryMethod.label}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.mutedText,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            CurrencyFormatter.formatGhs(order.total),
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                              color: AppColors.espresso,
                            ),
                          ),
                          Wrap(
                            spacing: 8,
                            children: [
                              OrderStatusBadge(status: order.status),
                              PaymentStatusBadge(status: order.paymentStatus),
                            ],
                          ),
                          Wrap(
                            spacing: 8,
                            children: [
                              IconButton(
                                tooltip: 'Send WhatsApp Update',
                                onPressed: () {
                                  WhatsAppHelper.openUrl(
                                    WhatsAppHelper
                                        .buildAdminOrderStatusUpdateUrl(
                                      order: order,
                                    ),
                                  );
                                },
                                icon: const Icon(
                                  Icons.chat_rounded,
                                  color: AppColors.whatsappGreen,
                                ),
                              ),
                              OutlinedButton(
                                onPressed: () =>
                                    context.go('/orders/${order.id}'),
                                child: const Text('Manage'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
