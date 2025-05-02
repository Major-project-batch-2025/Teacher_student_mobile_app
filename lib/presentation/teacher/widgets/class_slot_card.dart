// lib/presentation/teacher/widgets/class_slot_card.dart
// Purpose: Card widget for displaying class slot in teacher view

import 'package:flutter/material.dart';

import '../../../core/constants.dart';
import '../../../domain/entities/timetable.dart';

class ClassSlotCard extends StatelessWidget {
  final ClassSlot classSlot;
  final VoidCallback? onTap;
  final bool showActions;
  
  const ClassSlotCard({
    Key? key,
    required this.classSlot,
    this.onTap,
    this.showActions = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Determine card color based on colorCode
    Color borderColor;
    switch (classSlot.colorCode) {
      case 'red':
        borderColor = AppColors.classRed;
        break;
      case 'green':
        borderColor = AppColors.classGreen;
        break;
      case 'purple':
        borderColor = Colors.purple;
        break;
      case 'orange':
        borderColor = Colors.orange;
        break;
      case 'blue':
      default:
        borderColor = AppColors.classBlue;
        break;
    }
    
    // Format time display
    final duration = '${classSlot.durationMinutes ~/ 60}h ${classSlot.durationMinutes % 60}m';
    
    // Determine status badge
    Widget? statusBadge;
    if (classSlot.isCancelled) {
      statusBadge = _buildStatusBadge('Cancelled', Colors.red);
    } else if (classSlot.isRescheduled) {
      statusBadge = _buildStatusBadge('Rescheduled', Colors.orange);
    } else if (classSlot.isExtraClass) {
      statusBadge = _buildStatusBadge('Extra Class', Colors.green);
    }
    
    return Card(
      color: Colors.grey.shade800,
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.0),
        side: BorderSide(
          color: borderColor,
          width: 2.0,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8.0),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Status Badge
              if (statusBadge != null)
                Align(
                  alignment: Alignment.topRight,
                  child: statusBadge,
                ),
              
              // Time and Duration
              Row(
                children: [
                  const Icon(
                    Icons.access_time,
                    size: 16.0,
                    color: Colors.grey,
                  ),
                  const SizedBox(width: 8.0),
                  Text(
                    '${classSlot.startTime} - ${classSlot.endTime}',
                    style: const TextStyle(
                      color: Colors.grey,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8.0,
                      vertical: 2.0,
                    ),
                    decoration: BoxDecoration(
                      color: borderColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4.0),
                    ),
                    child: Text(
                      duration,
                      style: TextStyle(
                        color: borderColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12.0,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12.0),
              
              // Subject Name
              Text(
                classSlot.subject,
                style: TextStyle(
                  color: classSlot.isCancelled 
                      ? Colors.grey 
                      : Colors.white,
                  fontSize: 18.0,
                  fontWeight: FontWeight.bold,
                  decoration: classSlot.isCancelled 
                      ? TextDecoration.lineThrough 
                      : null,
                ),
              ),
              const SizedBox(height: 8.0),
              
              // Room and Teacher
              Row(
                children: [
                  const Icon(
                    Icons.room,
                    size: 16.0,
                    color: Colors.grey,
                  ),
                  const SizedBox(width: 8.0),
                  Text(
                    classSlot.roomNumber,
                    style: const TextStyle(
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
              
              // Action buttons
              if (showActions && !classSlot.isCancelled)
                Padding(
                  padding: const EdgeInsets.only(top: 12.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      _buildActionButton(
                        icon: Icons.cancel,
                        color: Colors.red,
                        tooltip: 'Cancel Class',
                        onPressed: onTap,
                      ),
                      const SizedBox(width: 8.0),
                      _buildActionButton(
                        icon: Icons.event_repeat,
                        color: Colors.orange,
                        tooltip: 'Reschedule',
                        onPressed: onTap,
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
  
  // Build status badge
  Widget _buildStatusBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8.0,
        vertical: 4.0,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(4.0),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 12.0,
        ),
      ),
    );
  }
  
  // Build action button
  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required String tooltip,
    required VoidCallback? onPressed,
  }) {
    return Material(
      color: Colors.transparent,
      child: Tooltip(
        message: tooltip,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(20.0),
          child: Container(
            padding: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: color,
              size: 16.0,
            ),
          ),
        ),
      ),
    );
  }
}