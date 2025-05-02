// lib/presentation/providers/notification_provider.dart
// Purpose: Provider for notification state management

import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../data/models/notification_model.dart';

class NotificationProvider extends ChangeNotifier {
  // List of notifications
  List<NotificationModel> _notifications = [];
  List<NotificationModel> get notifications => _notifications;
  
  // Unread count
  int get unreadCount => _notifications.where((n) => !n.isRead).length;
  
  // Loading state
  bool _isLoading = false;
  bool get isLoading => _isLoading;
  
  // Error state
  String? _error;
  String? get error => _error;
  
  // UUID generator for unique IDs
  final _uuid = const Uuid();
  
  // Initialize and fetch notifications
  Future<void> fetchNotifications({
    required String userId,
    required bool isTeacher,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      // In a real app, this would call a repository
      // For now, generate sample notifications
      await Future.delayed(const Duration(milliseconds: 800)); // Simulate network delay
      
      _notifications = _generateSampleNotifications(userId, isTeacher);
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = 'Failed to load notifications: ${e.toString()}';
      notifyListeners();
    }
  }
  
  // Mark a notification as read
  Future<void> markAsRead(String notificationId) async {
    final index = _notifications.indexWhere((n) => n.id == notificationId);
    
    if (index != -1) {
      // Update the notification
      final updatedNotification = _notifications[index].markAsRead();
      
      // In a real app, this would call a repository
      // For now, just update the local state
      await Future.delayed(const Duration(milliseconds: 300)); // Simulate network delay
      
      _notifications[index] = updatedNotification;
      notifyListeners();
    }
  }
  
  // Mark all notifications as read
  Future<void> markAllAsRead() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      // In a real app, this would call a repository
      // For now, just update the local state
      await Future.delayed(const Duration(milliseconds: 500)); // Simulate network delay
      
      _notifications = _notifications.map((n) => n.markAsRead()).toList();
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = 'Failed to mark notifications as read: ${e.toString()}';
      notifyListeners();
    }
  }
  
  // Add a new notification (used when a class action is applied)
  void addNotification({
    required String title,
    required String message,
    required NotificationType type,
    required String userId,
    Map<String, dynamic>? data,
  }) {
    final newNotification = NotificationModel(
      id: _uuid.v4(),
      title: title,
      message: message,
      type: type,
      timestamp: DateTime.now(),
      userId: userId,
      data: data,
    );
    
    _notifications = [newNotification, ..._notifications];
    notifyListeners();
  }
  
  // Generate sample notifications for testing
  List<NotificationModel> _generateSampleNotifications(String userId, bool isTeacher) {
    final now = DateTime.now();
    
    if (isTeacher) {
      // Teacher notifications
      return [
        NotificationModel(
          id: '1',
          title: 'Class Approved',
          message: 'Your request to cancel Mathematics class on Wednesday has been approved.',
          type: NotificationType.actionApproved,
          timestamp: now.subtract(const Duration(hours: 2)),
          userId: userId,
          data: {
            'actionId': '1',
            'subject': 'Mathematics',
            'dayOfWeek': 2,
          },
        ),
        NotificationModel(
          id: '2',
          title: 'Timetable Updated',
          message: 'The timetable for CS-3A has been updated for next week.',
          type: NotificationType.announcement,
          timestamp: now.subtract(const Duration(days: 1)),
          userId: userId,
        ),
        NotificationModel(
          id: '3',
          title: 'Extra Class Request',
          message: 'Your request for an extra Physics class is pending approval.',
          type: NotificationType.extraClass,
          timestamp: now.subtract(const Duration(days: 2)),
          isRead: true,
          userId: userId,
        ),
      ];
    } else {
      // Student notifications
      return [
        NotificationModel(
          id: '1',
          title: 'Class Cancelled',
          message: 'Mathematics class on Wednesday has been cancelled.',
          type: NotificationType.classCancelled,
          timestamp: now.subtract(const Duration(hours: 3)),
          userId: userId,
          data: {
            'subject': 'Mathematics',
            'dayOfWeek': 2,
          },
        ),
        NotificationModel(
          id: '2',
          title: 'Extra Class',
          message: 'Extra Physics class on Saturday at 10:00 AM for exam preparation.',
          type: NotificationType.extraClass,
          timestamp: now.subtract(const Duration(days: 1)),
          userId: userId,
          data: {
            'subject': 'Physics',
            'dayOfWeek': 5,
            'startTime': '10:00',
            'endTime': '11:30',
          },
        ),
        NotificationModel(
          id: '3',
          title: 'Rescheduled Class',
          message: 'Computer Science class moved from Thursday to Friday 9:00 AM.',
          type: NotificationType.classRescheduled,
          timestamp: now.subtract(const Duration(days: 2)),
          isRead: true,
          userId: userId,
        ),
        NotificationModel(
          id: '4',
          title: 'Semester Registration',
          message: 'Registration for next semester opens on Monday.',
          type: NotificationType.announcement,
          timestamp: now.subtract(const Duration(days: 3)),
          isRead: true,
          userId: userId,
        ),
      ];
    }
  }
}