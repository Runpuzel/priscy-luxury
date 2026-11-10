import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/widgets/admin_scaffold.dart';
import '../../../data/providers.dart';

class AdminReviewsScreen extends ConsumerStatefulWidget {
  const AdminReviewsScreen({super.key});

  @override
  ConsumerState<AdminReviewsScreen> createState() => _AdminReviewsScreenState();
}

class _AdminReviewsScreenState extends ConsumerState<AdminReviewsScreen> {
  int _tab = 0; // 0 = All, 1 = Pending, 2 = Approved

  @override
  Widget build(BuildContext context) {
    final reviewsAsync = ref.watch(adminReviewsProvider);

    return AdminScaffold(
      title: 'Customer Reviews Moderation',
      currentPath: '/reviews',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SegmentedButton<int>(
            segments: const [
              ButtonSegment(value: 0, label: Text('All Reviews')),
              ButtonSegment(value: 1, label: Text('Pending Approval')),
              ButtonSegment(value: 2, label: Text('Published')),
            ],
            selected: {_tab},
            onSelectionChanged: (s) => setState(() => _tab = s.first),
          ),
          const SizedBox(height: 18),
          reviewsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('Error: $e'),
            data: (reviews) {
              final filtered = reviews.where((r) {
                if (_tab == 1) return !r.isApproved;
                if (_tab == 2) return r.isApproved;
                return true;
              }).toList();

              if (filtered.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(36),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: const Center(
                    child: Text('No reviews in this tab.'),
                  ),
                );
              }

              return Column(
                children: [
                  for (final r in filtered)
                    Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            alignment: WrapAlignment.spaceBetween,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 12,
                            runSpacing: 8,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${r.productName ?? r.productId} — ${r.rating} ★',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15,
                                    ),
                                  ),
                                  Text(
                                    'By ${r.reviewerName} • ${CurrencyFormatter.formatDate(r.createdAt)}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.mutedText,
                                    ),
                                  ),
                                ],
                              ),
                              Wrap(
                                spacing: 8,
                                children: [
                                  if (!r.isApproved)
                                    ElevatedButton.icon(
                                      onPressed: () async {
                                        await ref
                                            .read(reviewRepositoryProvider)
                                            .setReviewApproval(r.id, true);
                                        ref
                                            .read(
                                              dataRefreshTriggerProvider
                                                  .notifier,
                                            )
                                            .state++;
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.success,
                                      ),
                                      icon: const Icon(
                                        Icons.check_rounded,
                                        size: 16,
                                      ),
                                      label: const Text('Approve'),
                                    )
                                  else
                                    OutlinedButton(
                                      onPressed: () async {
                                        await ref
                                            .read(reviewRepositoryProvider)
                                            .setReviewApproval(r.id, false);
                                        ref
                                            .read(
                                              dataRefreshTriggerProvider
                                                  .notifier,
                                            )
                                            .state++;
                                      },
                                      child: const Text('Hide'),
                                    ),
                                  IconButton(
                                    tooltip: 'Delete Review',
                                    onPressed: () async {
                                      await ref
                                          .read(reviewRepositoryProvider)
                                          .deleteReview(r.id);
                                      ref
                                          .read(
                                            dataRefreshTriggerProvider.notifier,
                                          )
                                          .state++;
                                    },
                                    icon: const Icon(
                                      Icons.delete_outline,
                                      color: AppColors.danger,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          if (r.comment.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            Text(r.comment),
                          ],
                        ],
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
