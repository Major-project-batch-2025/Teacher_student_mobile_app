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

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      role: _parseUserRole(json['role'] ?? 'student'),
      profileImageUrl: json['profileImageUrl'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role.toString().split('.').last,
      'profileImageUrl': profileImageUrl,
    };
  }

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

  factory StudentModel.fromJson(Map<String, dynamic> json) {
    return StudentModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      rollNumber: json['usn'] ?? '',
      department: json['department'] ?? '',
      section: json['section'] ?? '',
      semester: int.tryParse(json['semester']?.toString() ?? '0') ?? 0,
      profileImageUrl: json['profileImageUrl'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': 'student',
      'usn': rollNumber,
      'department': department,
      'section': section,
      'semester': semester,
      'profileImageUrl': profileImageUrl,
    };
  }

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

  factory TeachingAssignmentModel.fromJson(Map<String, dynamic> json) {
    final sections = (json['sections'] as List?)?.map((e) => e.toString()).toList() ?? [];

    return TeachingAssignmentModel(
      subject: json['subject'] ?? '',
      departmentCode: json['departmentCode'] ?? '',
      sections: sections,
      semester: int.tryParse(json['semester']?.toString() ?? '0') ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'subject': subject,
      'departmentCode': departmentCode,
      'sections': sections,
      'semester': semester,
    };
  }

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

  factory TeacherModel.fromJson(Map<String, dynamic> json) {
    final assignments = (json['assignment'] as List?)
        ?.whereType<Map<String, dynamic>>()
        .map((assignment) {
          final sections = (assignment['sections'] as List?)?.map((e) => e.toString()).toList() ?? [];
          return TeachingAssignmentModel(
            subject: assignment['subject'] ?? '',
            departmentCode: json['department'] ?? '',
            sections: sections,
            semester: int.tryParse(assignment['semester']?.toString() ?? '0') ?? 0,
          );
        })
        .toList() ?? [];

    return TeacherModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      employeeId: json['tId'] ?? '',
      department: json['department'] ?? '',
      teachingAssignments: assignments,
      profileImageUrl: json['profileImageUrl'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    final assignmentList = teachingAssignments.map((assignment) => {
      'subject': assignment.subject,
      'sections': assignment.sections,
      'semester': assignment.semester,
    }).toList();

    return {
      'id': id,
      'name': name,
      'email': email,
      'role': 'teacher',
      'tId': employeeId,
      'department': department,
      'assignment': assignmentList,
      'profileImageUrl': profileImageUrl,
    };
  }

  factory TeacherModel.fromEntity(Teacher teacher) {
    return TeacherModel(
      id: teacher.id,
      name: teacher.name,
      email: teacher.email,
      employeeId: teacher.employeeId,
      department: teacher.department,
      teachingAssignments: teacher.teachingAssignments.map((e) =>
        e is TeachingAssignmentModel ? e : TeachingAssignmentModel.fromEntity(e)
      ).toList(),
      profileImageUrl: teacher.profileImageUrl,
    );
  }
}
