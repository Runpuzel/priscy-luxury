import 'package:flutter/foundation.dart';

@immutable
class StockMovement {
  const StockMovement({
    required this.id,
    required this.variantId,
    this.productName,
    this.size,
    this.colour,
    required this.change,
    required this.reason,
    required this.createdAt,
  });

  final String id;
  final String variantId;
  final String? productName;
  final String? size;
  final String? colour;
  final int change;
  final String reason;
  final DateTime createdAt;

  factory StockMovement.fromJson(Map<String, dynamic> json) {
    final variantMap = json['product_variants'] as Map<String, dynamic>?;
    final prodMap = variantMap?['products'] as Map<String, dynamic>?;
    return StockMovement(
      id: json['id']?.toString() ?? '',
      variantId: json['variant_id']?.toString() ?? '',
      productName:
          prodMap?['name']?.toString() ?? json['product_name']?.toString(),
      size: variantMap?['size']?.toString() ?? json['size']?.toString(),
      colour: variantMap?['colour']?.toString() ?? json['colour']?.toString(),
      change: (json['change'] as num?)?.toInt() ?? 0,
      reason: json['reason']?.toString() ?? 'adjustment',
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'variant_id': variantId,
        'product_name': productName,
        'size': size,
        'colour': colour,
        'change': change,
        'reason': reason,
        'created_at': createdAt.toIso8601String(),
      };
}
