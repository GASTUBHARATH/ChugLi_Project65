import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppTheme {
  static const Color primaryPurple = Color(0xFF6C47FF);

  // SystemUiOverlayStyle applied globally: transparent status + nav bars,
  // correct icon brightness per theme.
  static const SystemUiOverlayStyle lightOverlayStyle = SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    statusBarBrightness: Brightness.light,
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarIconBrightness: Brightness.dark,
    systemNavigationBarDividerColor: Colors.transparent,
  );

  static const SystemUiOverlayStyle darkOverlayStyle = SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    statusBarBrightness: Brightness.dark,
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarIconBrightness: Brightness.light,
    systemNavigationBarDividerColor: Colors.transparent,
  );

  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorSchemeSeed: primaryPurple,
    scaffoldBackgroundColor: const Color(0xFFF7F5FF),
    canvasColor: Colors.white,
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: Color(0xFF1A1A1A)),
      bodyMedium: TextStyle(color: Color(0xFF1A1A1A)),
      bodySmall: TextStyle(color: Color(0xFF1A1A1A)),
    ),
    // All AppBars across the entire app get transparent status bars automatically
    appBarTheme: const AppBarTheme(
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: Colors.transparent,
      foregroundColor: Color(0xFF1A1A1A),
      systemOverlayStyle: lightOverlayStyle,
    ),
  );

  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorSchemeSeed: primaryPurple,
    scaffoldBackgroundColor: const Color(0xFF121212),
    cardColor: const Color(0xFF1E1E1E),
    canvasColor: const Color(0xFF1A1A1A), // For Drawer
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: Colors.white),
      bodyMedium: TextStyle(color: Colors.white),
      bodySmall: TextStyle(color: Colors.white70), // Light Grey secondary text
    ),
    // All AppBars across the entire app get transparent status bars automatically
    appBarTheme: const AppBarTheme(
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: Colors.transparent,
      foregroundColor: Colors.white,
      systemOverlayStyle: darkOverlayStyle,
    ),
  );
}
