// lib/presentation/auth/providers/auth_provider.dart
// Purpose: Provider for authentication state management

import 'package:flutter/material.dart';

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
      // In a real app, this would call a Firebase auth service
      // For now, simulate authentication
      await Future.delayed(const Duration(seconds: 1));
      
      // For testing, validate with simple rules
      if (usn.toUpperCase() == 'CS001' && dob == '01/01/2000') {
        // Successful login
        _user = Student(
          id: 'student_123',
          name: 'John Doe',
          email: 'student@example.com',
          rollNumber: 'CS001',
          department: 'Computer Science',
          section: 'CS-3A',
          semester: 5,
        );
        _status = AuthStatus.authenticated;
        notifyListeners();
        return true;
      } else {
        // Failed login
        _errorMessage = 'Invalid USN or date of birth. Please try again.';
        _status = AuthStatus.unauthenticated;
        notifyListeners();
        return false;
      }
    } catch (e) {
      // Error during login
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
      // In a real app, this would call a Firebase auth service
      // For now, simulate authentication
      await Future.delayed(const Duration(seconds: 1));
      
      // For testing, validate with simple rules
      if (email == 'teacher@example.com' && password == 'password123') {
        // Successful login
        final teachingAssignments = [
          TeachingAssignment(
            subject: 'Mathematics',
            departmentCode: 'MATH',
            sections: ['CS-3A', 'CS-3B'],
            semester: 5,
          ),
          TeachingAssignment(
            subject: 'Calculus',
            departmentCode: 'MATH',
            sections: ['CS-2A'],
            semester: 3,
          ),
        ];
        
        _user = Teacher(
          id: 'teacher_456',
          name: 'Prof. Smith',
          email: 'teacher@example.com',
          employeeId: 'TCHR001',
          department: 'Computer Science',
          teachingAssignments: teachingAssignments,
        );
        _status = AuthStatus.authenticated;
        notifyListeners();
        return true;
      } else {
        // Failed login
        _errorMessage = 'Invalid email or password. Please try again.';
        _status = AuthStatus.unauthenticated;
        notifyListeners();
        return false;
      }
    } catch (e) {
      // Error during login
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