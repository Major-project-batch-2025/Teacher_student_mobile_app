// lib/domain/usecases/fetch_timetable.dart
// Purpose: Use case for fetching a timetable for a specific department, section, and semester

import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../core/errors/failures.dart';
import '../entities/timetable.dart';
import '../repositories/schedule_repository.dart';

// Input parameters for the fetch timetable use case
class FetchTimetableParams extends Equatable {
  final String department;
  final String section;
  final int semester;

  const FetchTimetableParams({
    required this.department,
    required this.section,
    required this.semester,
  });

  @override
  List<Object?> get props => [department, section, semester];
}

// Use case for fetching timetable
class FetchTimetable {
  final ScheduleRepository repository;

  FetchTimetable(this.repository);

  // Execute the use case with given parameters
  Future<Either<Failure, Timetable>> execute(FetchTimetableParams params) async {
    return await repository.getTimetable(
      department: params.department,
      section: params.section,
      semester: params.semester,
    );
  }
}