import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// Clean iOS-inspired palette. Soft light surfaces, restrained accent.
abstract final class AppColors {
  static const Color background = Color(0xFFF2F2F7);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceSecondary = Color(0xFFE5E5EA);
  static const Color label = Color(0xFF1C1C1E);
  static const Color secondaryLabel = Color(0xFF8E8E93);
  static const Color tertiaryLabel = Color(0xFFAEAEB2);
  static const Color separator = Color(0xFFC6C6C8);
  static const Color keep = Color(0xFF34C759);
  static const Color delete = Color(0xFFFF3B30);
  static const Color accent = Color(0xFF007AFF);
  static const Color warning = Color(0xFFFF9500);
  static const Color fill = Color(0x33787880);
}

abstract final class AppTheme {
  static ThemeData get material {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: AppColors.accent,
        secondary: AppColors.keep,
        error: AppColors.delete,
        surface: AppColors.surface,
        onSurface: AppColors.label,
      ),
      scaffoldBackgroundColor: AppColors.background,
      dividerColor: AppColors.separator,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.label,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontFamily: '.SF Pro Text',
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: AppColors.label,
          letterSpacing: -0.4,
        ),
      ),
    );

    return base.copyWith(
      textTheme: base.textTheme.apply(
        fontFamily: '.SF Pro Text',
        bodyColor: AppColors.label,
        displayColor: AppColors.label,
      ),
      cupertinoOverrideTheme: const CupertinoThemeData(
        brightness: Brightness.light,
        primaryColor: AppColors.accent,
        barBackgroundColor: AppColors.background,
        scaffoldBackgroundColor: AppColors.background,
        textTheme: CupertinoTextThemeData(
          primaryColor: AppColors.accent,
          textStyle: TextStyle(
            fontFamily: '.SF Pro Text',
            fontSize: 17,
            color: AppColors.label,
          ),
          navTitleTextStyle: TextStyle(
            fontFamily: '.SF Pro Text',
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: AppColors.label,
          ),
          navLargeTitleTextStyle: TextStyle(
            fontFamily: '.SF Pro Display',
            fontSize: 34,
            fontWeight: FontWeight.w700,
            color: AppColors.label,
            letterSpacing: 0.4,
          ),
        ),
      ),
    );
  }

  static CupertinoThemeData get cupertino => const CupertinoThemeData(
        brightness: Brightness.light,
        primaryColor: AppColors.accent,
        barBackgroundColor: AppColors.background,
        scaffoldBackgroundColor: AppColors.background,
      );
}
