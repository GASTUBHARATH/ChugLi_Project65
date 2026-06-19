import 'package:flutter/foundation.dart';
import 'activity_data_service.dart';

class RoomDataService {
  RoomDataService._privateConstructor();
  static final RoomDataService instance = RoomDataService._privateConstructor();

  final ValueNotifier<List<Map<String, dynamic>>> roomsNotifier = ValueNotifier([
    {
      'id': '1',
      'category': 'Funny',
      'title': 'The Worst First Dates',
      'description': 'Share your worst first date stories!',
      'preview': 'So I showed up at the cafe and realized I was wearing two different shoes...',
      'participants': 42,
      'maxParticipants': '50',
      'visibility': 'Public',
      'createdAt': DateTime.now().subtract(const Duration(minutes: 10)),
      'expiryTime': const Duration(hours: 2),
      'isHighActivity': true,
      'createdBy': 'other_user',
      'joinedUsers': <String>[],
      'reactions': ['😂', '💀', '🔥'],
      'messages': [
        {
          'id': 'm1',
          'handle': 'Anonymous Panda',
          'text': 'So I showed up at the cafe and realized I was wearing two different shoes...',
          'timestamp': DateTime.now().subtract(const Duration(minutes: 9)),
          'tag': 'Funny',
          'reactions': ['😂', '💀'],
        }
      ]
    },
    {
      'id': '2',
      'category': 'Question',
      'title': 'Best Late Night Maggi Spot?',
      'description': 'Looking for midnight snacks.',
      'preview': 'Hungry near the main gate, where can I get the spiciest cheese maggi right now?',
      'participants': 12,
      'maxParticipants': '20',
      'visibility': 'Public',
      'createdAt': DateTime.now().subtract(const Duration(minutes: 20)),
      'expiryTime': const Duration(hours: 1),
      'isHighActivity': false,
      'createdBy': 'other_user',
      'joinedUsers': <String>[],
      'reactions': ['😋', '📍'],
      'messages': [
        {
          'id': 'm2',
          'handle': 'Hungry Ghost',
          'text': 'Hungry near the main gate, where can I get the spiciest cheese maggi right now?',
          'timestamp': DateTime.now().subtract(const Duration(minutes: 19)),
          'tag': 'Question',
          'reactions': ['😋'],
        }
      ]
    },
    {
      'id': '3',
      'category': 'Confession',
      'title': 'To the girl in the library...',
      'description': '',
      'preview': 'You were reading "The Alchemist" and wearing a yellow hoodie. I wanted to say hi but...',
      'participants': 8,
      'maxParticipants': 'Unlimited',
      'visibility': 'Public',
      'createdAt': DateTime.now().subtract(const Duration(hours: 1)),
      'expiryTime': const Duration(hours: 6),
      'isHighActivity': false,
      'createdBy': 'other_user',
      'joinedUsers': <String>[],
      'reactions': ['❤️', '👀'],
      'messages': [
        {
          'id': 'm3',
          'handle': 'Silent Reader',
          'text': 'You were reading "The Alchemist" and wearing a yellow hoodie. I wanted to say hi but I chickened out.',
          'timestamp': DateTime.now().subtract(const Duration(minutes: 55)),
          'tag': 'Confession',
          'reactions': ['❤️'],
        }
      ]
    },
  ]);

  void addRoom(Map<String, dynamic> room) {
    final newRooms = List<Map<String, dynamic>>.from(roomsNotifier.value);
    newRooms.insert(0, room); // Add to top
    roomsNotifier.value = newRooms;

    ActivityDataService.instance.addActivity(
      title: room['title'] ?? 'New Room',
      type: 'Room',
      action: 'Room Created',
      roomId: room['id'],
      preview: room['preview'],
      category: room['category'],
    );
  }

  void addMessage(String roomId, Map<String, dynamic> message) {
    final newRooms = List<Map<String, dynamic>>.from(roomsNotifier.value);
    final roomIndex = newRooms.indexWhere((r) => r['id'] == roomId);
    if (roomIndex != -1) {
      final room = Map<String, dynamic>.from(newRooms[roomIndex]);
      final messages = List<Map<String, dynamic>>.from(room['messages'] ?? []);
      messages.add(message);
      room['messages'] = messages;
      room['preview'] = message['text']; 
      
      final joinedUsers = List<String>.from(room['joinedUsers'] ?? []);
      if (!joinedUsers.contains('current_user')) {
        joinedUsers.add('current_user');
        room['joinedUsers'] = joinedUsers;
        
        ActivityDataService.instance.addActivity(
          title: room['title'] ?? 'Room',
          type: 'Room',
          action: 'Room Joined',
          roomId: room['id'],
          preview: 'You joined the conversation',
          category: room['category'],
        );
      }
      
      if (messages.length >= 3) {
        room['isHighActivity'] = true;
      }

      newRooms[roomIndex] = room;
      roomsNotifier.value = newRooms;

      ActivityDataService.instance.addActivity(
        title: room['title'] ?? 'Room',
        type: 'Message',
        action: 'New Message',
        roomId: room['id'],
        preview: message['text'],
        handle: message['handle'],
        category: room['category'],
      );
    }
  }

  void addReaction(String roomId, String messageId, String emoji) {
    final newRooms = List<Map<String, dynamic>>.from(roomsNotifier.value);
    final roomIndex = newRooms.indexWhere((r) => r['id'] == roomId);
    if (roomIndex != -1) {
      final room = Map<String, dynamic>.from(newRooms[roomIndex]);
      final messages = List<Map<String, dynamic>>.from(room['messages'] ?? []);
      final msgIndex = messages.indexWhere((m) => m['id'] == messageId);
      if (msgIndex != -1) {
        final message = Map<String, dynamic>.from(messages[msgIndex]);
        final reactions = List<String>.from(message['reactions'] ?? []);
        reactions.add(emoji);
        message['reactions'] = reactions;
        messages[msgIndex] = message;
        room['messages'] = messages;
        
        final roomReactions = List<String>.from(room['reactions'] ?? []);
        if (!roomReactions.contains(emoji)) {
          roomReactions.add(emoji);
          room['reactions'] = roomReactions;
        }

        final joinedUsers = List<String>.from(room['joinedUsers'] ?? []);
        if (!joinedUsers.contains('current_user')) {
          joinedUsers.add('current_user');
          room['joinedUsers'] = joinedUsers;
        }

        newRooms[roomIndex] = room;
        roomsNotifier.value = newRooms;
      }
    }
  }

  void endRoomEarly(String roomId) {
    final newRooms = List<Map<String, dynamic>>.from(roomsNotifier.value);
    final roomIndex = newRooms.indexWhere((r) => r['id'] == roomId);
    if (roomIndex != -1) {
      final room = Map<String, dynamic>.from(newRooms[roomIndex]);
      // Force room to expire immediately by setting expiryTime to 0
      room['expiryTime'] = const Duration(seconds: 0);
      newRooms[roomIndex] = room;
      roomsNotifier.value = newRooms;
      
      ActivityDataService.instance.addActivity(
        title: room['title'] ?? 'Room',
        type: 'Room',
        action: 'Room Expired',
        roomId: room['id'],
        category: room['category'],
      );
    }
  }
}
