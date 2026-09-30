import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';
import '../services/localization_service.dart';
import '../models/missing_child.dart';
import '../services/theme_provider.dart';
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
    final themeMode = ref.watch(themeProvider);
    final tr = AppTranslations.of(context);

    // Dynamic Card Color based on Theme
    final cardColor = themeMode == ThemeMode.dark
        ? Colors.lightBlue[100]
        : Colors.blue[900];
    final textColor = themeMode == ThemeMode.dark
        ? Colors.blue[900]
        : Colors.white;
    final subTextColor = themeMode == ThemeMode.dark
        ? Colors.blue[700]
        : Colors.white70;

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
                        tr.translate('missing_children'),
                        "$missing",
                        Colors.red,
                        Icons.warning_amber_rounded,
                        cardColor!,
                        textColor!,
                        subTextColor!,
                      ),
                      _buildStatCard(
                        tr.translate('certified_alerts'),
                        "$verified",
                        Colors.blue,
                        Icons.verified_user_outlined,
                        cardColor,
                        textColor,
                        subTextColor,
                      ),
                      _buildStatCard(
                        tr.translate('active_citizens'),
                        "1,240",
                        Colors.green,
                        Icons.people_outline,
                        cardColor,
                        textColor,
                        subTextColor,
                      ),
                      _buildStatCard(
                        tr.translate('found_30d'),
                        "12",
                        Colors.orange,
                        Icons.check_circle_outline,
                        cardColor,
                        textColor,
                        subTextColor,
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
                    return Container(
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
                            if (child.alertType == 'wanted_person')
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.red[100],
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '🚨 ${tr.translate('filter_wanted')}',
                                  style: TextStyle(
                                    color: Colors.red[900],
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              )
                            else if (child.alertType == 'adult_missing')
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.purple[100],
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '🧓 ${tr.translate('filter_adults')}',
                                  style: TextStyle(
                                    color: Colors.purple[900],
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              )
                            else
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.blue[100],
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '👶 ${tr.translate('filter_children')}',
                                  style: TextStyle(
                                    color: Colors.blue[900],
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            "${child.age} ans - ${child.isVerified ? '✅ ${tr.translate('certified')}' : '⏳ ${tr.translate('pending')}'}",
                          ),
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  ChildDetailScreen(child: child),
                            ),
                          );
                        },
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

  Widget _buildStatCard(
    String label,
    String value,
    Color iconColor,
    IconData icon,
    Color bg,
    Color text,
    Color subText,
  ) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: iconColor, size: 28),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: text,
                ),
              ),
              Text(label, style: TextStyle(color: subText, fontSize: 11)),
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
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChildDetailScreen(child: child),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 5),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(25),
          image: child.photoUrl != null
              ? DecorationImage(
                  image: NetworkImage(child.photoUrl!),
                  fit: BoxFit.cover,
                )
              : null,
          color: Colors.grey[300],
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(25),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.transparent, Colors.black.withValues(alpha: 0.8)],
            ),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    child.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (child.isVerified)
                    const Icon(Icons.verified, color: Colors.blue, size: 20),
                ],
              ),
              Text(
                "${child.age} ans - ${child.status == 'missing' ? tr.translate('missing').toUpperCase() : tr.translate('found').toUpperCase()}",
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
