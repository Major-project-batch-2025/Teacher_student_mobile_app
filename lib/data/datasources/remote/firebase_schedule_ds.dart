import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/errors/failures.dart';
import '../../models/class_action_model.dart';
import '../../models/notification_model.dart';
import '../../models/timetable_model.dart';

// Interface
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

// Implementation
class FirebaseScheduleDataSourceImpl implements FirebaseScheduleDataSource {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Future<TimetableModel> getTimetable({
    required String department,
    required String section,
    required int semester,
  }) async {
    try {
      final formattedSection = section;

      print('📥 Fetching timetable for:');
      print('   Department: $department');
      print('   Section: $formattedSection');
      print('   Semester: $semester');

      final snapshot = await _firestore
          .collection('Modified_TimeTable')
          .where('department', isEqualTo: department)
          .where('section', isEqualTo: formattedSection)
          .where('semester', isEqualTo: semester)
          .limit(1)
          .get();

      print('📦 Query result count: ${snapshot.docs.length}');
      if (snapshot.docs.isEmpty) {
        throw const ServerFailure(message: 'No timetable found for this section');
      }

      final doc = snapshot.docs.first;
      final docRef = doc.reference;

      print('📄 Document ID: ${doc.id}');
      print('📄 Raw Data: ${doc.data()}');

      final Map<String, Map<String, ClassSlotModel>> schedule = {};
      const days = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday'];

      for (final day in days) {
        final formattedDay = day[0].toUpperCase() + day.substring(1);
        schedule[formattedDay] = {};

        final daySnapshot = await docRef.collection(day).get();
        if (daySnapshot.docs.isEmpty) continue;

        // We assume only 1 document per day
        final dayDoc = daySnapshot.docs.first;
        final slotMap = dayDoc.data();

        print('📚 [$formattedDay] slots: ${slotMap.length}');

        for (final time in slotMap.keys) {
          final slot = slotMap[time];

          if (slot is Map<String, dynamic>) {
            final course = slot['course'] ?? 'Free';
            final teacher = slot['teacher'] ?? '';
            final classSlot = ClassSlotModel(course: course, teacher: teacher);
            schedule[formattedDay]![time] = classSlot;

            print('🕓 [$formattedDay] $time → $course ($teacher)');
          }
        }
      }

      return TimetableModel(
        department: department,
        section: formattedSection,
        semester: semester,
        schedule: schedule,
      );
    } catch (e) {
      print('❌ Error fetching timetable: $e');
      throw ServerFailure(message: e.toString());
    }
  }

  @override
  Future<List<ClassActionModel>> getClassActions({
    required String timetableId,
  }) async {
    return [];
  }

  @override
  Future<ClassActionModel> applyClassAction({
    required ClassActionModel action,
  }) async {
    throw const ServerFailure(message: 'Firebase class action integration not yet implemented');
  }

  @override
  Future<bool> revertClassAction({
    required String actionId,
  }) async {
    throw const ServerFailure(message: 'Firebase class action revert not yet implemented');
  }

  @override
  Future<List<NotificationModel>> getNotifications({
    required String userId,
    required bool isTeacher,
  }) async {
    return [];
  }

  @override
  Future<bool> markNotificationsAsRead({
    required String userId,
    required List<String> notificationIds,
  }) async {
    return true;
  }

  @override
  Future<String> downloadLogs({
    required String timetableId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    throw const ServerFailure(message: 'Firebase logs integration not yet implemented');
  }
}
