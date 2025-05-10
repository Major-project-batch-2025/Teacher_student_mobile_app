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
                _buildActionButton(
                  icon: Icons.event_repeat,
                  label: 'Reschedule Class',
                  color: Colors.orange,
                  onTap: () {
                    Navigator.pop(context);
                    _showActionDialog(classSlot, teacher, ActionType.reschedule, time);
                  },
                ),
              ] else if (isFreeSlot) ...[
                _buildActionButton(
                  icon: Icons.add_circle,
                  label: 'Add Extra Class',
                  color: Colors.green,
                  onTap: () async {
                    Navigator.pop(context);
                    // Only check for teacher conflict, removed time restriction
                    final hasConflict = await _checkTeacherConflict(time, teacher);
                    if (!hasConflict) {
                      _showActionDialog(classSlot, teacher, ActionType.extraClass, time);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('You already have a class in another section at this time'),
                          backgroundColor: Colors.red,
                        ),
                      );
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

  // Check if teacher has conflict at this time slot
  Future<bool> _checkTeacherConflict(String timeSlot, Teacher teacher) async {
    try {
      final firestore = FirebaseFirestore.instance;
      final timetableProvider = Provider.of<TimetableProvider>(context, listen: false);
      final selectedDate = timetableProvider.selectedDate;
      final dayName = _dayIndexToName(selectedDate.weekday - 1).toLowerCase();
      
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
              final slotData = dayData[timeSlot];
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