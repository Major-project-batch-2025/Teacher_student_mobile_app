// lib/presentation/auth/screens/login_role_select.dart
// Purpose: Screen for selecting login role (student or teacher)

import 'package:flutter/material.dart';

import '../../../core/constants.dart';
import 'student_login.dart';
import 'teacher_login.dart';

class LoginRoleSelectScreen extends StatelessWidget {
  const LoginRoleSelectScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // App Logo
              Center(
                child: Image.asset(
                  'assets/images/education_logo.png',
                  width: 120,
                  height: 120,
                  errorBuilder: (context, error, stackTrace) {
                    // Fallback to Icon if image asset is not available
                    return const Icon(
                      Icons.school,
                      size: 120,
                      color: AppColors.primary,
                    );
                  },
                ),
              ),
              const SizedBox(height: 32.0),
              
              // App Title
              const Text(
                AppStrings.appName,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 32.0,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 64.0),
              
              // Role Selection Header
              const Text(
                'Login as',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18.0,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 24.0),
              
              // Role Selection Buttons
              Row(
                children: [
                  // Student Button
                  Expanded(
                    child: _buildRoleButton(
                      context,
                      title: 'Login as Student',
                      icon: Icons.person,
                      backgroundColor: AppColors.primary,
                      isActive: true,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const StudentLoginScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                  
                  // Teacher Button
                  Expanded(
                    child: _buildRoleButton(
                      context,
                      title: 'Login as Teacher',
                      icon: Icons.school,
                      backgroundColor: Colors.white,
                      isActive: false,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const TeacherLoginScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
              // Removed login form container that was causing overflow
            ],
          ),
        ),
      ),
    );
  }

  // Helper method to build role selection button
  Widget _buildRoleButton(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color backgroundColor,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 150.0,
        padding: const EdgeInsets.all(16.0),
        margin: const EdgeInsets.all(8.0),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(10.0),
          border: Border.all(
            color: isActive ? AppColors.primary : Colors.grey.shade300,
            width: isActive ? 2.0 : 1.0,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 48.0,
              color: isActive ? Colors.white : AppColors.primary,
            ),
            const SizedBox(height: 16.0),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16.0,
                fontWeight: FontWeight.bold,
                color: isActive ? Colors.white : AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}