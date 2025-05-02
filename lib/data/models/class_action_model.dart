// lib/data/models/class_action_model.dart
// Purpose: Data model for class actions with JSON serialization

import '../../domain/entities/class_action.dart';

class ClassActionModel extends ClassAction {
  const ClassActionModel({
    required super.id,
    required super.actionType,
    required super.teacherId,
    required super.teacherName,
    required super.originSlotId,
    super.targetSlotId,
    required super.timestamp,
    required super.reason,
    required super.subject,
    required super.expiresAt,
    super.isApproved = false,
    super.approvedBy,
    super.approvedAt,
  });

  // Factory constructor to create a ClassActionModel from JSON
  factory ClassActionModel.fromJson(Map<String, dynamic> json) {
    return ClassActionModel(
      id: json['id'],
      actionType: _parseActionType(json['actionType']),
      teacherId: json['teacherId'],
      teacherName: json['teacherName'],
      originSlotId: json['originSlotId'],
      targetSlotId: json['targetSlotId'],
      timestamp: DateTime.parse(json['timestamp']),
      reason: json['reason'],
      subject: json['subject'],
      expiresAt: DateTime.parse(json['expiresAt']),
      isApproved: json['isApproved'] ?? false,
      approvedBy: json['approvedBy'],
      approvedAt: json['approvedAt'] != null 
          ? DateTime.parse(json['approvedAt']) 
          : null,
    );
  }

  // Convert ClassActionModel to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'actionType': actionType.toString().split('.').last,
      'teacherId': teacherId,
      'teacherName': teacherName,
      'originSlotId': originSlotId,
      'targetSlotId': targetSlotId,
      'timestamp': timestamp.toIso8601String(),
      'reason': reason,
      'subject': subject,
      'expiresAt': expiresAt.toIso8601String(),
      'isApproved': isApproved,
      'approvedBy': approvedBy,
      'approvedAt': approvedAt?.toIso8601String(),
    };
  }

  // Helper to parse ActionType from string
  static ActionType _parseActionType(String typeStr) {
    switch (typeStr.toLowerCase()) {
      case 'cancel':
        return ActionType.cancel;
      case 'reschedule':
        return ActionType.reschedule;
      case 'extraclass':
        return ActionType.extraClass;
      case 'normalize':
        return ActionType.normalize;
      default:
        return ActionType.cancel;
    }
  }
  
  // Create ClassActionModel from ClassAction entity
  factory ClassActionModel.fromEntity(ClassAction action) {
    return ClassActionModel(
      id: action.id,
      actionType: action.actionType,
      teacherId: action.teacherId,
      teacherName: action.teacherName,
      originSlotId: action.originSlotId,
      targetSlotId: action.targetSlotId,
      timestamp: action.timestamp,
      reason: action.reason,
      subject: action.subject,
      expiresAt: action.expiresAt,
      isApproved: action.isApproved,
      approvedBy: action.approvedBy,
      approvedAt: action.approvedAt,
    );
  }
}