import 'package:flutter/foundation.dart';

import 'enums.dart';

@immutable
class ProductImage {
  const ProductImage({
    required this.id,
    required this.productId,
    required this.url,
    this.sortOrder = 0,
  });

  final String id;
  final String productId;
  final String url;
  final int sortOrder;

  factory ProductImage.fromJson(Map<String, dynamic> json) {
    return ProductImage(
      id: json['id']?.toString() ?? '',
      productId: json['product_id']?.toString() ?? '',
      url: json['url']?.toString() ?? '',
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'product_id': productId,
        'url': url,
        'sort_order': sortOrder,
      };
}

@immutable
class ProductVariant {
  const ProductVariant({
    required this.id,
    required this.productId,
    required this.size,
    required this.colour,
    this.sku,
    this.priceOverride,
    this.stockQty = 0,
    this.reservedQty = 0,
  });

  final String id;
  final String productId;
  final String size;
  final String colour;
  final String? sku;
  final double? priceOverride;
  final int stockQty;
  final int reservedQty;

  /// Quantity available for new shoppers (stock minus active 15-minute reservations).
  int get availableQty {
    final available = stockQty - reservedQty;
    return available < 0 ? 0 : available;
  }

  bool get isInStock => availableQty > 0;

  double effectivePrice(double basePrice) => priceOverride ?? basePrice;

  ProductVariant copyWith({
    String? id,
    String? productId,
    String? size,
    String? colour,
    String? sku,
    double? priceOverride,
    bool clearPriceOverride = false,
    int? stockQty,
    int? reservedQty,
  }) {
    return ProductVariant(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      size: size ?? this.size,
      colour: colour ?? this.colour,
      sku: sku ?? this.sku,
      priceOverride:
          clearPriceOverride ? null : (priceOverride ?? this.priceOverride),
      stockQty: stockQty ?? this.stockQty,
      reservedQty: reservedQty ?? this.reservedQty,
    );
  }

  factory ProductVariant.fromJson(Map<String, dynamic> json) {
    return ProductVariant(
      id: json['id']?.toString() ?? '',
      productId: json['product_id']?.toString() ?? '',
      size: json['size']?.toString() ?? '',
      colour: json['colour']?.toString() ?? '',
      sku: json['sku']?.toString(),
      priceOverride: (json['price_override'] as num?)?.toDouble(),
      stockQty: (json['stock_qty'] as num?)?.toInt() ?? 0,
      reservedQty: (json['reserved_qty'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'product_id': productId,
        'size': size,
        'colour': colour,
        'sku': sku,
        'price_override': priceOverride,
        'stock_qty': stockQty,
        'reserved_qty': reservedQty,
      };
}

@immutable
class Product {
  const Product({
    required this.id,
    required this.categoryId,
    required this.name,
    required this.slug,
    required this.basePrice,
    this.description = '',
    this.audience = Audience.unisex,
    this.isActive = true,
    this.isFeatured = false,
    this.createdAt,
    this.categoryName,
    this.categorySlug,
    this.images = const [],
    this.variants = const [],
    this.avgRating = 0,
    this.reviewCount = 0,
    this.unitsSold = 0,
  });

  final String id;
  final String? categoryId;
  final String name;
  final String slug;
  final String description;
  final double basePrice;
  final Audience audience;
  final bool isActive;
  final bool isFeatured;
  final DateTime? createdAt;
  final String? categoryName;
  final String? categorySlug;
  final List<ProductImage> images;
  final List<ProductVariant> variants;
  final double avgRating;
  final int reviewCount;
  final int unitsSold;

  String get primaryImageUrl => images.isNotEmpty ? images.first.url : '';

  int get totalAvailableStock =>
      variants.fold<int>(0, (sum, v) => sum + v.availableQty);

  bool get hasInStockVariant => variants.any((v) => v.isInStock);

  List<String> get availableSizes {
    final seen = <String>{};
    final result = <String>[];
    for (final v in variants) {
      if (seen.add(v.size)) result.add(v.size);
    }
    return result;
  }

  List<String> get availableColours {
    final seen = <String>{};
    final result = <String>[];
    for (final v in variants) {
      if (seen.add(v.colour)) result.add(v.colour);
    }
    return result;
  }

  ProductVariant? findVariant(String size, String colour) {
    for (final v in variants) {
      if (v.size == size && v.colour.toLowerCase() == colour.toLowerCase()) {
        return v;
      }
    }
    return null;
  }

  Product copyWith({
    String? id,
    String? categoryId,
    String? name,
    String? slug,
    String? description,
    double? basePrice,
    Audience? audience,
    bool? isActive,
    bool? isFeatured,
    DateTime? createdAt,
    String? categoryName,
    String? categorySlug,
    List<ProductImage>? images,
    List<ProductVariant>? variants,
    double? avgRating,
    int? reviewCount,
    int? unitsSold,
  }) {
    return Product(
      id: id ?? this.id,
      categoryId: categoryId ?? this.categoryId,
      name: name ?? this.name,
      slug: slug ?? this.slug,
      description: description ?? this.description,
      basePrice: basePrice ?? this.basePrice,
      audience: audience ?? this.audience,
      isActive: isActive ?? this.isActive,
      isFeatured: isFeatured ?? this.isFeatured,
      createdAt: createdAt ?? this.createdAt,
      categoryName: categoryName ?? this.categoryName,
      categorySlug: categorySlug ?? this.categorySlug,
      images: images ?? this.images,
      variants: variants ?? this.variants,
      avgRating: avgRating ?? this.avgRating,
      reviewCount: reviewCount ?? this.reviewCount,
      unitsSold: unitsSold ?? this.unitsSold,
    );
  }

  factory Product.fromJson(Map<String, dynamic> json) {
    final rawImages = (json['product_images'] as List<dynamic>?) ?? const [];
    final parsedImages = rawImages
        .whereType<Map<String, dynamic>>()
        .map(ProductImage.fromJson)
        .toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    final rawVariants = (json['product_variants'] as List<dynamic>?) ?? const [];
    final parsedVariants = rawVariants
        .whereType<Map<String, dynamic>>()
        .map(ProductVariant.fromJson)
        .toList();

    final catMap = json['categories'] as Map<String, dynamic>?;

    return Product(
      id: json['id']?.toString() ?? '',
      categoryId: json['category_id']?.toString(),
      name: json['name']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      basePrice: (json['base_price'] as num?)?.toDouble() ?? 0,
      audience: Audience.fromString(json['audience']?.toString()),
      isActive: json['is_active'] as bool? ?? true,
      isFeatured: json['is_featured'] as bool? ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      categoryName: catMap?['name']?.toString() ?? json['category_name']?.toString(),
      categorySlug: catMap?['slug']?.toString() ?? json['category_slug']?.toString(),
      images: parsedImages,
      variants: parsedVariants,
      avgRating: (json['avg_rating'] as num?)?.toDouble() ?? 0,
      reviewCount: (json['review_count'] as num?)?.toInt() ?? 0,
      unitsSold: (json['units_sold'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'category_id': categoryId,
        'name': name,
        'slug': slug,
        'description': description,
        'base_price': basePrice,
        'audience': audience.dbValue,
        'is_active': isActive,
        'is_featured': isFeatured,
        'created_at': createdAt?.toIso8601String(),
        'category_name': categoryName,
        'category_slug': categorySlug,
        'product_images': images.map((e) => e.toJson()).toList(),
        'product_variants': variants.map((e) => e.toJson()).toList(),
        'avg_rating': avgRating,
        'review_count': reviewCount,
        'units_sold': unitsSold,
      };
}
