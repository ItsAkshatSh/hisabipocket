import 'package:flutter/material.dart';

extension ThemeExtensions on BuildContext {
  Color get backgroundColor => Theme.of(this).scaffoldBackgroundColor;
  Color get surfaceColor => Theme.of(this).colorScheme.surface;
  Color get onSurfaceColor => Theme.of(this).colorScheme.onSurface;
  Color get onSurfaceMutedColor => Theme.of(this).brightness == Brightness.dark
      ? Theme.of(this).colorScheme.onSurface.withOpacity(0.7)
      : Theme.of(this).colorScheme.onSurface.withOpacity(0.6);
  Color get borderColor => Theme.of(this).colorScheme.outline;
  Color get primaryColor => Theme.of(this).colorScheme.primary;
}


