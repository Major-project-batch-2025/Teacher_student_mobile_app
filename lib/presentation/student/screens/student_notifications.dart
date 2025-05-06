// lib/presentation/student/screens/student_notifications.dart
// Purpose: Student notifications screen showing list of notifications

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants.dart';
import '../../../data/models/notification_model.dart';
import '../../providers/notification_provider.dart';

class StudentNotificationsScreen extends StatelessWidget {
  const StudentNotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        backgroundColor: AppColors.darkBackground,
        elevation: 0,
        title: const Text(
          'Notifications',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          // Mark all as read button
          TextButton.icon(
            onPressed: () {
              final provider = Provider.of<NotificationProvider>(context, listen: false);
              provider.markAllAsRead();
            },
            icon: const Icon(
              Icons.done_all,
              color: Colors.white70,
            ),
            label: const Text(
              'Mark all as read',
              style: TextStyle(
                color: Colors.white70,
              ),
            ),
          ),
        ],
      ),
      body: Consumer<NotificationProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
          
          if (provider.notifications.isEmpty) {
            return const Center(
              child: Text(
                'No notifications yet',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 16.0,
                ),
              ),
            );
          }
          
          return ListView.builder(
            itemCount: provider.notifications.length,
            itemBuilder: (context, index) {
              final notification = provider.notifications[index];
              return _buildNotificationTile(context, notification);
            },
          );
        },
      ),
    );
  }
  
  // Build notification tile
  Widget _buildNotificationTile(BuildContext context, NotificationModel notification) {
    // Notification icon based on type
    IconData iconData;
    Color iconColor;
    
    switch (notification.type) {
      case NotificationType.classCancelled:
        iconData = Icons.cancel;
        iconColor = Colors.red;
        break;
      case NotificationType.classRescheduled:
        iconData = Icons.event_repeat;
        iconColor = Colors.orange;
        break;
      case NotificationType.extraClass:
        iconData = Icons.add_circle;
        iconColor = Colors.green;
        break;
      case NotificationType.announcement:
        iconData = Icons.announcement;
        iconColor = Colors.blue;
        break;
      case NotificationType.actionApproved:
        iconData = Icons.check_circle;
        iconColor = Colors.green;
        break;
      case NotificationType.actionDenied:
        iconData = Icons.cancel;
        iconColor = Colors.red;
        break;
    }
    
    // Format timestamp
    final now = DateTime.now();
    final difference = now.difference(notification.timestamp);
    String timeAgo;
    
    if (difference.inDays > 0) {
      timeAgo = '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      timeAgo = '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inMinutes > 0) {
      timeAgo = '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    } else {
      timeAgo = 'Just now';
    }
    
    return Dismissible(
      key: Key(notification.id),
      background: Container(
        color: Colors.blue,
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: const Icon(
          Icons.done,
          color: Colors.white,
        ),
      ),
      secondaryBackground: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: const Icon(
          Icons.delete,
          color: Colors.white,
        ),
      ),
      onDismissed: (direction) {
        // Mark as read
        final provider = Provider.of<NotificationProvider>(context, listen: false);
        provider.markAsRead(notification.id);
      },
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: iconColor.withOpacity(0.2),
          child: Icon(
            iconData,
            color: iconColor,
          ),
        ),
        title: Text(
          notification.title,
          style: TextStyle(
            color: Colors.white,
            fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              notification.message,
              style: const TextStyle(
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 4.0),
            Text(
              timeAgo,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 12.0,
              ),
            ),
          ],
        ),
        onTap: () {
          // Mark as read
          if (!notification.isRead) {
            final provider = Provider.of<NotificationProvider>(context, listen: false);
            provider.markAsRead(notification.id);
          }
          
          // Show notification details
          _showNotificationDetails(context, notification);
        },
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16.0,
          vertical: 8.0,
        ),
      ),
    );
  }
  
  // Show notification details dialog
  void _showNotificationDetails(BuildContext context, NotificationModel notification) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.darkBackground,
        title: Text(
          notification.title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              notification.message,
              style: const TextStyle(
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 16.0),
            Text(
              'Received: ${_formatDateTime(notification.timestamp)}',
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 12.0,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
  
  // Format date time for display
  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    final notificationDate = DateTime(dateTime.year, dateTime.month, dateTime.day);
    
    String dateStr;
    if (notificationDate == today) {
      dateStr = 'Today';
    } else if (notificationDate == yesterday) {
      dateStr = 'Yesterday';
    } else {
      dateStr = '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
    
    final timeStr = '${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    return '$dateStr at $timeStr';
  }
}