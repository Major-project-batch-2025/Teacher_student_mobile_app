// lib/data/datasources/local/cache_ds.dart
// Purpose: Local cache data source for storing and retrieving data when offline

import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/errors/failures.dart';
import '../../models/class_action_model.dart';
import '../../models/notification_model.dart';
import '../../models/timetable_model.dart';
import '../../models/user_model.dart';

// Cache data source interface
abstract class CacheDataSource {
  // User related methods
  Future<bool> cacheUser({
    required UserModel user,
  });
  
  Future<UserModel?> getUser();
  
  Future<bool> clearUser();
  
  // Timetable related methods
  Future<bool> cacheTimetable({
    required TimetableModel timetable,
  });
  
  Future<TimetableModel?> getTimetable({
    required String section,
    required int semester,
  });
  
  // Class action related methods
  Future<bool> cacheClassActions({
    required List<ClassActionModel> actions,
  });
  
  Future<List<ClassActionModel>> getClassActions();
  
  // Notification related methods
  Future<bool> cacheNotifications({
    required List<NotificationModel> notifications,
  });
  
  Future<List<NotificationModel>> getNotifications();
}

// Implementation of cache data source
class CacheDataSourceImpl implements CacheDataSource {
  final SharedPreferences sharedPreferences;
  
  // Keys for shared preferences
  static const String userKey = 'CACHED_USER';
  static const String timetablePrefixKey = 'CACHED_TIMETABLE_';
  static const String classActionsKey = 'CACHED_CLASS_ACTIONS';
  static const String notificationsKey = 'CACHED_NOTIFICATIONS';
  
  CacheDataSourceImpl({
    required this.sharedPreferences,
  });
  
  // User related methods implementation
  @override
  Future<bool> cacheUser({
    required UserModel user,
  }) async {
    final userJson = jsonEncode(user.toJson());
    return await sharedPreferences.setString(userKey, userJson);
  }
  
  @override
  Future<UserModel?> getUser() async {
    final userJsonString = sharedPreferences.getString(userKey);
    
    if (userJsonString == null) {
      return null;
    }
    
    try {
      final userJson = jsonDecode(userJsonString);
      
      // Check role to determine which model to instantiate
      if (userJson['role'] == 'student') {
        // Return StudentModel as UserModel since StudentModel extends UserModel
        return StudentModel.fromJson(userJson) as UserModel;
      } else if (userJson['role'] == 'teacher') {
        // Return TeacherModel as UserModel since TeacherModel extends UserModel
        return TeacherModel.fromJson(userJson) as UserModel;
      } else {
        return UserModel.fromJson(userJson);
      }
    } catch (e) {
      throw CacheFailure(message: 'Failed to parse cached user data: $e');
    }
  }
  
  @override
  Future<bool> clearUser() async {
    return await sharedPreferences.remove(userKey);
  }
  
  // Timetable related methods implementation
  @override
  Future<bool> cacheTimetable({
    required TimetableModel timetable,
  }) async {
    final key = '$timetablePrefixKey${timetable.section}_${timetable.semester}';
    final timetableJson = jsonEncode(timetable.toJson());
    return await sharedPreferences.setString(key, timetableJson);
  }
  
  @override
  Future<TimetableModel?> getTimetable({
    required String section,
    required int semester,
  }) async {
    final key = '$timetablePrefixKey${section}_$semester';
    final timetableJsonString = sharedPreferences.getString(key);
    
    if (timetableJsonString == null) {
      return null;
    }
    
    try {
      final timetableJson = jsonDecode(timetableJsonString);
      return TimetableModel.fromJson(timetableJson);
    } catch (e) {
      throw CacheFailure(message: 'Failed to parse cached timetable data: $e');
    }
  }
  
  // Class action related methods implementation
  @override
  Future<bool> cacheClassActions({
    required List<ClassActionModel> actions,
  }) async {
    final actionsJsonList = actions.map((action) => action.toJson()).toList();
    final actionsJson = jsonEncode(actionsJsonList);
    return await sharedPreferences.setString(classActionsKey, actionsJson);
  }
  
  @override
  Future<List<ClassActionModel>> getClassActions() async {
    final actionsJsonString = sharedPreferences.getString(classActionsKey);
    
    if (actionsJsonString == null) {
      return [];
    }
    
    try {
      final actionsJsonList = jsonDecode(actionsJsonString) as List;
      return actionsJsonList
          .map((actionJson) => ClassActionModel.fromJson(actionJson))
          .toList();
    } catch (e) {
      throw CacheFailure(message: 'Failed to parse cached class actions data: $e');
    }
  }
  
  // Notification related methods implementation
  @override
  Future<bool> cacheNotifications({
    required List<NotificationModel> notifications,
  }) async {
    final notificationsJsonList = notifications.map((notification) => notification.toJson()).toList();
    final notificationsJson = jsonEncode(notificationsJsonList);
    return await sharedPreferences.setString(notificationsKey, notificationsJson);
  }
  
  @override
  Future<List<NotificationModel>> getNotifications() async {
    final notificationsJsonString = sharedPreferences.getString(notificationsKey);
    
    if (notificationsJsonString == null) {
      return [];
    }
    
    try {
      final notificationsJsonList = jsonDecode(notificationsJsonString) as List;
      return notificationsJsonList
          .map((notificationJson) => NotificationModel.fromJson(notificationJson))
          .toList();
    } catch (e) {
      throw CacheFailure(message: 'Failed to parse cached notifications data: $e');
    }
  }
}