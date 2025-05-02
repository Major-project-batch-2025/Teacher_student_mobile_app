// lib/data/models/notification_model.dart
// Purpose: Data model for notifications with JSON serialization

import 'package:equatable/equatable.dart';

enum NotificationType {
  classCancelled,
  classRescheduled,
  extraClass,
  announcement,
  actionApproved,
  actionDenied,
}

class NotificationModel extends Equatable {
  final String id;
  final String title;
  final String message;
  final NotificationType type;
  final DateTime timestamp;
  final bool isRead;
  final String userId;
  final Map<String, dynamic>? data; // Additional data like class details
  
  const NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.timestamp,
    this.isRead = false,
    required this.userId,
    this.data,
  });
  
  @override
  List<Object?> get props => [id, title, message, type, timestamp, isRead, userId, data];
  
  // Factory constructor to create a NotificationModel from JSON
  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'],
      title: json['title'],
      message: json['message'],
      type: _parseNotificationType(json['type']),
      timestamp: DateTime.parse(json['timestamp']),
      isRead: json['isRead'] ?? false,
      userId: json['userId'],
      data: json['data'],
    );
  }
  
  // Convert NotificationModel to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'type': type.toString().split('.').last,
      'timestamp': timestamp.toIso8601String(),
      'isRead': isRead,
      'userId': userId,
      'data': data,
    };
  }
  
  // Helper to parse NotificationType from string
  static NotificationType _parseNotificationType(String typeStr) {
    switch (typeStr.toLowerCase()) {
      case 'classcancelled':
        return NotificationType.classCancelled;
      case 'classrescheduled':
        return NotificationType.classRescheduled;
      case 'extraclass':
        return NotificationType.extraClass;
      case 'announcement':
        return NotificationType.announcement;
      case 'actionapproved':
        return NotificationType.actionApproved;
      case 'actiondenied':
        return NotificationType.actionDenied;
      default:
        return NotificationType.announcement;
    }
  }
  
  // Mark notification as read
  NotificationModel markAsRead() {
    return NotificationModel(
      id: id,
      title: title,
      message: message,
      type: type,
      timestamp: timestamp,
      isRead: true,
      userId: userId,
      data: data,
    );
  }
  
  // Get icon for notification based on type
  String get icon {
    switch (type) {
      case NotificationType.classCancelled:
        return 'cancel';
      case NotificationType.classRescheduled:
        return 'event_repeat';
      case NotificationType.extraClass:
        return 'add_circle';
      case NotificationType.announcement:
        return 'announcement';
      case NotificationType.actionApproved:
        return 'check_circle';
      case NotificationType.actionDenied:
        return 'cancel';
    }
  }
}