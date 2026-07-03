import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class MuteService {
  static const String _mutedRoomsKey = 'muted_rooms';

  MuteService._();
  static final instance = MuteService._();

  Future<List<Map<String, dynamic>>> getMutedRooms() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> mutedStrings = prefs.getStringList(_mutedRoomsKey) ?? [];
    
    return mutedStrings.map((str) {
      try {
        return jsonDecode(str) as Map<String, dynamic>;
      } catch (e) {
        return <String, dynamic>{};
      }
    }).where((map) => map.isNotEmpty).toList();
  }

  Future<List<String>> getMutedRoomIds() async {
    final rooms = await getMutedRooms();
    return rooms.map((r) => r['id']?.toString() ?? '').where((id) => id.isNotEmpty).toList();
  }

  Future<void> muteRoom({
    required String id,
    required String title,
    required String category,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final rooms = await getMutedRooms();
    
    // Check if already muted
    if (rooms.any((r) => r['id'] == id)) return;
    
    final newRoom = {
      'id': id,
      'title': title,
      'category': category,
      'mutedAt': DateTime.now().toIso8601String(),
    };
    
    rooms.add(newRoom);
    
    final List<String> updatedStrings = rooms.map((r) => jsonEncode(r)).toList();
    await prefs.setStringList(_mutedRoomsKey, updatedStrings);
  }

  Future<void> unmuteRoom(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final rooms = await getMutedRooms();
    
    rooms.removeWhere((r) => r['id'] == id);
    
    final List<String> updatedStrings = rooms.map((r) => jsonEncode(r)).toList();
    await prefs.setStringList(_mutedRoomsKey, updatedStrings);
  }
}
