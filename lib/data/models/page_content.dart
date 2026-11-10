import 'package:flutter/foundation.dart';

@immutable
class StaticPageContent {
  const StaticPageContent({
    required this.slug,
    required this.title,
    required this.bodyMarkdown,
    required this.updatedAt,
  });

  final String slug;
  final String title;
  final String bodyMarkdown;
  final DateTime updatedAt;

  StaticPageContent copyWith({
    String? title,
    String? bodyMarkdown,
    DateTime? updatedAt,
  }) {
    return StaticPageContent(
      slug: slug,
      title: title ?? this.title,
      bodyMarkdown: bodyMarkdown ?? this.bodyMarkdown,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory StaticPageContent.fromJson(Map<String, dynamic> json) {
    return StaticPageContent(
      slug: json['slug']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      bodyMarkdown: json['body_markdown']?.toString() ?? '',
      updatedAt: DateTime.tryParse(json['updated_at']?.toString() ?? '') ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'slug': slug,
        'title': title,
        'body_markdown': bodyMarkdown,
        'updated_at': updatedAt.toIso8601String(),
      };
}

@immutable
class SiteSettings {
  const SiteSettings({
    this.brandName = 'Priscy Luxury Slippers',
    this.ownerName = 'Priscilla Adutwum',
    this.slogan = 'Premium quality, affordable prices, unbeatable style!',
    this.phone = '0550571248',
    this.whatsappNumber = '233550571248',
    this.email = 'adupriscytwum@gmail.com',
    this.pickupAddress = 'Adum / Kejetia Showroom Pickup Point, Kumasi',
    this.heroHeadline = 'Handcrafted Elegance for Every Step Across Ghana',
    this.heroSubheadline =
        'Premium quality, affordable prices, unbeatable style! Discover cushioned slides, artisan leather sandals, and effortless flats for women, men, and children.',
    this.heroCtaLabel = 'Shop the Launch Collection',
    this.heroBannerUrl =
        'https://images.unsplash.com/photo-1543163521-1bf539c55dd2?auto=format&fit=crop&w=1400&q=80',
    this.brandStoryTitle = 'Designed for Comfort, Built to Last',
    this.brandStoryBody =
        'Born in Kumasi and loved across Ghana, Priscy Luxury Slippers pairs supple leathers, cushioned footbeds, and timeless silhouettes that take you effortlessly from weekday errands to weekend celebrations.',
    this.lowStockThreshold = 3,
  });

  final String brandName;
  final String ownerName;
  final String slogan;
  final String phone;
  final String whatsappNumber;
  final String email;
  final String pickupAddress;
  final String heroHeadline;
  final String heroSubheadline;
  final String heroCtaLabel;
  final String heroBannerUrl;
  final String brandStoryTitle;
  final String brandStoryBody;
  final int lowStockThreshold;

  SiteSettings copyWith({
    String? brandName,
    String? ownerName,
    String? slogan,
    String? phone,
    String? whatsappNumber,
    String? email,
    String? pickupAddress,
    String? heroHeadline,
    String? heroSubheadline,
    String? heroCtaLabel,
    String? heroBannerUrl,
    String? brandStoryTitle,
    String? brandStoryBody,
    int? lowStockThreshold,
  }) {
    return SiteSettings(
      brandName: brandName ?? this.brandName,
      ownerName: ownerName ?? this.ownerName,
      slogan: slogan ?? this.slogan,
      phone: phone ?? this.phone,
      whatsappNumber: whatsappNumber ?? this.whatsappNumber,
      email: email ?? this.email,
      pickupAddress: pickupAddress ?? this.pickupAddress,
      heroHeadline: heroHeadline ?? this.heroHeadline,
      heroSubheadline: heroSubheadline ?? this.heroSubheadline,
      heroCtaLabel: heroCtaLabel ?? this.heroCtaLabel,
      heroBannerUrl: heroBannerUrl ?? this.heroBannerUrl,
      brandStoryTitle: brandStoryTitle ?? this.brandStoryTitle,
      brandStoryBody: brandStoryBody ?? this.brandStoryBody,
      lowStockThreshold: lowStockThreshold ?? this.lowStockThreshold,
    );
  }

  Map<String, dynamic> toJson() => {
        'brand_name': brandName,
        'owner_name': ownerName,
        'slogan': slogan,
        'phone': phone,
        'whatsapp_number': whatsappNumber,
        'email': email,
        'pickup_address': pickupAddress,
        'hero_headline': heroHeadline,
        'hero_subheadline': heroSubheadline,
        'hero_cta_label': heroCtaLabel,
        'hero_banner_url': heroBannerUrl,
        'brand_story_title': brandStoryTitle,
        'brand_story_body': brandStoryBody,
        'low_stock_threshold': lowStockThreshold,
      };

  factory SiteSettings.fromJson(Map<String, dynamic> json) {
    return SiteSettings(
      brandName: json['brand_name']?.toString() ?? 'Priscy Luxury Slippers',
      ownerName: json['owner_name']?.toString() ?? 'Priscilla Adutwum',
      slogan: json['slogan']?.toString() ??
          'Premium quality, affordable prices, unbeatable style!',
      phone: json['phone']?.toString() ?? '0550571248',
      whatsappNumber: json['whatsapp_number']?.toString() ?? '233550571248',
      email: json['email']?.toString() ?? 'adupriscytwum@gmail.com',
      pickupAddress: json['pickup_address']?.toString() ??
          'Adum / Kejetia Showroom Pickup Point, Kumasi',
      heroHeadline: json['hero_headline']?.toString() ??
          'Handcrafted Elegance for Every Step Across Ghana',
      heroSubheadline: json['hero_subheadline']?.toString() ??
          'Premium quality, affordable prices, unbeatable style!',
      heroCtaLabel:
          json['hero_cta_label']?.toString() ?? 'Shop the Launch Collection',
      heroBannerUrl: json['hero_banner_url']?.toString() ??
          'https://images.unsplash.com/photo-1543163521-1bf539c55dd2?auto=format&fit=crop&w=1400&q=80',
      brandStoryTitle: json['brand_story_title']?.toString() ??
          'Designed for Comfort, Built to Last',
      brandStoryBody: json['brand_story_body']?.toString() ?? '',
      lowStockThreshold: (json['low_stock_threshold'] as num?)?.toInt() ?? 3,
    );
  }
}
