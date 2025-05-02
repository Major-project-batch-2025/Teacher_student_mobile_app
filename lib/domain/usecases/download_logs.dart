// lib/domain/usecases/download_logs.dart
// Purpose: Use case for downloading timetable logs for analysis

import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../core/errors/failures.dart';
import '../repositories/schedule_repository.dart';

// Input parameters for the download logs use case
class DownloadLogsParams extends Equatable {
  final String timetableId;
  final DateTime startDate;
  final DateTime endDate;

  const DownloadLogsParams({
    required this.timetableId,
    required this.startDate,
    required this.endDate,
  });

  @override
  List<Object?> get props => [timetableId, startDate, endDate];
}

// Use case for downloading logs
class DownloadLogs {
  final ScheduleRepository repository;

  DownloadLogs(this.repository);

  // Execute the use case with given parameters
  Future<Either<Failure, String>> execute(DownloadLogsParams params) async {
    return await repository.downloadLogs(
      timetableId: params.timetableId,
      startDate: params.startDate,
      endDate: params.endDate,
    );
  }
}