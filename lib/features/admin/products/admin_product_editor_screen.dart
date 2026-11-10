import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/admin_scaffold.dart';
import '../../../data/models/models.dart';
import '../../../data/providers.dart';

class AdminProductEditorScreen extends ConsumerStatefulWidget {
  const AdminProductEditorScreen({super.key, this.productId});
  final String? productId;

  @override
  ConsumerState<AdminProductEditorScreen> createState() =>
      _AdminProductEditorScreenState();
}

class _AdminProductEditorScreenState
    extends ConsumerState<AdminProductEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _priceCtrl = TextEditingController(text: '185.00');
  final _newImgCtrl = TextEditingController();
  final _varSizeCtrl = TextEditingController();
  final _varColourCtrl = TextEditingController();
  final _varStockCtrl = TextEditingController(text: '5');
  final _varOverrideCtrl = TextEditingController();

  String? _categoryId;
  Audience _audience = Audience.women;
  bool _isActive = true;
  bool _isFeatured = false;
  final List<String> _imageUrls = [];
  final List<ProductVariant> _variants = [];
  bool _loaded = false;
  bool _saving = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _priceCtrl.dispose();
    _newImgCtrl.dispose();
    _varSizeCtrl.dispose();
    _varColourCtrl.dispose();
    _varStockCtrl.dispose();
    _varOverrideCtrl.dispose();
    super.dispose();
  }

  void _populateFromProduct(Product p) {
    if (_loaded) return;
    _loaded = true;
    _nameCtrl.text = p.name;
    _descCtrl.text = p.description;
    _priceCtrl.text = p.basePrice.toStringAsFixed(2);
    _categoryId = p.categoryId;
    _audience = p.audience;
    _isActive = p.isActive;
    _isFeatured = p.isFeatured;
    _imageUrls
      ..clear()
      ..addAll(p.images.map((e) => e.url));
    _variants
      ..clear()
      ..addAll(p.variants);
  }

  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    final url = await ref.read(productRepositoryProvider).uploadProductImage(
          fileName: picked.name,
          bytes: bytes,
        );
    setState(() => _imageUrls.add(url));
  }

  Future<void> _save(List<Category> categories) async {
    if (!_formKey.currentState!.validate()) return;
    final price = double.tryParse(_priceCtrl.text.trim()) ?? 0;
    final catId =
        _categoryId ?? (categories.isNotEmpty ? categories.first.id : '');

    setState(() => _saving = true);
    try {
      await ref.read(productRepositoryProvider).saveProduct(
            existingId: widget.productId,
            name: _nameCtrl.text,
            categoryId: catId,
            description: _descCtrl.text,
            basePrice: price,
            audience: _audience,
            isActive: _isActive,
            isFeatured: _isFeatured,
            imageUrls: _imageUrls,
            variants: _variants,
          );
      ref.read(dataRefreshTriggerProvider.notifier).state++;
      if (!mounted) return;
      context.go('/products');
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
    final categories = ref.watch(categoriesProvider).valueOrNull ?? const [];
    final allProducts = ref.watch(adminProductsProvider).valueOrNull ?? const [];

    if (widget.productId != null && !_loaded) {
      final existing =
          allProducts.where((p) => p.id == widget.productId).firstOrNull;
      if (existing != null) _populateFromProduct(existing);
    }
    if (_categoryId == null && categories.isNotEmpty) {
      _categoryId = categories.first.id;
    }

    return AdminScaffold(
      title: widget.productId == null ? 'Create New Product' : 'Edit Product',
      currentPath: '/products',
      actions: [
        TextButton(
          onPressed: () => context.go('/products'),
          child: const Text('Cancel'),
        ),
      ],
      body: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
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
                    'Product Information',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _nameCtrl,
                    decoration:
                        const InputDecoration(labelText: 'Product Name *'),
                    validator: (v) =>
                        Validators.requiredField(v, 'Product name'),
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 14,
                    runSpacing: 14,
                    children: [
                      SizedBox(
                        width: 240,
                        child: DropdownButtonFormField<String>(
                          value: _categoryId,
                          decoration:
                              const InputDecoration(labelText: 'Category'),
                          items: [
                            for (final c in categories)
                              DropdownMenuItem(value: c.id, child: Text(c.name)),
                          ],
                          onChanged: (v) => setState(() => _categoryId = v),
                        ),
                      ),
                      SizedBox(
                        width: 220,
                        child: DropdownButtonFormField<Audience>(
                          value: _audience,
                          decoration:
                              const InputDecoration(labelText: 'Audience'),
                          items: [
                            for (final a in Audience.values)
                              DropdownMenuItem(value: a, child: Text(a.label)),
                          ],
                          onChanged: (v) {
                            if (v != null) setState(() => _audience = v);
                          },
                        ),
                      ),
                      SizedBox(
                        width: 190,
                        child: TextFormField(
                          controller: _priceCtrl,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: const InputDecoration(
                            labelText: 'Base Price (GHS) *',
                          ),
                          validator: (v) =>
                              Validators.requiredField(v, 'Base price'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _descCtrl,
                    maxLines: 3,
                    decoration:
                        const InputDecoration(labelText: 'Description'),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 16,
                    children: [
                      FilterChip(
                        label: const Text('Active on Storefront'),
                        selected: _isActive,
                        onSelected: (v) => setState(() => _isActive = v),
                      ),
                      FilterChip(
                        label: const Text('Featured / Best Seller Badge'),
                        selected: _isFeatured,
                        onSelected: (v) => setState(() => _isFeatured = v),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Images
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Product Photos',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      OutlinedButton.icon(
                        onPressed: _pickAndUploadImage,
                        icon: const Icon(Icons.upload_file_rounded, size: 18),
                        label: const Text('Upload Photo from Device'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _newImgCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Or paste image URL',
                            hintText: 'https://...',
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: () {
                          if (_newImgCtrl.text.trim().isEmpty) return;
                          setState(() {
                            _imageUrls.add(_newImgCtrl.text.trim());
                            _newImgCtrl.clear();
                          });
                        },
                        child: const Text('Add URL'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  for (var i = 0; i < _imageUrls.length; i++)
                    ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        _imageUrls[i],
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: IconButton(
                        onPressed: () =>
                            setState(() => _imageUrls.removeAt(i)),
                        icon: const Icon(
                          Icons.delete_outline,
                          color: AppColors.danger,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Variants
            Container(
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
                    'Size × Colour Variants',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      SizedBox(
                        width: 110,
                        child: TextField(
                          controller: _varSizeCtrl,
                          decoration:
                              const InputDecoration(labelText: 'EU Size (39)'),
                        ),
                      ),
                      SizedBox(
                        width: 150,
                        child: TextField(
                          controller: _varColourCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Colour (Gold)',
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 110,
                        child: TextField(
                          controller: _varStockCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Stock'),
                        ),
                      ),
                      SizedBox(
                        width: 160,
                        child: TextField(
                          controller: _varOverrideCtrl,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: const InputDecoration(
                            labelText: 'Price Override (Opt)',
                          ),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          final sz = _varSizeCtrl.text.trim();
                          final col = _varColourCtrl.text.trim();
                          if (sz.isEmpty || col.isEmpty) return;
                          setState(() {
                            _variants.add(
                              ProductVariant(
                                id: 'temp-${DateTime.now().microsecondsSinceEpoch}',
                                productId: widget.productId ?? '',
                                size: sz,
                                colour: col,
                                stockQty:
                                    int.tryParse(_varStockCtrl.text) ?? 0,
                                priceOverride: double.tryParse(
                                  _varOverrideCtrl.text.trim(),
                                ),
                              ),
                            );
                            _varSizeCtrl.clear();
                            _varColourCtrl.clear();
                          });
                        },
                        child: const Text('Add Variant'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  for (var i = 0; i < _variants.length; i++)
                    ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        'EU ${_variants[i].size} • ${_variants[i].colour} — Stock: ${_variants[i].stockQty} (Reserved: ${_variants[i].reservedQty})',
                      ),
                      trailing: IconButton(
                        onPressed: () =>
                            setState(() => _variants.removeAt(i)),
                        icon: const Icon(
                          Icons.delete_outline,
                          color: AppColors.danger,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                onPressed: _saving ? null : () => _save(categories),
                icon: const Icon(Icons.save_outlined, size: 18),
                label: Text(_saving ? 'Saving Product...' : 'Save Product'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
