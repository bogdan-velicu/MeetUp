import 'package:flutter/material.dart';

class AppTheme {
  // Monochrome Color Palette - Professional and Modern
  static const Color primaryColor = Color(0xFF1A1A1A); // Near black
  static const Color primaryDark = Color(0xFF000000); // Pure black
  static const Color primaryLight = Color(0xFF4A4A4A); // Medium gray
  static const Color secondaryColor = Color(0xFF4A4A4A); // Medium gray
  static const Color accentColor = Color(0xFF6B6B6B); // Lighter gray
  static const Color successColor = Color(0xFF4CAF50); // Green - minimal accent
  static const Color errorColor = Color(0xFFF44336); // Red - minimal accent
  static const Color warningColor = Color(0xFFFF9800); // Orange - minimal accent
  static const Color backgroundColor = Color(0xFFF5F5F5); // Light gray
  static const Color surfaceColor = Colors.white;
  static const Color textPrimary = Color(0xFF1A1A1A); // High contrast black
  static const Color textSecondary = Color(0xFF6B6B6B); // Medium gray
  static const Color textTertiary = Color(0xFF9E9E9E); // Light gray
  
  // Base gradients for each page (used in parallax effect)
  static const List<LinearGradient> pageGradients = [
    // Chat (index 0) - Light gray gradient
    LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFF8F8F8), Color(0xFFF0F0F0), Color(0xFFE8E8E8)],
    ),
    // Friends (index 1) - Medium gray gradient
    LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFE8E8E8), Color(0xFFE0E0E0), Color(0xFFD8D8D8)],
    ),
    // Map (index 2) - Balanced gray gradient
    LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFE0E0E0), Color(0xFFD8D8D8), Color(0xFFD0D0D0)],
    ),
    // Meetings (index 3) - Darker gray gradient
    LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFD8D8D8), Color(0xFFD0D0D0), Color(0xFFC8C8C8)],
    ),
    // Profile (index 4) - Lightest gray gradient
    LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFFAFAFA), Color(0xFFF5F5F5), Color(0xFFF0F0F0)],
    ),
  ];
  
  // Primary gradient - Dark to light gray
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1A1A1A), Color(0xFF4A4A4A), Color(0xFF6B6B6B)],
  );
  
  // Accent gradient - Subtle gray variations
  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFE0E0E0), Color(0xFFD0D0D0), Color(0xFFC0C0C0)],
  );
  
  // Subtle gradient for backgrounds
  static const LinearGradient subtleGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFFFFFFF), Color(0xFFF5F5F5)],
  );
  
  // Helper method to get interpolated gradient between two page gradients
  static LinearGradient getInterpolatedGradient(double progress, int fromIndex, int toIndex) {
    if (fromIndex < 0 || fromIndex >= pageGradients.length ||
        toIndex < 0 || toIndex >= pageGradients.length) {
      return pageGradients[0];
    }
    
    final fromGradient = pageGradients[fromIndex];
    final toGradient = pageGradients[toIndex];
    
    // Interpolate between gradient colors
    Color interpolateColor(Color a, Color b, double t) {
      return Color.fromRGBO(
        (a.red + (b.red - a.red) * t).round(),
        (a.green + (b.green - a.green) * t).round(),
        (a.blue + (b.blue - a.blue) * t).round(),
        (a.alpha + (b.alpha - a.alpha) * t) / 255,
      );
    }
    
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        interpolateColor(fromGradient.colors[0], toGradient.colors[0], progress),
        interpolateColor(fromGradient.colors[1], toGradient.colors[1], progress),
        interpolateColor(fromGradient.colors[2], toGradient.colors[2], progress),
      ],
    );
  }

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
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      color: surfaceColor,
      shadowColor: Colors.black.withOpacity(0.1),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 0,
        shadowColor: Colors.black.withOpacity(0.15),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surfaceColor,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.withOpacity(0.2)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.withOpacity(0.2)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primaryColor, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: errorColor),
      ),
    ),
    textTheme: const TextTheme(
      displayLarge: TextStyle(color: textPrimary, fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: -0.5, height: 1.2),
      displayMedium: TextStyle(color: textPrimary, fontSize: 28, fontWeight: FontWeight.bold, letterSpacing: -0.5, height: 1.2),
      displaySmall: TextStyle(color: textPrimary, fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: -0.3, height: 1.3),
      headlineMedium: TextStyle(color: textPrimary, fontSize: 20, fontWeight: FontWeight.w600, letterSpacing: -0.2, height: 1.3),
      titleLarge: TextStyle(color: textPrimary, fontSize: 18, fontWeight: FontWeight.w600, letterSpacing: 0, height: 1.4),
      titleMedium: TextStyle(color: textPrimary, fontSize: 16, fontWeight: FontWeight.w600, letterSpacing: 0, height: 1.4),
      bodyLarge: TextStyle(color: textPrimary, fontSize: 16, height: 1.6, letterSpacing: 0.1),
      bodyMedium: TextStyle(color: textPrimary, fontSize: 14, height: 1.6, letterSpacing: 0.1),
      bodySmall: TextStyle(color: textSecondary, fontSize: 12, height: 1.5, letterSpacing: 0.1),
      labelLarge: TextStyle(color: textPrimary, fontSize: 14, fontWeight: FontWeight.w500, letterSpacing: 0.1, height: 1.4),
      labelMedium: TextStyle(color: textSecondary, fontSize: 12, fontWeight: FontWeight.w500, letterSpacing: 0.1, height: 1.4),
      labelSmall: TextStyle(color: textTertiary, fontSize: 11, fontWeight: FontWeight.w500, letterSpacing: 0.1, height: 1.4),
    ),
  );
}

