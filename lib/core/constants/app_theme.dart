import 'package:flutter/material.dart';

class AppColors {
  // Dark theme palette
  static const background = Color(0xFF0A0B0F);
  static const surface = Color(0xFF212834);
  static const surfaceVariant = Color(0xFF2A3342);
  static const onSurface = Color(0xFFE4E7EC);
  static const onSurfaceMuted = Color(0xFFB0B8C1);
  static const onSurfaceSubtle = Color(0xFF9B9A97);

  // Primary colors
  static const primary = Color(0xFF5355B9);
  static const primaryLight = Color(0xFF6B6DD6);
  static const primaryHover = Color(0xFF6B6DD6);

  // Borders
  static const border = Color(0xFF3A4354);
  static const borderFocus = Color(0xFF5355B9);

  // Status colors
  static const success = Color(0xFF10B981);
  static const error = Color(0xFFEF4444);
  static const warning = Color(0xFFF59E0B);

  // Hover states
  static const hover = Color(0xFF2A3342);
  static const hoverSubtle = Color(0xFF212834);
}

final ThemeData hisabiDarkTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,
  primaryColor: AppColors.primary,
  scaffoldBackgroundColor: AppColors.background,
  colorScheme: const ColorScheme.dark(
    primary: AppColors.primary,
    onPrimary: Colors.white,
    secondary: AppColors.primary,
    onSecondary: Colors.white,
    surface: AppColors.surface,
    onSurface: AppColors.onSurface,
    error: AppColors.error,
    onError: Colors.white,
    outline: AppColors.border,
    surfaceContainerHighest: AppColors.surfaceVariant,
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: AppColors.background,
    foregroundColor: AppColors.onSurface,
    elevation: 0,
    centerTitle: false,
    titleTextStyle: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w500,
      letterSpacing: -0.2,
      color: AppColors.onSurface,
    ),
  ),
  textTheme: const TextTheme(
    displayLarge: TextStyle(
      fontSize: 40,
      fontWeight: FontWeight.bold,
      letterSpacing: -1.5,
      height: 1.2,
      color: AppColors.onSurface,
    ),
    displayMedium: TextStyle(
      fontSize: 32,
      fontWeight: FontWeight.bold,
      letterSpacing: -1.0,
      height: 1.2,
      color: AppColors.onSurface,
    ),
    titleLarge: TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.5,
      height: 1.3,
      color: AppColors.onSurface,
    ),
    titleMedium: TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.w500,
      letterSpacing: -0.3,
      height: 1.3,
      color: AppColors.onSurface,
    ),
    bodyLarge: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.normal,
      height: 1.6,
      color: AppColors.onSurface,
    ),
    bodyMedium: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.normal,
      height: 1.6,
      color: AppColors.onSurfaceMuted,
    ),
    labelLarge: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      letterSpacing: 0,
      color: AppColors.onSurface,
    ),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      elevation: 0,
      shadowColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(6),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      minimumSize: const Size(0, 32),
      textStyle: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        letterSpacing: 0,
      ),
    ).copyWith(
      overlayColor: WidgetStateProperty.resolveWith<Color?>(
        (states) {
          if (states.contains(WidgetState.pressed)) {
            return Colors.white.withOpacity(0.1);
          }
          if (states.contains(WidgetState.hovered)) {
            return Colors.white.withOpacity(0.05);
          }
          return null;
        },
      ),
      backgroundColor: WidgetStateProperty.resolveWith<Color>(
        (states) {
          if (states.contains(WidgetState.hovered)) {
            return AppColors.primaryHover;
          }
          return AppColors.primary;
        },
      ),
    ),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: AppColors.onSurface,
      side: const BorderSide(color: AppColors.border, width: 1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(6),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      minimumSize: const Size(0, 32),
      textStyle: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
    ).copyWith(
      side: WidgetStateProperty.resolveWith<BorderSide>(
        (states) {
          if (states.contains(WidgetState.hovered)) {
            return const BorderSide(color: AppColors.borderFocus, width: 1);
          }
          return const BorderSide(color: AppColors.border, width: 1);
        },
      ),
    ),
  ),
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: AppColors.onSurface,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4),
      ),
      textStyle: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
    ).copyWith(
      overlayColor: WidgetStateProperty.resolveWith<Color?>(
        (states) =>
            states.contains(WidgetState.hovered) ? AppColors.hover : null,
      ),
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: AppColors.surface,
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(4),
      borderSide: const BorderSide(color: AppColors.border, width: 1),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(4),
      borderSide: const BorderSide(color: AppColors.border, width: 1),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(4),
      borderSide: const BorderSide(color: AppColors.borderFocus, width: 1.5),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(4),
      borderSide: const BorderSide(color: AppColors.error, width: 1),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(4),
      borderSide: const BorderSide(color: AppColors.error, width: 1.5),
    ),
    labelStyle: const TextStyle(
      color: AppColors.onSurfaceMuted,
      fontSize: 14,
      fontWeight: FontWeight.w400,
    ),
    hintStyle: const TextStyle(
      color: AppColors.onSurfaceSubtle,
      fontSize: 14,
      fontWeight: FontWeight.w400,
    ),
  ),
  cardTheme: CardThemeData(
    color: AppColors.background,
    elevation: 0,
    shadowColor: Colors.transparent,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(4),
      side: const BorderSide(
        color: AppColors.border,
        width: 1,
      ),
    ),
    margin: const EdgeInsets.symmetric(vertical: 4),
  ),
  dialogTheme: DialogThemeData(
    backgroundColor: AppColors.background,
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
      side: const BorderSide(
        color: AppColors.border,
        width: 1,
      ),
    ),
    titleTextStyle: const TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.w500,
      color: AppColors.onSurface,
    ),
    contentTextStyle: const TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      color: AppColors.onSurfaceMuted,
    ),
  ),
  bottomSheetTheme: const BottomSheetThemeData(
    backgroundColor: AppColors.background,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
    ),
    elevation: 0,
    modalElevation: 0,
  ),
  dividerTheme: const DividerThemeData(
    color: AppColors.border,
    thickness: 1,
    space: 1,
  ),
  switchTheme: SwitchThemeData(
    thumbColor: WidgetStateProperty.resolveWith<Color>(
      (states) => states.contains(WidgetState.selected)
          ? AppColors.primary
          : Colors.white,
    ),
    trackColor: WidgetStateProperty.resolveWith<Color>(
      (states) => states.contains(WidgetState.selected)
          ? AppColors.primary.withOpacity(0.3)
          : AppColors.border,
    ),
  ),
  checkboxTheme: CheckboxThemeData(
    fillColor: WidgetStateProperty.resolveWith<Color>(
      (states) => states.contains(WidgetState.selected)
          ? AppColors.primary
          : Colors.transparent,
    ),
    checkColor: WidgetStateProperty.all(Colors.white),
    side: const BorderSide(color: AppColors.border, width: 1.5),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(3),
    ),
  ),
  iconTheme: const IconThemeData(
    color: AppColors.onSurfaceMuted,
    size: 18,
  ),
  floatingActionButtonTheme: const FloatingActionButtonThemeData(
    backgroundColor: AppColors.primary,
    foregroundColor: Colors.white,
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(8)),
    ),
  ),
);

class LightAppColors {
  static const background = Color(0xFFFFFFFF);
  static const surface = Color(0xFFF5F7FA);
  static const surfaceVariant = Color(0xFFE8ECF1);
  static const onSurface = Color(0xFF1A1D29);
  static const onSurfaceMuted = Color(0xFF5A5F6F);
  static const onSurfaceSubtle = Color(0xFF8B8F9C);

  static const primary = Color(0xFF5355B9);
  static const primaryLight = Color(0xFF6B6DD6);
  static const primaryHover = Color(0xFF6B6DD6);

  static const border = Color(0xFFE1E5E9);
  static const borderFocus = Color(0xFF5355B9);

  static const success = Color(0xFF10B981);
  static const error = Color(0xFFEF4444);
  static const warning = Color(0xFFF59E0B);

  static const hover = Color(0xFFF0F2F5);
  static const hoverSubtle = Color(0xFFF5F7FA);
}

final ThemeData hisabiLightTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.light,
  primaryColor: LightAppColors.primary,
  scaffoldBackgroundColor: LightAppColors.background,
  colorScheme: const ColorScheme.light(
    primary: LightAppColors.primary,
    onPrimary: Colors.white,
    secondary: LightAppColors.primary,
    onSecondary: Colors.white,
    surface: LightAppColors.surface,
    onSurface: LightAppColors.onSurface,
    error: LightAppColors.error,
    onError: Colors.white,
    outline: LightAppColors.border,
    surfaceContainerHighest: LightAppColors.surfaceVariant,
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: LightAppColors.background,
    foregroundColor: LightAppColors.onSurface,
    elevation: 0,
    centerTitle: false,
    titleTextStyle: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w500,
      letterSpacing: -0.2,
      color: LightAppColors.onSurface,
    ),
  ),
  textTheme: const TextTheme(
    displayLarge: TextStyle(
      fontSize: 40,
      fontWeight: FontWeight.bold,
      letterSpacing: -1.5,
      height: 1.2,
      color: LightAppColors.onSurface,
    ),
    displayMedium: TextStyle(
      fontSize: 32,
      fontWeight: FontWeight.bold,
      letterSpacing: -1.0,
      height: 1.2,
      color: LightAppColors.onSurface,
    ),
    titleLarge: TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.5,
      height: 1.3,
      color: LightAppColors.onSurface,
    ),
    titleMedium: TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.w500,
      letterSpacing: -0.3,
      height: 1.3,
      color: LightAppColors.onSurface,
    ),
    bodyLarge: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.normal,
      height: 1.6,
      color: LightAppColors.onSurface,
    ),
    bodyMedium: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.normal,
      height: 1.6,
      color: LightAppColors.onSurfaceMuted,
    ),
    labelLarge: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      letterSpacing: 0,
      color: LightAppColors.onSurface,
    ),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: LightAppColors.primary,
      foregroundColor: Colors.white,
      elevation: 0,
      shadowColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(6),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      minimumSize: const Size(0, 32),
      textStyle: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        letterSpacing: 0,
      ),
    ).copyWith(
      overlayColor: WidgetStateProperty.resolveWith<Color?>(
        (states) {
          if (states.contains(WidgetState.pressed)) {
            return Colors.white.withOpacity(0.1);
          }
          if (states.contains(WidgetState.hovered)) {
            return Colors.white.withOpacity(0.05);
          }
          return null;
        },
      ),
      backgroundColor: WidgetStateProperty.resolveWith<Color>(
        (states) {
          if (states.contains(WidgetState.hovered)) {
            return LightAppColors.primaryHover;
          }
          return LightAppColors.primary;
        },
      ),
    ),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: LightAppColors.onSurface,
      side: const BorderSide(color: LightAppColors.border, width: 1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(6),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      minimumSize: const Size(0, 32),
      textStyle: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
    ).copyWith(
      side: WidgetStateProperty.resolveWith<BorderSide>(
        (states) {
          if (states.contains(WidgetState.hovered)) {
            return const BorderSide(color: LightAppColors.borderFocus, width: 1);
          }
          return const BorderSide(color: LightAppColors.border, width: 1);
        },
      ),
    ),
  ),
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: LightAppColors.onSurface,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4),
      ),
      textStyle: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
    ).copyWith(
      overlayColor: WidgetStateProperty.resolveWith<Color?>(
        (states) =>
            states.contains(WidgetState.hovered) ? LightAppColors.hover : null,
      ),
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: LightAppColors.surface,
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(4),
      borderSide: const BorderSide(color: LightAppColors.border, width: 1),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(4),
      borderSide: const BorderSide(color: LightAppColors.border, width: 1),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(4),
      borderSide: const BorderSide(color: LightAppColors.borderFocus, width: 1.5),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(4),
      borderSide: const BorderSide(color: LightAppColors.error, width: 1),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(4),
      borderSide: const BorderSide(color: LightAppColors.error, width: 1.5),
    ),
    labelStyle: const TextStyle(
      color: LightAppColors.onSurfaceMuted,
      fontSize: 14,
      fontWeight: FontWeight.w400,
    ),
    hintStyle: const TextStyle(
      color: LightAppColors.onSurfaceSubtle,
      fontSize: 14,
      fontWeight: FontWeight.w400,
    ),
  ),
  cardTheme: CardThemeData(
    color: LightAppColors.background,
    elevation: 0,
    shadowColor: Colors.transparent,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(4),
      side: const BorderSide(
        color: LightAppColors.border,
        width: 1,
      ),
    ),
    margin: const EdgeInsets.symmetric(vertical: 4),
  ),
  dialogTheme: DialogThemeData(
    backgroundColor: LightAppColors.background,
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
      side: const BorderSide(
        color: LightAppColors.border,
        width: 1,
      ),
    ),
    titleTextStyle: const TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.w500,
      color: LightAppColors.onSurface,
    ),
    contentTextStyle: const TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      color: LightAppColors.onSurfaceMuted,
    ),
  ),
  bottomSheetTheme: const BottomSheetThemeData(
    backgroundColor: LightAppColors.background,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
    ),
    elevation: 0,
    modalElevation: 0,
  ),
  dividerTheme: const DividerThemeData(
    color: LightAppColors.border,
    thickness: 1,
    space: 1,
  ),
  switchTheme: SwitchThemeData(
    thumbColor: WidgetStateProperty.resolveWith<Color>(
      (states) => states.contains(WidgetState.selected)
          ? LightAppColors.primary
          : Colors.white,
    ),
    trackColor: WidgetStateProperty.resolveWith<Color>(
      (states) => states.contains(WidgetState.selected)
          ? LightAppColors.primary.withOpacity(0.3)
          : LightAppColors.border,
    ),
  ),
  checkboxTheme: CheckboxThemeData(
    fillColor: WidgetStateProperty.resolveWith<Color>(
      (states) => states.contains(WidgetState.selected)
          ? LightAppColors.primary
          : Colors.transparent,
    ),
    checkColor: WidgetStateProperty.all(Colors.white),
    side: const BorderSide(color: LightAppColors.border, width: 1.5),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(3),
    ),
  ),
  iconTheme: const IconThemeData(
    color: LightAppColors.onSurfaceMuted,
    size: 18,
  ),
  floatingActionButtonTheme: const FloatingActionButtonThemeData(
    backgroundColor: LightAppColors.primary,
    foregroundColor: Colors.white,
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(8)),
    ),
  ),
);
