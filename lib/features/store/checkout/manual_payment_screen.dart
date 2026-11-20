import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/app_config.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/validators.dart';
import '../../../core/utils/whatsapp_helper.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../core/widgets/store_scaffold.dart';
import '../../../data/models/models.dart';
import '../../../data/providers.dart';

/// Manual MoMo payment screen: customer pays seller directly, then submits
/// Transaction ID for seller verification in the Admin app.
class ManualPaymentScreen extends ConsumerStatefulWidget {
  const ManualPaymentScreen({
    super.key,
    this.orderId,
    this.orderNumber,
    this.trackingToken,
  });

  final String? orderId;
  final String? orderNumber;
  final String? trackingToken;

  @override
  ConsumerState<ManualPaymentScreen> createState() => _ManualPaymentScreenState();
}

class _ManualPaymentScreenState extends ConsumerState<ManualPaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _txnCtrl = TextEditingController();
  final _senderNameCtrl = TextEditingController();
  final _senderPhoneCtrl = TextEditingController();
  final _screenshotCtrl = TextEditingController();
  bool _submitting = false;
  bool _submitted = false;

  @override
  void dispose() {
    _txnCtrl.dispose();
    _senderNameCtrl.dispose();
    _senderPhoneCtrl.dispose();
    _screenshotCtrl.dispose();
    super.dispose();
  }

  Future<void> _copy(String value, String label) async {
    await Clipboard.setData(ClipboardData(text: value));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$label copied: $value')),
    );
  }

  Future<void> _submitProof(Order order) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    try {
      await ref.read(orderRepositoryProvider).submitManualPaymentProof(
            orderId: order.id,
            orderNumber: order.orderNumber,
            trackingToken: order.trackingToken,
            phone: order.customerPhone,
            txnId: _txnCtrl.text.trim(),
            senderName: _senderNameCtrl.text.trim(),
            senderPhone: _senderPhoneCtrl.text.trim(),
            screenshotUrl: _screenshotCtrl.text.trim().isEmpty
                ? null
                : _screenshotCtrl.text.trim(),
          );
      ref.read(dataRefreshTriggerProvider.notifier).state++;
      if (!mounted) return;
      setState(() => _submitted = true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.danger,
          content: Text(e.toString().replaceFirst('Bad state: ', '').replaceFirst('Exception: ', '')),
        ),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final orderFuture = ref.watch(orderRepositoryProvider).trackOrder(
          orderNumber: widget.orderNumber,
          trackingToken: widget.trackingToken,
        );

    return StoreScaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 32, 16, 32),
            child: FutureBuilder<Order?>(
              future: orderFuture,
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
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.receipt_long_outlined, size: 48, color: AppColors.mutedText),
                        const SizedBox(height: 12),
                        Text('Order not found', style: Theme.of(context).textTheme.headlineSmall),
                        const SizedBox(height: 8),
                        const Text('Please check your order number or tracking link.'),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => context.go('/track'),
                          child: const Text('Go to Order Tracking'),
                        ),
                      ],
                    ),
                  );
                }

                if (order.paymentStatus == PaymentStatus.paid) {
                  return _buildPaidState(order);
                }
                if (order.paymentStatus == PaymentStatus.awaitingVerification || _submitted) {
                  return _buildAwaitingState(order);
                }
                return _buildPayForm(order);
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPaidState(Order order) {
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
            child: Icon(Icons.check_rounded, size: 34, color: AppColors.success),
          ),
          const SizedBox(height: 16),
          Text(
            'Payment Verified! 🎉',
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
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => context.go(
              '/track?order=${Uri.encodeComponent(order.orderNumber)}&token=${Uri.encodeComponent(order.trackingToken)}',
            ),
            icon: const Icon(Icons.local_shipping_outlined, size: 18),
            label: const Text('Track Order Live'),
          ),
        ],
      ),
    );
  }

  Widget _buildAwaitingState(Order order) {
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
            backgroundColor: Color(0xFFF3E8FF),
            child: Icon(Icons.hourglass_top_rounded, size: 34, color: Color(0xFF6D28D9)),
          ),
          const SizedBox(height: 16),
          Text(
            'Proof Submitted — Awaiting Verification',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Thank you, ${order.customerName}! We have received your MoMo proof for order ${order.orderNumber} '
            '(Txn: ${order.manualTxnId ?? _txnCtrl.text}). Priscilla will verify it shortly and confirm on WhatsApp.',
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
          if (order.manualRejectionReason != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.dangerSoft,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Previous proof was rejected: ${order.manualRejectionReason}\nPlease check and submit again below.',
                style: const TextStyle(fontSize: 13),
              ),
            ),
          ],
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
                label: const Text('Track Order'),
              ),
              OutlinedButton.icon(
                onPressed: () {
                  WhatsAppHelper.openUrl(
                    WhatsAppHelper.buildSupportChatUrl(
                      message:
                          'Hello Priscy Luxury Slippers! I submitted MoMo payment proof for order ${order.orderNumber} (Txn: ${order.manualTxnId ?? _txnCtrl.text}). Please verify.',
                    ),
                  );
                },
                icon: const Icon(Icons.chat_outlined, size: 18),
                label: const Text('Message on WhatsApp'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPayForm(Order order) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Pay with Mobile Money',
          style: Theme.of(context).textTheme.headlineLarge,
        ),
        const SizedBox(height: 6),
        Text(
          'Order ${order.orderNumber} • Stock reserved for 24 hours',
          style: const TextStyle(color: AppColors.mutedText),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.espresso,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'STEP 1 — SEND MONEY TO THIS NUMBER',
                style: TextStyle(color: AppColors.gold, fontWeight: FontWeight.w800, fontSize: 12, letterSpacing: 1.2),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      AppConfig.manualMomoNumber,
                      style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800, letterSpacing: 1),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Copy number',
                    onPressed: () => _copy(AppConfig.manualMomoNumber, 'MoMo number'),
                    icon: const Icon(Icons.copy_rounded, color: AppColors.gold),
                  ),
                ],
              ),
              Text(
                'Name: ${AppConfig.manualMomoName}',
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 6),
              Text(
                'Networks: ${AppConfig.manualMomoNetworks.join(' • ')}',
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
              const Divider(color: Colors.white24, height: 28),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Exact Amount to Pay:', style: TextStyle(color: Colors.white70)),
                  Text(
                    CurrencyFormatter.formatGhs(order.total),
                    style: const TextStyle(color: AppColors.gold, fontSize: 24, fontWeight: FontWeight.w800),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const Text(
                '⚠️ Pay the EXACT amount. Write your Order Number as the reference/note.',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'STEP 2 — SUBMIT YOUR PAYMENT PROOF',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                const Text(
                  'After paying, enter your MoMo Transaction ID so the seller can verify and confirm your order.',
                  style: TextStyle(fontSize: 13, color: AppColors.mutedText),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _txnCtrl,
                  decoration: const InputDecoration(
                    labelText: 'MoMo Transaction ID *',
                    hintText: 'e.g. 12345678901 (from your MoMo SMS)',
                    prefixIcon: Icon(Icons.receipt_long_outlined),
                  ),
                  validator: (v) => Validators.requiredField(v, 'Transaction ID'),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 14,
                  runSpacing: 14,
                  children: [
                    SizedBox(
                      width: 280,
                      child: TextFormField(
                        controller: _senderNameCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Sender Name (as on MoMo) *',
                          hintText: 'e.g. Akosua Mensah',
                        ),
                        validator: (v) => Validators.requiredField(v, 'Sender name'),
                      ),
                    ),
                    SizedBox(
                      width: 280,
                      child: TextFormField(
                        controller: _senderPhoneCtrl,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: 'Sender Phone Number *',
                          hintText: '024 / 055 / 020...',
                        ),
                        validator: (v) => Validators.ghanaPhone(v, 'Sender phone'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _screenshotCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Screenshot URL (Optional)',
                    hintText: 'https://... (link to your MoMo screenshot)',
                    prefixIcon: Icon(Icons.image_outlined),
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _submitting ? null : () => _submitProof(order),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.espresso,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    icon: _submitting
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.verified_outlined, size: 19),
                    label: Text(_submitting ? 'Submitting...' : 'Submit Proof for Verification'),
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'The seller (Priscilla) will verify your payment in the Admin app and confirm your order. You will get a WhatsApp update.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: AppColors.mutedText),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: () {
            WhatsAppHelper.openUrl(
              WhatsAppHelper.buildSupportChatUrl(
                message:
                    'Hello Priscy Luxury Slippers! I need help paying for order ${order.orderNumber} (${CurrencyFormatter.formatGhs(order.total)}).',
              ),
            );
          },
          icon: const Icon(Icons.chat_rounded, size: 18),
          label: const Text('Need Help? Chat on WhatsApp'),
        ),
      ],
    );
  }
}
