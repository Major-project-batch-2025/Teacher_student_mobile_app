// lib/presentation/providers/timetable_provider.dart
// Purpose: Provider for timetable state management with hardcoded data for now

import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

// import '../../core/utils/date_helpers.dart';
import '../../domain/entities/class_action.dart';
import '../../domain/entities/timetable.dart';

class TimetableProvider extends ChangeNotifier {
  // Current timetable data
  Timetable? _timetable;
  Timetable? get timetable => _timetable;
  
  // Class actions
  List<ClassAction> _actions = [];
  List<ClassAction> get actions => _actions;
  
  // Selected date
  DateTime _selectedDate = DateTime.now();
  DateTime get selectedDate => _selectedDate;
  
  // Loading state
  bool _isLoading = false;
  bool get isLoading => _isLoading;
  
  // Error state
  String? _error;
  String? get error => _error;
  
  // UUID generator for unique IDs
  final _uuid = const Uuid();
  
  // Initialize with loading timetable for a specific section/semester
  Future<void> initialize({
    required String department,
    required String section,
    required int semester,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      // In a real app, this would call a repository
      // For now, generate a sample timetable
      await Future.delayed(const Duration(milliseconds: 800)); // Simulate network delay
      
      _timetable = _generateSampleTimetable(
        department: department,
        section: section,
        semester: semester,
      );
      
      _actions = _generateSampleActions();
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = 'Failed to load timetable: ${e.toString()}';
      notifyListeners();
    }
  }
  
  // Set selected date
  void setSelectedDate(DateTime date) {
    _selectedDate = date;
    notifyListeners();
  }
  
  // Get active slots for the selected date
  List<ClassSlot> getActiveSlotsForSelectedDate() {
    if (_timetable == null) return [];
    
    final dayOfWeek = _selectedDate.weekday - 1; // Convert to 0-based (Monday = 0)
    return _timetable!.getActiveSlotsByDay(dayOfWeek);
  }
  
  // Apply a class action (cancel, reschedule, extra class)
  Future<void> applyClassAction(ActionType actionType, {
    required ClassSlot originSlot,
    ClassSlot? targetSlot,
    required String teacherId,
    required String teacherName,
    required String reason,
  }) async {
    if (_timetable == null) return;
    
    _isLoading = true;
    notifyListeners();
    
    try {
      // Create a new class action
      final newAction = ClassAction(
        id: _uuid.v4(),
        actionType: actionType,
        teacherId: teacherId,
        teacherName: teacherName,
        originSlotId: originSlot.id,
        targetSlotId: targetSlot?.id,
        timestamp: DateTime.now(),
        reason: reason,
        subject: originSlot.subject,
        expiresAt: DateTime.now().add(const Duration(days: 7)), // Expires after 7 days
      );
      
      // In a real app, this would call a repository
      // For now, just update the local state
      await Future.delayed(const Duration(milliseconds: 500)); // Simulate network delay
      
      // Update the timetable based on the action
      Timetable updatedTimetable = _timetable!;
      
      switch (actionType) {
        case ActionType.cancel:
          // Mark the original slot as cancelled
          updatedTimetable = _timetable!.updateSlot(
            originSlot.copyWith(
              isCancelled: true,
              updatedAt: DateTime.now(),
            ),
          );
          break;
          
        case ActionType.reschedule:
          if (targetSlot == null) break;
          
          // Mark the original slot as cancelled
          updatedTimetable = _timetable!.updateSlot(
            originSlot.copyWith(
              isCancelled: true,
              updatedAt: DateTime.now(),
            ),
          );
          
          // Create a new slot for the rescheduled class
          final newSlot = ClassSlot(
            id: _uuid.v4(),
            subject: originSlot.subject,
            teacherId: originSlot.teacherId,
            teacherName: originSlot.teacherName,
            roomNumber: originSlot.roomNumber,
            dayOfWeek: targetSlot.dayOfWeek,
            startTime: targetSlot.startTime,
            endTime: targetSlot.endTime,
            durationMinutes: 60, // Modified to 1 hour (60 minutes)
            isRescheduled: true,
            originalSlotId: originSlot.id,
            updatedAt: DateTime.now(),
            colorCode: originSlot.colorCode,
          );
          
          updatedTimetable = updatedTimetable.addSlot(newSlot);
          break;
          
        case ActionType.extraClass:
          if (targetSlot == null) break;
          
          // Create a new slot for the extra class
          final newSlot = ClassSlot(
            id: _uuid.v4(),
            subject: originSlot.subject,
            teacherId: originSlot.teacherId,
            teacherName: originSlot.teacherName,
            roomNumber: targetSlot.roomNumber,
            dayOfWeek: targetSlot.dayOfWeek,
            startTime: targetSlot.startTime,
            endTime: targetSlot.endTime,
            durationMinutes: 60, // Modified to 1 hour (60 minutes)
            isExtraClass: true,
            updatedAt: DateTime.now(),
            colorCode: originSlot.colorCode,
          );
          
          updatedTimetable = updatedTimetable.addSlot(newSlot);
          break;
          
        case ActionType.normalize:
          // Revert the slot back to normal (remove any cancellations/reschedules)
          updatedTimetable = _timetable!.updateSlot(
            originSlot.copyWith(
              isCancelled: false,
              isRescheduled: false,
              isExtraClass: false,
              updatedAt: DateTime.now(),
            ),
          );
          break;
      }
      
      // Update the state
      _timetable = updatedTimetable;
      _actions = [..._actions, newAction];
      
      // Check for expired actions and auto-revert them
      _checkAndRevertExpiredActions();
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = 'Failed to apply class action: ${e.toString()}';
      notifyListeners();
    }
  }
  
  // Check for expired actions and revert them
  void _checkAndRevertExpiredActions() {
    if (_timetable == null) return;
    
    final now = DateTime.now();
    final expiredActions = _actions.where((action) => 
      now.isAfter(action.expiresAt) && !action.isApproved
    ).toList();
    
    // Revert each expired action
    for (final action in expiredActions) {
      final originSlotId = action.originSlotId;
      final originSlot = _timetable!.slots.firstWhere(
        (slot) => slot.id == originSlotId,
        orElse: () => ClassSlot.empty(),
      );
      
      if (originSlot.id.isEmpty) continue;
      
      switch (action.actionType) {
        case ActionType.cancel:
          // Revert cancellation
          _timetable = _timetable!.updateSlot(
            originSlot.copyWith(
              isCancelled: false,
              updatedAt: now,
            ),
          );
          break;
          
        case ActionType.reschedule:
        case ActionType.extraClass:
          // Find and remove any rescheduled or extra slots
          final slotsToRemove = _timetable!.slots.where((slot) => 
            slot.originalSlotId == originSlotId || 
            (slot.isExtraClass && slot.subject == originSlot.subject)
          ).toList();
          
          // Remove these slots
          final updatedSlots = _timetable!.slots.where((slot) => 
            !slotsToRemove.contains(slot)
          ).toList();
          
          // Revert the original slot if it was cancelled
          final updatedOriginSlot = originSlot.copyWith(
            isCancelled: false,
            updatedAt: now,
          );
          
          // Update the slots
          final newSlots = List<ClassSlot>.from(updatedSlots)
            ..removeWhere((slot) => slot.id == originSlot.id)
            ..add(updatedOriginSlot);
          
          _timetable = _timetable!.copyWith(
            slots: newSlots,
            lastUpdated: now,
          );
          break;
          
        case ActionType.normalize:
          // No need to revert normalization
          break;
      }
    }
    
    // Remove expired actions
    _actions = _actions.where((action) => !expiredActions.contains(action)).toList();
  }
  
  // Generate a sample timetable for testing
  Timetable _generateSampleTimetable({
    required String department,
    required String section,
    required int semester,
  }) {
    // Sample class slots matching the design in the images
    final List<ClassSlot> slots = [
      // Monday
      ClassSlot(
        id: '1',
        subject: 'FAFL',
        teacherId: 'teacher1',
        teacherName: 'Appu Coco',
        roomNumber: 'Room 101',
        dayOfWeek: 0, // Monday
        startTime: '09:00',
        endTime: '10:00', // Modified to 1 hour
        durationMinutes: 60, // Modified to 1 hour (60 minutes)
        updatedAt: DateTime.now(),
        colorCode: 'blue',
      ),
      ClassSlot(
        id: '2',
        subject: 'Maths01',
        teacherId: 'teacher2',
        teacherName: 'Bhuvan M',
        roomNumber: 'Lab 2',
        dayOfWeek: 0, // Monday
        startTime: '11:00',
        endTime: '12:00', // Modified to 1 hour
        durationMinutes: 60, // Modified to 1 hour (60 minutes)
        updatedAt: DateTime.now(),
        colorCode: 'red',
      ),
      ClassSlot(
        id: '3',
        subject: 'computer Networks',
        teacherId: 'teacher3',
        teacherName: 'Prof. Williams',
        roomNumber: 'Room 202',
        dayOfWeek: 0, // Monday
        startTime: '14:00',
        endTime: '15:00', // Modified to 1 hour
        durationMinutes: 60, // Modified to 1 hour (60 minutes)
        updatedAt: DateTime.now(),
        colorCode: 'blue',
      ),
      ClassSlot(
        id: '4',
        subject: 'Data Science',
        teacherId: 'teacher4',
        teacherName: 'Dr. Brown',
        roomNumber: 'Lab 3',
        dayOfWeek: 0, // Monday
        startTime: '16:00',
        endTime: '17:00', // Modified to 1 hour
        durationMinutes: 60, // Modified to 1 hour (60 minutes)
        updatedAt: DateTime.now(),
        colorCode: 'green',
      ),
      
      // Tuesday
      ClassSlot(
        id: '5',
        subject: 'Database Management',
        teacherId: 'teacher5',
        teacherName: 'Prof. Davis',
        roomNumber: 'Room 205',
        dayOfWeek: 1, // Tuesday
        startTime: '09:00',
        endTime: '10:00', // Modified to 1 hour
        durationMinutes: 60, // Modified to 1 hour (60 minutes)
        updatedAt: DateTime.now(),
        colorCode: 'purple',
      ),
      ClassSlot(
        id: '6',
        subject: 'Web Development',
        teacherId: 'teacher6',
        teacherName: 'Dr. Wilson',
        roomNumber: 'Lab 1',
        dayOfWeek: 1, // Tuesday
        startTime: '11:00',
        endTime: '12:00', // Modified to 1 hour
        durationMinutes: 60, // Modified to 1 hour (60 minutes)
        updatedAt: DateTime.now(),
        colorCode: 'orange',
      ),
      
      // Wednesday
      ClassSlot(
        id: '7',
        subject: 'Mathematics',
        teacherId: 'teacher1',
        teacherName: 'Prof. Smith',
        roomNumber: 'Room 101',
        dayOfWeek: 2, // Wednesday
        startTime: '09:00',
        endTime: '10:00', // Modified to 1 hour
        durationMinutes: 60, // Modified to 1 hour (60 minutes)
        updatedAt: DateTime.now(),
        colorCode: 'blue',
      ),
      ClassSlot(
        id: '8',
        subject: 'Physics',
        teacherId: 'teacher2',
        teacherName: 'Dr. Johnson',
        roomNumber: 'Lab 2',
        dayOfWeek: 2, // Wednesday
        startTime: '11:00',
        endTime: '12:00', // Modified to 1 hour
        durationMinutes: 60, // Modified to 1 hour (60 minutes)
        updatedAt: DateTime.now(),
        colorCode: 'red',
      ),
      
      // Thursday
      ClassSlot(
        id: '9',
        subject: 'Computer Science',
        teacherId: 'teacher3',
        teacherName: 'Prof. Williams',
        roomNumber: 'Room 202',
        dayOfWeek: 3, // Thursday
        startTime: '09:00',
        endTime: '10:00', // Modified to 1 hour
        durationMinutes: 60, // Modified to 1 hour (60 minutes)
        updatedAt: DateTime.now(),
        colorCode: 'blue',
      ),
      ClassSlot(
        id: '10',
        subject: 'Data Science',
        teacherId: 'teacher4',
        teacherName: 'Dr. Brown',
        roomNumber: 'Lab 3',
        dayOfWeek: 3, // Thursday
        startTime: '11:00',
        endTime: '12:00', // Modified to 1 hour
        durationMinutes: 60, // Modified to 1 hour (60 minutes)
        updatedAt: DateTime.now(),
        colorCode: 'green',
      ),
      
      // Friday
      ClassSlot(
        id: '11',
        subject: 'Database Management',
        teacherId: 'teacher5',
        teacherName: 'Prof. Davis',
        roomNumber: 'Room 205',
        dayOfWeek: 4, // Friday
        startTime: '09:00',
        endTime: '10:00', // Modified to 1 hour
        durationMinutes: 60, // Modified to 1 hour (60 minutes)
        updatedAt: DateTime.now(),
        colorCode: 'purple',
      ),
      ClassSlot(
        id: '12',
        subject: 'Web Development',
        teacherId: 'teacher6',
        teacherName: 'Dr. Wilson',
        roomNumber: 'Lab 1',
        dayOfWeek: 4, // Friday
        startTime: '11:00',
        endTime: '12:00', // Modified to 1 hour
        durationMinutes: 60, // Modified to 1 hour (60 minutes)
        updatedAt: DateTime.now(),
        colorCode: 'orange',
      ),
      
      // Saturday
      ClassSlot(
        id: '13',
        subject: 'Practical Lab',
        teacherId: 'teacher7',
        teacherName: 'Prof. Taylor',
        roomNumber: 'Lab 4',
        dayOfWeek: 5, // Saturday
        startTime: '09:00',
        endTime: '10:00', // Modified to 1 hour
        durationMinutes: 60, // Modified to 1 hour (60 minutes)
        updatedAt: DateTime.now(),
        colorCode: 'blue',
      ),
    ];
    
    return Timetable(
      id: 'timetable_$department\_$section\_$semester',
      department: department,
      section: section,
      semester: semester,
      validFrom: DateTime.now(),
      validUntil: DateTime.now().add(const Duration(days: 180)),
      slots: slots,
      lastUpdated: DateTime.now(),
    );
  }
  
  // Generate sample class actions for testing
  List<ClassAction> _generateSampleActions() {
    return [
      ClassAction(
        id: '1',
        actionType: ActionType.cancel,
        teacherId: 'teacher1',
        teacherName: 'Prof. Smith',
        originSlotId: '7', // Wednesday Math class
        timestamp: DateTime.now().subtract(const Duration(days: 1)),
        reason: 'Faculty meeting',
        subject: 'Mathematics',
        expiresAt: DateTime.now().add(const Duration(days: 6)),
        isApproved: true,
        approvedBy: 'admin1',
        approvedAt: DateTime.now(),
      ),
      ClassAction(
        id: '2',
        actionType: ActionType.extraClass,
        teacherId: 'teacher2',
        teacherName: 'Dr. Johnson',
        originSlotId: '2', // Monday Physics class
        targetSlotId: 'extra1',
        timestamp: DateTime.now().subtract(const Duration(days: 2)),
        reason: 'Exam preparation',
        subject: 'Physics',
        expiresAt: DateTime.now().add(const Duration(days: 5)),
      ),
    ];
  }
}