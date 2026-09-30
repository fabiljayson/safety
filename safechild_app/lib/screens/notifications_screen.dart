import 'package:flutter/material.dart';
import '../services/localization_service.dart';
import '../theme/app_motion.dart';
import '../theme/app_theme.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tr = AppTranslations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(tr.translate('notifications')),
        centerTitle: true,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: 5,
        separatorBuilder: (context, index) => const Divider(),
        itemBuilder: (context, index) {
          final isAlert = index % 2 == 0;
          return FadeSlideIn(
            // Stagger only the first screenful so a long list still arrives
            // promptly; see StaggeredList for the reasoning.
            delay: index < 6 ? AppMotion.stagger * index : Duration.zero,
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: context.colors.surfaceMuted,
                child: Icon(
                  isAlert ? Icons.warning_rounded : Icons.info_rounded,
                  color: isAlert
                      ? context.colors.urgent
                      : Theme.of(context).colorScheme.primary,
                ),
              ),
              title: Text(
                isAlert
                    ? tr.translate('alert_kidnapping')
                    : tr.translate('certified'),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(tr.translate('notif_body')),
              trailing: Text(
                tr.translate('time_ago'),
                style: TextStyle(
                  fontSize: 10,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              onTap: () {},
            ),
          );
        },
      ),
    );
  }
}
