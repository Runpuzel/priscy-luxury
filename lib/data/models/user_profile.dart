import 'package:flutter/foundation.dart';

import 'enums.dart';

@immutable
class UserProfile {
  const UserProfile({
    required this.id,
    this.email,
    required this.fullName,
    required this.phone,
    this.role = AppRole.customer,
    this.createdAt,
  });

  final String id;
  final String? email;
  final String fullName;
  final String phone;
  final AppRole role;
  final DateTime? createdAt;

  bool get isAdmin => role == AppRole.admin;

  UserProfile copyWith({
    String? fullName,
    String? phone,
    String? email,
    AppRole? role,
  }) {
    return UserProfile(
      id: id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      createdAt: createdAt,
    );
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id']?.toString() ?? '',
      email: json['email']?.toString(),
      fullName: json['full_name']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      role: AppRole.fromString(json['role']?.toString()),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'full_name': fullName,
        'phone': phone,
        'role': role.dbValue,
        'created_at': createdAt?.toIso8601String(),
      };
}

@immutable
class SavedAddress {
  const SavedAddress({
    required this.id,
    required this.userId,
    this.label = 'Home',
    required this.recipientName,
    required this.phone,
    required this.region,
    required this.city,
    required this.address,
    this.landmark,
    this.isDefault = false,
  });

  final String id;
  final String userId;
  final String label;
  final String recipientName;
  final String phone;
  final String region;
  final String city;
  final String address;
  final String? landmark;
  final bool isDefault;

  factory SavedAddress.fromJson(Map<String, dynamic> json) {
    return SavedAddress(
      id: json['id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      label: json['label']?.toString() ?? 'Home',
      recipientName: json['recipient_name']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      region: json['region']?.toString() ?? '',
      city: json['city']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      landmark: json['landmark']?.toString(),
      isDefault: json['is_default'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'label': label,
        'recipient_name': recipientName,
        'phone': phone,
        'region': region,
        'city': city,
        'address': address,
        'landmark': landmark,
        'is_default': isDefault,
      };
}
