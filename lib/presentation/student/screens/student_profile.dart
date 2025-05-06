// lib/presentation/student/screens/student_profile.dart
// Purpose: Student profile screen showing personal information

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants.dart';
import '../../../domain/entities/student.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/screens/login_role_select.dart';

class StudentProfileScreen extends StatelessWidget {
  const StudentProfileScreen({super.key});

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
                student.initials,
                style: const TextStyle(
                  fontSize: 36.0,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 16.0),
            
            // Student name
            Text(
              student.name,
              style: const TextStyle(
                fontSize: 24.0,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            // Student email
            Text(
              student.email,
              style: const TextStyle(
                fontSize: 16.0,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 32.0),
            
            // Student details card
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
                      subtitle: student.department,
                    ),
                    const Divider(color: Colors.grey),
                    
                    // Roll Number
                    _buildInfoTile(
                      icon: Icons.badge,
                      title: 'Roll Number',
                      subtitle: student.rollNumber,
                    ),
                    const Divider(color: Colors.grey),
                    
                    // Section
                    _buildInfoTile(
                      icon: Icons.people,
                      title: 'Section',
                      subtitle: student.section,
                    ),
                    const Divider(color: Colors.grey),
                    
                    // Semester
                    _buildInfoTile(
                      icon: Icons.calendar_today,
                      title: 'Semester',
                      subtitle: '${student.semester}th Semester',
                    ),
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