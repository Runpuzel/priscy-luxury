enum AppRole {
  admin('admin', 'Admin'),
  customer('customer', 'Customer');

  const AppRole(this.dbValue, this.label);
  final String dbValue;
  final String label;

  static AppRole fromString(String? raw) {
    return AppRole.values.firstWhere(
      (e) => e.dbValue == raw,
      orElse: () => AppRole.customer,
    );
  }
}

enum OrderStatus {
  pendingPayment('pending_payment', 'Pending Payment', 'Received (Unpaid)'),
  confirmed('confirmed', 'Confirmed', 'Payment Confirmed'),
  processing('processing', 'Processing', 'Being Packed'),
  dispatched('dispatched', 'Dispatched', 'Dispatched'),
  delivered('delivered', 'Delivered', 'Delivered'),
  cancelled('cancelled', 'Cancelled', 'Cancelled');

  const OrderStatus(this.dbValue, this.label, this.customerLabel);
  final String dbValue;
  final String label;
  final String customerLabel;

  static OrderStatus fromString(String? raw) {
    return OrderStatus.values.firstWhere(
      (e) => e.dbValue == raw,
      orElse: () => OrderStatus.pendingPayment,
    );
  }
}

enum PaymentStatus {
  unpaid('unpaid', 'Unpaid'),
  paid('paid', 'Paid'),
  failed('failed', 'Failed');

  const PaymentStatus(this.dbValue, this.label);
  final String dbValue;
  final String label;

  static PaymentStatus fromString(String? raw) {
    return PaymentStatus.values.firstWhere(
      (e) => e.dbValue == raw,
      orElse: () => PaymentStatus.unpaid,
    );
  }
}

enum Audience {
  women('women', 'Women'),
  men('men', 'Men'),
  children('children', 'Children'),
  unisex('unisex', 'Unisex');

  const Audience(this.dbValue, this.label);
  final String dbValue;
  final String label;

  static Audience fromString(String? raw) {
    return Audience.values.firstWhere(
      (e) => e.dbValue == raw,
      orElse: () => Audience.unisex,
    );
  }
}

enum DeliveryMethod {
  delivery('delivery', 'Doorstep / Parcel Delivery'),
  pickup('pickup', 'Showroom Pickup (Kumasi)');

  const DeliveryMethod(this.dbValue, this.label);
  final String dbValue;
  final String label;

  static DeliveryMethod fromString(String? raw) {
    return DeliveryMethod.values.firstWhere(
      (e) => e.dbValue == raw,
      orElse: () => DeliveryMethod.delivery,
    );
  }
}

enum CatalogueSort {
  newest('newest', 'Newest First'),
  bestSelling('best_selling', 'Best Selling'),
  priceLowToHigh('price_asc', 'Price: Low to High'),
  priceHighToLow('price_desc', 'Price: High to Low');

  const CatalogueSort(this.queryValue, this.label);
  final String queryValue;
  final String label;

  static CatalogueSort fromString(String? raw) {
    return CatalogueSort.values.firstWhere(
      (e) => e.queryValue == raw,
      orElse: () => CatalogueSort.bestSelling,
    );
  }
}
