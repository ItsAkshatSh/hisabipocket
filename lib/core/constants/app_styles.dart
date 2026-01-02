import 'package:flutter/material.dart';
import 'package:hisabi/core/constants/app_theme.dart';

/// A utility class for easily accessing themed text styles.
///
/// Notion-inspired: thin, quiet typography that doesn't compete with content.
class AppText {
  static const TextStyle display = TextStyle(
    fontSize: 40,
    fontWeight: FontWeight.w400,
    letterSpacing: -1.5,
    height: 1.2,
    color: AppColors.onSurface,
  );

  static const TextStyle headline = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w400,
    letterSpacing: -1.0,
    height: 1.2,
    color: AppColors.onSurface,
  );

  static const TextStyle title = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w400,
    letterSpacing: -0.5,
    height: 1.3,
    color: AppColors.onSurface,
  );

  static const TextStyle subTitle = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w400,
    letterSpacing: -0.3,
    height: 1.3,
    color: AppColors.onSurface,
  );

  static const TextStyle body = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.6,
    color: AppColors.onSurface,
  );

  static const TextStyle bodyMuted = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.6,
    color: AppColors.onSurfaceMuted,
  );

  static const TextStyle label = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    letterSpacing: 0,
    color: AppColors.onSurface,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.onSurfaceSubtle,
  );
}
