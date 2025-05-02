// lib/domain/entities/user.dart
// Purpose: Base User entity with common properties for all user types

import 'package:equatable/equatable.dart';

enum UserRole {
  student,
  teacher,
  admin,
}

class User extends Equatable {
  final String id;
  final String name;
  final String email;
  final UserRole role;
  final String profileImageUrl; // Nullable, may not have a profile image

  const User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.profileImageUrl = '',
  });

  // Gets first character of name for profile placeholder
  String get initials {
    if (name.isEmpty) return '';
    return name[0].toUpperCase();
  }

  @override
  List<Object?> get props => [id, name, email, role, profileImageUrl];
  
  // Empty user for initial state
  factory User.empty() => const User(
    id: '',
    name: '',
    email: '',
    role: UserRole.student,
    profileImageUrl: '',
  );
}