import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:dart_geohash/dart_geohash.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:chugli_project65/data/services/fcm_service.dart';
import 'package:chugli_project65/data/services/location_service.dart';

// Safely converts a Firestore value to DateTime.
// Returns [fallback] if the value is null or not a Timestamp.
DateTime _toDateTime(dynamic value, {DateTime? fallback}) {
  if (value is Timestamp) return value.toDate();
  return fallback ?? DateTime.now();
}

class FirestoreRoomService {
  FirestoreRoomService._();
  static final instance = FirestoreRoomService._();

  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  String get _uid {
    final user = _auth.currentUser;
    if (user != null) return user.uid;
    throw Exception('No authenticated user. Please restart the app.');
  }

  /// Returns the current user's Firebase UID (null-safe, public getter).
  String? get currentUid => _auth.currentUser?.uid;

  /// Ensures an anonymous user session exists.
  Future<void> ensureSignedIn() async {
    if (_auth.currentUser == null) {
      await _auth.signInAnonymously();
    }
  }

  // ── Stream all active public rooms ──────────────────────────────
  Stream<List<Map<String, dynamic>>> roomsStream() {
    return _db
        .collection('rooms')
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) {
              final data = doc.data();
              data['id'] = doc.id;
              data['createdAt'] = _toDateTime(data['createdAt']);
              data['expiresAt'] = _toDateTime(
                data['expiresAt'],
                fallback: DateTime.now().subtract(const Duration(seconds: 1)),
              );
              // Participant count = number of unique UIDs
              final uids = List<String>.from(data['participantUids'] ?? []);
              data['participants'] = uids.isEmpty ? 1 : uids.length;
              return data;
            })
            .where((room) =>
                (room['expiresAt'] as DateTime).isAfter(DateTime.now()))
            .toList());
  }

  // ── Stream a single room document ──────────────────────────────
  Stream<Map<String, dynamic>?> roomStream(String roomId) {
    return _db.collection('rooms').doc(roomId).snapshots().map((doc) {
      if (!doc.exists) return null;
      final data = doc.data()!;
      data['id'] = doc.id;
      data['createdAt'] = _toDateTime(data['createdAt']);
      data['expiresAt'] = _toDateTime(
        data['expiresAt'],
        fallback: DateTime.now().subtract(const Duration(seconds: 1)),
      );
      // Participant count = unique UIDs who have sent a message
      final uids = List<String>.from(data['participantUids'] ?? []);
      data['participants'] = uids.isEmpty ? 1 : uids.length;
      return data;
    });
  }

  // ── Stream rooms created by the current user ─────────────────────
  Stream<List<Map<String, dynamic>>> myRoomsStream() {
    return _db
        .collection('rooms')
        .where('createdBy', isEqualTo: _uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((doc) {
              final data = doc.data();
              data['id'] = doc.id;
              data['createdAt'] = _toDateTime(data['createdAt']);
              data['expiresAt'] = _toDateTime(
                data['expiresAt'],
                fallback: DateTime.now().subtract(const Duration(seconds: 1)),
              );
              final uids = List<String>.from(data['participantUids'] ?? []);
              data['participants'] = uids.isEmpty ? 1 : uids.length;
              return data;
            }).toList());
  }

  // ── Stream rooms joined by the current user ─────────────────────
  Stream<List<Map<String, dynamic>>> joinedRoomsStream() {
    return _db
        .collection('rooms')
        .where('joinedUsers', arrayContains: _uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((doc) {
              final data = doc.data();
              data['id'] = doc.id;
              data['createdAt'] = _toDateTime(data['createdAt']);
              data['expiresAt'] = _toDateTime(
                data['expiresAt'],
                fallback: DateTime.now().subtract(const Duration(seconds: 1)),
              );
              final uids = List<String>.from(data['participantUids'] ?? []);
              data['participants'] = uids.isEmpty ? 1 : uids.length;
              return data;
            }).toList());
  }

  // ── Stream user activity ─────────────────────────────────────────
  Stream<List<Map<String, dynamic>>> activitiesStream() {
    return _db
        .collection('users')
        .doc(_uid)
        .collection('activity')
        .orderBy('timestamp', descending: true)
        .limit(100)
        .snapshots()
        .map((snap) => snap.docs.map((doc) {
              final data = doc.data();
              data['id'] = doc.id;
              data['timestamp'] = _toDateTime(data['timestamp']);
              return data;
            }).toList());
  }

  // ── Stream messages for a specific room ─────────────────────────
  Stream<List<Map<String, dynamic>>> messagesStream(String roomId) {
    return _db
        .collection('rooms')
        .doc(roomId)
        .collection('messages')
        .orderBy('timestamp')
        .snapshots()
        .map((snap) => snap.docs.map((doc) {
              final data = doc.data();
              data['id'] = doc.id;
              data['timestamp'] = _toDateTime(data['timestamp']);
              return data;
            }).toList());
  }

  // ── Join a room ──────────────────────────────────────────────────
  Future<void> joinRoom(String roomId) async {
    final uid = _uid;
    await _db.collection('rooms').doc(roomId).update({
      'joinedUsers': FieldValue.arrayUnion([uid]),
    });
  }

  // ── Create a new room ────────────────────────────────────────────
  Future<String> createRoom({
    required String title,
    required String category,
    required String description,
    required Duration expiryDuration,
    required String maxParticipants,
    required String visibility,
    double? latitude,
    double? longitude,
  }) async {
    final now = DateTime.now();
    final uid = _uid;
    final docRef = await _db.collection('rooms').add({
      'title': title,
      'category': category,
      'description': description,
      'preview': 'Room created! Start the conversation...',
      'participantUids': [uid],
      'joinedUsers': [uid],
      'maxParticipants': maxParticipants,
      'visibility': visibility,
      'createdAt': Timestamp.fromDate(now),
      'expiresAt': Timestamp.fromDate(now.add(expiryDuration)),
      'isHighActivity': false,
      'createdBy': uid,
      'reactions': <String>[],
      'latitude': latitude,
      'longitude': longitude,
    });

    await _logActivity(
      docId: docRef.id,
      title: title,
      type: 'Room',
      action: 'Room Created',
      category: category,
    );

    return docRef.id;
  }

  // ── Send a message ───────────────────────────────────────────────
  Future<void> sendMessage({
    required String roomId,
    required String handle,
    required String text,
    String? tag,
  }) async {
    final uid = _uid;
    final batch = _db.batch();

    final msgRef = _db
        .collection('rooms')
        .doc(roomId)
        .collection('messages')
        .doc();

    batch.set(msgRef, {
      'handle': handle,
      'text': text,
      'timestamp': Timestamp.now(),
      'tag': tag,
      'uid': uid,
      'reactions': <String>[],
    });

    final roomRef = _db.collection('rooms').doc(roomId);
    batch.update(roomRef, {
      'preview': text,
      'participantUids': FieldValue.arrayUnion([uid]),
    });

    await batch.commit();

    final snap = await _db
        .collection('rooms')
        .doc(roomId)
        .collection('messages')
        .count()
        .get();
    if ((snap.count ?? 0) >= 10) {
      await roomRef.update({'isHighActivity': true});
    }
  }

  // ── Add emoji reaction to a message ─────────────────────────────
  Future<void> addReaction(String roomId, String messageId, String emoji) async {
    final msgRef = _db
        .collection('rooms')
        .doc(roomId)
        .collection('messages')
        .doc(messageId);

    await msgRef.update({
      'reactions': FieldValue.arrayUnion([emoji]),
    });

    await _db.collection('rooms').doc(roomId).update({
      'reactions': FieldValue.arrayUnion([emoji]),
    });
  }

  // ── End a room early (creator only) ─────────────────────────────
  Future<void> endRoom(String roomId) async {
    await _db.collection('rooms').doc(roomId).update({
      'expiresAt': Timestamp.now(),
    });
  }

  // ── Save user profile to Firestore ──────────────────────────────
  Future<void> saveUserProfile({
    required String handle,
    List<String>? interests,
  }) async {
    await _db.collection('users').doc(_uid).set({
      'handle': handle,
      'interests': interests ?? [],
      'updatedAt': Timestamp.now(),
    }, SetOptions(merge: true));
  }

  // ── Sync user location, radius, and FCM token for notifications ──
  Future<void> syncUserLocationData({
    required double latitude,
    required double longitude,
    required double radiusPreference,
    required String geohash,
    String? fcmToken,
  }) async {
    final Map<String, dynamic> data = {
      'lastLocation': GeoPoint(latitude, longitude),
      'geohash': geohash,
      'radiusPreference': radiusPreference,
      'updatedAt': Timestamp.now(),
    };

    if (fcmToken != null) {
      data['fcmTokens'] = FieldValue.arrayUnion([fcmToken]);
    }

    await _db.collection('users').doc(_uid).set(data, SetOptions(merge: true));
  }

  Future<void> syncUserLocationAndNotifications() async {
    try {
      final locationService = LocationService.instance;
      final lat = locationService.latitude;
      final lon = locationService.longitude;

      if (lat == null || lon == null) return;

      final prefs = await SharedPreferences.getInstance();
      String radiusStr = prefs.getString('selected_radius') ?? '0.5 km';
      double radiusPreference = double.tryParse(radiusStr.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.5;

      final hasher = GeoHasher();
      final geohash = hasher.encode(lon, lat);

      final fcmToken = await FCMService.instance.getToken();

      await syncUserLocationData(
        latitude: lat,
        longitude: lon,
        radiusPreference: radiusPreference,
        geohash: geohash,
        fcmToken: fcmToken,
      );
    } catch (e) {
      // Ignore background sync errors
    }
  }


  // ── Get user handle from Firestore ───────────────────────────────
  Future<String?> getUserHandle() async {
    final doc = await _db.collection('users').doc(_uid).get();
    if (doc.exists) return doc.data()?['handle'] as String?;
    return null;
  }

  // ── Private: log activity ────────────────────────────────────────
  Future<void> _logActivity({
    required String docId,
    required String title,
    required String type,
    required String action,
    String? category,
    String? preview,
  }) async {
    await _db.collection('users').doc(_uid).collection('activity').add({
      'docId': docId,
      'title': title,
      'type': type,
      'action': action,
      'category': category,
      'preview': preview,
      'timestamp': Timestamp.now(),
    });
  }

  // ── Delete Account Data ──────────────────────────────────────────
  Future<void> deleteAccountData() async {
    final uid = _uid;
    final batch = _db.batch();

    // 1. Delete all user activity subcollection docs
    final activitySnap = await _db
        .collection('users')
        .doc(uid)
        .collection('activity')
        .get();
    for (final doc in activitySnap.docs) {
      batch.delete(doc.reference);
    }

    // 2. Delete all user reports subcollection docs
    final reportsSnap = await _db
        .collection('users')
        .doc(uid)
        .collection('reports')
        .get();
    for (final doc in reportsSnap.docs) {
      batch.delete(doc.reference);
    }

    // 3. Delete the user document itself
    batch.delete(_db.collection('users').doc(uid));

    // 4. Remove uid from joinedUsers & participantUids across rooms
    // Perform two queries and merge unique room document references.
    final participantRoomsSnap = await _db
        .collection('rooms')
        .where('participantUids', arrayContains: uid)
        .get();
    
    final joinedRoomsSnap = await _db
        .collection('rooms')
        .where('joinedUsers', arrayContains: uid)
        .get();

    final Set<String> roomIdsToUpdate = {};
    for (final doc in participantRoomsSnap.docs) {
      roomIdsToUpdate.add(doc.id);
    }
    for (final doc in joinedRoomsSnap.docs) {
      roomIdsToUpdate.add(doc.id);
    }

    for (final roomId in roomIdsToUpdate) {
      batch.update(_db.collection('rooms').doc(roomId), {
        'participantUids': FieldValue.arrayRemove([uid]),
        'joinedUsers': FieldValue.arrayRemove([uid]),
      });
    }

    // Commit all deletions and updates
    await batch.commit();
  }

  // ── Report a user from a chat message ────────────────────────────
  // Submits a report to rooms/{roomId}/reports and users/{myUid}/reports.
  // Then checks if the reported user should be auto-banned.
  Future<void> reportUser({
    required String roomId,
    required String reportedUid,
    required String reportedHandle,
    required String messageText,
    required String reason,
  }) async {
    final myUid = _uid;
    final now = Timestamp.now();

    // Avoid duplicate reports from the same user for the same person in this room.
    final existing = await _db
        .collection('rooms')
        .doc(roomId)
        .collection('reports')
        .where('reporterUid', isEqualTo: myUid)
        .where('reportedUid', isEqualTo: reportedUid)
        .limit(1)
        .get();
    if (existing.docs.isNotEmpty) return; // already reported this person

    final batch = _db.batch();

    // Write to room's reports subcollection
    final roomReportRef =
        _db.collection('rooms').doc(roomId).collection('reports').doc();
    batch.set(roomReportRef, {
      'reportedUid': reportedUid,
      'reportedHandle': reportedHandle,
      'reporterUid': myUid,
      'messageText': messageText,
      'reason': reason,
      'status': 'Pending',
      'timestamp': now,
    });

    // Mirror to the reporter's personal reports history
    final userReportRef =
        _db.collection('users').doc(myUid).collection('reports').doc();
    batch.set(userReportRef, {
      'reportedUid': reportedUid,
      'reportedHandle': reportedHandle,
      'roomId': roomId,
      'messageText': messageText,
      'reason': reason,
      'status': 'Pending',
      'submittedAt': now,
    });

    await batch.commit();

    // Check if the reported user should be auto-banned from this room.
    await _checkAndBanIfNeeded(roomId: roomId, reportedUid: reportedUid);
  }

  // ── Internal: auto-ban if reported by >50% of participants ───────
  Future<void> _checkAndBanIfNeeded({
    required String roomId,
    required String reportedUid,
  }) async {
    final roomDoc = await _db.collection('rooms').doc(roomId).get();
    if (!roomDoc.exists) return;

    final participantUids =
        List<String>.from(roomDoc.data()?['participantUids'] ?? []);
    final totalParticipants = participantUids.length;
    if (totalParticipants < 2) return; // Need at least 2 people

    // Count how many UNIQUE reporters have reported this specific user.
    final reportsSnap = await _db
        .collection('rooms')
        .doc(roomId)
        .collection('reports')
        .where('reportedUid', isEqualTo: reportedUid)
        .get();

    // Count unique reporters (deduplicate just in case)
    final uniqueReporters =
        reportsSnap.docs.map((d) => d.data()['reporterUid'] as String).toSet();
    final reportCount = uniqueReporters.length;

    // >50% threshold
    if (reportCount / totalParticipants > 0.5) {
      await _db
          .collection('rooms')
          .doc(roomId)
          .collection('bannedUsers')
          .doc(reportedUid)
          .set({
        'bannedAt': Timestamp.now(),
        'reason': 'Reported by majority of participants',
        'reportCount': reportCount,
      });
    }
  }

  // ── Check if the current user is banned from a room ──────────────
  Future<bool> isUserBanned(String roomId) async {
    final uid = _uid;
    final doc = await _db
        .collection('rooms')
        .doc(roomId)
        .collection('bannedUsers')
        .doc(uid)
        .get();
    return doc.exists;
  }

  // ── Stream of current user's report history ───────────────────────
  Stream<List<Map<String, dynamic>>> myReportsStream() {
    return _db
        .collection('users')
        .doc(_uid)
        .collection('reports')
        .orderBy('submittedAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((doc) {
              final data = doc.data();
              data['id'] = doc.id;
              data['submittedAt'] = _toDateTime(data['submittedAt']);
              return data;
            }).toList());
  }
}

