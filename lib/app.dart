import 'package:flutter/material.dart';
import 'routes.dart';
import 'utils/theme.dart';
import 'utils/theme_controller.dart';
import 'screens/chat/chat_room_screen.dart';

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
          onGenerateRoute: (settings) {
            final name = settings.name ?? '';
            if (name.startsWith(Routes.chat)) {
              final uri = Uri.parse(name);

              final mergedArgs = <String, dynamic>{};
              final args = settings.arguments;
              if (args is Map) {
                mergedArgs.addAll(args.map((k, v) => MapEntry(k.toString(), v)));
              }

              mergedArgs.putIfAbsent('chatId', () => uri.queryParameters['chatId']);
              mergedArgs.putIfAbsent('otherUid', () => uri.queryParameters['otherUid']);
              mergedArgs.putIfAbsent('otherName', () => uri.queryParameters['otherName']);

              return MaterialPageRoute(
                settings: RouteSettings(name: Routes.chat, arguments: mergedArgs),
                builder: (_) => const ChatRoomScreen(),
              );
            }
            return null;
          },
        );
      },
    );
  }
}
