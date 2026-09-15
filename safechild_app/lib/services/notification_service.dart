import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'api_service.dart';

final notificationServiceProvider = Provider((ref) => NotificationService(ref));

class NotificationService {
  final Ref _ref;
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  NotificationService(this._ref);

  Future<void> init() async {
    try {
      // Request permissions
      await _fcm.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      // Initialize local notifications
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const InitializationSettings initializationSettings =
          InitializationSettings(android: initializationSettingsAndroid);
      await _localNotifications.initialize(initializationSettings);

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        _showLocalNotification(message);
      });

      // Handle background/terminated messages when app is opened
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        _handleNotificationClick(message);
      });

      // Get and save token
      String? token = await _fcm.getToken();
      if (token != null) {
        await _saveTokenToBackend(token);
      }

      // Refresh token
      _fcm.onTokenRefresh.listen((newToken) async {
        await _saveTokenToBackend(newToken);
      });
    } catch (e) {
      debugPrint("NotificationService init failed: $e");
    }
  }

  Future<void> _saveTokenToBackend(String token) async {
    try {
      await _ref.read(apiServiceProvider).post('/update-fcm-token', data: {'fcm_token': token});
    } catch (e) {
      // Ignore if not logged in yet
    }
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;

    if (notification != null && android != null) {
      await _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'safechild_alerts',
            'SafeChild Alerts',
            importance: Importance.max,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
        ),
      );
    }
  }

  void _handleNotificationClick(RemoteMessage message) {
    // Navigate to specific child if needed
    // Example: Navigator.of(context).push(...)
  }
}
