import 'package:flutter/material.dart';
import 'routes.dart';
import 'utils/theme.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HeartSPace',
      debugShowCheckedModeBanner: false,
      theme: buildRedWhiteTheme(),
      initialRoute: Routes.splash,
      routes: buildRoutes(),
    );
  }
}
