# Student Timetable Management App

## Overview
A dynamic timetable management mobile application built with Flutter for college students and faculty. The app allows students to view their daily schedule, receive real-time notifications about class changes, and access their profile information.

## Features
- **Role-based Authentication**: Separate login flows for students and teachers
- **Dynamic Timetable View**: Weekly view with day selection
- **Class Management**: For teachers to cancel, reschedule, or add extra classes
- **Real-time Notifications**: Updates about class changes
- **Profile Information**: Student and teacher profiles with relevant details
- **Offline Support**: Caching for offline access using SharedPreferences

## Project Structure
The project follows Clean Architecture principles with the following layers:

### Core
- **Constants**: App-wide colors, text styles, and spacing
- **Error Handling**: Failure classes for different error scenarios
- **Utilities**: Helper functions for dates and time formatting

### Domain Layer
- **Entities**: Core business models (User, Student, Teacher, Timetable, etc.)
- **Repositories**: Abstract interfaces for data operations
- **Use Cases**: Application-specific business rules

### Data Layer
- **Models**: Serializable versions of domain entities
- **Data Sources**: Remote (Firebase) and local (Cache) data sources
- **Repository Implementations**: Concrete implementations of domain repositories

### Presentation Layer
- **Providers**: State management using the Provider package
- **Screens**: UI screens for different user roles and features
- **Shared Widgets**: Reusable components across the app

## Technologies Used
- **Flutter**: UI framework
- **Provider**: State management
- **SharedPreferences**: Local cache storage
- **Equatable**: Value equality
- **UUID**: Unique ID generation
- **Firebase** *(Stubbed)*: Authentication, Database, and Notifications

## Setup Instructions
1. Clone the repository
2. Ensure Flutter (2.5.0 or higher) is installed
3. Run `flutter pub get` to fetch dependencies
4. Run `flutter run` to launch the app

## Test Credentials
- **Student Login**:
  - USN: CS001
  - DOB: 01/01/2000
- **Teacher Login**:
  - Email: teacher@example.com
  - Password: password123

## Future Enhancements
- Complete Firebase integration
- Class exchange requests
- Admin approval workflow
- Smart timetable updates based on predefined rules
- Expanded teacher functionalities
