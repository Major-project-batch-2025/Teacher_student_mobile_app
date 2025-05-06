// lib/presentation/teacher/screens/teacher_section_view.dart
// Purpose: Show timetable for a specific section with teacher actions

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants.dart';
import '../../../domain/entities/class_action.dart';
import '../../../domain/entities/teacher.dart';
import '../../../domain/entities/timetable.dart';
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
    
    // Initialize timetable provider after build completes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeTimetable();
    });
  }
  
  // Initialize timetable for this section
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
    
    // Safety check to ensure user is logged in and is a teacher
    if (!authProvider.isLoggedIn || !authProvider.isTeacher) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('You need to be logged in as a teacher'),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
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
          // Notification bell
          const NotificationBell(isTeacher: true),
          
          // View class actions button
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ClassActionScreen(
                    section: widget.section,
                  ),
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
              // Section info
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
              
              // Timetable grid
              TimetableGrid(
                isEditable: true,
                onClassTap: (classSlot) => _handleClassTap(classSlot, teacher),
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
  
  // Handle class tap to show action options
  void _handleClassTap(ClassSlot classSlot, Teacher teacher) {
    // Check if this class belongs to the logged-in teacher
    bool isTeacherClass = classSlot.teacherId == teacher.id;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey.shade900,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Class details
              ListTile(
                title: Text(
                  classSlot.subject,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18.0,
                  ),
                ),
                subtitle: Text(
                  '${classSlot.startTime} - ${classSlot.endTime}, ${classSlot.roomNumber}',
                  style: const TextStyle(
                    color: Colors.grey,
                  ),
                ),
              ),
              const Divider(color: Colors.grey),
              
              // Action buttons (only for teacher's own classes)
              if (isTeacherClass) ...[
                _buildActionButton(
                  icon: Icons.cancel,
                  label: 'Cancel Class',
                  color: Colors.red,
                  onTap: () {
                    Navigator.pop(context);
                    _showActionDialog(classSlot, teacher, ActionType.cancel);
                  },
                ),
                _buildActionButton(
                  icon: Icons.event_repeat,
                  label: 'Reschedule Class',
                  color: Colors.orange,
                  onTap: () {
                    Navigator.pop(context);
                    _showActionDialog(classSlot, teacher, ActionType.reschedule);
                  },
                ),
                _buildActionButton(
                  icon: Icons.add_circle,
                  label: 'Add Extra Class',
                  color: Colors.green,
                  onTap: () {
                    Navigator.pop(context);
                    _showActionDialog(classSlot, teacher, ActionType.extraClass);
                  },
                ),
              ] else ...[
                // Message if the class doesn't belong to this teacher
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
  
  // Show action dialog for the selected action type
  void _showActionDialog(ClassSlot classSlot, Teacher teacher, ActionType actionType) {
    showDialog(
      context: context,
      builder: (context) => ActionDialog(
        classSlot: classSlot,
        actionType: actionType,
        teacherId: teacher.id,
        teacherName: teacher.name,
      ),
    );
  }
  
  // Handle adding an extra class (FAB)
  void _handleAddExtraClass(Teacher teacher) {
    // For now, just show a snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Feature coming soon: Add extra class'),
      ),
    );
  }
  
  // Build an action button for the bottom sheet
  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: color,
      ),
      title: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
        ),
      ),
      onTap: onTap,
    );
  }
}