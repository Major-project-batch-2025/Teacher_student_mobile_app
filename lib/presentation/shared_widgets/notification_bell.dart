// lib/presentation/shared_widgets/notification_bell.dart
// Purpose: Notification bell widget with badge showing unread count

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// import '../../core/constants.dart';
import '../providers/notification_provider.dart';
import '../student/screens/student_notifications.dart';
import '../teacher/screens/teacher_notifications.dart';

class NotificationBell extends StatelessWidget {
  final bool isTeacher;
  
  const NotificationBell({
    super.key,
    this.isTeacher = false,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<NotificationProvider>(
      builder: (context, provider, child) {
        final unreadCount = provider.unreadCount;
        
        return Stack(
          children: [
            IconButton(
              icon: const Icon(Icons.notifications_outlined),
              onPressed: () {
                // Navigate to the appropriate notifications screen
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => isTeacher
                        ? const TeacherNotificationsScreen()
                        : const StudentNotificationsScreen(),
                  ),
                );
              },
            ),
            
            // Badge showing unread count
            if (unreadCount > 0)
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  child: Text(
                    unreadCount > 9 ? '9+' : '$unreadCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}