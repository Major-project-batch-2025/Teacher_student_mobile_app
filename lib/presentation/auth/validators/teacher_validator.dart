// lib/presentation/auth/validators/teacher_validator.dart
// Purpose: Validator for teacher login form fields (email and password)

class TeacherValidator {
  // Validate email
  bool validateEmail(String email) {
    if (email.isEmpty) return false;
    
    // Use a regular expression to validate email format
    final RegExp emailRegExp = RegExp(
      r'^[a-zA-Z0-9.]+@[a-zA-Z0-9]+\.[a-zA-Z]+',
    );
    return emailRegExp.hasMatch(email);
  }
  
  // Get validation message for email field
  String? getEmailValidationMessage(String email) {
    if (email.isEmpty) {
      return 'Email is required';
    }
    
    if (!validateEmail(email)) {
      return 'Invalid email format';
    }
    
    return null; // Valid email
  }
  
  // Validate password
  bool validatePassword(String password) {
    // Password must be at least 6 characters
    return password.length >= 6;
  }
  
  // Get validation message for password field
  String? getPasswordValidationMessage(String password) {
    if (password.isEmpty) {
      return 'Password is required';
    }
    
    if (password.length < 6) {
      return 'Password must be at least 6 characters';
    }
    
    return null; // Valid password
  }
  
  // Validate password strength (for registration)
  Map<String, bool> checkPasswordStrength(String password) {
    return {
      'length': password.length >= 8,
      'uppercase': password.contains(RegExp(r'[A-Z]')),
      'lowercase': password.contains(RegExp(r'[a-z]')),
      'numbers': password.contains(RegExp(r'[0-9]')),
      'special': password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]')),
    };
  }
  
  // Get password strength score (0-4)
  int getPasswordStrengthScore(String password) {
    final checks = checkPasswordStrength(password);
    return checks.values.where((value) => value).length;
  }
  
  // Get password strength label
  String getPasswordStrengthLabel(String password) {
    final score = getPasswordStrengthScore(password);
    
    if (score <= 1) return 'Weak';
    if (score <= 3) return 'Medium';
    return 'Strong';
  }
}