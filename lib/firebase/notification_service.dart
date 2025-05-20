import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/models/notification_model.dart';
import '../presentation/providers/notification_provider.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print("Handling a background message: ${message.messageId}");
}

class NotificationService {
  static BuildContext? _context;
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  // Add this method to get the FCM token
  static Future<String?> getToken() async {
    try {
      // Request permission first
      NotificationSettings settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        // Get the token
        String? token = await _messaging.getToken();
        print('FCM Token: $token');
        return token;
      } else {
        print('User declined notifications permission');
        return null;
      }
    } catch (e) {
      print('Error getting FCM token: $e');
      return null;
    }
  }

  static void setContext(BuildContext context) {
    _context = context;
  }

  static Future<void> initialize() async {
    await Firebase.initializeApp();

    // Request permission
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    print('User granted permission: ${settings.authorizationStatus}');

    // Get FCM token
    String? token = await _messaging.getToken();
    print('FCM Token: $token');

    // Handle background messages
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle when app is opened from notification
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);
  }

  static void _handleForegroundMessage(RemoteMessage message) {
    print("Got a message in foreground!");
    if (message.notification != null && _context != null) {
      final notification = NotificationModel(
        id: message.messageId ?? DateTime.now().toString(),
        title: message.notification?.title ?? 'New Notification',
        message: message.notification?.body ?? '',
        type: _parseNotificationType(message.data['type'] ?? 'announcement'),
        timestamp: DateTime.now(),
        userId: message.data['userId'] ?? '',
        data: message.data,
      );

      // Update UI through provider
      if (_context!.mounted) {
        Provider.of<NotificationProvider>(
          _context!,
          listen: false,
        ).addNotification(notification);

        // Show a snackbar
        ScaffoldMessenger.of(_context!).showSnackBar(
          SnackBar(
            content: Text(notification.title),
            action: SnackBarAction(
              label: 'View',
              onPressed: () {
                // Navigate to notifications screen
              },
            ),
          ),
        );
      }
    }
  }

  static void _handleMessageOpenedApp(RemoteMessage message) {
    print("App opened from notification: ${message.messageId}");
    // Handle navigation when app is opened from notification
  }

  static NotificationType _parseNotificationType(String type) {
    switch (type.toLowerCase()) {
      case 'classcancelled':
        return NotificationType.classCancelled;
      case 'classrescheduled':
        return NotificationType.classRescheduled;
      case 'extraclass':
        return NotificationType.extraClass;
      default:
        return NotificationType.announcement;
    }
  }
}
