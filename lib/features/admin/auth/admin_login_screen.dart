import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/app_config.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/providers.dart';

class AdminLoginScreen extends ConsumerStatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  ConsumerState<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends ConsumerState<AdminLoginScreen> {
  late final TextEditingController _emailCtrl;
  late final TextEditingController _passwordCtrl;
  String? _error;

  @override
  void initState() {
    super.initState();
    _emailCtrl = TextEditingController(
      text: AppConfig.isDemoMode ? AppConfig.supportEmail : '',
    );
    _passwordCtrl = TextEditingController(
      text: AppConfig.isDemoMode ? 'admin1234' : '',
    );
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    setState(() => _error = null);
    await ref
        .read(adminAuthProvider.notifier)
        .signIn(_emailCtrl.text.trim(), _passwordCtrl.text);
    if (!mounted) return;
    final state = ref.read(adminAuthProvider);
    if (state.hasError) {
      setState(
        () => _error = state.error.toString().replaceFirst('Bad state: ', ''),
      );
    } else if (state.valueOrNull != null) {
      context.go('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    final loading = ref.watch(adminAuthProvider).isLoading;

    return Scaffold(
      backgroundColor: AppColors.espressoDark,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.espresso,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        alignment: Alignment.center,
                        child: const Text(
                          'PL',
                          style: TextStyle(
                            color: AppColors.gold,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Owner Admin Portal',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const Text(
                              AppConfig.brandName,
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.mutedText,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  if (AppConfig.isDemoMode)
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: AppColors.sand,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        'Demo Mode Active: Pre-filled with owner credentials so you can explore orders, stock, reviews, and reports right away.',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  if (_error != null)
                    Container(
                      padding: const EdgeInsets.all(10),
                      margin: const EdgeInsets.only(bottom: 14),
                      decoration: BoxDecoration(
                        color: AppColors.dangerSoft,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _error!,
                        style: const TextStyle(
                          color: AppColors.danger,
                          fontSize: 12.5,
                        ),
                      ),
                    ),
                  TextField(
                    controller: _emailCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Admin Email',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _passwordCtrl,
                    obscureText: true,
                    onSubmitted: (_) => _signIn(),
                    decoration: const InputDecoration(
                      labelText: 'Password',
                      prefixIcon: Icon(Icons.lock_outline_rounded),
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: loading ? null : _signIn,
                    child: Text(loading ? 'Signing In...' : 'Sign In to Admin'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
