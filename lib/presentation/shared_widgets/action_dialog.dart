// lib/presentation/shared_widgets/action_dialog.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/constants.dart';
import '../../domain/entities/class_action.dart';
import '../../domain/entities/timetable.dart';
import '../../domain/entities/teacher.dart';
import '../providers/timetable_provider.dart';
import '../../core/utils/date_helpers.dart';
import '../auth/providers/auth_provider.dart';

class ActionDialog extends StatefulWidget {
  final ClassSlot classSlot;
  final ActionType actionType;
  final String teacherId;
  final String teacherName;
  final String section;
  final int semester;
  final String department;
  
  const ActionDialog({
    super.key,
    required this.classSlot,
    required this.actionType,
    required this.teacherId,
    required this.teacherName,
    required this.section,
    required this.semester,
    required this.department,
  });

  @override
  State<ActionDialog> createState() => _ActionDialogState();
}

class _ActionDialogState extends State<ActionDialog> {
  final _formKey = GlobalKey<FormState>();
  final _reasonController = TextEditingController();
  final _subjectController = TextEditingController();
  ClassSlot? _targetSlot;
  bool _isSubmitting = false;
  String? _selectedSubject;
  
  @override
  void initState() {
    super.initState();
    // If it's an extra class, populate the subject dropdown
    if (widget.actionType == ActionType.extraClass) {
      _loadTeacherSubjects();
    }
  }
  
  // Load teacher's subjects for dropdown
  void _loadTeacherSubjects() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.isTeacher) {
      final teacher = authProvider.user as Teacher;
      // Get subjects for this specific section
      final subjects = <String>{};
      for (final assignment in teacher.teachingAssignments) {
        if (assignment.sections.contains(widget.section) && 
            assignment.semester == widget.semester) {
          subjects.add(assignment.subject);
        }
      }
      if (subjects.isNotEmpty) {
        _selectedSubject = subjects.first;
      }
    }
  }
  
  @override
  void dispose() {
    _reasonController.dispose();
    _subjectController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
      ),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: contentBox(context),
    );
  }
  
  Widget contentBox(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final teacher = authProvider.user as Teacher;
    
    // Get teacher's subjects for this section
    final teacherSubjects = <String>{};
    for (final assignment in teacher.teachingAssignments) {
      if (assignment.sections.contains(widget.section) && 
          assignment.semester == widget.semester) {
        teacherSubjects.add(assignment.subject);
      }
    }
    
    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        shape: BoxShape.rectangle,
        color: AppColors.darkBackground,
        borderRadius: BorderRadius.circular(16.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10.0,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              Text(
                _getTitle(),
                style: const TextStyle(
                  fontSize: 22.0,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16.0),
              
              // Original class info or subject selection for extra class
              if (widget.actionType == ActionType.extraClass)
                // Subject dropdown for extra class
                DropdownButtonFormField<String>(
                  value: _selectedSubject,
                  decoration: const InputDecoration(
                    labelText: 'Subject',
                    hintText: 'Select subject',
                    filled: true,
                    fillColor: Colors.black38,
                    border: OutlineInputBorder(),
                    labelStyle: TextStyle(color: Colors.grey),
                    hintStyle: TextStyle(color: Colors.grey),
                  ),
                  dropdownColor: Colors.grey.shade900,
                  style: const TextStyle(color: Colors.white),
                  items: teacherSubjects.map((subject) => 
                    DropdownMenuItem(
                      value: subject,
                      child: Text(subject),
                    )
                  ).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedSubject = value;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select a subject';
                    }
                    return null;
                  },
                )
              else
                Container(
                  padding: const EdgeInsets.all(12.0),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.classSlot.subject,
                        style: const TextStyle(
                          fontSize: 18.0,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8.0),
                      Text(
                        '${DateHelpers.getWeekdayName(widget.classSlot.dayOfWeek)}, ${widget.classSlot.startTime} - ${widget.classSlot.endTime}',
                        style: const TextStyle(
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 16.0),
              
              // Reason field
              TextFormField(
                controller: _reasonController,
                decoration: const InputDecoration(
                  labelText: 'Reason',
                  hintText: 'Enter reason for this action',
                  filled: true,
                  fillColor: Colors.black38,
                  border: OutlineInputBorder(),
                  labelStyle: TextStyle(color: Colors.grey),
                  hintStyle: TextStyle(color: Colors.grey),
                ),
                style: const TextStyle(color: Colors.white),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a reason';
                  }
                  return null;
                },
                maxLines: 3,
              ),
              const SizedBox(height: 24.0),
              
              // Action buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isSubmitting ? null : () {
                      Navigator.of(context).pop();
                    },
                    child: const Text(
                      'Cancel',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                  const SizedBox(width: 16.0),
                  SizedBox(
                    width: 120,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _submitAction,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _getActionColor(),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text('Confirm'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  // Get title based on action type
  String _getTitle() {
    switch (widget.actionType) {
      case ActionType.cancel:
        return 'Cancel Class';
      case ActionType.reschedule:
        return 'Reschedule Class';
      case ActionType.extraClass:
        return 'Add Extra Class';
      case ActionType.normalize:
        return 'Normalize Class';
    }
  }
  
  // Get button color based on action type
  Color _getActionColor() {
    switch (widget.actionType) {
      case ActionType.cancel:
        return Colors.red;
      case ActionType.reschedule:
        return Colors.orange;
      case ActionType.extraClass:
        return Colors.green;
      case ActionType.normalize:
        return AppColors.primary;
    }
  }
  
  // Submit the action
  Future<void> _submitAction() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isSubmitting = true;
      });

      try {
        // Get Firestore instance
        final firestore = FirebaseFirestore.instance;
        
        // Construct the path to the specific day collection
        final dayName = DateHelpers.getWeekdayName(widget.classSlot.dayOfWeek).toLowerCase();
        
        // Format the time slot to match Firebase field names
        final startTime = widget.classSlot.startTime;
        final endTime = widget.classSlot.endTime;
        final timeSlot = '$startTime-$endTime'; // Format: "8:30-9:30"
        
        print('Debug: Looking for timetable with:');
        print('Department: ${widget.department}');
        print('Section: ${widget.section}');
        print('Semester: ${widget.semester}');
        print('Day: $dayName');
        print('Time slot: $timeSlot');
        
        // Get reference to the Modified_TimeTable document
        final querySnapshot = await firestore
            .collection('Modified_TimeTable')
            .where('department', isEqualTo: widget.department)
            .where('section', isEqualTo: widget.section)
            .where('semester', isEqualTo: widget.semester)
            .limit(1)
            .get();

        if (querySnapshot.docs.isEmpty) {
          throw Exception('Timetable not found for ${widget.section}, Semester ${widget.semester}');
        }

        final docRef = querySnapshot.docs.first.reference;
        
        // Check if the day collection exists
        final dayCollection = await docRef.collection(dayName).get();
        
        if (dayCollection.docs.isEmpty) {
          throw Exception('No timetable data found for $dayName');
        }
        
        // Get the specific document for the day
        final dayDocRef = dayCollection.docs.first.reference;
        
        // Update the specific time slot field
        Map<String, dynamic> updateData = {};
        
        if (widget.actionType == ActionType.cancel) {
          // For cancellation, update the slot to show it's cancelled
          updateData[timeSlot] = {
            'course': 'Cancelled',
            'teacher': widget.teacherName,
            'originalCourse': widget.classSlot.subject,
            'reason': _reasonController.text,
          };
          
          print('Debug: Updating slot to cancelled');
        } else if (widget.actionType == ActionType.extraClass) {
          // For extra class, add the new class to the slot
          final subject = _selectedSubject ?? _subjectController.text;
          updateData[timeSlot] = {
            'course': subject,
            'teacher': widget.teacherName,
            'isExtraClass': true,
            'reason': _reasonController.text,
          };
          
          print('Debug: Adding extra class: $subject');
        }
        
        // Update only the specific field
        await dayDocRef.update(updateData);
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                widget.actionType == ActionType.cancel 
                  ? 'Class cancelled successfully' 
                  : 'Extra class added successfully'
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
        
        // Refresh the timetable
        if (context.mounted) {
          final timetableProvider = Provider.of<TimetableProvider>(context, listen: false);
          await timetableProvider.initialize(
            department: widget.department,
            section: widget.section,
            semester: widget.semester,
            isTeacher: true,
          );
        }
        
        // Close the dialog
        if (context.mounted) {
          Navigator.of(context).pop(true);
        }
      } catch (e) {
        print('Error: $e');
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${e.toString()}'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 5),
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isSubmitting = false;
          });
        }
      }
    }
  }
}