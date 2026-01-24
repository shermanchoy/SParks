import 'package:flutter/material.dart';
import 'routes.dart';
import 'utils/theme.dart';
import 'utils/theme_controller.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: themeController.isDark,
      builder: (context, isDark, _) {
        return MaterialApp(
          title: 'sparks',
          debugShowCheckedModeBanner: false,

          theme: buildSParksTheme(isDark: false),
          darkTheme: buildSParksTheme(isDark: true),
          themeMode: isDark ? ThemeMode.dark : ThemeMode.light,

          initialRoute: Routes.splash,
          routes: buildRoutes(),
        );
      },
    );
  }
}
