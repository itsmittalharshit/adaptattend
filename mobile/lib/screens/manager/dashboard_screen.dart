import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../data/database.dart';
import '../../services/auth_service.dart';
import '../../services/local_qr_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';

class ManagerDashboardScreen extends StatefulWidget {
  const ManagerDashboardScreen({super.key});
  @override
  State<ManagerDashboardScreen> createState() => _ManagerDashboardScreenState();
}

class _ManagerDashboardScreenState extends State<ManagerDashboardScreen>
    with SingleTickerProviderStateMixin {
  String _code = '';
  int _secondsLeft = 15;
  Timer? _timer;
  int _totalEmployees = 0;
  int _todayPresent = 0;
  late AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    _loadStats();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadStats() async {
    final org = AuthService.currentOrg!;
    final count = await db.countEmployees(org.id);
    final today = DateTime.now();
    final records = await db.getOrgRecordsForDateRange(
      org.id,
      DateTime(today.year, today.month, today.day),
      DateTime(today.year, today.month, today.day + 1),
    );
    if (mounted) {
      setState(() {
        _totalEmployees = count;
        _todayPresent = records.where((r) => r.status == 'present').length;
      });
    }
  }

  void _startTimer() {
    _refreshCode();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        _secondsLeft = LocalQrService.secondsLeft();
        _code = LocalQrService.generateToken(AuthService.currentOrg!.orgSecret);
      });
    });
  }

  void _refreshCode() {
    if (!mounted) return;
    setState(() {
      _code = LocalQrService.generateToken(AuthService.currentOrg!.orgSecret);
      _secondsLeft = LocalQrService.secondsLeft();
    });
  }

  void _copyCode() {
    Clipboard.setData(ClipboardData(text: _code));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Code copied to clipboard'),
        backgroundColor: AppColors.indigo,
        duration: Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final manager = AuthService.currentUser!;
    final org = AuthService.currentOrg!;
    final isUrgent = _secondsLeft <= 4;
    final digits = _code.isEmpty ? '------' : _code;

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.indigo,
          onRefresh: () async {
            await _loadStats();
            _refreshCode();
          },
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // ── Header ──────────────────────────────────────────────────
              Row(children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _greeting(manager.fullName.split(' ').first),
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.indigo.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.indigo.withOpacity(0.25)),
                        ),
                        child: Text(
                          org.name,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.indigo,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.logout_rounded),
                  onPressed: () async {
                    await AuthService.logout();
                    if (mounted) context.go('/login');
                  },
                ),
              ]),
              const SizedBox(height: 24),

              // ── Stat cards ──────────────────────────────────────────────
              Row(children: [
                Expanded(
                  child: StatCard(
                    label: 'Employees',
                    value: '$_totalEmployees',
                    icon: Icons.group_rounded,
                    color: AppColors.indigo,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: StatCard(
                    label: 'Present Today',
                    value: '$_todayPresent',
                    icon: Icons.check_circle_rounded,
                    color: AppColors.emerald,
                  ),
                ),
              ]),
              const SizedBox(height: 24),

              // ── Attendance code card ─────────────────────────────────────
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isUrgent
                        ? [const Color(0xFF2A0E0E), const Color(0xFF1A0808)]
                        : [const Color(0xFF1E1B38), const Color(0xFF120E26)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: isUrgent
                        ? AppColors.rose.withOpacity(0.5)
                        : AppColors.indigo.withOpacity(0.25),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: (isUrgent ? AppColors.rose : AppColors.indigo).withOpacity(0.18),
                      blurRadius: 24,
                      spreadRadius: 2,
                      offset: const Offset(0, 6),
                    )
                  ],
                ),
                padding: const EdgeInsets.all(28),
                child: Column(children: [
                  // Live indicator row
                  Row(children: [
                    AnimatedBuilder(
                      animation: _pulseCtrl,
                      builder: (_, __) => Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: isUrgent ? AppColors.rose : AppColors.emerald,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: (isUrgent ? AppColors.rose : AppColors.emerald)
                                  .withOpacity(0.4 + _pulseCtrl.value * 0.4),
                              blurRadius: 8,
                            )
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Live Attendance Code',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Colors.white.withOpacity(0.85),
                      ),
                    ),
                    const Spacer(),
                    // Countdown chip
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: (isUrgent ? AppColors.rose : AppColors.indigo).withOpacity(0.18),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: (isUrgent ? AppColors.rose : AppColors.indigo).withOpacity(0.4),
                        ),
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(
                          Icons.timer_rounded,
                          size: 13,
                          color: isUrgent ? AppColors.rose : AppColors.indigo,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          '${_secondsLeft}s',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: isUrgent ? AppColors.rose : AppColors.indigo,
                          ),
                        ),
                      ]),
                    ),
                  ]),

                  const SizedBox(height: 32),

                  // ── Big digit display ─────────────────────────────────
                  Text(
                    'Show this to employees',
                    style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.35)),
                  ),
                  const SizedBox(height: 16),

                  GestureDetector(
                    onTap: _copyCode,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: (isUrgent ? AppColors.rose : AppColors.indigo).withOpacity(0.3),
                        ),
                      ),
                      child: Column(children: [
                        // Spaced-out digits wrapped inside a FittedBox to handle narrow screens safely
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(6, (i) {
                              final ch = i < digits.length ? digits[i] : '-';
                              return AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                margin: EdgeInsets.symmetric(horizontal: i == 2 ? 10 : 4),
                                width: 40,
                                height: 56,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.12),
                                  ),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  ch,
                                  style: TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w900,
                                    color: isUrgent ? AppColors.rose : Colors.white,
                                    fontFamily: 'monospace',
                                  ),
                                ),
                              );
                            }),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                          Icon(Icons.copy_rounded, size: 13, color: Colors.white.withOpacity(0.3)),
                          const SizedBox(width: 5),
                          Text(
                            'Tap to copy',
                            style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.3)),
                          ),
                        ]),
                      ]),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Progress bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: _secondsLeft / 15,
                      minHeight: 5,
                      backgroundColor: Colors.white.withOpacity(0.07),
                      color: isUrgent ? AppColors.rose : AppColors.indigo,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Refreshes every 15 seconds · works without internet',
                    style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.28)),
                    textAlign: TextAlign.center,
                  ),
                ]),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _greeting(String name) {
    final h = DateTime.now().hour;
    final g = h < 12 ? 'Good morning' : h < 17 ? 'Good afternoon' : 'Good evening';
    return '$g, $name 👋';
  }
}
