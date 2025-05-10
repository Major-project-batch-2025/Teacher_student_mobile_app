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
    return Container(
      height: 60.0,
      decoration: BoxDecoration(
        color: AppColors.darkBackground,
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: AppStrings.weekdays.length,
        itemBuilder: (context, index) {
          final isSelected = index == _selectedDayIndex;
          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedDayIndex = index;
              });
              final provider = Provider.of<TimetableProvider>(context, listen: false);
              final today = DateTime.now();
              final selectedDate = today
                  .subtract(Duration(days: today.weekday - 1))
                  .add(Duration(days: index));
              provider.setSelectedDate(selectedDate);
            },
            child: Container(
              width: 70.0,
              margin: const EdgeInsets.all(4.0),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Center(
                child: Text(
                  AppStrings.weekdays[index],
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.grey,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
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

        final sortedEntries = slotsMap.entries
            .where((entry) => entry.value.course != 'Free')
            .toList()
          ..sort((a, b) {
            int toMinutes(String timeStr) {
              final timeRange = timeStr.split('-').first.trim();
              final parts = timeRange.split(':');
              final hour = int.tryParse(parts[0]) ?? 0;
              final minute = int.tryParse(parts[1]) ?? 0;
              final hour24 = (hour < 7) ? hour + 12 : hour;
              return hour24 * 60 + minute;
            }

            return toMinutes(a.key).compareTo(toMinutes(b.key));
          });

        if (sortedEntries.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(32.0),
            child: Center(
              child: Text(
                'No classes scheduled for this day',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 16.0,
                ),
              ),
            ),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: sortedEntries.length,
          itemBuilder: (context, index) {
            final entry = sortedEntries[index];
            return GestureDetector(
              onTap: () {
                if (widget.onClassTap != null) {
                  widget.onClassTap!(entry.key, entry.value);
                }
              },
              child: _buildClassCard(entry.key, entry.value),
            );
          },
        );
      },
    );
  }

  Widget _buildClassCard(String time, ClassSlotModel classSlot) {
    const duration = '1h';

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6.0),
      decoration: BoxDecoration(
        color: AppColors.darkBackground,
        borderRadius: BorderRadius.circular(8.0),
        border: Border(
          left: BorderSide(color: AppColors.classBlue, width: 6.0),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
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
                  padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4.0),
                  ),
                  child: const Text(
                    duration,
                    style: TextStyle(
                      color: AppColors.classBlue,
                      fontWeight: FontWeight.bold,
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
            const SizedBox(height: 6.0),
            Row(
              children: [
                const Icon(Icons.person, size: 16.0, color: Colors.grey),
                const SizedBox(width: 8.0),
                Text(
                  classSlot.teacher.isEmpty ? 'TBA' : classSlot.teacher,
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
