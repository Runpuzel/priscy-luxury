import 'package:flutter/foundation.dart';

import 'product.dart';

@immutable
class LowStockAlertItem {
  const LowStockAlertItem({
    required this.product,
    required this.variant,
  });

  final Product product;
  final ProductVariant variant;
}

@immutable
class DailySalesPoint {
  const DailySalesPoint({
    required this.date,
    required this.label,
    required this.revenue,
    required this.orderCount,
  });

  final DateTime date;
  final String label;
  final double revenue;
  final int orderCount;
}

@immutable
class ProductSalesSummary {
  const ProductSalesSummary({
    required this.productName,
    required this.unitsSold,
    required this.revenue,
  });

  final String productName;
  final int unitsSold;
  final double revenue;
}

@immutable
class CategorySalesSummary {
  const CategorySalesSummary({
    required this.categoryName,
    required this.unitsSold,
    required this.revenue,
  });

  final String categoryName;
  final int unitsSold;
  final double revenue;
}

@immutable
class DashboardMetrics {
  const DashboardMetrics({
    required this.todaysOrders,
    required this.revenueThisWeek,
    required this.revenueThisMonth,
    required this.pendingOrdersCount,
    required this.lowStockItems,
    required this.bestSellers,
    required this.dailySales,
    required this.salesByProduct,
    required this.salesByCategory,
  });

  final int todaysOrders;
  final double revenueThisWeek;
  final double revenueThisMonth;
  final int pendingOrdersCount;
  final List<LowStockAlertItem> lowStockItems;
  final List<Product> bestSellers;
  final List<DailySalesPoint> dailySales;
  final List<ProductSalesSummary> salesByProduct;
  final List<CategorySalesSummary> salesByCategory;
}
