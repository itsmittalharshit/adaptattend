import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'database.g.dart';

// ── Tables ───────────────────────────────────────────────────────────────────

class Orgs extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get orgSecret => text()(); // TOTP secret for QR
  TextColumn get allowedMethods => text().withDefault(const Constant('qr'))(); // 'qr,geo,face'
  RealColumn get officeLat => real().nullable()();
  RealColumn get officeLng => real().nullable()();
  RealColumn get geofenceRadius => real().withDefault(const Constant(100))();
  TextColumn get officeHoursStart => text().withDefault(const Constant('09:00'))();
  TextColumn get officeHoursEnd => text().withDefault(const Constant('18:00'))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

class AppUsers extends Table {
  TextColumn get id => text()();
  TextColumn get orgId => text().references(Orgs, #id)();
  TextColumn get username => text()();
  TextColumn get pinHash => text()(); // bcrypt of 4-6 digit PIN
  TextColumn get role => text()(); // 'manager' | 'employee'
  TextColumn get fullName => text()();
  TextColumn get faceEmbedding => text().nullable()(); // encrypted blob from backend
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

class AttendanceRecords extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text().references(AppUsers, #id)();
  TextColumn get orgId => text().references(Orgs, #id)();
  DateTimeColumn get date => dateTime()();
  DateTimeColumn get checkIn => dateTime().nullable()();
  DateTimeColumn get checkOut => dateTime().nullable()();
  IntColumn get durationMinutes => integer().nullable()();
  TextColumn get method => text().nullable()(); // 'qr' | 'geo' | 'face'
  TextColumn get status => text().withDefault(const Constant('present'))(); // 'present'|'absent'|'incomplete'
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

// ── Database ─────────────────────────────────────────────────────────────────

@DriftDatabase(tables: [Orgs, AppUsers, AttendanceRecords])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  static QueryExecutor _openConnection() {
    return driftDatabase(name: 'adaptattend.db');
  }

  // ── Org queries ──────────────────────────────────────────────────────────

  Future<Org?> getFirstOrg() =>
      (select(orgs)..limit(1)).getSingleOrNull();

  Future<String> insertOrg(OrgsCompanion org) async {
    await into(orgs).insert(org, mode: InsertMode.insertOrIgnore);
    return org.id.value;
  }

  Future<void> updateOrg(OrgsCompanion org) =>
      (update(orgs)..where((t) => t.id.equals(org.id.value))).write(org);

  // ── User queries ─────────────────────────────────────────────────────────

  Future<AppUser?> getUserByUsername(String orgId, String username) =>
      (select(appUsers)
        ..where((t) => t.orgId.equals(orgId) & t.username.equals(username)))
          .getSingleOrNull();

  Future<AppUser?> getUserById(String id) =>
      (select(appUsers)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<List<AppUser>> getEmployees(String orgId) =>
      (select(appUsers)
        ..where((t) => t.orgId.equals(orgId) & t.role.equals('employee'))
        ..orderBy([(t) => OrderingTerm(expression: t.fullName)]))
          .get();

  Future<int> countEmployees(String orgId) async {
    final count = appUsers.id.count();
    final query = selectOnly(appUsers)
      ..addColumns([count])
      ..where(appUsers.orgId.equals(orgId) & appUsers.role.equals('employee'));
    final row = await query.getSingle();
    return row.read(count) ?? 0;
  }

  Future<String> insertUser(AppUsersCompanion user) async {
    await into(appUsers).insert(user, mode: InsertMode.insertOrIgnore);
    return user.id.value;
  }

  Future<void> updateUser(AppUsersCompanion user) =>
      (update(appUsers)..where((t) => t.id.equals(user.id.value))).write(user);

  Future<void> toggleUserActive(String id, bool active) =>
      (update(appUsers)..where((t) => t.id.equals(id)))
          .write(AppUsersCompanion(isActive: Value(active)));

  // ── Attendance queries ───────────────────────────────────────────────────

  Future<AttendanceRecord?> getTodayRecord(String userId) {
    final today = DateTime.now();
    final start = DateTime(today.year, today.month, today.day);
    final end = start.add(const Duration(days: 1));
    return (select(attendanceRecords)
      ..where((t) => t.userId.equals(userId)
          & t.date.isBiggerOrEqualValue(start)
          & t.date.isSmallerThanValue(end)))
        .getSingleOrNull();
  }

  Future<List<AttendanceRecord>> getRecordsForMonth(
      String userId, int year, int month) {
    final start = DateTime(year, month, 1);
    final end = DateTime(year, month + 1, 1);
    return (select(attendanceRecords)
      ..where((t) => t.userId.equals(userId)
          & t.date.isBiggerOrEqualValue(start)
          & t.date.isSmallerThanValue(end))
      ..orderBy([(t) => OrderingTerm(expression: t.date, mode: OrderingMode.desc)]))
        .get();
  }

  Future<List<AttendanceRecord>> getOrgRecordsForDateRange(
      String orgId, DateTime from, DateTime to) {
    return (select(attendanceRecords)
      ..where((t) => t.orgId.equals(orgId)
          & t.date.isBiggerOrEqualValue(from)
          & t.date.isSmallerThanValue(to))
      ..orderBy([(t) => OrderingTerm(expression: t.date, mode: OrderingMode.desc)]))
        .get();
  }

  Future<void> upsertRecord(AttendanceRecordsCompanion record) =>
      into(attendanceRecords).insertOnConflictUpdate(record);

  Future<void> checkOut(String recordId, DateTime checkOut, int durationMinutes) =>
      (update(attendanceRecords)..where((t) => t.id.equals(recordId))).write(
        AttendanceRecordsCompanion(
          checkOut: Value(checkOut),
          durationMinutes: Value(durationMinutes),
          status: const Value('present'),
        ),
      );
}

// ── Singleton ─────────────────────────────────────────────────────────────────

AppDatabase? _dbInstance;
AppDatabase get db {
  _dbInstance ??= AppDatabase();
  return _dbInstance!;
}
