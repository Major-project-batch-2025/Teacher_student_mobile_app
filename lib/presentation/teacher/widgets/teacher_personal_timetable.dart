import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants.dart';
import '../../../domain/entities/teacher.dart';
import '../../providers/timetable_provider.dart';

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

    // Initialize teacher's personal timetable
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializePersonalTimetable();
    });
  }

  Future<void> _initializePersonalTimetable() async {
    final provider = Provider.of<TimetableProvider>(context, listen: false);
    await provider.initializeTeacherPersonalTimetable(teacher: widget.teacher);
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
    return SizedBox(
      height: 80.0,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: AppStrings.weekdays.length,
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        itemBuilder: (context, index) {
          final isSelected = index == _selectedDayIndex;
          return GestureDetector(
            onTap: () {
              setState(() => _selectedDayIndex = index);
            },
            child: Container(
              width: 80.0,
              margin: const EdgeInsets.symmetric(
                horizontal: 6.0,
                vertical: 8.0,
              ),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : Colors.grey.shade900,
                borderRadius: BorderRadius.circular(12.0),
                border: Border.all(
                  color: isSelected ? AppColors.primary : Colors.grey.shade800,
                  width: 2.0,
                ),
                boxShadow:
                    isSelected
                        ? [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.3),
                            blurRadius: 8.0,
                            offset: const Offset(0, 4),
                          ),
                        ]
                        : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.calendar_today,
                    color: isSelected ? Colors.white : Colors.grey,
                    size: 24.0,
                  ),
                  const SizedBox(height: 8.0),
                  Text(
                    AppStrings.weekdays[index],
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.grey,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                      fontSize: 14.0,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildClassList() {
    final provider = Provider.of<TimetableProvider>(context);

    if (provider.isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (provider.error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Text(
            'Error: ${provider.error}',
            style: const TextStyle(color: Colors.red),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final dayName = _dayIndexToName(_selectedDayIndex);
    final classes = provider.teacherPersonalSchedule[dayName] ?? [];

    if (classes.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(32.0),
        child: Center(
          child: Text(
            'No classes scheduled for this day',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 16.0),
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: classes.length,
      itemBuilder: (_, index) => _buildClassCard(classes[index]),
    );
  }

  Widget _buildClassCard(TeacherClassInfo classInfo) {
    // Get a color for the subject
    Color borderColor = _getSubjectColor(classInfo.subject);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6.0),
      decoration: BoxDecoration(
        color: AppColors.darkBackground, // Different from black background
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: borderColor.withOpacity(0.3), width: 1.0),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12.0),
          border: Border(left: BorderSide(color: borderColor, width: 6.0)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Time and Section Badge Row
              Row(
                children: [
                  const Icon(Icons.access_time, size: 16.0, color: Colors.grey),
                  const SizedBox(width: 8.0),
                  Text(
                    classInfo.time,
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8.0,
                      vertical: 4.0,
                    ),
                    decoration: BoxDecoration(
                      color: borderColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4.0),
                    ),
                    child: Text(
                      classInfo.section,
                      style: const TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.w500,
                        fontSize: 12.0,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10.0),

              // Subject Name
              Text(
                classInfo.subject,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8.0),

              // Semester and Room Info
              Row(
                children: [
                  const Icon(
                    Icons.school_outlined,
                    size: 16.0,
                    color: Colors.grey,
                  ),
                  const SizedBox(width: 8.0),
                  Text(
                    'Semester ${classInfo.semester}',
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(width: 16.0),
                  const Icon(
                    Icons.location_on_outlined,
                    size: 16.0,
                    color: Colors.grey,
                  ),
                  const SizedBox(width: 8.0),
                  Text(
                    'Room ${_getRoomNumber(classInfo.subject, classInfo.section)}',
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Get random color for subjects
  final Map<String, Color> _courseColors = {};
  final List<Color> _availableColors = [
    Colors.green,
    Colors.red,
    Colors.purple,
    Colors.teal,
    Colors.orange,
    Colors.blue,
    Colors.pink,
    Colors.indigo,
    Colors.amber,
    Colors.cyan,
    Colors.lime,
    Colors.deepOrange,
    Colors.lightBlue,
    Colors.deepPurple,
    Colors.brown,
  ];

  Color _getSubjectColor(String subject) {
    // Check if color already assigned to this subject
    if (_courseColors.containsKey(subject)) {
      return _courseColors[subject]!;
    }

    // Generate a hash-based index for consistent color assignment per subject
    int hash = subject.hashCode;
    int colorIndex = hash.abs() % _availableColors.length;

    // Assign and store the color
    Color assignedColor = _availableColors[colorIndex];
    _courseColors[subject] = assignedColor;

    return assignedColor;
  }

  String _getRoomNumber(String subject, String section) {
    // Generate room number based on subject and section
    // This is a simple algorithm - you can replace with actual room data if available
    final subjectHash = subject.hashCode.abs() % 100;
    final sectionValue = section.codeUnitAt(0) - 'A'.codeUnitAt(0);
    return '${100 + subjectHash + sectionValue}';
  }

  String _dayIndexToName(int index) {
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
    ];
    return days[index % 6];
  }
}
