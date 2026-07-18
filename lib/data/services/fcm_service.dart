import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// ── Notification channel IDs ──────────────────────────────────────────────────
const String _nearbyRoomsChannelId = 'nearby_rooms';
const String _broadcastsChannelId = 'broadcasts';
const String _mentionsRepliesChannelId = 'mentions_replies';

// ── Background message handler ────────────────────────────────────────────────
// MUST be a top-level function (not inside a class) — Flutter's isolate rules.
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Firebase is already initialized by the main isolate, but we print to confirm.
  debugPrint(
      '📬 [BGHandler] Received background message: ${message.messageId}');
  debugPrint('  title : ${message.notification?.title}');
  debugPrint('  body  : ${message.notification?.body}');
  debugPrint('  data  : ${message.data}');
}

// ── Android notification channels ────────────────────────────────────────────
const AndroidNotificationChannel _nearbyRoomsChannel = AndroidNotificationChannel(
  _nearbyRoomsChannelId,
  'Nearby Rooms',
  description: 'Notifications when new rooms open near you.',
  importance: Importance.high,
  playSound: true,
  enableVibration: true,
);

const AndroidNotificationChannel _broadcastsChannel = AndroidNotificationChannel(
  _broadcastsChannelId,
  'Announcements',
  description: 'Important announcements from the Bolbro team.',
  importance: Importance.max,
  playSound: true,
  enableVibration: true,
);

const AndroidNotificationChannel _mentionsRepliesChannel = AndroidNotificationChannel(
  _mentionsRepliesChannelId,
  'Mentions & Replies',
  description: 'Notifications when someone replies to you or @mentions you in a room.',
  importance: Importance.high,
  playSound: true,
  enableVibration: true,
);

// ── FCMService singleton ──────────────────────────────────────────────────────
class FCMService {
  FCMService._internal();
  static final FCMService instance = FCMService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  // Injected from main.dart so we can navigate from notification taps.
  GlobalKey<NavigatorState>? _navigatorKey;

  // Broadcast listeners — widgets can register to show an in-app banner.
  final List<void Function(String title, String body)> _broadcastListeners = [];

  // ── Broadcast listener registration ────────────────────────────────────────
  void addBroadcastListener(void Function(String title, String body) listener) {
    _broadcastListeners.add(listener);
  }

  void removeBroadcastListener(void Function(String title, String body) listener) {
    _broadcastListeners.remove(listener);
  }

  void _notifyBroadcastListeners(String title, String body) {
    for (final listener in _broadcastListeners) {
      listener(title, body);
    }
  }

  // ── Public: call once in main() after Firebase.initializeApp ─────────────
  Future<void> initialize(GlobalKey<NavigatorState> navigatorKey) async {
    _navigatorKey = navigatorKey;

    // 1. Register background handler (must be done before any other setup).
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // 2. Set up Android local notification channels.
    final androidPlugin = _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.createNotificationChannel(_nearbyRoomsChannel);
    await androidPlugin?.createNotificationChannel(_broadcastsChannel);
    await androidPlugin?.createNotificationChannel(_mentionsRepliesChannel);

    // 3. Initialize local notifications plugin.
    const initSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false, // We request via FCM below.
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
    );
    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onLocalNotificationTap,
    );

    // 4. Request notification permission from the user.
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
    debugPrint(
        '🔔 FCM permission: ${settings.authorizationStatus.name}');

    // 5. Tell FCM to deliver data-only messages even when the app is foregrounded.
    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    // 6. Foreground message listener — show an in-app local notification.
    FirebaseMessaging.onMessage.listen(_onForegroundMessage);

    // 7. Notification tap when app was in background (not terminated).
    FirebaseMessaging.onMessageOpenedApp.listen(_onNotificationTap);

    // 8. Notification tap when app was fully terminated.
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      debugPrint(
          '🚀 App launched via notification: ${initialMessage.data}');
      // Slight delay so the navigator is ready.
      await Future.delayed(const Duration(milliseconds: 500));
      _navigateFromMessage(initialMessage);
    }

    // 9. Listen for FCM token refresh — when Android/iOS rotates the token,
    //    save the new one to Firestore so notifications keep working.
    _messaging.onTokenRefresh.listen((newToken) {
      debugPrint('🔄 FCM token refreshed: $newToken');
      _saveTokenToFirestore(newToken);
    });

    // 10. Also eagerly save the current token on every app launch.
    //     This ensures the token is present even if the onboarding flow
    //     didn't sync it (e.g., user skipped location).
    try {
      final currentToken = await _messaging.getToken();
      if (currentToken != null) {
        debugPrint('📲 Saving current FCM token on startup: $currentToken');
        _saveTokenToFirestore(currentToken);
      }
    } catch (e) {
      debugPrint('⚠️ Could not save FCM token on startup: $e');
    }
  }

  // ── Get FCM token (used by syncUserLocationAndNotifications) ─────────────
  Future<String?> getToken() async {
    try {
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional) {
        final token = await _messaging.getToken();
        debugPrint('📲 FCM Token: $token');
        return token;
      } else {
        debugPrint('❌ User declined notification permission');
        return null;
      }
    } catch (e) {
      debugPrint('❌ Error getting FCM token: $e');
      return null;
    }
  }

  /// Saves a single FCM token to the current user's Firestore document.
  /// Called on token refresh and on each app startup.
  void _saveTokenToFirestore(String token) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    FirebaseFirestore.instance.collection('users').doc(uid).set({
      'fcmTokens': FieldValue.arrayUnion([token]),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true)).then((_) {
      debugPrint('✅ FCM token saved to Firestore for uid=$uid');
    }).catchError((e) {
      debugPrint('⚠️ Failed to save FCM token to Firestore: $e');
    });
  }

  // ── Foreground handler ────────────────────────────────────────────────────
  void _onForegroundMessage(RemoteMessage message) {
    debugPrint('📨 [FG] Message received: ${message.notification?.title}');

    final notification = message.notification;
    final android = message.notification?.android;
    final String type = message.data['type'] ?? '';
    final isBroadcast = type == 'broadcast';
    final isMentionReply = type == 'mention' || type == 'reply';

    if (notification != null) {
      // For broadcasts: notify in-app listeners (shows a banner) AND
      // still show a system notification for visibility.
      if (isBroadcast) {
        _notifyBroadcastListeners(
          notification.title ?? '📣 Announcement',
          notification.body ?? '',
        );
      }

      // Route to the correct channel based on type.
      final String channelId;
      final String channelName;
      final String? channelDescription;
      final Importance importance;

      if (isBroadcast) {
        channelId = _broadcastsChannelId;
        channelName = _broadcastsChannel.name;
        channelDescription = _broadcastsChannel.description;
        importance = Importance.max;
      } else if (isMentionReply) {
        channelId = _mentionsRepliesChannelId;
        channelName = _mentionsRepliesChannel.name;
        channelDescription = _mentionsRepliesChannel.description;
        importance = Importance.high;
      } else {
        channelId = _nearbyRoomsChannelId;
        channelName = _nearbyRoomsChannel.name;
        channelDescription = _nearbyRoomsChannel.description;
        importance = Importance.high;
      }

      _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            channelId,
            channelName,
            channelDescription: channelDescription,
            importance: importance,
            priority: Priority.high,
            icon: android?.smallIcon ?? '@mipmap/ic_launcher',
            playSound: true,
            enableVibration: true,
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        // For mention/reply and room notifications, payload is the roomId for tap navigation.
        payload: isBroadcast ? null : message.data['roomId'],
      );
    }
  }

  // ── Background tap handler ────────────────────────────────────────────────
  void _onNotificationTap(RemoteMessage message) {
    debugPrint('👆 Notification tapped (background): ${message.data}');
    _navigateFromMessage(message);
  }

  // ── Local notification tap (foreground notification tapped) ───────────────
  void _onLocalNotificationTap(NotificationResponse response) {
    final roomId = response.payload;
    debugPrint('👆 Local notification tapped. roomId=$roomId');
    if (roomId != null && roomId.isNotEmpty) {
      _navigateToRoom(roomId);
    }
  }

  // ── Navigate based on FCM data payload ───────────────────────────────────
  void _navigateFromMessage(RemoteMessage message) {
    final roomId = message.data['roomId'];
    if (roomId != null && roomId.toString().isNotEmpty) {
      _navigateToRoom(roomId.toString());
    }
  }

  void _navigateToRoom(String roomId) {
    final navigator = _navigatorKey?.currentState;
    if (navigator == null) {
      debugPrint('⚠️ Navigator not ready for FCM navigation');
      return;
    }

    // Import is resolved at runtime — we push a named route or a dynamic route.
    // Using pushNamed with arguments keeps routing clean.
    navigator.pushNamed(
      '/room',
      arguments: roomId,
    );
  }
}
