import 'package:flutter/material.dart';
// Removed google_fonts dependency usage in favor of bundled Montserrat assets

class AppTheme {
  const AppTheme._();

  static const Color primaryRed = Color(0xFFBD0F0F);
  static const Color surfaceDark = Color(0xFF121212);
  static const Color onSurfaceMuted = Color(0xFFBDBDBD);

  static ThemeData get dark {
    const ColorScheme colorScheme = ColorScheme.dark(
      primary: primaryRed,
      surface: surfaceDark,
      onSurface: Colors.white,
    );

    return ThemeData(
      // ignore: deprecated_member_use
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: surfaceDark,
      fontFamily: 'Montserrat',
      textTheme: const TextTheme(
        displaySmall: TextStyle(fontWeight: FontWeight.w600),
        titleLarge: TextStyle(fontWeight: FontWeight.w600),
        bodyMedium: TextStyle(color: onSurfaceMuted),
      ).apply(bodyColor: Colors.white, displayColor: Colors.white),
      inputDecorationTheme: InputDecorationTheme(
        filled: false,
        hintStyle: const TextStyle(color: onSurfaceMuted),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0x33FFFFFF)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.white),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0x00FFFFFF),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
            side: const BorderSide(color: Color(0x33FFFFFF)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        ),
      ),
    );
  }

  static ThemeData get light {
    return ThemeData(
      // ignore: deprecated_member_use
      useMaterial3: true,
      colorScheme: const ColorScheme.light(),
      fontFamily: 'Montserrat',
    );
  }
}


