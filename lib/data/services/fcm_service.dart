import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

class FCMService {
  static final FCMService instance = FCMService._internal();
  FCMService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  Future<String?> getToken() async {
    try {
      NotificationSettings settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        String? token = await _messaging.getToken();
        debugPrint("FCM Token: $token");
        return token;
      } else {
        debugPrint("User declined or has not accepted notification permission");
        return null;
      }
    } catch (e) {
      debugPrint("Error getting FCM token: $e");
      return null;
    }
  }
}
