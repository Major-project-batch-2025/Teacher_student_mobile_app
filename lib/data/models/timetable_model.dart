// lib/data/models/timetable_model.dart

import '../../domain/entities/timetable.dart';

class ClassSlotModel {
  final String course;
  final String teacher;

  const ClassSlotModel({
    required this.course,
    required this.teacher,
  });

  factory ClassSlotModel.fromJson(Map<String, dynamic> json) {
    return ClassSlotModel(
      course: json['course'] ?? 'Free',
      teacher: json['teacher'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'course': course,
      'teacher': teacher,
    };
  }
}

class TimetableModel {
  final int numberOfSections;
  final int semester;
  final Map<String, Map<String, Map<String, ClassSlotModel>>> sections;

  const TimetableModel({
    required this.numberOfSections,
    required this.semester,
    required this.sections,
  });

  factory TimetableModel.fromJson(Map<String, dynamic> json) {
    // Safely extract sections from JSON
    final rawSections = json['sections'] as Map<String, dynamic>? ?? {};

    final parsedSections = rawSections.map((sectionKey, sectionValue) {
      // Handle missing or malformed schedule
      final schedule = sectionValue['schedule'] as Map<String, dynamic>? ?? {};
      
      final scheduleMap = schedule.map(
        (timeSlotKey, timeSlotValue) {
          // Ensure timeSlotValue is Map<String, dynamic>
          final timeSlotMap = timeSlotValue is Map<String, dynamic> 
              ? timeSlotValue 
              : <String, dynamic>{};
              
          return MapEntry(
            timeSlotKey,
            timeSlotMap.map(
              (dayKey, dayValue) {
                return MapEntry(
                  dayKey, 
                  dayValue is Map<String, dynamic> 
                      ? ClassSlotModel.fromJson(dayValue)
                      : ClassSlotModel(course: 'Free', teacher: '')
                );
              },
            ),
          );
        },
      );

      return MapEntry(sectionKey, scheduleMap);
    });

    return TimetableModel(
      numberOfSections: json['numberOfSections'] ?? 1,
      semester: json['semester'] ?? 0,
      sections: parsedSections,
    );
  }

  Map<String, dynamic> toJson() {
    final sectionsMap = sections.map((sectionKey, schedule) {
      final scheduleMap = schedule.map((timeSlot, dayMap) {
        return MapEntry(
            timeSlot, dayMap.map((day, slot) => MapEntry(day, slot.toJson())));
      });

      return MapEntry(sectionKey, {'schedule': scheduleMap});
    });

    return {
      'numberOfSections': numberOfSections,
      'semester': semester,
      'sections': sectionsMap,
    };
  }

  // Converts TimetableModel to domain-level Timetable entity
  Timetable toEntity({
    required String sectionKey,
    required String department,
    required DateTime lastUpdated,
  }) {
    final slots = <ClassSlot>[];

    final schedule = sections[sectionKey];
    if (schedule != null) {
      schedule.forEach((timeSlot, dayMap) {
        final timeParts = timeSlot.split('-');
        final startTime = timeParts.length > 0 ? timeParts[0].trim() : '00:00';
        final endTime = timeParts.length > 1 ? timeParts[1].trim() : '00:00';

        dayMap.forEach((dayName, slotModel) {
          final slot = ClassSlot(
            id: '${sectionKey}_${dayName}_$timeSlot',
            subject: slotModel.course,
            teacherId: '', // optional: update if you store IDs later
            teacherName: slotModel.teacher,
            roomNumber: '', // not provided in data
            dayOfWeek: _dayToIndex(dayName),
            startTime: startTime,
            endTime: endTime,
            durationMinutes: 60, // or calculate if needed
            updatedAt: lastUpdated,
          );
          slots.add(slot);
        });
      });
    }

    return Timetable(
      id: 'timetable_${sectionKey}_${semester}',
      department: department,
      section: sectionKey.replaceAll('Section_', ''),
      semester: semester,
      validFrom: DateTime.now(),
      validUntil: DateTime.now().add(const Duration(days: 180)),
      slots: slots,
      lastUpdated: lastUpdated,
    );
  }

  // Utility to convert weekday string to 0-based index (Monday = 0)
  int _dayToIndex(String day) {
    const days = {
      'Monday': 0,
      'Tuesday': 1,
      'Wednesday': 2,
      'Thursday': 3,
      'Friday': 4,
      'Saturday': 5,
    };
    return days[day] ?? 0;
  }
}