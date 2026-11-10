import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/whatsapp_helper.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../core/widgets/store_scaffold.dart';
import '../../../data/models/models.dart';
import '../../../data/providers.dart';

class OrderConfirmationScreen extends ConsumerStatefulWidget {
  const OrderConfirmationScreen({
    super.key,
    this.reference,
    this.orderNumber,
    this.trackingToken,
  });

  final String? reference;
  final String? orderNumber;
  final String? trackingToken;

  @override
  ConsumerState<OrderConfirmationScreen> createState() =>
      _OrderConfirmationScreenState();
}

class _OrderConfirmationScreenState
    extends ConsumerState<OrderConfirmationScreen> {
  Future<Order?>? _orderFuture;

  @override
  void initState() {
    super.initState();
    _loadOrder();
  }

  void _loadOrder() {
    _orderFuture = ref.read(orderRepositoryProvider).trackOrder(
          orderNumber: widget.orderNumber,
          trackingToken: widget.trackingToken,
          reference: widget.reference,
        );
  }

  @override
  Widget build(BuildContext context) {
    return StoreScaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 36, 16, 36),
            child: FutureBuilder<Order?>(
              future: _orderFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.all(64),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                final order = snapshot.data;
                if (order == null) {
                  return Container(
                    padding: const EdgeInsets.all(36),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.receipt_long_outlined,
                          size: 48,
                          color: AppColors.mutedText,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Verifying your order...',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'If you just completed payment, click Refresh or track using your order number.',
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 18),
                        Wrap(
                          spacing: 12,
                          children: [
                            ElevatedButton(
                              onPressed: () => setState(_loadOrder),
                              child: const Text('Refresh Status'),
                            ),
                            OutlinedButton(
                              onPressed: () => context.go('/track'),
                              child: const Text('Go to Order Tracking'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }

                return Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const CircleAvatar(
                        radius: 30,
                        backgroundColor: AppColors.successSoft,
                        child: Icon(
                          Icons.check_rounded,
                          size: 34,
                          color: AppColors.success,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Thank You, ${order.customerName}!',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Order ${order.orderNumber} is ${order.status.customerLabel}.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: AppColors.mutedText),
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 10,
                        children: [
                          OrderStatusBadge(status: order.status),
                          PaymentStatusBadge(status: order.paymentStatus),
                        ],
                      ),
                      const Divider(height: 32),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.sand,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Order Number: ${order.orderNumber}',
                              style: const TextStyle(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Secret Tracking Token: ${order.trackingToken}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.mutedText,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Delivery: ${order.deliveryMethod.label} ${order.region != null ? '(${order.city ?? order.region})' : ''}',
                              style: const TextStyle(fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      for (final item in order.items)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 5),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  '${item.productName} (EU ${item.size ?? '-'}, ${item.colour ?? '-'}) × ${item.quantity}',
                                ),
                              ),
                              Text(
                                CurrencyFormatter.formatGhs(item.lineTotal),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      const Divider(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Total Paid',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            CurrencyFormatter.formatGhs(order.total),
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 18,
                              color: AppColors.espresso,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        alignment: WrapAlignment.center,
                        children: [
                          ElevatedButton.icon(
                            onPressed: () => context.go(
                              '/track?order=${Uri.encodeComponent(order.orderNumber)}&token=${Uri.encodeComponent(order.trackingToken)}',
                            ),
                            icon: const Icon(Icons.local_shipping_outlined, size: 18),
                            label: const Text('Track Order Live'),
                          ),
                          OutlinedButton.icon(
                            onPressed: () {
                              WhatsAppHelper.openUrl(
                                WhatsAppHelper.buildSupportChatUrl(
                                  message:
                                      'Hello Priscy Luxury Slippers! I just completed Mobile Money payment for order ${order.orderNumber}.',
                                ),
                              );
                            },
                            icon: const Icon(Icons.chat_outlined, size: 18),
                            label: const Text('Message Us on WhatsApp'),
                          ),
                          TextButton(
                            onPressed: () => context.go('/catalogue'),
                            child: const Text('Continue Shopping'),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
