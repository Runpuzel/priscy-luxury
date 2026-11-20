import 'package:flutter/foundation.dart';

@immutable
class CartItem {
  const CartItem({
    required this.variantId,
    required this.productId,
    required this.productSlug,
    required this.productName,
    required this.imageUrl,
    required this.size,
    required this.colour,
    required this.unitPrice,
    required this.quantity,
    this.maxAvailable = 99,
  });

  final String variantId;
  final String productId;
  final String productSlug;
  final String productName;
  final String imageUrl;
  final String size;
  final String colour;
  final double unitPrice;
  final int quantity;
  final int maxAvailable;

  double get lineTotal => unitPrice * quantity;

  CartItem copyWith({
    int? quantity,
    double? unitPrice,
    int? maxAvailable,
  }) {
    return CartItem(
      variantId: variantId,
      productId: productId,
      productSlug: productSlug,
      productName: productName,
      imageUrl: imageUrl,
      size: size,
      colour: colour,
      unitPrice: unitPrice ?? this.unitPrice,
      quantity: quantity ?? this.quantity,
      maxAvailable: maxAvailable ?? this.maxAvailable,
    );
  }

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      variantId: json['variant_id']?.toString() ?? '',
      productId: json['product_id']?.toString() ?? '',
      productSlug: json['product_slug']?.toString() ?? '',
      productName: json['product_name']?.toString() ?? '',
      imageUrl: json['image_url']?.toString() ?? '',
      size: json['size']?.toString() ?? '',
      colour: json['colour']?.toString() ?? '',
      unitPrice: (json['unit_price'] as num?)?.toDouble() ?? 0,
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      maxAvailable: (json['max_available'] as num?)?.toInt() ?? 99,
    );
  }

  Map<String, dynamic> toJson() => {
        'variant_id': variantId,
        'product_id': productId,
        'product_slug': productSlug,
        'product_name': productName,
        'image_url': imageUrl,
        'size': size,
        'colour': colour,
        'unit_price': unitPrice,
        'quantity': quantity,
        'max_available': maxAvailable,
      };
}
