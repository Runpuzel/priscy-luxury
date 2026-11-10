import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/stock_calculator.dart';
import '../../../core/utils/validators.dart';
import '../../../core/utils/whatsapp_helper.dart';
import '../../../core/widgets/store_scaffold.dart';
import '../../../data/models/models.dart';
import '../../../data/providers.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _whatsappCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _landmarkCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  DeliveryMethod _deliveryMethod = DeliveryMethod.delivery;
  String? _selectedZoneId;
  bool _whatsappSameAsPhone = true;
  bool _acceptedPolicies = true;
  bool _submitting = false;
  bool _prefilledFromCustomer = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _whatsappCtrl.dispose();
    _emailCtrl.dispose();
    _cityCtrl.dispose();
    _addressCtrl.dispose();
    _landmarkCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  void _prefillIfSignedIn(UserProfile? customer) {
    if (_prefilledFromCustomer || customer == null) return;
    _prefilledFromCustomer = true;
    if (_nameCtrl.text.isEmpty) _nameCtrl.text = customer.fullName;
    if (_phoneCtrl.text.isEmpty) _phoneCtrl.text = customer.phone;
    if (_emailCtrl.text.isEmpty && customer.email != null) {
      _emailCtrl.text = customer.email!;
    }
  }

  Future<void> _submitOrder(
    List<CartItem> cartItems,
    List<DeliveryZone> zones,
  ) async {
    if (!_formKey.currentState!.validate()) return;
    if (!_acceptedPolicies) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please acknowledge the Privacy & Exchange-Only Policy before paying.',
          ),
        ),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      final customer = ref.read(customerAuthProvider).valueOrNull;
      DeliveryZone? chosenZone;
      for (final z in zones) {
        if (z.id == _selectedZoneId) {
          chosenZone = z;
          break;
        }
      }
      chosenZone ??= zones.isNotEmpty ? zones.first : null;

      final request = CheckoutRequest(
        items: [
          for (final item in cartItems)
            {
              'variant_id': item.variantId,
              'quantity': item.quantity,
            },
        ],
        customerName: _nameCtrl.text.trim(),
        customerPhone: _phoneCtrl.text.trim(),
        customerWhatsapp: _whatsappSameAsPhone
            ? _phoneCtrl.text.trim()
            : _whatsappCtrl.text.trim(),
        customerEmail: _emailCtrl.text.trim().isEmpty
            ? null
            : _emailCtrl.text.trim(),
        deliveryMethod: _deliveryMethod,
        deliveryZoneId:
            _deliveryMethod == DeliveryMethod.delivery ? chosenZone?.id : null,
        region: _deliveryMethod == DeliveryMethod.delivery
            ? chosenZone?.region
            : 'Ashanti Region',
        city: _deliveryMethod == DeliveryMethod.delivery
            ? _cityCtrl.text.trim()
            : 'Kumasi Showroom Pickup',
        address: _deliveryMethod == DeliveryMethod.delivery
            ? _addressCtrl.text.trim()
            : 'Showroom Pickup',
        landmark: _landmarkCtrl.text.trim(),
        notes: _notesCtrl.text.trim(),
      );

      final result = await ref
          .read(orderRepositoryProvider)
          .createOrder(request, userId: customer?.id);

      ref.read(dataRefreshTriggerProvider.notifier).state++;
      if (!mounted) return;

      if (result.isDemoCheckout) {
        context.go(result.authorizationUrl);
      } else {
        // Redirect browser to Paystack Hosted Checkout (Section 4 & 10)
        ref.read(cartProvider.notifier).clearCart();
        await WhatsAppHelper.openUrl(result.authorizationUrl, sameTab: true);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.danger,
          content: Text(e.toString().replaceFirst('Bad state: ', '')),
        ),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartItems = ref.watch(cartProvider);
    final zones = ref.watch(deliveryZonesProvider).valueOrNull ?? const [];
    final customer = ref.watch(customerAuthProvider).valueOrNull;
    final settings =
        ref.watch(siteSettingsProvider).valueOrNull ?? const SiteSettings();

    _prefillIfSignedIn(customer);
    if (_selectedZoneId == null && zones.isNotEmpty) {
      _selectedZoneId = zones.first.id;
    }

    DeliveryZone? activeZone;
    for (final z in zones) {
      if (z.id == _selectedZoneId) {
        activeZone = z;
        break;
      }
    }
    activeZone ??= zones.isNotEmpty ? zones.first : null;

    final totals = StockAndPricingCalculator.calculateOrderTotals(
      items: cartItems,
      deliveryMethod: _deliveryMethod,
      selectedZone: activeZone,
    );

    if (cartItems.isEmpty) {
      return StoreScaffold(
        body: Padding(
          padding: const EdgeInsets.all(64),
          child: Center(
            child: Column(
              children: [
                const Text('Your cart is empty.'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => context.go('/catalogue'),
                  child: const Text('Return to Catalogue'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return StoreScaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1140),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 28, 16, 28),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        'Mobile Money Checkout',
                        style: Theme.of(context).textTheme.headlineLarge,
                      ),
                      if (customer == null)
                        TextButton.icon(
                          onPressed: () => context.go('/account'),
                          icon: const Icon(Icons.person_outline_rounded, size: 18),
                          label: const Text(
                            'Have an account? Sign in (or continue as Guest)',
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final wide = constraints.maxWidth >= 860;
                      final formPanel = _buildFormPanel(zones, activeZone, settings);
                      final summaryPanel =
                          _buildSummaryPanel(cartItems, activeZone, totals);

                      if (wide) {
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(flex: 7, child: formPanel),
                            const SizedBox(width: 24),
                            Expanded(flex: 5, child: summaryPanel),
                          ],
                        );
                      }
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          formPanel,
                          const SizedBox(height: 20),
                          summaryPanel,
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFormPanel(
    List<DeliveryZone> zones,
    DeliveryZone? activeZone,
    SiteSettings settings,
  ) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '1. Contact & Mobile Money Details',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _nameCtrl,
            decoration: const InputDecoration(
              labelText: 'Full Name *',
              hintText: 'e.g. Akosua Mensah',
            ),
            validator: (v) => Validators.requiredField(v, 'Full name'),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 14,
            runSpacing: 14,
            children: [
              SizedBox(
                width: 290,
                child: TextFormField(
                  controller: _phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Mobile Money Phone Number *',
                    hintText: '024 / 055 / 020 / 027...',
                  ),
                  validator: (v) =>
                      Validators.ghanaPhone(v, 'Mobile Money number'),
                ),
              ),
              SizedBox(
                width: 290,
                child: TextFormField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email for Receipt (Optional)',
                    hintText: 'you@example.com',
                  ),
                  validator: Validators.optionalEmail,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            value: _whatsappSameAsPhone,
            title: const Text(
              'Send WhatsApp order status updates to the same phone number',
              style: TextStyle(fontSize: 13.5),
            ),
            onChanged: (v) =>
                setState(() => _whatsappSameAsPhone = v ?? true),
          ),
          if (!_whatsappSameAsPhone) ...[
            const SizedBox(height: 8),
            TextFormField(
              controller: _whatsappCtrl,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'WhatsApp Number *',
                hintText: '0550571248',
              ),
              validator: (v) => Validators.ghanaPhone(v, 'WhatsApp number'),
            ),
          ],
          const Divider(height: 32),
          Text(
            '2. Delivery or Kumasi Pickup',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          SegmentedButton<DeliveryMethod>(
            segments: const [
              ButtonSegment(
                value: DeliveryMethod.delivery,
                icon: Icon(Icons.local_shipping_outlined),
                label: Text('Nationwide Delivery (3–5 Days)'),
              ),
              ButtonSegment(
                value: DeliveryMethod.pickup,
                icon: Icon(Icons.storefront_outlined),
                label: Text('Kumasi Pickup (Free)'),
              ),
            ],
            selected: {_deliveryMethod},
            onSelectionChanged: (s) =>
                setState(() => _deliveryMethod = s.first),
          ),
          const SizedBox(height: 16),
          if (_deliveryMethod == DeliveryMethod.pickup)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.sand,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.place_outlined, color: AppColors.espresso),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Pickup Point: ${settings.pickupAddress}\nNo delivery fee. Ready for collection once Mobile Money payment is confirmed.',
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
            )
          else ...[
            DropdownButtonFormField<String>(
              value: _selectedZoneId,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Select Ghana Region / Delivery Zone *',
              ),
              items: [
                for (final z in zones)
                  DropdownMenuItem(
                    value: z.id,
                    child: Text(
                      '${z.displayName} — ${CurrencyFormatter.formatGhs(z.fee)} (${z.estimatedWindow})',
                    ),
                  ),
              ],
              onChanged: (v) => setState(() => _selectedZoneId = v),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 14,
              runSpacing: 14,
              children: [
                SizedBox(
                  width: 260,
                  child: TextFormField(
                    controller: _cityCtrl,
                    decoration: const InputDecoration(
                      labelText: 'City / Suburb *',
                      hintText: 'e.g. Ahodwo, East Legon, Tema Comm. 8',
                    ),
                    validator: (v) =>
                        _deliveryMethod == DeliveryMethod.delivery
                            ? Validators.requiredField(v, 'City / Suburb')
                            : null,
                  ),
                ),
                SizedBox(
                  width: 320,
                  child: TextFormField(
                    controller: _landmarkCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Nearest Landmark',
                      hintText: 'e.g. Opposite Total Filling Station',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _addressCtrl,
              decoration: const InputDecoration(
                labelText: 'House Address / GhanaPost GPS *',
                hintText: 'e.g. AK-039-5028, Cedar Street House 14',
              ),
              validator: (v) => _deliveryMethod == DeliveryMethod.delivery
                  ? Validators.requiredField(v, 'Delivery address')
                  : null,
            ),
          ],
          const SizedBox(height: 14),
          TextFormField(
            controller: _notesCtrl,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Order / Rider Notes (Optional)',
              hintText: 'Preferred delivery time or gift note...',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryPanel(
    List<CartItem> cartItems,
    DeliveryZone? activeZone,
    OrderPricingSummary totals,
  ) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Your Order (${cartItems.fold<int>(0, (s, i) => s + i.quantity)} items)',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 14),
          for (final item in cartItems)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      '${item.productName} (EU ${item.size}, ${item.colour}) × ${item.quantity}',
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    CurrencyFormatter.formatGhs(item.lineTotal),
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Subtotal'),
              Text(CurrencyFormatter.formatGhs(totals.subtotal)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _deliveryMethod == DeliveryMethod.pickup
                    ? 'Kumasi Pickup'
                    : 'Delivery (${activeZone?.region ?? 'Ghana'})',
              ),
              Text(
                totals.deliveryFee == 0
                    ? 'FREE'
                    : CurrencyFormatter.formatGhs(totals.deliveryFee),
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          if (_deliveryMethod == DeliveryMethod.delivery && activeZone != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'Estimated arrival: ${activeZone.estimatedWindow}',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.mutedText,
                ),
              ),
            ),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total to Pay',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
              ),
              Text(
                CurrencyFormatter.formatGhs(totals.total),
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 20,
                  color: AppColors.espresso,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            value: _acceptedPolicies,
            onChanged: (v) => setState(() => _acceptedPolicies = v ?? false),
            title: Wrap(
              children: [
                const Text(
                  'I understand payment is required before delivery, payments are non-refundable (size/colour exchanges allowed), and I agree to the ',
                  style: TextStyle(fontSize: 12),
                ),
                InkWell(
                  onTap: () => context.go('/pages/privacy'),
                  child: const Text(
                    'Privacy Policy',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
                const Text('.', style: TextStyle(fontSize: 12)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: _submitting
                ? null
                : () => _submitOrder(
                      cartItems,
                      ref.read(deliveryZonesProvider).valueOrNull ?? const [],
                    ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.espresso,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            icon: const Icon(Icons.phone_android_rounded, size: 19),
            label: Text(
              _submitting
                  ? 'Reserving Stock & Connecting...'
                  : 'Pay ${CurrencyFormatter.formatGhs(totals.total)} with Mobile Money',
            ),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () {
              final url = WhatsAppHelper.buildCartOrderUrl(
                items: cartItems,
                deliveryMethod: _deliveryMethod,
                zone: activeZone,
                customerName: _nameCtrl.text,
                notes: _notesCtrl.text,
              );
              WhatsAppHelper.openUrl(url);
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.whatsappGreen,
              side: const BorderSide(color: AppColors.whatsappGreen),
            ),
            icon: const Icon(Icons.chat_rounded, size: 18),
            label: const Text('Prefer WhatsApp? Send Order via WhatsApp'),
          ),
        ],
      ),
    );
  }
}
