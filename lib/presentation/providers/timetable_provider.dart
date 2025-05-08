// lib/presentation/providers/timetable_provider.dart

import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../../data/models/timetable_model.dart';
import '../../../data/datasources/remote/firebase_schedule_ds.dart';

class TimetableProvider extends ChangeNotifier {
  final FirebaseScheduleDataSource _remoteSource = FirebaseScheduleDataSourceImpl();

  final _uuid = const Uuid();

  // Section-specific nested timetable (e.g., Section_A)
  Map<String, Map<String, ClassSlotModel>>? _sectionSchedule;
  Map<String, Map<String, ClassSlotModel>>? get sectionSchedule => _sectionSchedule;

  // Store multiple section schedules
  final Map<String, Map<String, Map<String, ClassSlotModel>>> _sectionSchedules = {};

  DateTime _selectedDate = DateTime.now();
  DateTime get selectedDate => _selectedDate;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  // Initialize from Firestore
  Future<void> initialize({
    required String department,
    required String section,
    required int semester,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final timetable = await _remoteSource.getTimetable(
        department: department,
        section: section,
        semester: semester,
      );

      // Store the schedule for the selected section
      final sectionKey = 'Section_$section';
      if (timetable.sections.containsKey(sectionKey)) {
        _sectionSchedule = timetable.sections[sectionKey];
        // Also store in the map of all sections for teacher's view
        _sectionSchedules[sectionKey] = timetable.sections[sectionKey] ?? {};
      } else {
        throw Exception('No schedule found for $sectionKey');
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = 'Failed to load timetable: ${e.toString()}';
      notifyListeners();
    }
  }

  void setSelectedDate(DateTime date) {
    _selectedDate = date;
    notifyListeners();
  }

  // Return a map of all time slots with course info for the selected weekday
  Map<String, ClassSlotModel> getSlotsForSelectedDay() {
    if (_sectionSchedule == null) return {};

    final dayName = _weekdayToFirestoreKey(_selectedDate.weekday);
    final result = <String, ClassSlotModel>{};

    _sectionSchedule!.forEach((timeSlot, dayMap) {
      if (dayMap.containsKey(dayName)) {
        result[timeSlot] = dayMap[dayName]!;
      }
    });

    return result;
  }

  // Get schedule for a specific section
  Map<String, Map<String, ClassSlotModel>>? getSectionSchedule(String sectionKey) {
    return _sectionSchedules[sectionKey];
  }

  String _weekdayToFirestoreKey(int weekday) {
    switch (weekday) {
      case DateTime.monday:
        return 'Monday';
      case DateTime.tuesday:
        return 'Tuesday';
      case DateTime.wednesday:
        return 'Wednesday';
      case DateTime.thursday:
        return 'Thursday';
      case DateTime.friday:
        return 'Friday';
      case DateTime.saturday:
        return 'Saturday';
      default:
        return 'Monday';
    }
  }
}