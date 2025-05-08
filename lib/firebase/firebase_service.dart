import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<Map<String, dynamic>> fetchTimetable(String section, int semester) async {
    try {
      final querySnapshot = await _firestore
          .collection('Original_timetable')
          .where('semester', isEqualTo: semester)
          .get();

      if (querySnapshot.docs.isEmpty) {
        throw Exception('No timetable found for semester $semester.');
      }

      final data = querySnapshot.docs.first.data();

      final sectionKey = 'Section_$section';
      if (data['sections'] == null || data['sections'][sectionKey] == null) {
        throw Exception('Section $section not found in timetable.');
      }

      final schedule = data['sections'][sectionKey]['schedule'];
      if (schedule == null) {
        throw Exception('Schedule not found for Section $section.');
      }

      return Map<String, dynamic>.from(schedule);
    } catch (e) {
      rethrow; // let the UI handle this exception appropriately
    }
  }
}
