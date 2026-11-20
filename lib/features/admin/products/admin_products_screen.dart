import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/widgets/admin_scaffold.dart';
import '../../../core/widgets/product_image_view.dart';
import '../../../data/models/models.dart';
import '../../../data/providers.dart';

class AdminProductsScreen extends ConsumerStatefulWidget {
  const AdminProductsScreen({super.key});

  @override
  ConsumerState<AdminProductsScreen> createState() =>
      _AdminProductsScreenState();
}

class _AdminProductsScreenState extends ConsumerState<AdminProductsScreen> {
  final _searchCtrl = TextEditingController();
  bool _showArchived = true;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _showInlinePriceEditor(BuildContext context, Product product) {
    final ctrl =
        TextEditingController(text: product.basePrice.toStringAsFixed(2));
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Edit Price — ${product.name}'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Base Price (GHS)',
            prefixText: 'GHS ',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final nextPrice = double.tryParse(ctrl.text.trim());
              if (nextPrice == null || nextPrice < 0) return;
              await ref
                  .read(productRepositoryProvider)
                  .updateProductBasePrice(product.id, nextPrice);
              ref.read(dataRefreshTriggerProvider.notifier).state++;
              if (ctx.mounted) Navigator.of(ctx).pop();
            },
            child: const Text('Save Price'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(adminProductsProvider);

    return AdminScaffold(
      title: 'Products & Inline Pricing',
      currentPath: '/products',
      actions: [
        ElevatedButton.icon(
          onPressed: () => context.go('/products/new'),
          icon: const Icon(Icons.add_rounded, size: 18),
          label: const Text('Add Product'),
        ),
      ],
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: Wrap(
              spacing: 16,
              runSpacing: 10,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                SizedBox(
                  width: 300,
                  child: TextField(
                    controller: _searchCtrl,
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(
                      hintText: 'Search product name or category...',
                      prefixIcon: Icon(Icons.search_rounded),
                      isDense: true,
                    ),
                  ),
                ),
                FilterChip(
                  label: const Text('Include Archived'),
                  selected: _showArchived,
                  onSelected: (v) => setState(() => _showArchived = v),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          productsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('Error: $e'),
            data: (products) {
              final q = _searchCtrl.text.trim().toLowerCase();
              final filtered = products.where((p) {
                if (!_showArchived && !p.isActive) return false;
                if (q.isNotEmpty &&
                    !'${p.name} ${p.categoryName ?? ''}'
                        .toLowerCase()
                        .contains(q)) {
                  return false;
                }
                return true;
              }).toList();

              return Column(
                children: [
                  for (final p in filtered)
                    Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: p.isActive
                            ? AppColors.surface
                            : AppColors.background,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Wrap(
                        alignment: WrapAlignment.spaceBetween,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 14,
                        runSpacing: 12,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 62,
                                height: 62,
                                child: ProductImageView(
                                  imageUrl: p.primaryImageUrl,
                                  altText: p.name,
                                  borderRadius: 10,
                                ),
                              ),
                              const SizedBox(width: 12),
                              SizedBox(
                                width: 250,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      p.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    Text(
                                      '${p.categoryName ?? 'Footwear'} • ${p.audience.label} • ${p.variants.length} variants',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.mutedText,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          // Inline price button
                          InkWell(
                            borderRadius: BorderRadius.circular(8),
                            onTap: () => _showInlinePriceEditor(context, p),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.sand,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    CurrencyFormatter.formatGhs(p.basePrice),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.espresso,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  const Icon(
                                    Icons.edit_outlined,
                                    size: 15,
                                    color: AppColors.espresso,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Text(
                            'Stock: ${p.totalAvailableStock}',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: p.totalAvailableStock <= 3
                                  ? AppColors.rose
                                  : AppColors.ink,
                            ),
                          ),
                          Wrap(
                            spacing: 8,
                            children: [
                              OutlinedButton(
                                onPressed: () =>
                                    context.go('/products/${p.id}'),
                                child: const Text('Edit'),
                              ),
                              TextButton(
                                onPressed: () async {
                                  await ref
                                      .read(productRepositoryProvider)
                                      .toggleProductArchive(p.id, !p.isActive);
                                  ref
                                      .read(dataRefreshTriggerProvider.notifier)
                                      .state++;
                                },
                                child: Text(
                                  p.isActive ? 'Archive' : 'Restore',
                                  style: TextStyle(
                                    color: p.isActive
                                        ? AppColors.danger
                                        : AppColors.success,
                                  ),
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
        ],
      ),
    );
  }
}
