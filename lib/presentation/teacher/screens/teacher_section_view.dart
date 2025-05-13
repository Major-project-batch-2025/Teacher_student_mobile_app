// lib/presentation/teacher/screens/teacher_section_view.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/constants.dart';
import '../../../domain/entities/class_action.dart';
import '../../../domain/entities/teacher.dart';
import '../../../data/models/timetable_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../../providers/timetable_provider.dart';
import '../../shared_widgets/action_dialog.dart';
import '../../shared_widgets/notification_bell.dart';
import '../../shared_widgets/timetable_grid.dart';
import 'class_action_screen.dart';

class TeacherSectionViewScreen extends StatefulWidget {
  final String section;
  final int semester;
  final String department;

  const TeacherSectionViewScreen({
    super.key,
    required this.section,
    required this.semester,
    required this.department,
  });

  @override
  State<TeacherSectionViewScreen> createState() => _TeacherSectionViewScreenState();
}

class _TeacherSectionViewScreenState extends State<TeacherSectionViewScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeTimetable();
    });
  }

  Future<void> _initializeTimetable() async {
    final timetableProvider = Provider.of<TimetableProvider>(context, listen: false);

    await timetableProvider.initialize(
      department: widget.department,
      section: widget.section,
      semester: widget.semester,
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    if (!authProvider.isLoggedIn || !authProvider.isTeacher) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('You need to be logged in as a teacher'),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      );
    }

    final teacher = authProvider.user as Teacher;

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        backgroundColor: AppColors.darkBackground,
        elevation: 0,
        title: Text(
          widget.section,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          const NotificationBell(isTeacher: true),
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ClassActionScreen(section: widget.section),
                ),
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _initializeTimetable,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${widget.department} - ${widget.section}',
                style: const TextStyle(
                  fontSize: 20.0,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(
                'Semester ${widget.semester}',
                style: const TextStyle(
                  fontSize: 16.0,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 24.0),
              TimetableGrid(
                onClassTap: (time, classSlot) =>
                    _handleClassTap(time, classSlot, teacher),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleClassTap(String time, ClassSlotModel classSlot, Teacher teacher) {
    // Check if the slot is cancelled
    final isCancelled = classSlot.course == 'Cancelled';
    
    // Check if this is the teacher's class
    final isTeacherClass = teacher.teachingAssignments.any((assignment) =>
        assignment.subject == classSlot.course &&
        assignment.sections.contains(widget.section) &&
        assignment.semester == widget.semester);

    // Check if the slot is free
    final isFreeSlot = classSlot.course == 'Free' || classSlot.course.isEmpty;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey.shade900,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!isFreeSlot && !isCancelled)
                ListTile(
                  title: Text(
                    classSlot.course,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18.0,
                    ),
                  ),
                  subtitle: Text(
                    'Instructor: ${classSlot.teacher}',
                    style: const TextStyle(color: Colors.grey),
                  ),
                ),
              const Divider(color: Colors.grey),
              if (isCancelled) ...[
                const ListTile(
                  title: Text(
                    'This class has been cancelled',
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 16.0,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ] else if (isTeacherClass && !isFreeSlot) ...[
                _buildActionButton(
                  icon: Icons.cancel,
                  label: 'Cancel Class',
                  color: Colors.red,
                  onTap: () {
                    Navigator.pop(context);
                    _showActionDialog(classSlot, teacher, ActionType.cancel, time);
                  },
                ),
                // Removed reschedule action button
              ] else if (isFreeSlot) ...[
                _buildActionButton(
                  icon: Icons.add_circle,
                  label: 'Add Extra Class',
                  color: Colors.green,
                  onTap: () async {
                    Navigator.pop(context);
                    // Check if the teacher can add an extra class at this time
                    final canAddClass = await _canAddExtraClass(time, teacher);
                    if (canAddClass) {
                      _showActionDialog(classSlot, teacher, ActionType.extraClass, time);
                    }
                  },
                ),
              ] else if (!isTeacherClass) ...[
                const ListTile(
                  title: Text(
                    "You can only manage your own classes",
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 16.0,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  // Check if teacher can add extra class
  Future<bool> _canAddExtraClass(String time, Teacher teacher) async {
    try {
      // Parse the time slot to get start time
      final parts = time.split('-');
      final startTime = parts[0].trim();
      
      // Parse hours and minutes
      final timeParts = startTime.split(':');
      final hour = int.parse(timeParts[0]);
      final minute = int.parse(timeParts[1]);
      
      // Get current time
      final now = DateTime.now();
      final timetableProvider = Provider.of<TimetableProvider>(context, listen: false);
      final selectedDate = timetableProvider.selectedDate;
      
      // Create DateTime for the class start time on the selected day
      DateTime classDateTime;
      
      // Handle 12-hour format (assuming times after 7 are PM)
      final hour24 = (hour < 7) ? hour + 12 : hour;
      
      // Create the class date-time for comparison
      classDateTime = DateTime(
        selectedDate.year,
        selectedDate.month,
        selectedDate.day,
        hour24,
        minute,
      );
      
      // If the selected date is in the past or today but the time has passed
      if (classDateTime.isBefore(now)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cannot add extra class for a past time slot'),
            backgroundColor: Colors.red,
          ),
        );
        return false;
      }
      
      // Check if class is at least 2 hours in the future
      final timeDifference = classDateTime.difference(now);
      print('Current time: $now');
      print('Class time: $classDateTime');
      print('Time difference in hours: ${timeDifference.inHours}');
      
      if (timeDifference.inHours < 2) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Extra classes must be scheduled at least 2 hours in advance.\n'
              'Current time: ${now.hour}:${now.minute.toString().padLeft(2, '0')}\n'
              'Class time: ${classDateTime.hour}:${classDateTime.minute.toString().padLeft(2, '0')}'
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
        return false;
      }
      
      // Check for conflicts with other sections at this time
      final hasConflict = await _checkTeacherConflict(time, teacher);
      if (hasConflict) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You already have a class in another section at this time'),
            backgroundColor: Colors.red,
          ),
        );
        return false;
      }
      
      return true;
    } catch (e) {
      print('Error checking if can add extra class: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    }
  }

  // Check if teacher has conflict at this time slot
  Future<bool> _checkTeacherConflict(String timeSlot, Teacher teacher) async {
    try {
      final firestore = FirebaseFirestore.instance;
      final timetableProvider = Provider.of<TimetableProvider>(context, listen: false);
      final selectedDate = timetableProvider.selectedDate;
      final dayName = _dayIndexToName(selectedDate.weekday - 1);
      
      // Format time slot to match Firebase format (no spaces)
      final formattedTimeSlot = timeSlot.replaceAll(' ', '');
      
      // Check all sections where this teacher has assignments
      for (final assignment in teacher.teachingAssignments) {
        for (final section in assignment.sections) {
          // Skip the current section
          if (section == widget.section) continue;
          
          // Query the timetable for this section
          final querySnapshot = await firestore
              .collection('Modified_TimeTable')
              .where('department', isEqualTo: widget.department)
              .where('section', isEqualTo: section)
              .where('semester', isEqualTo: assignment.semester)
              .limit(1)
              .get();
          
          if (querySnapshot.docs.isNotEmpty) {
            final docRef = querySnapshot.docs.first.reference;
            final dayCollection = await docRef.collection(dayName).get();
            
            if (dayCollection.docs.isNotEmpty) {
              final dayDoc = dayCollection.docs.first;
              final dayData = dayDoc.data();
              
              // Check if teacher has a class at this time slot
              final slotData = dayData[formattedTimeSlot];
              if (slotData != null && slotData is Map<String, dynamic>) {
                final slotTeacher = slotData['teacher'] as String?;
                if (slotTeacher == teacher.name) {
                  return true; // Conflict found
                }
              }
            }
          }
        }
      }
      
      return false; // No conflict
    } catch (e) {
      print('Error checking teacher conflict: $e');
      return true; // Assume conflict on error to be safe
    }
  }

  String _dayIndexToName(int index) {
    const days = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday'];
    return days[index % 6];
  }

  void _showActionDialog(ClassSlotModel classSlotModel, Teacher teacher,
      ActionType actionType, String time) {
    final provider = Provider.of<TimetableProvider>(context, listen: false);
    final selectedDate = provider.selectedDate;
    
    final parts = time.split('-');
    final startTime = parts[0].trim();
    final endTime = parts.length > 1 ? parts[1].trim() : '';
    final duration = _calculateDuration(startTime, endTime);

    final classSlotEntity = classSlotModel.toEntity(
      id: '${widget.section}_${widget.semester}_${selectedDate.weekday - 1}_$time',
      subject: classSlotModel.course,
      dayOfWeek: selectedDate.weekday - 1,
      startTime: startTime,
      endTime: endTime,
      durationMinutes: duration,
      updatedAt: DateTime.now(),
    );

    showDialog(
      context: context,
      builder: (context) => ActionDialog(
        classSlot: classSlotEntity,
        actionType: actionType,
        teacherId: teacher.id,
        teacherName: teacher.name,
        section: widget.section,
        semester: widget.semester,
        department: widget.department,
      ),
    );
  }

  int _calculateDuration(String start, String end) {
    try {
      final startParts = start.split(':');
      final endParts = end.split(':');

      final startHour = int.tryParse(startParts[0]) ?? 0;
      final startMinute = int.tryParse(startParts[1]) ?? 0;
      final endHour = int.tryParse(endParts[0]) ?? 0;
      final endMinute = int.tryParse(endParts[1]) ?? 0;

      // Handle 12-hour format
      final start24Hour = (startHour < 7) ? startHour + 12 : startHour;
      final end24Hour = (endHour < 7) ? endHour + 12 : endHour;

      final startTotal = start24Hour * 60 + startMinute;
      final endTotal = end24Hour * 60 + endMinute;

      return endTotal - startTotal;
    } catch (_) {
      return 60;
    }
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(
        label,
        style: const TextStyle(color: Colors.white),
      ),
      onTap: onTap,
    );
  }
}