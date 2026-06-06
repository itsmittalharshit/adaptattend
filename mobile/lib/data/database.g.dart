// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $OrgsTable extends Orgs with TableInfo<$OrgsTable, Org> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $OrgsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _orgSecretMeta =
      const VerificationMeta('orgSecret');
  @override
  late final GeneratedColumn<String> orgSecret = GeneratedColumn<String>(
      'org_secret', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _allowedMethodsMeta =
      const VerificationMeta('allowedMethods');
  @override
  late final GeneratedColumn<String> allowedMethods = GeneratedColumn<String>(
      'allowed_methods', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('qr'));
  static const VerificationMeta _officeLatMeta =
      const VerificationMeta('officeLat');
  @override
  late final GeneratedColumn<double> officeLat = GeneratedColumn<double>(
      'office_lat', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _officeLngMeta =
      const VerificationMeta('officeLng');
  @override
  late final GeneratedColumn<double> officeLng = GeneratedColumn<double>(
      'office_lng', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _geofenceRadiusMeta =
      const VerificationMeta('geofenceRadius');
  @override
  late final GeneratedColumn<double> geofenceRadius = GeneratedColumn<double>(
      'geofence_radius', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(100));
  static const VerificationMeta _officeHoursStartMeta =
      const VerificationMeta('officeHoursStart');
  @override
  late final GeneratedColumn<String> officeHoursStart = GeneratedColumn<String>(
      'office_hours_start', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('09:00'));
  static const VerificationMeta _officeHoursEndMeta =
      const VerificationMeta('officeHoursEnd');
  @override
  late final GeneratedColumn<String> officeHoursEnd = GeneratedColumn<String>(
      'office_hours_end', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('18:00'));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        name,
        orgSecret,
        allowedMethods,
        officeLat,
        officeLng,
        geofenceRadius,
        officeHoursStart,
        officeHoursEnd,
        createdAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'orgs';
  @override
  VerificationContext validateIntegrity(Insertable<Org> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('org_secret')) {
      context.handle(_orgSecretMeta,
          orgSecret.isAcceptableOrUnknown(data['org_secret']!, _orgSecretMeta));
    } else if (isInserting) {
      context.missing(_orgSecretMeta);
    }
    if (data.containsKey('allowed_methods')) {
      context.handle(
          _allowedMethodsMeta,
          allowedMethods.isAcceptableOrUnknown(
              data['allowed_methods']!, _allowedMethodsMeta));
    }
    if (data.containsKey('office_lat')) {
      context.handle(_officeLatMeta,
          officeLat.isAcceptableOrUnknown(data['office_lat']!, _officeLatMeta));
    }
    if (data.containsKey('office_lng')) {
      context.handle(_officeLngMeta,
          officeLng.isAcceptableOrUnknown(data['office_lng']!, _officeLngMeta));
    }
    if (data.containsKey('geofence_radius')) {
      context.handle(
          _geofenceRadiusMeta,
          geofenceRadius.isAcceptableOrUnknown(
              data['geofence_radius']!, _geofenceRadiusMeta));
    }
    if (data.containsKey('office_hours_start')) {
      context.handle(
          _officeHoursStartMeta,
          officeHoursStart.isAcceptableOrUnknown(
              data['office_hours_start']!, _officeHoursStartMeta));
    }
    if (data.containsKey('office_hours_end')) {
      context.handle(
          _officeHoursEndMeta,
          officeHoursEnd.isAcceptableOrUnknown(
              data['office_hours_end']!, _officeHoursEndMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Org map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Org(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      orgSecret: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}org_secret'])!,
      allowedMethods: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}allowed_methods'])!,
      officeLat: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}office_lat']),
      officeLng: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}office_lng']),
      geofenceRadius: attachedDatabase.typeMapping.read(
          DriftSqlType.double, data['${effectivePrefix}geofence_radius'])!,
      officeHoursStart: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}office_hours_start'])!,
      officeHoursEnd: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}office_hours_end'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $OrgsTable createAlias(String alias) {
    return $OrgsTable(attachedDatabase, alias);
  }
}

class Org extends DataClass implements Insertable<Org> {
  final String id;
  final String name;
  final String orgSecret;
  final String allowedMethods;
  final double? officeLat;
  final double? officeLng;
  final double geofenceRadius;
  final String officeHoursStart;
  final String officeHoursEnd;
  final DateTime createdAt;
  const Org(
      {required this.id,
      required this.name,
      required this.orgSecret,
      required this.allowedMethods,
      this.officeLat,
      this.officeLng,
      required this.geofenceRadius,
      required this.officeHoursStart,
      required this.officeHoursEnd,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['org_secret'] = Variable<String>(orgSecret);
    map['allowed_methods'] = Variable<String>(allowedMethods);
    if (!nullToAbsent || officeLat != null) {
      map['office_lat'] = Variable<double>(officeLat);
    }
    if (!nullToAbsent || officeLng != null) {
      map['office_lng'] = Variable<double>(officeLng);
    }
    map['geofence_radius'] = Variable<double>(geofenceRadius);
    map['office_hours_start'] = Variable<String>(officeHoursStart);
    map['office_hours_end'] = Variable<String>(officeHoursEnd);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  OrgsCompanion toCompanion(bool nullToAbsent) {
    return OrgsCompanion(
      id: Value(id),
      name: Value(name),
      orgSecret: Value(orgSecret),
      allowedMethods: Value(allowedMethods),
      officeLat: officeLat == null && nullToAbsent
          ? const Value.absent()
          : Value(officeLat),
      officeLng: officeLng == null && nullToAbsent
          ? const Value.absent()
          : Value(officeLng),
      geofenceRadius: Value(geofenceRadius),
      officeHoursStart: Value(officeHoursStart),
      officeHoursEnd: Value(officeHoursEnd),
      createdAt: Value(createdAt),
    );
  }

  factory Org.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Org(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      orgSecret: serializer.fromJson<String>(json['orgSecret']),
      allowedMethods: serializer.fromJson<String>(json['allowedMethods']),
      officeLat: serializer.fromJson<double?>(json['officeLat']),
      officeLng: serializer.fromJson<double?>(json['officeLng']),
      geofenceRadius: serializer.fromJson<double>(json['geofenceRadius']),
      officeHoursStart: serializer.fromJson<String>(json['officeHoursStart']),
      officeHoursEnd: serializer.fromJson<String>(json['officeHoursEnd']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'orgSecret': serializer.toJson<String>(orgSecret),
      'allowedMethods': serializer.toJson<String>(allowedMethods),
      'officeLat': serializer.toJson<double?>(officeLat),
      'officeLng': serializer.toJson<double?>(officeLng),
      'geofenceRadius': serializer.toJson<double>(geofenceRadius),
      'officeHoursStart': serializer.toJson<String>(officeHoursStart),
      'officeHoursEnd': serializer.toJson<String>(officeHoursEnd),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  Org copyWith(
          {String? id,
          String? name,
          String? orgSecret,
          String? allowedMethods,
          Value<double?> officeLat = const Value.absent(),
          Value<double?> officeLng = const Value.absent(),
          double? geofenceRadius,
          String? officeHoursStart,
          String? officeHoursEnd,
          DateTime? createdAt}) =>
      Org(
        id: id ?? this.id,
        name: name ?? this.name,
        orgSecret: orgSecret ?? this.orgSecret,
        allowedMethods: allowedMethods ?? this.allowedMethods,
        officeLat: officeLat.present ? officeLat.value : this.officeLat,
        officeLng: officeLng.present ? officeLng.value : this.officeLng,
        geofenceRadius: geofenceRadius ?? this.geofenceRadius,
        officeHoursStart: officeHoursStart ?? this.officeHoursStart,
        officeHoursEnd: officeHoursEnd ?? this.officeHoursEnd,
        createdAt: createdAt ?? this.createdAt,
      );
  Org copyWithCompanion(OrgsCompanion data) {
    return Org(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      orgSecret: data.orgSecret.present ? data.orgSecret.value : this.orgSecret,
      allowedMethods: data.allowedMethods.present
          ? data.allowedMethods.value
          : this.allowedMethods,
      officeLat: data.officeLat.present ? data.officeLat.value : this.officeLat,
      officeLng: data.officeLng.present ? data.officeLng.value : this.officeLng,
      geofenceRadius: data.geofenceRadius.present
          ? data.geofenceRadius.value
          : this.geofenceRadius,
      officeHoursStart: data.officeHoursStart.present
          ? data.officeHoursStart.value
          : this.officeHoursStart,
      officeHoursEnd: data.officeHoursEnd.present
          ? data.officeHoursEnd.value
          : this.officeHoursEnd,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Org(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('orgSecret: $orgSecret, ')
          ..write('allowedMethods: $allowedMethods, ')
          ..write('officeLat: $officeLat, ')
          ..write('officeLng: $officeLng, ')
          ..write('geofenceRadius: $geofenceRadius, ')
          ..write('officeHoursStart: $officeHoursStart, ')
          ..write('officeHoursEnd: $officeHoursEnd, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      name,
      orgSecret,
      allowedMethods,
      officeLat,
      officeLng,
      geofenceRadius,
      officeHoursStart,
      officeHoursEnd,
      createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Org &&
          other.id == this.id &&
          other.name == this.name &&
          other.orgSecret == this.orgSecret &&
          other.allowedMethods == this.allowedMethods &&
          other.officeLat == this.officeLat &&
          other.officeLng == this.officeLng &&
          other.geofenceRadius == this.geofenceRadius &&
          other.officeHoursStart == this.officeHoursStart &&
          other.officeHoursEnd == this.officeHoursEnd &&
          other.createdAt == this.createdAt);
}

class OrgsCompanion extends UpdateCompanion<Org> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> orgSecret;
  final Value<String> allowedMethods;
  final Value<double?> officeLat;
  final Value<double?> officeLng;
  final Value<double> geofenceRadius;
  final Value<String> officeHoursStart;
  final Value<String> officeHoursEnd;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const OrgsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.orgSecret = const Value.absent(),
    this.allowedMethods = const Value.absent(),
    this.officeLat = const Value.absent(),
    this.officeLng = const Value.absent(),
    this.geofenceRadius = const Value.absent(),
    this.officeHoursStart = const Value.absent(),
    this.officeHoursEnd = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  OrgsCompanion.insert({
    required String id,
    required String name,
    required String orgSecret,
    this.allowedMethods = const Value.absent(),
    this.officeLat = const Value.absent(),
    this.officeLng = const Value.absent(),
    this.geofenceRadius = const Value.absent(),
    this.officeHoursStart = const Value.absent(),
    this.officeHoursEnd = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        name = Value(name),
        orgSecret = Value(orgSecret);
  static Insertable<Org> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? orgSecret,
    Expression<String>? allowedMethods,
    Expression<double>? officeLat,
    Expression<double>? officeLng,
    Expression<double>? geofenceRadius,
    Expression<String>? officeHoursStart,
    Expression<String>? officeHoursEnd,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (orgSecret != null) 'org_secret': orgSecret,
      if (allowedMethods != null) 'allowed_methods': allowedMethods,
      if (officeLat != null) 'office_lat': officeLat,
      if (officeLng != null) 'office_lng': officeLng,
      if (geofenceRadius != null) 'geofence_radius': geofenceRadius,
      if (officeHoursStart != null) 'office_hours_start': officeHoursStart,
      if (officeHoursEnd != null) 'office_hours_end': officeHoursEnd,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  OrgsCompanion copyWith(
      {Value<String>? id,
      Value<String>? name,
      Value<String>? orgSecret,
      Value<String>? allowedMethods,
      Value<double?>? officeLat,
      Value<double?>? officeLng,
      Value<double>? geofenceRadius,
      Value<String>? officeHoursStart,
      Value<String>? officeHoursEnd,
      Value<DateTime>? createdAt,
      Value<int>? rowid}) {
    return OrgsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      orgSecret: orgSecret ?? this.orgSecret,
      allowedMethods: allowedMethods ?? this.allowedMethods,
      officeLat: officeLat ?? this.officeLat,
      officeLng: officeLng ?? this.officeLng,
      geofenceRadius: geofenceRadius ?? this.geofenceRadius,
      officeHoursStart: officeHoursStart ?? this.officeHoursStart,
      officeHoursEnd: officeHoursEnd ?? this.officeHoursEnd,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (orgSecret.present) {
      map['org_secret'] = Variable<String>(orgSecret.value);
    }
    if (allowedMethods.present) {
      map['allowed_methods'] = Variable<String>(allowedMethods.value);
    }
    if (officeLat.present) {
      map['office_lat'] = Variable<double>(officeLat.value);
    }
    if (officeLng.present) {
      map['office_lng'] = Variable<double>(officeLng.value);
    }
    if (geofenceRadius.present) {
      map['geofence_radius'] = Variable<double>(geofenceRadius.value);
    }
    if (officeHoursStart.present) {
      map['office_hours_start'] = Variable<String>(officeHoursStart.value);
    }
    if (officeHoursEnd.present) {
      map['office_hours_end'] = Variable<String>(officeHoursEnd.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('OrgsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('orgSecret: $orgSecret, ')
          ..write('allowedMethods: $allowedMethods, ')
          ..write('officeLat: $officeLat, ')
          ..write('officeLng: $officeLng, ')
          ..write('geofenceRadius: $geofenceRadius, ')
          ..write('officeHoursStart: $officeHoursStart, ')
          ..write('officeHoursEnd: $officeHoursEnd, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AppUsersTable extends AppUsers with TableInfo<$AppUsersTable, AppUser> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AppUsersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _orgIdMeta = const VerificationMeta('orgId');
  @override
  late final GeneratedColumn<String> orgId = GeneratedColumn<String>(
      'org_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES orgs (id)'));
  static const VerificationMeta _usernameMeta =
      const VerificationMeta('username');
  @override
  late final GeneratedColumn<String> username = GeneratedColumn<String>(
      'username', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _pinHashMeta =
      const VerificationMeta('pinHash');
  @override
  late final GeneratedColumn<String> pinHash = GeneratedColumn<String>(
      'pin_hash', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _roleMeta = const VerificationMeta('role');
  @override
  late final GeneratedColumn<String> role = GeneratedColumn<String>(
      'role', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _fullNameMeta =
      const VerificationMeta('fullName');
  @override
  late final GeneratedColumn<String> fullName = GeneratedColumn<String>(
      'full_name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _faceEmbeddingMeta =
      const VerificationMeta('faceEmbedding');
  @override
  late final GeneratedColumn<String> faceEmbedding = GeneratedColumn<String>(
      'face_embedding', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _isActiveMeta =
      const VerificationMeta('isActive');
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
      'is_active', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_active" IN (0, 1))'),
      defaultValue: const Constant(true));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        orgId,
        username,
        pinHash,
        role,
        fullName,
        faceEmbedding,
        isActive,
        createdAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'app_users';
  @override
  VerificationContext validateIntegrity(Insertable<AppUser> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('org_id')) {
      context.handle(
          _orgIdMeta, orgId.isAcceptableOrUnknown(data['org_id']!, _orgIdMeta));
    } else if (isInserting) {
      context.missing(_orgIdMeta);
    }
    if (data.containsKey('username')) {
      context.handle(_usernameMeta,
          username.isAcceptableOrUnknown(data['username']!, _usernameMeta));
    } else if (isInserting) {
      context.missing(_usernameMeta);
    }
    if (data.containsKey('pin_hash')) {
      context.handle(_pinHashMeta,
          pinHash.isAcceptableOrUnknown(data['pin_hash']!, _pinHashMeta));
    } else if (isInserting) {
      context.missing(_pinHashMeta);
    }
    if (data.containsKey('role')) {
      context.handle(
          _roleMeta, role.isAcceptableOrUnknown(data['role']!, _roleMeta));
    } else if (isInserting) {
      context.missing(_roleMeta);
    }
    if (data.containsKey('full_name')) {
      context.handle(_fullNameMeta,
          fullName.isAcceptableOrUnknown(data['full_name']!, _fullNameMeta));
    } else if (isInserting) {
      context.missing(_fullNameMeta);
    }
    if (data.containsKey('face_embedding')) {
      context.handle(
          _faceEmbeddingMeta,
          faceEmbedding.isAcceptableOrUnknown(
              data['face_embedding']!, _faceEmbeddingMeta));
    }
    if (data.containsKey('is_active')) {
      context.handle(_isActiveMeta,
          isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AppUser map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AppUser(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      orgId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}org_id'])!,
      username: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}username'])!,
      pinHash: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}pin_hash'])!,
      role: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}role'])!,
      fullName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}full_name'])!,
      faceEmbedding: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}face_embedding']),
      isActive: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_active'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $AppUsersTable createAlias(String alias) {
    return $AppUsersTable(attachedDatabase, alias);
  }
}

class AppUser extends DataClass implements Insertable<AppUser> {
  final String id;
  final String orgId;
  final String username;
  final String pinHash;
  final String role;
  final String fullName;
  final String? faceEmbedding;
  final bool isActive;
  final DateTime createdAt;
  const AppUser(
      {required this.id,
      required this.orgId,
      required this.username,
      required this.pinHash,
      required this.role,
      required this.fullName,
      this.faceEmbedding,
      required this.isActive,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['org_id'] = Variable<String>(orgId);
    map['username'] = Variable<String>(username);
    map['pin_hash'] = Variable<String>(pinHash);
    map['role'] = Variable<String>(role);
    map['full_name'] = Variable<String>(fullName);
    if (!nullToAbsent || faceEmbedding != null) {
      map['face_embedding'] = Variable<String>(faceEmbedding);
    }
    map['is_active'] = Variable<bool>(isActive);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  AppUsersCompanion toCompanion(bool nullToAbsent) {
    return AppUsersCompanion(
      id: Value(id),
      orgId: Value(orgId),
      username: Value(username),
      pinHash: Value(pinHash),
      role: Value(role),
      fullName: Value(fullName),
      faceEmbedding: faceEmbedding == null && nullToAbsent
          ? const Value.absent()
          : Value(faceEmbedding),
      isActive: Value(isActive),
      createdAt: Value(createdAt),
    );
  }

  factory AppUser.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AppUser(
      id: serializer.fromJson<String>(json['id']),
      orgId: serializer.fromJson<String>(json['orgId']),
      username: serializer.fromJson<String>(json['username']),
      pinHash: serializer.fromJson<String>(json['pinHash']),
      role: serializer.fromJson<String>(json['role']),
      fullName: serializer.fromJson<String>(json['fullName']),
      faceEmbedding: serializer.fromJson<String?>(json['faceEmbedding']),
      isActive: serializer.fromJson<bool>(json['isActive']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'orgId': serializer.toJson<String>(orgId),
      'username': serializer.toJson<String>(username),
      'pinHash': serializer.toJson<String>(pinHash),
      'role': serializer.toJson<String>(role),
      'fullName': serializer.toJson<String>(fullName),
      'faceEmbedding': serializer.toJson<String?>(faceEmbedding),
      'isActive': serializer.toJson<bool>(isActive),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  AppUser copyWith(
          {String? id,
          String? orgId,
          String? username,
          String? pinHash,
          String? role,
          String? fullName,
          Value<String?> faceEmbedding = const Value.absent(),
          bool? isActive,
          DateTime? createdAt}) =>
      AppUser(
        id: id ?? this.id,
        orgId: orgId ?? this.orgId,
        username: username ?? this.username,
        pinHash: pinHash ?? this.pinHash,
        role: role ?? this.role,
        fullName: fullName ?? this.fullName,
        faceEmbedding:
            faceEmbedding.present ? faceEmbedding.value : this.faceEmbedding,
        isActive: isActive ?? this.isActive,
        createdAt: createdAt ?? this.createdAt,
      );
  AppUser copyWithCompanion(AppUsersCompanion data) {
    return AppUser(
      id: data.id.present ? data.id.value : this.id,
      orgId: data.orgId.present ? data.orgId.value : this.orgId,
      username: data.username.present ? data.username.value : this.username,
      pinHash: data.pinHash.present ? data.pinHash.value : this.pinHash,
      role: data.role.present ? data.role.value : this.role,
      fullName: data.fullName.present ? data.fullName.value : this.fullName,
      faceEmbedding: data.faceEmbedding.present
          ? data.faceEmbedding.value
          : this.faceEmbedding,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AppUser(')
          ..write('id: $id, ')
          ..write('orgId: $orgId, ')
          ..write('username: $username, ')
          ..write('pinHash: $pinHash, ')
          ..write('role: $role, ')
          ..write('fullName: $fullName, ')
          ..write('faceEmbedding: $faceEmbedding, ')
          ..write('isActive: $isActive, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, orgId, username, pinHash, role, fullName,
      faceEmbedding, isActive, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AppUser &&
          other.id == this.id &&
          other.orgId == this.orgId &&
          other.username == this.username &&
          other.pinHash == this.pinHash &&
          other.role == this.role &&
          other.fullName == this.fullName &&
          other.faceEmbedding == this.faceEmbedding &&
          other.isActive == this.isActive &&
          other.createdAt == this.createdAt);
}

class AppUsersCompanion extends UpdateCompanion<AppUser> {
  final Value<String> id;
  final Value<String> orgId;
  final Value<String> username;
  final Value<String> pinHash;
  final Value<String> role;
  final Value<String> fullName;
  final Value<String?> faceEmbedding;
  final Value<bool> isActive;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const AppUsersCompanion({
    this.id = const Value.absent(),
    this.orgId = const Value.absent(),
    this.username = const Value.absent(),
    this.pinHash = const Value.absent(),
    this.role = const Value.absent(),
    this.fullName = const Value.absent(),
    this.faceEmbedding = const Value.absent(),
    this.isActive = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AppUsersCompanion.insert({
    required String id,
    required String orgId,
    required String username,
    required String pinHash,
    required String role,
    required String fullName,
    this.faceEmbedding = const Value.absent(),
    this.isActive = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        orgId = Value(orgId),
        username = Value(username),
        pinHash = Value(pinHash),
        role = Value(role),
        fullName = Value(fullName);
  static Insertable<AppUser> custom({
    Expression<String>? id,
    Expression<String>? orgId,
    Expression<String>? username,
    Expression<String>? pinHash,
    Expression<String>? role,
    Expression<String>? fullName,
    Expression<String>? faceEmbedding,
    Expression<bool>? isActive,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (orgId != null) 'org_id': orgId,
      if (username != null) 'username': username,
      if (pinHash != null) 'pin_hash': pinHash,
      if (role != null) 'role': role,
      if (fullName != null) 'full_name': fullName,
      if (faceEmbedding != null) 'face_embedding': faceEmbedding,
      if (isActive != null) 'is_active': isActive,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AppUsersCompanion copyWith(
      {Value<String>? id,
      Value<String>? orgId,
      Value<String>? username,
      Value<String>? pinHash,
      Value<String>? role,
      Value<String>? fullName,
      Value<String?>? faceEmbedding,
      Value<bool>? isActive,
      Value<DateTime>? createdAt,
      Value<int>? rowid}) {
    return AppUsersCompanion(
      id: id ?? this.id,
      orgId: orgId ?? this.orgId,
      username: username ?? this.username,
      pinHash: pinHash ?? this.pinHash,
      role: role ?? this.role,
      fullName: fullName ?? this.fullName,
      faceEmbedding: faceEmbedding ?? this.faceEmbedding,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (orgId.present) {
      map['org_id'] = Variable<String>(orgId.value);
    }
    if (username.present) {
      map['username'] = Variable<String>(username.value);
    }
    if (pinHash.present) {
      map['pin_hash'] = Variable<String>(pinHash.value);
    }
    if (role.present) {
      map['role'] = Variable<String>(role.value);
    }
    if (fullName.present) {
      map['full_name'] = Variable<String>(fullName.value);
    }
    if (faceEmbedding.present) {
      map['face_embedding'] = Variable<String>(faceEmbedding.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AppUsersCompanion(')
          ..write('id: $id, ')
          ..write('orgId: $orgId, ')
          ..write('username: $username, ')
          ..write('pinHash: $pinHash, ')
          ..write('role: $role, ')
          ..write('fullName: $fullName, ')
          ..write('faceEmbedding: $faceEmbedding, ')
          ..write('isActive: $isActive, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AttendanceRecordsTable extends AttendanceRecords
    with TableInfo<$AttendanceRecordsTable, AttendanceRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AttendanceRecordsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
      'user_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES app_users (id)'));
  static const VerificationMeta _orgIdMeta = const VerificationMeta('orgId');
  @override
  late final GeneratedColumn<String> orgId = GeneratedColumn<String>(
      'org_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES orgs (id)'));
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<DateTime> date = GeneratedColumn<DateTime>(
      'date', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _checkInMeta =
      const VerificationMeta('checkIn');
  @override
  late final GeneratedColumn<DateTime> checkIn = GeneratedColumn<DateTime>(
      'check_in', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _checkOutMeta =
      const VerificationMeta('checkOut');
  @override
  late final GeneratedColumn<DateTime> checkOut = GeneratedColumn<DateTime>(
      'check_out', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _durationMinutesMeta =
      const VerificationMeta('durationMinutes');
  @override
  late final GeneratedColumn<int> durationMinutes = GeneratedColumn<int>(
      'duration_minutes', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _methodMeta = const VerificationMeta('method');
  @override
  late final GeneratedColumn<String> method = GeneratedColumn<String>(
      'method', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
      'status', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('present'));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        userId,
        orgId,
        date,
        checkIn,
        checkOut,
        durationMinutes,
        method,
        status,
        createdAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'attendance_records';
  @override
  VerificationContext validateIntegrity(Insertable<AttendanceRecord> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(_userIdMeta,
          userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta));
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('org_id')) {
      context.handle(
          _orgIdMeta, orgId.isAcceptableOrUnknown(data['org_id']!, _orgIdMeta));
    } else if (isInserting) {
      context.missing(_orgIdMeta);
    }
    if (data.containsKey('date')) {
      context.handle(
          _dateMeta, date.isAcceptableOrUnknown(data['date']!, _dateMeta));
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('check_in')) {
      context.handle(_checkInMeta,
          checkIn.isAcceptableOrUnknown(data['check_in']!, _checkInMeta));
    }
    if (data.containsKey('check_out')) {
      context.handle(_checkOutMeta,
          checkOut.isAcceptableOrUnknown(data['check_out']!, _checkOutMeta));
    }
    if (data.containsKey('duration_minutes')) {
      context.handle(
          _durationMinutesMeta,
          durationMinutes.isAcceptableOrUnknown(
              data['duration_minutes']!, _durationMinutesMeta));
    }
    if (data.containsKey('method')) {
      context.handle(_methodMeta,
          method.isAcceptableOrUnknown(data['method']!, _methodMeta));
    }
    if (data.containsKey('status')) {
      context.handle(_statusMeta,
          status.isAcceptableOrUnknown(data['status']!, _statusMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AttendanceRecord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AttendanceRecord(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      userId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}user_id'])!,
      orgId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}org_id'])!,
      date: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}date'])!,
      checkIn: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}check_in']),
      checkOut: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}check_out']),
      durationMinutes: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}duration_minutes']),
      method: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}method']),
      status: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}status'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $AttendanceRecordsTable createAlias(String alias) {
    return $AttendanceRecordsTable(attachedDatabase, alias);
  }
}

class AttendanceRecord extends DataClass
    implements Insertable<AttendanceRecord> {
  final String id;
  final String userId;
  final String orgId;
  final DateTime date;
  final DateTime? checkIn;
  final DateTime? checkOut;
  final int? durationMinutes;
  final String? method;
  final String status;
  final DateTime createdAt;
  const AttendanceRecord(
      {required this.id,
      required this.userId,
      required this.orgId,
      required this.date,
      this.checkIn,
      this.checkOut,
      this.durationMinutes,
      this.method,
      required this.status,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['user_id'] = Variable<String>(userId);
    map['org_id'] = Variable<String>(orgId);
    map['date'] = Variable<DateTime>(date);
    if (!nullToAbsent || checkIn != null) {
      map['check_in'] = Variable<DateTime>(checkIn);
    }
    if (!nullToAbsent || checkOut != null) {
      map['check_out'] = Variable<DateTime>(checkOut);
    }
    if (!nullToAbsent || durationMinutes != null) {
      map['duration_minutes'] = Variable<int>(durationMinutes);
    }
    if (!nullToAbsent || method != null) {
      map['method'] = Variable<String>(method);
    }
    map['status'] = Variable<String>(status);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  AttendanceRecordsCompanion toCompanion(bool nullToAbsent) {
    return AttendanceRecordsCompanion(
      id: Value(id),
      userId: Value(userId),
      orgId: Value(orgId),
      date: Value(date),
      checkIn: checkIn == null && nullToAbsent
          ? const Value.absent()
          : Value(checkIn),
      checkOut: checkOut == null && nullToAbsent
          ? const Value.absent()
          : Value(checkOut),
      durationMinutes: durationMinutes == null && nullToAbsent
          ? const Value.absent()
          : Value(durationMinutes),
      method:
          method == null && nullToAbsent ? const Value.absent() : Value(method),
      status: Value(status),
      createdAt: Value(createdAt),
    );
  }

  factory AttendanceRecord.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AttendanceRecord(
      id: serializer.fromJson<String>(json['id']),
      userId: serializer.fromJson<String>(json['userId']),
      orgId: serializer.fromJson<String>(json['orgId']),
      date: serializer.fromJson<DateTime>(json['date']),
      checkIn: serializer.fromJson<DateTime?>(json['checkIn']),
      checkOut: serializer.fromJson<DateTime?>(json['checkOut']),
      durationMinutes: serializer.fromJson<int?>(json['durationMinutes']),
      method: serializer.fromJson<String?>(json['method']),
      status: serializer.fromJson<String>(json['status']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'userId': serializer.toJson<String>(userId),
      'orgId': serializer.toJson<String>(orgId),
      'date': serializer.toJson<DateTime>(date),
      'checkIn': serializer.toJson<DateTime?>(checkIn),
      'checkOut': serializer.toJson<DateTime?>(checkOut),
      'durationMinutes': serializer.toJson<int?>(durationMinutes),
      'method': serializer.toJson<String?>(method),
      'status': serializer.toJson<String>(status),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  AttendanceRecord copyWith(
          {String? id,
          String? userId,
          String? orgId,
          DateTime? date,
          Value<DateTime?> checkIn = const Value.absent(),
          Value<DateTime?> checkOut = const Value.absent(),
          Value<int?> durationMinutes = const Value.absent(),
          Value<String?> method = const Value.absent(),
          String? status,
          DateTime? createdAt}) =>
      AttendanceRecord(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        orgId: orgId ?? this.orgId,
        date: date ?? this.date,
        checkIn: checkIn.present ? checkIn.value : this.checkIn,
        checkOut: checkOut.present ? checkOut.value : this.checkOut,
        durationMinutes: durationMinutes.present
            ? durationMinutes.value
            : this.durationMinutes,
        method: method.present ? method.value : this.method,
        status: status ?? this.status,
        createdAt: createdAt ?? this.createdAt,
      );
  AttendanceRecord copyWithCompanion(AttendanceRecordsCompanion data) {
    return AttendanceRecord(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      orgId: data.orgId.present ? data.orgId.value : this.orgId,
      date: data.date.present ? data.date.value : this.date,
      checkIn: data.checkIn.present ? data.checkIn.value : this.checkIn,
      checkOut: data.checkOut.present ? data.checkOut.value : this.checkOut,
      durationMinutes: data.durationMinutes.present
          ? data.durationMinutes.value
          : this.durationMinutes,
      method: data.method.present ? data.method.value : this.method,
      status: data.status.present ? data.status.value : this.status,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AttendanceRecord(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('orgId: $orgId, ')
          ..write('date: $date, ')
          ..write('checkIn: $checkIn, ')
          ..write('checkOut: $checkOut, ')
          ..write('durationMinutes: $durationMinutes, ')
          ..write('method: $method, ')
          ..write('status: $status, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, userId, orgId, date, checkIn, checkOut,
      durationMinutes, method, status, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AttendanceRecord &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.orgId == this.orgId &&
          other.date == this.date &&
          other.checkIn == this.checkIn &&
          other.checkOut == this.checkOut &&
          other.durationMinutes == this.durationMinutes &&
          other.method == this.method &&
          other.status == this.status &&
          other.createdAt == this.createdAt);
}

class AttendanceRecordsCompanion extends UpdateCompanion<AttendanceRecord> {
  final Value<String> id;
  final Value<String> userId;
  final Value<String> orgId;
  final Value<DateTime> date;
  final Value<DateTime?> checkIn;
  final Value<DateTime?> checkOut;
  final Value<int?> durationMinutes;
  final Value<String?> method;
  final Value<String> status;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const AttendanceRecordsCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.orgId = const Value.absent(),
    this.date = const Value.absent(),
    this.checkIn = const Value.absent(),
    this.checkOut = const Value.absent(),
    this.durationMinutes = const Value.absent(),
    this.method = const Value.absent(),
    this.status = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AttendanceRecordsCompanion.insert({
    required String id,
    required String userId,
    required String orgId,
    required DateTime date,
    this.checkIn = const Value.absent(),
    this.checkOut = const Value.absent(),
    this.durationMinutes = const Value.absent(),
    this.method = const Value.absent(),
    this.status = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        userId = Value(userId),
        orgId = Value(orgId),
        date = Value(date);
  static Insertable<AttendanceRecord> custom({
    Expression<String>? id,
    Expression<String>? userId,
    Expression<String>? orgId,
    Expression<DateTime>? date,
    Expression<DateTime>? checkIn,
    Expression<DateTime>? checkOut,
    Expression<int>? durationMinutes,
    Expression<String>? method,
    Expression<String>? status,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (orgId != null) 'org_id': orgId,
      if (date != null) 'date': date,
      if (checkIn != null) 'check_in': checkIn,
      if (checkOut != null) 'check_out': checkOut,
      if (durationMinutes != null) 'duration_minutes': durationMinutes,
      if (method != null) 'method': method,
      if (status != null) 'status': status,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AttendanceRecordsCompanion copyWith(
      {Value<String>? id,
      Value<String>? userId,
      Value<String>? orgId,
      Value<DateTime>? date,
      Value<DateTime?>? checkIn,
      Value<DateTime?>? checkOut,
      Value<int?>? durationMinutes,
      Value<String?>? method,
      Value<String>? status,
      Value<DateTime>? createdAt,
      Value<int>? rowid}) {
    return AttendanceRecordsCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      orgId: orgId ?? this.orgId,
      date: date ?? this.date,
      checkIn: checkIn ?? this.checkIn,
      checkOut: checkOut ?? this.checkOut,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      method: method ?? this.method,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (orgId.present) {
      map['org_id'] = Variable<String>(orgId.value);
    }
    if (date.present) {
      map['date'] = Variable<DateTime>(date.value);
    }
    if (checkIn.present) {
      map['check_in'] = Variable<DateTime>(checkIn.value);
    }
    if (checkOut.present) {
      map['check_out'] = Variable<DateTime>(checkOut.value);
    }
    if (durationMinutes.present) {
      map['duration_minutes'] = Variable<int>(durationMinutes.value);
    }
    if (method.present) {
      map['method'] = Variable<String>(method.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AttendanceRecordsCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('orgId: $orgId, ')
          ..write('date: $date, ')
          ..write('checkIn: $checkIn, ')
          ..write('checkOut: $checkOut, ')
          ..write('durationMinutes: $durationMinutes, ')
          ..write('method: $method, ')
          ..write('status: $status, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $OrgsTable orgs = $OrgsTable(this);
  late final $AppUsersTable appUsers = $AppUsersTable(this);
  late final $AttendanceRecordsTable attendanceRecords =
      $AttendanceRecordsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities =>
      [orgs, appUsers, attendanceRecords];
}

typedef $$OrgsTableCreateCompanionBuilder = OrgsCompanion Function({
  required String id,
  required String name,
  required String orgSecret,
  Value<String> allowedMethods,
  Value<double?> officeLat,
  Value<double?> officeLng,
  Value<double> geofenceRadius,
  Value<String> officeHoursStart,
  Value<String> officeHoursEnd,
  Value<DateTime> createdAt,
  Value<int> rowid,
});
typedef $$OrgsTableUpdateCompanionBuilder = OrgsCompanion Function({
  Value<String> id,
  Value<String> name,
  Value<String> orgSecret,
  Value<String> allowedMethods,
  Value<double?> officeLat,
  Value<double?> officeLng,
  Value<double> geofenceRadius,
  Value<String> officeHoursStart,
  Value<String> officeHoursEnd,
  Value<DateTime> createdAt,
  Value<int> rowid,
});

final class $$OrgsTableReferences
    extends BaseReferences<_$AppDatabase, $OrgsTable, Org> {
  $$OrgsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$AppUsersTable, List<AppUser>> _appUsersRefsTable(
          _$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.appUsers,
          aliasName: $_aliasNameGenerator(db.orgs.id, db.appUsers.orgId));

  $$AppUsersTableProcessedTableManager get appUsersRefs {
    final manager = $$AppUsersTableTableManager($_db, $_db.appUsers)
        .filter((f) => f.orgId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_appUsersRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$AttendanceRecordsTable, List<AttendanceRecord>>
      _attendanceRecordsRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.attendanceRecords,
              aliasName:
                  $_aliasNameGenerator(db.orgs.id, db.attendanceRecords.orgId));

  $$AttendanceRecordsTableProcessedTableManager get attendanceRecordsRefs {
    final manager =
        $$AttendanceRecordsTableTableManager($_db, $_db.attendanceRecords)
            .filter((f) => f.orgId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache =
        $_typedResult.readTableOrNull(_attendanceRecordsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$OrgsTableFilterComposer extends Composer<_$AppDatabase, $OrgsTable> {
  $$OrgsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get orgSecret => $composableBuilder(
      column: $table.orgSecret, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get allowedMethods => $composableBuilder(
      column: $table.allowedMethods,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get officeLat => $composableBuilder(
      column: $table.officeLat, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get officeLng => $composableBuilder(
      column: $table.officeLng, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get geofenceRadius => $composableBuilder(
      column: $table.geofenceRadius,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get officeHoursStart => $composableBuilder(
      column: $table.officeHoursStart,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get officeHoursEnd => $composableBuilder(
      column: $table.officeHoursEnd,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  Expression<bool> appUsersRefs(
      Expression<bool> Function($$AppUsersTableFilterComposer f) f) {
    final $$AppUsersTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.appUsers,
        getReferencedColumn: (t) => t.orgId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$AppUsersTableFilterComposer(
              $db: $db,
              $table: $db.appUsers,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> attendanceRecordsRefs(
      Expression<bool> Function($$AttendanceRecordsTableFilterComposer f) f) {
    final $$AttendanceRecordsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.attendanceRecords,
        getReferencedColumn: (t) => t.orgId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$AttendanceRecordsTableFilterComposer(
              $db: $db,
              $table: $db.attendanceRecords,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$OrgsTableOrderingComposer extends Composer<_$AppDatabase, $OrgsTable> {
  $$OrgsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get orgSecret => $composableBuilder(
      column: $table.orgSecret, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get allowedMethods => $composableBuilder(
      column: $table.allowedMethods,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get officeLat => $composableBuilder(
      column: $table.officeLat, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get officeLng => $composableBuilder(
      column: $table.officeLng, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get geofenceRadius => $composableBuilder(
      column: $table.geofenceRadius,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get officeHoursStart => $composableBuilder(
      column: $table.officeHoursStart,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get officeHoursEnd => $composableBuilder(
      column: $table.officeHoursEnd,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));
}

class $$OrgsTableAnnotationComposer
    extends Composer<_$AppDatabase, $OrgsTable> {
  $$OrgsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get orgSecret =>
      $composableBuilder(column: $table.orgSecret, builder: (column) => column);

  GeneratedColumn<String> get allowedMethods => $composableBuilder(
      column: $table.allowedMethods, builder: (column) => column);

  GeneratedColumn<double> get officeLat =>
      $composableBuilder(column: $table.officeLat, builder: (column) => column);

  GeneratedColumn<double> get officeLng =>
      $composableBuilder(column: $table.officeLng, builder: (column) => column);

  GeneratedColumn<double> get geofenceRadius => $composableBuilder(
      column: $table.geofenceRadius, builder: (column) => column);

  GeneratedColumn<String> get officeHoursStart => $composableBuilder(
      column: $table.officeHoursStart, builder: (column) => column);

  GeneratedColumn<String> get officeHoursEnd => $composableBuilder(
      column: $table.officeHoursEnd, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  Expression<T> appUsersRefs<T extends Object>(
      Expression<T> Function($$AppUsersTableAnnotationComposer a) f) {
    final $$AppUsersTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.appUsers,
        getReferencedColumn: (t) => t.orgId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$AppUsersTableAnnotationComposer(
              $db: $db,
              $table: $db.appUsers,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> attendanceRecordsRefs<T extends Object>(
      Expression<T> Function($$AttendanceRecordsTableAnnotationComposer a) f) {
    final $$AttendanceRecordsTableAnnotationComposer composer =
        $composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.id,
            referencedTable: $db.attendanceRecords,
            getReferencedColumn: (t) => t.orgId,
            builder: (joinBuilder,
                    {$addJoinBuilderToRootComposer,
                    $removeJoinBuilderFromRootComposer}) =>
                $$AttendanceRecordsTableAnnotationComposer(
                  $db: $db,
                  $table: $db.attendanceRecords,
                  $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                  joinBuilder: joinBuilder,
                  $removeJoinBuilderFromRootComposer:
                      $removeJoinBuilderFromRootComposer,
                ));
    return f(composer);
  }
}

class $$OrgsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $OrgsTable,
    Org,
    $$OrgsTableFilterComposer,
    $$OrgsTableOrderingComposer,
    $$OrgsTableAnnotationComposer,
    $$OrgsTableCreateCompanionBuilder,
    $$OrgsTableUpdateCompanionBuilder,
    (Org, $$OrgsTableReferences),
    Org,
    PrefetchHooks Function({bool appUsersRefs, bool attendanceRecordsRefs})> {
  $$OrgsTableTableManager(_$AppDatabase db, $OrgsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$OrgsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$OrgsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$OrgsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String> orgSecret = const Value.absent(),
            Value<String> allowedMethods = const Value.absent(),
            Value<double?> officeLat = const Value.absent(),
            Value<double?> officeLng = const Value.absent(),
            Value<double> geofenceRadius = const Value.absent(),
            Value<String> officeHoursStart = const Value.absent(),
            Value<String> officeHoursEnd = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              OrgsCompanion(
            id: id,
            name: name,
            orgSecret: orgSecret,
            allowedMethods: allowedMethods,
            officeLat: officeLat,
            officeLng: officeLng,
            geofenceRadius: geofenceRadius,
            officeHoursStart: officeHoursStart,
            officeHoursEnd: officeHoursEnd,
            createdAt: createdAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String name,
            required String orgSecret,
            Value<String> allowedMethods = const Value.absent(),
            Value<double?> officeLat = const Value.absent(),
            Value<double?> officeLng = const Value.absent(),
            Value<double> geofenceRadius = const Value.absent(),
            Value<String> officeHoursStart = const Value.absent(),
            Value<String> officeHoursEnd = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              OrgsCompanion.insert(
            id: id,
            name: name,
            orgSecret: orgSecret,
            allowedMethods: allowedMethods,
            officeLat: officeLat,
            officeLng: officeLng,
            geofenceRadius: geofenceRadius,
            officeHoursStart: officeHoursStart,
            officeHoursEnd: officeHoursEnd,
            createdAt: createdAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) =>
                  (e.readTable(table), $$OrgsTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: (
              {appUsersRefs = false, attendanceRecordsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (appUsersRefs) db.appUsers,
                if (attendanceRecordsRefs) db.attendanceRecords
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (appUsersRefs)
                    await $_getPrefetchedData<Org, $OrgsTable, AppUser>(
                        currentTable: table,
                        referencedTable:
                            $$OrgsTableReferences._appUsersRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$OrgsTableReferences(db, table, p0).appUsersRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.orgId == item.id),
                        typedResults: items),
                  if (attendanceRecordsRefs)
                    await $_getPrefetchedData<Org, $OrgsTable,
                            AttendanceRecord>(
                        currentTable: table,
                        referencedTable: $$OrgsTableReferences
                            ._attendanceRecordsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$OrgsTableReferences(db, table, p0)
                                .attendanceRecordsRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.orgId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$OrgsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $OrgsTable,
    Org,
    $$OrgsTableFilterComposer,
    $$OrgsTableOrderingComposer,
    $$OrgsTableAnnotationComposer,
    $$OrgsTableCreateCompanionBuilder,
    $$OrgsTableUpdateCompanionBuilder,
    (Org, $$OrgsTableReferences),
    Org,
    PrefetchHooks Function({bool appUsersRefs, bool attendanceRecordsRefs})>;
typedef $$AppUsersTableCreateCompanionBuilder = AppUsersCompanion Function({
  required String id,
  required String orgId,
  required String username,
  required String pinHash,
  required String role,
  required String fullName,
  Value<String?> faceEmbedding,
  Value<bool> isActive,
  Value<DateTime> createdAt,
  Value<int> rowid,
});
typedef $$AppUsersTableUpdateCompanionBuilder = AppUsersCompanion Function({
  Value<String> id,
  Value<String> orgId,
  Value<String> username,
  Value<String> pinHash,
  Value<String> role,
  Value<String> fullName,
  Value<String?> faceEmbedding,
  Value<bool> isActive,
  Value<DateTime> createdAt,
  Value<int> rowid,
});

final class $$AppUsersTableReferences
    extends BaseReferences<_$AppDatabase, $AppUsersTable, AppUser> {
  $$AppUsersTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $OrgsTable _orgIdTable(_$AppDatabase db) =>
      db.orgs.createAlias($_aliasNameGenerator(db.appUsers.orgId, db.orgs.id));

  $$OrgsTableProcessedTableManager get orgId {
    final $_column = $_itemColumn<String>('org_id')!;

    final manager = $$OrgsTableTableManager($_db, $_db.orgs)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_orgIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static MultiTypedResultKey<$AttendanceRecordsTable, List<AttendanceRecord>>
      _attendanceRecordsRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.attendanceRecords,
              aliasName: $_aliasNameGenerator(
                  db.appUsers.id, db.attendanceRecords.userId));

  $$AttendanceRecordsTableProcessedTableManager get attendanceRecordsRefs {
    final manager =
        $$AttendanceRecordsTableTableManager($_db, $_db.attendanceRecords)
            .filter((f) => f.userId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache =
        $_typedResult.readTableOrNull(_attendanceRecordsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$AppUsersTableFilterComposer
    extends Composer<_$AppDatabase, $AppUsersTable> {
  $$AppUsersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get username => $composableBuilder(
      column: $table.username, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get pinHash => $composableBuilder(
      column: $table.pinHash, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get role => $composableBuilder(
      column: $table.role, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get fullName => $composableBuilder(
      column: $table.fullName, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get faceEmbedding => $composableBuilder(
      column: $table.faceEmbedding, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isActive => $composableBuilder(
      column: $table.isActive, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  $$OrgsTableFilterComposer get orgId {
    final $$OrgsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.orgId,
        referencedTable: $db.orgs,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$OrgsTableFilterComposer(
              $db: $db,
              $table: $db.orgs,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  Expression<bool> attendanceRecordsRefs(
      Expression<bool> Function($$AttendanceRecordsTableFilterComposer f) f) {
    final $$AttendanceRecordsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.attendanceRecords,
        getReferencedColumn: (t) => t.userId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$AttendanceRecordsTableFilterComposer(
              $db: $db,
              $table: $db.attendanceRecords,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$AppUsersTableOrderingComposer
    extends Composer<_$AppDatabase, $AppUsersTable> {
  $$AppUsersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get username => $composableBuilder(
      column: $table.username, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get pinHash => $composableBuilder(
      column: $table.pinHash, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get role => $composableBuilder(
      column: $table.role, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get fullName => $composableBuilder(
      column: $table.fullName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get faceEmbedding => $composableBuilder(
      column: $table.faceEmbedding,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isActive => $composableBuilder(
      column: $table.isActive, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  $$OrgsTableOrderingComposer get orgId {
    final $$OrgsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.orgId,
        referencedTable: $db.orgs,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$OrgsTableOrderingComposer(
              $db: $db,
              $table: $db.orgs,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$AppUsersTableAnnotationComposer
    extends Composer<_$AppDatabase, $AppUsersTable> {
  $$AppUsersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get username =>
      $composableBuilder(column: $table.username, builder: (column) => column);

  GeneratedColumn<String> get pinHash =>
      $composableBuilder(column: $table.pinHash, builder: (column) => column);

  GeneratedColumn<String> get role =>
      $composableBuilder(column: $table.role, builder: (column) => column);

  GeneratedColumn<String> get fullName =>
      $composableBuilder(column: $table.fullName, builder: (column) => column);

  GeneratedColumn<String> get faceEmbedding => $composableBuilder(
      column: $table.faceEmbedding, builder: (column) => column);

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$OrgsTableAnnotationComposer get orgId {
    final $$OrgsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.orgId,
        referencedTable: $db.orgs,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$OrgsTableAnnotationComposer(
              $db: $db,
              $table: $db.orgs,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  Expression<T> attendanceRecordsRefs<T extends Object>(
      Expression<T> Function($$AttendanceRecordsTableAnnotationComposer a) f) {
    final $$AttendanceRecordsTableAnnotationComposer composer =
        $composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.id,
            referencedTable: $db.attendanceRecords,
            getReferencedColumn: (t) => t.userId,
            builder: (joinBuilder,
                    {$addJoinBuilderToRootComposer,
                    $removeJoinBuilderFromRootComposer}) =>
                $$AttendanceRecordsTableAnnotationComposer(
                  $db: $db,
                  $table: $db.attendanceRecords,
                  $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                  joinBuilder: joinBuilder,
                  $removeJoinBuilderFromRootComposer:
                      $removeJoinBuilderFromRootComposer,
                ));
    return f(composer);
  }
}

class $$AppUsersTableTableManager extends RootTableManager<
    _$AppDatabase,
    $AppUsersTable,
    AppUser,
    $$AppUsersTableFilterComposer,
    $$AppUsersTableOrderingComposer,
    $$AppUsersTableAnnotationComposer,
    $$AppUsersTableCreateCompanionBuilder,
    $$AppUsersTableUpdateCompanionBuilder,
    (AppUser, $$AppUsersTableReferences),
    AppUser,
    PrefetchHooks Function({bool orgId, bool attendanceRecordsRefs})> {
  $$AppUsersTableTableManager(_$AppDatabase db, $AppUsersTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AppUsersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AppUsersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AppUsersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> orgId = const Value.absent(),
            Value<String> username = const Value.absent(),
            Value<String> pinHash = const Value.absent(),
            Value<String> role = const Value.absent(),
            Value<String> fullName = const Value.absent(),
            Value<String?> faceEmbedding = const Value.absent(),
            Value<bool> isActive = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              AppUsersCompanion(
            id: id,
            orgId: orgId,
            username: username,
            pinHash: pinHash,
            role: role,
            fullName: fullName,
            faceEmbedding: faceEmbedding,
            isActive: isActive,
            createdAt: createdAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String orgId,
            required String username,
            required String pinHash,
            required String role,
            required String fullName,
            Value<String?> faceEmbedding = const Value.absent(),
            Value<bool> isActive = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              AppUsersCompanion.insert(
            id: id,
            orgId: orgId,
            username: username,
            pinHash: pinHash,
            role: role,
            fullName: fullName,
            faceEmbedding: faceEmbedding,
            isActive: isActive,
            createdAt: createdAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) =>
                  (e.readTable(table), $$AppUsersTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: (
              {orgId = false, attendanceRecordsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (attendanceRecordsRefs) db.attendanceRecords
              ],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (orgId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.orgId,
                    referencedTable: $$AppUsersTableReferences._orgIdTable(db),
                    referencedColumn:
                        $$AppUsersTableReferences._orgIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [
                  if (attendanceRecordsRefs)
                    await $_getPrefetchedData<AppUser, $AppUsersTable,
                            AttendanceRecord>(
                        currentTable: table,
                        referencedTable: $$AppUsersTableReferences
                            ._attendanceRecordsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$AppUsersTableReferences(db, table, p0)
                                .attendanceRecordsRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.userId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$AppUsersTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $AppUsersTable,
    AppUser,
    $$AppUsersTableFilterComposer,
    $$AppUsersTableOrderingComposer,
    $$AppUsersTableAnnotationComposer,
    $$AppUsersTableCreateCompanionBuilder,
    $$AppUsersTableUpdateCompanionBuilder,
    (AppUser, $$AppUsersTableReferences),
    AppUser,
    PrefetchHooks Function({bool orgId, bool attendanceRecordsRefs})>;
typedef $$AttendanceRecordsTableCreateCompanionBuilder
    = AttendanceRecordsCompanion Function({
  required String id,
  required String userId,
  required String orgId,
  required DateTime date,
  Value<DateTime?> checkIn,
  Value<DateTime?> checkOut,
  Value<int?> durationMinutes,
  Value<String?> method,
  Value<String> status,
  Value<DateTime> createdAt,
  Value<int> rowid,
});
typedef $$AttendanceRecordsTableUpdateCompanionBuilder
    = AttendanceRecordsCompanion Function({
  Value<String> id,
  Value<String> userId,
  Value<String> orgId,
  Value<DateTime> date,
  Value<DateTime?> checkIn,
  Value<DateTime?> checkOut,
  Value<int?> durationMinutes,
  Value<String?> method,
  Value<String> status,
  Value<DateTime> createdAt,
  Value<int> rowid,
});

final class $$AttendanceRecordsTableReferences extends BaseReferences<
    _$AppDatabase, $AttendanceRecordsTable, AttendanceRecord> {
  $$AttendanceRecordsTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static $AppUsersTable _userIdTable(_$AppDatabase db) =>
      db.appUsers.createAlias(
          $_aliasNameGenerator(db.attendanceRecords.userId, db.appUsers.id));

  $$AppUsersTableProcessedTableManager get userId {
    final $_column = $_itemColumn<String>('user_id')!;

    final manager = $$AppUsersTableTableManager($_db, $_db.appUsers)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_userIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static $OrgsTable _orgIdTable(_$AppDatabase db) => db.orgs.createAlias(
      $_aliasNameGenerator(db.attendanceRecords.orgId, db.orgs.id));

  $$OrgsTableProcessedTableManager get orgId {
    final $_column = $_itemColumn<String>('org_id')!;

    final manager = $$OrgsTableTableManager($_db, $_db.orgs)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_orgIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$AttendanceRecordsTableFilterComposer
    extends Composer<_$AppDatabase, $AttendanceRecordsTable> {
  $$AttendanceRecordsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get date => $composableBuilder(
      column: $table.date, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get checkIn => $composableBuilder(
      column: $table.checkIn, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get checkOut => $composableBuilder(
      column: $table.checkOut, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get durationMinutes => $composableBuilder(
      column: $table.durationMinutes,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get method => $composableBuilder(
      column: $table.method, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  $$AppUsersTableFilterComposer get userId {
    final $$AppUsersTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.userId,
        referencedTable: $db.appUsers,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$AppUsersTableFilterComposer(
              $db: $db,
              $table: $db.appUsers,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$OrgsTableFilterComposer get orgId {
    final $$OrgsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.orgId,
        referencedTable: $db.orgs,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$OrgsTableFilterComposer(
              $db: $db,
              $table: $db.orgs,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$AttendanceRecordsTableOrderingComposer
    extends Composer<_$AppDatabase, $AttendanceRecordsTable> {
  $$AttendanceRecordsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get date => $composableBuilder(
      column: $table.date, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get checkIn => $composableBuilder(
      column: $table.checkIn, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get checkOut => $composableBuilder(
      column: $table.checkOut, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get durationMinutes => $composableBuilder(
      column: $table.durationMinutes,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get method => $composableBuilder(
      column: $table.method, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  $$AppUsersTableOrderingComposer get userId {
    final $$AppUsersTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.userId,
        referencedTable: $db.appUsers,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$AppUsersTableOrderingComposer(
              $db: $db,
              $table: $db.appUsers,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$OrgsTableOrderingComposer get orgId {
    final $$OrgsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.orgId,
        referencedTable: $db.orgs,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$OrgsTableOrderingComposer(
              $db: $db,
              $table: $db.orgs,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$AttendanceRecordsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AttendanceRecordsTable> {
  $$AttendanceRecordsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<DateTime> get checkIn =>
      $composableBuilder(column: $table.checkIn, builder: (column) => column);

  GeneratedColumn<DateTime> get checkOut =>
      $composableBuilder(column: $table.checkOut, builder: (column) => column);

  GeneratedColumn<int> get durationMinutes => $composableBuilder(
      column: $table.durationMinutes, builder: (column) => column);

  GeneratedColumn<String> get method =>
      $composableBuilder(column: $table.method, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$AppUsersTableAnnotationComposer get userId {
    final $$AppUsersTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.userId,
        referencedTable: $db.appUsers,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$AppUsersTableAnnotationComposer(
              $db: $db,
              $table: $db.appUsers,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$OrgsTableAnnotationComposer get orgId {
    final $$OrgsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.orgId,
        referencedTable: $db.orgs,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$OrgsTableAnnotationComposer(
              $db: $db,
              $table: $db.orgs,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$AttendanceRecordsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $AttendanceRecordsTable,
    AttendanceRecord,
    $$AttendanceRecordsTableFilterComposer,
    $$AttendanceRecordsTableOrderingComposer,
    $$AttendanceRecordsTableAnnotationComposer,
    $$AttendanceRecordsTableCreateCompanionBuilder,
    $$AttendanceRecordsTableUpdateCompanionBuilder,
    (AttendanceRecord, $$AttendanceRecordsTableReferences),
    AttendanceRecord,
    PrefetchHooks Function({bool userId, bool orgId})> {
  $$AttendanceRecordsTableTableManager(
      _$AppDatabase db, $AttendanceRecordsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AttendanceRecordsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AttendanceRecordsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AttendanceRecordsTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> userId = const Value.absent(),
            Value<String> orgId = const Value.absent(),
            Value<DateTime> date = const Value.absent(),
            Value<DateTime?> checkIn = const Value.absent(),
            Value<DateTime?> checkOut = const Value.absent(),
            Value<int?> durationMinutes = const Value.absent(),
            Value<String?> method = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              AttendanceRecordsCompanion(
            id: id,
            userId: userId,
            orgId: orgId,
            date: date,
            checkIn: checkIn,
            checkOut: checkOut,
            durationMinutes: durationMinutes,
            method: method,
            status: status,
            createdAt: createdAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String userId,
            required String orgId,
            required DateTime date,
            Value<DateTime?> checkIn = const Value.absent(),
            Value<DateTime?> checkOut = const Value.absent(),
            Value<int?> durationMinutes = const Value.absent(),
            Value<String?> method = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              AttendanceRecordsCompanion.insert(
            id: id,
            userId: userId,
            orgId: orgId,
            date: date,
            checkIn: checkIn,
            checkOut: checkOut,
            durationMinutes: durationMinutes,
            method: method,
            status: status,
            createdAt: createdAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$AttendanceRecordsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({userId = false, orgId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (userId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.userId,
                    referencedTable:
                        $$AttendanceRecordsTableReferences._userIdTable(db),
                    referencedColumn:
                        $$AttendanceRecordsTableReferences._userIdTable(db).id,
                  ) as T;
                }
                if (orgId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.orgId,
                    referencedTable:
                        $$AttendanceRecordsTableReferences._orgIdTable(db),
                    referencedColumn:
                        $$AttendanceRecordsTableReferences._orgIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$AttendanceRecordsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $AttendanceRecordsTable,
    AttendanceRecord,
    $$AttendanceRecordsTableFilterComposer,
    $$AttendanceRecordsTableOrderingComposer,
    $$AttendanceRecordsTableAnnotationComposer,
    $$AttendanceRecordsTableCreateCompanionBuilder,
    $$AttendanceRecordsTableUpdateCompanionBuilder,
    (AttendanceRecord, $$AttendanceRecordsTableReferences),
    AttendanceRecord,
    PrefetchHooks Function({bool userId, bool orgId})>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$OrgsTableTableManager get orgs => $$OrgsTableTableManager(_db, _db.orgs);
  $$AppUsersTableTableManager get appUsers =>
      $$AppUsersTableTableManager(_db, _db.appUsers);
  $$AttendanceRecordsTableTableManager get attendanceRecords =>
      $$AttendanceRecordsTableTableManager(_db, _db.attendanceRecords);
}
