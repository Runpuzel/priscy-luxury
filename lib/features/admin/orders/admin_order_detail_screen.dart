import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/app_config.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/whatsapp_helper.dart';
import '../../../core/widgets/admin_scaffold.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../data/models/models.dart';
import '../../../data/providers.dart';

class AdminOrderDetailScreen extends ConsumerStatefulWidget {
  const AdminOrderDetailScreen({super.key, required this.orderId});
  final String orderId;

  @override
  ConsumerState<AdminOrderDetailScreen> createState() =>
      _AdminOrderDetailScreenState();
}

class _AdminOrderDetailScreenState
    extends ConsumerState<AdminOrderDetailScreen> {
  OrderStatus? _selectedStatus;
  final _noteCtrl = TextEditingController();
  final _rejectionCtrl = TextEditingController();
  bool _saving = false;
  bool _verifying = false;

  @override
  void dispose() {
    _noteCtrl.dispose();
    _rejectionCtrl.dispose();
    super.dispose();
  }

  Future<void> _verifyManualPayment(Order order, bool approve) async {
    if (!approve && _rejectionCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a rejection reason.')),
      );
      return;
    }
    setState(() => _verifying = true);
    try {
      final waUrl = await ref.read(orderRepositoryProvider).verifyManualPayment(
            orderId: order.id,
            approve: approve,
            rejectionReason: approve ? null : _rejectionCtrl.text.trim(),
          );
      _rejectionCtrl.clear();
      ref.read(dataRefreshTriggerProvider.notifier).state++;
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(approve
              ? '✅ Payment verified! Order confirmed. Stock deducted.'
              : '❌ Payment rejected. Customer notified to re-submit.'),
          action: waUrl != null
              ? SnackBarAction(
                  label: 'SEND WHATSAPP',
                  textColor: AppColors.gold,
                  onPressed: () => WhatsAppHelper.openUrl(waUrl),
                )
              : null,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(backgroundColor: AppColors.danger, content: Text('$e')),
      );
    } finally {
      if (mounted) setState(() => _verifying = false);
    }
  }

  Future<void> _saveStatus(Order currentOrder) async {
    final target = _selectedStatus ?? currentOrder.status;
    setState(() => _saving = true);
    try {
      final updated =
          await ref.read(orderRepositoryProvider).updateOrderStatus(
                orderId: currentOrder.id,
                newStatus: target,
                trackingNote: _noteCtrl.text,
              );
      _noteCtrl.clear();
      ref.read(dataRefreshTriggerProvider.notifier).state++;
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Order updated to ${updated.status.label}.'),
          action: SnackBarAction(
            label: 'SEND WHATSAPP',
            textColor: AppColors.gold,
            onPressed: () {
              WhatsAppHelper.openUrl(
                WhatsAppHelper.buildAdminOrderStatusUpdateUrl(order: updated),
              );
            },
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(backgroundColor: AppColors.danger, content: Text('$e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showPackingSlipDialog(BuildContext context, Order order) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Packing Slip — ${order.orderNumber}'),
        content: SizedBox(
          width: 480,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  AppConfig.brandName,
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                ),
                Text(
                  'Support / WhatsApp: ${AppConfig.supportPhoneLocal}',
                  style: const TextStyle(fontSize: 12),
                ),
                const Divider(height: 24),
                Text(
                  'Deliver To: ${order.customerName}',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                Text('Phone: ${order.customerPhone}'),
                Text('Method: ${order.deliveryMethod.label}'),
                if (order.region != null)
                  Text('Location: ${order.city ?? ''}, ${order.region}'),
                if (order.address != null && order.address!.isNotEmpty)
                  Text('Address: ${order.address}'),
                if (order.landmark != null && order.landmark!.isNotEmpty)
                  Text('Landmark: ${order.landmark}'),
                const Divider(height: 24),
                for (final item in order.items)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text(
                      '[ ] ${item.quantity}x ${item.productName} — EU ${item.size ?? '-'}, ${item.colour ?? '-'}',
                    ),
                  ),
                const Divider(height: 24),
                Text(
                  'Total Paid: ${CurrencyFormatter.formatGhs(order.total)} (${order.paymentStatus.label})',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close (Use Ctrl+P / Cmd+P to Print)'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final orderAsync = ref.watch(adminOrderByIdProvider(widget.orderId));

    return AdminScaffold(
      title: 'Order Detail',
      currentPath: '/orders',
      actions: [
        TextButton.icon(
          onPressed: () => context.go('/orders'),
          icon: const Icon(Icons.arrow_back_rounded, size: 18),
          label: const Text('All Orders'),
        ),
      ],
      body: orderAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Text('Error: $e'),
        data: (order) {
          if (order == null) return const Text('Order not found.');
          _selectedStatus ??= order.status;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header bar
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 16,
                  runSpacing: 12,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          order.orderNumber,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        Text(
                          'Placed ${CurrencyFormatter.formatDateTime(order.createdAt)} • Channel: ${order.channel}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                    Wrap(
                      spacing: 10,
                      runSpacing: 8,
                      children: [
                        OrderStatusBadge(status: order.status),
                        PaymentStatusBadge(status: order.paymentStatus),
                        OutlinedButton.icon(
                          onPressed: () =>
                              _showPackingSlipDialog(context, order),
                          icon: const Icon(Icons.print_outlined, size: 18),
                          label: const Text('Packing Slip'),
                        ),
                        ElevatedButton.icon(
                          onPressed: () {
                            WhatsAppHelper.openUrl(
                              WhatsAppHelper.buildAdminOrderStatusUpdateUrl(
                                order: order,
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.whatsappGreen,
                          ),
                          icon: const Icon(Icons.chat_rounded, size: 18),
                          label: Text(
                            'Send "${order.status.label}" WhatsApp Update',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // Manual MoMo verification panel (seller confirms payment)
              if (order.isManualPayment) _buildVerificationPanel(order),
              if (order.isManualPayment) const SizedBox(height: 20),
              // Customer + Status Update panels
              Wrap(
                spacing: 20,
                runSpacing: 20,
                children: [
                  SizedBox(
                    width: 480,
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
                            'Customer & Delivery Details',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const Divider(height: 22),
                          Text('Name: ${order.customerName}'),
                          Text('Mobile Money Phone: ${order.customerPhone}'),
                          Text(
                            'WhatsApp: ${order.customerWhatsapp ?? order.customerPhone}',
                          ),
                          const SizedBox(height: 8),
                          Text('Method: ${order.deliveryMethod.label}'),
                          if (order.region != null)
                            Text('Region / City: ${order.region} — ${order.city ?? ''}'),
                          if (order.address != null && order.address!.isNotEmpty)
                            Text('Address: ${order.address}'),
                          if (order.landmark != null &&
                              order.landmark!.isNotEmpty)
                            Text('Landmark: ${order.landmark}'),
                          if (order.notes != null && order.notes!.isNotEmpty)
                            Text('Notes: ${order.notes}'),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 480,
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Update Order Status & Tracking Note',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<OrderStatus>(
                            value: _selectedStatus,
                            decoration: const InputDecoration(
                              labelText: 'Order Status',
                            ),
                            items: [
                              for (final st in OrderStatus.values)
                                DropdownMenuItem(
                                  value: st,
                                  child: Text(st.label),
                                ),
                            ],
                            onChanged: (v) =>
                                setState(() => _selectedStatus = v),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _noteCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Tracking / Dispatch Note (Optional)',
                              hintText:
                                  'e.g. Sent via VIP Parcel Kumasi–Accra #8812',
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Note: Cancelling an order before dispatch automatically restores reserved/sold stock.',
                            style: TextStyle(
                              fontSize: 11.5,
                              color: AppColors.mutedText,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            onPressed:
                                _saving ? null : () => _saveStatus(order),
                            child: Text(
                              _saving ? 'Saving...' : 'Save Status Update',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Items & Timeline
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Ordered Pairs',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 10),
                    for (final item in order.items)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                '${item.productName} — Size EU ${item.size ?? '-'}, ${item.colour ?? '-'} × ${item.quantity}',
                              ),
                            ),
                            Text(
                              CurrencyFormatter.formatGhs(item.lineTotal),
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    const Divider(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Subtotal: ${CurrencyFormatter.formatGhs(order.subtotal)}  •  Delivery: ${CurrencyFormatter.formatGhs(order.deliveryFee)}',
                        ),
                        Text(
                          'Total: ${CurrencyFormatter.formatGhs(order.total)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 17,
                            color: AppColors.espresso,
                          ),
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
    );
  }

  Widget _buildVerificationPanel(Order order) {
    final awaiting = order.needsVerification;
    final paid = order.paymentStatus == PaymentStatus.paid;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: awaiting
            ? const Color(0xFFF3E8FF)
            : paid
                ? AppColors.successSoft
                : AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: awaiting
              ? const Color(0xFF6D28D9)
              : paid
                  ? AppColors.success
                  : AppColors.border,
          width: awaiting ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                awaiting
                    ? Icons.verified_outlined
                    : paid
                        ? Icons.check_circle_rounded
                        : Icons.phone_android_outlined,
                color: awaiting
                    ? const Color(0xFF6D28D9)
                    : paid
                        ? AppColors.success
                        : AppColors.espresso,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  awaiting
                      ? '⏳ Manual MoMo Payment — Verify to Confirm Order'
                      : paid
                          ? '✅ Manual Payment Verified'
                          : '📱 Manual MoMo Payment (Awaiting Customer Proof)',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              PaymentStatusBadge(status: order.paymentStatus),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.7),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Payee: ${AppConfig.manualMomoName} • ${AppConfig.manualMomoNumber}'),
                Text('Expected amount: ${CurrencyFormatter.formatGhs(order.total)}'),
                if (order.manualTxnId != null)
                  Text('Customer Txn ID: ${order.manualTxnId}'),
                if (order.manualSenderName != null)
                  Text('Sender: ${order.manualSenderName} (${order.manualSenderPhone ?? ''})'),
                if (order.manualSubmittedAt != null)
                  Text('Submitted: ${CurrencyFormatter.formatDateTime(order.manualSubmittedAt!)}'),
                if (order.manualScreenshotUrl != null &&
                    order.manualScreenshotUrl!.isNotEmpty)
                  Text('Screenshot: ${order.manualScreenshotUrl}'),
                if (order.manualRejectionReason != null)
                  Text(
                    'Last rejection: ${order.manualRejectionReason}',
                    style: const TextStyle(color: AppColors.danger),
                  ),
              ],
            ),
          ),
          if (awaiting) ...[
            const SizedBox(height: 14),
            const Text(
              'Check your MoMo account for this Transaction ID and amount, then approve or reject below.',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _rejectionCtrl,
              decoration: const InputDecoration(
                labelText: 'Rejection reason (required if rejecting)',
                hintText: 'e.g. Amount mismatch — expected GH₵205.00',
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 10,
              children: [
                ElevatedButton.icon(
                  onPressed: _verifying ? null : () => _verifyManualPayment(order, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  ),
                  icon: const Icon(Icons.check_rounded, size: 18),
                  label: Text(_verifying ? 'Verifying...' : '✅ Approve & Confirm Order'),
                ),
                OutlinedButton.icon(
                  onPressed: _verifying ? null : () => _verifyManualPayment(order, false),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.danger,
                    side: const BorderSide(color: AppColors.danger),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  ),
                  icon: const Icon(Icons.close_rounded, size: 18),
                  label: const Text('Reject Proof'),
                ),
                OutlinedButton.icon(
                  onPressed: () {
                    WhatsAppHelper.openUrl(
                      WhatsAppHelper.buildSupportChatUrl(
                        message:
                            'Hello ${order.customerName}, this is Priscy Luxury Slippers verifying your MoMo payment for order ${order.orderNumber} (Txn: ${order.manualTxnId ?? '-'}).',
                      ),
                    );
                  },
                  icon: const Icon(Icons.chat_rounded, size: 18),
                  label: const Text('Ask Customer on WhatsApp'),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
