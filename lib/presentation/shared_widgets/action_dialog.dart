// lib/presentation/shared_widgets/action_dialog.dart
// Purpose: Dialog for creating class actions (cancel, reschedule, extra)

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants.dart';
import '../../domain/entities/class_action.dart';
import '../../domain/entities/timetable.dart';
import '../providers/timetable_provider.dart';
import '../../core/utils/date_helpers.dart';

class ActionDialog extends StatefulWidget {
  final ClassSlot classSlot;
  final ActionType actionType;
  final String teacherId;
  final String teacherName;
  
  const ActionDialog({
    Key? key,
    required this.classSlot,
    required this.actionType,
    required this.teacherId,
    required this.teacherName,
  }) : super(key: key);

  @override
  State<ActionDialog> createState() => _ActionDialogState();
}

class _ActionDialogState extends State<ActionDialog> {
  final _formKey = GlobalKey<FormState>();
  final _reasonController = TextEditingController();
  ClassSlot? _targetSlot;
  
  @override
  void dispose() {
    _reasonController.dispose();
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
            
            // Original class info
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
                  Text(
                    'Room: ${widget.classSlot.roomNumber}',
                    style: const TextStyle(
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16.0),
            
            // Target slot selection (for reschedule or extra class)
            if (widget.actionType == ActionType.reschedule || 
                widget.actionType == ActionType.extraClass)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Select new time slot:',
                    style: TextStyle(
                      fontSize: 16.0,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8.0),
                  _buildTimeSlotSelector(),
                  const SizedBox(height: 16.0),
                ],
              ),
            
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
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                const SizedBox(width: 16.0),
                ElevatedButton(
                  onPressed: _submitAction,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _getActionColor(),
                  ),
                  child: const Text('Confirm'),
                ),
              ],
            ),
          ],
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
        return 'Schedule Extra Class';
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
  
  // Build time slot selector for reschedule or extra class
  Widget _buildTimeSlotSelector() {
    // Sample time slots for demonstration
    final timeSlots = [
      _createSampleTimeSlot(1, '09:00', '10:30'), // Tuesday 9:00-10:30
      _createSampleTimeSlot(2, '11:00', '12:30'), // Wednesday 11:00-12:30
      _createSampleTimeSlot(3, '14:00', '15:30'), // Thursday 14:00-15:30
      _createSampleTimeSlot(5, '09:00', '10:30'), // Saturday 9:00-10:30
    ];
    
    return Container(
      height: 150.0,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: ListView.builder(
        itemCount: timeSlots.length,
        itemBuilder: (context, index) {
          final slot = timeSlots[index];
          final isSelected = _targetSlot?.id == slot.id;
          
          return ListTile(
            title: Text(
              '${DateHelpers.getWeekdayName(slot.dayOfWeek)}, ${slot.startTime} - ${slot.endTime}',
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey,
              ),
            ),
            subtitle: Text(
              'Room: ${slot.roomNumber}',
              style: TextStyle(
                color: isSelected ? Colors.white70 : Colors.grey,
              ),
            ),
            leading: Radio<String>(
              value: slot.id,
              groupValue: _targetSlot?.id,
              onChanged: (value) {
                setState(() {
                  _targetSlot = slot;
                });
              },
              activeColor: _getActionColor(),
            ),
          );
        },
      ),
    );
  }
  
  // Create a sample time slot for demonstration
  ClassSlot _createSampleTimeSlot(int dayOfWeek, String startTime, String endTime) {
    return ClassSlot(
      id: 'slot_$dayOfWeek\_$startTime',
      subject: widget.classSlot.subject,
      teacherId: widget.teacherId,
      teacherName: widget.teacherName,
      roomNumber: widget.classSlot.roomNumber,
      dayOfWeek: dayOfWeek,
      startTime: startTime,
      endTime: endTime,
      durationMinutes: 90,
      updatedAt: DateTime.now(),
    );
  }
  
  // Submit the action
  void _submitAction() {
    if (_formKey.currentState!.validate()) {
      // Validate target slot for reschedule or extra class
      if ((widget.actionType == ActionType.reschedule || 
           widget.actionType == ActionType.extraClass) && 
          _targetSlot == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select a time slot'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      
      // Get the timetable provider
      final provider = Provider.of<TimetableProvider>(context, listen: false);
      
      // Apply the action
      provider.applyClassAction(
        widget.actionType,
        originSlot: widget.classSlot,
        targetSlot: _targetSlot,
        teacherId: widget.teacherId,
        teacherName: widget.teacherName,
        reason: _reasonController.text,
      );
      
      // Close the dialog
      Navigator.of(context).pop(true);
    }
  }
}