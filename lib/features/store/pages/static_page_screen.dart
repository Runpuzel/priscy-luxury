import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_config.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/whatsapp_helper.dart';
import '../../../core/widgets/markdown_body_view.dart';
import '../../../core/widgets/store_scaffold.dart';
import '../../../data/providers.dart';

class StaticPageScreen extends ConsumerWidget {
  const StaticPageScreen({super.key, required this.slug});
  final String slug;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pageAsync = ref.watch(pageBySlugProvider(slug));

    return StoreScaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 840),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 36, 16, 36),
            child: pageAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(64),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => Text('Unable to load page: $e'),
              data: (page) {
                if (page == null) {
                  return const Text('Requested page was not found.');
                }

                return Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        page.title,
                        style: Theme.of(context).textTheme.headlineLarge,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Last updated ${CurrencyFormatter.formatDate(page.updatedAt)}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const Divider(height: 30),
                      MarkdownBodyView(markdown: page.bodyMarkdown),
                      if (slug == 'contact') ...[
                        const SizedBox(height: 24),
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            ElevatedButton.icon(
                              onPressed: () => WhatsAppHelper.openUrl(
                                WhatsAppHelper.buildSupportChatUrl(),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.whatsappGreen,
                              ),
                              icon: const Icon(Icons.chat_rounded, size: 18),
                              label: const Text(
                                'Chat on WhatsApp (${AppConfig.supportPhoneLocal})',
                              ),
                            ),
                            OutlinedButton.icon(
                              onPressed: () => WhatsAppHelper.openUrl(
                                'mailto:${AppConfig.supportEmail}',
                              ),
                              icon: const Icon(Icons.email_outlined, size: 18),
                              label: const Text(AppConfig.supportEmail),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
