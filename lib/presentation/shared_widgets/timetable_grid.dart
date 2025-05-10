import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants.dart';
import '../providers/timetable_provider.dart';
import '../../../data/models/timetable_model.dart';

class TimetableGrid extends StatefulWidget {
  final void Function(String timeSlot, ClassSlotModel slot)? onClassTap;

  const TimetableGrid({super.key, this.onClassTap});

  @override
  State<TimetableGrid> createState() => _TimetableGridState();
}

class _TimetableGridState extends State<TimetableGrid> {
  int _selectedDayIndex = 0;

  // Color assignment for courses
  final Map<String, Color> _courseColors = {};
  final Random _random = Random();
  final List<Color> _availableColors = [
    Colors.green,
    Colors.red,
    Colors.purple,
    Colors.teal,
    Colors.orange,
    Colors.blue,
    Colors.pink,
    Colors.indigo,
    Colors.amber,
    Colors.cyan,
    Colors.lime,
    Colors.deepOrange,
    Colors.lightBlue,
    Colors.deepPurple,
    Colors.brown,
  ];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedDayIndex = now.weekday - 1; // Monday = 0, Sunday = 6

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<TimetableProvider>(context, listen: false);
      final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
      final selectedDate = DateTime(
        startOfWeek.year,
        startOfWeek.month,
        startOfWeek.day + _selectedDayIndex,
      );
      provider.setSelectedDate(selectedDate);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildDaySelector(),
        const SizedBox(height: 16.0),
        _buildClassList(),
      ],
    );
  }

  Widget _buildDaySelector() {
    return SizedBox(
      height: 80.0, // Fixed height for the selector
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: AppStrings.weekdays.length,
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        itemBuilder: (context, index) {
          final isSelected = index == _selectedDayIndex;
          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedDayIndex = index;
              });
              final provider = Provider.of<TimetableProvider>(
                context,
                listen: false,
              );
              final today = DateTime.now();
              final selectedDate = today
                  .subtract(Duration(days: today.weekday - 1))
                  .add(Duration(days: index));
              provider.setSelectedDate(selectedDate);
            },
            child: Container(
              width: 80.0, // Fixed width for each day box
              margin: const EdgeInsets.symmetric(
                horizontal: 6.0,
                vertical: 8.0,
              ),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : Colors.grey.shade900,
                borderRadius: BorderRadius.circular(12.0),
                border: Border.all(
                  color: isSelected ? AppColors.primary : Colors.grey.shade800,
                  width: 2.0,
                ),
                boxShadow:
                    isSelected
                        ? [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.3),
                            blurRadius: 8.0,
                            offset: const Offset(0, 4),
                          ),
                        ]
                        : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.calendar_today,
                    color: isSelected ? Colors.white : Colors.grey,
                    size: 24.0,
                  ),
                  const SizedBox(height: 8.0),
                  Text(
                    AppStrings.weekdays[index],
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.grey,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                      fontSize: 14.0,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildClassList() {
    return Consumer<TimetableProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.error != null) {
          return Center(
            child: Text(
              'Error loading timetable: ${provider.error}',
              style: const TextStyle(color: Colors.red),
            ),
          );
        }

        final slotsMap = provider.getSlotsForSelectedDay();

        // Get all time slots from the fetched data
        final allTimeSlots = <String>{};

        // First, collect all time slots from all days to ensure consistency
        if (provider.sectionSchedule != null) {
          provider.sectionSchedule!.forEach((day, daySlots) {
            daySlots.forEach((timeSlot, _) {
              allTimeSlots.add(timeSlot);
            });
          });
        }

        // Sort time slots chronologically
        final sortedTimeSlots =
            allTimeSlots.toList()..sort((a, b) {
              int toMinutes(String timeStr) {
                final timeRange = timeStr.split('-').first.trim();
                final parts = timeRange.split(':');
                final hour = int.tryParse(parts[0]) ?? 0;
                final minute = int.tryParse(parts[1]) ?? 0;
                final hour24 = (hour < 7) ? hour + 12 : hour;
                return hour24 * 60 + minute;
              }

              return toMinutes(a).compareTo(toMinutes(b));
            });

        if (sortedTimeSlots.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(32.0),
            child: Center(
              child: Text(
                'No timetable data available',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 16.0,
                ),
              ),
            ),
          );
        }

        // Build list with all time slots
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: sortedTimeSlots.length,
          itemBuilder: (context, index) {
            final timeSlot = sortedTimeSlots[index];
            final classSlot = slotsMap[timeSlot];

            if (classSlot != null && classSlot.course != 'Free') {
              // Class exists for this time slot
              return GestureDetector(
                onTap: () {
                  if (widget.onClassTap != null) {
                    widget.onClassTap!(timeSlot, classSlot);
                  }
                },
                child: _buildClassCard(timeSlot, classSlot),
              );
            } else {
              // Free slot
              return _buildFreeSlot(timeSlot);
            }
          },
        );
      },
    );
  }

  Widget _buildClassCard(String time, ClassSlotModel classSlot) {
    // Determine the color based on the subject
    Color borderColor = _getSubjectColor(classSlot.course);

    // Calculate duration from time string
    final duration = _calculateDuration(time);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6.0),
      decoration: BoxDecoration(
        color: AppColors.darkBackground,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: borderColor.withOpacity(0.3), width: 1.0),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12.0),
          border: Border(left: BorderSide(color: borderColor, width: 6.0)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.access_time, size: 16.0, color: Colors.grey),
                  const SizedBox(width: 8.0),
                  Text(time, style: const TextStyle(color: Colors.grey)),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8.0,
                      vertical: 4.0,
                    ),
                    decoration: BoxDecoration(
                      color: borderColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4.0),
                    ),
                    child: Text(
                      duration,
                      style: const TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.w500,
                        fontSize: 12.0,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10.0),
              Text(
                classSlot.course,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8.0),
              Row(
                children: [
                  const Icon(
                    Icons.location_on_outlined,
                    size: 16.0,
                    color: Colors.grey,
                  ),
                  const SizedBox(width: 8.0),
                  Text(
                    'Room', // Room info not available in current data model
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(width: 16.0),
                  const Icon(
                    Icons.person_outline,
                    size: 16.0,
                    color: Colors.grey,
                  ),
                  const SizedBox(width: 8.0),
                  Expanded(
                    child: Text(
                      classSlot.teacher.isEmpty ? 'TBA' : classSlot.teacher,
                      style: const TextStyle(color: Colors.grey),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFreeSlot(String time) {
    final duration = _calculateDuration(time);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6.0),
      decoration: BoxDecoration(
        color: Colors.grey.shade900.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: Colors.grey.shade800, width: 1.0),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.access_time, size: 16.0, color: Colors.grey),
                const SizedBox(width: 8.0),
                Text(time, style: const TextStyle(color: Colors.grey)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8.0,
                    vertical: 4.0,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade800,
                    borderRadius: BorderRadius.circular(4.0),
                  ),
                  child: Text(
                    duration,
                    style: TextStyle(
                      color: Colors.grey.shade400,
                      fontWeight: FontWeight.w500,
                      fontSize: 12.0,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10.0),
            Text(
              'Free',
              style: TextStyle(
                color: Colors.grey.shade400,
                fontSize: 18.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8.0),
            Text(
              'No class scheduled',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14.0),
            ),
          ],
        ),
      ),
    );
  }

  Color _getSubjectColor(String subject) {
    // Check if color already assigned to this subject
    if (_courseColors.containsKey(subject)) {
      return _courseColors[subject]!;
    }

    // Get a list of unused colors
    List<Color> unusedColors = List.from(_availableColors);
    _courseColors.values.forEach((usedColor) {
      unusedColors.remove(usedColor);
    });

    // If all colors are used, just pick any color
    if (unusedColors.isEmpty) {
      unusedColors = List.from(_availableColors);
    }

    // Randomly select a color
    int randomIndex = _random.nextInt(unusedColors.length);
    Color selectedColor = unusedColors[randomIndex];

    // Assign and store the color
    _courseColors[subject] = selectedColor;

    return selectedColor;
  }

  String _calculateDuration(String timeSlot) {
    try {
      final parts = timeSlot.split('-');
      if (parts.length != 2) return '1h';

      final startTime = parts[0].trim().split(':');
      final endTime = parts[1].trim().split(':');

      if (startTime.length != 2 || endTime.length != 2) return '1h';

      final startHour = int.tryParse(startTime[0]) ?? 0;
      final startMinute = int.tryParse(startTime[1]) ?? 0;
      final endHour = int.tryParse(endTime[0]) ?? 0;
      final endMinute = int.tryParse(endTime[1]) ?? 0;

      // Handle times like 09:00 (AM) and 1:30 (PM)
      final start24Hour =
          (startHour < 7 && startHour != 0) ? startHour + 12 : startHour;
      final end24Hour = (endHour < 7 && endHour != 0) ? endHour + 12 : endHour;

      final durationMinutes =
          (end24Hour * 60 + endMinute) - (start24Hour * 60 + startMinute);

      if (durationMinutes <= 0) return '1h';

      final hours = durationMinutes ~/ 60;
      final minutes = durationMinutes % 60;

      if (minutes == 0) {
        return '${hours}h';
      } else {
        return '${hours}h ${minutes}m';
      }
    } catch (e) {
      return '1h';
    }
  }
}
