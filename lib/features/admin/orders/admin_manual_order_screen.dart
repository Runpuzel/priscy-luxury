import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/validators.dart';
import '../../../core/utils/whatsapp_helper.dart';
import '../../../core/widgets/admin_scaffold.dart';
import '../../../data/models/models.dart';
import '../../../data/providers.dart';

/// Section 6.2 & Section 10:
/// Build a manual order from a WhatsApp conversation, reserve stock,
/// and generate a Paystack Mobile Money link + 1-tap WhatsApp message.
class AdminManualOrderScreen extends ConsumerStatefulWidget {
  const AdminManualOrderScreen({super.key});

  @override
  ConsumerState<AdminManualOrderScreen> createState() =>
      _AdminManualOrderScreenState();
}

class _AdminManualOrderScreenState
    extends ConsumerState<AdminManualOrderScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  DeliveryMethod _deliveryMethod = DeliveryMethod.delivery;
  String? _selectedZoneId;
  String? _selectedProductId;
  String? _selectedVariantId;
  int _qty = 1;
  bool _markPaidImmediately = false;
  bool _saving = false;

  final List<_DraftManualLine> _lines = [];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _cityCtrl.dispose();
    _addressCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _createManualOrder(List<DeliveryZone> zones) async {
    if (!_formKey.currentState!.validate()) return;
    if (_lines.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least one footwear pair first.')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final zone = zones.where((z) => z.id == _selectedZoneId).firstOrNull;
      final res = await ref.read(orderRepositoryProvider).createManualOrder(
            CheckoutRequest(
              items: [
                for (final l in _lines)
                  {'variant_id': l.variant.id, 'quantity': l.qty},
              ],
              customerName: _nameCtrl.text.trim(),
              customerPhone: _phoneCtrl.text.trim(),
              customerWhatsapp: _phoneCtrl.text.trim(),
              deliveryMethod: _deliveryMethod,
              deliveryZoneId: _deliveryMethod == DeliveryMethod.delivery
                  ? zone?.id
                  : null,
              region: zone?.region,
              city: _cityCtrl.text.trim(),
              address: _addressCtrl.text.trim(),
              notes: _notesCtrl.text.trim(),
            ),
            markPaidImmediately: _markPaidImmediately,
          );
      ref.read(dataRefreshTriggerProvider.notifier).state++;
      if (!mounted) return;

      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text('Manual Order ${res.orderNumber} Created'),
          content: Text(
            'Total: ${CurrencyFormatter.formatGhs(res.total)}\n\nSend the Mobile Money payment link directly to ${_nameCtrl.text} on WhatsApp now.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                context.go('/orders/${res.orderId}');
              },
              child: const Text('View Order'),
            ),
            if (res.whatsappUrl != null)
              ElevatedButton.icon(
                onPressed: () {
                  WhatsAppHelper.openUrl(res.whatsappUrl!);
                  Navigator.of(ctx).pop();
                  context.go('/orders/${res.orderId}');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.whatsappGreen,
                ),
                icon: const Icon(Icons.chat_rounded, size: 18),
                label: const Text('Send Payment Link via WhatsApp'),
              ),
          ],
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

  @override
  Widget build(BuildContext context) {
    final products = ref.watch(adminProductsProvider).valueOrNull ?? const [];
    final zones = ref.watch(deliveryZonesProvider).valueOrNull ?? const [];

    if (_selectedZoneId == null && zones.isNotEmpty) {
      _selectedZoneId = zones.first.id;
    }
    final activeProduct =
        products.where((p) => p.id == _selectedProductId).firstOrNull;
    final inStockVariants =
        activeProduct?.variants.where((v) => v.isInStock).toList() ?? const [];

    final subtotal = _lines.fold<double>(
      0,
      (s, l) => s + l.variant.effectivePrice(l.product.basePrice) * l.qty,
    );
    final zoneFee = _deliveryMethod == DeliveryMethod.pickup
        ? 0.0
        : (zones.where((z) => z.id == _selectedZoneId).firstOrNull?.fee ?? 0.0);

    return AdminScaffold(
      title: 'Create Manual WhatsApp Order',
      currentPath: '/orders/manual-new',
      body: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
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
                    '1. Add Products from WhatsApp Chat',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      SizedBox(
                        width: 300,
                        child: DropdownButtonFormField<String>(
                          value: _selectedProductId,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Select Product',
                          ),
                          items: [
                            for (final p in products.where((e) => e.isActive))
                              DropdownMenuItem(value: p.id, child: Text(p.name)),
                          ],
                          onChanged: (v) => setState(() {
                            _selectedProductId = v;
                            _selectedVariantId = null;
                          }),
                        ),
                      ),
                      SizedBox(
                        width: 240,
                        child: DropdownButtonFormField<String>(
                          value: _selectedVariantId,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Size & Colour (In Stock)',
                          ),
                          items: [
                            for (final v in inStockVariants)
                              DropdownMenuItem(
                                value: v.id,
                                child: Text(
                                  'EU ${v.size} • ${v.colour} (${v.availableQty} left)',
                                ),
                              ),
                          ],
                          onChanged: (v) =>
                              setState(() => _selectedVariantId = v),
                        ),
                      ),
                      SizedBox(
                        width: 90,
                        child: DropdownButtonFormField<int>(
                          value: _qty,
                          decoration: const InputDecoration(labelText: 'Qty'),
                          items: [
                            for (var q = 1; q <= 5; q++)
                              DropdownMenuItem(value: q, child: Text('$q')),
                          ],
                          onChanged: (v) {
                            if (v != null) setState(() => _qty = v);
                          },
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed:
                            (activeProduct != null && _selectedVariantId != null)
                                ? () {
                                    final variant = inStockVariants.firstWhere(
                                      (v) => v.id == _selectedVariantId,
                                    );
                                    setState(() {
                                      _lines.add(
                                        _DraftManualLine(
                                          product: activeProduct,
                                          variant: variant,
                                          qty: _qty,
                                        ),
                                      );
                                    });
                                  }
                                : null,
                        icon: const Icon(Icons.add_rounded, size: 18),
                        label: const Text('Add Line'),
                      ),
                    ],
                  ),
                  if (_lines.isNotEmpty) ...[
                    const Divider(height: 24),
                    for (var i = 0; i < _lines.length; i++)
                      ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          '${_lines[i].product.name} — EU ${_lines[i].variant.size}, ${_lines[i].variant.colour} × ${_lines[i].qty}',
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              CurrencyFormatter.formatGhs(
                                _lines[i].variant.effectivePrice(
                                          _lines[i].product.basePrice,
                                        ) *
                                    _lines[i].qty,
                              ),
                              style: const TextStyle(fontWeight: FontWeight.w700),
                            ),
                            IconButton(
                              onPressed: () =>
                                  setState(() => _lines.removeAt(i)),
                              icon: const Icon(
                                Icons.delete_outline,
                                color: AppColors.danger,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '2. Customer & Delivery Details',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 14,
                    runSpacing: 14,
                    children: [
                      SizedBox(
                        width: 280,
                        child: TextFormField(
                          controller: _nameCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Customer Name *',
                          ),
                          validator: (v) =>
                              Validators.requiredField(v, 'Customer name'),
                        ),
                      ),
                      SizedBox(
                        width: 280,
                        child: TextFormField(
                          controller: _phoneCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Customer WhatsApp / MoMo Number *',
                          ),
                          validator: Validators.ghanaPhone,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  SegmentedButton<DeliveryMethod>(
                    segments: const [
                      ButtonSegment(
                        value: DeliveryMethod.delivery,
                        label: Text('Delivery'),
                      ),
                      ButtonSegment(
                        value: DeliveryMethod.pickup,
                        label: Text('Kumasi Pickup (Free)'),
                      ),
                    ],
                    selected: {_deliveryMethod},
                    onSelectionChanged: (s) =>
                        setState(() => _deliveryMethod = s.first),
                  ),
                  if (_deliveryMethod == DeliveryMethod.delivery) ...[
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      value: _selectedZoneId,
                      decoration:
                          const InputDecoration(labelText: 'Delivery Zone'),
                      items: [
                        for (final z in zones)
                          DropdownMenuItem(
                            value: z.id,
                            child: Text(
                              '${z.displayName} (${CurrencyFormatter.formatGhs(z.fee)})',
                            ),
                          ),
                      ],
                      onChanged: (v) => setState(() => _selectedZoneId = v),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 14,
                      runSpacing: 14,
                      children: [
                        SizedBox(
                          width: 260,
                          child: TextFormField(
                            controller: _cityCtrl,
                            decoration:
                                const InputDecoration(labelText: 'City / Area'),
                          ),
                        ),
                        SizedBox(
                          width: 340,
                          child: TextFormField(
                            controller: _addressCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Address / Landmark',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 12),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: _markPaidImmediately,
                    title: const Text(
                      'Mobile Money already received directly (Confirm & deduct stock immediately)',
                      style: TextStyle(fontSize: 13.5),
                    ),
                    subtitle: const Text(
                      'Leave off to reserve stock for 15 minutes and send a Paystack payment link.',
                      style: TextStyle(fontSize: 12),
                    ),
                    onChanged: (v) =>
                        setState(() => _markPaidImmediately = v),
                  ),
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total: ${CurrencyFormatter.formatGhs(subtotal + zoneFee)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                          color: AppColors.espresso,
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed:
                            _saving ? null : () => _createManualOrder(zones),
                        icon: const Icon(Icons.check_circle_outline, size: 18),
                        label: Text(
                          _saving
                              ? 'Creating...'
                              : 'Create Order & Generate WhatsApp Link',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DraftManualLine {
  const _DraftManualLine({
    required this.product,
    required this.variant,
    required this.qty,
  });

  final Product product;
  final ProductVariant variant;
  final int qty;
}
