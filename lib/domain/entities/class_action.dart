// lib/domain/entities/class_action.dart
// Purpose: Model for representing class actions like cancellations, rescheduling, or extra classes

import 'package:equatable/equatable.dart';

enum ActionType {
  cancel,
  reschedule,
  extraClass,
  normalize, // Revert back to original state
}

class ClassAction extends Equatable {
  final String id;
  final ActionType actionType;
  final String teacherId;
  final String teacherName;
  final String originSlotId; // Original class slot ID
  final String? targetSlotId; // Target slot ID for rescheduling
  final DateTime timestamp;
  final String reason;
  final String subject;
  final DateTime expiresAt; // When this action expires (7 days)
  final bool isApproved; // If admin approval is required
  final String? approvedBy;
  final DateTime? approvedAt;
  
  const ClassAction({
    required this.id,
    required this.actionType,
    required this.teacherId,
    required this.teacherName,
    required this.originSlotId,
    this.targetSlotId,
    required this.timestamp,
    required this.reason,
    required this.subject,
    required this.expiresAt,
    this.isApproved = false,
    this.approvedBy,
    this.approvedAt,
  });
  
  @override
  List<Object?> get props => [
    id, actionType, teacherId, teacherName, originSlotId,
    targetSlotId, timestamp, reason, subject, expiresAt,
    isApproved, approvedBy, approvedAt,
  ];
  
  // Get the user-friendly string for action type
  String get actionTypeString {
    switch (actionType) {
      case ActionType.cancel:
        return 'Cancelled';
      case ActionType.reschedule:
        return 'Rescheduled';
      case ActionType.extraClass:
        return 'Extra Class';
      case ActionType.normalize:
        return 'Normalized';
    }
  }
  
  // Check if the action is expired (for auto-reverting)
  bool isExpired() {
    final now = DateTime.now();
    return now.isAfter(expiresAt);
  }
  
  // Create a copy with updated fields
  ClassAction copyWith({
    String? id,
    ActionType? actionType,
    String? teacherId,
    String? teacherName,
    String? originSlotId,
    String? targetSlotId,
    DateTime? timestamp,
    String? reason,
    String? subject,
    DateTime? expiresAt,
    bool? isApproved,
    String? approvedBy,
    DateTime? approvedAt,
  }) {
    return ClassAction(
      id: id ?? this.id,
      actionType: actionType ?? this.actionType,
      teacherId: teacherId ?? this.teacherId,
      teacherName: teacherName ?? this.teacherName,
      originSlotId: originSlotId ?? this.originSlotId,
      targetSlotId: targetSlotId ?? this.targetSlotId,
      timestamp: timestamp ?? this.timestamp,
      reason: reason ?? this.reason,
      subject: subject ?? this.subject,
      expiresAt: expiresAt ?? this.expiresAt,
      isApproved: isApproved ?? this.isApproved,
      approvedBy: approvedBy ?? this.approvedBy,
      approvedAt: approvedAt ?? this.approvedAt,
    );
  }
  
  // Mark action as approved
  ClassAction approve(String adminId) {
    return copyWith(
      isApproved: true,
      approvedBy: adminId,
      approvedAt: DateTime.now(),
    );
  }
  
  // Empty action for initial state
  factory ClassAction.empty() => ClassAction(
    id: '',
    actionType: ActionType.cancel,
    teacherId: '',
    teacherName: '',
    originSlotId: '',
    timestamp: DateTime.now(),
    reason: '',
    subject: '',
    expiresAt: DateTime.now().add(const Duration(days: 7)),
  );
}