import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';
import '../services/localization_service.dart';
import '../models/missing_child.dart';
import 'child_detail_screen.dart';

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
                      color: Colors.grey[300],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      tr.translate('no_reports'),
                      style: const TextStyle(color: Colors.grey, fontSize: 16),
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
                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Padding(
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
                                      if (child.alertType == 'wanted_person')
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.red[50],
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                            border: Border.all(
                                              color: Colors.red[300]!,
                                            ),
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
                                      else if (child.alertType ==
                                          'adult_missing')
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.purple[50],
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                            border: Border.all(
                                              color: Colors.purple[300]!,
                                            ),
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
                                            color: Colors.blue[50],
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                            border: Border.all(
                                              color: Colors.blue[300]!,
                                            ),
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
                                    ? Colors.green[50]
                                    : Colors.amber[50],
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: child.isVerified
                                      ? Colors.green[300]!
                                      : Colors.amber[400]!,
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
                                        ? Colors.green[700]
                                        : Colors.amber[800],
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    child.isVerified
                                        ? tr.translate('published_alert')
                                        : tr.translate('pending_approval'),
                                    style: TextStyle(
                                      color: child.isVerified
                                          ? Colors.green[800]
                                          : Colors.amber[900],
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
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        ChildDetailScreen(child: child),
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
