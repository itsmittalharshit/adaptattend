import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../data/database.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});
  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<AttendanceRecord> _records = [];
  bool _loading = true;
  late int _month, _year;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _month = now.month; _year = now.year;
    _load();
  }

  Future<void> _load() async {
    final user = AuthService.currentUser!;
    final recs = await db.getRecordsForMonth(user.id, _year, _month);
    setState(() { _records = recs; _loading = false; });
  }

  void _prevMonth() {
    setState(() {
      _loading = true;
      if (_month == 1) { _month = 12; _year--; } else _month--;
    });
    _load();
  }

  void _nextMonth() {
    final now = DateTime.now();
    if (_year == now.year && _month == now.month) return;
    setState(() {
      _loading = true;
      if (_month == 12) { _month = 1; _year++; } else _month++;
    });
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final present    = _records.where((r) => r.status == 'present').length;
    final incomplete = _records.where((r) => r.status == 'incomplete').length;
    final totalMins  = _records.fold(0, (s, r) => s + (r.durationMinutes ?? 0));

    return Scaffold(
      appBar: AppBar(
        title: const Text('My History'),
        actions: [
          IconButton(icon: const Icon(Icons.chevron_left_rounded), onPressed: _prevMonth),
          Center(child: Text(
            DateFormat('MMM yyyy').format(DateTime(_year, _month)),
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          )),
          IconButton(icon: const Icon(Icons.chevron_right_rounded), onPressed: _nextMonth),
          const SizedBox(width: 4),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.indigo))
          : Column(children: [
              // Summary
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Row(children: [
                  Expanded(child: StatCard(
                    label: 'Present', value: '$present',
                    icon: Icons.check_circle_rounded, color: AppColors.emerald,
                  )),
                  const SizedBox(width: 10),
                  Expanded(child: StatCard(
                    label: 'Incomplete', value: '$incomplete',
                    icon: Icons.warning_rounded, color: AppColors.amber,
                  )),
                  const SizedBox(width: 10),
                  Expanded(child: StatCard(
                    label: 'Hours', value: '${totalMins ~/ 60}h',
                    icon: Icons.schedule_rounded, color: AppColors.indigo,
                  )),
                ]),
              ),

              // Records
              Expanded(
                child: _records.isEmpty
                    ? Center(child: Text('No records for this month',
                        style: TextStyle(color: Colors.white38)))
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _records.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (_, i) => _RecordTile(record: _records[i]),
                      ),
              ),
            ]),
    );
  }
}

class _RecordTile extends StatelessWidget {
  const _RecordTile({required this.record});
  final AttendanceRecord record;

  @override
  Widget build(BuildContext context) {
    final fmt = (DateTime? dt) => dt != null ? DateFormat('HH:mm').format(dt) : '--:--';
    final mins = record.durationMinutes;

    return GradientCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(children: [
        // Day
        Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.center, children: [
          Text(DateFormat('dd').format(record.date),
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
          Text(DateFormat('EEE').format(record.date),
              style: TextStyle(fontSize: 11, color: Colors.white38)),
        ]),
        const SizedBox(width: 14),
        Container(width: 1, height: 40, color: Colors.white.withOpacity(0.06)),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          StatusBadge(record.status),
          const SizedBox(height: 6),
          Row(children: [
            MethodBadge(record.method),
            const Spacer(),
            Text('${fmt(record.checkIn)} → ${fmt(record.checkOut)}',
                style: TextStyle(fontSize: 11, color: Colors.white38, fontFamily: 'monospace')),
          ]),
        ])),
        if (mins != null) ...[
          const SizedBox(width: 12),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text('${mins ~/ 60}h ${mins % 60}m',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.indigo)),
            Text('worked', style: TextStyle(fontSize: 10, color: Colors.white38)),
          ]),
        ],
      ]),
    );
  }
}
