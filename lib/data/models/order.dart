import 'package:flutter/foundation.dart';

import 'enums.dart';

@immutable
class OrderItem {
  const OrderItem({
    required this.id,
    required this.orderId,
    this.variantId,
    this.productId,
    required this.productName,
    this.size,
    this.colour,
    required this.unitPrice,
    required this.quantity,
  });

  final String id;
  final String orderId;
  final String? variantId;
  final String? productId;
  final String productName;
  final String? size;
  final String? colour;
  final double unitPrice;
  final int quantity;

  double get lineTotal => unitPrice * quantity;

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      id: json['id']?.toString() ?? '',
      orderId: json['order_id']?.toString() ?? '',
      variantId: json['variant_id']?.toString(),
      productId: json['product_id']?.toString(),
      productName: json['product_name']?.toString() ?? '',
      size: json['size']?.toString(),
      colour: json['colour']?.toString(),
      unitPrice: (json['unit_price'] as num?)?.toDouble() ?? 0,
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'order_id': orderId,
        'variant_id': variantId,
        'product_id': productId,
        'product_name': productName,
        'size': size,
        'colour': colour,
        'unit_price': unitPrice,
        'quantity': quantity,
      };
}

@immutable
class OrderEvent {
  const OrderEvent({
    required this.id,
    required this.orderId,
    required this.status,
    this.note,
    required this.createdAt,
  });

  final String id;
  final String orderId;
  final OrderStatus status;
  final String? note;
  final DateTime createdAt;

  factory OrderEvent.fromJson(Map<String, dynamic> json) {
    return OrderEvent(
      id: json['id']?.toString() ?? '',
      orderId: json['order_id']?.toString() ?? '',
      status: OrderStatus.fromString(json['status']?.toString()),
      note: json['note']?.toString(),
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'order_id': orderId,
        'status': status.dbValue,
        'note': note,
        'created_at': createdAt.toIso8601String(),
      };
}

@immutable
class Order {
  const Order({
    required this.id,
    required this.orderNumber,
    this.userId,
    required this.trackingToken,
    this.channel = 'website',
    required this.customerName,
    required this.customerPhone,
    this.customerWhatsapp,
    required this.deliveryMethod,
    this.region,
    this.city,
    this.address,
    this.landmark,
    this.notes,
    required this.subtotal,
    this.deliveryFee = 0,
    required this.total,
    this.status = OrderStatus.pendingPayment,
    this.paymentStatus = PaymentStatus.unpaid,
    this.paystackReference,
    this.reservedUntil,
    required this.createdAt,
    this.items = const [],
    this.events = const [],
  });

  final String id;
  final String orderNumber;
  final String? userId;
  final String trackingToken;
  final String channel;
  final String customerName;
  final String customerPhone;
  final String? customerWhatsapp;
  final DeliveryMethod deliveryMethod;
  final String? region;
  final String? city;
  final String? address;
  final String? landmark;
  final String? notes;
  final double subtotal;
  final double deliveryFee;
  final double total;
  final OrderStatus status;
  final PaymentStatus paymentStatus;
  final String? paystackReference;
  final DateTime? reservedUntil;
  final DateTime createdAt;
  final List<OrderItem> items;
  final List<OrderEvent> events;

  Order copyWith({
    OrderStatus? status,
    PaymentStatus? paymentStatus,
    String? paystackReference,
    DateTime? reservedUntil,
    bool clearReservedUntil = false,
    String? notes,
    List<OrderItem>? items,
    List<OrderEvent>? events,
  }) {
    return Order(
      id: id,
      orderNumber: orderNumber,
      userId: userId,
      trackingToken: trackingToken,
      channel: channel,
      customerName: customerName,
      customerPhone: customerPhone,
      customerWhatsapp: customerWhatsapp,
      deliveryMethod: deliveryMethod,
      region: region,
      city: city,
      address: address,
      landmark: landmark,
      notes: notes ?? this.notes,
      subtotal: subtotal,
      deliveryFee: deliveryFee,
      total: total,
      status: status ?? this.status,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      paystackReference: paystackReference ?? this.paystackReference,
      reservedUntil:
          clearReservedUntil ? null : (reservedUntil ?? this.reservedUntil),
      createdAt: createdAt,
      items: items ?? this.items,
      events: events ?? this.events,
    );
  }

  factory Order.fromJson(Map<String, dynamic> json) {
    final rawItems = (json['order_items'] as List<dynamic>?) ?? const [];
    final rawEvents = (json['order_events'] as List<dynamic>?) ?? const [];

    final parsedEvents = rawEvents
        .whereType<Map<String, dynamic>>()
        .map(OrderEvent.fromJson)
        .toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

    return Order(
      id: json['id']?.toString() ?? '',
      orderNumber: json['order_number']?.toString() ?? '',
      userId: json['user_id']?.toString(),
      trackingToken: json['tracking_token']?.toString() ?? '',
      channel: json['channel']?.toString() ?? 'website',
      customerName: json['customer_name']?.toString() ?? '',
      customerPhone: json['customer_phone']?.toString() ?? '',
      customerWhatsapp: json['customer_whatsapp']?.toString(),
      deliveryMethod:
          DeliveryMethod.fromString(json['delivery_method']?.toString()),
      region: json['region']?.toString(),
      city: json['city']?.toString(),
      address: json['address']?.toString(),
      landmark: json['landmark']?.toString(),
      notes: json['notes']?.toString(),
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0,
      deliveryFee: (json['delivery_fee'] as num?)?.toDouble() ?? 0,
      total: (json['total'] as num?)?.toDouble() ?? 0,
      status: OrderStatus.fromString(json['status']?.toString()),
      paymentStatus: PaymentStatus.fromString(json['payment_status']?.toString()),
      paystackReference: json['paystack_reference']?.toString(),
      reservedUntil: json['reserved_until'] != null
          ? DateTime.tryParse(json['reserved_until'].toString())
          : null,
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
      items: rawItems
          .whereType<Map<String, dynamic>>()
          .map(OrderItem.fromJson)
          .toList(),
      events: parsedEvents,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'order_number': orderNumber,
        'user_id': userId,
        'tracking_token': trackingToken,
        'channel': channel,
        'customer_name': customerName,
        'customer_phone': customerPhone,
        'customer_whatsapp': customerWhatsapp,
        'delivery_method': deliveryMethod.dbValue,
        'region': region,
        'city': city,
        'address': address,
        'landmark': landmark,
        'notes': notes,
        'subtotal': subtotal,
        'delivery_fee': deliveryFee,
        'total': total,
        'status': status.dbValue,
        'payment_status': paymentStatus.dbValue,
        'paystack_reference': paystackReference,
        'reserved_until': reservedUntil?.toIso8601String(),
        'created_at': createdAt.toIso8601String(),
        'order_items': items.map((e) => e.toJson()).toList(),
        'order_events': events.map((e) => e.toJson()).toList(),
      };
}

@immutable
class CheckoutRequest {
  const CheckoutRequest({
    required this.items,
    required this.customerName,
    required this.customerPhone,
    this.customerWhatsapp,
    this.customerEmail,
    required this.deliveryMethod,
    this.deliveryZoneId,
    this.region,
    this.city,
    this.address,
    this.landmark,
    this.notes,
  });

  final List<Map<String, dynamic>> items;
  final String customerName;
  final String customerPhone;
  final String? customerWhatsapp;
  final String? customerEmail;
  final DeliveryMethod deliveryMethod;
  final String? deliveryZoneId;
  final String? region;
  final String? city;
  final String? address;
  final String? landmark;
  final String? notes;
}

@immutable
class CreateOrderResult {
  const CreateOrderResult({
    required this.orderId,
    required this.orderNumber,
    required this.trackingToken,
    required this.reference,
    required this.authorizationUrl,
    required this.total,
    this.isDemoCheckout = false,
    this.whatsappUrl,
  });

  final String orderId;
  final String orderNumber;
  final String trackingToken;
  final String reference;
  final String authorizationUrl;
  final double total;
  final bool isDemoCheckout;
  final String? whatsappUrl;
}
