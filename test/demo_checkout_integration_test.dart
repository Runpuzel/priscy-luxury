import 'package:flutter_test/flutter_test.dart';
import 'package:priscy_store/data/models/models.dart';
import 'package:priscy_store/data/repositories/demo_database.dart';
import 'package:priscy_store/data/repositories/order_repository.dart';
import 'package:priscy_store/data/repositories/product_repository.dart';
import 'package:priscy_store/data/repositories/review_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('Full checkout, Paystack MoMo confirmation, guest tracking & verified review flow', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final demoDb = DemoDatabase(prefs);
    final productRepo = ProductRepository(demoDb: demoDb);
    final orderRepo = OrderRepository(demoDb: demoDb);
    final reviewRepo = ReviewRepository(demoDb: demoDb);

    final products = await productRepo.fetchProducts();
    expect(products.length, 20);

    final targetProduct = products.first;
    final targetVariant =
        targetProduct.variants.firstWhere((v) => v.availableQty >= 2);
    final initialStock = targetVariant.stockQty;

    // 1. Start checkout -> reserves 2 pairs for 15 minutes
    final result = await orderRepo.createOrder(
      CheckoutRequest(
        items: [
          {'variant_id': targetVariant.id, 'quantity': 2},
        ],
        customerName: 'Ama Serwaa',
        customerPhone: '0551122334',
        deliveryMethod: DeliveryMethod.delivery,
        deliveryZoneId: 'zone-kumasi',
        region: 'Ashanti Region',
        city: 'Kumasi',
        address: 'KNUST Commercial Area',
      ),
    );

    final afterReserve =
        (await productRepo.fetchProductById(targetProduct.id))!
            .variants
            .firstWhere((v) => v.id == targetVariant.id);
    expect(afterReserve.reservedQty, 2);
    expect(afterReserve.availableQty, initialStock - 2);

    // 2. Confirm Mobile Money payment (idempotent even if called twice)
    final paidOrder = await orderRepo.confirmDemoPayment(result.reference);
    final duplicateCall = await orderRepo.confirmDemoPayment(result.reference);
    expect(paidOrder.status, OrderStatus.confirmed);
    expect(paidOrder.paymentStatus, PaymentStatus.paid);
    expect(duplicateCall.id, paidOrder.id);

    final afterPay = (await productRepo.fetchProductById(targetProduct.id))!
        .variants
        .firstWhere((v) => v.id == targetVariant.id);
    expect(afterPay.stockQty, initialStock - 2);
    expect(afterPay.reservedQty, 0);

    // 3. Guest order tracking by orderNumber + Ghana phone
    final tracked = await orderRepo.trackOrder(
      orderNumber: result.orderNumber,
      phone: '+233 55 112 2334',
    );
    expect(tracked, isNotNull);
    expect(tracked!.orderNumber, result.orderNumber);

    // 4. Verified buyer review submission + owner moderation
    await reviewRepo.submitVerifiedReview(
      productId: targetProduct.id,
      productName: targetProduct.name,
      orderNumber: result.orderNumber,
      phone: '0551122334',
      reviewerName: 'Ama Serwaa',
      rating: 5,
      comment: 'Super comfortable slippers!',
    );

    final allAdminReviews = await reviewRepo.fetchAllReviewsForAdmin();
    final newlySubmitted = allAdminReviews.firstWhere(
      (r) => r.reviewerName == 'Ama Serwaa',
    );
    expect(newlySubmitted.isApproved, isFalse);

    await reviewRepo.setReviewApproval(newlySubmitted.id, true);
    final approvedReviews =
        await reviewRepo.fetchApprovedReviews(targetProduct.id);
    expect(approvedReviews.any((r) => r.id == newlySubmitted.id), isTrue);

    // 5. Cancel before dispatch -> restores stock automatically
    await orderRepo.updateOrderStatus(
      orderId: paidOrder.id,
      newStatus: OrderStatus.cancelled,
      trackingNote: 'Customer requested size swap before dispatch',
    );
    final afterCancel = (await productRepo.fetchProductById(targetProduct.id))!
        .variants
        .firstWhere((v) => v.id == targetVariant.id);
    expect(afterCancel.stockQty, initialStock);
  });
}
