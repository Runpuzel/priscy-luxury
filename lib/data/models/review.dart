import 'package:flutter/foundation.dart';

@immutable
class Review {
  const Review({
    required this.id,
    required this.productId,
    this.productName,
    this.orderId,
    this.userId,
    required this.reviewerName,
    required this.rating,
    this.comment = '',
    this.isApproved = false,
    required this.createdAt,
  });

  final String id;
  final String productId;
  final String? productName;
  final String? orderId;
  final String? userId;
  final String reviewerName;
  final int rating;
  final String comment;
  final bool isApproved;
  final DateTime createdAt;

  Review copyWith({
    bool? isApproved,
    String? comment,
    int? rating,
  }) {
    return Review(
      id: id,
      productId: productId,
      productName: productName,
      orderId: orderId,
      userId: userId,
      reviewerName: reviewerName,
      rating: rating ?? this.rating,
      comment: comment ?? this.comment,
      isApproved: isApproved ?? this.isApproved,
      createdAt: createdAt,
    );
  }

  factory Review.fromJson(Map<String, dynamic> json) {
    final prodMap = json['products'] as Map<String, dynamic>?;
    return Review(
      id: json['id']?.toString() ?? '',
      productId: json['product_id']?.toString() ?? '',
      productName:
          prodMap?['name']?.toString() ?? json['product_name']?.toString(),
      orderId: json['order_id']?.toString(),
      userId: json['user_id']?.toString(),
      reviewerName: json['reviewer_name']?.toString() ?? 'Verified Buyer',
      rating: ((json['rating'] as num?)?.toInt() ?? 5).clamp(1, 5),
      comment: json['comment']?.toString() ?? '',
      isApproved: json['is_approved'] as bool? ?? false,
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'product_id': productId,
        'product_name': productName,
        'order_id': orderId,
        'user_id': userId,
        'reviewer_name': reviewerName,
        'rating': rating,
        'comment': comment,
        'is_approved': isApproved,
        'created_at': createdAt.toIso8601String(),
      };
}
