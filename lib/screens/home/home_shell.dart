import 'package:flutter/material.dart';

import '../../routes.dart';
import '../../services/auth_service.dart';
import '../../utils/home_tab.dart';
import '../../utils/theme_controller.dart';

import '../../widgets/animated_gradient_app_bar.dart';
import '../notifications/notifications_screens.dart';

import 'discover_screen.dart';
import 'matches_screen.dart';
import 'profile_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  @override
  void initState() {
    super.initState();
    HomeTab.bind((i) => setState(() => _index = i));
  }

  String _subtitleFor(int i) {
    if (i == 0) return 'Discover';
    if (i == 1) return 'Matches';
    return 'Profile';
  }

  void _openNotifications() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const NotificationsScreen()),
    );
  }

  Future<void> _logout() async {
    await AuthService().signOut();
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil(Routes.login, (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    final subtitle = _subtitleFor(_index);

    final screens = <Widget>[
      const DiscoverScreen(),
      const MatchesScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      appBar: AnimatedGradientAppBar(
        title: const SparksTitle(),
        subtitle: subtitle,
        actions: [
          ValueListenableBuilder<bool>(
            valueListenable: themeController.isDark,
            builder: (context, isDark, _) {
              return IconButton(
                tooltip: 'Toggle theme',
                icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
                onPressed: () => themeController.toggle(),
              );
            },
          ),
          IconButton(
            tooltip: 'Notifications',
            icon: const Icon(Icons.notifications_none),
            onPressed: _openNotifications,
          ),
          IconButton(
            tooltip: 'Logout',
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: screens[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.explore_outlined), label: 'Discover'),
          NavigationDestination(icon: Icon(Icons.favorite_border), label: 'Matches'),
          NavigationDestination(icon: Icon(Icons.person_outline), label: 'Profile'),
        ],
      ),
    );
  }
}
