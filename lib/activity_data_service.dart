import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ActivityDataService {
  ActivityDataService._privateConstructor();
  static final ActivityDataService instance = ActivityDataService._privateConstructor();

  final ValueNotifier<List<Map<String, dynamic>>> activitiesNotifier = ValueNotifier([]);
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;
    final prefs = await SharedPreferences.getInstance();
    final String? activitiesStr = prefs.getString('recent_activities');
    if (activitiesStr != null) {
      try {
        final List<dynamic> decoded = jsonDecode(activitiesStr);
        final List<Map<String, dynamic>> loaded = decoded.map((e) {
          final map = Map<String, dynamic>.from(e);
          map['timestamp'] = DateTime.parse(map['timestamp']);
          return map;
        }).toList();
        activitiesNotifier.value = loaded;
      } catch (e) {
        debugPrint('Error loading activities: $e');
      }
    }
    _isInitialized = true;
  }

  Future<void> _saveActivities() async {
    final prefs = await SharedPreferences.getInstance();
    final List<Map<String, dynamic>> toSave = activitiesNotifier.value.map((e) {
      final map = Map<String, dynamic>.from(e);
      map['timestamp'] = (map['timestamp'] as DateTime).toIso8601String();
      return map;
    }).toList();
    await prefs.setString('recent_activities', jsonEncode(toSave));
  }

  Future<void> addActivity({
    required String title,
    required String type, // 'Room', 'Message', 'Report', 'System'
    required String action,
    String? roomId,
    String? reportId,
    String? preview,
    String? handle,
    String? category,
  }) async {
    if (!_isInitialized) await initialize();
    
    final newActivity = {
      'id': 'act_${DateTime.now().millisecondsSinceEpoch}_${title.hashCode}',
      'title': title,
      'type': type,
      'action': action,
      'timestamp': DateTime.now(),
      'roomId': roomId,
      'reportId': reportId,
      'preview': preview,
      'handle': handle,
      'category': category,
    };

    final current = List<Map<String, dynamic>>.from(activitiesNotifier.value);
    current.insert(0, newActivity);
    activitiesNotifier.value = current;
    await _saveActivities();
  }

  Future<void> clearActivities() async {
    activitiesNotifier.value = [];
    await _saveActivities();
  }
}
