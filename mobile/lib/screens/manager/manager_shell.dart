import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';

class ManagerShell extends StatelessWidget {
  const ManagerShell({super.key, required this.child, required this.location});
  final Widget child;
  final String location;

  @override
  Widget build(BuildContext context) {
    final idx = switch (location) {
      String s when s.startsWith('/manager/employees') => 1,
      String s when s.startsWith('/manager/attendance') => 2,
      String s when s.startsWith('/manager/analytics')  => 3,
      String s when s.startsWith('/manager/settings')   => 4,
      _ => 0,
    };

    return Scaffold(
      body: child,
      // Face-scan FAB appears only on the Attendance tab
      floatingActionButton: location.startsWith('/manager/attendance')
          ? FloatingActionButton.extended(
              onPressed: () => context.push('/manager/face-attendance'),
              icon: const Icon(Icons.face_retouching_natural_rounded),
              label: const Text('Face Scan',
                  style: TextStyle(fontWeight: FontWeight.w700)),
              backgroundColor: AppColors.indigo,
              foregroundColor: Colors.white,
            )
          : null,
      bottomNavigationBar: Column(mainAxisSize: MainAxisSize.min, children: [
        _ThemeToggleBar(),
        NavigationBar(
        selectedIndex: idx,
        onDestinationSelected: (i) {
          final routes = [
            '/manager', '/manager/employees',
            '/manager/attendance', '/manager/analytics', '/manager/settings'
          ];
          context.go(routes[i]);
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard_rounded),       label: 'Dashboard'),
          NavigationDestination(icon: Icon(Icons.group_rounded),           label: 'Employees'),
          NavigationDestination(icon: Icon(Icons.calendar_month_rounded),  label: 'Attendance'),
          NavigationDestination(icon: Icon(Icons.bar_chart_rounded),       label: 'Analytics'),
          NavigationDestination(icon: Icon(Icons.settings_rounded),        label: 'Settings'),
        ],
      ),
      ]),
    );
  }
}

class _ThemeToggleBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: AppTheme.themeNotifier,
      builder: (_, mode, __) {
        final isDark = mode == ThemeMode.dark;
        return GestureDetector(
          onTap: () => AppTheme.themeNotifier.value =
              isDark ? ThemeMode.light : ThemeMode.dark,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            color: Theme.of(context).navigationBarTheme.backgroundColor,
            child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
              Icon(
                isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                size: 16,
                color: isDark ? Colors.white54 : const Color(0xFF9CA3AF),
              ),
              const SizedBox(width: 6),
              Text(
                isDark ? 'Light mode' : 'Dark mode',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.white54 : const Color(0xFF9CA3AF),
                ),
              ),
            ]),
          ),
        );
      },
    );
  }
}
