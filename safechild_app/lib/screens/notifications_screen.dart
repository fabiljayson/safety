import 'package:flutter/material.dart';
import '../services/localization_service.dart';

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
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: index % 2 == 0 ? Colors.red[50] : Colors.blue[50],
              child: Icon(
                index % 2 == 0 ? Icons.warning_rounded : Icons.info_rounded,
                color: index % 2 == 0 ? Colors.red : Colors.blue,
              ),
            ),
            title: Text(
              index % 2 == 0 ? tr.translate('alert_kidnapping') : tr.translate('certified'),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(tr.translate('notif_body')),
            trailing: Text(tr.translate('time_ago'), style: const TextStyle(fontSize: 10, color: Colors.grey)),
            onTap: () {},
          );
        },
      ),
    );
  }
}
