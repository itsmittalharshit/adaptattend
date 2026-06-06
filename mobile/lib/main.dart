import 'dart:async' show unawaited;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import 'data/database.dart';
import 'services/auth_service.dart';
import 'services/seed_service.dart';
import 'theme/app_theme.dart';

// Screens
import 'screens/auth/login_screen.dart';
import 'screens/manager/manager_shell.dart';
import 'screens/manager/dashboard_screen.dart';
import 'screens/manager/employees_screen.dart';
import 'screens/manager/attendance_screen.dart';
import 'screens/manager/analytics_screen.dart';
import 'screens/manager/settings_screen.dart';
import 'screens/manager/face_attendance_screen.dart';
import 'screens/employee/employee_shell.dart';
import 'screens/employee/mark_attendance_screen.dart';
import 'screens/employee/history_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock to portrait
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // System UI style
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Color(0xFF0A0A14),
  ));

  // Seed demo data on first launch
  await seedDemoData();

  // Pre-enroll demo employee faces from bundled assets (one-time, ~2 s)
  unawaited(seedFaceEmbeddings());

  // Try to restore previous session
  final hasSession = await AuthService.restoreSession();

  runApp(AdaptAttendApp(initialRoute: hasSession
      ? (AuthService.isManager ? '/manager' : '/employee')
      : '/login'));
}

// ── Router ───────────────────────────────────────────────────────────────────

GoRouter _buildRouter(String initialLocation) => GoRouter(
  initialLocation: initialLocation,
  redirect: (ctx, state) {
    final loggedIn = AuthService.isLoggedIn;
    final going = state.matchedLocation;

    if (!loggedIn && going != '/login') return '/login';
    if (loggedIn && going == '/login') {
      return AuthService.isManager ? '/manager' : '/employee';
    }
    // Role guard
    if (loggedIn && !AuthService.isManager && going.startsWith('/manager')) {
      return '/employee';
    }
    if (loggedIn && AuthService.isManager && going.startsWith('/employee')) {
      return '/manager';
    }
    return null;
  },
  routes: [
    // Auth
    GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),

    // Manager shell with nested routes
    ShellRoute(
      builder: (ctx, state, child) => ManagerShell(
        child: child, location: state.matchedLocation),
      routes: [
        GoRoute(path: '/manager',             builder: (_, __) => const ManagerDashboardScreen()),
        GoRoute(path: '/manager/employees',   builder: (_, __) => const EmployeesScreen()),
        GoRoute(path: '/manager/attendance',  builder: (_, __) => const AttendanceScreen()),
        GoRoute(path: '/manager/analytics',   builder: (_, __) => const AnalyticsScreen()),
        GoRoute(path: '/manager/settings',    builder: (_, __) => const SettingsScreen()),
      ],
    ),

    // Face attendance — fullscreen, no shell nav bar
    GoRoute(
      path: '/manager/face-attendance',
      builder: (_, __) => const FaceAttendanceScreen(),
    ),

    // Employee shell with nested routes
    ShellRoute(
      builder: (ctx, state, child) => EmployeeShell(
        child: child, location: state.matchedLocation),
      routes: [
        GoRoute(path: '/employee',          builder: (_, __) => const MarkAttendanceScreen()),
        GoRoute(path: '/employee/history',  builder: (_, __) => const HistoryScreen()),
      ],
    ),
  ],
);

// ── App ──────────────────────────────────────────────────────────────────────

class AdaptAttendApp extends StatefulWidget {
  const AdaptAttendApp({super.key, required this.initialRoute});
  final String initialRoute;

  @override
  State<AdaptAttendApp> createState() => _AdaptAttendAppState();
}

class _AdaptAttendAppState extends State<AdaptAttendApp> {
  @override
  void initState() {
    super.initState();
    AppTheme.themeNotifier.addListener(_onThemeChange);
  }

  @override
  void dispose() {
    AppTheme.themeNotifier.removeListener(_onThemeChange);
    super.dispose();
  }

  void _onThemeChange() => setState(() {});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'AdaptAttend',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: AppTheme.themeNotifier.value,
      routerConfig: _buildRouter(widget.initialRoute),
    );
  }
}
