// lib/core/constants.dart
// Purpose: Defines app-wide constants including colors, text styles, and spacing

import 'package:flutter/material.dart';

// Colors from colors.dart
class AppColors {
  static const Color primary = Color(0xFF2196F3);
  static const Color secondary = Color(0xFF03A9F4);
  static const Color accent = Color(0xFF00BCD4);
  static const Color background = Color(0xFFF5F5F5);
  static const Color cardBackground = Colors.white;
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color divider = Color(0xFFBDBDBD);
  
  // Additional colors based on app design in provided images
  static const Color darkBackground = Color(0xFF212121);
  static const Color error = Colors.red;
  static const Color success = Colors.green;
  static const Color warning = Colors.orange;
  static const Color classBlue = Color(0xFF2196F3);  // For blue class cards
  static const Color classRed = Colors.red;          // For red class cards
  static const Color classGreen = Colors.green;      // For green class cards
  static const Color profileBlue = Color(0xFF2196F3); // For profile circle
}

// Text Styles
class AppTextStyles {
  static const TextStyle headerLarge = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );
  
  static const TextStyle headerMedium = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );
  
  static const TextStyle title = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );
  
  static const TextStyle subtitle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
  );
  
  static const TextStyle body = TextStyle(
    fontSize: 14,
    color: AppColors.textPrimary,
  );
  
  static const TextStyle caption = TextStyle(
    fontSize: 12,
    color: AppColors.textSecondary,
  );
  
  static const TextStyle buttonText = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: Colors.white,
  );
}

// Spacing
class AppSpacing {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;
  
  // Padding
  static const EdgeInsets paddingXS = EdgeInsets.all(xs);
  static const EdgeInsets paddingSM = EdgeInsets.all(sm);
  static const EdgeInsets paddingMD = EdgeInsets.all(md);
  static const EdgeInsets paddingLG = EdgeInsets.all(lg);
  
  // Border Radius
  static const double borderRadiusSM = 4.0;
  static const double borderRadiusMD = 8.0;
  static const double borderRadiusLG = 16.0;
  static final BorderRadius roundedSM = BorderRadius.circular(borderRadiusSM);
  static final BorderRadius roundedMD = BorderRadius.circular(borderRadiusMD);
  static final BorderRadius roundedLG = BorderRadius.circular(borderRadiusLG);
}

// App Assets
class AppAssets {
  static const String logo = 'assets/images/logo.png';
  // Add other asset paths as needed
}

// App Strings
class AppStrings {
  // App Name
  static const String appName = 'Student Timetable';
  
  // Auth Screens
  static const String loginAsStudent = 'Login as Student';
  static const String loginAsTeacher = 'Login as Teacher';
  static const String email = 'Email';
  static const String password = 'Password';
  static const String login = 'Login';
  static const String logout = 'Logout';
  
  // Timetable
  static const String yourSchedule = 'Your Schedule';
  static const String profile = 'Profile';
  static const String notifications = 'Notifications';
  
  // Days of week
  static const List<String> weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
  
  // Class Actions
  static const String cancelClass = 'Cancel Class';
  static const String rescheduleClass = 'Reschedule Class';
  static const String extraClass = 'Extra Class';
}