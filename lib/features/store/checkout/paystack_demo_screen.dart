import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/widgets/store_scaffold.dart';
import '../../../data/providers.dart';

/// Interactive Hosted Paystack Mobile Money Simulator used in Demo Mode
/// so Priscilla and testers can walk through the entire MTN MoMo / Telecel Cash / AT Money
/// authorization & webhook confirmation flow without needing live gateway keys yet.
class PaystackDemoScreen extends ConsumerStatefulWidget {
  const PaystackDemoScreen({
    super.key,
    required this.reference,
    required this.orderNumber,
    required this.trackingToken,
  });

  final String reference;
  final String orderNumber;
  final String trackingToken;

  @override
  ConsumerState<PaystackDemoScreen> createState() => _PaystackDemoScreenState();
}

class _PaystackDemoScreenState extends ConsumerState<PaystackDemoScreen> {
  String _network = 'MTN Mobile Money';
  bool _processing = false;

  Future<void> _approvePayment() async {
    setState(() => _processing = true);
    try {
      await ref
          .read(orderRepositoryProvider)
          .confirmDemoPayment(widget.reference);
      ref.read(cartProvider.notifier).clearCart();
      ref.read(dataRefreshTriggerProvider.notifier).state++;
      if (!mounted) return;
      context.go(
        '/order/confirmation?ref=${Uri.encodeComponent(widget.reference)}&order=${Uri.encodeComponent(widget.orderNumber)}&token=${Uri.encodeComponent(widget.trackingToken)}',
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(backgroundColor: AppColors.danger, content: Text('$e')),
      );
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final orderFuture = ref.watch(orderRepositoryProvider).trackOrder(
          trackingToken: widget.trackingToken,
          reference: widget.reference,
        );

    return StoreScaffold(
      includeFooter: false,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 40),
            child: FutureBuilder(
              future: orderFuture,
              builder: (context, snapshot) {
                final order = snapshot.data;
                return Container(
                  padding: const EdgeInsets.all(26),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.border, width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(18),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.successSoft,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'PAYSTACK MOBILE MONEY (DEMO)',
                              style: TextStyle(
                                color: AppColors.success,
                                fontWeight: FontWeight.w800,
                                fontSize: 11,
                              ),
                            ),
                          ),
                          Text(
                            widget.orderNumber,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.mutedText,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Text(
                        order != null
                            ? 'Pay ${CurrencyFormatter.formatGhs(order.total)}'
                            : 'Authorize Mobile Money Payment',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Merchant: Priscy Luxury Slippers • Stock reserved for 15 minutes',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const Divider(height: 28),
                      const Text(
                        'Choose Ghana Mobile Money Provider:',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 10),
                      for (final provider in const [
                        'MTN Mobile Money',
                        'Telecel Cash',
                        'AT Money',
                      ])
                        RadioListTile<String>(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          value: provider,
                          groupValue: _network,
                          title: Text(provider),
                          onChanged: (v) {
                            if (v != null) setState(() => _network = v);
                          },
                        ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.sand,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          'In live mode, Paystack sends a $_network USSD prompt to ${order?.customerPhone ?? 'your phone'} and confirms your order via signed webhook.',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        onPressed: _processing ? null : _approvePayment,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.success,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                        ),
                        icon: const Icon(Icons.verified_user_outlined, size: 19),
                        label: Text(
                          _processing
                              ? 'Confirming Payment...'
                              : 'Simulate MoMo PIN Approval (Success)',
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextButton(
                        onPressed: () => context.go('/checkout'),
                        child: const Text('Cancel & Return to Checkout'),
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
