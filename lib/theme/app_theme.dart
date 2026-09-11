import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// Clean iOS-inspired palette with system light / dark variants.
abstract final class AppColors {
  static const Color background = CupertinoDynamicColor.withBrightness(
    color: Color(0xFFF2F2F7),
    darkColor: Color(0xFF000000),
  );
  static const Color surface = CupertinoDynamicColor.withBrightness(
    color: Color(0xFFFFFFFF),
    darkColor: Color(0xFF1C1C1E),
  );
  static const Color surfaceSecondary = CupertinoDynamicColor.withBrightness(
    color: Color(0xFFE5E5EA),
    darkColor: Color(0xFF2C2C2E),
  );
  static const Color label = CupertinoDynamicColor.withBrightness(
    color: Color(0xFF1C1C1E),
    darkColor: Color(0xFFFFFFFF),
  );
  static const Color secondaryLabel = CupertinoDynamicColor.withBrightness(
    color: Color(0xFF8E8E93),
    darkColor: Color(0xFFAEAEB2),
  );
  static const Color tertiaryLabel = CupertinoDynamicColor.withBrightness(
    color: Color(0xFFAEAEB2),
    darkColor: Color(0xFF8E8E93),
  );
  static const Color separator = CupertinoDynamicColor.withBrightness(
    color: Color(0xFFC6C6C8),
    darkColor: Color(0xFF38383A),
  );
  static const Color keep = Color(0xFF34C759);
  static const Color delete = Color(0xFFFF3B30);
  static const Color accent = Color(0xFF007AFF);
  static const Color warning = Color(0xFFFF9500);
  static const Color fill = CupertinoDynamicColor.withBrightness(
    color: Color(0x33787880),
    darkColor: Color(0x52AEAEB2),
  );

  static Color resolve(BuildContext context, Color color) {
    return CupertinoDynamicColor.resolve(color, context);
  }
}

abstract final class AppTheme {
  static ThemeData get materialLight => _material(Brightness.light);
  static ThemeData get materialDark => _material(Brightness.dark);

  static ThemeData _material(Brightness brightness) {
    final dark = brightness == Brightness.dark;
    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: AppColors.accent,
        onPrimary: Colors.white,
        secondary: AppColors.keep,
        onSecondary: Colors.white,
        error: AppColors.delete,
        onError: Colors.white,
        surface: dark ? const Color(0xFF1C1C1E) : const Color(0xFFFFFFFF),
        onSurface: dark ? const Color(0xFFFFFFFF) : const Color(0xFF1C1C1E),
      ),
      scaffoldBackgroundColor: dark
          ? const Color(0xFF000000)
          : const Color(0xFFF2F2F7),
      dividerColor: dark ? const Color(0xFF38383A) : const Color(0xFFC6C6C8),
      appBarTheme: AppBarTheme(
        backgroundColor: dark
            ? const Color(0xFF000000)
            : const Color(0xFFF2F2F7),
        foregroundColor: dark
            ? const Color(0xFFFFFFFF)
            : const Color(0xFF1C1C1E),
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontFamily: '.SF Pro Text',
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: dark ? const Color(0xFFFFFFFF) : const Color(0xFF1C1C1E),
          letterSpacing: -0.4,
        ),
      ),
    );

    return base.copyWith(
      textTheme: base.textTheme.apply(
        fontFamily: '.SF Pro Text',
        bodyColor: dark ? const Color(0xFFFFFFFF) : const Color(0xFF1C1C1E),
        displayColor: dark ? const Color(0xFFFFFFFF) : const Color(0xFF1C1C1E),
      ),
      cupertinoOverrideTheme: cupertino(brightness),
    );
  }

  static CupertinoThemeData cupertino(Brightness brightness) {
    final dark = brightness == Brightness.dark;
    return CupertinoThemeData(
      brightness: brightness,
      primaryColor: AppColors.accent,
      barBackgroundColor: dark
          ? const Color(0xFF000000)
          : const Color(0xFFF2F2F7),
      scaffoldBackgroundColor: dark
          ? const Color(0xFF000000)
          : const Color(0xFFF2F2F7),
      textTheme: CupertinoTextThemeData(
        primaryColor: AppColors.accent,
        textStyle: TextStyle(
          fontFamily: '.SF Pro Text',
          fontSize: 17,
          color: dark ? const Color(0xFFFFFFFF) : const Color(0xFF1C1C1E),
        ),
        navTitleTextStyle: TextStyle(
          fontFamily: '.SF Pro Text',
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: dark ? const Color(0xFFFFFFFF) : const Color(0xFF1C1C1E),
        ),
        navLargeTitleTextStyle: TextStyle(
          fontFamily: '.SF Pro Display',
          fontSize: 34,
          fontWeight: FontWeight.w700,
          color: dark ? const Color(0xFFFFFFFF) : const Color(0xFF1C1C1E),
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}
