import 'package:flutter/material.dart';

ThemeData buildSParksTheme({required bool isDark}) {
  final base = ThemeData(
    useMaterial3: true,
    brightness: isDark ? Brightness.dark : Brightness.light,
    colorSchemeSeed: const Color(0xFFE53935),
  );

  final bg = isDark ? const Color(0xFF0F0F10) : const Color(0xFFF7F7F7);
  final card = isDark ? const Color(0xFF1A1A1C) : Colors.white;
  final border = isDark ? const Color(0xFF2A2A2D) : const Color(0xFFF0F0F0);
  final textOnGradient = Colors.white;

  return base.copyWith(
    scaffoldBackgroundColor: bg,

    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      foregroundColor: textOnGradient,
      surfaceTintColor: Colors.transparent,
      iconTheme: const IconThemeData(color: Colors.white),
      titleTextStyle: base.textTheme.titleLarge?.copyWith(
        color: Colors.white,
        fontWeight: FontWeight.w800,
      ),
    ),

    cardTheme: CardThemeData(
      color: card,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: border),
      ),
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: card,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: Color(0xFFE53935), width: 2),
      ),
    ),
  );
}
