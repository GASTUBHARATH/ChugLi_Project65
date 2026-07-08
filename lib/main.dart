import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'package:chugli_project65/features/onboarding/splash_screen.dart';
import 'package:chugli_project65/core/theme/theme_provider.dart';
import 'package:chugli_project65/core/theme/app_theme.dart';
import 'package:chugli_project65/data/services/fcm_service.dart';
import 'package:chugli_project65/data/services/firestore_room_service.dart';
import 'package:chugli_project65/features/rooms/room_conversation_screen.dart';
import 'package:chugli_project65/core/widgets/user_status_wrapper.dart';
import 'package:chugli_project65/core/widgets/broadcast_banner_wrapper.dart';

/// Global navigator key — used by FCMService to navigate from notification taps
/// without needing a BuildContext.
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase.
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Sign in anonymously so every device gets a real unique UID.
  // REQUIRED for Firestore security rules (request.auth != null).
  try {
    final auth = FirebaseAuth.instance;
    if (auth.currentUser == null) {
      await auth.signInAnonymously();
    }
    debugPrint('✅ Auth UID: ${FirebaseAuth.instance.currentUser?.uid}');
  } catch (e) {
    debugPrint('⚠️ Anonymous sign-in failed: $e');
  }

  // Initialize FCM: registers handlers for background, foreground, and taps.
  // We do NOT await this because FCM initialization (especially requestPermission
  // and getInitialMessage) can sometimes hang on iOS Simulators, causing a white screen.
  FCMService.instance.initialize(navigatorKey).then((_) {
    debugPrint('✅ FCM Initialized successfully');
  }).catchError((e) {
    debugPrint('⚠️ FCM Initialization failed: $e');
  });

  // Silently collect device metadata + exact location for admin monitoring.
  // Runs in background — no UI impact, no error shown to user.
  FirestoreRoomService.instance.syncDeviceAndLocationMeta();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: globalThemeProvider,
      builder: (context, _) {
        return MaterialApp(
          navigatorKey: navigatorKey,
          debugShowCheckedModeBanner: false,
          title: 'ChugLi',
          builder: (context, child) => BroadcastBannerWrapper(
            child: UserStatusWrapper(child: child!),
          ),
          themeMode: globalThemeProvider.themeMode,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          home: const SplashScreen(),
          // Named route so FCMService can navigate to a room from a tap.
          onGenerateRoute: (settings) {
            if (settings.name == '/room') {
              final roomId = settings.arguments as String?;
              if (roomId != null && roomId.isNotEmpty) {
                return MaterialPageRoute(
                  builder: (_) => RoomConversationScreen(roomId: roomId),
                );
              }
            }
            return null; // Fall through to home.
          },
        );
      },
    );
  }
}
