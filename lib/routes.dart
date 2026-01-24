import 'package:flutter/material.dart';

import 'services/auth_service.dart';
import 'services/firestore_service.dart';

import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'screens/home/home_shell.dart';
import 'screens/onboarding/splashscreen.dart';

// ADD THIS
import 'screens/chat/chat_room_screen.dart';

class Routes {
  static const splash = '/';
  static const authGate = '/auth';
  static const login = '/login';
  static const register = '/register';
  static const onboarding = '/onboarding';
  static const home = '/home';

  // ADD THIS
  static const chat = '/chat';
}

Map<String, WidgetBuilder> buildRoutes() {
  return {
    Routes.authGate: (_) => const AuthGate(),
    Routes.login: (_) => const LoginScreen(),
    Routes.register: (_) => const RegisterScreen(),
    Routes.onboarding: (_) => const OnboardingScreen(),
    Routes.home: (_) => const HomeShell(),
    Routes.splash: (_) => const SplashScreen(),

    // ADD THIS
    Routes.chat: (_) => const ChatRoomScreen(),
  };
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = AuthService();
    final db = FirestoreService();

    return StreamBuilder(
      stream: auth.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = auth.currentUser;
        if (user == null) return const LoginScreen();

        return FutureBuilder<bool>(
          future: db.userProfileExists(user.uid),
          builder: (context, profSnap) {
            if (profSnap.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }
            final exists = profSnap.data ?? false;
            return exists ? const HomeShell() : const OnboardingScreen();
          },
        );
      },
    );
  }
}
