import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/whatsapp_helper.dart';
import '../../../core/widgets/product_image_view.dart';
import '../../../core/widgets/store_scaffold.dart';
import '../../../data/providers.dart';

class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(cartProvider);
    final subtotal = ref.watch(cartSubtotalProvider);

    return StoreScaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1120),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 28, 16, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Your Shopping Bag',
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
                const SizedBox(height: 6),
                const Text(
                  'Saved on this device automatically. Pay via Mobile Money or send your bag directly to WhatsApp.',
                  style: TextStyle(color: AppColors.mutedText, fontSize: 13),
                ),
                const SizedBox(height: 24),
                if (items.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(52),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.shopping_bag_outlined,
                          size: 52,
                          color: AppColors.mutedText,
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'Your shopping bag is currently empty',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Browse our launch collection of flat sandals, slides, and artisan leather sandals.',
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: () => context.go('/catalogue'),
                          child: const Text('Explore Footwear Collection'),
                        ),
                      ],
                    ),
                  )
                else
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final wide = constraints.maxWidth >= 860;
                      final itemList = Column(
                        children: [
                          for (final item in items)
                            Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 84,
                                    height: 84,
                                    child: ProductImageView(
                                      imageUrl: item.imageUrl,
                                      altText: item.productName,
                                      borderRadius: 10,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        InkWell(
                                          onTap: () => context
                                              .go('/product/${item.productSlug}'),
                                          child: Text(
                                            item.productName,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 15,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Size: EU ${item.size} • Colour: ${item.colour}',
                                          style: const TextStyle(
                                            fontSize: 12.5,
                                            color: AppColors.mutedText,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          CurrencyFormatter.formatGhs(
                                            item.unitPrice,
                                          ),
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.espresso,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        tooltip: 'Decrease quantity',
                                        onPressed: () => ref
                                            .read(cartProvider.notifier)
                                            .updateQuantity(
                                              item.variantId,
                                              item.quantity - 1,
                                            ),
                                        icon: const Icon(Icons.remove_circle_outline),
                                      ),
                                      Text(
                                        '${item.quantity}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      IconButton(
                                        tooltip: 'Increase quantity',
                                        onPressed: item.quantity < item.maxAvailable
                                            ? () => ref
                                                .read(cartProvider.notifier)
                                                .updateQuantity(
                                                  item.variantId,
                                                  item.quantity + 1,
                                                )
                                            : null,
                                        icon: const Icon(Icons.add_circle_outline),
                                      ),
                                      IconButton(
                                        tooltip: 'Remove item',
                                        onPressed: () => ref
                                            .read(cartProvider.notifier)
                                            .removeItem(item.variantId),
                                        icon: const Icon(
                                          Icons.delete_outline_rounded,
                                          color: AppColors.danger,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                        ],
                      );

                      final summaryCard = Container(
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
                              'Order Summary',
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Subtotal'),
                                Text(
                                  CurrencyFormatter.formatGhs(subtotal),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            const Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Delivery Fee',
                                  style: TextStyle(color: AppColors.mutedText),
                                ),
                                Text(
                                  'Calculated at checkout',
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    color: AppColors.mutedText,
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 28),
                            ElevatedButton.icon(
                              onPressed: () => context.go('/checkout'),
                              icon: const Icon(Icons.lock_outline_rounded, size: 18),
                              label: const Text(
                                'Proceed to Mobile Money Checkout',
                              ),
                            ),
                            const SizedBox(height: 12),
                            OutlinedButton.icon(
                              onPressed: () {
                                final url = WhatsAppHelper.buildCartOrderUrl(
                                  items: items,
                                );
                                WhatsAppHelper.openUrl(url);
                              },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.whatsappGreen,
                                side: const BorderSide(
                                  color: AppColors.whatsappGreen,
                                  width: 1.4,
                                ),
                              ),
                              icon: const Icon(Icons.chat_rounded, size: 18),
                              label: const Text('Order Entire Bag on WhatsApp'),
                            ),
                            const SizedBox(height: 14),
                            const Text(
                              'Stock is reserved for 15 minutes once you start Mobile Money payment.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 11.5,
                                color: AppColors.mutedText,
                              ),
                            ),
                          ],
                        ),
                      );

                      if (wide) {
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(flex: 7, child: itemList),
                            const SizedBox(width: 24),
                            Expanded(flex: 4, child: summaryCard),
                          ],
                        );
                      }
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          itemList,
                          const SizedBox(height: 20),
                          summaryCard,
                        ],
                      );
                    },
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
