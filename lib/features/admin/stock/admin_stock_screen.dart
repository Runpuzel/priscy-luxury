import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/admin_scaffold.dart';
import '../../../data/models/models.dart';
import '../../../data/providers.dart';

class AdminStockScreen extends ConsumerStatefulWidget {
  const AdminStockScreen({super.key});

  @override
  ConsumerState<AdminStockScreen> createState() => _AdminStockScreenState();
}

class _AdminStockScreenState extends ConsumerState<AdminStockScreen> {
  String? _selectedProductId;

  void _openCsvImportDialog(BuildContext context, List<Product> products) {
    final sampleCsv = [
      'product_slug,size,colour,stock_qty,price_override,sku',
      'adowa-gold-buckle-slide,38,Espresso,12,,ADOWA-38-ESP',
      'kumasi-royal-crossover-leather,43,Black,10,265.00,KUMAS-43-BLK',
    ].join('\n');
    final csvCtrl = TextEditingController(text: sampleCsv);

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Import Variant Stock via CSV'),
        content: SizedBox(
          width: 580,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Paste rows from Priscilla\'s Excel/Google Sheet stock list with columns:\nproduct_slug,size,colour,stock_qty,price_override,sku',
                style: TextStyle(fontSize: 12.5, color: AppColors.mutedText),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: csvCtrl,
                maxLines: 8,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 12.5),
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
              final count = await ref
                  .read(productRepositoryProvider)
                  .importStockCsv(csvCtrl.text);
              ref.read(dataRefreshTriggerProvider.notifier).state++;
              if (ctx.mounted) {
                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Updated $count variants from CSV.')),
                );
              }
            },
            child: const Text('Run CSV Stock Import'),
          ),
        ],
      ),
    );
  }

  void _openCsvExportDialog(BuildContext context, List<Product> products) {
    final lines = <String>[
      'product_slug,product_name,size,colour,stock_qty,reserved_qty,available_qty,price_override,sku',
      for (final p in products)
        for (final v in p.variants)
          [
            Validators.escapeCsvCell(p.slug),
            Validators.escapeCsvCell(p.name),
            Validators.escapeCsvCell(v.size),
            Validators.escapeCsvCell(v.colour),
            '${v.stockQty}',
            '${v.reservedQty}',
            '${v.availableQty}',
            v.priceOverride?.toStringAsFixed(2) ?? '',
            Validators.escapeCsvCell(v.sku ?? ''),
          ].join(','),
    ];

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Export Full Inventory CSV'),
        content: SizedBox(
          width: 620,
          child: SelectableText(
            lines.join('\n'),
            style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final products = ref.watch(adminProductsProvider).valueOrNull ?? const [];
    final movements =
        ref.watch(adminStockMovementsProvider).valueOrNull ?? const [];

    if (_selectedProductId == null && products.isNotEmpty) {
      _selectedProductId = products.first.id;
    }
    final activeProduct =
        products.where((p) => p.id == _selectedProductId).firstOrNull;

    return AdminScaffold(
      title: 'Variants, Stock Grid & Audit Log',
      currentPath: '/stock',
      actions: [
        OutlinedButton.icon(
          onPressed: () => _openCsvExportDialog(context, products),
          icon: const Icon(Icons.download_rounded, size: 18),
          label: const Text('Export CSV'),
        ),
        const SizedBox(width: 8),
        ElevatedButton.icon(
          onPressed: () => _openCsvImportDialog(context, products),
          icon: const Icon(Icons.upload_file_rounded, size: 18),
          label: const Text('Import Stock CSV'),
        ),
      ],
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Product selector + Size × Colour grid
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
                DropdownButtonFormField<String>(
                  value: _selectedProductId,
                  decoration: const InputDecoration(
                    labelText: 'Select Product to Manage Size × Colour Stock',
                  ),
                  items: [
                    for (final p in products)
                      DropdownMenuItem(
                        value: p.id,
                        child: Text(
                          '${p.name} (Total Available: ${p.totalAvailableStock})',
                        ),
                      ),
                  ],
                  onChanged: (v) => setState(() => _selectedProductId = v),
                ),
                const SizedBox(height: 18),
                if (activeProduct != null)
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      for (final v in activeProduct.variants)
                        Container(
                          width: 245,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: v.availableQty <= 3
                                ? AppColors.roseSoft
                                : AppColors.background,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'EU ${v.size} • ${v.colour}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                'Available: ${v.availableQty} (Reserved: ${v.reservedQty})',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.mutedText,
                                ),
                              ),
                              Text(
                                'Price: ${CurrencyFormatter.formatGhs(v.effectivePrice(activeProduct.basePrice))}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  IconButton.outlined(
                                    tooltip: 'Deduct 1',
                                    onPressed: v.availableQty > 0
                                        ? () async {
                                            await ref
                                                .read(productRepositoryProvider)
                                                .adjustVariantStock(
                                                  variantId: v.id,
                                                  delta: -1,
                                                  reason: 'adjustment',
                                                );
                                            ref
                                                .read(
                                                  dataRefreshTriggerProvider
                                                      .notifier,
                                                )
                                                .state++;
                                          }
                                        : null,
                                    icon: const Icon(Icons.remove, size: 16),
                                  ),
                                  Text(
                                    '${v.stockQty}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 16,
                                    ),
                                  ),
                                  IconButton.outlined(
                                    tooltip: 'Add 1',
                                    onPressed: () async {
                                      await ref
                                          .read(productRepositoryProvider)
                                          .adjustVariantStock(
                                            variantId: v.id,
                                            delta: 1,
                                            reason: 'restock',
                                          );
                                      ref
                                          .read(
                                            dataRefreshTriggerProvider.notifier,
                                          )
                                          .state++;
                                    },
                                    icon: const Icon(Icons.add, size: 16),
                                  ),
                                  TextButton(
                                    onPressed: () async {
                                      await ref
                                          .read(productRepositoryProvider)
                                          .adjustVariantStock(
                                            variantId: v.id,
                                            delta: 5,
                                            reason: 'restock:+5',
                                          );
                                      ref
                                          .read(
                                            dataRefreshTriggerProvider.notifier,
                                          )
                                          .state++;
                                    },
                                    child: const Text('+5'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Stock Movements History Log
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
                  'Recent Stock History Log',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 10),
                for (final sm in movements.take(20))
                  ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      '${sm.productName ?? sm.variantId} (EU ${sm.size ?? '-'}, ${sm.colour ?? '-'})',
                    ),
                    subtitle: Text(
                      '${sm.reason} • ${CurrencyFormatter.formatDateTime(sm.createdAt)}',
                    ),
                    trailing: Text(
                      sm.change > 0 ? '+${sm.change}' : '${sm.change}',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color:
                            sm.change > 0 ? AppColors.success : AppColors.rose,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
