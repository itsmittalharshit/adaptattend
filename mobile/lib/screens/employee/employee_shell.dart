import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';

class EmployeeShell extends StatelessWidget {
  const EmployeeShell({super.key, required this.child, required this.location});
  final Widget child;
  final String location;

  @override
  Widget build(BuildContext context) {
    final idx = location.startsWith('/employee/history') ? 1 : 0;
    return Scaffold(
      body: child,
      bottomNavigationBar: Column(mainAxisSize: MainAxisSize.min, children: [
        _ThemeToggleBar(),
        NavigationBar(
          selectedIndex: idx,
          onDestinationSelected: (i) {
            context.go(i == 0 ? '/employee' : '/employee/history');
          },
          destinations: const [
            NavigationDestination(icon: Icon(Icons.home_rounded),          label: 'Today'),
            NavigationDestination(icon: Icon(Icons.calendar_month_rounded), label: 'History'),
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
