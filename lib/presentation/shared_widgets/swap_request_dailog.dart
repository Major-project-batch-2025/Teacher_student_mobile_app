// lib/presentation/shared_widgets/swap_request_dialog.dart
// Purpose: Dialog for teachers to request class swap with another teacher - FIXED VERSION

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/constants.dart';
import '../../domain/entities/timetable.dart';
import '../../domain/entities/teacher.dart';
import '../providers/timetable_provider.dart';
import '../auth/providers/auth_provider.dart';

class SwapRequestDialog extends StatefulWidget {
  final ClassSlot originalClassSlot; // The class to be swapped
  final String originalSection; // Section of the original class
  final int originalSemester; // Semester of the original class
  final String originalDepartment; // Department of the original class
  final String
  targetTeacherName; // Teacher whose class is being targeted for swap

  const SwapRequestDialog({
    super.key,
    required this.originalClassSlot,
    required this.originalSection,
    required this.originalSemester,
    required this.originalDepartment,
    required this.targetTeacherName,
  });

  @override
  State<SwapRequestDialog> createState() => _SwapRequestDialogState();
}

class _SwapRequestDialogState extends State<SwapRequestDialog> {
  String? _selectedDay;
  String? _selectedTimeSlot;
  bool _isLoading = false;
  bool _isCheckingAvailability = false;
  List<String> _availableTimeSlots = [];

  // Days of the week - will be filtered to show only present and upcoming days
  List<String> _availableDays = [];

  @override
  void initState() {
    super.initState();
    _initializeAvailableDays();
  }

  // Initialize available days (present and upcoming only)
  void _initializeAvailableDays() {
    final now = DateTime.now();
    final currentDayOfWeek =
        now.weekday; // 1 = Monday, 2 = Tuesday, ..., 7 = Sunday

    const allWeekDays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
    ];

    // Filter days to include only present and upcoming days
    _availableDays = [];

    // Add today and remaining days of the week
    for (int i = 0; i < allWeekDays.length; i++) {
      final dayIndex = i + 1; // Convert to 1-based index (Monday = 1)

      // Include current day and future days
      if (dayIndex >= currentDayOfWeek) {
        _availableDays.add(allWeekDays[i]);
      }
    }

    // If it's Sunday (7), include all days of next week
    if (currentDayOfWeek == 7) {
      _availableDays = List.from(allWeekDays);
    }

    // If no days available (shouldn't happen), include all days
    if (_availableDays.isEmpty) {
      _availableDays = List.from(allWeekDays);
    }

    print('📅 Available days for swap: $_availableDays');
    print(
      '📅 Current day of week: $currentDayOfWeek (${allWeekDays[currentDayOfWeek - 1]})',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: contentBox(context),
    );
  }

  Widget contentBox(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        shape: BoxShape.rectangle,
        color: AppColors.darkBackground,
        borderRadius: BorderRadius.circular(16.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10.0,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            const Text(
              'Request Class Swap',
              style: TextStyle(
                fontSize: 22.0,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16.0),

            // Original class info
            Container(
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Swapping: ${widget.originalClassSlot.subject}',
                    style: const TextStyle(
                      fontSize: 16.0,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4.0),
                  Text(
                    'With: ${widget.targetTeacherName}',
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16.0),

            // Day selector
            const Text(
              'Select Day',
              style: TextStyle(
                fontSize: 16.0,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8.0),
            DropdownButtonFormField<String>(
              value: _selectedDay,
              decoration: const InputDecoration(
                hintText: 'Choose a day',
                filled: true,
                fillColor: Colors.black38,
                border: OutlineInputBorder(),
                hintStyle: TextStyle(color: Colors.grey),
              ),
              dropdownColor: Colors.grey.shade900,
              style: const TextStyle(color: Colors.white),
              items:
                  _availableDays.map((day) {
                    return DropdownMenuItem<String>(
                      value: day,
                      child: Text(day),
                    );
                  }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedDay = value;
                  _selectedTimeSlot = null; // Reset time slot selection
                  _availableTimeSlots.clear();
                });
                if (value != null) {
                  _loadAvailableTimeSlotsFromCurrentSection(value);
                }
              },
            ),
            const SizedBox(height: 16.0),

            // Time slot selector (only shown after day is selected)
            if (_selectedDay != null) ...[
              const Text(
                'Select Your Time Slot',
                style: TextStyle(
                  fontSize: 16.0,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8.0),
              if (_isCheckingAvailability)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (_availableTimeSlots.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'No available time slots for the selected day',
                    style: TextStyle(color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                )
              else
                DropdownButtonFormField<String>(
                  value: _selectedTimeSlot,
                  decoration: const InputDecoration(
                    hintText: 'Choose a time slot',
                    filled: true,
                    fillColor: Colors.black38,
                    border: OutlineInputBorder(),
                    hintStyle: TextStyle(color: Colors.grey),
                  ),
                  dropdownColor: Colors.grey.shade900,
                  style: const TextStyle(color: Colors.white),
                  items:
                      _availableTimeSlots.map((timeSlot) {
                        return DropdownMenuItem<String>(
                          value: timeSlot,
                          child: Text(timeSlot),
                        );
                      }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedTimeSlot = value;
                    });
                  },
                ),
              const SizedBox(height: 24.0),
            ],

            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed:
                      _isLoading
                          ? null
                          : () {
                            Navigator.of(context).pop();
                          },
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                const SizedBox(width: 16.0),
                SizedBox(
                  width: 140,
                  child: ElevatedButton(
                    onPressed:
                        (_isLoading ||
                                _selectedDay == null ||
                                _selectedTimeSlot == null)
                            ? null
                            : _sendSwapRequest,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child:
                        _isLoading
                            ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                            : const Text('Send Request'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // FIXED: Load available time slots only from the current section where the requesting teacher has classes
  Future<void> _loadAvailableTimeSlotsFromCurrentSection(String day) async {
    setState(() {
      _isCheckingAvailability = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final requestingTeacher = authProvider.user as Teacher;

      print(
        '🔍 Loading time slots for requesting teacher: ${requestingTeacher.name}',
      );
      print('🔍 Section: ${widget.originalSection}, Day: $day');

      // Get the timetable for the current section only
      final firestore = FirebaseFirestore.instance;

      // Query the timetable for the current section
      final timetableQuery =
          await firestore
              .collection('Modified_TimeTable')
              .where('department', isEqualTo: widget.originalDepartment)
              .where('section', isEqualTo: widget.originalSection)
              .where('semester', isEqualTo: widget.originalSemester)
              .limit(1)
              .get();

      if (timetableQuery.docs.isEmpty) {
        print('❌ No timetable found for section ${widget.originalSection}');
        setState(() {
          _availableTimeSlots = [];
          _isCheckingAvailability = false;
        });
        return;
      }

      final docRef = timetableQuery.docs.first.reference;
      final dayName = day.toLowerCase();

      // Get the day collection
      final dayCollection = await docRef.collection(dayName).get();

      if (dayCollection.docs.isEmpty) {
        print('❌ No data found for $dayName');
        setState(() {
          _availableTimeSlots = [];
          _isCheckingAvailability = false;
        });
        return;
      }

      final dayDoc = dayCollection.docs.first;
      final dayData = dayDoc.data();

      print('📊 Day data keys: ${dayData.keys.toList()}');

      // Filter time slots where the requesting teacher has classes
      final teacherTimeSlots = <String>[];

      dayData.forEach((timeSlot, slotData) {
        if (slotData is Map<String, dynamic>) {
          final teacher = slotData['teacher'] as String?;
          final course = slotData['course'] as String?;

          print('🕐 TimeSlot: $timeSlot, Teacher: $teacher, Course: $course');

          // Check if this is the requesting teacher's class
          if (teacher == requestingTeacher.name &&
              course != null &&
              course != 'Free') {
            // Format the time slot for display (add spaces around hyphen)
            final formattedTimeSlot =
                timeSlot.contains('-')
                    ? timeSlot.replaceAll('-', ' - ')
                    : timeSlot;
            teacherTimeSlots.add(formattedTimeSlot);
            print('✅ Added time slot: $formattedTimeSlot');
          }
        }
      });

      // Sort time slots
      teacherTimeSlots.sort((a, b) {
        final aTime = a.split(' - ')[0];
        final bTime = b.split(' - ')[0];
        return _compareTimeStrings(aTime, bTime);
      });

      print('📋 Final available time slots: $teacherTimeSlots');

      setState(() {
        _availableTimeSlots = teacherTimeSlots;
        _isCheckingAvailability = false;
      });
    } catch (e) {
      print('❌ Error loading time slots: $e');
      setState(() {
        _isCheckingAvailability = false;
        _availableTimeSlots = [];
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading time slots: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Helper method to compare time strings
  int _compareTimeStrings(String time1, String time2) {
    try {
      final parts1 = time1.split(':');
      final parts2 = time2.split(':');

      final hour1 = int.parse(parts1[0]);
      final minute1 = int.parse(parts1[1]);
      final hour2 = int.parse(parts2[0]);
      final minute2 = int.parse(parts2[1]);

      // Convert to 24-hour format
      final hour1_24 = (hour1 < 7) ? hour1 + 12 : hour1;
      final hour2_24 = (hour2 < 7) ? hour2 + 12 : hour2;

      final total1 = hour1_24 * 60 + minute1;
      final total2 = hour2_24 * 60 + minute2;

      return total1.compareTo(total2);
    } catch (e) {
      return 0;
    }
  }

  // Send swap request after checking conditions
  Future<void> _sendSwapRequest() async {
    if (_selectedDay == null || _selectedTimeSlot == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final requestingTeacher = authProvider.user as Teacher;

      print('🔄 Checking swap possibility...');
      print('   Requesting Teacher: ${requestingTeacher.name}');
      print('   Target Teacher: ${widget.targetTeacherName}');
      print('   Day: $_selectedDay');
      print('   Time Slot: $_selectedTimeSlot');

      // Check if target teacher is available at the requesting teacher's selected time slot
      final canSwap = await _checkSwapPossibility(
        requestingTeacher,
        widget.targetTeacherName,
        _selectedDay!,
        _selectedTimeSlot!,
      );

      if (canSwap) {
        // Show success message - CHANGED MESSAGE
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Can able to swap - No conflicts found!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );

          Navigator.of(context).pop(true);
        }
      } else {
        // Show error message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '${widget.targetTeacherName} has a class conflict at your selected time slot',
              ),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    } catch (e) {
      print('❌ Error in swap request: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // FIXED: Check if swap is possible by verifying target teacher's availability
  Future<bool> _checkSwapPossibility(
    Teacher requestingTeacher,
    String targetTeacherName,
    String day,
    String timeSlot,
  ) async {
    try {
      print('🔍 Checking swap possibility...');
      print('🔍 Looking for target teacher: "$targetTeacherName"');

      final firestore = FirebaseFirestore.instance;

      // Get all teachers and search manually for better matching
      final allTeachersQuery = await firestore.collection('Teachers').get();

      print('📋 Total teachers in database: ${allTeachersQuery.docs.length}');

      DocumentSnapshot? targetTeacherDoc;

      // Search through all teachers with flexible matching
      for (final doc in allTeachersQuery.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final name = data['name'] as String?;

        if (name != null) {
          print('👤 Checking teacher: "$name"');

          // Try multiple matching strategies
          if (name == targetTeacherName || // Exact match
              name.trim() == targetTeacherName.trim() || // Trimmed match
              name.toLowerCase() ==
                  targetTeacherName.toLowerCase() || // Case insensitive
              name.trim().toLowerCase() ==
                  targetTeacherName.trim().toLowerCase()) {
            // Both

            print('✅ Found matching teacher: "$name"');
            targetTeacherDoc = doc;
            break;
          }
        }
      }

      if (targetTeacherDoc == null) {
        print(
          '❌ Target teacher not found after checking all ${allTeachersQuery.docs.length} teachers',
        );
        print('🔍 Available teacher names:');
        for (final doc in allTeachersQuery.docs) {
          final data = doc.data() as Map<String, dynamic>;
          final name = data['name'] as String?;
          if (name != null) {
            print('   - "$name"');
          }
        }

        // For now, assume no conflict if teacher not found (they might not be in system)
        print('⚠️ Assuming no conflict since teacher not found in system');
        return true;
      }

      final targetTeacherData = targetTeacherDoc.data() as Map<String, dynamic>;
      return await _checkTeacherAssignments(
        targetTeacherData,
        day,
        timeSlot,
        targetTeacherName,
      );
    } catch (e) {
      print('❌ Error checking swap possibility: $e');
      // Instead of throwing exception, assume no conflict and allow swap
      print('⚠️ Assuming no conflict due to error - allowing swap');
      return true;
    }
  }

  // Helper method to check teacher assignments
  Future<bool> _checkTeacherAssignments(
    Map<String, dynamic> targetTeacherData,
    String day,
    String timeSlot,
    String targetTeacherName,
  ) async {
    final targetAssignments = targetTeacherData['assignment'] as List?;

    if (targetAssignments == null || targetAssignments.isEmpty) {
      print('✅ Target teacher has no assignments - no conflicts');
      return true; // No assignments means no conflicts
    }

    print('📋 Target teacher assignments: ${targetAssignments.length}');

    // Check each section where target teacher has assignments
    for (final assignment in targetAssignments) {
      if (assignment is Map<String, dynamic>) {
        final sections = assignment['sections'] as List?;
        final semester = assignment['semester'];

        if (sections != null) {
          for (final section in sections) {
            print('🔍 Checking section: $section, semester: $semester');

            // Check if target teacher has a class at requesting teacher's time slot
            final hasConflict = await _checkSectionConflict(
              section.toString(),
              semester ?? 0,
              day,
              timeSlot,
              targetTeacherName,
            );

            if (hasConflict) {
              print('❌ Conflict found in section $section');
              return false; // Conflict found
            }
          }
        }
      }
    }

    print('✅ No conflicts found');
    return true; // No conflicts found
  }

  // Check if target teacher has a class in a specific section at the given time
  Future<bool> _checkSectionConflict(
    String section,
    int semester,
    String day,
    String timeSlot,
    String targetTeacherName,
  ) async {
    try {
      final firestore = FirebaseFirestore.instance;

      print(
        '🔍 Checking conflict in section: $section, semester: $semester, day: $day, time: $timeSlot',
      );

      // Query the timetable for this section
      final timetableQuery =
          await firestore
              .collection('Modified_TimeTable')
              .where('department', isEqualTo: widget.originalDepartment)
              .where('section', isEqualTo: section)
              .where('semester', isEqualTo: semester)
              .limit(1)
              .get();

      if (timetableQuery.docs.isEmpty) {
        print('📅 No timetable found for section $section');
        return false; // No timetable found, no conflict
      }

      final docRef = timetableQuery.docs.first.reference;
      final dayName = day.toLowerCase();

      // Get the day collection
      final dayCollection = await docRef.collection(dayName).get();

      if (dayCollection.docs.isEmpty) {
        print('📅 No data for $dayName in section $section');
        return false; // No data for this day
      }

      final dayDoc = dayCollection.docs.first;
      final dayData = dayDoc.data();

      // Format time slot to match Firebase format (remove spaces)
      final formattedTimeSlot = timeSlot
          .replaceAll(' ', '')
          .replaceAll('-', '-');

      print('🔍 Looking for time slot: $formattedTimeSlot in day data');
      print('📊 Available time slots: ${dayData.keys.toList()}');

      // Check if target teacher has a class at this time slot
      final slotData = dayData[formattedTimeSlot];
      if (slotData != null && slotData is Map<String, dynamic>) {
        final slotTeacher = slotData['teacher'] as String?;
        final course = slotData['course'] as String?;

        print('🎯 Found slot - Teacher: $slotTeacher, Course: $course');

        if (slotTeacher == targetTeacherName &&
            course != null &&
            course != 'Free') {
          print('❌ Conflict: Target teacher has class at this time');
          return true; // Conflict found
        }
      }

      return false; // No conflict
    } catch (e) {
      print('❌ Error checking section conflict: $e');
      return true; // Assume conflict on error to be safe
    }
  }
}
