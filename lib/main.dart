import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'package:chugli_project65/features/onboarding/welcome_screen.dart';
import 'package:chugli_project65/core/theme/theme_provider.dart';
import 'package:chugli_project65/core/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
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
          debugShowCheckedModeBanner: false,
          title: 'ChugLi',
          themeMode: globalThemeProvider.themeMode,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          home: const WelcomeScreen(),
        );
      },
    );
  }
}
