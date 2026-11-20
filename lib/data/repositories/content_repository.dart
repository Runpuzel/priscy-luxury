import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/config/app_config.dart';
import '../models/models.dart';
import 'demo_database.dart';

class ContentRepository {
  ContentRepository({required DemoDatabase demoDb}) : _demoDb = demoDb;

  final DemoDatabase _demoDb;
  SupabaseClient get _supabase => Supabase.instance.client;

  Future<List<DeliveryZone>> fetchDeliveryZones({
    bool includeInactive = false,
  }) async {
    if (AppConfig.isDemoMode) {
      return _demoDb.deliveryZones
          .where((z) => includeInactive || z.isActive)
          .toList();
    }

    var query = _supabase.from('delivery_zones').select();
    if (!includeInactive) {
      query = query.eq('is_active', true);
    }
    final rows = await query.order('fee', ascending: true);
    return rows.map(DeliveryZone.fromJson).toList();
  }

  Future<void> saveDeliveryZone(DeliveryZone zone) async {
    if (AppConfig.isDemoMode) {
      final id = zone.id.isEmpty ? _demoDb.nextId('zone') : zone.id;
      final saved = zone.copyWith(id: id);
      final idx = _demoDb.deliveryZones.indexWhere((z) => z.id == id);
      if (idx == -1) {
        _demoDb.deliveryZones.add(saved);
      } else {
        _demoDb.deliveryZones[idx] = saved;
      }
      await _demoDb.saveZones();
      return;
    }

    if (zone.id.isEmpty) {
      await _supabase.from('delivery_zones').insert({
        'region': zone.region,
        'city': zone.city,
        'fee': zone.fee,
        'est_days_min': zone.estDaysMin,
        'est_days_max': zone.estDaysMax,
        'is_active': zone.isActive,
      });
    } else {
      await _supabase
          .from('delivery_zones')
          .update(zone.toJson())
          .eq('id', zone.id);
    }
  }

  Future<List<StaticPageContent>> fetchAllPages() async {
    if (AppConfig.isDemoMode) {
      return List<StaticPageContent>.from(_demoDb.pages);
    }

    final rows = await _supabase.from('pages').select().order('slug');
    return rows.map(StaticPageContent.fromJson).toList();
  }

  Future<StaticPageContent?> fetchPageBySlug(String slug) async {
    final all = await fetchAllPages();
    for (final p in all) {
      if (p.slug == slug) return p;
    }
    return null;
  }

  Future<void> savePage(StaticPageContent page) async {
    if (AppConfig.isDemoMode) {
      final idx = _demoDb.pages.indexWhere((p) => p.slug == page.slug);
      final updated = page.copyWith(updatedAt: DateTime.now());
      if (idx == -1) {
        _demoDb.pages.add(updated);
      } else {
        _demoDb.pages[idx] = updated;
      }
      await _demoDb.savePages();
      return;
    }

    await _supabase.from('pages').upsert({
      'slug': page.slug,
      'title': page.title,
      'body_markdown': page.bodyMarkdown,
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  Future<SiteSettings> fetchSiteSettings() async {
    if (AppConfig.isDemoMode) {
      return _demoDb.settings;
    }

    final rows = await _supabase.from('site_settings').select();
    final combined = <String, dynamic>{};
    for (final row in rows) {
      final key = row['key']?.toString() ?? '';
      final val = row['value'];
      if (val is Map<String, dynamic>) {
        if (key == 'hero') {
          combined['hero_headline'] = val['headline'];
          combined['hero_subheadline'] = val['subheadline'];
          combined['hero_cta_label'] = val['cta_label'];
          combined['hero_banner_url'] = val['banner_url'];
        } else if (key == 'brand_story') {
          combined['brand_story_title'] = val['title'];
          combined['brand_story_body'] = val['body'];
        } else {
          combined.addAll(val);
        }
      }
    }
    return SiteSettings.fromJson(combined);
  }

  Future<void> saveSiteSettings(SiteSettings settings) async {
    if (AppConfig.isDemoMode) {
      _demoDb.settings = settings;
      await _demoDb.saveSettings();
      return;
    }

    await _supabase.from('site_settings').upsert([
      {
        'key': 'general',
        'value': {
          'brand_name': settings.brandName,
          'owner_name': settings.ownerName,
          'slogan': settings.slogan,
          'phone': settings.phone,
          'whatsapp_number': settings.whatsappNumber,
          'email': settings.email,
          'pickup_address': settings.pickupAddress,
          'low_stock_threshold': settings.lowStockThreshold,
        },
      },
      {
        'key': 'hero',
        'value': {
          'headline': settings.heroHeadline,
          'subheadline': settings.heroSubheadline,
          'cta_label': settings.heroCtaLabel,
          'banner_url': settings.heroBannerUrl,
        },
      },
      {
        'key': 'brand_story',
        'value': {
          'title': settings.brandStoryTitle,
          'body': settings.brandStoryBody,
        },
      },
    ]);
  }
}
