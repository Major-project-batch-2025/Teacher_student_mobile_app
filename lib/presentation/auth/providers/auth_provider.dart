// lib/presentation/auth/providers/auth_provider.dart
// Purpose: Provider for authentication state management

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
  
  // Initialize the auth provider
  AuthProvider() {
    // In a real app, this would check for cached user
    _status = AuthStatus.unauthenticated;
  }
  
  // Student login with USN and DOB
  Future<bool> studentLogin({
  required String usn,
  required String dob,
}) async {
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
    // Query Firestore for student document matching USN and DOB
    final snapshot = await FirebaseFirestore.instance
        .collection('Students')
        .where('usn', isEqualTo: usn.toUpperCase())
        .where('dob', isEqualTo: dob)
        .limit(1)
        .get();

    if (snapshot.docs.isNotEmpty) {
      // Document found, build Student object
      final doc = snapshot.docs.first;
      final data = doc.data();

      _user = Student(
        id: doc.id,
        name: data['name'],
        email: data['email'],
        rollNumber: data['usn'],
        department: data['department'],
        section: data['section'],
        semester: data['semester'],
      );

      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } else {
      // No matching student found
      _errorMessage = 'Invalid USN or date of birth. Please try again.';
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    }
  } catch (e) {
    // Firestore query error
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
  // Validate inputs
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

  // Set authenticating state
  _status = AuthStatus.authenticating;
  _errorMessage = null;
  notifyListeners();

  try {
    // Query Firestore for teacher document matching email and password
    final snapshot = await FirebaseFirestore.instance
        .collection('Teachers')
        .where('email', isEqualTo: email)
        .where('password', isEqualTo: password)
        .limit(1)
        .get();

    if (snapshot.docs.isNotEmpty) {
      // Document found, build Teacher object
      final doc = snapshot.docs.first;
      final data = doc.data();

      // Convert teachingAssignments list
      final List<dynamic> assignmentsRaw = data['teachingAssignments'] ?? [];
      final List<TeachingAssignment> teachingAssignments = assignmentsRaw.map((assignment) {
        return TeachingAssignment(
          subject: assignment['subject'],
          departmentCode: assignment['departmentCode'],
          sections: List<String>.from(assignment['sections'] ?? []),
          semester: int.tryParse(assignment['semester'].toString().trim()) ?? 0,
        );
      }).toList();

      _user = Teacher(
        id: doc.id,
        name: data['name'],
        email: data['email'],
        employeeId: data['employeeId'],
        department: data['department'],
        teachingAssignments: teachingAssignments,
      );

      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } else {
      // No matching teacher found
      _errorMessage = 'Invalid email or password. Please try again.';
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    }
  } catch (e) {
    // Firestore query error
    _errorMessage = 'Authentication failed: ${e.toString()}';
    _status = AuthStatus.error;
    notifyListeners();
    return false;
  }
}
  // Logout
  Future<void> logout() async {
    // In a real app, this would call a Firebase auth service
    // For now, just clear the user
    _status = AuthStatus.unauthenticated;
    _user = null;
    _errorMessage = null;
    notifyListeners();
  }
  
  // Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}