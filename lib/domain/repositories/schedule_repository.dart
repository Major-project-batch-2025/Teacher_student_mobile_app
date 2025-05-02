// lib/domain/repositories/schedule_repository.dart
// Purpose: Abstract interface to fetch timetables, post actions, logs, and notifications

import 'package:dartz/dartz.dart';

import '../../core/errors/failures.dart';
import '../entities/class_action.dart';
import '../entities/timetable.dart';

// Abstract repository interface
abstract class ScheduleRepository {
  // Fetch timetable for a specific section and semester
  Future<Either<Failure, Timetable>> getTimetable({
    required String department,
    required String section, 
    required int semester,
  });
  
  // Get active class actions for a specific timetable
  Future<Either<Failure, List<ClassAction>>> getClassActions({
    required String timetableId,
  });
  
  // Apply a class action (cancel, reschedule, extra class)
  Future<Either<Failure, ClassAction>> applyClassAction({
    required ClassAction action,
  });
  
  // Revert a class action
  Future<Either<Failure, bool>> revertClassAction({
    required String actionId,
  });
  
  // Get notifications for a specific user
  Future<Either<Failure, List<dynamic>>> getNotifications({
    required String userId,
    required bool isTeacher,
  });
  
  // Mark notifications as read
  Future<Either<Failure, bool>> markNotificationsAsRead({
    required String userId,
    required List<String> notificationIds,
  });
  
  // Download timetable logs for analysis
  Future<Either<Failure, String>> downloadLogs({
    required String timetableId,
    required DateTime startDate,
    required DateTime endDate,
  });
}