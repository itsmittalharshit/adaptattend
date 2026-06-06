import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../data/database.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});
  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  List<AttendanceRecord> _records = [];
  Map<String, AppUser> _userMap = {};
  bool _loading = true;
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final org = AuthService.currentOrg!;
    final from = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
    final to   = from.add(const Duration(days: 1));
    final records = await db.getOrgRecordsForDateRange(org.id, from, to);
    final emps = await db.getEmployees(org.id);
    setState(() {
      _records = records;
      _userMap = {for (final e in emps) e.id: e};
      _loading = false;
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 90)),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.dark(primary: AppColors.indigo),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() { _selectedDate = picked; _loading = true; });
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final present   = _records.where((r) => r.status == 'present').length;
    final incomplete = _records.where((r) => r.status == 'incomplete').length;
    final absent    = _records.where((r) => r.status == 'absent').length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance'),
        actions: [
          TextButton.icon(
            onPressed: _pickDate,
            icon: const Icon(Icons.calendar_today_rounded, size: 16),
            label: Text(DateFormat('d MMM').format(_selectedDate)),
            style: TextButton.styleFrom(foregroundColor: AppColors.indigo),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.indigo))
          : Column(children: [
              // Summary strip
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                decoration: BoxDecoration(
                  color: AppColors.surface1,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withOpacity(0.06)),
                ),
                child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                  _SummaryChip(label: 'Present',    value: present,    color: AppColors.emerald),
                  _Divider(),
                  _SummaryChip(label: 'Incomplete', value: incomplete, color: AppColors.amber),
                  _Divider(),
                  _SummaryChip(label: 'Absent',     value: absent,    color: AppColors.rose),
                ]),
              ),

              // Records list
              Expanded(
                child: _records.isEmpty
                    ? Center(child: Text(
                        'No records for ${DateFormat('d MMMM').format(_selectedDate)}',
                        style: TextStyle(color: Colors.white38)))
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _records.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (_, i) {
                          final r = _records[i];
                          final user = _userMap[r.userId];
                          return _RecordTile(record: r, user: user);
                        },
                      ),
              ),
            ]),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  const _SummaryChip({required this.label, required this.value, required this.color});
  final String label; final int value; final Color color;
  @override
  Widget build(BuildContext context) => Column(mainAxisSize: MainAxisSize.min, children: [
    Text('$value', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: color)),
    const SizedBox(height: 2),
    Text(label, style: TextStyle(fontSize: 11, color: Colors.white38)),
  ]);
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      Container(width: 1, height: 32, color: Colors.white.withOpacity(0.06));
}

class _RecordTile extends StatelessWidget {
  const _RecordTile({required this.record, required this.user});
  final AttendanceRecord record;
  final AppUser? user;

  @override
  Widget build(BuildContext context) {
    final fmt = (DateTime? dt) => dt != null ? DateFormat('HH:mm').format(dt) : '--:--';
    return GradientCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(children: [
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
            color: AppColors.indigo.withOpacity(0.12),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            user?.fullName[0].toUpperCase() ?? '?',
            style: const TextStyle(color: AppColors.indigo, fontWeight: FontWeight.w700, fontSize: 16),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(user?.fullName ?? 'Unknown',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          const SizedBox(height: 4),
          Row(children: [
            MethodBadge(record.method),
          ]),
        ])),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          StatusBadge(record.status),
          const SizedBox(height: 4),
          Text('${fmt(record.checkIn)} – ${fmt(record.checkOut)}',
              style: TextStyle(fontSize: 11, color: Colors.white38, fontFamily: 'monospace')),
        ]),
      ]),
    );
  }
}
