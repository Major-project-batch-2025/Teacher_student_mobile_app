// lib/domain/entities/student.dart
// Purpose: Student entity extending User with student-specific properties

import 'user.dart';

class Student extends User {
  final String rollNumber;
  final String department;
  final String section;
  final int semester;
  
  const Student({
    required super.id,
    required super.name,
    required super.email,
    required this.rollNumber,
    required this.department,
    required this.section,
    required this.semester,
    super.profileImageUrl,
  }) : super(role: UserRole.student);
  
  @override
  List<Object?> get props => [...super.props, rollNumber, department, section, semester];
  
  // Create a copy with updated fields
  Student copyWith({
    String? id,
    String? name,
    String? email,
    String? rollNumber,
    String? department,
    String? section,
    int? semester,
    String? profileImageUrl,
  }) {
    return Student(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      rollNumber: rollNumber ?? this.rollNumber,
      department: department ?? this.department,
      section: section ?? this.section,
      semester: semester ?? this.semester,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
    );
  }
  
  // Empty student for initial state
  factory Student.empty() => const Student(
    id: '',
    name: '',
    email: '',
    rollNumber: '',
    department: '',
    section: '',
    semester: 0,
    profileImageUrl: '',
  );
}