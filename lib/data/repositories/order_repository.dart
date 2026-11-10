import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/config/app_config.dart';
import '../../core/utils/stock_calculator.dart';
import '../../core/utils/whatsapp_helper.dart';
import '../models/models.dart';
import 'demo_database.dart';

class OrderRepository {
  OrderRepository({required DemoDatabase demoDb}) : _demoDb = demoDb;

  final DemoDatabase _demoDb;
  SupabaseClient get _supabase => Supabase.instance.client;

  /// Creates an order via the `create-order` Edge Function (live) or
  /// atomically reserves stock in DemoDatabase (demo mode).
  Future<CreateOrderResult> createOrder(
    CheckoutRequest request, {
    String? userId,
  }) async {
    if (AppConfig.isDemoMode) {
      return _createDemoOrder(
        request,
        userId: userId,
        channel: 'website',
      );
    }

    final response = await _supabase.functions.invoke(
      'create-order',
      body: {
        'items': request.items,
        'customer_name': request.customerName,
        'customer_phone': request.customerPhone,
        'customer_whatsapp': request.customerWhatsapp ?? request.customerPhone,
        'customer_email': request.customerEmail,
        'delivery_method': request.deliveryMethod.dbValue,
        'delivery_zone_id': request.deliveryZoneId,
        'region': request.region,
        'city': request.city,
        'address': request.address,
        'landmark': request.landmark,
        'notes': request.notes,
        'callback_base_url': Uri.base.origin,
      },
    );

    final data = response.data as Map<String, dynamic>?;
    if (response.status >= 400 || data == null || data['error'] != null) {
      throw Exception(data?['error'] ?? 'Could not create order');
    }

    return CreateOrderResult(
      orderId: data['order_id']?.toString() ?? '',
      orderNumber: data['order_number']?.toString() ?? '',
      trackingToken: data['tracking_token']?.toString() ?? '',
      reference: data['reference']?.toString() ?? '',
      authorizationUrl: data['authorization_url']?.toString() ?? '',
      total: (data['total'] as num?)?.toDouble() ?? 0,
      isDemoCheckout: false,
    );
  }

  /// Admin manual WhatsApp order creation (`create-manual-order` Edge Function).
  Future<CreateOrderResult> createManualOrder(
    CheckoutRequest request, {
    bool markPaidImmediately = false,
  }) async {
    if (AppConfig.isDemoMode) {
      final result = await _createDemoOrder(
        request,
        channel: 'whatsapp_manual',
      );
      if (markPaidImmediately) {
        await confirmDemoPayment(result.reference);
      }
      final order = _demoDb.orders.firstWhere((o) => o.id == result.orderId);
      final waUrl = WhatsAppHelper.buildAdminOrderStatusUpdateUrl(
        order: order,
        customPaymentUrl: result.authorizationUrl,
      );
      return CreateOrderResult(
        orderId: result.orderId,
        orderNumber: result.orderNumber,
        trackingToken: result.trackingToken,
        reference: result.reference,
        authorizationUrl: result.authorizationUrl,
        total: result.total,
        isDemoCheckout: true,
        whatsappUrl: waUrl,
      );
    }

    final response = await _supabase.functions.invoke(
      'create-manual-order',
      body: {
        'items': request.items,
        'customer_name': request.customerName,
        'customer_phone': request.customerPhone,
        'customer_whatsapp': request.customerWhatsapp ?? request.customerPhone,
        'delivery_method': request.deliveryMethod.dbValue,
        'delivery_zone_id': request.deliveryZoneId,
        'region': request.region,
        'city': request.city,
        'address': request.address,
        'landmark': request.landmark,
        'notes': request.notes,
        'mark_paid_immediately': markPaidImmediately,
      },
    );

    final data = response.data as Map<String, dynamic>?;
    if (response.status >= 400 || data == null || data['error'] != null) {
      throw Exception(data?['error'] ?? 'Could not create manual order');
    }

    return CreateOrderResult(
      orderId: data['order_id']?.toString() ?? '',
      orderNumber: data['order_number']?.toString() ?? '',
      trackingToken: data['tracking_token']?.toString() ?? '',
      reference: '',
      authorizationUrl: data['payment_url']?.toString() ?? '',
      total: (data['total'] as num?)?.toDouble() ?? 0,
      whatsappUrl: data['whatsapp_url']?.toString(),
    );
  }

  Future<CreateOrderResult> _createDemoOrder(
    CheckoutRequest request, {
    String? userId,
    required String channel,
  }) async {
    _demoDb.releaseExpiredReservations();

    DeliveryZone? zone;
    if (request.deliveryMethod == DeliveryMethod.delivery) {
      for (final z in _demoDb.deliveryZones) {
        if (z.id == request.deliveryZoneId || z.region == request.region) {
          zone = z;
          break;
        }
      }
      zone ??= _demoDb.deliveryZones.first;
    }

    final orderId = _demoDb.nextId('ord');
    final orderNumber = _demoDb.nextOrderNumber();
    final trackingToken = _demoDb.nextId('tok');
    final reference = '$orderNumber-MOMO';
    final orderItems = <OrderItem>[];
    var subtotal = 0.0;

    // Validate & reserve each variant
    for (final line in request.items) {
      final variantId = line['variant_id']?.toString() ?? '';
      final qty = (line['quantity'] as num?)?.toInt() ?? 1;

      Product? foundProduct;
      ProductVariant? foundVariant;
      var pIndex = -1;
      var vIndex = -1;

      for (var pi = 0; pi < _demoDb.products.length; pi++) {
        final vi =
            _demoDb.products[pi].variants.indexWhere((v) => v.id == variantId);
        if (vi != -1) {
          foundProduct = _demoDb.products[pi];
          foundVariant = foundProduct.variants[vi];
          pIndex = pi;
          vIndex = vi;
          break;
        }
      }

      if (foundProduct == null || foundVariant == null) {
        throw StateError('Selected footwear variant is no longer available.');
      }

      final reservedVariant =
          StockAndPricingCalculator.reserveStock(foundVariant, qty);
      final updatedVariants =
          List<ProductVariant>.from(foundProduct.variants);
      updatedVariants[vIndex] = reservedVariant;
      _demoDb.products[pIndex] =
          foundProduct.copyWith(variants: updatedVariants);

      final unitPrice =
          StockAndPricingCalculator.unitPriceForVariant(foundProduct, foundVariant);
      subtotal += unitPrice * qty;

      orderItems.add(
        OrderItem(
          id: _demoDb.nextId('oi'),
          orderId: orderId,
          variantId: foundVariant.id,
          productId: foundProduct.id,
          productName: foundProduct.name,
          size: foundVariant.size,
          colour: foundVariant.colour,
          unitPrice: unitPrice,
          quantity: qty,
        ),
      );
    }

    final deliveryFee =
        request.deliveryMethod == DeliveryMethod.pickup ? 0.0 : (zone?.fee ?? 0.0);
    final total = double.parse((subtotal + deliveryFee).toStringAsFixed(2));
    final now = DateTime.now();

    final order = Order(
      id: orderId,
      orderNumber: orderNumber,
      userId: userId,
      trackingToken: trackingToken,
      channel: channel,
      customerName: request.customerName.trim(),
      customerPhone: request.customerPhone.trim(),
      customerWhatsapp: (request.customerWhatsapp?.trim().isNotEmpty ?? false)
          ? request.customerWhatsapp!.trim()
          : request.customerPhone.trim(),
      deliveryMethod: request.deliveryMethod,
      region: request.deliveryMethod == DeliveryMethod.pickup
          ? 'Ashanti Region'
          : (request.region ?? zone?.region),
      city: request.deliveryMethod == DeliveryMethod.pickup
          ? 'Kumasi Pickup'
          : (request.city ?? zone?.city),
      address: request.address,
      landmark: request.landmark,
      notes: request.notes,
      subtotal: double.parse(subtotal.toStringAsFixed(2)),
      deliveryFee: deliveryFee,
      total: total,
      status: OrderStatus.pendingPayment,
      paymentStatus: PaymentStatus.unpaid,
      paystackReference: reference,
      reservedUntil:
          now.add(const Duration(minutes: AppConfig.reservationMinutes)),
      createdAt: now,
      items: orderItems,
      events: [
        OrderEvent(
          id: _demoDb.nextId('ev'),
          orderId: orderId,
          status: OrderStatus.pendingPayment,
          note: 'Order created ($channel) — stock reserved for 15 minutes',
          createdAt: now,
        ),
      ],
    );

    _demoDb.orders.insert(0, order);
    await _demoDb.saveProducts();
    await _demoDb.saveOrders();

    final demoPayUrl =
        '/checkout/paystack-demo?ref=${Uri.encodeComponent(reference)}&order=${Uri.encodeComponent(orderNumber)}&token=${Uri.encodeComponent(trackingToken)}';

    return CreateOrderResult(
      orderId: orderId,
      orderNumber: orderNumber,
      trackingToken: trackingToken,
      reference: reference,
      authorizationUrl: demoPayUrl,
      total: total,
      isDemoCheckout: true,
    );
  }

  /// Simulates the Paystack `charge.success` webhook in Demo Mode:
  /// confirms payment, deducts physical stock, releases reservation, and logs `stock_movements`.
  Future<Order> confirmDemoPayment(String reference) async {
    final idx =
        _demoDb.orders.indexWhere((o) => o.paystackReference == reference);
    if (idx == -1) {
      throw StateError('Order not found for reference $reference');
    }
    final order = _demoDb.orders[idx];
    if (order.paymentStatus == PaymentStatus.paid) {
      return order;
    }

    for (final item in order.items) {
      if (item.variantId == null) continue;
      for (var pi = 0; pi < _demoDb.products.length; pi++) {
        final p = _demoDb.products[pi];
        final vi = p.variants.indexWhere((v) => v.id == item.variantId);
        if (vi != -1) {
          final updatedVariant = StockAndPricingCalculator.confirmReservedSale(
            p.variants[vi],
            item.quantity,
          );
          final nextVariants = List<ProductVariant>.from(p.variants);
          nextVariants[vi] = updatedVariant;
          _demoDb.products[pi] = p.copyWith(
            variants: nextVariants,
            unitsSold: p.unitsSold + item.quantity,
          );
          _demoDb.stockMovements.insert(
            0,
            StockMovement(
              id: _demoDb.nextId('sm'),
              variantId: item.variantId!,
              productName: p.name,
              size: item.size,
              colour: item.colour,
              change: -item.quantity,
              reason: 'sale:${order.orderNumber}',
              createdAt: DateTime.now(),
            ),
          );
          break;
        }
      }
    }

    final updatedOrder = order.copyWith(
      paymentStatus: PaymentStatus.paid,
      status: OrderStatus.confirmed,
      clearReservedUntil: true,
      events: [
        ...order.events,
        OrderEvent(
          id: _demoDb.nextId('ev'),
          orderId: order.id,
          status: OrderStatus.confirmed,
          note: 'Mobile Money payment confirmed via Paystack',
          createdAt: DateTime.now(),
        ),
      ],
    );

    _demoDb.orders[idx] = updatedOrder;
    await _demoDb.saveProducts();
    await _demoDb.saveMovements();
    await _demoDb.saveOrders();
    return updatedOrder;
  }

  Future<Order?> trackOrder({
    String? orderNumber,
    String? phone,
    String? trackingToken,
    String? reference,
  }) async {
    if (AppConfig.isDemoMode) {
      return _demoDb.findTrackableOrder(
        orderNumber: orderNumber,
        phone: phone,
        trackingToken: trackingToken,
        reference: reference,
      );
    }

    final response = await _supabase.functions.invoke(
      'track-order',
      body: {
        if (orderNumber != null) 'order_number': orderNumber,
        if (phone != null) 'phone': phone,
        if (trackingToken != null) 'tracking_token': trackingToken,
        if (reference != null) 'reference': reference,
      },
    );

    if (response.status >= 400) return null;
    final data = response.data as Map<String, dynamic>?;
    final orderJson = data?['order'] as Map<String, dynamic>?;
    if (orderJson == null) return null;
    return Order.fromJson(orderJson);
  }

  Future<List<Order>> fetchCustomerOrders(String userId) async {
    if (AppConfig.isDemoMode) {
      return _demoDb.orders.where((o) => o.userId == userId).toList();
    }

    final rows = await _supabase
        .from('orders')
        .select('*, order_items(*), order_events(*)')
        .eq('user_id', userId)
        .order('created_at', ascending: false);
    return rows.map(Order.fromJson).toList();
  }

  Future<List<Order>> fetchAdminOrders({OrderStatus? statusFilter}) async {
    if (AppConfig.isDemoMode) {
      _demoDb.releaseExpiredReservations();
      if (statusFilter == null) return List<Order>.from(_demoDb.orders);
      return _demoDb.orders.where((o) => o.status == statusFilter).toList();
    }

    var query =
        _supabase.from('orders').select('*, order_items(*), order_events(*)');
    if (statusFilter != null) {
      query = query.eq('status', statusFilter.dbValue);
    }
    final rows = await query.order('created_at', ascending: false);
    return rows.map(Order.fromJson).toList();
  }

  Future<Order?> fetchAdminOrderById(String orderId) async {
    final orders = await fetchAdminOrders();
    for (final o in orders) {
      if (o.id == orderId || o.orderNumber == orderId) return o;
    }
    return null;
  }

  Future<Order> updateOrderStatus({
    required String orderId,
    required OrderStatus newStatus,
    String? trackingNote,
  }) async {
    if (AppConfig.isDemoMode) {
      final idx = _demoDb.orders.indexWhere((o) => o.id == orderId);
      if (idx == -1) throw StateError('Order not found');
      final current = _demoDb.orders[idx];

      // Section 7: Restore stock automatically if an order is cancelled before dispatch
      if (newStatus == OrderStatus.cancelled &&
          current.status != OrderStatus.cancelled &&
          current.status != OrderStatus.dispatched &&
          current.status != OrderStatus.delivered) {
        for (final item in current.items) {
          if (item.variantId == null) continue;
          for (var pi = 0; pi < _demoDb.products.length; pi++) {
            final p = _demoDb.products[pi];
            final vi = p.variants.indexWhere((v) => v.id == item.variantId);
            if (vi != -1) {
              final nextVariant = current.paymentStatus == PaymentStatus.paid
                  ? StockAndPricingCalculator.restoreCancelledPaidOrder(
                      p.variants[vi],
                      item.quantity,
                    )
                  : StockAndPricingCalculator.releaseUnpaidReservation(
                      p.variants[vi],
                      item.quantity,
                    );
              final nextVariants = List<ProductVariant>.from(p.variants);
              nextVariants[vi] = nextVariant;
              _demoDb.products[pi] = p.copyWith(variants: nextVariants);

              if (current.paymentStatus == PaymentStatus.paid) {
                _demoDb.stockMovements.insert(
                  0,
                  StockMovement(
                    id: _demoDb.nextId('sm'),
                    variantId: item.variantId!,
                    productName: p.name,
                    size: item.size,
                    colour: item.colour,
                    change: item.quantity,
                    reason: 'cancel:${current.orderNumber}',
                    createdAt: DateTime.now(),
                  ),
                );
              }
              break;
            }
          }
        }
        await _demoDb.saveProducts();
        await _demoDb.saveMovements();
      }

      final updated = current.copyWith(
        status: newStatus,
        clearReservedUntil: newStatus == OrderStatus.cancelled,
        events: [
          ...current.events,
          OrderEvent(
            id: _demoDb.nextId('ev'),
            orderId: current.id,
            status: newStatus,
            note: (trackingNote != null && trackingNote.trim().isNotEmpty)
                ? trackingNote.trim()
                : 'Status updated to ${newStatus.label}',
            createdAt: DateTime.now(),
          ),
        ],
      );
      _demoDb.orders[idx] = updated;
      await _demoDb.saveOrders();
      return updated;
    }

    if (newStatus == OrderStatus.cancelled) {
      await _supabase.rpc('cancel_order_and_release_stock', params: {
        'p_order_id': orderId,
        'p_reason': trackingNote ?? 'cancelled_by_admin',
      });
    } else {
      await _supabase
          .from('orders')
          .update({'status': newStatus.dbValue}).eq('id', orderId);
    }

    if (trackingNote != null && trackingNote.trim().isNotEmpty) {
      await _supabase.from('order_events').insert({
        'order_id': orderId,
        'status': newStatus.dbValue,
        'note': trackingNote.trim(),
      });
    }

    return (await fetchAdminOrderById(orderId))!;
  }

  Future<DashboardMetrics> computeDashboardMetrics(
    List<Product> products,
    int lowStockThreshold,
  ) async {
    final allOrders = await fetchAdminOrders();
    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);
    final startOfWeek = now.subtract(const Duration(days: 7));
    final startOfMonth = DateTime(now.year, now.month, 1);

    final paidOrders =
        allOrders.where((o) => o.paymentStatus == PaymentStatus.paid).toList();

    final todaysOrders = allOrders
        .where((o) => !o.createdAt.isBefore(startOfToday))
        .length;

    final revenueThisWeek = paidOrders
        .where((o) => !o.createdAt.isBefore(startOfWeek))
        .fold<double>(0, (s, o) => s + o.total);

    final revenueThisMonth = paidOrders
        .where((o) => !o.createdAt.isBefore(startOfMonth))
        .fold<double>(0, (s, o) => s + o.total);

    final pendingOrdersCount = allOrders
        .where(
          (o) =>
              o.status == OrderStatus.confirmed ||
              o.status == OrderStatus.processing,
        )
        .length;

    final lowStockItems = <LowStockAlertItem>[];
    for (final p in products) {
      if (!p.isActive) continue;
      for (final v in p.variants) {
        if (v.availableQty <= lowStockThreshold) {
          lowStockItems.add(LowStockAlertItem(product: p, variant: v));
        }
      }
    }
    lowStockItems.sort(
      (a, b) => a.variant.availableQty.compareTo(b.variant.availableQty),
    );

    final bestSellers = List<Product>.from(products)
      ..sort((a, b) => b.unitsSold.compareTo(a.unitsSold));

    // Last 7 days daily sales points for fl_chart
    final dayFormat = DateFormat('EEE');
    final dailySales = <DailySalesPoint>[];
    for (var d = 6; d >= 0; d--) {
      final dayStart =
          DateTime(now.year, now.month, now.day).subtract(Duration(days: d));
      final dayEnd = dayStart.add(const Duration(days: 1));
      final dayOrders = paidOrders.where(
        (o) => !o.createdAt.isBefore(dayStart) && o.createdAt.isBefore(dayEnd),
      );
      dailySales.add(
        DailySalesPoint(
          date: dayStart,
          label: dayFormat.format(dayStart),
          revenue: dayOrders.fold<double>(0, (s, o) => s + o.total),
          orderCount: dayOrders.length,
        ),
      );
    }

    // Sales by product & by category
    final productMap = <String, ProductSalesSummary>{};
    final categoryLookup = <String, String>{
      for (final p in products) p.name: p.categoryName ?? 'Footwear',
    };
    final categoryMap = <String, CategorySalesSummary>{};

    for (final order in paidOrders) {
      for (final item in order.items) {
        final prevProd = productMap[item.productName];
        productMap[item.productName] = ProductSalesSummary(
          productName: item.productName,
          unitsSold: (prevProd?.unitsSold ?? 0) + item.quantity,
          revenue: (prevProd?.revenue ?? 0) + item.lineTotal,
        );

        final catName = categoryLookup[item.productName] ?? 'Footwear';
        final prevCat = categoryMap[catName];
        categoryMap[catName] = CategorySalesSummary(
          categoryName: catName,
          unitsSold: (prevCat?.unitsSold ?? 0) + item.quantity,
          revenue: (prevCat?.revenue ?? 0) + item.lineTotal,
        );
      }
    }

    final salesByProduct = productMap.values.toList()
      ..sort((a, b) => b.revenue.compareTo(a.revenue));
    final salesByCategory = categoryMap.values.toList()
      ..sort((a, b) => b.revenue.compareTo(a.revenue));

    return DashboardMetrics(
      todaysOrders: todaysOrders,
      revenueThisWeek: revenueThisWeek,
      revenueThisMonth: revenueThisMonth,
      pendingOrdersCount: pendingOrdersCount,
      lowStockItems: lowStockItems,
      bestSellers: bestSellers.take(6).toList(),
      dailySales: dailySales,
      salesByProduct: salesByProduct,
      salesByCategory: salesByCategory,
    );
  }
}
