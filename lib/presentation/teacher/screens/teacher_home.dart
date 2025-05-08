// lib/presentation/teacher/screens/teacher_home.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants.dart';
import '../../../domain/entities/teacher.dart';
import '../../auth/providers/auth_provider.dart';
import '../../providers/notification_provider.dart';
import '../../providers/timetable_provider.dart';
import '../../shared_widgets/notification_bell.dart';
import '../widgets/teacher_personal_timetable.dart';
import 'teacher_profile.dart';

class TeacherHomeScreen extends StatefulWidget {
  const TeacherHomeScreen({super.key});

  @override
  State<TeacherHomeScreen> createState() => _TeacherHomeScreenState();
}

class _TeacherHomeScreenState extends State<TeacherHomeScreen> {
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    
    // Initialize providers after build completes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeProviders();
    });
  }
  
  // Initialize notification provider and fetch timetables for all sections
  Future<void> _initializeProviders() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final notificationProvider = Provider.of<NotificationProvider>(context, listen: false);
      final timetableProvider = Provider.of<TimetableProvider>(context, listen: false);
      
      // Get teacher user
      if (authProvider.isLoggedIn && authProvider.isTeacher) {
        final teacher = authProvider.user as Teacher;
        
        // Fetch notifications
        await notificationProvider.fetchNotifications(
          userId: teacher.id,
          isTeacher: true,
        );

        // Fetch timetables for all sections this teacher teaches
        // We're focusing on 7th semester sections
        final sections = ['A', 'B', 'C']; // 7th semester sections
        final semester = 7;
        final department = teacher.department;

        // Fetch all section timetables
        for (final section in sections) {
          await timetableProvider.initialize(
            department: department,
            section: section,
            semester: semester,
          );
        }
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    
    // Safety check to ensure user is logged in and is a teacher
    if (!authProvider.isLoggedIn || !authProvider.isTeacher) {
      // Handle case where user is not logged in or not a teacher
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
        title: const Text(
          'My Schedule',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          // Notification bell
          const NotificationBell(isTeacher: true),
          
          // Profile button
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const TeacherProfileScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Error loading timetable: $_error',
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _initializeProviders,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _initializeProviders,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Teacher info
                        Text(
                          'Hello, ${teacher.name}',
                          style: const TextStyle(
                            fontSize: 24.0,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          teacher.department,
                          style: const TextStyle(
                            fontSize: 16.0,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 24.0),
                        
                        // Teacher's personal timetable
                        const Text(
                          'Your Weekly Schedule',
                          style: TextStyle(
                            fontSize: 20.0,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 16.0),
                        
                        // Personal timetable widget
                        TeacherPersonalTimetable(teacher: teacher),
                      ],
                    ),
                  ),
                ),
    );
  }
}