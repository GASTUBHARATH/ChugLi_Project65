import 'package:flutter/material.dart';
import 'package:chugli_project65/features/onboarding/welcome_screen.dart';

import 'package:chugli_project65/core/theme/theme_provider.dart';
import 'package:chugli_project65/core/theme/app_theme.dart';

void main() {
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
