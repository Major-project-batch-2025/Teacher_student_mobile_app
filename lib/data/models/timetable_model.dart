// lib/data/models/timetable_model.dart
// Purpose: Data model for timetable and class slots with JSON serialization

import '../../domain/entities/timetable.dart';

class ClassSlotModel extends ClassSlot {
  const ClassSlotModel({
    required super.id,
    required super.subject,
    required super.teacherId,
    required super.teacherName,
    required super.roomNumber,
    required super.dayOfWeek,
    required super.startTime,
    required super.endTime,
    required super.durationMinutes,
    super.isCancelled,
    super.isExtraClass,
    super.isRescheduled,
    super.originalSlotId,
    required super.updatedAt,
    super.colorCode,
  });

  // Factory constructor to create a ClassSlotModel from JSON
  factory ClassSlotModel.fromJson(Map<String, dynamic> json) {
    return ClassSlotModel(
      id: json['id'],
      subject: json['subject'],
      teacherId: json['teacherId'],
      teacherName: json['teacherName'],
      roomNumber: json['roomNumber'],
      dayOfWeek: json['dayOfWeek'],
      startTime: json['startTime'],
      endTime: json['endTime'],
      durationMinutes: json['durationMinutes'],
      isCancelled: json['isCancelled'] ?? false,
      isExtraClass: json['isExtraClass'] ?? false,
      isRescheduled: json['isRescheduled'] ?? false,
      originalSlotId: json['originalSlotId'],
      updatedAt: DateTime.parse(json['updatedAt']),
      colorCode: json['colorCode'] ?? 'blue',
    );
  }

  // Convert ClassSlotModel to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'subject': subject,
      'teacherId': teacherId,
      'teacherName': teacherName,
      'roomNumber': roomNumber,
      'dayOfWeek': dayOfWeek,
      'startTime': startTime,
      'endTime': endTime,
      'durationMinutes': durationMinutes,
      'isCancelled': isCancelled,
      'isExtraClass': isExtraClass,
      'isRescheduled': isRescheduled,
      'originalSlotId': originalSlotId,
      'updatedAt': updatedAt.toIso8601String(),
      'colorCode': colorCode,
    };
  }
  
  // Create ClassSlotModel from ClassSlot entity
  factory ClassSlotModel.fromEntity(ClassSlot slot) {
    return ClassSlotModel(
      id: slot.id,
      subject: slot.subject,
      teacherId: slot.teacherId,
      teacherName: slot.teacherName,
      roomNumber: slot.roomNumber,
      dayOfWeek: slot.dayOfWeek,
      startTime: slot.startTime,
      endTime: slot.endTime,
      durationMinutes: slot.durationMinutes,
      isCancelled: slot.isCancelled,
      isExtraClass: slot.isExtraClass,
      isRescheduled: slot.isRescheduled,
      originalSlotId: slot.originalSlotId,
      updatedAt: slot.updatedAt,
      colorCode: slot.colorCode,
    );
  }
}

class TimetableModel extends Timetable {
  const TimetableModel({
    required super.id,
    required super.department,
    required super.section,
    required super.semester,
    required super.validFrom,
    required super.validUntil,
    required super.slots,
    required super.lastUpdated,
  });

  // Factory constructor to create a TimetableModel from JSON
  factory TimetableModel.fromJson(Map<String, dynamic> json) {
    final slotsList = (json['slots'] as List)
        .map((slotJson) => ClassSlotModel.fromJson(slotJson))
        .toList();

    return TimetableModel(
      id: json['id'],
      department: json['department'],
      section: json['section'],
      semester: json['semester'],
      validFrom: DateTime.parse(json['validFrom']),
      validUntil: DateTime.parse(json['validUntil']),
      slots: slotsList,
      lastUpdated: DateTime.parse(json['lastUpdated']),
    );
  }

  // Convert TimetableModel to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'department': department,
      'section': section,
      'semester': semester,
      'validFrom': validFrom.toIso8601String(),
      'validUntil': validUntil.toIso8601String(),
      'slots': slots.map((slot) => 
        (slot is ClassSlotModel) 
          ? slot.toJson() 
          : ClassSlotModel.fromEntity(slot).toJson()
      ).toList(),
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }
  
  // Create TimetableModel from Timetable entity
  factory TimetableModel.fromEntity(Timetable timetable) {
    return TimetableModel(
      id: timetable.id,
      department: timetable.department,
      section: timetable.section,
      semester: timetable.semester,
      validFrom: timetable.validFrom,
      validUntil: timetable.validUntil,
      slots: timetable.slots.map((slot) => 
        (slot is ClassSlotModel) 
          ? slot 
          : ClassSlotModel.fromEntity(slot)
      ).toList(),
      lastUpdated: timetable.lastUpdated,
    );
  }
}