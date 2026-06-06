import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

import '../../data/database.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});
  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  List<AttendanceRecord> _records = [];
  List<AppUser> _employees = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final org = AuthService.currentOrg!;
    final from = DateTime.now().subtract(const Duration(days: 29));
    final to = DateTime.now().add(const Duration(days: 1));
    final records = await db.getOrgRecordsForDateRange(org.id, from, to);
    final emps = await db.getEmployees(org.id);
    setState(() { _records = records; _employees = emps; _loading = false; });
  }

  // Last 7 days present count per day
  List<FlSpot> get _weeklySpots {
    final spots = <FlSpot>[];
    for (int i = 6; i >= 0; i--) {
      final day = DateTime.now().subtract(Duration(days: i));
      final count = _records.where((r) {
        return r.date.year == day.year &&
            r.date.month == day.month &&
            r.date.day == day.day &&
            r.status == 'present';
      }).length;
      spots.add(FlSpot((6 - i).toDouble(), count.toDouble()));
    }
    return spots;
  }

  // Method breakdown
  Map<String, int> get _methodCounts {
    final m = <String, int>{'qr': 0, 'geo': 0, 'face': 0};
    for (final r in _records) {
      if (r.method != null && m.containsKey(r.method)) {
        m[r.method!] = (m[r.method!] ?? 0) + 1;
      }
    }
    return m;
  }

  // Top employees by attendance rate
  List<(AppUser, double)> get _leaderboard {
    final workdays = _records.map((r) => '${r.date.year}-${r.date.month}-${r.date.day}')
        .toSet().length;
    final result = <(AppUser, double)>[];
    for (final emp in _employees) {
      final present = _records.where((r) =>
          r.userId == emp.id && r.status == 'present').length;
      final rate = workdays == 0 ? 0.0 : present / workdays;
      result.add((emp, rate));
    }
    result.sort((a, b) => b.$2.compareTo(a.$2));
    return result;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator(color: AppColors.indigo));

    final spots = _weeklySpots;
    final methods = _methodCounts;
    final board = _leaderboard;
    final total = methods.values.fold(0, (a, b) => a + b);

    return Scaffold(
      appBar: AppBar(title: const Text('Analytics')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Weekly trend
          GradientCard(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Weekly Attendance', style: TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text('Last 7 days', style: TextStyle(fontSize: 12, color: Colors.white38)),
              const SizedBox(height: 20),
              SizedBox(height: 160, child: LineChart(LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: Colors.white.withOpacity(0.05), strokeWidth: 1),
                ),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(sideTitles: SideTitles(
                    showTitles: true, reservedSize: 22,
                    getTitlesWidget: (v, _) {
                      final day = DateTime.now().subtract(Duration(days: 6 - v.toInt()));
                      return Text(DateFormat('EEE').format(day),
                          style: const TextStyle(fontSize: 10, color: Colors.white38));
                    },
                  )),
                  leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles:  AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  color: AppColors.indigo,
                  barWidth: 3,
                  dotData: FlDotData(getDotPainter: (_, __, ___, ____) =>
                      FlDotCirclePainter(radius: 4, color: AppColors.indigo,
                          strokeColor: AppColors.surface0, strokeWidth: 2)),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      colors: [AppColors.indigo.withOpacity(0.3), Colors.transparent],
                      begin: Alignment.topCenter, end: Alignment.bottomCenter,
                    ),
                  ),
                )],
              ))),
            ],
          )),
          const SizedBox(height: 16),

          // Method breakdown
          GradientCard(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Method Breakdown', style: TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 16),
              ...[
                ('QR Code',  'qr',   AppColors.indigo),
                ('GPS',      'geo',  AppColors.cyan),
                ('Face Scan','face', AppColors.emerald),
              ].map((entry) {
                final (label, key, color) = entry;
                final count = methods[key] ?? 0;
                final pct = total == 0 ? 0.0 : count / total;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                      const Spacer(),
                      Text('$count', style: TextStyle(fontSize: 13, color: color, fontWeight: FontWeight.w700)),
                    ]),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: pct, minHeight: 6,
                        backgroundColor: Colors.white.withOpacity(0.06),
                        valueColor: AlwaysStoppedAnimation(color),
                      ),
                    ),
                  ]),
                );
              }),
            ],
          )),
          const SizedBox(height: 16),

          // Leaderboard
          GradientCard(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Attendance Leaders', style: TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text('30-day rate', style: TextStyle(fontSize: 12, color: Colors.white38)),
              const SizedBox(height: 16),
              ...board.asMap().entries.map((entry) {
                final (rank, (emp, rate)) = (entry.key, entry.value);
                final pct = (rate * 100).round();
                final medal = rank == 0 ? '🥇' : rank == 1 ? '🥈' : rank == 2 ? '🥉' : '${rank + 1}.';
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(children: [
                    SizedBox(width: 28, child: Text(medal,
                        style: const TextStyle(fontSize: 14))),
                    UserAvatar(username: emp.username, fullName: emp.fullName, userId: emp.id, size: 32),
                    const SizedBox(width: 10),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(emp.fullName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(3),
                        child: LinearProgressIndicator(
                          value: rate, minHeight: 4,
                          backgroundColor: Colors.white.withOpacity(0.06),
                          color: rate > 0.9 ? AppColors.emerald
                              : rate > 0.7 ? AppColors.amber : AppColors.rose,
                        ),
                      ),
                    ])),
                    const SizedBox(width: 10),
                    Text('$pct%', style: TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w700,
                        color: rate > 0.9 ? AppColors.emerald
                            : rate > 0.7 ? AppColors.amber : AppColors.rose)),
                  ]),
                );
              }),
            ],
          )),
        ],
      ),
    );
  }
}
