// lib/domain/usecases/fetch_notifications.dart
// Purpose: Use case for fetching notifications for a specific user

import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../core/errors/failures.dart';
import '../repositories/schedule_repository.dart';

// Input parameters for the fetch notifications use case
class FetchNotificationsParams extends Equatable {
  final String userId;
  final bool isTeacher;

  const FetchNotificationsParams({
    required this.userId,
    required this.isTeacher,
  });

  @override
  List<Object?> get props => [userId, isTeacher];
}

// Use case for fetching notifications
class FetchNotifications {
  final ScheduleRepository repository;

  FetchNotifications(this.repository);

  // Execute the use case with given parameters
  Future<Either<Failure, List<dynamic>>> execute(FetchNotificationsParams params) async {
    return await repository.getNotifications(
      userId: params.userId,
      isTeacher: params.isTeacher,
    );
  }
}