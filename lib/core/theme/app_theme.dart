// lib/core/theme/app_theme.dart - PROFESSIONAL UNIFIED THEME
import 'package:flutter/material.dart';

class AppTheme {
  // Brand Colors - Professional Blue Palette
  static const Color primaryBlue = Color(0xFF1E40AF);        // Deep blue
  static const Color primaryBlueLight = Color(0xFF3B82F6);   // Lighter blue
  static const Color primaryBlueDark = Color(0xFF1E3A8A);    // Darker blue
  
  // Secondary Colors
  static const Color accentOrange = Color(0xFFF59E0B);       // Amber
  static const Color accentGreen = Color(0xFF10B981);        // Emerald
  static const Color accentRed = Color(0xFFEF4444);          // Red
  
  // Neutral Colors
  static const Color backgroundLight = Color(0xFFFFFFFF);    // Pure white
  static const Color surfaceLight = Color(0xFFFAFAFA);       // Off white
  static const Color surfaceGrey = Color(0xFFF3F4F6);        // Light grey
  
  // Text Colors
  static const Color textPrimary = Color(0xFF111827);        // Dark grey
  static const Color textSecondary = Color(0xFF6B7280);      // Medium grey
  static const Color textMuted = Color(0xFF9CA3AF);          // Light grey
  
  // Status Colors
  static const Color statusSuccess = Color(0xFF059669);      // Green
  static const Color statusWarning = Color(0xFFD97706);      // Orange
  static const Color statusError = Color(0xFFDC2626);        // Red
  static const Color statusInfo = Color(0xFF2563EB);         // Blue
  
  // Spacing Constants
  static const double spaceXS = 4.0;
  static const double spaceSM = 8.0;
  static const double spaceMD = 12.0;
  static const double spaceLG = 16.0;
  static const double spaceXL = 20.0;
  static const double space2XL = 24.0;
  static const double space3XL = 32.0;
  static const double space4XL = 48.0;
  
  // Radius Constants
  static const double radiusSM = 8.0;
  static const double radiusMD = 12.0;
  static const double radiusLG = 16.0;
  static const double radiusXL = 20.0;
  
  // Text Styles
  static const TextStyle headingLarge = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: textPrimary,
    height: 1.2,
  );
  
  static const TextStyle headingMedium = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: textPrimary,
    height: 1.25,
  );
  
  static const TextStyle headingSmall = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: textPrimary,
    height: 1.3,
  );
  
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: textPrimary,
    height: 1.5,
  );
  
  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: textSecondary,
    height: 1.45,
  );
  
  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: textMuted,
    height: 1.4,
  );
  
  static const TextStyle labelLarge = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: textPrimary,
    height: 1.4,
  );
  
  static const TextStyle labelMedium = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: textSecondary,
    height: 1.35,
  );

  // Main Theme
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryBlue,
        brightness: Brightness.light,
        primary: primaryBlue,
        onPrimary: Colors.white,
        secondary: accentOrange,
        onSecondary: Colors.white,
        surface: backgroundLight,
        onSurface: textPrimary,
        error: accentRed,
        onError: Colors.white,
      ),
      
      // AppBar Theme
      appBarTheme: const AppBarTheme(
        backgroundColor: backgroundLight,
        foregroundColor: textPrimary,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        titleTextStyle: headingMedium,
      ),
      
      // Card Theme
      cardTheme: CardTheme(
        color: backgroundLight,
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMD),
        ),
      ),
      
      // Elevated Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryBlue,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMD),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      
      // Outlined Button Theme
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryBlue,
          minimumSize: const Size(double.infinity, 48),
          side: const BorderSide(color: primaryBlue, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMD),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      
      // Text Button Theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryBlue,
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      
      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceLight,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMD),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMD),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMD),
          borderSide: const BorderSide(color: primaryBlue, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMD),
          borderSide: const BorderSide(color: accentRed, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: spaceLG,
          vertical: spaceMD,
        ),
        labelStyle: const TextStyle(
          color: textSecondary,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        hintStyle: const TextStyle(
          color: textMuted,
          fontSize: 14,
        ),
      ),
      
      // Bottom Navigation Bar Theme
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: backgroundLight,
        selectedItemColor: primaryBlue,
        unselectedItemColor: textMuted,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      
      // Scaffold Theme
      scaffoldBackgroundColor: surfaceLight,
      
      // Text Theme
      textTheme: const TextTheme(
        headlineLarge: headingLarge,
        headlineMedium: headingMedium,
        headlineSmall: headingSmall,
        bodyLarge: bodyLarge,
        bodyMedium: bodyMedium,
        bodySmall: bodySmall,
        labelLarge: labelLarge,
        labelMedium: labelMedium,
      ),
    );
  }

  // Utility Methods
  static BoxDecoration cardDecoration({
    Color? color,
    double? elevation,
    BorderRadius? borderRadius,
  }) {
    return BoxDecoration(
      color: color ?? backgroundLight,
      borderRadius: borderRadius ?? BorderRadius.circular(radiusMD),
      boxShadow: elevation != null && elevation > 0 ? [
        BoxShadow(
          color: Colors.black.withOpacity(0.1),
          blurRadius: elevation * 2,
          offset: Offset(0, elevation),
        ),
      ] : null,
    );
  }
  
  static BoxDecoration primaryGradient({BorderRadius? borderRadius}) {
    return BoxDecoration(
      gradient: const LinearGradient(
        colors: [primaryBlue, primaryBlueLight],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: borderRadius ?? BorderRadius.circular(radiusMD),
    );
  }
  
  static Color statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
      case 'success':
      case 'completed':
        return statusSuccess;
      case 'pending':
      case 'warning':
        return statusWarning;
      case 'cancelled':
      case 'failed':
      case 'error':
        return statusError;
      case 'info':
      default:
        return statusInfo;
    }
  }
  
  static IconData statusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
      case 'success':
      case 'completed':
        return Icons.check_circle;
      case 'pending':
      case 'warning':
        return Icons.schedule;
      case 'cancelled':
      case 'failed':
      case 'error':
        return Icons.cancel;
      case 'info':
      default:
        return Icons.info;
    }
  }
}