// lib/presentation/shared_widgets/timetable_grid.dart
// Purpose: Reusable timetable grid widget showing class slots in a day

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants.dart';
import '../../core/utils/date_helpers.dart';
import '../../domain/entities/timetable.dart';
import '../providers/timetable_provider.dart';

class TimetableGrid extends StatefulWidget {
  final bool isEditable;
  final Function(ClassSlot)? onClassTap;
  
  const TimetableGrid({
    super.key,
    this.isEditable = false,
    this.onClassTap,
  });

  @override
  State<TimetableGrid> createState() => _TimetableGridState();
}

class _TimetableGridState extends State<TimetableGrid> {
  int _selectedDayIndex = 0;

  @override
  void initState() {
    super.initState();
    // Set initial day index based on current day of week (0 = Monday)
    final now = DateTime.now();
    final dayOfWeek = now.weekday - 1;
    _selectedDayIndex = dayOfWeek > 5 ? 0 : dayOfWeek; // Default to Monday if Sunday
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

  // Day selector (Mon - Sat) tabs
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
              
              // Update selected date in provider
              final provider = Provider.of<TimetableProvider>(context, listen: false);
              final today = DateTime.now();
              final startOfWeek = DateHelpers.getStartOfWeek(today);
              final selectedDate = DateTime(
                startOfWeek.year,
                startOfWeek.month,
                startOfWeek.day + index,
              );
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

  // Class list for the selected day
  Widget _buildClassList() {
    return Consumer<TimetableProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }
        
        if (provider.error != null) {
          return Center(
            child: Text(
              'Error loading timetable: ${provider.error}',
              style: const TextStyle(color: Colors.red),
            ),
          );
        }
        
        final classes = provider.getActiveSlotsForSelectedDate();
        
        if (classes.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32.0),
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
          itemCount: classes.length,
          itemBuilder: (context, index) {
            final classSlot = classes[index];
            return _buildClassCard(classSlot);
          },
        );
      },
    );
  }

  // Individual class card
  Widget _buildClassCard(ClassSlot classSlot) {
    // Determine card color based on colorCode
    Color borderColor;
    switch (classSlot.colorCode) {
      case 'red':
        borderColor = AppColors.classRed;
        break;
      case 'green':
        borderColor = AppColors.classGreen;
        break;
      case 'purple':
        borderColor = Colors.purple;
        break;
      case 'orange':
        borderColor = Colors.orange;
        break;
      case 'blue':
      default:
        borderColor = AppColors.classBlue;
        break;
    }
    
    // Always show 1h duration instead of the actual duration
    const duration = '1h';
    
    return GestureDetector(
      onTap: widget.onClassTap != null 
          ? () => widget.onClassTap!(classSlot) 
          : null,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6.0), // Reduced vertical margin
        decoration: BoxDecoration(
          color: AppColors.darkBackground,
          borderRadius: BorderRadius.circular(8.0),
          border: Border(
            left: BorderSide(
              color: borderColor,
              width: 6.0,
            ),
          ),
        ),
        child: Padding(
          // Reduced padding to make the card more compact
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0), 
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Time and Duration
              Row(
                children: [
                  const Icon(
                    Icons.access_time,
                    size: 16.0,
                    color: Colors.grey,
                  ),
                  const SizedBox(width: 8.0),
                  Text(
                    '${classSlot.startTime} - ${classSlot.endTime}',
                    style: const TextStyle(
                      color: Colors.grey,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8.0,
                      vertical: 2.0,
                    ),
                    decoration: BoxDecoration(
                      color: borderColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4.0),
                    ),
                    child: Text(
                      duration, // Always show 1h
                      style: TextStyle(
                        color: borderColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12.0,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10.0), // Reduced spacing
              
              // Subject Name
              Text(
                classSlot.subject,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6.0), // Reduced spacing
              
              // Only Teacher (Room number removed)
              Row(
                children: [
                  const Icon(
                    Icons.person,
                    size: 16.0,
                    color: Colors.grey,
                  ),
                  const SizedBox(width: 8.0),
                  Text(
                    classSlot.teacherName,
                    style: const TextStyle(
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
              
              // Status badges (if any)
              if (classSlot.isExtraClass || classSlot.isRescheduled)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8.0,
                      vertical: 2.0,
                    ),
                    decoration: BoxDecoration(
                      color: classSlot.isExtraClass 
                          ? Colors.green.withOpacity(0.2)
                          : Colors.orange.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4.0),
                    ),
                    child: Text(
                      classSlot.isExtraClass ? 'Extra Class' : 'Rescheduled',
                      style: TextStyle(
                        color: classSlot.isExtraClass ? Colors.green : Colors.orange,
                        fontWeight: FontWeight.bold,
                        fontSize: 12.0,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}