import 'package:flutter/material.dart';
import '../../../data/models/timetable_model.dart';
import '../../../data/datasources/remote/firebase_schedule_ds.dart';

class TimetableProvider extends ChangeNotifier {
  final FirebaseScheduleDataSource _remoteSource = FirebaseScheduleDataSourceImpl();

  // Used for student view (single section)
  Map<String, Map<String, ClassSlotModel>>? _sectionSchedule;
  Map<String, Map<String, ClassSlotModel>>? get sectionSchedule => _sectionSchedule;

  // Used for teacher view (multiple sections)
  final Map<String, Map<String, Map<String, ClassSlotModel>>> _sectionSchedules = {};

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
