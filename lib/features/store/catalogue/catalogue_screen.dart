import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/stock_calculator.dart';
import '../../../core/widgets/product_card.dart';
import '../../../core/widgets/store_scaffold.dart';
import '../../../data/models/models.dart';
import '../../../data/providers.dart';

class CatalogueScreen extends ConsumerStatefulWidget {
  const CatalogueScreen({
    super.key,
    this.initialCategory,
    this.initialAudience,
    this.initialSize,
    this.initialColour,
    this.initialSort,
    this.initialBestSellers = false,
    this.initialQuery,
  });

  final String? initialCategory;
  final String? initialAudience;
  final String? initialSize;
  final String? initialColour;
  final String? initialSort;
  final bool initialBestSellers;
  final String? initialQuery;

  @override
  ConsumerState<CatalogueScreen> createState() => _CatalogueScreenState();
}

class _CatalogueScreenState extends ConsumerState<CatalogueScreen> {
  String? _selectedCategory;
  Audience? _selectedAudience;
  String? _selectedSize;
  String? _selectedColour;
  late CatalogueSort _sort;
  bool _bestSellersOnly = false;
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _syncFromWidget();
    _searchController = TextEditingController(text: widget.initialQuery ?? '');
  }

  @override
  void didUpdateWidget(covariant CatalogueScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialCategory != widget.initialCategory ||
        oldWidget.initialAudience != widget.initialAudience ||
        oldWidget.initialBestSellers != widget.initialBestSellers ||
        oldWidget.initialQuery != widget.initialQuery ||
        oldWidget.initialSort != widget.initialSort) {
      setState(() {
        _syncFromWidget();
        _searchController.text = widget.initialQuery ?? '';
      });
    }
  }

  void _syncFromWidget() {
    _selectedCategory = widget.initialCategory;
    _selectedAudience = widget.initialAudience != null &&
            widget.initialAudience!.isNotEmpty
        ? Audience.fromString(widget.initialAudience)
        : null;
    _selectedSize = widget.initialSize;
    _selectedColour = widget.initialColour;
    _sort = CatalogueSort.fromString(widget.initialSort);
    _bestSellersOnly = widget.initialBestSellers;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _resetFilters() {
    setState(() {
      _selectedCategory = null;
      _selectedAudience = null;
      _selectedSize = null;
      _selectedColour = null;
      _bestSellersOnly = false;
      _sort = CatalogueSort.bestSelling;
      _searchController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(storeProductsProvider);
    final categories = ref.watch(categoriesProvider).valueOrNull ?? const [];

    return StoreScaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 28, 16, 20),
            child: productsAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(64),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => Text('Failed to load catalogue: $e'),
              data: (allProducts) {
                final allSizes = <String>{
                  for (final p in allProducts) ...p.availableSizes,
                }.toList()
                  ..sort();
                final allColours = <String>{
                  for (final p in allProducts) ...p.availableColours,
                }.toList()
                  ..sort();

                final filtered = StockAndPricingCalculator.filterAndSortProducts(
                  products: allProducts,
                  categorySlug: _selectedCategory,
                  audience: _selectedAudience,
                  size: _selectedSize,
                  colour: _selectedColour,
                  bestSellersOnly: _bestSellersOnly,
                  searchQuery: _searchController.text,
                  sort: _sort,
                );

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Footwear Catalogue',
                      style: Theme.of(context).textTheme.headlineLarge,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Showing ${filtered.length} of ${allProducts.length} styles • Size & colour filters only display in-stock pairs.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 20),
                    // Filter & sort bar
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              SizedBox(
                                width: 250,
                                child: TextField(
                                  controller: _searchController,
                                  onChanged: (_) => setState(() {}),
                                  decoration: const InputDecoration(
                                    hintText: 'Search style or material...',
                                    prefixIcon: Icon(Icons.search_rounded),
                                    isDense: true,
                                  ),
                                ),
                              ),
                              _FilterDropdown<String?>(
                                label: 'Category',
                                value: _selectedCategory,
                                items: [
                                  const DropdownMenuItem(
                                    value: null,
                                    child: Text('All Categories'),
                                  ),
                                  for (final c in categories)
                                    DropdownMenuItem(
                                      value: c.slug,
                                      child: Text(c.name),
                                    ),
                                ],
                                onChanged: (v) =>
                                    setState(() => _selectedCategory = v),
                              ),
                              _FilterDropdown<Audience?>(
                                label: 'Audience',
                                value: _selectedAudience,
                                items: const [
                                  DropdownMenuItem(
                                    value: null,
                                    child: Text('Everyone'),
                                  ),
                                  DropdownMenuItem(
                                    value: Audience.women,
                                    child: Text('Women'),
                                  ),
                                  DropdownMenuItem(
                                    value: Audience.men,
                                    child: Text('Men'),
                                  ),
                                  DropdownMenuItem(
                                    value: Audience.children,
                                    child: Text('Children'),
                                  ),
                                ],
                                onChanged: (v) =>
                                    setState(() => _selectedAudience = v),
                              ),
                              _FilterDropdown<String?>(
                                label: 'In-Stock Size',
                                value: _selectedSize,
                                items: [
                                  const DropdownMenuItem(
                                    value: null,
                                    child: Text('Any Size'),
                                  ),
                                  for (final sz in allSizes)
                                    DropdownMenuItem(
                                      value: sz,
                                      child: Text('EU $sz'),
                                    ),
                                ],
                                onChanged: (v) =>
                                    setState(() => _selectedSize = v),
                              ),
                              _FilterDropdown<String?>(
                                label: 'In-Stock Colour',
                                value: _selectedColour,
                                items: [
                                  const DropdownMenuItem(
                                    value: null,
                                    child: Text('Any Colour'),
                                  ),
                                  for (final col in allColours)
                                    DropdownMenuItem(
                                      value: col,
                                      child: Text(col),
                                    ),
                                ],
                                onChanged: (v) =>
                                    setState(() => _selectedColour = v),
                              ),
                              _FilterDropdown<CatalogueSort>(
                                label: 'Sort By',
                                value: _sort,
                                items: [
                                  for (final s in CatalogueSort.values)
                                    DropdownMenuItem(
                                      value: s,
                                      child: Text(s.label),
                                    ),
                                ],
                                onChanged: (v) {
                                  if (v != null) setState(() => _sort = v);
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 10,
                            runSpacing: 8,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              FilterChip(
                                label: const Text('Best Sellers Only'),
                                selected: _bestSellersOnly,
                                onSelected: (val) =>
                                    setState(() => _bestSellersOnly = val),
                              ),
                              if (_selectedCategory != null ||
                                  _selectedAudience != null ||
                                  _selectedSize != null ||
                                  _selectedColour != null ||
                                  _bestSellersOnly ||
                                  _searchController.text.isNotEmpty)
                                TextButton.icon(
                                  onPressed: _resetFilters,
                                  icon: const Icon(Icons.clear_all_rounded),
                                  label: const Text('Clear All Filters'),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    if (filtered.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(48),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Column(
                          children: [
                            const Icon(
                              Icons.search_off_rounded,
                              size: 46,
                              color: AppColors.mutedText,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'No in-stock styles match those exact filters',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Try clearing the size or colour filter, or message us on WhatsApp for custom restock timelines.',
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            OutlinedButton(
                              onPressed: _resetFilters,
                              child: const Text('Reset Filters'),
                            ),
                          ],
                        ),
                      )
                    else
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final w = constraints.maxWidth;
                          final cols = w >= 1020
                              ? 4
                              : w >= 700
                                  ? 3
                                  : 2;
                          final aspect = w < 430 ? 0.63 : 0.72;

                          return GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: filtered.length,
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: cols,
                              mainAxisSpacing: 16,
                              crossAxisSpacing: 16,
                              childAspectRatio: aspect,
                            ),
                            itemBuilder: (context, idx) =>
                                ProductCard(product: filtered[idx]),
                          );
                        },
                      ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _FilterDropdown<T> extends StatelessWidget {
  const _FilterDropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String label;
  final T value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 175,
      child: DropdownButtonFormField<T>(
        value: value,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: label,
          isDense: true,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
        items: items,
        onChanged: onChanged,
      ),
    );
  }
}
