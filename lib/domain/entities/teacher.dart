// lib/domain/entities/teacher.dart
// Purpose: Teacher entity extending User with teacher-specific properties

import 'user.dart';

class TeachingAssignment {
  final String subject;
  final String departmentCode;
  final List<String> sections;
  final int semester;
  
  const TeachingAssignment({
    required this.subject,
    required this.departmentCode,
    required this.sections,
    required this.semester,
  });
  
  // For equality comparison
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TeachingAssignment &&
        other.subject == subject &&
        other.departmentCode == departmentCode &&
        other.semester == semester &&
        _listEquals(other.sections, sections);
  }
  
  // Helper for list equality
  bool _listEquals<T>(List<T>? a, List<T>? b) {
    if (a == null) return b == null;
    if (b == null || a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(
        subject,
        departmentCode,
        Object.hashAll(sections),
        semester,
      );
}

class Teacher extends User {
  final String employeeId;
  final String department;
  final List<TeachingAssignment> teachingAssignments;
  
  const Teacher({
    required super.id,
    required super.name,
    required super.email,
    required this.employeeId,
    required this.department,
    required this.teachingAssignments,
    super.profileImageUrl,
  }) : super(role: UserRole.teacher);
  
  @override
  List<Object?> get props => [...super.props, employeeId, department, teachingAssignments];
  
  // Create a copy with updated fields
  Teacher copyWith({
    String? id,
    String? name,
    String? email,
    String? employeeId,
    String? department,
    List<TeachingAssignment>? teachingAssignments,
    String? profileImageUrl,
  }) {
    return Teacher(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      employeeId: employeeId ?? this.employeeId,
      department: department ?? this.department,
      teachingAssignments: teachingAssignments ?? this.teachingAssignments,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
    );
  }
  
  // Get all sections taught by this teacher
  List<String> get allSections {
    final sections = <String>{};
    for (final assignment in teachingAssignments) {
      sections.addAll(assignment.sections);
    }
    return sections.toList();
  }
  
  // Empty teacher for initial state
  factory Teacher.empty() => const Teacher(
    id: '',
    name: '',
    email: '',
    employeeId: '',
    department: '',
    teachingAssignments: [],
    profileImageUrl: '',
  );
}