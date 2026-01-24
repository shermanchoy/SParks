import 'package:flutter/foundation.dart';

class ThemeController {
  final ValueNotifier<bool> isDark = ValueNotifier<bool>(false);

  void toggle() {
    isDark.value = !isDark.value;
  }

  void dispose() {
    isDark.dispose();
  }
}

final themeController = ThemeController();
