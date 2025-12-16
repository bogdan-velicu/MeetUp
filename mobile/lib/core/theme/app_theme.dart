import 'package:flutter/material.dart';

class AppTheme {
  // Colors extracted from meetup_logo.png
  // Primary: Dark Navy Blue from logo (#001830, #001B32, #00273B)
  static const Color primaryColor = Color(0xFF001B32); // Main brand color - Dark Navy
  static const Color primaryDark = Color(0xFF001830); // Darker variant
  static const Color primaryLight = Color(0xFF00273B); // Lighter variant
  static const Color secondaryColor = Color(0xFF3A5271); // Blue-gray from average
  static const Color accentColor = Color(0xFF4A90E2); // Bright blue accent
  static const Color successColor = Color(0xFF10B981); // Green
  static const Color errorColor = Color(0xFFEF4444); // Red
  static const Color warningColor = Color(0xFFF59E0B); // Orange
  static const Color backgroundColor = Color(0xFFF5F7FA); // Light gray
  static const Color surfaceColor = Colors.white;
  static const Color textPrimary = Color(0xFF0F172A); // Darker text for better contrast
  static const Color textSecondary = Color(0xFF64748B); // Better contrast gray
  static const Color textTertiary = Color(0xFF94A3B8); // Lighter gray for hints
  
  // Gradient colors
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryColor, primaryLight, secondaryColor],
  );
  
  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [accentColor, Color(0xFF5BA3F5)],
  );

  // Light Theme
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.light(
      primary: primaryColor,
      secondary: secondaryColor,
      tertiary: accentColor,
      error: errorColor,
      surface: surfaceColor,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: textPrimary,
    ),
    scaffoldBackgroundColor: backgroundColor,
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      iconTheme: const IconThemeData(color: textPrimary),
      titleTextStyle: const TextStyle(
        color: textPrimary,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
      // Modern transparent app bar
      surfaceTintColor: Colors.transparent,
    ),
    cardTheme: CardThemeData(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: surfaceColor,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        elevation: 2,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surfaceColor,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: primaryColor, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: errorColor),
      ),
    ),
    textTheme: const TextTheme(
      displayLarge: TextStyle(color: textPrimary, fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: -0.5),
      displayMedium: TextStyle(color: textPrimary, fontSize: 28, fontWeight: FontWeight.bold, letterSpacing: -0.5),
      displaySmall: TextStyle(color: textPrimary, fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: -0.3),
      headlineMedium: TextStyle(color: textPrimary, fontSize: 20, fontWeight: FontWeight.w600, letterSpacing: -0.2),
      titleLarge: TextStyle(color: textPrimary, fontSize: 18, fontWeight: FontWeight.w600, letterSpacing: 0),
      titleMedium: TextStyle(color: textPrimary, fontSize: 16, fontWeight: FontWeight.w600, letterSpacing: 0),
      bodyLarge: TextStyle(color: textPrimary, fontSize: 16, height: 1.5, letterSpacing: 0),
      bodyMedium: TextStyle(color: textPrimary, fontSize: 14, height: 1.5, letterSpacing: 0),
      bodySmall: TextStyle(color: textSecondary, fontSize: 12, height: 1.4, letterSpacing: 0),
      labelLarge: TextStyle(color: textPrimary, fontSize: 14, fontWeight: FontWeight.w500, letterSpacing: 0.1),
      labelMedium: TextStyle(color: textSecondary, fontSize: 12, fontWeight: FontWeight.w500, letterSpacing: 0.1),
      labelSmall: TextStyle(color: textTertiary, fontSize: 11, fontWeight: FontWeight.w500, letterSpacing: 0.1),
    ),
  );
}

