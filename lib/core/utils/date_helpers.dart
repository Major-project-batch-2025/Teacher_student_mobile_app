// lib/core/utils/date_helpers.dart
// Purpose: Utility functions for date operations, week ranges, formatting, etc.

import 'package:intl/intl.dart';

class DateHelpers {
  // Format date to display as "dd MMM yyyy" (e.g., "01 Jan 2025")
  static String formatDate(DateTime date) {
    return DateFormat('dd MMM yyyy').format(date);
  }

  // Format time to display as "HH:mm" (e.g., "09:30")
  static String formatTime(DateTime time) {
    return DateFormat('HH:mm').format(time);
  }

  // Format duration in minutes to "Xh Ym" format
  static String formatDuration(int durationMinutes) {
    final hours = durationMinutes ~/ 60;
    final minutes = durationMinutes % 60;
    
    if (hours > 0 && minutes > 0) {
      return '${hours}h ${minutes}m';
    } else if (hours > 0) {
      return '${hours}h';
    } else {
      return '${minutes}m';
    }
  }

  // Get the start of the current week (Monday)
  static DateTime getStartOfWeek(DateTime date) {
    // Get days since Monday (0 for Monday, 1 for Tuesday, etc.)
    final daysSinceMonday = date.weekday - 1;
    return DateTime(date.year, date.month, date.day - daysSinceMonday);
  }

  // Get the end of the current week (Saturday for college schedule)
  static DateTime getEndOfWeek(DateTime date) {
    final startOfWeek = getStartOfWeek(date);
    // Add 5 days to get to Saturday (college schedule typically Monday-Saturday)
    return DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day + 5);
  }

  // Get week range as formatted string (e.g., "2 Jan - 7 Jan 2025")
  static String getWeekRangeString(DateTime date) {
    final startOfWeek = getStartOfWeek(date);
    final endOfWeek = getEndOfWeek(date);
    
    // Same month and year
    if (startOfWeek.month == endOfWeek.month && startOfWeek.year == endOfWeek.year) {
      return '${startOfWeek.day} - ${endOfWeek.day} ${DateFormat('MMM yyyy').format(startOfWeek)}';
    }
    // Same year
    else if (startOfWeek.year == endOfWeek.year) {
      return '${DateFormat('d MMM').format(startOfWeek)} - ${DateFormat('d MMM yyyy').format(endOfWeek)}';
    }
    // Different years
    else {
      return '${DateFormat('d MMM yyyy').format(startOfWeek)} - ${DateFormat('d MMM yyyy').format(endOfWeek)}';
    }
  }

  // Get current week number in the year (1-52)
  static int getWeekNumber(DateTime date) {
    // Get first day of the year
    final firstDayOfYear = DateTime(date.year, 1, 1);
    // Get days passed since first day of the year
    final daysPassed = date.difference(firstDayOfYear).inDays;
    // Calculate week number (adding 1 because weeks start from 1)
    return ((daysPassed + firstDayOfYear.weekday - 1) / 7).ceil();
  }

  // Generate a list of DateTime objects for each weekday in current week
  static List<DateTime> getWeekdays(DateTime date) {
    final startOfWeek = getStartOfWeek(date);
    // Generate 6 days (Monday to Saturday)
    return List.generate(6, (index) => 
      DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day + index)
    );
  }

  // Check if two DateTimes are on the same day
  static bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
  
  // Check if a date is today
  static bool isToday(DateTime date) {
    final now = DateTime.now();
    return isSameDay(date, now);
  }
  
  // Calculate if a class action has expired (after 7 days)
  static bool isActionExpired(DateTime actionDate) {
    final now = DateTime.now();
    final difference = now.difference(actionDate).inDays;
    return difference >= 7; // Action expires after 7 days
  }
  
  // Get weekday name from index (0 = Monday, 1 = Tuesday, etc.)
  static String getWeekdayName(int index) {
    const weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
    return weekdays[index % weekdays.length];
  }
  
  // Get short weekday name from index (0 = Mon, 1 = Tue, etc.)
  static String getShortWeekdayName(int index) {
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    return weekdays[index % weekdays.length];
  }
}