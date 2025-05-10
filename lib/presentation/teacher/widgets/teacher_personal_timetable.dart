import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants.dart';
import '../../../domain/entities/teacher.dart';
import '../../../data/models/timetable_model.dart';
import '../../providers/timetable_provider.dart';

class ClassInfo {
  final String subject;
  final String section;
  final String time;
  final ClassSlotModel slotModel;

  ClassInfo({
    required this.subject,
    required this.section,
    required this.time,
    required this.slotModel,
  });
}

class TeacherPersonalTimetable extends StatefulWidget {
  final Teacher teacher;

  const TeacherPersonalTimetable({super.key, required this.teacher});

  @override
  State<TeacherPersonalTimetable> createState() =>
      _TeacherPersonalTimetableState();
}

class _TeacherPersonalTimetableState extends State<TeacherPersonalTimetable> {
  int _selectedDayIndex = 0;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    int dayIndex = now.weekday - 1;
    if (dayIndex > 5) dayIndex = 0;
    _selectedDayIndex = dayIndex;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildDaySelector(),
        const SizedBox(height: 16),
        _buildClassList(),
      ],
    );
  }

  Widget _buildDaySelector() {
    return Container(
      height: 60.0,
      decoration: BoxDecoration(
        color: AppColors.darkBackground,
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: AppStrings.weekdays.length,
        itemBuilder: (context, index) {
          final isSelected = index == _selectedDayIndex;
          return GestureDetector(
            onTap: () {
              setState(() => _selectedDayIndex = index);
            },
            child: Container(
              width: 70.0,
              margin: const EdgeInsets.all(4.0),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Center(
                child: Text(
                  AppStrings.weekdays[index],
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.grey,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildClassList() {
    final provider = Provider.of<TimetableProvider>(context);
    final Map<String, List<String>> sectionSubjects = {};

    for (final assignment in widget.teacher.teachingAssignments) {
      if (assignment.semester != 7) continue;

      for (final section in assignment.sections) {
        sectionSubjects.putIfAbsent(section, () => []);
        sectionSubjects[section]!.add(assignment.subject);
      }
    }

    final dayName = _dayIndexToName(_selectedDayIndex);
    final classes = <ClassInfo>[];

    for (final entry in sectionSubjects.entries) {
      final section = entry.key;
      final subjects = entry.value;
      final sectionKey = section.trim(); // Normalized, if needed

      final schedule = provider.getSectionSchedule(sectionKey);
      if (schedule == null) {
        debugPrint('⚠️ No schedule found for $sectionKey');
        continue;
      }

      final dayMap = schedule[dayName];
      if (dayMap != null) {
        dayMap.forEach((time, slot) {
          debugPrint('🔍 Checking section $section at $time on $dayName');
          debugPrint('→ Slot: ${slot.course} (${slot.teacher})');
          debugPrint('→ Teacher teaches: $subjects');

          if (slot != null &&
              subjects
                  .map((s) => s.trim().toLowerCase())
                  .contains(slot.course.trim().toLowerCase())) {
            classes.add(ClassInfo(
              subject: slot.course,
              section: section,
              time: time,
              slotModel: slot,
            ));
          }
        });
      }
    }

    if (classes.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(32.0),
        child: Center(
          child: Text(
            'No classes scheduled for this day',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 16.0,
            ),
          ),
        ),
      );
    }

    classes.sort((a, b) {
      final aTime = _convertTimeToMinutes(a.time.split('-')[0].trim());
      final bTime = _convertTimeToMinutes(b.time.split('-')[0].trim());
      return aTime.compareTo(bTime);
    });

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: classes.length,
      itemBuilder: (_, index) => _buildClassCard(classes[index]),
    );
  }

  Widget _buildClassCard(ClassInfo classInfo) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6.0),
      decoration: BoxDecoration(
        color: AppColors.darkBackground,
        borderRadius: BorderRadius.circular(8.0),
        border: Border(
          left: BorderSide(color: AppColors.classBlue, width: 6.0),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.access_time, size: 16.0, color: Colors.grey),
                const SizedBox(width: 8.0),
                Text(classInfo.time, style: const TextStyle(color: Colors.grey)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4.0),
                  ),
                  child: Text(
                    classInfo.section,
                    style: const TextStyle(
                      color: AppColors.classBlue,
                      fontWeight: FontWeight.bold,
                      fontSize: 12.0,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10.0),
            Text(
              classInfo.subject,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6.0),
            Row(
              children: [
                const Icon(Icons.location_on, size: 16.0, color: Colors.grey),
                const SizedBox(width: 8.0),
                Text(
                  'Room ${_getDummyRoomNumber(classInfo)}',
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _dayIndexToName(int index) {
    const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
    return days[index % 6];
  }

  int _convertTimeToMinutes(String timeStr) {
    final parts = timeStr.split(':');
    if (parts.length != 2) return 0;
    final hour = int.tryParse(parts[0]) ?? 0;
    final minute = int.tryParse(parts[1]) ?? 0;
    return hour * 60 + minute;
  }

  String _getDummyRoomNumber(ClassInfo classInfo) {
    final sectionValue = classInfo.section.codeUnitAt(0) - 'A'.codeUnitAt(0);
    final hash = classInfo.subject.length + sectionValue;
    return '${100 + hash}';
  }
}
