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

  ClassSlot toEntity({
    required String id,
    required String subject,
    required int dayOfWeek,
    required String startTime,
    required String endTime,
    required int durationMinutes,
    required DateTime updatedAt,
  }) {
    return ClassSlot(
      id: id,
      subject: subject,
      teacherId: '', // Update if needed
      teacherName: teacher,
      roomNumber: '', // Add if your model supports it
      dayOfWeek: dayOfWeek,
      startTime: startTime,
      endTime: endTime,
      durationMinutes: durationMinutes,
      updatedAt: updatedAt,
    );
  }
}

class TimetableModel {
  final String department;
  final String section;
  final int semester;
  final Map<String, Map<String, ClassSlotModel>> schedule;

  const TimetableModel({
    required this.department,
    required this.section,
    required this.semester,
    required this.schedule,
  });

  /// Useful for teacher screens (organized by section prefix)
  Map<String, Map<String, Map<String, ClassSlotModel>>> get sections {
    return {'Section_$section': schedule};
  }

  factory TimetableModel.fromJson(Map<String, dynamic> json) {
    final schedule = <String, Map<String, ClassSlotModel>>{};
    const days = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday'];

    for (final day in days) {
      final data = json[day];
      if (data is Map<String, dynamic>) {
        final parsed = data.map((time, classData) {
          return MapEntry(
            time,
            classData is Map<String, dynamic>
                ? ClassSlotModel.fromJson(classData)
                : const ClassSlotModel(course: 'Free', teacher: ''),
          );
        });
        schedule[_capitalize(day)] = parsed;
      }
    }

    return TimetableModel(
      department: json['department'] ?? '',
      section: json['section'] ?? '',
      semester: json['semester'] ?? 0,
      schedule: schedule,
    );
  }

  Map<String, dynamic> toJson() {
    final scheduleMap = schedule.map((day, timeMap) {
      return MapEntry(
        day.toLowerCase(),
        timeMap.map((time, slot) => MapEntry(time, slot.toJson())),
      );
    });

    return {
      'department': department,
      'section': section,
      'semester': semester,
      ...scheduleMap,
    };
  }

  Timetable toEntity({required DateTime lastUpdated}) {
    final slots = <ClassSlot>[];

    schedule.forEach((day, timeMap) {
      final dayIndex = _dayToIndex(day);

      timeMap.forEach((timeSlot, classSlot) {
        final parts = timeSlot.split('-');
        final startTime = parts[0].trim();
        final endTime = parts.length > 1 ? parts[1].trim() : '';
        final duration = _calculateDuration(startTime, endTime);

        slots.add(classSlot.toEntity(
          id: '${section}_${day}_$timeSlot',
          subject: classSlot.course,
          dayOfWeek: dayIndex,
          startTime: startTime,
          endTime: endTime,
          durationMinutes: duration,
          updatedAt: lastUpdated,
        ));
      });
    });

    return Timetable(
      id: 'timetable_${section}_$semester',
      department: department,
      section: section,
      semester: semester,
      validFrom: DateTime.now(),
      validUntil: DateTime.now().add(const Duration(days: 180)),
      slots: slots,
      lastUpdated: lastUpdated,
    );
  }

  int _dayToIndex(String day) {
    const map = {
      'Monday': 0,
      'Tuesday': 1,
      'Wednesday': 2,
      'Thursday': 3,
      'Friday': 4,
      'Saturday': 5,
    };
    return map[day] ?? 0;
  }

  int _calculateDuration(String start, String end) {
    try {
      final s = _parseTime(start);
      final e = _parseTime(end);
      return e.difference(s).inMinutes;
    } catch (_) {
      return 60;
    }
  }

  DateTime _parseTime(String time) {
    final parts = time.split(':');
    final hour = int.tryParse(parts[0]) ?? 0;
    final minute = int.tryParse(parts[1]) ?? 0;
    final hour24 = (hour < 7) ? hour + 12 : hour;
    return DateTime(0, 1, 1, hour24, minute);
  }

static String _capitalize(String str) {
  if (str.isEmpty) return str;
  return str[0].toUpperCase() + str.substring(1);
}

}
