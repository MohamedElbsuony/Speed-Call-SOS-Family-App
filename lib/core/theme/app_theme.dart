import 'package:flutter/material.dart';

import '../../features/settings/domain/models/settings_model.dart';

class AppTheme {
  static ThemeData lightTheme(ColorScheme? dynamicColorScheme) {
    final colorScheme = dynamicColorScheme ??
        ColorScheme.fromSeed(
          seedColor: const Color(0xFF6750A4),
          brightness: Brightness.light,
        );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      brightness: Brightness.light,
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
      ),
    );
  }

  static ThemeData darkTheme(ColorScheme? dynamicColorScheme) {
    final colorScheme = dynamicColorScheme ??
        ColorScheme.fromSeed(
          seedColor: const Color(0xFFD0BCFF),
          brightness: Brightness.dark,
        );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF141218),
      cardTheme: CardThemeData(
        elevation: 2,
        color: const Color(0xFF211F26),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        backgroundColor: Color(0xFF141218),
        elevation: 0,
      ),
    );
  }

  static ThemeData amoledTheme() {
    const colorScheme = ColorScheme.dark(
      primary: Color(0xFFBB86FC),
      secondary: Color(0xFF03DAC6),
      surface: Color(0xFF121212),
      onPrimary: Colors.black,
      onSecondary: Colors.black,
      onSurface: Colors.white,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: Colors.black,
      cardTheme: CardThemeData(
        elevation: 0,
        color: const Color(0xFF121212),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFF2C2C2C)),
        ),
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        backgroundColor: Colors.black,
        elevation: 0,
      ),
    );
  }

  static ThemeData getTheme(AppThemeMode mode, ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
    switch (mode) {
      case AppThemeMode.light:
        return lightTheme(lightDynamic);
      case AppThemeMode.dark:
        return darkTheme(darkDynamic);
      case AppThemeMode.amoled:
        return amoledTheme();
      case AppThemeMode.system:
        return lightTheme(lightDynamic);
    }
  }

  static ThemeData getDarkTheme(AppThemeMode mode, ColorScheme? darkDynamic) {
    if (mode == AppThemeMode.amoled) {
      return amoledTheme();
    }
    return darkTheme(darkDynamic);
  }
}
