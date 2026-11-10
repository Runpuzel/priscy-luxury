import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/admin_scaffold.dart';
import '../../../data/models/models.dart';
import '../../../data/providers.dart';

class AdminContentScreen extends ConsumerStatefulWidget {
  const AdminContentScreen({super.key});

  @override
  ConsumerState<AdminContentScreen> createState() => _AdminContentScreenState();
}

class _AdminContentScreenState extends ConsumerState<AdminContentScreen> {
  final _sloganCtrl = TextEditingController();
  final _heroHeadCtrl = TextEditingController();
  final _heroSubCtrl = TextEditingController();
  final _heroBannerCtrl = TextEditingController();
  final _storyTitleCtrl = TextEditingController();
  final _storyBodyCtrl = TextEditingController();
  final _pickupCtrl = TextEditingController();
  final _thresholdCtrl = TextEditingController();
  bool _loadedSettings = false;

  String? _selectedPageSlug;
  final _pageTitleCtrl = TextEditingController();
  final _pageBodyCtrl = TextEditingController();

  @override
  void dispose() {
    _sloganCtrl.dispose();
    _heroHeadCtrl.dispose();
    _heroSubCtrl.dispose();
    _heroBannerCtrl.dispose();
    _storyTitleCtrl.dispose();
    _storyBodyCtrl.dispose();
    _pickupCtrl.dispose();
    _thresholdCtrl.dispose();
    _pageTitleCtrl.dispose();
    _pageBodyCtrl.dispose();
    super.dispose();
  }

  void _populateSettings(SiteSettings s) {
    if (_loadedSettings) return;
    _loadedSettings = true;
    _sloganCtrl.text = s.slogan;
    _heroHeadCtrl.text = s.heroHeadline;
    _heroSubCtrl.text = s.heroSubheadline;
    _heroBannerCtrl.text = s.heroBannerUrl;
    _storyTitleCtrl.text = s.brandStoryTitle;
    _storyBodyCtrl.text = s.brandStoryBody;
    _pickupCtrl.text = s.pickupAddress;
    _thresholdCtrl.text = '${s.lowStockThreshold}';
  }

  void _selectPage(StaticPageContent p) {
    setState(() {
      _selectedPageSlug = p.slug;
      _pageTitleCtrl.text = p.title;
      _pageBodyCtrl.text = p.bodyMarkdown;
    });
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(siteSettingsProvider).valueOrNull;
    final pages = ref.watch(staticPagesProvider).valueOrNull ?? const [];

    if (settings != null) _populateSettings(settings);
    if (_selectedPageSlug == null && pages.isNotEmpty) {
      _selectedPageSlug = pages.first.slug;
      _pageTitleCtrl.text = pages.first.title;
      _pageBodyCtrl.text = pages.first.bodyMarkdown;
    }

    return AdminScaffold(
      title: 'Storefront Content & Policy Pages',
      currentPath: '/content',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hero Banner, Slogan & Pickup Settings',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _sloganCtrl,
                  decoration: const InputDecoration(labelText: 'Brand Slogan'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _heroHeadCtrl,
                  decoration:
                      const InputDecoration(labelText: 'Hero Headline'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _heroSubCtrl,
                  maxLines: 2,
                  decoration:
                      const InputDecoration(labelText: 'Hero Subheadline'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _heroBannerCtrl,
                  decoration:
                      const InputDecoration(labelText: 'Hero Banner Image URL'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _storyTitleCtrl,
                  decoration:
                      const InputDecoration(labelText: 'Brand Story Heading'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _storyBodyCtrl,
                  maxLines: 3,
                  decoration:
                      const InputDecoration(labelText: 'Brand Story Copy'),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 14,
                  runSpacing: 12,
                  children: [
                    SizedBox(
                      width: 420,
                      child: TextField(
                        controller: _pickupCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Kumasi Pickup Address',
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 210,
                      child: TextField(
                        controller: _thresholdCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Low-Stock Alert Threshold',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: settings == null
                      ? null
                      : () async {
                          await ref
                              .read(contentRepositoryProvider)
                              .saveSiteSettings(
                                settings.copyWith(
                                  slogan: _sloganCtrl.text.trim(),
                                  heroHeadline: _heroHeadCtrl.text.trim(),
                                  heroSubheadline: _heroSubCtrl.text.trim(),
                                  heroBannerUrl: _heroBannerCtrl.text.trim(),
                                  brandStoryTitle: _storyTitleCtrl.text.trim(),
                                  brandStoryBody: _storyBodyCtrl.text.trim(),
                                  pickupAddress: _pickupCtrl.text.trim(),
                                  lowStockThreshold:
                                      int.tryParse(_thresholdCtrl.text) ?? 3,
                                ),
                              );
                          ref.read(dataRefreshTriggerProvider.notifier).state++;
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Storefront settings saved!'),
                              ),
                            );
                          }
                        },
                  child: const Text('Save Storefront Settings'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Static policy pages editor
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Edit Static & Policy Pages (Markdown)',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final p in pages)
                      ChoiceChip(
                        label: Text(p.title),
                        selected: _selectedPageSlug == p.slug,
                        onSelected: (_) => _selectPage(p),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _pageTitleCtrl,
                  decoration: const InputDecoration(labelText: 'Page Title'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _pageBodyCtrl,
                  maxLines: 12,
                  decoration: const InputDecoration(
                    labelText: 'Body Content (Markdown)',
                  ),
                ),
                const SizedBox(height: 14),
                ElevatedButton(
                  onPressed: _selectedPageSlug == null
                      ? null
                      : () async {
                          await ref.read(contentRepositoryProvider).savePage(
                                StaticPageContent(
                                  slug: _selectedPageSlug!,
                                  title: _pageTitleCtrl.text.trim(),
                                  bodyMarkdown: _pageBodyCtrl.text,
                                  updatedAt: DateTime.now(),
                                ),
                              );
                          ref.read(dataRefreshTriggerProvider.notifier).state++;
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Policy page updated!'),
                              ),
                            );
                          }
                        },
                  child: const Text('Save Page Content'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
