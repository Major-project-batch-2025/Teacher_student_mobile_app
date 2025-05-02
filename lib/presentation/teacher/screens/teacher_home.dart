// lib/presentation/teacher/screens/teacher_home.dart
// Purpose: Home screen for teacher users showing classes and sections

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants.dart';
import '../../../domain/entities/teacher.dart';
import '../../auth/providers/auth_provider.dart';
import '../../providers/notification_provider.dart';
import '../../shared_widgets/notification_bell.dart';
import 'teacher_profile.dart';
import 'teacher_section_view.dart';

class TeacherHomeScreen extends StatefulWidget {
  const TeacherHomeScreen({Key? key}) : super(key: key);

  @override
  State<TeacherHomeScreen> createState() => _TeacherHomeScreenState();
}

class _TeacherHomeScreenState extends State<TeacherHomeScreen> {
  @override
  void initState() {
    super.initState();
    
    // Initialize providers after build completes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeProviders();
    });
  }
  
  // Initialize notification provider
  Future<void> _initializeProviders() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final notificationProvider = Provider.of<NotificationProvider>(context, listen: false);
    
    // Get teacher user
    if (authProvider.isLoggedIn && authProvider.isTeacher) {
      final teacher = authProvider.user as Teacher;
      
      // Fetch notifications
      await notificationProvider.fetchNotifications(
        userId: teacher.id,
        isTeacher: true,
      );
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
          'My Classes',
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
      body: RefreshIndicator(
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
              const SizedBox(height: 32.0),
              
              // Sections heading
              const Text(
                'Your Sections',
                style: TextStyle(
                  fontSize: 20.0,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16.0),
              
              // List of sections taught
              _buildSectionsList(teacher),
              const SizedBox(height: 32.0),
              
              // Subjects heading
              const Text(
                'Your Subjects',
                style: TextStyle(
                  fontSize: 20.0,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16.0),
              
              // List of subjects taught
              _buildSubjectsList(teacher),
            ],
          ),
        ),
      ),
    );
  }
  
  // Build list of sections taught by the teacher
  Widget _buildSectionsList(Teacher teacher) {
    final sections = teacher.allSections;
    
    if (sections.isEmpty) {
      return const Center(
        child: Text(
          'No sections assigned',
          style: TextStyle(
            color: Colors.grey,
          ),
        ),
      );
    }
    
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.5,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: sections.length,
      itemBuilder: (context, index) {
        final section = sections[index];
        return _buildSectionCard(context, section);
      },
    );
  }
  
  // Build a section card
  Widget _buildSectionCard(BuildContext context, String section) {
    // Find semester for this section
    final teacher = Provider.of<AuthProvider>(context).user as Teacher;
    int? semester;
    String? department;
    
    for (final assignment in teacher.teachingAssignments) {
      if (assignment.sections.contains(section)) {
        semester = assignment.semester;
        department = assignment.departmentCode;
        break;
      }
    }
    
    return GestureDetector(
      onTap: () {
        // Navigate to section timetable view
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TeacherSectionViewScreen(
              section: section,
              semester: semester ?? 0,
              department: department ?? '',
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey.shade800,
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.people,
              size: 32.0,
              color: AppColors.primary,
            ),
            const SizedBox(height: 8.0),
            Text(
              section,
              style: const TextStyle(
                fontSize: 18.0,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            if (semester != null)
              Text(
                'Semester $semester',
                style: const TextStyle(
                  fontSize: 14.0,
                  color: Colors.grey,
                ),
              ),
          ],
        ),
      ),
    );
  }
  
  // Build list of subjects taught by the teacher
  Widget _buildSubjectsList(Teacher teacher) {
    // Get unique subjects
    final subjects = <String>{};
    for (final assignment in teacher.teachingAssignments) {
      subjects.add(assignment.subject);
    }
    
    if (subjects.isEmpty) {
      return const Center(
        child: Text(
          'No subjects assigned',
          style: TextStyle(
            color: Colors.grey,
          ),
        ),
      );
    }
    
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: subjects.length,
      itemBuilder: (context, index) {
        final subject = subjects.elementAt(index);
        
        // Find sections for this subject
        final sections = <String>[];
        for (final assignment in teacher.teachingAssignments) {
          if (assignment.subject == subject) {
            sections.addAll(assignment.sections);
          }
        }
        
        return Card(
          color: Colors.grey.shade800,
          margin: const EdgeInsets.only(bottom: 8.0),
          child: ListTile(
            title: Text(
              subject,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Text(
              'Taught in ${sections.join(", ")}',
              style: const TextStyle(
                color: Colors.grey,
              ),
            ),
            leading: const CircleAvatar(
              backgroundColor: AppColors.primary,
              child: Icon(
                Icons.book,
                color: Colors.white,
              ),
            ),
            trailing: const Icon(
              Icons.arrow_forward_ios,
              color: Colors.grey,
              size: 16.0,
            ),
            onTap: () {
              // TO DO: Navigate to subject details
            },
          ),
        );
      },
    );
  }
}