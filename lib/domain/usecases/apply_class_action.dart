// lib/domain/usecases/apply_class_action.dart
// Purpose: Use case for applying a class action (cancel, reschedule, extra class)

import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../core/errors/failures.dart';
import '../entities/class_action.dart';
import '../repositories/schedule_repository.dart';

// Input parameters for the apply class action use case
class ApplyClassActionParams extends Equatable {
  final ClassAction action;

  const ApplyClassActionParams({
    required this.action,
  });

  @override
  List<Object?> get props => [action];
}

// Use case for applying a class action
class ApplyClassAction {
  final ScheduleRepository repository;

  ApplyClassAction(this.repository);

  // Execute the use case with given parameters
  Future<Either<Failure, ClassAction>> execute(ApplyClassActionParams params) async {
    return await repository.applyClassAction(
      action: params.action,
    );
  }
}