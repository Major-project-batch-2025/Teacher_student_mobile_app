// lib/data/models/user_model.dart
// Purpose: Data models for User, Student, and Teacher with JSON serialization

import '../../domain/entities/student.dart';
import '../../domain/entities/teacher.dart';
import '../../domain/entities/user.dart';

class UserModel extends User {
  const UserModel({
    required super.id,
    required super.name,
    required super.email,
    required super.role,
    super.profileImageUrl,
  });

  // Factory constructor to create a UserModel from JSON
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      role: _parseUserRole(json['role']),
      profileImageUrl: json['profileImageUrl'] ?? '',
    );
  }

  // Convert UserModel to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role.toString().split('.').last,
      'profileImageUrl': profileImageUrl,
    };
  }

  // Helper to parse UserRole from string
  static UserRole _parseUserRole(String roleStr) {
    switch (roleStr.toLowerCase()) {
      case 'student':
        return UserRole.student;
      case 'teacher':
        return UserRole.teacher;
      case 'admin':
        return UserRole.admin;
      default:
        return UserRole.student;
    }
  }
  
  // Create UserModel from User entity
  factory UserModel.fromEntity(User user) {
    return UserModel(
      id: user.id,
      name: user.name,
      email: user.email,
      role: user.role,
      profileImageUrl: user.profileImageUrl,
    );
  }
}

class StudentModel extends Student {
  const StudentModel({
    required super.id,
    required super.name,
    required super.email,
    required super.rollNumber,
    required super.department,
    required super.section,
    required super.semester,
    super.profileImageUrl,
  });

  // Factory constructor to create a StudentModel from JSON
  factory StudentModel.fromJson(Map<String, dynamic> json) {
    return StudentModel(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      rollNumber: json['rollNumber'],
      department: json['department'],
      section: json['section'],
      semester: json['semester'],
      profileImageUrl: json['profileImageUrl'] ?? '',
    );
  }

  // Convert StudentModel to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': 'student',
      'rollNumber': rollNumber,
      'department': department,
      'section': section,
      'semester': semester,
      'profileImageUrl': profileImageUrl,
    };
  }
  
  // Create StudentModel from Student entity
  factory StudentModel.fromEntity(Student student) {
    return StudentModel(
      id: student.id,
      name: student.name,
      email: student.email,
      rollNumber: student.rollNumber,
      department: student.department,
      section: student.section,
      semester: student.semester,
      profileImageUrl: student.profileImageUrl,
    );
  }
}

class TeachingAssignmentModel extends TeachingAssignment {
  const TeachingAssignmentModel({
    required super.subject,
    required super.departmentCode,
    required super.sections,
    required super.semester,
  });

  // Factory constructor to create a TeachingAssignmentModel from JSON
  factory TeachingAssignmentModel.fromJson(Map<String, dynamic> json) {
    return TeachingAssignmentModel(
      subject: json['subject'],
      departmentCode: json['departmentCode'],
      sections: List<String>.from(json['sections']),
      semester: json['semester'],
    );
  }

  // Convert TeachingAssignmentModel to JSON
  Map<String, dynamic> toJson() {
    return {
      'subject': subject,
      'departmentCode': departmentCode,
      'sections': sections,
      'semester': semester,
    };
  }
  
  // Create TeachingAssignmentModel from TeachingAssignment entity
  factory TeachingAssignmentModel.fromEntity(TeachingAssignment assignment) {
    return TeachingAssignmentModel(
      subject: assignment.subject,
      departmentCode: assignment.departmentCode,
      sections: assignment.sections,
      semester: assignment.semester,
    );
  }
}

class TeacherModel extends Teacher {
  const TeacherModel({
    required super.id,
    required super.name,
    required super.email,
    required super.employeeId,
    required super.department,
    required super.teachingAssignments,
    super.profileImageUrl,
  });

  // Factory constructor to create a TeacherModel from JSON
  factory TeacherModel.fromJson(Map<String, dynamic> json) {
    final assignmentsList = (json['teachingAssignments'] as List)
        .map((assignmentJson) => TeachingAssignmentModel.fromJson(assignmentJson))
        .toList();

    return TeacherModel(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      employeeId: json['employeeId'],
      department: json['department'],
      teachingAssignments: assignmentsList,
      profileImageUrl: json['profileImageUrl'] ?? '',
    );
  }

  // Convert TeacherModel to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': 'teacher',
      'employeeId': employeeId,
      'department': department,
      'teachingAssignments': teachingAssignments.map((assignment) => 
        (assignment is TeachingAssignmentModel)
            ? assignment.toJson()
            : TeachingAssignmentModel.fromEntity(assignment).toJson()
      ).toList(),
      'profileImageUrl': profileImageUrl,
    };
  }
  
  // Create TeacherModel from Teacher entity
  factory TeacherModel.fromEntity(Teacher teacher) {
    return TeacherModel(
      id: teacher.id,
      name: teacher.name,
      email: teacher.email,
      employeeId: teacher.employeeId,
      department: teacher.department,
      teachingAssignments: teacher.teachingAssignments.map((assignment) => 
        (assignment is TeachingAssignmentModel) 
            ? assignment 
            : TeachingAssignmentModel.fromEntity(assignment)
      ).toList(),
      profileImageUrl: teacher.profileImageUrl,
    );
  }
}