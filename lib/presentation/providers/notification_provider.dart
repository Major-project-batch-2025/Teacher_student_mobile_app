import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../data/models/notification_model.dart';

class NotificationProvider extends ChangeNotifier {
  final List<NotificationModel> _notifications = [];
  List<NotificationModel> get notifications => _notifications;

  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  final _uuid = const Uuid();

  void addNotification(NotificationModel notification) {
    _notifications.insert(0, notification);
    notifyListeners();
  }

  Future<void> markAsRead(String notificationId) async {
    final index = _notifications.indexWhere((n) => n.id == notificationId);
    if (index != -1) {
      _notifications[index] = _notifications[index].markAsRead();
      notifyListeners();
    }
  }

  Future<void> markAllAsRead() async {
    _isLoading = true;
    notifyListeners();

    try {
      for (var i = 0; i < _notifications.length; i++) {
        if (!_notifications[i].isRead) {
          _notifications[i] = _notifications[i].markAsRead();
        }
      }
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = 'Failed to mark notifications as read: ${e.toString()}';
      notifyListeners();
    }
  }

  void clearNotifications() {
    _notifications.clear();
    notifyListeners();
  }

  Future<void> fetchNotifications({
    required String userId,
    required bool isTeacher, // Added this parameter
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Get the appropriate collection based on user type
      final String collection =
          isTeacher ? 'TeacherNotifications' : 'StudentNotifications';

      final QuerySnapshot snapshot =
          await FirebaseFirestore.instance
              .collection(collection)
              .where('userId', isEqualTo: userId)
              .orderBy('timestamp', descending: true)
              .get();

      _notifications.clear();
      _notifications.addAll(
        snapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return NotificationModel(
            id: doc.id,
            title: data['title'] ?? '',
            message: data['message'] ?? '',
            type: _parseNotificationType(data['type'] ?? 'other'),
            timestamp: (data['timestamp'] as Timestamp).toDate(),
            userId: data['userId'] ?? '',
            isRead: data['isRead'] ?? false,
            data: data['data'] ?? {},
          );
        }),
      );

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to fetch notifications: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
    }
  }

  NotificationType _parseNotificationType(String type) {
    switch (type.toLowerCase()) {
      case 'class_cancelled':
        return NotificationType.classCancelled;
      case 'extra_class':
        return NotificationType.extraClass;
      case 'class_rescheduled':
        return NotificationType.classRescheduled;
      case 'announcement':
        return NotificationType.announcement;
      default:
        return NotificationType.other;
    }
  }
}
