import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/stock_calculator.dart';
import '../../../core/utils/validators.dart';
import '../../../core/utils/whatsapp_helper.dart';
import '../../../core/widgets/product_card.dart';
import '../../../core/widgets/product_image_view.dart';
import '../../../core/widgets/store_scaffold.dart';
import '../../../core/widgets/variant_selectors.dart';
import '../../../data/models/models.dart';
import '../../../data/providers.dart';

class ProductDetailScreen extends ConsumerStatefulWidget {
  const ProductDetailScreen({super.key, required this.slug});
  final String slug;

  @override
  ConsumerState<ProductDetailScreen> createState() =>
      _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {
  String? _selectedColour;
  String? _selectedSize;
  int _selectedImageIndex = 0;
  int _quantity = 1;
  String? _initializedProductId;

  void _initializeSelectionIfNeeded(Product product) {
    if (_initializedProductId == product.id) return;
    _initializedProductId = product.id;
    _selectedImageIndex = 0;
    _quantity = 1;

    final firstInStock = product.variants.where((v) => v.isInStock).firstOrNull;
    if (firstInStock != null) {
      _selectedColour = firstInStock.colour;
      _selectedSize = firstInStock.size;
    } else if (product.variants.isNotEmpty) {
      _selectedColour = product.variants.first.colour;
      _selectedSize = product.variants.first.size;
    }
  }

  void _onColourChanged(Product product, String newColour) {
    setState(() {
      _selectedColour = newColour;
      final currentMatch = product.findVariant(_selectedSize ?? '', newColour);
      if (currentMatch == null || !currentMatch.isInStock) {
        final fallback = product.variants
            .where(
              (v) =>
                  v.colour.toLowerCase() == newColour.toLowerCase() &&
                  v.isInStock,
            )
            .firstOrNull;
        if (fallback != null) {
          _selectedSize = fallback.size;
        }
      }
      _quantity = 1;
    });
  }

  void _addToCart(Product product, ProductVariant variant, {bool buyNow = false}) {
    ref.read(cartProvider.notifier).addItem(
          product: product,
          variant: variant,
          quantity: _quantity,
        );
    if (buyNow) {
      context.go('/checkout');
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Added ${product.name} (Size ${variant.size}, ${variant.colour}) to cart',
        ),
        action: SnackBarAction(
          label: 'VIEW CART',
          textColor: AppColors.gold,
          onPressed: () => context.go('/cart'),
        ),
      ),
    );
  }

  void _openZoomGallery(BuildContext context, Product product, String imageUrl) {
    showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.black87,
        insetPadding: const EdgeInsets.all(16),
        child: Stack(
          children: [
            SizedBox(
              width: 820,
              height: 620,
              child: InteractiveViewer(
                minScale: 1,
                maxScale: 4,
                child: ProductImageView(
                  imageUrl: imageUrl,
                  altText: product.name,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: IconButton.filled(
                onPressed: () => Navigator.of(ctx).pop(),
                icon: const Icon(Icons.close_rounded),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final productAsync = ref.watch(productBySlugProvider(widget.slug));
    final allProducts = ref.watch(storeProductsProvider).valueOrNull ?? const [];
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isMobile = screenWidth < 760;

    return productAsync.when(
      loading: () => const StoreScaffold(
        body: Padding(
          padding: EdgeInsets.all(80),
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (e, _) => StoreScaffold(
        body: Padding(
          padding: const EdgeInsets.all(48),
          child: Center(child: Text('Error loading product: $e')),
        ),
      ),
      data: (product) {
        if (product == null) {
          return StoreScaffold(
            body: Padding(
              padding: const EdgeInsets.all(64),
              child: Column(
                children: [
                  const Text('Product not found.'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context.go('/catalogue'),
                    child: const Text('Back to Catalogue'),
                  ),
                ],
              ),
            ),
          );
        }

        _initializeSelectionIfNeeded(product);
        final selectedVariant = (_selectedSize != null && _selectedColour != null)
            ? product.findVariant(_selectedSize!, _selectedColour!)
            : null;
        final unitPrice = selectedVariant != null
            ? selectedVariant.effectivePrice(product.basePrice)
            : product.basePrice;
        final canPurchase = selectedVariant != null && selectedVariant.isInStock;
        final stockMsg = StockAndPricingCalculator.liveStockMessage(selectedVariant);
        final activeImageUrl = product.images.isNotEmpty
            ? product.images[_selectedImageIndex.clamp(0, product.images.length - 1)].url
            : '';

        final related = allProducts
            .where(
              (p) =>
                  p.id != product.id &&
                  (p.categoryId == product.categoryId ||
                      p.audience == product.audience),
            )
            .take(4)
            .toList();

        return StoreScaffold(
          bottomStickyBar: isMobile
              ? SafeArea(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      border: const Border(top: BorderSide(color: AppColors.border)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(18),
                          blurRadius: 10,
                          offset: const Offset(0, -2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                CurrencyFormatter.formatGhs(unitPrice * _quantity),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16,
                                  color: AppColors.espresso,
                                ),
                              ),
                              Text(
                                selectedVariant != null
                                    ? 'EU ${selectedVariant.size} • ${selectedVariant.colour}'
                                    : 'Pick size & colour',
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  color: AppColors.mutedText,
                                ),
                              ),
                            ],
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: canPurchase
                              ? () => _addToCart(product, selectedVariant)
                              : null,
                          icon: const Icon(Icons.add_shopping_cart_rounded, size: 18),
                          label: const Text('Add to Cart'),
                        ),
                      ],
                    ),
                  ),
                )
              : null,
          body: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1200),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Breadcrumb
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 6,
                      children: [
                        InkWell(
                          onTap: () => context.go('/catalogue'),
                          child: const Text(
                            'Catalogue',
                            style: TextStyle(
                              color: AppColors.mutedText,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        const Text('/', style: TextStyle(color: AppColors.mutedText)),
                        Text(
                          product.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Gallery + Details layout
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final wide = constraints.maxWidth >= 840;
                        final gallery = _GalleryPanel(
                          product: product,
                          activeImageUrl: activeImageUrl,
                          selectedIndex: _selectedImageIndex,
                          onSelectIndex: (idx) =>
                              setState(() => _selectedImageIndex = idx),
                          onZoom: () =>
                              _openZoomGallery(context, product, activeImageUrl),
                        );
                        final details = _ProductPurchasePanel(
                          product: product,
                          selectedColour: _selectedColour,
                          selectedSize: _selectedSize,
                          selectedVariant: selectedVariant,
                          unitPrice: unitPrice,
                          quantity: _quantity,
                          stockMessage: stockMsg,
                          canPurchase: canPurchase,
                          onColourChanged: (c) => _onColourChanged(product, c),
                          onSizeChanged: (s) => setState(() {
                            _selectedSize = s;
                            _quantity = 1;
                          }),
                          onQuantityChanged: (q) => setState(() => _quantity = q),
                          onAddToCart: () =>
                              _addToCart(product, selectedVariant!),
                          onBuyNow: () => _addToCart(
                            product,
                            selectedVariant!,
                            buyNow: true,
                          ),
                        );

                        if (wide) {
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(flex: 5, child: gallery),
                              const SizedBox(width: 36),
                              Expanded(flex: 6, child: details),
                            ],
                          );
                        }
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            gallery,
                            const SizedBox(height: 24),
                            details,
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 52),
                    _ReviewsSection(product: product),
                    if (related.isNotEmpty) ...[
                      const SizedBox(height: 52),
                      Text(
                        'You May Also Love',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 18),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final cols = constraints.maxWidth >= 960
                              ? 4
                              : constraints.maxWidth >= 660
                                  ? 3
                                  : 2;
                          return GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: related.length,
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: cols,
                              mainAxisSpacing: 16,
                              crossAxisSpacing: 16,
                              childAspectRatio:
                                  constraints.maxWidth < 430 ? 0.63 : 0.72,
                            ),
                            itemBuilder: (ctx, i) =>
                                ProductCard(product: related[i]),
                          );
                        },
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _GalleryPanel extends StatelessWidget {
  const _GalleryPanel({
    required this.product,
    required this.activeImageUrl,
    required this.selectedIndex,
    required this.onSelectIndex,
    required this.onZoom,
  });

  final Product product;
  final String activeImageUrl;
  final int selectedIndex;
  final ValueChanged<int> onSelectIndex;
  final VoidCallback onZoom;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTap: onZoom,
          child: Stack(
            children: [
              AspectRatio(
                aspectRatio: 1.05,
                child: ProductImageView(
                  imageUrl: activeImageUrl,
                  altText: product.name,
                  borderRadius: 16,
                ),
              ),
              Positioned(
                bottom: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.zoom_in_rounded, color: Colors.white, size: 16),
                      SizedBox(width: 4),
                      Text(
                        'Tap to zoom',
                        style: TextStyle(color: Colors.white, fontSize: 11.5),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        if (product.images.length > 1) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              for (var i = 0; i < product.images.length; i++)
                Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: InkWell(
                    onTap: () => onSelectIndex(i),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      width: 68,
                      height: 68,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: selectedIndex == i
                              ? AppColors.espresso
                              : AppColors.border,
                          width: selectedIndex == i ? 2 : 1,
                        ),
                      ),
                      child: ProductImageView(
                        imageUrl: product.images[i].url,
                        altText: '${product.name} thumbnail ${i + 1}',
                        borderRadius: 8,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

class _ProductPurchasePanel extends StatelessWidget {
  const _ProductPurchasePanel({
    required this.product,
    required this.selectedColour,
    required this.selectedSize,
    required this.selectedVariant,
    required this.unitPrice,
    required this.quantity,
    required this.stockMessage,
    required this.canPurchase,
    required this.onColourChanged,
    required this.onSizeChanged,
    required this.onQuantityChanged,
    required this.onAddToCart,
    required this.onBuyNow,
  });

  final Product product;
  final String? selectedColour;
  final String? selectedSize;
  final ProductVariant? selectedVariant;
  final double unitPrice;
  final int quantity;
  final String stockMessage;
  final bool canPurchase;
  final ValueChanged<String> onColourChanged;
  final ValueChanged<String> onSizeChanged;
  final ValueChanged<int> onQuantityChanged;
  final VoidCallback onAddToCart;
  final VoidCallback onBuyNow;

  @override
  Widget build(BuildContext context) {
    final maxQty = selectedVariant?.availableQty ?? 1;
    final isLow = selectedVariant != null &&
        selectedVariant!.availableQty > 0 &&
        selectedVariant!.availableQty <= 3;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.sand,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${product.audience.label} • ${product.categoryName ?? 'Luxury Footwear'}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.espresso,
                ),
              ),
            ),
            if (product.avgRating > 0)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.star_rounded, color: AppColors.gold, size: 18),
                  const SizedBox(width: 3),
                  Text(
                    '${product.avgRating.toStringAsFixed(1)} (${product.reviewCount} reviews)',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
          ],
        ),
        const SizedBox(height: 12),
        Text(product.name, style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 10),
        Text(
          CurrencyFormatter.formatGhs(unitPrice),
          style: const TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: AppColors.espresso,
          ),
        ),
        const SizedBox(height: 14),
        Text(product.description, style: Theme.of(context).textTheme.bodyLarge),
        const SizedBox(height: 22),
        const Divider(),
        const SizedBox(height: 16),
        Text(
          '1. Choose Colour: ${selectedColour ?? ''}',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 10),
        ColourSwatchSelector(
          colours: product.availableColours,
          selectedColour: selectedColour,
          variants: product.variants,
          selectedSize: selectedSize,
          onSelected: onColourChanged,
        ),
        const SizedBox(height: 20),
        Text(
          '2. Choose EU Size: ${selectedSize ?? ''}',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 10),
        SizeChipSelector(
          sizes: product.availableSizes,
          selectedSize: selectedSize,
          variants: product.variants,
          selectedColour: selectedColour,
          onSelected: onSizeChanged,
        ),
        const SizedBox(height: 16),
        // Live stock badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: !canPurchase
                ? AppColors.dangerSoft
                : (isLow ? AppColors.roseSoft : AppColors.successSoft),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                !canPurchase
                    ? Icons.error_outline_rounded
                    : (isLow
                        ? Icons.local_fire_department_rounded
                        : Icons.check_circle_outline_rounded),
                size: 18,
                color: !canPurchase
                    ? AppColors.danger
                    : (isLow ? AppColors.rose : AppColors.success),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  stockMessage,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: !canPurchase
                        ? AppColors.danger
                        : (isLow ? AppColors.rose : AppColors.success),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        // Quantity selector
        Row(
          children: [
            const Text(
              'Quantity:',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(width: 14),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(10),
                color: AppColors.surface,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    onPressed: quantity > 1
                        ? () => onQuantityChanged(quantity - 1)
                        : null,
                    icon: const Icon(Icons.remove_rounded, size: 18),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      '$quantity',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: canPurchase && quantity < maxQty
                        ? () => onQuantityChanged(quantity + 1)
                        : null,
                    icon: const Icon(Icons.add_rounded, size: 18),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 22),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            ElevatedButton.icon(
              onPressed: canPurchase ? onAddToCart : null,
              icon: const Icon(Icons.shopping_bag_outlined, size: 19),
              label: const Text('Add to Cart'),
            ),
            FilledButton.icon(
              onPressed: canPurchase ? onBuyNow : null,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.gold,
                foregroundColor: AppColors.espressoDark,
              ),
              icon: const Icon(Icons.bolt_rounded, size: 19),
              label: const Text(
                'Buy Now (Mobile Money)',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            OutlinedButton.icon(
              onPressed: () {
                final url = WhatsAppHelper.buildSingleProductOrderUrl(
                  product: product,
                  variant: selectedVariant,
                  quantity: quantity,
                );
                WhatsAppHelper.openUrl(url);
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.whatsappGreen,
                side: const BorderSide(color: AppColors.whatsappGreen, width: 1.4),
              ),
              icon: const Icon(Icons.chat_rounded, size: 18),
              label: const Text('Order on WhatsApp'),
            ),
          ],
        ),
        const SizedBox(height: 22),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.sand,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Delivery & Exchange Guarantee',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: AppColors.espresso,
                ),
              ),
              SizedBox(height: 4),
              Text(
                '• Kumasi (1–2 days) • Accra & Nationwide (3–5 days) • Free Kumasi Pickup\n'
                '• Payment via Mobile Money confirms your order immediately.\n'
                '• Size & colour exchanges allowed within 3 days (payments non-refundable).',
                style: TextStyle(fontSize: 12, color: AppColors.mutedText),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ReviewsSection extends ConsumerStatefulWidget {
  const _ReviewsSection({required this.product});
  final Product product;

  @override
  ConsumerState<_ReviewsSection> createState() => _ReviewsSectionState();
}

class _ReviewsSectionState extends ConsumerState<_ReviewsSection> {
  bool _showForm = false;
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _orderNumCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _commentCtrl = TextEditingController();
  int _rating = 5;
  bool _submitting = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _orderNumCtrl.dispose();
    _phoneCtrl.dispose();
    _commentCtrl.dispose();
    super.dispose();
  }

  Future<void> _submitReview() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    try {
      final customer = ref.read(customerAuthProvider).valueOrNull;
      await ref.read(reviewRepositoryProvider).submitVerifiedReview(
            productId: widget.product.id,
            productName: widget.product.name,
            orderNumber: _orderNumCtrl.text,
            phone: _phoneCtrl.text,
            reviewerName: _nameCtrl.text,
            rating: _rating,
            comment: _commentCtrl.text,
            userId: customer?.id,
          );
      if (!mounted) return;
      setState(() {
        _showForm = false;
        _commentCtrl.clear();
      });
      ref.read(dataRefreshTriggerProvider.notifier).state++;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Thank you! Your verified review has been sent for owner approval.',
          ),
        ),
      );
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
    final reviewsAsync = ref.watch(productReviewsProvider(widget.product.id));

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            runSpacing: 12,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Verified Customer Reviews',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Only verified buyers with a paid order can leave a review.',
                    style: TextStyle(fontSize: 12.5, color: AppColors.mutedText),
                  ),
                ],
              ),
              OutlinedButton.icon(
                onPressed: () => setState(() => _showForm = !_showForm),
                icon: const Icon(Icons.rate_review_outlined, size: 18),
                label: Text(_showForm ? 'Close Form' : 'Write a Verified Review'),
              ),
            ],
          ),
          if (_showForm) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Verify Your Purchase (Demo tip: try Order PSY-20261030-0001 + Phone 0244123456 on Adowa Slide)',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.espresso,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        SizedBox(
                          width: 240,
                          child: TextFormField(
                            controller: _nameCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Your Name',
                            ),
                            validator: (v) =>
                                Validators.requiredField(v, 'Your name'),
                          ),
                        ),
                        SizedBox(
                          width: 240,
                          child: TextFormField(
                            controller: _orderNumCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Order Number (e.g. PSY-...)',
                            ),
                            validator: (v) =>
                                Validators.requiredField(v, 'Order number'),
                          ),
                        ),
                        SizedBox(
                          width: 240,
                          child: TextFormField(
                            controller: _phoneCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Order Phone Number',
                            ),
                            validator: Validators.ghanaPhone,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        const Text(
                          'Rating:',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(width: 8),
                        for (var star = 1; star <= 5; star++)
                          IconButton(
                            onPressed: () => setState(() => _rating = star),
                            icon: Icon(
                              star <= _rating
                                  ? Icons.star_rounded
                                  : Icons.star_border_rounded,
                              color: AppColors.gold,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _commentCtrl,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'How did your pair fit and feel?',
                      ),
                      validator: (v) => Validators.requiredField(v, 'Comment'),
                    ),
                    const SizedBox(height: 14),
                    ElevatedButton(
                      onPressed: _submitting ? null : _submitReview,
                      child: Text(
                        _submitting ? 'Submitting...' : 'Submit Verified Review',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 20),
          reviewsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('Unable to load reviews: $e'),
            data: (reviews) {
              if (reviews.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    'No approved reviews yet for this style. Be the first verified buyer to review!',
                    style: TextStyle(color: AppColors.mutedText),
                  ),
                );
              }
              return Column(
                children: [
                  for (final r in reviews)
                    Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              for (var s = 1; s <= 5; s++)
                                Icon(
                                  s <= r.rating
                                      ? Icons.star_rounded
                                      : Icons.star_border_rounded,
                                  size: 16,
                                  color: AppColors.gold,
                                ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  r.reviewerName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13.5,
                                  ),
                                ),
                              ),
                              Text(
                                CurrencyFormatter.formatDate(r.createdAt),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.mutedText,
                                ),
                              ),
                            ],
                          ),
                          if (r.comment.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(r.comment),
                          ],
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
