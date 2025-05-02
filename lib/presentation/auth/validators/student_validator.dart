// lib/presentation/auth/validators/student_validator.dart
// Purpose: Validator for student login form fields (USN and DOB)

class StudentValidator {
  // Validate University Serial Number (USN)
  // Format: DEPT followed by 3 digits (e.g., CS001)
  bool validateUSN(String usn) {
    if (usn.isEmpty) return false;
    
    // Use a regular expression to validate the USN format
    // Example formats: CS001, EC045, ME102, etc.
    final RegExp usnRegExp = RegExp(r'^[A-Za-z]{2,4}\d{3}$');
    return usnRegExp.hasMatch(usn);
  }
  
  // Get validation message for USN field
  String? getUSNValidationMessage(String usn) {
    if (usn.isEmpty) {
      return 'USN is required';
    }
    
    if (!validateUSN(usn)) {
      return 'Invalid USN format';
    }
    
    return null; // Valid USN
  }
  
  // Validate Date of Birth
  // Format: DD/MM/YYYY
  bool validateDOB(String dob) {
    if (dob.isEmpty) return false;
    
    // Use a regular expression to validate the DOB format
    final RegExp dobRegExp = RegExp(r'^(0[1-9]|[12][0-9]|3[01])/(0[1-9]|1[0-2])/\d{4}$');
    if (!dobRegExp.hasMatch(dob)) {
      return false;
    }
    
    // Further validate the date is real
    try {
      final parts = dob.split('/');
      final day = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      final year = int.parse(parts[2]);
      
      // Check if date is valid
      final date = DateTime(year, month, day);
      
      // Check that the date is not in the future
      final now = DateTime.now();
      if (date.isAfter(now)) {
        return false;
      }
      
      // Check that the student is at least 16 years old
      final sixteenYearsAgo = DateTime(now.year - 16, now.month, now.day);
      if (date.isAfter(sixteenYearsAgo)) {
        return false;
      }
      
      return true;
    } catch (e) {
      return false;
    }
  }
  
  // Get validation message for DOB field
  String? getDOBValidationMessage(String dob) {
    if (dob.isEmpty) {
      return 'Date of birth is required';
    }
    
    if (!validateDOB(dob)) {
      return 'Invalid date of birth. Use DD/MM/YYYY format';
    }
    
    return null; // Valid DOB
  }
}