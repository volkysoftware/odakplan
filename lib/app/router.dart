import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/focus/focus_page.dart';
import '../features/progress/progress_page.dart';
import '../features/settings/settings_page.dart';
import '../features/today/today_page.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/today',
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/today',
                pageBuilder: (context, state) =>
                    const NoTransitionPage(child: TodayPage()),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/focus',
                pageBuilder: (context, state) =>
                    const NoTransitionPage(child: FocusPage()),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/progress',
                pageBuilder: (context, state) =>
                    const NoTransitionPage(child: ProgressPage()),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/settings',
                pageBuilder: (context, state) =>
                    const NoTransitionPage(child: SettingsPage()),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});

class MainShell extends StatelessWidget {
  const MainShell({super.key, required this.navigationShell});
  final StatefulNavigationShell navigationShell;

  static const _tabs = [
    _TabItem(label: 'Bugün', icon: Icons.today, route: '/today'),
    _TabItem(label: 'Odak', icon: Icons.timer, route: '/focus'),
    _TabItem(label: 'İlerleme', icon: Icons.insights, route: '/progress'),
    _TabItem(label: 'Ayarlar', icon: Icons.settings, route: '/settings'),
  ];

  void _onTap(BuildContext context, int index) {
    // Aynı sekmeye tekrar basılırsa o sekmenin root'una döndürmek için:
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = navigationShell.currentIndex;

    return Scaffold(
      // ✅ IndexedStack mantığını GoRouter zaten navigationShell içinde yapıyor
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (i) => _onTap(context, i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.today), label: 'Bugün'),
          NavigationDestination(icon: Icon(Icons.timer), label: 'Odak'),
          NavigationDestination(icon: Icon(Icons.insights), label: 'İlerleme'),
          NavigationDestination(icon: Icon(Icons.settings), label: 'Ayarlar'),
        ],
      ),
    );
  }
}

class _TabItem {
  const _TabItem({required this.label, required this.icon, required this.route});
  final String label;
  final IconData icon;
  final String route;
}
