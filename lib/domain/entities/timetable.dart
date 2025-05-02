// lib/domain/entities/timetable.dart
// Purpose: Timetable entity containing a week's schedule with class slots

import 'package:equatable/equatable.dart';

// ClassSlot represents a single class session
class ClassSlot extends Equatable {
  final String id;
  final String subject;
  final String teacherId;
  final String teacherName;
  final String roomNumber;
  final int dayOfWeek; // 0 = Monday, 1 = Tuesday, etc.
  final String startTime; // Format: "09:00"
  final String endTime;   // Format: "10:30"
  final int durationMinutes; // Duration in minutes
  final bool isCancelled;
  final bool isExtraClass;
  final bool isRescheduled;
  final String? originalSlotId; // Reference to original slot if rescheduled
  final DateTime updatedAt; // Last update timestamp
  
  // UI Properties
  final String colorCode; // Color code for UI display
  
  const ClassSlot({
    required this.id,
    required this.subject,
    required this.teacherId,
    required this.teacherName,
    required this.roomNumber,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    required this.durationMinutes,
    this.isCancelled = false,
    this.isExtraClass = false,
    this.isRescheduled = false,
    this.originalSlotId,
    required this.updatedAt,
    this.colorCode = 'blue', // Default color
  });
  
  @override
  List<Object?> get props => [
    id, subject, teacherId, teacherName, roomNumber, 
    dayOfWeek, startTime, endTime, durationMinutes,
    isCancelled, isExtraClass, isRescheduled, originalSlotId, updatedAt
  ];
  
  // Create a copy with updated fields
  ClassSlot copyWith({
    String? id,
    String? subject,
    String? teacherId,
    String? teacherName,
    String? roomNumber,
    int? dayOfWeek,
    String? startTime,
    String? endTime,
    int? durationMinutes,
    bool? isCancelled,
    bool? isExtraClass,
    bool? isRescheduled,
    String? originalSlotId,
    DateTime? updatedAt,
    String? colorCode,
  }) {
    return ClassSlot(
      id: id ?? this.id,
      subject: subject ?? this.subject,
      teacherId: teacherId ?? this.teacherId,
      teacherName: teacherName ?? this.teacherName,
      roomNumber: roomNumber ?? this.roomNumber,
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      isCancelled: isCancelled ?? this.isCancelled,
      isExtraClass: isExtraClass ?? this.isExtraClass,
      isRescheduled: isRescheduled ?? this.isRescheduled,
      originalSlotId: originalSlotId ?? this.originalSlotId,
      updatedAt: updatedAt ?? this.updatedAt,
      colorCode: colorCode ?? this.colorCode,
    );
  }
  
  // Mark class as cancelled
  ClassSlot markAsCancelled() {
    return copyWith(
      isCancelled: true,
      updatedAt: DateTime.now(),
    );
  }
  
  // Mark as rescheduled with reference to original slot
  ClassSlot markAsRescheduled(String originalId) {
    return copyWith(
      isRescheduled: true,
      originalSlotId: originalId,
      updatedAt: DateTime.now(),
    );
  }
  
  // Create an empty ClassSlot (for fallback/default cases)
  factory ClassSlot.empty() => ClassSlot(
    id: '',
    subject: '',
    teacherId: '',
    teacherName: '',
    roomNumber: '',
    dayOfWeek: 0,
    startTime: '00:00',
    endTime: '00:00',
    durationMinutes: 0,
    updatedAt: DateTime.now(),
  );
}

// Timetable containing a collection of class slots for a specific section/semester
class Timetable extends Equatable {
  final String id;
  final String department;
  final String section;
  final int semester;
  final DateTime validFrom;
  final DateTime validUntil;
  final List<ClassSlot> slots;
  final DateTime lastUpdated;
  
  const Timetable({
    required this.id,
    required this.department,
    required this.section,
    required this.semester,
    required this.validFrom,
    required this.validUntil,
    required this.slots,
    required this.lastUpdated,
  });
  
  @override
  List<Object?> get props => [
    id, department, section, semester, 
    validFrom, validUntil, slots, lastUpdated
  ];
  
  // Get all slots for a specific day of week
  List<ClassSlot> getSlotsByDay(int dayOfWeek) {
    return slots.where((slot) => slot.dayOfWeek == dayOfWeek).toList();
  }
  
  // Get active slots (not cancelled) for a specific day
  List<ClassSlot> getActiveSlotsByDay(int dayOfWeek) {
    return slots.where((slot) => 
      slot.dayOfWeek == dayOfWeek && !slot.isCancelled
    ).toList()..sort((a, b) => a.startTime.compareTo(b.startTime));
  }
  
  // Create a copy with updated fields
  Timetable copyWith({
    String? id,
    String? department,
    String? section,
    int? semester,
    DateTime? validFrom,
    DateTime? validUntil,
    List<ClassSlot>? slots,
    DateTime? lastUpdated,
  }) {
    return Timetable(
      id: id ?? this.id,
      department: department ?? this.department,
      section: section ?? this.section,
      semester: semester ?? this.semester,
      validFrom: validFrom ?? this.validFrom,
      validUntil: validUntil ?? this.validUntil,
      slots: slots ?? this.slots,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
  
  // Create an updated timetable with a modified class slot
  Timetable updateSlot(ClassSlot updatedSlot) {
    final newSlots = slots.map((slot) {
      if (slot.id == updatedSlot.id) {
        return updatedSlot;
      }
      return slot;
    }).toList();
    
    return copyWith(
      slots: newSlots,
      lastUpdated: DateTime.now(),
    );
  }
  
  // Add a new class slot (for extra classes)
  Timetable addSlot(ClassSlot newSlot) {
    final newSlots = List<ClassSlot>.from(slots)..add(newSlot);
    return copyWith(
      slots: newSlots,
      lastUpdated: DateTime.now(),
    );
  }
  
  // Empty timetable for initial state
  factory Timetable.empty() => Timetable(
    id: '',
    department: '',
    section: '',
    semester: 0,
    validFrom: DateTime.now(),
    validUntil: DateTime.now().add(const Duration(days: 180)),
    slots: [],
    lastUpdated: DateTime.now(),
  );
}