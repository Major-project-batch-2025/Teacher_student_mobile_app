// lib/data/datasources/remote/firebase_schedule_ds.dart
// Purpose: Remote data source implementation using Firebase

import '../../../core/errors/failures.dart';
// import '../../../domain/entities/class_action.dart';
import '../../models/class_action_model.dart';
import '../../models/notification_model.dart';
import '../../models/timetable_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Firebase schedule data source interface
abstract class FirebaseScheduleDataSource {
  Future<TimetableModel> getTimetable({
    required String department,
    required String section, 
    required int semester,
  });
  
  Future<List<ClassActionModel>> getClassActions({
    required String timetableId,
  });
  
  Future<ClassActionModel> applyClassAction({
    required ClassActionModel action,
  });
  
  Future<bool> revertClassAction({
    required String actionId,
  });
  
  Future<List<NotificationModel>> getNotifications({
    required String userId,
    required bool isTeacher,
  });
  
  Future<bool> markNotificationsAsRead({
    required String userId,
    required List<String> notificationIds,
  });
  
  Future<String> downloadLogs({
    required String timetableId,
    required DateTime startDate,
    required DateTime endDate,
  });
}

// Implementation will be filled by the backend
class FirebaseScheduleDataSourceImpl implements FirebaseScheduleDataSource {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
Future<TimetableModel> getTimetable({
  required String department,
  required String section,
  required int semester,
}) async {
  try {
    // 🔍 1. Get first document from Original_TimeTable
    final snapshot = await _firestore
        .collection('Original_TimeTable')
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) {
      throw const ServerFailure(message: 'No timetable found');
    }

    final doc = snapshot.docs.first;
    final data = doc.data();

    // 🔍 2. Extract section-specific data
    final sectionKey = 'Section_$section'; // Ensure proper casing
    final sectionData = data['sections'][sectionKey];

    if (sectionData == null) {
      throw ServerFailure(message: 'Section $sectionKey not found');
    }

    final timetableJson = {
      'numberOfSections': data['numberOfSections'],
      'semester': data['semester'],
      'sections': {
        sectionKey: sectionData,
      },
    };

    return TimetableModel.fromJson(timetableJson);
  } catch (e) {
    throw ServerFailure(message: 'Failed to load timetable. ${e.toString()}');
  }
}

  @override
  Future<List<ClassActionModel>> getClassActions({
    required String timetableId,
  }) async {
    // Mock implementation for now
    throw const ServerFailure(message: 'Firebase integration not yet implemented');
  }
  
  @override
  Future<ClassActionModel> applyClassAction({
    required ClassActionModel action,
  }) async {
    // Mock implementation for now
    throw const ServerFailure(message: 'Firebase integration not yet implemented');
  }
  
  @override
  Future<bool> revertClassAction({
    required String actionId,
  }) async {
    // Mock implementation for now
    throw const ServerFailure(message: 'Firebase integration not yet implemented');
  }
  
  @override
  Future<List<NotificationModel>> getNotifications({
    required String userId,
    required bool isTeacher,
  }) async {
    // Mock implementation for now
    throw const ServerFailure(message: 'Firebase integration not yet implemented');
  }
  
  @override
  Future<bool> markNotificationsAsRead({
    required String userId,
    required List<String> notificationIds,
  }) async {
    // Mock implementation for now
    throw const ServerFailure(message: 'Firebase integration not yet implemented');
  }
  
  @override
  Future<String> downloadLogs({
    required String timetableId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    // Mock implementation for now
    throw const ServerFailure(message: 'Firebase integration not yet implemented');
  }
}