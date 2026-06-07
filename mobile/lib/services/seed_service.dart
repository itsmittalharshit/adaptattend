/// Seeds the database with a realistic demo org + 5 employees + 30 days of
/// attendance records on first launch. Also pre-enrolls demo face embeddings.
import 'dart:math';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import '../data/database.dart';
import 'face_local_service.dart';

const _uuid = Uuid();

String _hashPin(String pin) {
  final bytes = utf8.encode('adaptattend_salt_$pin');
  return sha256.convert(bytes).toString();
}

Future<void> seedDemoData() async {
  final existing = await db.getFirstOrg();
  if (existing != null) return; // already seeded

  const orgId = 'demo-org-001';
  const orgSecret = 'DEMO_SECRET_XYZ_2024';

  // ── Org ──────────────────────────────────────────────────────────────────
  await db.insertOrg(OrgsCompanion.insert(
    id: orgId,
    name: 'AdaptAttend Demo Corp',
    orgSecret: orgSecret,
    allowedMethods: const Value('qr,geo,face'),
    officeLat: const Value(28.6139),  // New Delhi coords
    officeLng: const Value(77.2090),
    geofenceRadius: const Value(150),
    officeHoursStart: const Value('09:00'),
    officeHoursEnd: const Value('18:00'),
  ));

  // ── Manager ──────────────────────────────────────────────────────────────
  const managerId = 'demo-manager-001';
  await db.insertUser(AppUsersCompanion.insert(
    id: managerId,
    orgId: orgId,
    username: 'manager',
    pinHash: _hashPin('1234'),
    role: 'manager',
    fullName: 'Alex Johnson',
  ));

  // ── Employees ────────────────────────────────────────────────────────────
  final employees = [
    ('emp-001', 'Emma Wilson',   'emma'),
    ('emp-002', 'Liam Chen',     'liam'),
    ('emp-003', 'Sofia Patel',   'sofia'),
    ('emp-004', 'Noah Martinez', 'noah'),
    ('emp-005', 'Zara Ahmed',    'zara'),
  ];

  for (final (id, name, username) in employees) {
    await db.insertUser(AppUsersCompanion.insert(
      id: id,
      orgId: orgId,
      username: username,
      pinHash: _hashPin('1234'),
      role: 'employee',
      fullName: name,
    ));
  }

  // ── 30 days of realistic attendance ──────────────────────────────────────
  final rng = Random();
  final allEmployeeIds = employees.map((e) => e.$1).toList();
  final methods = ['qr', 'geo', 'face'];

  for (int dayOffset = 29; dayOffset >= 0; dayOffset--) {
    final date = DateTime.now().subtract(Duration(days: dayOffset));
    if (date.weekday == DateTime.saturday || date.weekday == DateTime.sunday) {
      continue; // skip weekends
    }

    for (final empId in allEmployeeIds) {
      final isPresent = rng.nextDouble() < 0.87; // 87% attendance
      if (!isPresent) continue;

      // Random check-in between 8:45 and 9:30
      final checkInMinute = 8 * 60 + 45 + rng.nextInt(45);
      final checkIn = DateTime(date.year, date.month, date.day,
          checkInMinute ~/ 60, checkInMinute % 60);

      // Work 7.5–10 hours
      final workedMinutes = 450 + rng.nextInt(150);
      final checkOut = checkIn.add(Duration(minutes: workedMinutes));

      await db.upsertRecord(AttendanceRecordsCompanion.insert(
        id: _uuid.v4(),
        userId: empId,
        orgId: orgId,
        date: date,
        checkIn: Value(checkIn),
        checkOut: Value(checkOut),
        durationMinutes: Value(workedMinutes),
        method: Value(methods[rng.nextInt(methods.length)]),
        status: const Value('present'),
      ));
    }
  }
}

/// Pre-enrolls face embeddings for the 5 demo employees from their bundled
/// asset photos. Runs once (guarded by a SharedPreferences flag) and is
/// safe to call on every launch — skips instantly after the first run.
Future<void> seedFaceEmbeddings() async {
  final prefs = await SharedPreferences.getInstance();
  // v2 flag — forces re-seed after LBP→TFLite upgrade
  if (prefs.getBool('face_demo_seeded_v2') == true) return;

  // Clear stale LBP embeddings
  await prefs.remove('face_demo_seeded');
  for (final id in ['emp-001','emp-002','emp-003','emp-004','emp-005']) {
    await prefs.remove('face_embed_$id');
  }

  const assetMap = [
    ('emp-001', 'assets/images/emma.jpg'),
    ('emp-002', 'assets/images/liam.jpg'),
    ('emp-003', 'assets/images/sofia.jpg'),
    ('emp-004', 'assets/images/noah.jpg'),
    ('emp-005', 'assets/images/zara.jpg'),
  ];

  int enrolled = 0;
  for (final (id, asset) in assetMap) {
    final ok = await FaceLocalService.enrollFromAsset(id, asset);
    if (ok) enrolled++;
  }

  // Only mark done if at least one enrollment succeeded.
  // If model is missing, this will retry on next launch.
  if (enrolled > 0) {
    await prefs.setBool('face_demo_seeded_v2', true);
  }
}
