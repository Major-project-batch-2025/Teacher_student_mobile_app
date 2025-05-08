// lib/presentation/auth/screens/login_role_select.dart

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
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const Spacer(flex: 1),
              
              // App Logo
              Center(
                child: Image.asset(
                  'assets/images/education_logo.png',
                  width: 100,
                  height: 100,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(
                      Icons.school,
                      size: 100,
                      color: AppColors.primary,
                    );
                  },
                ),
              ),
              const SizedBox(height: 24.0),
              
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
              
              const Spacer(flex: 1),
              
              // Login Text - Made Bold
              const Text(
                'Login as',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24.0,
                  fontWeight: FontWeight.bold, // Made bold
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 24.0),
              
              // Role Selection Cards - Fixed size to prevent overflow
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Student Button
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: _buildRoleButton(
                        context,
                        title: 'Student', // Simplified text
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
                  ),
                  
                  // Teacher Button
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: _buildRoleButton(
                        context,
                        title: 'Teacher', // Simplified text
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
                  ),
                ],
              ),
              
              const Spacer(flex: 2),
            ],
          ),
        ),
      ),
    );
  }

  // Helper method to build role selection button with fixed height
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
        height: 130, // Fixed height to prevent overflow
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(10.0),
          border: Border.all(
            color: isActive ? AppColors.primary : Colors.grey.shade300,
            width: isActive ? 2.0 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 5,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 48.0,
              color: isActive ? Colors.white : AppColors.primary,
            ),
            const SizedBox(height: 8.0), // Reduced space
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