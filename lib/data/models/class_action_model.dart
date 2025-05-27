// lib/data/models/class_action_model.dart
// Purpose: Data model for class actions with JSON serialization - Updated with swap functionality

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
    // New swap-related parameters
    super.swapWithTeacherId,
    super.swapWithTeacherName,
    super.swapTargetSlotId,
    super.swapTargetSection,
    super.swapTargetDay,
    super.swapTargetTime,
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
      // Parse new swap-related fields
      swapWithTeacherId: json['swapWithTeacherId'],
      swapWithTeacherName: json['swapWithTeacherName'],
      swapTargetSlotId: json['swapTargetSlotId'],
      swapTargetSection: json['swapTargetSection'],
      swapTargetDay: json['swapTargetDay'],
      swapTargetTime: json['swapTargetTime'],
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
      // Include new swap-related fields in JSON
      'swapWithTeacherId': swapWithTeacherId,
      'swapWithTeacherName': swapWithTeacherName,
      'swapTargetSlotId': swapTargetSlotId,
      'swapTargetSection': swapTargetSection,
      'swapTargetDay': swapTargetDay,
      'swapTargetTime': swapTargetTime,
    };
  }

  // Helper to parse ActionType from string - Updated with swap case
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
      case 'swap': // New case for swap action
        return ActionType.swap;
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
      // Include swap-related fields
      swapWithTeacherId: action.swapWithTeacherId,
      swapWithTeacherName: action.swapWithTeacherName,
      swapTargetSlotId: action.swapTargetSlotId,
      swapTargetSection: action.swapTargetSection,
      swapTargetDay: action.swapTargetDay,
      swapTargetTime: action.swapTargetTime,
    );
  }
}