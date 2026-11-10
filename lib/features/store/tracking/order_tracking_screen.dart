import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_config.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../core/widgets/store_scaffold.dart';
import '../../../data/models/models.dart';
import '../../../data/providers.dart';

class OrderTrackingScreen extends ConsumerStatefulWidget {
  const OrderTrackingScreen({
    super.key,
    this.initialOrderNumber,
    this.initialToken,
  });

  final String? initialOrderNumber;
  final String? initialToken;

  @override
  ConsumerState<OrderTrackingScreen> createState() =>
      _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends ConsumerState<OrderTrackingScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _orderCtrl;
  final _phoneCtrl = TextEditingController();
  Order? _trackedOrder;
  String? _errorMsg;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _orderCtrl = TextEditingController(text: widget.initialOrderNumber ?? '');
    if (widget.initialToken != null && widget.initialToken!.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _lookupByToken());
    }
  }

  @override
  void dispose() {
    _orderCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _lookupByToken() async {
    setState(() {
      _loading = true;
      _errorMsg = null;
    });
    final res = await ref.read(orderRepositoryProvider).trackOrder(
          orderNumber: widget.initialOrderNumber,
          trackingToken: widget.initialToken,
        );
    if (!mounted) return;
    setState(() {
      _loading = false;
      _trackedOrder = res;
      if (res == null) {
        _errorMsg = 'Could not find order for that tracking link.';
      }
    });
  }

  Future<void> _lookupManual() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _errorMsg = null;
    });
    final res = await ref.read(orderRepositoryProvider).trackOrder(
          orderNumber: _orderCtrl.text.trim(),
          phone: _phoneCtrl.text.trim(),
        );
    if (!mounted) return;
    setState(() {
      _loading = false;
      _trackedOrder = res;
      if (res == null) {
        _errorMsg =
            'No matching order found. Please check your Order Number and Mobile Money phone number.';
      }
    });
  }

  int _stepIndexForStatus(OrderStatus status) {
    return switch (status) {
      OrderStatus.pendingPayment => 0,
      OrderStatus.confirmed => 1,
      OrderStatus.processing => 1,
      OrderStatus.dispatched => 2,
      OrderStatus.delivered => 3,
      OrderStatus.cancelled => -1,
    };
  }

  @override
  Widget build(BuildContext context) {
    return StoreScaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 820),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 32, 16, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Track Your Order',
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
                const SizedBox(height: 6),
                Text(
                  AppConfig.isDemoMode
                      ? 'Enter your order number & phone (Demo example: PSY-20261030-0001 + 0244123456 or PSY-20261029-0002 + 0558234567).'
                      : 'Enter your order number and Mobile Money phone number to see live status.',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.mutedText,
                  ),
                ),
                const SizedBox(height: 22),
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Form(
                    key: _formKey,
                    child: Wrap(
                      spacing: 14,
                      runSpacing: 14,
                      crossAxisAlignment: WrapCrossAlignment.start,
                      children: [
                        SizedBox(
                          width: 280,
                          child: TextFormField(
                            controller: _orderCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Order Number *',
                              hintText: 'PSY-20261101-0001',
                            ),
                            validator: (v) =>
                                Validators.requiredField(v, 'Order number'),
                          ),
                        ),
                        SizedBox(
                          width: 280,
                          child: TextFormField(
                            controller: _phoneCtrl,
                            keyboardType: TextInputType.phone,
                            decoration: const InputDecoration(
                              labelText: 'Order Phone Number *',
                              hintText: '0244123456',
                            ),
                            validator: Validators.ghanaPhone,
                          ),
                        ),
                        SizedBox(
                          height: 48,
                          child: ElevatedButton.icon(
                            onPressed: _loading ? null : _lookupManual,
                            icon: const Icon(Icons.search_rounded, size: 18),
                            label: Text(_loading ? 'Searching...' : 'Track Order'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (_errorMsg != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.dangerSoft,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _errorMsg!,
                      style: const TextStyle(
                        color: AppColors.danger,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
                if (_trackedOrder != null) ...[
                  const SizedBox(height: 24),
                  _TrackedOrderDetailsCard(
                    order: _trackedOrder!,
                    activeStep: _stepIndexForStatus(_trackedOrder!.status),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TrackedOrderDetailsCard extends StatelessWidget {
  const _TrackedOrderDetailsCard({
    required this.order,
    required this.activeStep,
  });

  final Order order;
  final int activeStep;

  static const _milestones = ['Received', 'Paid', 'Dispatched', 'Delivered'];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            runSpacing: 8,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    order.orderNumber,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  Text(
                    'Placed on ${CurrencyFormatter.formatDateTime(order.createdAt)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
              Wrap(
                spacing: 8,
                children: [
                  OrderStatusBadge(status: order.status),
                  PaymentStatusBadge(status: order.paymentStatus),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          // 4-step milestone tracker (Section 6.1: Received, Paid, Dispatched, Delivered)
          if (order.status != OrderStatus.cancelled)
            Row(
              children: [
                for (var i = 0; i < _milestones.length; i++)
                  Expanded(
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: i <= activeStep
                              ? AppColors.espresso
                              : AppColors.sand,
                          child: Icon(
                            i <= activeStep
                                ? Icons.check_rounded
                                : Icons.circle_outlined,
                            size: 16,
                            color:
                                i <= activeStep ? AppColors.gold : AppColors.mutedText,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _milestones[i],
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: i <= activeStep
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: i <= activeStep
                                ? AppColors.espresso
                                : AppColors.mutedText,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          const Divider(height: 32),
          Text('Items', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          for (final item in order.items)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
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
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total (${order.deliveryMethod.label})',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              Text(
                CurrencyFormatter.formatGhs(order.total),
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  color: AppColors.espresso,
                ),
              ),
            ],
          ),
          if (order.events.isNotEmpty) ...[
            const Divider(height: 28),
            Text(
              'Status Timeline',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 10),
            for (final ev in order.events.reversed)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 5, right: 10),
                      child: Icon(
                        Icons.fiber_manual_record,
                        size: 9,
                        color: AppColors.gold,
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${ev.status.customerLabel} • ${CurrencyFormatter.formatDateTime(ev.createdAt)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                          if (ev.note != null && ev.note!.isNotEmpty)
                            Text(
                              ev.note!,
                              style: const TextStyle(
                                fontSize: 12.5,
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
        ],
      ),
    );
  }
}
