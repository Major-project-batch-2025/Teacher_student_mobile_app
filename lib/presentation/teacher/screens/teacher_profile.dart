// lib/presentation/teacher/screens/teacher_profile.dart
// Purpose: Teacher profile screen showing personal information And All section timetable view

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants.dart';
import '../../../domain/entities/teacher.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/screens/login_role_select.dart';
import '../screens/teacher_section_view.dart';

class TeacherProfileScreen extends StatelessWidget {
  const TeacherProfileScreen({super.key});

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
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile header
            Center(
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
                    style: const TextStyle(fontSize: 16.0, color: Colors.grey),
                  ),
                ],
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
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24.0),

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
            _buildSectionsList(context, teacher),

            const SizedBox(height: 24.0),

            // Subjects heading
            const Text(
              'Your Subjects',
              style: TextStyle(
                fontSize: 20.0,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8.0),

            // Subjects list
            _buildSubjectsList(teacher),

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

  // Build list of sections taught by the teacher
  Widget _buildSectionsList(BuildContext context, Teacher teacher) {
    // Get all unique sections from teacher's assignments
    final sectionsWithSemesters = <String, int>{};

    for (final assignment in teacher.teachingAssignments) {
      for (final section in assignment.sections) {
        sectionsWithSemesters[section] = assignment.semester;
      }
    }

    if (sectionsWithSemesters.isEmpty) {
      return const Center(
        child: Text(
          'No sections assigned',
          style: TextStyle(color: Colors.grey, fontSize: 16.0),
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.9, // Changed from 1.0 to give more height
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: sectionsWithSemesters.length,
      itemBuilder: (context, index) {
        final entry = sectionsWithSemesters.entries.elementAt(index);
        final section = entry.key;
        final semester = entry.value;
        return _buildSectionCard(context, section, semester, teacher);
      },
    );
  }

  // Build a section card
  Widget _buildSectionCard(
    BuildContext context,
    String section,
    int semester,
    Teacher teacher,
  ) {
    return GestureDetector(
      onTap: () {
        // Navigate to section timetable view
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) => TeacherSectionViewScreen(
                  section: section,
                  semester: semester,
                  department: teacher.department,
                ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey.shade800,
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.people, size: 28.0, color: AppColors.primary),
              const SizedBox(height: 4.0),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  ' $section',
                  style: const TextStyle(
                    fontSize: 16.0,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 2.0),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  'Sem $semester',
                  style: const TextStyle(fontSize: 12.0, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Build subjects list
  Widget _buildSubjectsList(Teacher teacher) {
    // Get unique subjects with their semesters
    final subjectsWithSemesters = <String, List<int>>{};

    for (final assignment in teacher.teachingAssignments) {
      if (subjectsWithSemesters.containsKey(assignment.subject)) {
        if (!subjectsWithSemesters[assignment.subject]!.contains(
          assignment.semester,
        )) {
          subjectsWithSemesters[assignment.subject]!.add(assignment.semester);
        }
      } else {
        subjectsWithSemesters[assignment.subject] = [assignment.semester];
      }
    }

    if (subjectsWithSemesters.isEmpty) {
      return const Center(
        child: Text(
          'No subjects assigned',
          style: TextStyle(color: Colors.grey, fontSize: 16.0),
        ),
      );
    }

    return Card(
      color: Colors.grey.shade800,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: subjectsWithSemesters.length,
        separatorBuilder:
            (_, __) => const Divider(color: Colors.grey, height: 1),
        itemBuilder: (context, index) {
          final entry = subjectsWithSemesters.entries.elementAt(index);
          final subject = entry.key;
          final semesters = entry.value;

          return ListTile(
            leading: const CircleAvatar(
              backgroundColor: AppColors.primary,
              child: Icon(Icons.book, color: Colors.white, size: 16),
            ),
            title: Text(subject, style: const TextStyle(color: Colors.white)),
            subtitle: Text(
              'Semester(s): ${semesters.join(', ')}',
              style: const TextStyle(color: Colors.grey),
            ),
          );
        },
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
      leading: Icon(icon, color: AppColors.profileBlue),
      title: Text(
        title,
        style: const TextStyle(fontSize: 16.0, color: Colors.grey),
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
