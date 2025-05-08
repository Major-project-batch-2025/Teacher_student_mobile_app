// lib/data/datasources/remote/firebase_schedule_ds.dart

import '../../../core/errors/failures.dart';
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

// Implementation of Firebase schedule data source
class FirebaseScheduleDataSourceImpl implements FirebaseScheduleDataSource {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Future<TimetableModel> getTimetable({
    required String department,
    required String section,
    required int semester,
  }) async {
    try {
      // First, try to get the timetable from Modified_TimeTable collection
      // If not found there, fall back to Original_TimeTable
      
      // Try Modified_TimeTable first
      final modifiedQuery = await _firestore
          .collection('Modified_TimeTable')
          .where('department', isEqualTo: department)
          .where('section', isEqualTo: section)
          .where('semester', isEqualTo: semester)
          .limit(1)
          .get();
      
      // If modified timetable exists, use it
      if (modifiedQuery.docs.isNotEmpty) {
        return _processTimeTableDocument(modifiedQuery.docs.first, section);
      }
      
      // Otherwise, get from Original_TimeTable
      final originalQuery = await _firestore
          .collection('Original_TimeTable')
          .where('department', isEqualTo: department)
          .where('section', isEqualTo: section)
          .where('semester', isEqualTo: semester)
          .limit(1)
          .get();

      if (originalQuery.docs.isEmpty) {
        throw const ServerFailure(message: 'No timetable found for this section and semester');
      }

      return _processTimeTableDocument(originalQuery.docs.first, section);
    } catch (e) {
      if (e is ServerFailure) rethrow;
      throw ServerFailure(message: 'Failed to load timetable: ${e.toString()}');
    }
  }
  
  // Helper method to process timetable document
  TimetableModel _processTimeTableDocument(DocumentSnapshot doc, String section) {
    final data = doc.data() as Map<String, dynamic>;
    final String sectionKey = 'Section_$section';
    
    // Create a standard format expected by TimetableModel
    // This will hold all days and their time slots
    final Map<String, Map<String, Map<String, ClassSlotModel>>> sections = {};
    
    // Initialize the section's schedule
    final Map<String, Map<String, ClassSlotModel>> schedule = {};
    
    // Loop through each day in the subcollection structure
    final days = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday'];
    for (final day in days) {
      if (data[day] == null || !(data[day] is Map)) continue;
      
      final dayData = data[day] as Map<String, dynamic>;
      
      // Process each time slot for this day
      dayData.forEach((timeSlotKey, slotData) {
        if (slotData is Map<String, dynamic>) {
          // Format the day name properly for our model (first letter capitalized)
          final String dayName = day[0].toUpperCase() + day.substring(1);
          
          // Create class slot from the data
          final classSlot = ClassSlotModel(
            course: slotData['course'] as String? ?? 'Free',
            teacher: slotData['teacher'] as String? ?? '',
          );
          
          // Make sure this time slot exists in our schedule
          if (!schedule.containsKey(timeSlotKey)) {
            schedule[timeSlotKey] = {};
          }
          
          // Add this day's class to the time slot
          schedule[timeSlotKey]![dayName] = classSlot;
        }
      });
    }
    
    // Add the section's schedule to our sections object
    sections[sectionKey] = schedule;
    
    // Create final timetable structure
    final timetableJson = {
      'numberOfSections': 1, // Default value
      'semester': data['semester'] ?? 0,
      'sections': {
        sectionKey: {'schedule': schedule}
      },
    };

    return TimetableModel.fromJson(timetableJson);
  }

  @override
  Future<List<ClassActionModel>> getClassActions({
    required String timetableId,
  }) async {
    // Implement with actual Firestore logic when needed
    // For now, return empty list to avoid errors
    return [];
  }
  
  @override
  Future<ClassActionModel> applyClassAction({
    required ClassActionModel action,
  }) async {
    // Implement with actual Firestore logic when needed
    throw const ServerFailure(message: 'Firebase class action integration not yet implemented');
  }
  
  @override
  Future<bool> revertClassAction({
    required String actionId,
  }) async {
    // Implement with actual Firestore logic when needed
    throw const ServerFailure(message: 'Firebase class action revert not yet implemented');
  }
  
  @override
  Future<List<NotificationModel>> getNotifications({
    required String userId,
    required bool isTeacher,
  }) async {
    // Implement with actual Firestore logic when needed
    // For now, return empty list to avoid errors
    return [];
  }
  
  @override
  Future<bool> markNotificationsAsRead({
    required String userId,
    required List<String> notificationIds,
  }) async {
    // Implement with actual Firestore logic when needed
    return true;
  }
  
  @override
  Future<String> downloadLogs({
    required String timetableId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    // Implement with actual Firestore logic when needed
    throw const ServerFailure(message: 'Firebase logs integration not yet implemented');
  }
}