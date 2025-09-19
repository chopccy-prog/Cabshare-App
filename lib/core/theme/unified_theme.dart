// lib/core/theme/unified_theme.dart - Professional Theme for CabShare
import 'package:flutter/material.dart';

class CabShareTheme {
  // Primary Colors
  static const Color primaryBlue = Color(0xFF1565C0);
  static const Color primaryBlueDark = Color(0xFF0D47A1);
  static const Color primaryBlueLight = Color(0xFF42A5F5);
  
  // Accent Colors
  static const Color accentGreen = Color(0xFF2E7D32);
  static const Color accentOrange = Color(0xFFEF6C00);
  static const Color accentRed = Color(0xFFC62828);
  
  // Surface Colors
  static const Color surfaceWhite = Color(0xFFFFFFFF);
  static const Color surfaceGrey = Color(0xFFF8F9FA);
  static const Color surfaceLight = Color(0xFFF5F5F5);
  
  // Text Colors
  static const Color textDark = Color(0xFF212121);
  static const Color textMedium = Color(0xFF757575);
  static const Color textLight = Color(0xFF9E9E9E);
  
  // Border & Divider
  static const Color borderGrey = Color(0xFFE0E0E0);
  static const Color dividerGrey = Color(0xFFEEEEEE);
  
  // Spacing
  static const double spacing4 = 4.0;
  static const double spacing8 = 8.0;
  static const double spacing12 = 12.0;
  static const double spacing16 = 16.0;
  static const double spacing20 = 20.0;
  static const double spacing24 = 24.0;
  static const double spacing32 = 32.0;
  
  // Border Radius
  static const double radius8 = 8.0;
  static const double radius12 = 12.0;
  static const double radius16 = 16.0;
  static const double radius20 = 20.0;
  
  // Shadows
  static List<BoxShadow> get cardShadow => [
    BoxShadow(
      color: Colors.black.withOpacity(0.08),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ];
  
  static List<BoxShadow> get softShadow => [
    BoxShadow(
      color: Colors.black.withOpacity(0.05),
      blurRadius: 4,
      offset: const Offset(0, 1),
    ),
  ];

  // Card Decoration
  static BoxDecoration cardDecoration({Color? color}) => BoxDecoration(
    color: color ?? surfaceWhite,
    borderRadius: BorderRadius.circular(radius16),
    boxShadow: cardShadow,
  );
  
  // Input Decoration
  static InputDecoration inputDecoration({
    String? labelText,
    String? hintText,
    IconData? prefixIcon,
    Widget? suffixIcon,
    Color? prefixIconColor,
  }) => InputDecoration(
    labelText: labelText,
    hintText: hintText,
    prefixIcon: prefixIcon != null 
        ? Icon(prefixIcon, color: prefixIconColor ?? textMedium, size: 20) 
        : null,
    suffixIcon: suffixIcon,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(radius12),
      borderSide: const BorderSide(color: borderGrey),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(radius12),
      borderSide: const BorderSide(color: borderGrey),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(radius12),
      borderSide: const BorderSide(color: primaryBlue, width: 2),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(radius12),
      borderSide: const BorderSide(color: accentRed),
    ),
    filled: true,
    fillColor: surfaceWhite,
    contentPadding: const EdgeInsets.symmetric(
      horizontal: spacing16,
      vertical: spacing16,
    ),
    labelStyle: const TextStyle(color: textMedium),
    hintStyle: const TextStyle(color: textLight),
  );
  
  // Button Styles
  static ButtonStyle primaryButtonStyle() => ElevatedButton.styleFrom(
    backgroundColor: primaryBlue,
    foregroundColor: surfaceWhite,
    elevation: 2,
    shadowColor: primaryBlue.withOpacity(0.3),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radius16),
    ),
    padding: const EdgeInsets.symmetric(
      vertical: spacing16,
      horizontal: spacing24,
    ),
    textStyle: const TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w600,
    ),
  );
  
  static ButtonStyle secondaryButtonStyle() => ElevatedButton.styleFrom(
    backgroundColor: surfaceWhite,
    foregroundColor: primaryBlue,
    elevation: 1,
    side: const BorderSide(color: primaryBlue, width: 1.5),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radius16),
    ),
    padding: const EdgeInsets.symmetric(
      vertical: spacing16,
      horizontal: spacing24,
    ),
    textStyle: const TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w600,
    ),
  );
  
  static ButtonStyle successButtonStyle() => ElevatedButton.styleFrom(
    backgroundColor: accentGreen,
    foregroundColor: surfaceWhite,
    elevation: 2,
    shadowColor: accentGreen.withOpacity(0.3),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radius16),
    ),
    padding: const EdgeInsets.symmetric(
      vertical: spacing16,
      horizontal: spacing24,
    ),
    textStyle: const TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w600,
    ),
  );
  
  // Text Styles
  static const TextStyle h1 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: textDark,
    height: 1.2,
  );
  
  static const TextStyle h2 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: textDark,
    height: 1.3,
  );
  
  static const TextStyle h3 = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: textDark,
    height: 1.3,
  );
  
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: textDark,
    height: 1.4,
  );
  
  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: textMedium,
    height: 1.4,
  );
  
  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: textMedium,
    height: 1.4,
  );
  
  static const TextStyle caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: textLight,
    height: 1.2,
  );
  
  // App Bar Style
  static AppBarTheme get appBarTheme => const AppBarTheme(
    backgroundColor: surfaceWhite,
    foregroundColor: textDark,
    elevation: 0,
    centerTitle: true,
    titleTextStyle: TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.w600,
      color: textDark,
    ),
  );
  
  // Theme Data
  static ThemeData get lightTheme => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryBlue,
      brightness: Brightness.light,
    ),
    scaffoldBackgroundColor: surfaceGrey,
    appBarTheme: appBarTheme,
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: primaryButtonStyle(),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radius12),
      ),
      filled: true,
      fillColor: surfaceWhite,
    ),
    cardTheme: CardTheme(
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.08),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radius16),
      ),
    ),
  );
}

// Common Widgets
class ThemeCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final Color? color;
  
  const ThemeCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.color,
  });
  
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      decoration: CabShareTheme.cardDecoration(color: color),
      padding: padding ?? const EdgeInsets.all(CabShareTheme.spacing20),
      child: child,
    );
  }
}

class SectionHeader extends StatelessWidget {
  final String title;
  final IconData? icon;
  final Color? iconColor;
  final Widget? trailing;
  
  const SectionHeader({
    super.key,
    required this.title,
    this.icon,
    this.iconColor,
    this.trailing,
  });
  
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (icon != null) ...[
          Container(
            padding: const EdgeInsets.all(CabShareTheme.spacing8),
            decoration: BoxDecoration(
              color: (iconColor ?? CabShareTheme.primaryBlue).withOpacity(0.1),
              borderRadius: BorderRadius.circular(CabShareTheme.radius8),
            ),
            child: Icon(
              icon,
              color: iconColor ?? CabShareTheme.primaryBlue,
              size: 20,
            ),
          ),
          const SizedBox(width: CabShareTheme.spacing12),
        ],
        Expanded(
          child: Text(title, style: CabShareTheme.h3),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

class ThemeButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final IconData? icon;
  final ButtonStyle? style;
  final bool isLoading;
  final Size? size;
  
  const ThemeButton({
    super.key,
    required this.text,
    this.onPressed,
    this.icon,
    this.style,
    this.isLoading = false,
    this.size,
  });
  
  @override
  Widget build(BuildContext context) {
    Widget button = ElevatedButton.icon(
      onPressed: isLoading ? null : onPressed,
      style: style ?? CabShareTheme.primaryButtonStyle(),
      icon: isLoading 
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : Icon(icon ?? Icons.check, size: 20),
      label: Text(text),
    );
    
    if (size != null) {
      return SizedBox(
        width: size!.width,
        height: size!.height,
        child: button,
      );
    }
    
    return button;
  }
}