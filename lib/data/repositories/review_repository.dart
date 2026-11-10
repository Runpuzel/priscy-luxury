import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/config/app_config.dart';
import '../../core/utils/validators.dart';
import '../models/models.dart';
import 'demo_database.dart';

class ReviewRepository {
  ReviewRepository({required DemoDatabase demoDb}) : _demoDb = demoDb;

  final DemoDatabase _demoDb;
  SupabaseClient get _supabase => Supabase.instance.client;

  Future<List<Review>> fetchApprovedReviews(String productId) async {
    if (AppConfig.isDemoMode) {
      return _demoDb.reviews
          .where((r) => r.productId == productId && r.isApproved)
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }

    final rows = await _supabase
        .from('reviews')
        .select('*, products(name)')
        .eq('product_id', productId)
        .eq('is_approved', true)
        .order('created_at', ascending: false);
    return rows.map(Review.fromJson).toList();
  }

  Future<List<Review>> fetchUserReviews(String userId) async {
    if (AppConfig.isDemoMode) {
      return _demoDb.reviews.where((r) => r.userId == userId).toList();
    }

    final rows = await _supabase
        .from('reviews')
        .select('*, products(name)')
        .eq('user_id', userId)
        .order('created_at', ascending: false);
    return rows.map(Review.fromJson).toList();
  }

  /// Submits a review after verifying the buyer purchased the product (`submit-review` Edge Function).
  Future<void> submitVerifiedReview({
    required String productId,
    required String productName,
    required String orderNumber,
    required String phone,
    required String reviewerName,
    required int rating,
    required String comment,
    String? userId,
  }) async {
    if (AppConfig.isDemoMode) {
      final normalizedOrder = orderNumber.trim().toUpperCase();
      final normalizedPhone = Validators.normalizeGhanaPhone(phone);

      Order? matchedOrder;
      for (final o in _demoDb.orders) {
        if (o.orderNumber.toUpperCase() == normalizedOrder &&
            o.paymentStatus == PaymentStatus.paid &&
            Validators.normalizeGhanaPhone(o.customerPhone) == normalizedPhone) {
          matchedOrder = o;
          break;
        }
      }

      if (matchedOrder == null) {
        throw StateError(
          'Only verified buyers with a paid order matching this phone number can review.',
        );
      }

      final boughtProduct = matchedOrder.items.any(
        (i) => i.productId == productId || i.productName == productName,
      );
      if (!boughtProduct) {
        throw StateError('Order $normalizedOrder does not contain this style.');
      }

      _demoDb.reviews.insert(
        0,
        Review(
          id: _demoDb.nextId('rev'),
          productId: productId,
          productName: productName,
          orderId: matchedOrder.id,
          userId: userId,
          reviewerName: reviewerName.trim(),
          rating: rating.clamp(1, 5),
          comment: comment.trim(),
          isApproved: false,
          createdAt: DateTime.now(),
        ),
      );
      await _demoDb.saveReviews();
      return;
    }

    final response = await _supabase.functions.invoke(
      'submit-review',
      body: {
        'product_id': productId,
        'order_number': orderNumber.trim().toUpperCase(),
        'phone': phone.trim(),
        'reviewer_name': reviewerName.trim(),
        'rating': rating,
        'comment': comment.trim(),
      },
    );

    final data = response.data as Map<String, dynamic>?;
    if (response.status >= 400 || data?['error'] != null) {
      throw Exception(data?['error'] ?? 'Could not submit review');
    }
  }

  // Admin moderation methods
  Future<List<Review>> fetchAllReviewsForAdmin() async {
    if (AppConfig.isDemoMode) {
      final list = List<Review>.from(_demoDb.reviews)
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    }

    final rows = await _supabase
        .from('reviews')
        .select('*, products(name)')
        .order('created_at', ascending: false);
    return rows.map(Review.fromJson).toList();
  }

  Future<void> setReviewApproval(String reviewId, bool isApproved) async {
    if (AppConfig.isDemoMode) {
      final idx = _demoDb.reviews.indexWhere((r) => r.id == reviewId);
      if (idx != -1) {
        _demoDb.reviews[idx] =
            _demoDb.reviews[idx].copyWith(isApproved: isApproved);
        await _demoDb.saveReviews();
      }
      return;
    }
    await _supabase
        .from('reviews')
        .update({'is_approved': isApproved}).eq('id', reviewId);
  }

  Future<void> deleteReview(String reviewId) async {
    if (AppConfig.isDemoMode) {
      _demoDb.reviews.removeWhere((r) => r.id == reviewId);
      await _demoDb.saveReviews();
      return;
    }
    await _supabase.from('reviews').delete().eq('id', reviewId);
  }
}
