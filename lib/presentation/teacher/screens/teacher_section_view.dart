import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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
      floatingActionButton: FloatingActionButton(
        onPressed: () => _handleAddExtraClass(teacher),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add),
      ),
    );
  }

  void _handleClassTap(String time, ClassSlotModel classSlot, Teacher teacher) {
    final isTeacherClass = teacher.teachingAssignments.any((assignment) =>
        assignment.subject == classSlot.course &&
        assignment.sections.contains(widget.section) &&
        assignment.semester == widget.semester);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey.shade900,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
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
              if (isTeacherClass) ...[
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
                _buildActionButton(
                  icon: Icons.add_circle,
                  label: 'Add Extra Class',
                  color: Colors.green,
                  onTap: () {
                    Navigator.pop(context);
                    _showActionDialog(classSlot, teacher, ActionType.extraClass, time);
                  },
                ),
              ] else
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
          ),
        );
      },
    );
  }

  void _showActionDialog(ClassSlotModel classSlotModel, Teacher teacher,
      ActionType actionType, String time) {
    final parts = time.split('-');
    final startTime = parts[0].trim();
    final endTime = parts.length > 1 ? parts[1].trim() : '';
    final duration = _calculateDuration(startTime, endTime);

    final classSlotEntity = classSlotModel.toEntity(
      id: '${widget.section}_${widget.semester}_$time',
      subject: classSlotModel.course,
      dayOfWeek: DateTime.now().weekday - 1,
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

      final startTotal = startHour * 60 + startMinute;
      final endTotal = endHour * 60 + endMinute;

      return endTotal - startTotal;
    } catch (_) {
      return 60;
    }
  }

  void _handleAddExtraClass(Teacher teacher) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Feature coming soon: Add extra class')),
    );
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
