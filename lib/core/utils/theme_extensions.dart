import 'package:flutter/material.dart';
import 'package:hisabi/core/constants/app_theme.dart';

extension ThemeExtensions on BuildContext {
  Color get backgroundColor => Theme.of(this).scaffoldBackgroundColor;
  Color get surfaceColor => Theme.of(this).colorScheme.surface;
  Color get surfaceVariantColor =>
      Theme.of(this).colorScheme.surfaceContainerHighest;
  Color get onSurfaceColor => Theme.of(this).colorScheme.onSurface;
  Color get onSurfaceMutedColor =>
      Theme.of(this).brightness == Brightness.dark ? AppColors.onSurfaceMuted : LightAppColors.onSurfaceMuted;
  Color get onSurfaceSubtleColor =>
      Theme.of(this).brightness == Brightness.dark ? AppColors.onSurfaceSubtle : LightAppColors.onSurfaceSubtle;
  Color get borderColor => Theme.of(this).colorScheme.outline;
  Color get primaryColor => Theme.of(this).colorScheme.primary;
  Color get primaryLightColor =>
      _adjustLightness(primaryColor, Theme.of(this).brightness == Brightness.dark ? 0.05 : 0.15);
  Color get primaryHoverColor =>
      _adjustLightness(primaryColor, Theme.of(this).brightness == Brightness.dark ? 0.03 : 0.10);
  Color get surfaceHoverColor =>
      Theme.of(this).brightness == Brightness.dark ? AppColors.hover : LightAppColors.hover;
  Color get surfaceHoverSubtleColor =>
      Theme.of(this).brightness == Brightness.dark ? AppColors.hoverSubtle : LightAppColors.hoverSubtle;
  Color get borderFocusColor =>
      Theme.of(this).brightness == Brightness.dark ? AppColors.borderFocus : LightAppColors.borderFocus;
  Color get successColor => AppColors.success;
  Color get warningColor => AppColors.warning;
  Color get errorColor => AppColors.error;

  Color _adjustLightness(Color color, double delta) {
    final hsl = HSLColor.fromColor(color);
    final lightness = (hsl.lightness + delta).clamp(0.0, 1.0);
    return hsl.withLightness(lightness).toColor();
  }
}

