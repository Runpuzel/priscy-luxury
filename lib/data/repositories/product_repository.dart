import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/config/app_config.dart';
import '../../core/utils/validators.dart';
import '../models/models.dart';
import 'demo_database.dart';

class ProductRepository {
  ProductRepository({required DemoDatabase demoDb}) : _demoDb = demoDb;

  final DemoDatabase _demoDb;

  SupabaseClient get _supabase => Supabase.instance.client;

  Future<List<Category>> fetchCategories() async {
    if (AppConfig.isDemoMode) {
      final list = List<Category>.from(_demoDb.categories)
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
      return list;
    }

    final rows = await _supabase
        .from('categories')
        .select()
        .order('sort_order', ascending: true);
    return rows.map(Category.fromJson).toList();
  }

  Future<List<Product>> fetchProducts({bool includeInactive = false}) async {
    if (AppConfig.isDemoMode) {
      _demoDb.releaseExpiredReservations();
      final list = _demoDb.products
          .where((p) => includeInactive || p.isActive)
          .map(_demoDb.recalculateProductRatings)
          .toList();
      return list;
    }

    var query = _supabase.from('products').select(
          '*, categories(id, name, slug), product_images(*), product_variants(*)',
        );
    if (!includeInactive) {
      query = query.eq('is_active', true);
    }
    final productRows = await query.order('created_at', ascending: false);

    final ratingsRows = await _supabase.from('product_ratings').select();
    final soldRows = await _supabase.from('best_sellers').select();

    final ratingMap = <String, Map<String, dynamic>>{
      for (final r in ratingsRows) r['product_id'].toString(): r,
    };
    final soldMap = <String, int>{
      for (final s in soldRows)
        s['product_id'].toString(): (s['units_sold'] as num?)?.toInt() ?? 0,
    };

    return productRows.map((row) {
      final id = row['id'].toString();
      final rating = ratingMap[id];
      return Product.fromJson({
        ...row,
        'avg_rating': rating?['avg_rating'] ?? 0,
        'review_count': rating?['review_count'] ?? 0,
        'units_sold': soldMap[id] ?? 0,
      });
    }).toList();
  }

  Future<Product?> fetchProductBySlug(String slug) async {
    final all = await fetchProducts(includeInactive: false);
    for (final p in all) {
      if (p.slug == slug || p.id == slug) return p;
    }
    return null;
  }

  Future<Product?> fetchProductById(String id) async {
    final all = await fetchProducts(includeInactive: true);
    for (final p in all) {
      if (p.id == id) return p;
    }
    return null;
  }

  Future<Product> saveProduct({
    String? existingId,
    required String name,
    required String categoryId,
    required String description,
    required double basePrice,
    required Audience audience,
    required bool isActive,
    required bool isFeatured,
    required List<String> imageUrls,
    required List<ProductVariant> variants,
  }) async {
    final slug = Validators.slugify(name);

    if (AppConfig.isDemoMode) {
      final cat = _demoDb.categories.firstWhere(
        (c) => c.id == categoryId,
        orElse: () => _demoDb.categories.first,
      );
      final productId = existingId ?? _demoDb.nextId('prod');
      final imgs = <ProductImage>[
        for (var i = 0; i < imageUrls.length; i++)
          if (imageUrls[i].trim().isNotEmpty)
            ProductImage(
              id: _demoDb.nextId('img'),
              productId: productId,
              url: imageUrls[i].trim(),
              sortOrder: i,
            ),
      ];
      final normalizedVariants = variants.map((v) {
        return v.copyWith(
          id: v.id.isEmpty ? _demoDb.nextId('var') : v.id,
          productId: productId,
          sku: (v.sku == null || v.sku!.trim().isEmpty)
              ? '${slug.substring(0, slug.length.clamp(0, 5)).toUpperCase()}-${v.size}-${v.colour.substring(0, v.colour.length.clamp(0, 3)).toUpperCase()}'
              : v.sku,
        );
      }).toList();

      final saved = Product(
        id: productId,
        categoryId: cat.id,
        categoryName: cat.name,
        categorySlug: cat.slug,
        name: name.trim(),
        slug: slug,
        description: description.trim(),
        basePrice: basePrice,
        audience: audience,
        isActive: isActive,
        isFeatured: isFeatured,
        createdAt: DateTime.now(),
        images: imgs,
        variants: normalizedVariants,
      );

      final idx = _demoDb.products.indexWhere((p) => p.id == productId);
      if (idx == -1) {
        _demoDb.products.insert(0, saved);
      } else {
        final prev = _demoDb.products[idx];
        _demoDb.products[idx] = saved.copyWith(
          avgRating: prev.avgRating,
          reviewCount: prev.reviewCount,
          unitsSold: prev.unitsSold,
          createdAt: prev.createdAt,
        );
      }
      await _demoDb.saveProducts();
      return saved;
    }

    // Live Supabase CRUD
    Map<String, dynamic> prodRow;
    if (existingId == null) {
      prodRow = await _supabase
          .from('products')
          .insert({
            'category_id': categoryId,
            'name': name.trim(),
            'slug': slug,
            'description': description.trim(),
            'base_price': basePrice,
            'audience': audience.dbValue,
            'is_active': isActive,
            'is_featured': isFeatured,
          })
          .select()
          .single();
    } else {
      prodRow = await _supabase
          .from('products')
          .update({
            'category_id': categoryId,
            'name': name.trim(),
            'slug': slug,
            'description': description.trim(),
            'base_price': basePrice,
            'audience': audience.dbValue,
            'is_active': isActive,
            'is_featured': isFeatured,
          })
          .eq('id', existingId)
          .select()
          .single();
    }

    final productId = prodRow['id'].toString();
    await _supabase.from('product_images').delete().eq('product_id', productId);
    for (var i = 0; i < imageUrls.length; i++) {
      if (imageUrls[i].trim().isEmpty) continue;
      await _supabase.from('product_images').insert({
        'product_id': productId,
        'url': imageUrls[i].trim(),
        'sort_order': i,
      });
    }

    for (final v in variants) {
      await _supabase.from('product_variants').upsert(
        {
          if (v.id.isNotEmpty && !v.id.startsWith('temp-')) 'id': v.id,
          'product_id': productId,
          'size': v.size,
          'colour': v.colour,
          'sku': v.sku,
          'price_override': v.priceOverride,
          'stock_qty': v.stockQty,
        },
        onConflict: 'product_id,size,colour',
      );
    }

    return (await fetchProductById(productId))!;
  }

  Future<void> updateProductBasePrice(String productId, double newPrice) async {
    if (AppConfig.isDemoMode) {
      final idx = _demoDb.products.indexWhere((p) => p.id == productId);
      if (idx != -1) {
        _demoDb.products[idx] = _demoDb.products[idx].copyWith(basePrice: newPrice);
        await _demoDb.saveProducts();
      }
      return;
    }
    await _supabase
        .from('products')
        .update({'base_price': newPrice}).eq('id', productId);
  }

  Future<void> toggleProductArchive(String productId, bool isActive) async {
    if (AppConfig.isDemoMode) {
      final idx = _demoDb.products.indexWhere((p) => p.id == productId);
      if (idx != -1) {
        _demoDb.products[idx] = _demoDb.products[idx].copyWith(isActive: isActive);
        await _demoDb.saveProducts();
      }
      return;
    }
    await _supabase
        .from('products')
        .update({'is_active': isActive}).eq('id', productId);
  }

  Future<void> adjustVariantStock({
    required String variantId,
    required int delta,
    required String reason,
    double? priceOverride,
    bool updatePriceOverride = false,
  }) async {
    if (AppConfig.isDemoMode) {
      for (var pIdx = 0; pIdx < _demoDb.products.length; pIdx++) {
        final p = _demoDb.products[pIdx];
        final vIdx = p.variants.indexWhere((v) => v.id == variantId);
        if (vIdx != -1) {
          final current = p.variants[vIdx];
          final nextQty =
              (current.stockQty + delta).clamp(current.reservedQty, 999999);
          final actualDelta = nextQty - current.stockQty;
          final updated = current.copyWith(
            stockQty: nextQty,
            priceOverride: updatePriceOverride ? priceOverride : current.priceOverride,
            clearPriceOverride: updatePriceOverride && priceOverride == null,
          );
          final nextVariants = List<ProductVariant>.from(p.variants);
          nextVariants[vIdx] = updated;
          _demoDb.products[pIdx] = p.copyWith(variants: nextVariants);
          if (actualDelta != 0) {
            _demoDb.stockMovements.insert(
              0,
              StockMovement(
                id: _demoDb.nextId('sm'),
                variantId: variantId,
                productName: p.name,
                size: current.size,
                colour: current.colour,
                change: actualDelta,
                reason: reason,
                createdAt: DateTime.now(),
              ),
            );
            await _demoDb.saveMovements();
          }
          await _demoDb.saveProducts();
          return;
        }
      }
      return;
    }

    if (delta != 0) {
      await _supabase.rpc('adjust_variant_stock', params: {
        'p_variant_id': variantId,
        'p_change': delta,
        'p_reason': reason,
      });
    }
    if (updatePriceOverride) {
      await _supabase
          .from('product_variants')
          .update({'price_override': priceOverride}).eq('id', variantId);
    }
  }

  /// Imports stock rows from CSV (`product_slug,size,colour,stock_qty,price_override,sku`).
  Future<int> importStockCsv(String csvContent) async {
    final rows = Validators.parseCsvRows(csvContent);
    var updatedCount = 0;
    final allProducts = await fetchProducts(includeInactive: true);

    for (final row in rows) {
      final slug = row['product_slug'] ?? row['slug'] ?? '';
      final size = row['size'] ?? '';
      final colour = row['colour'] ?? row['color'] ?? '';
      final qty = int.tryParse(row['stock_qty'] ?? row['qty'] ?? '');
      final overrideVal = double.tryParse(row['price_override'] ?? '');
      final sku = row['sku'];

      if (slug.isEmpty || size.isEmpty || colour.isEmpty || qty == null) {
        continue;
      }

      Product? product;
      for (final p in allProducts) {
        if (p.slug.toLowerCase() == slug.toLowerCase()) {
          product = p;
          break;
        }
      }
      if (product == null) continue;

      final existingVariant = product.findVariant(size, colour);
      if (existingVariant != null) {
        final delta = qty - existingVariant.stockQty;
        await adjustVariantStock(
          variantId: existingVariant.id,
          delta: delta,
          reason: 'csv_import',
          priceOverride: overrideVal,
          updatePriceOverride: row.containsKey('price_override'),
        );
        updatedCount++;
      } else {
        final nextVariants = [
          ...product.variants,
          ProductVariant(
            id: '',
            productId: product.id,
            size: size,
            colour: colour,
            sku: sku?.isNotEmpty == true ? sku : null,
            priceOverride: overrideVal,
            stockQty: qty,
          ),
        ];
        await saveProduct(
          existingId: product.id,
          name: product.name,
          categoryId: product.categoryId ?? '',
          description: product.description,
          basePrice: product.basePrice,
          audience: product.audience,
          isActive: product.isActive,
          isFeatured: product.isFeatured,
          imageUrls: product.images.map((e) => e.url).toList(),
          variants: nextVariants,
        );
        updatedCount++;
      }
    }
    return updatedCount;
  }

  Future<List<StockMovement>> fetchStockMovements() async {
    if (AppConfig.isDemoMode) {
      return List<StockMovement>.from(_demoDb.stockMovements);
    }

    final rows = await _supabase
        .from('stock_movements')
        .select('*, product_variants(size, colour, products(name))')
        .order('created_at', ascending: false)
        .limit(100);
    return rows.map(StockMovement.fromJson).toList();
  }

  Future<String> uploadProductImage({
    required String fileName,
    required Uint8List bytes,
    String contentType = 'image/jpeg',
  }) async {
    if (AppConfig.isDemoMode) {
      return 'https://images.unsplash.com/photo-1603487742131-4160ec999306?auto=format&fit=crop&w=900&q=80';
    }
    final safeName =
        '${DateTime.now().millisecondsSinceEpoch}-${fileName.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_')}';
    await _supabase.storage.from('product-images').uploadBinary(
          safeName,
          bytes,
          fileOptions: FileOptions(contentType: contentType),
        );
    return _supabase.storage.from('product-images').getPublicUrl(safeName);
  }
}
