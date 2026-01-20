import 'package:flutter/material.dart';

ThemeData buildRedWhiteTheme() {
  const red = Color(0xFFE53935);

  return ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: red,
      brightness: Brightness.light,
    ),
    scaffoldBackgroundColor: Colors.white,
    appBarTheme: const AppBarTheme(
      backgroundColor: red,
      foregroundColor: Colors.white,
      centerTitle: true,
    ),
  );
}