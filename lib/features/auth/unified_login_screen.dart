import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/config/app_config.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/store_scaffold.dart';
import '../../data/providers.dart';

/// Unified login for everyone: customers AND the owner admin sign in here.
/// After sign-in the app checks the account role:
/// - admin  -> Admin Dashboard (/admin)
/// - customer -> returnTo (e.g. /checkout) or Account page
///
/// Admin accounts can ONLY be created by the developer (database role).
/// Public registration always creates a `customer` account.
class UnifiedLoginScreen extends ConsumerStatefulWidget {
  const UnifiedLoginScreen({super.key, this.returnTo});

  final String? returnTo;

  @override
  ConsumerState<UnifiedLoginScreen> createState() => _UnifiedLoginScreenState();
}

class _UnifiedLoginScreenState extends ConsumerState<UnifiedLoginScreen> {
  int _authMode = 0; // 0 = Sign In, 1 = Create Account, 2 = Phone OTP
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _otpCtrl = TextEditingController();
  bool _otpSent = false;
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _otpCtrl.dispose();
    super.dispose();
  }

  void _routeAfterLogin() {
    final profile = ref.read(customerAuthProvider).valueOrNull;
    if (!mounted) return;
    if (profile != null && profile.isAdmin) {
      context.go('/admin');
    } else if (widget.returnTo != null && widget.returnTo!.isNotEmpty) {
      context.go(widget.returnTo!);
    } else {
      context.go('/account');
    }
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;
    await ref
        .read(customerAuthProvider.notifier)
        .signIn(_emailCtrl.text.trim(), _passCtrl.text);
    if (!mounted) return;
    final state = ref.read(customerAuthProvider);
    if (state.hasError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.danger,
          content: Text(state.error.toString().replaceFirst('Bad state: ', '').replaceFirst('Exception: ', '')),
        ),
      );
    } else if (state.valueOrNull != null) {
      _routeAfterLogin();
    }
  }

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;
    await ref.read(customerAuthProvider.notifier).signUp(
          fullName: _nameCtrl.text.trim(),
          phone: _phoneCtrl.text.trim(),
          email: _emailCtrl.text.trim(),
          password: _passCtrl.text,
        );
    if (!mounted) return;
    final state = ref.read(customerAuthProvider);
    if (state.hasError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.danger,
          content: Text(state.error.toString().replaceFirst('Bad state: ', '').replaceFirst('Exception: ', '')),
        ),
      );
    } else if (state.valueOrNull != null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Account created! You can now shop and checkout.')),
      );
      _routeAfterLogin();
    }
  }

  @override
  Widget build(BuildContext context) {
    final loading = ref.watch(customerAuthProvider).isLoading;

    return StoreScaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 36, 16, 36),
            child: Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.border),
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: AppColors.espresso,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          alignment: Alignment.center,
                          child: const Text(
                            'PL',
                            style: TextStyle(
                              color: AppColors.gold,
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Welcome to ${AppConfig.brandName}',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              const Text(
                                'Sign in to shop, track orders & checkout',
                                style: TextStyle(fontSize: 12.5, color: AppColors.mutedText),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    SegmentedButton<int>(
                      segments: const [
                        ButtonSegment(value: 0, label: Text('Sign In')),
                        ButtonSegment(value: 1, label: Text('Create Account')),
                        ButtonSegment(value: 2, label: Text('Phone OTP')),
                      ],
                      selected: {_authMode},
                      onSelectionChanged: (s) => setState(() => _authMode = s.first),
                    ),
                    const SizedBox(height: 18),
                    if (_authMode == 0) ...[
                      TextFormField(
                        controller: _emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'Email Address *',
                          prefixIcon: Icon(Icons.email_outlined),
                        ),
                        validator: Validators.requiredEmail,
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _passCtrl,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'Password *',
                          prefixIcon: Icon(Icons.lock_outline_rounded),
                        ),
                        validator: Validators.requiredField,
                      ),
                      const SizedBox(height: 18),
                      ElevatedButton.icon(
                        onPressed: loading ? null : _signIn,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.espresso,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                        ),
                        icon: loading
                            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.login_rounded, size: 18),
                        label: const Text('Sign In'),
                      ),
                    ],
                    if (_authMode == 1) ...[
                      TextFormField(
                        controller: _nameCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Full Name *',
                          hintText: 'e.g. Akosua Mensah',
                        ),
                        validator: (v) => Validators.requiredField(v, 'Full name'),
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _phoneCtrl,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: 'Phone / MoMo Number *',
                          hintText: '0550571248',
                        ),
                        validator: (v) => Validators.ghanaPhone(v, 'Phone number'),
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'Email Address *',
                        ),
                        validator: Validators.requiredEmail,
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _passCtrl,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'Password * (min 8 characters)',
                        ),
                        validator: Validators.password,
                      ),
                      const SizedBox(height: 18),
                      ElevatedButton.icon(
                        onPressed: loading ? null : _signUp,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.espresso,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                        ),
                        icon: loading
                            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.person_add_outlined, size: 18),
                        label: const Text('Create Free Account'),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Admin accounts are created by the developer only and cannot be registered here.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 11.5, color: AppColors.mutedText),
                      ),
                    ],
                    if (_authMode == 2) ...[
                      TextFormField(
                        controller: _phoneCtrl,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: 'Ghana Phone Number *',
                          hintText: '0550571248',
                          prefixIcon: Icon(Icons.phone_outlined),
                        ),
                        validator: (v) => Validators.ghanaPhone(v, 'Phone number'),
                      ),
                      if (_otpSent) ...[
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _otpCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: '6-Digit SMS OTP Code',
                          ),
                        ),
                        const SizedBox(height: 18),
                        ElevatedButton.icon(
                          onPressed: loading
                              ? null
                              : () async {
                                  await ref.read(customerAuthProvider.notifier).verifyPhoneOtp(
                                        _phoneCtrl.text.trim(),
                                        _otpCtrl.text.trim(),
                                      );
                                  if (!mounted) return;
                                  final state = ref.read(customerAuthProvider);
                                  if (state.hasError) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(backgroundColor: AppColors.danger, content: Text(state.error.toString())),
                                    );
                                  } else {
                                    _routeAfterLogin();
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.espresso,
                            padding: const EdgeInsets.symmetric(vertical: 15),
                          ),
                          icon: const Icon(Icons.verified_outlined, size: 18),
                          label: const Text('Verify OTP & Sign In'),
                        ),
                      ] else ...[
                        const SizedBox(height: 18),
                        ElevatedButton.icon(
                          onPressed: loading
                              ? null
                              : () async {
                                  if (Validators.ghanaPhone(_phoneCtrl.text) != null) return;
                                  await ref.read(customerAuthProvider.notifier).requestPhoneOtp(_phoneCtrl.text.trim());
                                  if (!mounted) return;
                                  setState(() => _otpSent = true);
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.espresso,
                            padding: const EdgeInsets.symmetric(vertical: 15),
                          ),
                          icon: const Icon(Icons.sms_outlined, size: 18),
                          label: const Text('Send SMS OTP'),
                        ),
                      ],
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
