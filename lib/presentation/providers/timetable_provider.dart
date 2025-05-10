import 'package:flutter/material.dart';
import '../../../data/models/timetable_model.dart';
import '../../../data/datasources/remote/firebase_schedule_ds.dart';
import '../../../domain/entities/teacher.dart';

class TimetableProvider extends ChangeNotifier {
  final FirebaseScheduleDataSource _remoteSource = FirebaseScheduleDataSourceImpl();

  // Used for student view (single section)
  Map<String, Map<String, ClassSlotModel>>? _sectionSchedule;
  Map<String, Map<String, ClassSlotModel>>? get sectionSchedule => _sectionSchedule;

  // Used for teacher view (multiple sections)
  final Map<String, Map<String, Map<String, ClassSlotModel>>> _sectionSchedules = {};

  // New: Teacher's personal timetable (only their classes)
  Map<String, List<TeacherClassInfo>> _teacherPersonalSchedule = {};
  Map<String, List<TeacherClassInfo>> get teacherPersonalSchedule => _teacherPersonalSchedule;

  DateTime _selectedDate = DateTime.now();
  DateTime get selectedDate => _selectedDate;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  /// Initializes timetable data
  /// Set [isTeacher] = true if calling for a teacher to avoid overwriting `_sectionSchedule`
  Future<void> initialize({
    required String department,
    required String section,
    required int semester,
    bool isTeacher = false,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      debugPrint('📥 Fetching timetable for:');
      debugPrint('   Department: $department');
      debugPrint('   Section: $section');
      debugPrint('   Semester: $semester');

      final timetable = await _remoteSource.getTimetable(
        department: department,
        section: section,
        semester: semester,
      );

      final sectionKey = section.trim().toLowerCase(); // Normalize section key

      if (isTeacher) {
        _sectionSchedules[sectionKey] = timetable.schedule;
      } else {
        _sectionSchedule = timetable.schedule;
      }

      debugPrint('📦 Timetable loaded for $sectionKey: ${timetable.schedule.length} days');

      Future.microtask(() {
        _isLoading = false;
        notifyListeners();
      });
    } catch (e) {
      Future.microtask(() {
        _isLoading = false;
        _error = 'Failed to load timetable: ${e.toString()}';
        notifyListeners();
      });
    }
  }

  /// Initialize teacher's personal timetable by fetching all timetables and filtering by teacher name
  Future<void> initializeTeacherPersonalTimetable({
    required Teacher teacher,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      debugPrint('📥 Fetching personal timetable for teacher: ${teacher.name}');

      // Fetch all timetables for the teacher's department
      final allTimetables = await _remoteSource.getAllTimetablesForTeacher(
        department: teacher.department,
      );

      debugPrint('📦 Processing ${allTimetables.length} timetables');

      // Clear previous schedule
      _teacherPersonalSchedule.clear();

      // Process each timetable
      for (final timetable in allTimetables) {
        // Check each day
        timetable.schedule.forEach((day, timeSlots) {
          // Check each time slot
          timeSlots.forEach((time, classSlot) {
            // If the teacher name matches, add to personal schedule
            if (classSlot.teacher.toLowerCase() == teacher.name.toLowerCase()) {
              // Create teacher class info
              final classInfo = TeacherClassInfo(
                subject: classSlot.course,
                section: timetable.section,
                time: time,
                semester: timetable.semester,
              );

              // Add to schedule
              if (_teacherPersonalSchedule.containsKey(day)) {
                _teacherPersonalSchedule[day]!.add(classInfo);
              } else {
                _teacherPersonalSchedule[day] = [classInfo];
              }
            }
          });
        });
      }

      // Sort classes by time for each day
      _teacherPersonalSchedule.forEach((day, classes) {
        classes.sort((a, b) => _compareTimeStrings(a.time, b.time));
      });

      debugPrint('📦 Teacher personal schedule loaded');

      Future.microtask(() {
        _isLoading = false;
        notifyListeners();
      });
    } catch (e) {
      Future.microtask(() {
        _isLoading = false;
        _error = 'Failed to load teacher personal timetable: ${e.toString()}';
        notifyListeners();
      });
    }
  }

  int _compareTimeStrings(String time1, String time2) {
    // Extract start time from format "HH:MM - HH:MM"
    final start1 = time1.split('-')[0].trim();
    final start2 = time2.split('-')[0].trim();
    
    // Convert to minutes
    final minutes1 = _timeToMinutes(start1);
    final minutes2 = _timeToMinutes(start2);
    
    return minutes1.compareTo(minutes2);
  }

  int _timeToMinutes(String time) {
    final parts = time.split(':');
    if (parts.length != 2) return 0;
    
    final hour = int.tryParse(parts[0]) ?? 0;
    final minute = int.tryParse(parts[1]) ?? 0;
    
    // Handle 12-hour format (assuming times after 7 are PM)
    final hour24 = (hour < 7) ? hour + 12 : hour;
    
    return hour24 * 60 + minute;
  }

  void setSelectedDate(DateTime date) {
    _selectedDate = date;
    notifyListeners();
  }

  /// Returns slots for the selected day (used in student timetable view)
  Map<String, ClassSlotModel> getSlotsForSelectedDay() {
    if (_sectionSchedule == null) return {};

    final dayName = _weekdayToFirestoreKey(_selectedDate.weekday);
    final result = <String, ClassSlotModel>{};

    final dayMap = _sectionSchedule![dayName];
    if (dayMap != null) {
      result.addAll(dayMap);

      // Debug
      debugPrint('🗓️ Slots for $dayName:');
      dayMap.forEach((time, slot) {
        debugPrint('⏰ $time → ${slot.course} (${slot.teacher})');
      });
    }

    return result;
  }

  /// Returns schedule for a given section (used in teacher timetable view)
  Map<String, Map<String, ClassSlotModel>>? getSectionSchedule(String sectionKey) {
    final normalizedKey = sectionKey.trim().toLowerCase(); // Normalize
    for (final key in _sectionSchedules.keys) {
      if (key.trim().toLowerCase() == normalizedKey) {
        return _sectionSchedules[key];
      }
    }
    debugPrint('⚠️ No schedule found for $normalizedKey');
    return null;
  }

  String _weekdayToFirestoreKey(int weekday) {
    const weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
    return weekdays[(weekday - 1).clamp(0, 5)];
  }
}

// Class to hold teacher's class information
class TeacherClassInfo {
  final String subject;
  final String section;
  final String time;
  final int semester;

  TeacherClassInfo({
    required this.subject,
    required this.section,
    required this.time,
    required this.semester,
  });
}