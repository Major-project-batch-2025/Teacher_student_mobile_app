// lib/data/repositories/schedule_repository_impl.dart
// Purpose: Implementation of the schedule repository with both remote and local data sources

import 'package:dartz/dartz.dart';

import '../../core/errors/failures.dart';
import '../../domain/entities/class_action.dart';
import '../../domain/entities/timetable.dart';
import '../../domain/repositories/schedule_repository.dart';
import '../datasources/local/cache_ds.dart';
import '../datasources/remote/firebase_schedule_ds.dart';
import '../models/class_action_model.dart';

class ScheduleRepositoryImpl implements ScheduleRepository {
  final FirebaseScheduleDataSource remoteDataSource;
  final CacheDataSource localDataSource;

  ScheduleRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
  });

  @override
  Future<Either<Failure, Timetable>> getTimetable({
    required String department,
    required String section,
    required int semester,
  }) async {
    try {
      final remoteTimetable = await remoteDataSource.getTimetable(
        department: department,
        section: section,
        semester: semester,
      );

      await localDataSource.cacheTimetable(timetable: remoteTimetable);

      return Right(
        remoteTimetable.toEntity(
          sectionKey: section,
          department: department,
          lastUpdated: DateTime.now(), // Replace with real timestamp if stored
        ),
      );
    } on ServerFailure catch (_) {
      try {
        final cachedTimetable = await localDataSource.getTimetable(
          section: section,
          semester: semester,
        );

        if (cachedTimetable != null) {
          return Right(
            cachedTimetable.toEntity(
              sectionKey: section,
              department: department,
              lastUpdated: DateTime.now(), // Replace with stored timestamp if needed
            ),
          );
        } else {
          return Left(ServerFailure(message: 'No timetable available for this section and semester'));
        }
      } on CacheFailure catch (cacheFailure) {
        return Left(cacheFailure);
      }
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<ClassAction>>> getClassActions({
    required String timetableId,
  }) async {
    try {
      final remoteActions = await remoteDataSource.getClassActions(timetableId: timetableId);
      await localDataSource.cacheClassActions(actions: remoteActions);
      return Right(remoteActions);
    } on ServerFailure catch (_) {
      try {
        final cachedActions = await localDataSource.getClassActions();
        return Right(cachedActions);
      } on CacheFailure catch (cacheFailure) {
        return Left(cacheFailure);
      }
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, ClassAction>> applyClassAction({
    required ClassAction action,
  }) async {
    try {
      final actionModel = action is ClassActionModel
          ? action
          : ClassActionModel.fromEntity(action);

      final result = await remoteDataSource.applyClassAction(action: actionModel);

      final cachedActions = await localDataSource.getClassActions();
      final updatedActions = List<ClassActionModel>.from(cachedActions);

      final index = updatedActions.indexWhere((a) => a.id == result.id);
      if (index >= 0) {
        updatedActions[index] = result;
      } else {
        updatedActions.add(result);
      }

      await localDataSource.cacheClassActions(actions: updatedActions);

      return Right(result);
    } on ServerFailure catch (failure) {
      return Left(failure);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> revertClassAction({
    required String actionId,
  }) async {
    try {
      final result = await remoteDataSource.revertClassAction(actionId: actionId);

      if (result) {
        final cachedActions = await localDataSource.getClassActions();
        final updatedActions = cachedActions.where((a) => a.id != actionId).toList();
        await localDataSource.cacheClassActions(actions: updatedActions);
      }

      return Right(result);
    } on ServerFailure catch (failure) {
      return Left(failure);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<dynamic>>> getNotifications({
    required String userId,
    required bool isTeacher,
  }) async {
    try {
      final remoteNotifications = await remoteDataSource.getNotifications(
        userId: userId,
        isTeacher: isTeacher,
      );

      await localDataSource.cacheNotifications(notifications: remoteNotifications);
      return Right(remoteNotifications);
    } on ServerFailure catch (_) {
      try {
        final cachedNotifications = await localDataSource.getNotifications();
        return Right(cachedNotifications);
      } on CacheFailure catch (cacheFailure) {
        return Left(cacheFailure);
      }
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> markNotificationsAsRead({
    required String userId,
    required List<String> notificationIds,
  }) async {
    try {
      final result = await remoteDataSource.markNotificationsAsRead(
        userId: userId,
        notificationIds: notificationIds,
      );

      if (result) {
        final cachedNotifications = await localDataSource.getNotifications();
        final updatedNotifications = cachedNotifications.map((notification) {
          if (notificationIds.contains(notification.id)) {
            return notification.markAsRead();
          }
          return notification;
        }).toList();

        await localDataSource.cacheNotifications(notifications: updatedNotifications);
      }

      return Right(result);
    } on ServerFailure catch (failure) {
      return Left(failure);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, String>> downloadLogs({
    required String timetableId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final result = await remoteDataSource.downloadLogs(
        timetableId: timetableId,
        startDate: startDate,
        endDate: endDate,
      );

      return Right(result);
    } on ServerFailure catch (failure) {
      return Left(failure);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }
}
