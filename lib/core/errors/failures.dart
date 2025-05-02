// lib/core/errors/failures.dart
// Purpose: Define failure classes for handling various network, server, and data failures

import 'package:equatable/equatable.dart';

// Base failure class that all other failures will extend
abstract class Failure extends Equatable {
  final String message;
  final int? statusCode;

  const Failure({
    required this.message,
    this.statusCode,
  });

  @override
  List<Object?> get props => [message, statusCode];
}

// Network failures
class NetworkFailure extends Failure {
  const NetworkFailure({
    required super.message,
  });
}

// Server failures
class ServerFailure extends Failure {
  const ServerFailure({
    required super.message,
    super.statusCode,
  });
}

// Authentication failures
class AuthFailure extends Failure {
  const AuthFailure({
    required super.message,
  });
}

// Cache failures (for local storage)
class CacheFailure extends Failure {
  const CacheFailure({
    required super.message,
  });
}

// Validation failures (for form validation)
class ValidationFailure extends Failure {
  final Map<String, String> errors;

  const ValidationFailure({
    required super.message,
    required this.errors,
  });

  @override
  List<Object?> get props => [message, statusCode, errors];
}

// Timetable-specific failures
class TimetableFailure extends Failure {
  const TimetableFailure({
    required super.message,
  });
}

// Class action failures
class ClassActionFailure extends Failure {
  const ClassActionFailure({
    required super.message,
  });
}

// Notification failures
class NotificationFailure extends Failure {
  const NotificationFailure({
    required super.message,
  });
}