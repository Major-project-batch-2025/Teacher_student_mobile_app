// lib/presentation/teacher/widgets/teacher_personal_timetable.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants.dart';
// import '../../../core/utils/date_helpers.dart';
import '../../../domain/entities/teacher.dart';
import '../../../data/models/timetable_model.dart';
import '../../providers/timetable_provider.dart';

// Move ClassInfo outside the state class to make it globally accessible
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

  const TeacherPersonalTimetable({
    super.key,
    required this.teacher,
  });

  @override
  State<TeacherPersonalTimetable> createState() => _TeacherPersonalTimetableState();
}

class _TeacherPersonalTimetableState extends State<TeacherPersonalTimetable> {
  int _selectedDayIndex = 0;

  @override
  void initState() {
    super.initState();
    // Set the default selected day to today or Monday if weekend
    final now = DateTime.now();
    int dayIndex = now.weekday - 1; // 0 = Monday, 6 = Sunday
    
    // If it's Sunday, default to Monday
    if (dayIndex > 5) {
      dayIndex = 0;
    }
    
    setState(() {
      _selectedDayIndex = dayIndex;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildDaySelector(),
        const SizedBox(height: 16.0),
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
              setState(() {
                _selectedDayIndex = index;
              });
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
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
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
    final timetableProvider = Provider.of<TimetableProvider>(context);
    
    // Get the teacher's subjects for 7th semester
    final teacherSubjects = <String>[];
    for (final assignment in widget.teacher.teachingAssignments) {
      if (assignment.semester == 7) {
        teacherSubjects.add(assignment.subject);
      }
    }
    
    // Get classes for all sections on the selected day for this teacher's subjects
    final classes = _getTeacherClasses(
      timetableProvider,
      _selectedDayIndex,
      teacherSubjects,
    );
    
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
    
    // Sort classes by time
    classes.sort((a, b) {
      final timeA = _convertTimeToMinutes(a.time.split('-').first.trim());
      final timeB = _convertTimeToMinutes(b.time.split('-').first.trim());
      return timeA.compareTo(timeB);
    });
    
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: classes.length,
      itemBuilder: (context, index) {
        final classInfo = classes[index];
        return _buildClassCard(classInfo);
      },
    );
  }
  
  // Get teacher's classes across all sections for the selected day
  List<ClassInfo> _getTeacherClasses(
    TimetableProvider provider,
    int dayOfWeek,
    List<String> teacherSubjects,
  ) {
    final classes = <ClassInfo>[];
    final sections = ['A', 'B', 'C']; // 7th semester sections
    
    for (final section in sections) {
      // Get schedule for this section
      final sectionKey = 'Section_$section';
      final sectionSchedule = provider.getSectionSchedule(sectionKey);
      if (sectionSchedule == null) continue;
      
      // Convert day index to Firebase day name (0 = Monday)
      final dayName = _dayIndexToName(dayOfWeek);
      
      // Check all time slots for this day
      sectionSchedule.forEach((timeSlot, dayMap) {
        if (dayMap.containsKey(dayName)) {
          final classSlot = dayMap[dayName];
          
          // Check if this is a class taught by this teacher and the slot exists
          if (classSlot != null && teacherSubjects.contains(classSlot.course)) {
            classes.add(
              ClassInfo(
                subject: classSlot.course,
                section: section,
                time: timeSlot, // timeSlot is the key from forEach, so it's non-null
                slotModel: classSlot,
              ),
            );
          }
        }
      });
    }
    
    return classes;
  }
  
  // Convert day index to Firebase day name
  String _dayIndexToName(int dayIndex) {
    const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
    return days[dayIndex % days.length];
  }
  
  // Convert time string to minutes for sorting
  int _convertTimeToMinutes(String timeStr) {
    final parts = timeStr.split(':');
    if (parts.length != 2) return 0;
    
    final hour = int.tryParse(parts[0]) ?? 0;
    final minute = int.tryParse(parts[1]) ?? 0;
    return hour * 60 + minute;
  }
  
  // Build class card for personal timetable
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8.0,
                    vertical: 2.0,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4.0),
                  ),
                  child: Text(
                    'Section ${classInfo.section}',
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
  
  // Helper to get a room number (just for UI demonstration)
  String _getDummyRoomNumber(ClassInfo classInfo) {
    // In a real app, this would come from your database
    // For now, we'll generate consistent room numbers based on section and subject
    final sectionValue = classInfo.section.codeUnitAt(0) - 'A'.codeUnitAt(0);
    final hash = classInfo.subject.length + sectionValue;
    return '${100 + hash}';
  }
}