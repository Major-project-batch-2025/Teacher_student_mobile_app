// lib/presentation/teacher/screens/teacher_profile.dart
// Purpose: Teacher profile screen showing personal information

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants.dart';
import '../../../domain/entities/teacher.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/screens/login_role_select.dart';

class TeacherProfileScreen extends StatelessWidget {
  const TeacherProfileScreen({Key? key}) : super(key: key);

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
          'Profile',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          // Notification bell
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              // TODO: Navigate to notifications screen
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Profile image
            CircleAvatar(
              radius: 50.0,
              backgroundColor: AppColors.profileBlue,
              child: Text(
                teacher.initials,
                style: const TextStyle(
                  fontSize: 36.0,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 16.0),
            
            // Teacher name
            Text(
              teacher.name,
              style: const TextStyle(
                fontSize: 24.0,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            // Teacher email
            Text(
              teacher.email,
              style: const TextStyle(
                fontSize: 16.0,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 32.0),
            
            // Teacher details card
            Card(
              color: Colors.grey.shade800,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    // Department
                    _buildInfoTile(
                      icon: Icons.school,
                      title: 'Department',
                      subtitle: teacher.department,
                    ),
                    const Divider(color: Colors.grey),
                    
                    // Employee ID
                    _buildInfoTile(
                      icon: Icons.badge,
                      title: 'Employee ID',
                      subtitle: teacher.employeeId,
                    ),
                    const Divider(color: Colors.grey),
                    
                    // Sections taught
                    _buildInfoTile(
                      icon: Icons.people,
                      title: 'Sections',
                      subtitle: teacher.allSections.join(', '),
                    ),
                    const Divider(color: Colors.grey),
                    
                    // Subjects taught
                    _buildInfoTile(
                      icon: Icons.book,
                      title: 'Subjects',
                      subtitle: teacher.teachingAssignments
                          .map((a) => a.subject)
                          .toSet()
                          .join(', '),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32.0),
            
            // Teaching schedule card
            Card(
              color: Colors.grey.shade800,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Teaching Schedule Summary',
                      style: TextStyle(
                        fontSize: 18.0,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16.0),
                    
                    // Display teaching assignments
                    ...teacher.teachingAssignments.map((assignment) => 
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              assignment.subject,
                              style: const TextStyle(
                                fontSize: 16.0,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(height: 4.0),
                            Text(
                              'Semester ${assignment.semester}, ${assignment.sections.join(", ")}',
                              style: const TextStyle(
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ).toList(),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32.0),
            
            // Logout button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  await authProvider.logout();
                  if (context.mounted) {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(
                        builder: (context) => const LoginRoleSelectScreen(),
                      ),
                      (route) => false,
                    );
                  }
                },
                icon: const Icon(Icons.logout),
                label: const Text('Logout'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(vertical: 12.0),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  // Helper widget to build info tile
  Widget _buildInfoTile({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: AppColors.profileBlue,
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 16.0,
          color: Colors.grey,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(
          fontSize: 18.0,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }
}