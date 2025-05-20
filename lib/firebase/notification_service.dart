import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:timetable_app/presentation/student/screens/student_notifications.dart';
import 'package:timetable_app/presentation/teacher/screens/teacher_notifications.dart';
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

        // Show a material banner instead of snackbar
        ScaffoldMessenger.of(_context!).showMaterialBanner(
          MaterialBanner(
            backgroundColor: Colors.grey.shade900,
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  notification.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  notification.message,
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  ScaffoldMessenger.of(_context!).hideCurrentMaterialBanner();
                },
                child: const Text('Dismiss'),
              ),
              TextButton(
                onPressed: () {
                  ScaffoldMessenger.of(_context!).hideCurrentMaterialBanner();
                  // Navigate to notifications screen based on user type
                  Navigator.push(
                    _context!,
                    MaterialPageRoute(
                      builder:
                          (context) =>
                              notification.data['isTeacher'] == true
                                  ? const TeacherNotificationsScreen()
                                  : const StudentNotificationsScreen(),
                    ),
                  );
                },
                child: const Text('View'),
              ),
            ],
          ),
        );

        // Auto-dismiss after 3 seconds
        Future.delayed(const Duration(seconds: 5), () {
          if (_context!.mounted) {
            ScaffoldMessenger.of(_context!).hideCurrentMaterialBanner();
          }
        });
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
