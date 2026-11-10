import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../core/widgets/store_scaffold.dart';
import '../../../data/models/models.dart';
import '../../../data/providers.dart';

class AccountScreen extends ConsumerStatefulWidget {
  const AccountScreen({super.key});

  @override
  ConsumerState<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends ConsumerState<AccountScreen> {
  int _authMode = 0; // 0 = Sign In, 1 = Create Account, 2 = Phone OTP
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _otpCtrl = TextEditingController();
  bool _otpSent = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _otpCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(customerAuthProvider);

    return StoreScaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 32, 16, 32),
            child: authState.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(64),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (err, _) => Column(
                children: [
                  Text('Authentication error: $err'),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () => ref.invalidate(customerAuthProvider),
                    child: const Text('Try Again'),
                  ),
                ],
              ),
              data: (customer) {
                if (customer == null) {
                  return _buildGuestAuthCard(context);
                }
                return _SignedInAccountView(customer: customer);
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGuestAuthCard(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Container(
          padding: const EdgeInsets.all(26),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Customer Account',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 6),
              const Text(
                'Track orders, save Ghana delivery addresses, and sync your cart across devices. (Guest checkout is always available too!)',
                style: TextStyle(fontSize: 13, color: AppColors.mutedText),
              ),
              const SizedBox(height: 18),
              SegmentedButton<int>(
                segments: const [
                  ButtonSegment(value: 0, label: Text('Sign In')),
                  ButtonSegment(value: 1, label: Text('Create Account')),
                  ButtonSegment(value: 2, label: Text('Phone OTP')),
                ],
                selected: {_authMode},
                onSelectionChanged: (s) => setState(() => _authMode = s.first),
              ),
              const SizedBox(height: 20),
              if (_authMode == 0) ...[
                TextField(
                  controller: _emailCtrl,
                  decoration: const InputDecoration(labelText: 'Email Address'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _passCtrl,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Password'),
                ),
                const SizedBox(height: 18),
                ElevatedButton(
                  onPressed: () {
                    if (_emailCtrl.text.trim().isEmpty) return;
                    ref.read(customerAuthProvider.notifier).signIn(
                          _emailCtrl.text.trim(),
                          _passCtrl.text,
                        );
                  },
                  child: const Text('Sign In'),
                ),
              ] else if (_authMode == 1) ...[
                TextField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(labelText: 'Full Name'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _phoneCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Mobile Money / Phone Number',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _emailCtrl,
                  decoration: const InputDecoration(labelText: 'Email Address'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _passCtrl,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Create Password (min 6 chars)',
                  ),
                ),
                const SizedBox(height: 18),
                ElevatedButton(
                  onPressed: () {
                    if (_nameCtrl.text.trim().isEmpty ||
                        _emailCtrl.text.trim().isEmpty) {
                      return;
                    }
                    ref.read(customerAuthProvider.notifier).signUp(
                          fullName: _nameCtrl.text,
                          phone: _phoneCtrl.text,
                          email: _emailCtrl.text,
                          password: _passCtrl.text,
                        );
                  },
                  child: const Text('Create My Account'),
                ),
              ] else ...[
                TextField(
                  controller: _phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Ghana Phone Number (e.g. 0550571248)',
                  ),
                ),
                const SizedBox(height: 12),
                if (_otpSent) ...[
                  TextField(
                    controller: _otpCtrl,
                    decoration: const InputDecoration(
                      labelText: '6-Digit SMS OTP Code',
                    ),
                  ),
                  const SizedBox(height: 14),
                  ElevatedButton(
                    onPressed: () async {
                      await ref.read(authRepositoryProvider).verifyPhoneOtp(
                            ghanaPhone: _phoneCtrl.text.trim(),
                            otpCode: _otpCtrl.text.trim(),
                          );
                      ref.invalidate(customerAuthProvider);
                    },
                    child: const Text('Verify OTP & Sign In'),
                  ),
                ] else
                  ElevatedButton(
                    onPressed: () async {
                      if (Validators.ghanaPhone(_phoneCtrl.text) != null) return;
                      await ref
                          .read(authRepositoryProvider)
                          .requestPhoneOtp(_phoneCtrl.text.trim());
                      setState(() => _otpSent = true);
                    },
                    child: const Text('Send SMS OTP'),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SignedInAccountView extends ConsumerStatefulWidget {
  const _SignedInAccountView({required this.customer});
  final UserProfile customer;

  @override
  ConsumerState<_SignedInAccountView> createState() =>
      _SignedInAccountViewState();
}

class _SignedInAccountViewState extends ConsumerState<_SignedInAccountView> {
  void _showAddAddressDialog() {
    final labelCtrl = TextEditingController(text: 'Home');
    final regionCtrl = TextEditingController(text: 'Ashanti Region');
    final cityCtrl = TextEditingController();
    final addrCtrl = TextEditingController();
    final landmarkCtrl = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Save Delivery Address'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: labelCtrl,
                decoration: const InputDecoration(labelText: 'Label (Home/Work)'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: regionCtrl,
                decoration: const InputDecoration(labelText: 'Region'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: cityCtrl,
                decoration: const InputDecoration(labelText: 'City / Suburb'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: addrCtrl,
                decoration: const InputDecoration(labelText: 'Street / GPS'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: landmarkCtrl,
                decoration: const InputDecoration(labelText: 'Landmark'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await ref.read(authRepositoryProvider).addSavedAddress(
                    SavedAddress(
                      id: '',
                      userId: widget.customer.id,
                      label: labelCtrl.text.trim(),
                      recipientName: widget.customer.fullName,
                      phone: widget.customer.phone,
                      region: regionCtrl.text.trim(),
                      city: cityCtrl.text.trim(),
                      address: addrCtrl.text.trim(),
                      landmark: landmarkCtrl.text.trim(),
                    ),
                  );
              if (ctx.mounted) Navigator.of(ctx).pop();
              setState(() {});
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ordersFuture = ref
        .watch(orderRepositoryProvider)
        .fetchCustomerOrders(widget.customer.id);
    final addressesFuture = ref
        .watch(authRepositoryProvider)
        .fetchSavedAddresses(widget.customer.id);
    final reviewsFuture = ref
        .watch(reviewRepositoryProvider)
        .fetchUserReviews(widget.customer.id);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            runSpacing: 12,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome, ${widget.customer.fullName}',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  Text(
                    '${widget.customer.email ?? ''} • ${widget.customer.phone}',
                    style: const TextStyle(color: AppColors.mutedText),
                  ),
                ],
              ),
              OutlinedButton.icon(
                onPressed: () =>
                    ref.read(customerAuthProvider.notifier).signOut(),
                icon: const Icon(Icons.logout_rounded, size: 18),
                label: const Text('Sign Out'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Text('Order History', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 12),
        FutureBuilder<List<Order>>(
          future: ordersFuture,
          builder: (context, snap) {
            final orders = snap.data ?? const [];
            if (orders.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: const Text('No orders linked to this account yet.'),
              );
            }
            return Column(
              children: [
                for (final o in orders)
                  Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              o.orderNumber,
                              style: const TextStyle(fontWeight: FontWeight.w700),
                            ),
                            Text(
                              '${CurrencyFormatter.formatDate(o.createdAt)} • ${CurrencyFormatter.formatGhs(o.total)}',
                              style: const TextStyle(
                                fontSize: 12.5,
                                color: AppColors.mutedText,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            OrderStatusBadge(status: o.status),
                            const SizedBox(width: 10),
                            TextButton(
                              onPressed: () => context.go(
                                '/track?order=${Uri.encodeComponent(o.orderNumber)}&token=${Uri.encodeComponent(o.trackingToken)}',
                              ),
                              child: const Text('Track'),
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
        const SizedBox(height: 28),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Saved Delivery Addresses',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            TextButton.icon(
              onPressed: _showAddAddressDialog,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add Address'),
            ),
          ],
        ),
        const SizedBox(height: 10),
        FutureBuilder<List<SavedAddress>>(
          future: addressesFuture,
          builder: (context, snap) {
            final addresses = snap.data ?? const [];
            if (addresses.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: const Text('No saved addresses yet.'),
              );
            }
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (final a in addresses)
                  Container(
                    width: 300,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              a.label,
                              style: const TextStyle(fontWeight: FontWeight.w700),
                            ),
                            IconButton(
                              onPressed: () async {
                                await ref
                                    .read(authRepositoryProvider)
                                    .deleteSavedAddress(a.id);
                                setState(() {});
                              },
                              icon: const Icon(
                                Icons.delete_outline,
                                size: 18,
                                color: AppColors.danger,
                              ),
                            ),
                          ],
                        ),
                        Text('${a.city}, ${a.region}'),
                        Text(
                          a.address,
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: AppColors.mutedText,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            );
          },
        ),
        const SizedBox(height: 28),
        Text(
          'My Submitted Reviews',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 10),
        FutureBuilder<List<Review>>(
          future: reviewsFuture,
          builder: (context, snap) {
            final reviews = snap.data ?? const [];
            if (reviews.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: const Text('You have not submitted any reviews yet.'),
              );
            }
            return Column(
              children: [
                for (final r in reviews)
                  ListTile(
                    tileColor: AppColors.surface,
                    title: Text('${r.productName ?? 'Footwear'} (${r.rating}/5)'),
                    subtitle: Text(r.comment),
                    trailing: Text(
                      r.isApproved ? 'Published' : 'Pending Approval',
                      style: TextStyle(
                        color: r.isApproved ? AppColors.success : AppColors.warning,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}
