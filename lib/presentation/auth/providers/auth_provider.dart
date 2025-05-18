// lib/presentation/auth/providers/auth_provider.dart
// Purpose: Provider for authentication state management

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:timetable_app/firebase/notification_service.dart';
import '../../../domain/entities/student.dart';
import '../../../domain/entities/teacher.dart';
import '../../../domain/entities/user.dart';
import '../validators/student_validator.dart';
import '../validators/teacher_validator.dart';

enum AuthStatus {
  initial,
  authenticating,
  authenticated,
  unauthenticated,
  error,
}

class AuthProvider extends ChangeNotifier {
  // Current auth status
  AuthStatus _status = AuthStatus.initial;
  AuthStatus get status => _status;

  // Current user (either Student or Teacher)
  User? _user;
  User? get user => _user;

  // Error message
  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  // Student validators
  final StudentValidator _studentValidator = StudentValidator();
  StudentValidator get studentValidator => _studentValidator;

  // Teacher validators
  final TeacherValidator _teacherValidator = TeacherValidator();
  TeacherValidator get teacherValidator => _teacherValidator;

  // Is currently a student or teacher
  bool get isStudent => _user is Student;
  bool get isTeacher => _user is Teacher;

  // Check if logged in
  bool get isLoggedIn => _status == AuthStatus.authenticated && _user != null;

  // Additional fields to access section and semester for timetable
  String? _studentSection;
  int? _studentSemester;

  String get studentSection => _studentSection ?? '';
  int get studentSemester => _studentSemester ?? 0;

  // Initialize the auth provider
  AuthProvider() {
    _status = AuthStatus.unauthenticated;
  }

  // Student login with USN and DOB
  Future<bool> studentLogin({required String usn, required String dob}) async {
    // Validate inputs
    if (!_studentValidator.validateUSN(usn)) {
      _errorMessage = 'Invalid USN format. Please use the correct format.';
      notifyListeners();
      return false;
    }

    if (!_studentValidator.validateDOB(dob)) {
      _errorMessage = 'Invalid date of birth format. Please use DD/MM/YYYY.';
      notifyListeners();
      return false;
    }

    // Set authenticating state
    _status = AuthStatus.authenticating;
    _errorMessage = null;
    notifyListeners();

    try {
      // Get FCM token first
      final fcmToken = await NotificationService.getToken();
      if (fcmToken == null) {
        throw Exception('Failed to get FCM token');
      }

      // Query Firestore for student document matching USN and DOB
      final snapshot =
          await FirebaseFirestore.instance
              .collection(
                'Students',
              ) // Note: Using 'Students' collection instead of 'Student'
              .where('usn', isEqualTo: usn.toUpperCase())
              .where('dob', isEqualTo: dob)
              .get();

      if (snapshot.docs.isNotEmpty) {
        // Document found, build Student object
        final doc = snapshot.docs.first;
        final data = doc.data();

        // Update the document with the new tokenId
        await FirebaseFirestore.instance
            .collection('Students')
            .doc(doc.id)
            .update({'tokenId': fcmToken});

        // Extract section and semester with careful null handling
        final section = data['section']?.toString() ?? 'A';
        final semester = int.tryParse(data['semester']?.toString() ?? '1') ?? 1;

        _user = Student(
          id: doc.id,
          name: data['name']?.toString() ?? 'Student',
          email: data['email']?.toString() ?? '',
          rollNumber:
              data['usn']?.toString() ??
              '', // Note: Using 'usn' field instead of 'rollNumber'
          department: data['department']?.toString() ?? 'Unknown',
          section: section,
          semester: semester,
        );

        // Save section and semester
        _studentSection = section;
        _studentSemester = semester;

        _status = AuthStatus.authenticated;
        notifyListeners();
        return true;
      } else {
        _errorMessage = 'Invalid USN or date of birth. Please try again.';
        _status = AuthStatus.unauthenticated;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Authentication failed: ${e.toString()}';
      _status = AuthStatus.error;
      notifyListeners();
      return false;
    }
  }

  // Teacher login with email and password
  Future<bool> teacherLogin({
    required String email,
    required String password,
  }) async {
    if (!_teacherValidator.validateEmail(email)) {
      _errorMessage = 'Invalid email format.';
      notifyListeners();
      return false;
    }

    if (!_teacherValidator.validatePassword(password)) {
      _errorMessage = 'Password must be at least 6 characters.';
      notifyListeners();
      return false;
    }

    _status = AuthStatus.authenticating;
    _errorMessage = null;
    notifyListeners();

    try {
      // Get FCM token
      final fcmToken = await NotificationService.getToken();
      if (fcmToken == null) {
        throw Exception('Failed to get FCM token');
      }

      // Query Firestore for teacher document matching email and password
      final snapshot =
          await FirebaseFirestore.instance
              .collection(
                'Teachers',
              ) // Note: Using 'Teachers' collection instead of 'Teacher'
              .where('email', isEqualTo: email)
              .where('password', isEqualTo: password)
              .limit(1)
              .get();

      if (snapshot.docs.isNotEmpty) {
        final doc = snapshot.docs.first;

        // Update the document with the new tokenId
        await FirebaseFirestore.instance
            .collection('Teachers')
            .doc(doc.id)
            .update({'tokenId': fcmToken});

        final data = doc.data();

        // Parse assignment data - this matches the structure shown in your Firebase screenshot
        final List<TeachingAssignment> teachingAssignments = [];

        if (data['assignment'] != null) {
          // Note: Using 'assignment' field instead of 'teachingAssignments'
          // Handle assignments as they appear in your database
          if (data['assignment'] is List) {
            final assignmentList = data['assignment'] as List;

            for (final item in assignmentList) {
              if (item is Map<String, dynamic>) {
                // Extract sections as a list
                List<String> sections = [];
                if (item['sections'] is List) {
                  sections = List<String>.from(item['sections']);
                }

                teachingAssignments.add(
                  TeachingAssignment(
                    subject: item['subject']?.toString() ?? 'Unknown',
                    departmentCode: data['department']?.toString() ?? 'Unknown',
                    sections: sections,
                    semester:
                        item['semester'] != null
                            ? int.tryParse(item['semester'].toString()) ?? 0
                            : 0,
                  ),
                );
              }
            }
          }
        }

        // Create teacher model with careful null handling for all fields
        _user = Teacher(
          id: doc.id,
          name: data['name']?.toString() ?? 'Unknown',
          email: data['email']?.toString() ?? '',
          employeeId:
              data['tId']?.toString() ??
              '', // Note: Using 'tId' field instead of 'employeeId'
          department: data['department']?.toString() ?? 'Unknown',
          teachingAssignments: teachingAssignments,
        );

        _status = AuthStatus.authenticated;
        notifyListeners();
        return true;
      } else {
        _errorMessage = 'Invalid email or password. Please try again.';
        _status = AuthStatus.unauthenticated;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Authentication failed: ${e.toString()}';
      _status = AuthStatus.error;
      notifyListeners();
      return false;
    }
  }

  // Modify logout to remove FCM token
  Future<void> logout() async {
    _status = AuthStatus.unauthenticated;
    _user = null;
    _studentSection = null;
    _studentSemester = null;
    _errorMessage = null;
    notifyListeners();
  }

  // Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
