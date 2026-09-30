import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';
import '../services/localization_service.dart';
import '../models/missing_child.dart';
import '../theme/app_motion.dart';
import '../theme/app_theme.dart';
import '../widgets/app_widgets.dart';
import '../widgets/status_badges.dart';
import 'auth_screen.dart';
import 'child_detail_screen.dart';

final missingChildrenProvider = FutureProvider<List<MissingChild>>((ref) async {
  final api = ref.watch(apiServiceProvider);
  final response = await api.get('/missing-children');
  return (response.data as List).map((e) => MissingChild.fromJson(e)).toList();
});

class LatLngPoint {
  final double latitude;
  final double longitude;
  LatLngPoint(this.latitude, this.longitude);
}

class WeightedLatLng {
  final LatLngPoint point;
  final double weight;
  WeightedLatLng(this.point, {this.weight = 1.0});
}

final dangerZonesProvider = FutureProvider<List<WeightedLatLng>>((ref) async {
  final api = ref.watch(apiServiceProvider);
  try {
    final response = await api.get('/danger-zones');
    return (response.data as List)
        .map(
          (e) => WeightedLatLng(
            LatLngPoint(
              double.parse(e['lat'].toString()),
              double.parse(e['lng'].toString()),
            ),
            weight: double.parse(e['intensity'].toString()),
          ),
        )
        .toList();
  } catch (e) {
    return [];
  }
});

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reports = ref.watch(missingChildrenProvider);
    final user = ref.watch(authProvider).value;
    final tr = AppTranslations.of(context);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          // Manual refresh of all providers
          ref.invalidate(missingChildrenProvider);
          ref.invalidate(dangerZonesProvider);
          await ref.read(missingChildrenProvider.future);
          await ref.read(dangerZonesProvider.future);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                tr.translate('direct_stats'),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),

              // Stats Grid
              reports.when(
                data: (list) {
                  final missing = list
                      .where((c) => c.status == 'missing')
                      .length;
                  final verified = list.where((c) => c.isVerified).length;
                  return GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    crossAxisSpacing: 15,
                    mainAxisSpacing: 15,
                    childAspectRatio: 1.5,
                    children: [
                      _buildStatCard(
                        context: context,
                        label: tr.translate('missing_children'),
                        value: "$missing",
                        accent: context.colors.urgent,
                        icon: Icons.warning_amber_rounded,
                      ),
                      _buildStatCard(
                        context: context,
                        label: tr.translate('certified_alerts'),
                        value: "$verified",
                        accent: context.colors.verified,
                        icon: Icons.verified_user_outlined,
                      ),
                      _buildStatCard(
                        context: context,
                        label: tr.translate('active_citizens'),
                        value: "1,240",
                        accent: Theme.of(context).colorScheme.primary,
                        icon: Icons.people_outline,
                      ),
                      _buildStatCard(
                        context: context,
                        label: tr.translate('found_30d'),
                        value: "12",
                        accent: context.colors.resolved,
                        icon: Icons.check_circle_outline,
                      ),
                    ],
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Text("${tr.translate('error')}: $e"),
              ),

              const SizedBox(height: 30),

              // Large Carousel Card (User's Reports)
              reports.when(
                data: (list) {
                  final userReports = list
                      .where((c) => c.userId == user?.id)
                      .toList();
                  if (userReports.isEmpty) return const SizedBox();

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tr.translate('your_reports'),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 15),
                      SizedBox(
                        height: 250,
                        child: PageView.builder(
                          itemCount: userReports.length,
                          itemBuilder: (context, index) {
                            final child = userReports[index];
                            return _buildCarouselCard(context, child, tr);
                          },
                        ),
                      ),
                      const SizedBox(height: 30),
                    ],
                  );
                },
                loading: () => const SizedBox(),
                error: (_, _) => const SizedBox(),
              ),

              Text(
                tr.translate('latest_alerts'),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 15),

              reports.when(
                data: (list) => ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: list.take(5).length,
                  itemBuilder: (context, index) {
                    final child = list[index];
                    return FadeSlideIn(
                      // Stagger the first screenful only: past that a delay
                      // would make fresh data look like it failed to load.
                      delay: index < 6
                          ? AppMotion.stagger * index
                          : Duration.zero,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundImage: child.photoUrl != null
                                ? NetworkImage(child.photoUrl!)
                                : null,
                            child: child.photoUrl == null
                                ? const Icon(Icons.person)
                                : null,
                          ),
                          title: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  child.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
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
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Row(
                              children: [
                                Text(tr.ageLabel(child.age)),
                                const SizedBox(width: AppSpacing.sm),
                                ReviewStateTag(
                                  isVerified: child.isVerified,
                                  isResolved: child.status == 'found',
                                  certifiedLabel: tr.translate('certified'),
                                  pendingLabel: tr.translate('pending'),
                                  resolvedLabel: tr.translate('found'),
                                  iconSize: 12,
                                ),
                              ],
                            ),
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {
                            Navigator.push(
                              context,
                              AppPushRoute(
                                page: ChildDetailScreen(child: child),
                              ),
                            );
                          },
                        ),
                      ),
                    );
                  },
                ),
                loading: () => const SizedBox(),
                error: (e, _) => const SizedBox(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Stat tile. Colours are taken from the theme rather than passed in.
  ///
  /// The previous version branched on `themeMode` by hand and used
  /// `Colors.lightBlue[100]` for the dark-mode fill, so in dark mode these
  /// tiles rendered as bright blue cards floating on a black background. It
  /// also took its `bg`/`text`/`subText` from the caller while separately
  /// taking `iconColor` from the caller, which is why the four call sites had
  /// drifted apart.
  Widget _buildStatCard({
    required BuildContext context,
    required String label,
    required String value,
    required Color accent,
    required IconData icon,
  }) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: context.colors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppRadii.sm),
            ),
            child: Icon(icon, color: accent, size: 20),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 2),
              Text(label, style: theme.textTheme.labelSmall),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCarouselCard(
    BuildContext context,
    MissingChild child,
    AppTranslations tr,
  ) {
    final scheme = Theme.of(context).colorScheme;

    return PressableScale(
      onTap: () {
        Navigator.push(
          context,
          AppPageRoute(page: ChildDetailScreen(child: child)),
        );
      },
      borderRadius: BorderRadius.circular(AppRadii.lg),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 5),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadii.lg),
          border: Border.all(color: context.colors.borderSubtle),
          image: child.photoUrl != null
              ? DecorationImage(
                  image: NetworkImage(child.photoUrl!),
                  fit: BoxFit.cover,
                )
              : null,
          color: child.photoUrl != null ? null : scheme.surfaceContainerHigh,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Flat scrim behind the caption instead of a full-card
            // transparent-to-black gradient. The photo stays visible across the
            // top of the card and the caption gets an even, predictable
            // background to sit on rather than a wash that changed contrast
            // from top to bottom.
            ImageScrim(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          child.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(
                            context,
                          ).textTheme.titleLarge?.copyWith(color: Colors.white),
                        ),
                      ),
                      if (child.isVerified) ...[
                        const SizedBox(width: AppSpacing.sm),
                        Icon(
                          Icons.verified_rounded,
                          color: context.colors.verified,
                          size: 20,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          tr.ageLabel(child.age),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: Colors.white70),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        '·',
                        style: Theme.of(
                          context,
                        ).textTheme.bodySmall?.copyWith(color: Colors.white70),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        child.status == 'missing'
                            ? tr.translate('missing').toUpperCase()
                            : tr.translate('found').toUpperCase(),
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Colors.white70,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
