import 'package:flutter/foundation.dart';

@immutable
class DeliveryZone {
  const DeliveryZone({
    required this.id,
    required this.region,
    this.city,
    required this.fee,
    this.estDaysMin = 3,
    this.estDaysMax = 5,
    this.isActive = true,
  });

  final String id;
  final String region;
  final String? city;
  final double fee;
  final int estDaysMin;
  final int estDaysMax;
  final bool isActive;

  String get displayName =>
      (city != null && city!.trim().isNotEmpty) ? '$region — $city' : region;

  String get estimatedWindow =>
      estDaysMin == estDaysMax ? '$estDaysMin days' : '$estDaysMin to $estDaysMax days';

  DeliveryZone copyWith({
    String? id,
    String? region,
    String? city,
    double? fee,
    int? estDaysMin,
    int? estDaysMax,
    bool? isActive,
  }) {
    return DeliveryZone(
      id: id ?? this.id,
      region: region ?? this.region,
      city: city ?? this.city,
      fee: fee ?? this.fee,
      estDaysMin: estDaysMin ?? this.estDaysMin,
      estDaysMax: estDaysMax ?? this.estDaysMax,
      isActive: isActive ?? this.isActive,
    );
  }

  factory DeliveryZone.fromJson(Map<String, dynamic> json) {
    return DeliveryZone(
      id: json['id']?.toString() ?? '',
      region: json['region']?.toString() ?? '',
      city: json['city']?.toString(),
      fee: (json['fee'] as num?)?.toDouble() ?? 0,
      estDaysMin: (json['est_days_min'] as num?)?.toInt() ?? 3,
      estDaysMax: (json['est_days_max'] as num?)?.toInt() ?? 5,
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'region': region,
        'city': city,
        'fee': fee,
        'est_days_min': estDaysMin,
        'est_days_max': estDaysMax,
        'is_active': isActive,
      };
}
