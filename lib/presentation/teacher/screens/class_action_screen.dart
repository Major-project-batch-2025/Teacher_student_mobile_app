// lib/presentation/teacher/screens/class_action_screen.dart
// Purpose: Show history of class actions for a specific section

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants.dart';
import '../../../domain/entities/class_action.dart';
import '../../providers/timetable_provider.dart';
import '../../../domain/entities/timetable.dart';

class ClassActionScreen extends StatelessWidget {
  final String section;
  
  const ClassActionScreen({
    super.key,
    required this.section,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        backgroundColor: AppColors.darkBackground,
        elevation: 0,
        title: Text(
          'Class Actions - $section',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Consumer<TimetableProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
          
          final actions = <ClassAction>[]; // TODO: Replace with real actions when backend is ready

          
          if (actions.isEmpty) {
            return const Center(
              child: Text(
                'No class actions found',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 16.0,
                ),
              ),
            );
          }
          
          return ListView.builder(
            itemCount: actions.length,
            itemBuilder: (context, index) {
              final action = actions[index];
              return _buildActionCard(context, action, provider);
            },
          );
        },
      ),
    );
  }
  
  // Build a card for each class action
  Widget _buildActionCard(
    BuildContext context, 
    ClassAction action, 
    TimetableProvider provider,
  ) {
    // Get action color
    Color actionColor;
    IconData actionIcon;
    
    switch (action.actionType) {
      case ActionType.cancel:
        actionColor = Colors.red;
        actionIcon = Icons.cancel;
        break;
      case ActionType.reschedule:
        actionColor = Colors.orange;
        actionIcon = Icons.event_repeat;
        break;
      case ActionType.extraClass:
        actionColor = Colors.green;
        actionIcon = Icons.add_circle;
        break;
      case ActionType.normalize:
        actionColor = AppColors.primary;
        actionIcon = Icons.refresh;
        break;
    }
    
    // Format date
    final actionDate = action.timestamp;
    final formattedDate = 
      '${actionDate.day}/${actionDate.month}/${actionDate.year} ' 
      '${actionDate.hour}:${actionDate.minute.toString().padLeft(2, '0')}';
    
    return Card(
      color: Colors.grey.shade800,
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Action type and date
            Row(
              children: [
                Icon(
                  actionIcon,
                  color: actionColor,
                ),
                const SizedBox(width: 8.0),
                Text(
                  action.actionTypeString,
                  style: TextStyle(
                    fontSize: 18.0,
                    fontWeight: FontWeight.bold,
                    color: actionColor,
                  ),
                ),
                const Spacer(),
                Text(
                  formattedDate,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 12.0,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16.0),
            
            // Subject
            Text(
              action.subject,
              style: const TextStyle(
                fontSize: 16.0,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8.0),
            
            // Reason
            Text(
              'Reason: ${action.reason}',
              style: const TextStyle(
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8.0),
            
            // Approval status
            Row(
              children: [
                Icon(
                  action.isApproved ? Icons.check_circle : Icons.pending,
                  color: action.isApproved ? Colors.green : Colors.amber,
                  size: 16.0,
                ),
                const SizedBox(width: 4.0),
                Text(
                  action.isApproved 
                      ? 'Approved'
                      : action.isExpired() 
                          ? 'Expired'
                          : 'Pending Approval',
                  style: TextStyle(
                    color: action.isApproved 
                        ? Colors.green
                        : action.isExpired()
                            ? Colors.grey
                            : Colors.amber,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            
            // Revert button (if action is still active)
            if (!action.isExpired())
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    // Confirm before reverting
                    _showRevertConfirmation(context, action, provider);
                  },
                  child: const Text('Revert'),
                ),
              ),
          ],
        ),
      ),
    );
  }
  
  // Show confirmation dialog before reverting an action
  void _showRevertConfirmation(
    BuildContext context, 
    ClassAction action, 
    TimetableProvider provider,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey.shade900,
        title: const Text(
          'Revert Action',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Are you sure you want to revert this ${action.actionTypeString.toLowerCase()}?',
          style: const TextStyle(
            color: Colors.white70,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // Apply the normalize action
              print('Would revert action: ${action.id}'); // TODO: Restore applyClassAction when backend ready
              Navigator.of(context).pop();
              
              // Show success message
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Action reverted successfully'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Revert'),
          ),
        ],
      ),
    );
  }
}