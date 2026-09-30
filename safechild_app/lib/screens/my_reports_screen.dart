import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';
import '../services/localization_service.dart';
import '../models/missing_child.dart';
import 'child_detail_screen.dart';
import '../theme/app_motion.dart';
import '../widgets/app_widgets.dart';
import '../widgets/status_badges.dart';
import '../theme/app_theme.dart';

final myReportsProvider = FutureProvider<List<MissingChild>>((ref) async {
  final api = ref.watch(apiServiceProvider);
  final response = await api.get(
    '/missing-children',
    queryParameters: {'my_reports': 1},
  );
  return (response.data as List).map((e) => MissingChild.fromJson(e)).toList();
});

class MyReportsScreen extends ConsumerWidget {
  const MyReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final myReports = ref.watch(myReportsProvider);
    final tr = AppTranslations.of(context);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(myReportsProvider);
          await ref.read(myReportsProvider.future);
        },
        child: myReports.when(
          data: (userReports) {
            if (userReports.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.list_alt_rounded,
                      size: 80,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      tr.translate('no_reports'),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: userReports.length,
              itemBuilder: (context, index) {
                final child = userReports[index];
                return FadeSlideIn(
                  key: ValueKey(child.id),
                  // Stagger only the first screenful. Beyond that a per-item
                  // delay would make the tail of a long list appear broken.
                  delay: index < 6 ? AppMotion.stagger * index : Duration.zero,
                  child: AppCard(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Hero(
                              tag: 'child_img_${child.id}',
                              child: CircleAvatar(
                                radius: 28,
                                backgroundImage: child.photoUrl != null
                                    ? NetworkImage(child.photoUrl!)
                                    : null,
                                child: child.photoUrl == null
                                    ? const Icon(Icons.person)
                                    : null,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          child.name,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 17,
                                          ),
                                        ),
                                      ),
                                      AlertTypeBadge(
                                        child: child,
                                        dense: true,
                                        label: child.isWantedPerson
                                            ? tr.translate('filter_wanted')
                                            : child.isAdultMissing
                                            ? tr.translate('filter_adults')
                                            : tr.translate('filter_children'),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "${tr.ageLabel(child.age)} • ${child.status == 'missing' ? tr.translate('missing') : tr.translate('found')}",
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: child.isVerified
                                    ? context.colors.surfaceMuted
                                    : context.colors.pending.withValues(
                                        alpha: 0.10,
                                      ),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: child.isVerified
                                      ? context.colors.borderSubtle
                                      : context.colors.pending,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    child.isVerified
                                        ? Icons.verified
                                        : Icons.hourglass_top_rounded,
                                    size: 14,
                                    color: child.isVerified
                                        ? context.colors.verified
                                        : context.colors.pending,
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    child.isVerified
                                        ? tr.translate('published_alert')
                                        : tr.translate('pending_approval'),
                                    style: TextStyle(
                                      color: child.isVerified
                                          ? context.colors.verified
                                          : context.colors.pending,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            TextButton.icon(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  AppPushRoute(
                                    page: ChildDetailScreen(child: child),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.arrow_forward, size: 14),
                              label: Text(
                                tr.translate('details'),
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
          loading: () => Center(child: Text(tr.translate('loading'))),
          error: (e, _) => Center(child: Text("${tr.translate('error')}: $e")),
        ),
      ),
    );
  }
}
