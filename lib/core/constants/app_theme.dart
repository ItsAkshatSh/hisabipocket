import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hisabi/features/settings/providers/settings_provider.dart';

class AppTheme {
  // Expressive Shape Tokens - More Rounded for Fluidity
  static const double shapeCornerExtraSmall = 8.0;
  static const double shapeCornerSmall = 12.0;
  static const double shapeCornerMedium = 16.0;
  static const double shapeCornerLarge = 20.0;
  static const double shapeCornerExtraLarge = 28.0;

  static ThemeData getTheme(AppThemeSelection selection, Brightness brightness, ColorScheme? dynamicColorScheme) {
    ColorScheme colorScheme;
    
    // If "Classic" is selected and we have a dynamic color scheme (Material You), use it!
    if (selection == AppThemeSelection.classic && dynamicColorScheme != null) {
      colorScheme = dynamicColorScheme;
    } else {
      colorScheme = _getColorScheme(selection, brightness);
    }

    final baseTheme = brightness == Brightness.dark ? ThemeData.dark() : ThemeData.light();
    
    return baseTheme.copyWith(
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.surface,
      
      textTheme: GoogleFonts.plusJakartaSansTextTheme(baseTheme.textTheme).copyWith(
        displayLarge: GoogleFonts.plusJakartaSans(
          fontWeight: FontWeight.w800,
          letterSpacing: -1.5,
          color: colorScheme.onSurface,
        ),
        headlineLarge: GoogleFonts.plusJakartaSans(
          fontWeight: FontWeight.w900,
          letterSpacing: -1.5,
          fontSize: 38,
          color: colorScheme.onSurface,
        ),
        headlineMedium: GoogleFonts.plusJakartaSans(
          fontWeight: FontWeight.w900,
          letterSpacing: -1.0,
          fontSize: 32,
          color: colorScheme.onSurface,
        ),
        titleLarge: GoogleFonts.plusJakartaSans(
          fontWeight: FontWeight.w800,
          letterSpacing: -0.5,
          fontSize: 32,
          color: colorScheme.onSurface,
        ),
      ),

      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(shapeCornerExtraLarge),
          side: BorderSide(
            color: colorScheme.outlineVariant.withOpacity(0.5),
            width: 1,
          ),
        ),
        color: colorScheme.surfaceContainerLow,
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest.withOpacity(0.3),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        contentPadding: const EdgeInsets.all(20),
      ),

      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.plusJakartaSans(
          color: colorScheme.onSurface,
          fontSize: 48,
          fontWeight: FontWeight.w900,
          letterSpacing: -1.0,
        ),
        iconTheme: IconThemeData(color: colorScheme.onSurface),
      ),

      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colorScheme.primaryContainer,
        foregroundColor: colorScheme.onPrimaryContainer,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        elevation: 6,
      ),
    );
  }

  static ColorScheme _getColorScheme(AppThemeSelection selection, Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    
    switch (selection) {
      case AppThemeSelection.midnight:
        return ColorScheme.fromSeed(
          seedColor: const Color(0xFF1E293B),
          brightness: brightness,
          primary: isDark ? const Color(0xFF60A5FA) : const Color(0xFF3B82F6),
          secondary: isDark ? const Color(0xFF8B5CF6) : const Color(0xFF6366F1),
          tertiary: isDark ? const Color(0xFFEC4899) : const Color(0xFFEF4444),
          surface: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
        );
      case AppThemeSelection.forest:
        return ColorScheme.fromSeed(
          seedColor: const Color(0xFF064E3B),
          brightness: brightness,
          primary: isDark ? const Color(0xFF34D399) : const Color(0xFF059669),
          surface: isDark ? const Color(0xFF022C22) : const Color(0xFFF0FDF4),
        );
      case AppThemeSelection.sunset:
        return ColorScheme.fromSeed(
          seedColor: const Color(0xFF7C2D12),
          brightness: brightness,
          primary: isDark ? const Color(0xFFF97316) : const Color(0xFFDC2626),
          secondary: isDark ? const Color(0xFFF59E0B) : const Color(0xFFEA580C),
          tertiary: isDark ? const Color(0xFFFACC15) : const Color(0xFFD97706),
          surface: isDark ? const Color(0xFF451A03) : const Color(0xFFFFFBEB),
        );
      case AppThemeSelection.lavender:
        return ColorScheme.fromSeed(
          seedColor: const Color(0xFF4C1D95),
          brightness: brightness,
          primary: isDark ? const Color(0xFFA78BFA) : const Color(0xFF7C3AED),
          surface: isDark ? const Color(0xFF0C0A09) : const Color(0xFFF5F3FF),
        );
      case AppThemeSelection.monochrome:
        return ColorScheme.fromSeed(
          seedColor: Colors.grey,
          brightness: brightness,
          primary: isDark ? Colors.white : Colors.black,
          surface: isDark ? const Color(0xFF121212) : Colors.white,
        );
      case AppThemeSelection.classic:
        return ColorScheme.fromSeed(
          seedColor: Colors.grey,
          brightness: brightness,
          primary: isDark ? Colors.white : Colors.black,
          secondary: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
          tertiary: isDark ? Colors.grey.shade300 : Colors.grey.shade600,
          surface: isDark ? Colors.black : Colors.white,
          surfaceContainerHighest: isDark ? Colors.grey.shade900 : Colors.grey.shade100,
          surfaceContainerLow: isDark ? Colors.grey.shade800 : Colors.grey.shade50,
          onSurface: isDark ? Colors.white : Colors.black,
          onPrimary: isDark ? Colors.black : Colors.white,
        );
    }
  }
}

class AppColors {
  static const primary = Color(0xFF6366F1);
  static const success = Color(0xFF10B981);
  static const error = Color(0xFFEF4444);
  static const warning = Color(0xFFF59E0B);
  static const onSurface = Color(0xFFE2E8F0);
  static const onSurfaceMuted = Color(0xFFB0B8C1);
  static const onSurfaceSubtle = Color(0xFF9B9A97);
  static const hover = Color(0xFF2A3342);
  static const hoverSubtle = Color(0xFF212834);
  static const borderFocus = Color(0xFF6366F1);
  static const border = Color(0xFF334155);
  static const background = Color(0xFF212834);
  static const surface = Color(0xFF212834);
}

class LightAppColors {
  static const primary = Color(0xFF6366F1);
  static const success = Color(0xFF10B981);
  static const error = Color(0xFFEF4444);
  static const warning = Color(0xFFF59E0B);
  static const onSurface = Color(0xFF1E293B);
  static const onSurfaceMuted = Color(0xFF5A5F6F);
  static const onSurfaceSubtle = Color(0xFF8B8F9C);
  static const hover = Color(0xFFF0F2F5);
  static const hoverSubtle = Color(0xFFF5F7FA);
  static const borderFocus = Color(0xFF6366F1);
  static const border = Color(0xFFE2E8F0);
  static const background = Color(0xFFF5F7FA);
  static const surface = Color(0xFFF5F7FA);
}
