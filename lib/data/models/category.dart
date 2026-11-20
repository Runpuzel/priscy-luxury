import 'package:flutter/foundation.dart';

@immutable
class Category {
  const Category({
    required this.id,
    required this.name,
    required this.slug,
    this.sortOrder = 0,
  });

  final String id;
  final String name;
  final String slug;
  final int sortOrder;

  Category copyWith({
    String? id,
    String? name,
    String? slug,
    int? sortOrder,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      slug: slug ?? this.slug,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'slug': slug,
        'sort_order': sortOrder,
      };
}
