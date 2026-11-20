import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/widgets/admin_scaffold.dart';
import '../../../data/models/models.dart';
import '../../../data/providers.dart';

class AdminDeliveryZonesScreen extends ConsumerWidget {
  const AdminDeliveryZonesScreen({super.key});

  void _openZoneEditor(
    BuildContext context,
    WidgetRef ref, [
    DeliveryZone? existing,
  ]) {
    final regionCtrl = TextEditingController(text: existing?.region ?? '');
    final cityCtrl = TextEditingController(text: existing?.city ?? '');
    final feeCtrl = TextEditingController(
      text: existing != null ? existing.fee.toStringAsFixed(2) : '35.00',
    );
    final minCtrl =
        TextEditingController(text: '${existing?.estDaysMin ?? 3}');
    final maxCtrl =
        TextEditingController(text: '${existing?.estDaysMax ?? 5}');
    var isActive = existing?.isActive ?? true;

    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(
            existing == null ? 'Add Delivery Zone' : 'Edit Delivery Zone',
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: regionCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Region (e.g. Greater Accra)',
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: cityCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Cities / Notes (e.g. Accra & Tema)',
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: feeCtrl,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Delivery Fee (GHS)',
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: minCtrl,
                        keyboardType: TextInputType.number,
                        decoration:
                            const InputDecoration(labelText: 'Min Days'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: maxCtrl,
                        keyboardType: TextInputType.number,
                        decoration:
                            const InputDecoration(labelText: 'Max Days'),
                      ),
                    ),
                  ],
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: isActive,
                  title: const Text('Active at Checkout'),
                  onChanged: (v) => setDialogState(() => isActive = v),
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
                if (regionCtrl.text.trim().isEmpty) return;
                await ref.read(contentRepositoryProvider).saveDeliveryZone(
                      DeliveryZone(
                        id: existing?.id ?? '',
                        region: regionCtrl.text.trim(),
                        city: cityCtrl.text.trim(),
                        fee: double.tryParse(feeCtrl.text.trim()) ?? 0,
                        estDaysMin: int.tryParse(minCtrl.text.trim()) ?? 3,
                        estDaysMax: int.tryParse(maxCtrl.text.trim()) ?? 5,
                        isActive: isActive,
                      ),
                    );
                ref.read(dataRefreshTriggerProvider.notifier).state++;
                if (ctx.mounted) Navigator.of(ctx).pop();
              },
              child: const Text('Save Zone'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final zonesAsync = ref.watch(adminDeliveryZonesProvider);

    return AdminScaffold(
      title: 'Ghana Delivery Zones & Fees',
      currentPath: '/delivery',
      actions: [
        ElevatedButton.icon(
          onPressed: () => _openZoneEditor(context, ref),
          icon: const Icon(Icons.add_rounded, size: 18),
          label: const Text('Add Zone'),
        ),
      ],
      body: zonesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Text('Error: $e'),
        data: (zones) => Column(
          children: [
            for (final z in zones)
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
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            z.displayName,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                          Text(
                            'Estimated delivery: ${z.estimatedWindow} • ${z.isActive ? 'Active' : 'Inactive'}',
                            style: const TextStyle(
                              fontSize: 12.5,
                              color: AppColors.mutedText,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      CurrencyFormatter.formatGhs(z.fee),
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        color: AppColors.espresso,
                      ),
                    ),
                    const SizedBox(width: 14),
                    OutlinedButton(
                      onPressed: () => _openZoneEditor(context, ref, z),
                      child: const Text('Edit'),
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
