import 'package:equatable/equatable.dart';

enum NotificationType {
  classCancelled,
  classRescheduled,
  extraClass,
  announcement,
  actionApproved,
  actionDenied,
  other,
}

class NotificationModel extends Equatable {
  final String id;
  final String title;
  final String message;
  final NotificationType type;
  final DateTime timestamp;
  final String userId;
  final Map<String, dynamic> data;
  final bool isRead;

  const NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.timestamp,
    required this.userId,
    required this.data,
    this.isRead = false,
  });

  NotificationModel markAsRead() {
    return NotificationModel(
      id: id,
      title: title,
      message: message,
      type: type,
      timestamp: timestamp,
      userId: userId,
      data: data,
      isRead: true,
    );
  }

  NotificationModel copyWith({
    String? id,
    String? title,
    String? message,
    NotificationType? type,
    DateTime? timestamp,
    String? userId,
    Map<String, dynamic>? data,
    bool? isRead,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      timestamp: timestamp ?? this.timestamp,
      userId: userId ?? this.userId,
      data: data ?? this.data,
      isRead: isRead ?? this.isRead,
    );
  }

  @override
  List<Object?> get props => [
    id,
    title,
    message,
    type,
    timestamp,
    userId,
    data,
    isRead,
  ];

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'type': type.toString().split('.').last,
      'timestamp': timestamp.toIso8601String(),
      'userId': userId,
      'data': data,
      'isRead': isRead,
    };
  }

  // Add fromJson factory constructor as well for completeness
  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      type: _parseNotificationType(json['type'] ?? 'other'),
      timestamp:
          json['timestamp'] is String
              ? DateTime.parse(json['timestamp'])
              : (json['timestamp'] as DateTime),
      userId: json['userId'] ?? '',
      data: json['data'] as Map<String, dynamic>? ?? {},
      isRead: json['isRead'] ?? false,
    );
  }

  // Helper method to parse notification type
  static NotificationType _parseNotificationType(String type) {
    switch (type.toLowerCase()) {
      case 'classcancelled':
        return NotificationType.classCancelled;
      case 'classrescheduled':
        return NotificationType.classRescheduled;
      case 'extraclass':
        return NotificationType.extraClass;
      case 'actionapproved':
        return NotificationType.actionApproved;
      case 'actiondenied':
        return NotificationType.actionDenied;
      case 'announcement':
        return NotificationType.announcement;
      default:
        return NotificationType.other;
    }
  }
}
