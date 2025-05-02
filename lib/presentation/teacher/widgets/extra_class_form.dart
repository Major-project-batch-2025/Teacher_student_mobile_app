// lib/presentation/teacher/widgets/extra_class_form.dart
// Purpose: Form widget for scheduling extra classes

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants.dart';
import '../../../core/utils/date_helpers.dart';
import '../../../domain/entities/class_action.dart';
import '../../../domain/entities/teacher.dart';
import '../../../domain/entities/timetable.dart';
import '../../auth/providers/auth_provider.dart';
import '../../providers/timetable_provider.dart';

class ExtraClassForm extends StatefulWidget {
  final String section;
  final int semester;
  
  const ExtraClassForm({
    Key? key,
    required this.section,
    required this.semester,
  }) : super(key: key);

  @override
  State<ExtraClassForm> createState() => _ExtraClassFormState();
}

class _ExtraClassFormState extends State<ExtraClassForm> {
  final _formKey = GlobalKey<FormState>();
  final _subjectController = TextEditingController();
  final _roomController = TextEditingController();
  final _reasonController = TextEditingController();
  
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _startTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 10, minute: 30);
  
  @override
  void dispose() {
    _subjectController.dispose();
    _roomController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    
    if (!authProvider.isLoggedIn || !authProvider.isTeacher) {
      return const Center(
        child: Text('You need to be logged in as a teacher'),
      );
    }
    
    final teacher = authProvider.user as Teacher;
    
    // Get subjects taught by this teacher to this section
    final subjectsTaught = <String>[];
    for (final assignment in teacher.teachingAssignments) {
      if (assignment.sections.contains(widget.section) && 
          assignment.semester == widget.semester) {
        subjectsTaught.add(assignment.subject);
      }
    }
    
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Schedule Extra Class',
            style: TextStyle(
              fontSize: 20.0,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 24.0),
          
          // Subject dropdown
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(
              labelText: 'Subject',
              filled: true,
              fillColor: Colors.black38,
              border: OutlineInputBorder(),
              labelStyle: TextStyle(color: Colors.grey),
            ),
            dropdownColor: Colors.grey.shade900,
            items: subjectsTaught.map((subject) {
              return DropdownMenuItem<String>(
                value: subject,
                child: Text(
                  subject,
                  style: const TextStyle(color: Colors.white),
                ),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _subjectController.text = value ?? '';
              });
            },
            style: const TextStyle(
              color: Colors.white,
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please select a subject';
              }
              return null;
            },
          ),
          const SizedBox(height: 16.0),
          
          // Date picker
          InkWell(
            onTap: () => _selectDate(context),
            child: InputDecorator(
              decoration: const InputDecoration(
                labelText: 'Date',
                filled: true,
                fillColor: Colors.black38,
                border: OutlineInputBorder(),
                labelStyle: TextStyle(color: Colors.grey),
                suffixIcon: Icon(Icons.calendar_today, color: Colors.grey),
              ),
              child: Text(
                DateHelpers.formatDate(_selectedDate),
                style: const TextStyle(
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16.0),
          
          // Time pickers (start and end)
          Row(
            children: [
              // Start time
              Expanded(
                child: InkWell(
                  onTap: () => _selectStartTime(context),
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Start Time',
                      filled: true,
                      fillColor: Colors.black38,
                      border: OutlineInputBorder(),
                      labelStyle: TextStyle(color: Colors.grey),
                      suffixIcon: Icon(Icons.access_time, color: Colors.grey),
                    ),
                    child: Text(
                      _formatTimeOfDay(_startTime),
                      style: const TextStyle(
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16.0),
              
              // End time
              Expanded(
                child: InkWell(
                  onTap: () => _selectEndTime(context),
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'End Time',
                      filled: true,
                      fillColor: Colors.black38,
                      border: OutlineInputBorder(),
                      labelStyle: TextStyle(color: Colors.grey),
                      suffixIcon: Icon(Icons.access_time, color: Colors.grey),
                    ),
                    child: Text(
                      _formatTimeOfDay(_endTime),
                      style: const TextStyle(
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16.0),
          
          // Room number
          TextFormField(
            controller: _roomController,
            decoration: const InputDecoration(
              labelText: 'Room Number',
              filled: true,
              fillColor: Colors.black38,
              border: OutlineInputBorder(),
              labelStyle: TextStyle(color: Colors.grey),
              hintStyle: TextStyle(color: Colors.grey),
            ),
            style: const TextStyle(color: Colors.white),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter a room number';
              }
              return null;
            },
          ),
          const SizedBox(height: 16.0),
          
          // Reason
          TextFormField(
            controller: _reasonController,
            decoration: const InputDecoration(
              labelText: 'Reason',
              filled: true,
              fillColor: Colors.black38,
              border: OutlineInputBorder(),
              labelStyle: TextStyle(color: Colors.grey),
              hintStyle: TextStyle(color: Colors.grey),
            ),
            style: const TextStyle(color: Colors.white),
            maxLines: 3,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter a reason for the extra class';
              }
              return null;
            },
          ),
          const SizedBox(height: 24.0),
          
          // Submit button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _submitForm,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 12.0),
              ),
              child: const Text('Schedule Extra Class'),
            ),
          ),
        ],
      ),
    );
  }
  
  // Select date
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: Colors.grey,
              onSurface: Colors.white,
            ),
            dialogBackgroundColor: Colors.grey.shade900,
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }
  
  // Select start time
  Future<void> _selectStartTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _startTime,
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: Colors.grey,
              onSurface: Colors.white,
            ),
            dialogBackgroundColor: Colors.grey.shade900,
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null && picked != _startTime) {
      setState(() {
        _startTime = picked;
        
        // Automatically set end time 1.5 hours later
        final int totalMinutes = picked.hour * 60 + picked.minute + 90;
        _endTime = TimeOfDay(
          hour: totalMinutes ~/ 60,
          minute: totalMinutes % 60,
        );
      });
    }
  }
  
  // Select end time
  Future<void> _selectEndTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _endTime,
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: Colors.grey,
              onSurface: Colors.white,
            ),
            dialogBackgroundColor: Colors.grey.shade900,
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null && picked != _endTime) {
      // Validate that end time is after start time
      final startMinutes = _startTime.hour * 60 + _startTime.minute;
      final endMinutes = picked.hour * 60 + picked.minute;
      
      if (endMinutes <= startMinutes) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('End time must be after start time'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      
      setState(() {
        _endTime = picked;
      });
    }
  }
  
  // Format TimeOfDay to string
  String _formatTimeOfDay(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
  
  // Submit form
  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final timetableProvider = Provider.of<TimetableProvider>(context, listen: false);
      
      if (!authProvider.isLoggedIn || !authProvider.isTeacher) {
        return;
      }
      
      final teacher = authProvider.user as Teacher;
      
      // Calculate day of week (0 = Monday, 6 = Sunday)
      final dayOfWeek = _selectedDate.weekday - 1;
      
      // Check if day is within Monday-Saturday
      if (dayOfWeek > 5) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cannot schedule classes on Sunday'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      
      // Create a sample class slot for the extra class
      final originSlot = ClassSlot(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        subject: _subjectController.text,
        teacherId: teacher.id,
        teacherName: teacher.name,
        roomNumber: _roomController.text,
        dayOfWeek: dayOfWeek,
        startTime: _formatTimeOfDay(_startTime),
        endTime: _formatTimeOfDay(_endTime),
        durationMinutes: (_endTime.hour * 60 + _endTime.minute) - 
                         (_startTime.hour * 60 + _startTime.minute),
        updatedAt: DateTime.now(),
      );
      
      // Apply the extra class action
      timetableProvider.applyClassAction(
        ActionType.extraClass,
        originSlot: originSlot,
        targetSlot: originSlot, // Same as origin for extra class
        teacherId: teacher.id,
        teacherName: teacher.name,
        reason: _reasonController.text,
      );
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Extra class scheduled successfully'),
          backgroundColor: Colors.green,
        ),
      );
      
      // Close form or reset
      Navigator.of(context).pop(true);
    }
  }
}