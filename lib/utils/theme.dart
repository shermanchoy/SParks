import 'package:flutter/material.dart';

ThemeData buildSParksTheme({required bool isDark}) {
  final base = ThemeData(
    useMaterial3: true,
    brightness: isDark ? Brightness.dark : Brightness.light,
    colorSchemeSeed: const Color(0xFFE53935),
  );

  final cs = base.colorScheme;

  final bg = isDark ? const Color(0xFF0E0E10) : const Color(0xFFF7F7F8);
  final surface = isDark ? const Color(0xFF141417) : Colors.white;
  final surface2 = isDark ? const Color(0xFF1B1B1F) : const Color(0xFFF2F3F6);
  final border = isDark ? const Color(0xFF2A2A2F) : const Color(0xFFE7E8EC);

  final textTheme = base.textTheme.copyWith(
    titleLarge: base.textTheme.titleLarge?.copyWith(
      fontWeight: FontWeight.w800,
      letterSpacing: -0.2,
    ),
    titleMedium: base.textTheme.titleMedium?.copyWith(
      fontWeight: FontWeight.w800,
      letterSpacing: -0.2,
    ),
    bodyLarge: base.textTheme.bodyLarge?.copyWith(height: 1.25),
    bodyMedium: base.textTheme.bodyMedium?.copyWith(height: 1.25),
    labelLarge: base.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
  );

  return base.copyWith(
    textTheme: textTheme,
    scaffoldBackgroundColor: bg,

    appBarTheme: AppBarTheme(
      // Default app bars should be readable in both themes.
      // Gradient app bars override these values explicitly.
      backgroundColor: surface,
      elevation: 0,
      foregroundColor: cs.onSurface,
      surfaceTintColor: Colors.transparent,
      iconTheme: IconThemeData(color: cs.onSurface),
      titleTextStyle: textTheme.titleLarge?.copyWith(
        color: cs.onSurface,
        fontWeight: FontWeight.w800,
      ),
    ),

    cardTheme: CardThemeData(
      color: surface,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(color: border),
      ),
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surface,
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
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),

    dialogTheme: DialogThemeData(
      backgroundColor: surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    ),

    chipTheme: base.chipTheme.copyWith(
      labelStyle: textTheme.labelLarge?.copyWith(fontSize: 12),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      shape: StadiumBorder(side: BorderSide(color: border)),
      backgroundColor: surface2,
      side: BorderSide(color: border),
    ),

    listTileTheme: base.listTileTheme.copyWith(
      iconColor: cs.onSurfaceVariant,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    ),

    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        textStyle: textTheme.labelLarge,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        textStyle: textTheme.labelLarge,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        side: BorderSide(color: border),
        textStyle: textTheme.labelLarge,
      ),
    ),

    navigationBarTheme: base.navigationBarTheme.copyWith(
      height: 68,
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
    ),
  );
}
