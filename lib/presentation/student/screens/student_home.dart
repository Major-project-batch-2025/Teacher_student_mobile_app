// lib/presentation/student/screens/student_home.dart
// Purpose: Home screen for student users showing their timetable

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants.dart';
import '../../../domain/entities/student.dart';
import '../../auth/providers/auth_provider.dart';
import '../../providers/notification_provider.dart';
import '../../providers/timetable_provider.dart';
import '../../shared_widgets/notification_bell.dart';
import '../../shared_widgets/timetable_grid.dart';
import 'student_profile.dart';

class StudentHomeScreen extends StatefulWidget {
  const StudentHomeScreen({Key? key}) : super(key: key);

  @override
  State<StudentHomeScreen> createState() => _StudentHomeScreenState();
}

class _StudentHomeScreenState extends State<StudentHomeScreen> {
  @override
  void initState() {
    super.initState();
    
    // Initialize providers after build completes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeProviders();
    });
  }
  
  // Initialize timetable and notification providers
  Future<void> _initializeProviders() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final timetableProvider = Provider.of<TimetableProvider>(context, listen: false);
    final notificationProvider = Provider.of<NotificationProvider>(context, listen: false);
    
    // Get student user
    if (authProvider.isLoggedIn && authProvider.isStudent) {
      final student = authProvider.user as Student;
      
      // Initialize timetable
      await timetableProvider.initialize(
        department: student.department,
        section: student.section,
        semester: student.semester,
      );
      
      // Fetch notifications
      await notificationProvider.fetchNotifications(
        userId: student.id,
        isTeacher: false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    
    // Safety check to ensure user is logged in and is a student
    if (!authProvider.isLoggedIn || !authProvider.isStudent) {
      // Handle case where user is not logged in or not a student
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('You need to be logged in as a student'),
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
    
    final student = authProvider.user as Student;
    
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        backgroundColor: AppColors.darkBackground,
        elevation: 0,
        title: Text(
          AppStrings.yourSchedule,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          // Notification bell
          const NotificationBell(),
          
          // Profile button
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const StudentProfileScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _initializeProviders,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Student info
              Text(
                'Hello, ${student.name}',
                style: const TextStyle(
                  fontSize: 24.0,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(
                '${student.department} - ${student.section}',
                style: const TextStyle(
                  fontSize: 16.0,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 24.0),
              
              // Timetable grid
              const TimetableGrid(),
            ],
          ),
        ),
      ),
    );
  }
}