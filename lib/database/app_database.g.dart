// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $ProfilesTable extends Profiles with TableInfo<$ProfilesTable, Profile> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProfilesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 1, maxTextLength: 100),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _mikrotikIdMeta =
      const VerificationMeta('mikrotikId');
  @override
  late final GeneratedColumn<String> mikrotikId = GeneratedColumn<String>(
      'mikrotik_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _rateLimitMeta =
      const VerificationMeta('rateLimit');
  @override
  late final GeneratedColumn<String> rateLimit = GeneratedColumn<String>(
      'rate_limit', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _sharedUsersMeta =
      const VerificationMeta('sharedUsers');
  @override
  late final GeneratedColumn<int> sharedUsers = GeneratedColumn<int>(
      'shared_users', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(1));
  static const VerificationMeta _uploadUsedBytesMeta =
      const VerificationMeta('uploadUsedBytes');
  @override
  late final GeneratedColumn<int> uploadUsedBytes = GeneratedColumn<int>(
      'upload_used_bytes', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _downloadUsedBytesMeta =
      const VerificationMeta('downloadUsedBytes');
  @override
  late final GeneratedColumn<int> downloadUsedBytes = GeneratedColumn<int>(
      'download_used_bytes', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _uptimeLimitSecondsMeta =
      const VerificationMeta('uptimeLimitSeconds');
  @override
  late final GeneratedColumn<int> uptimeLimitSeconds = GeneratedColumn<int>(
      'uptime_limit_seconds', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _uptimeUsedSecondsMeta =
      const VerificationMeta('uptimeUsedSeconds');
  @override
  late final GeneratedColumn<int> uptimeUsedSeconds = GeneratedColumn<int>(
      'uptime_used_seconds', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _lastSyncedAtMeta =
      const VerificationMeta('lastSyncedAt');
  @override
  late final GeneratedColumn<DateTime> lastSyncedAt = GeneratedColumn<DateTime>(
      'last_synced_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        name,
        mikrotikId,
        rateLimit,
        sharedUsers,
        uploadUsedBytes,
        downloadUsedBytes,
        uptimeLimitSeconds,
        uptimeUsedSeconds,
        createdAt,
        lastSyncedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'profiles';
  @override
  VerificationContext validateIntegrity(Insertable<Profile> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('mikrotik_id')) {
      context.handle(
          _mikrotikIdMeta,
          mikrotikId.isAcceptableOrUnknown(
              data['mikrotik_id']!, _mikrotikIdMeta));
    }
    if (data.containsKey('rate_limit')) {
      context.handle(_rateLimitMeta,
          rateLimit.isAcceptableOrUnknown(data['rate_limit']!, _rateLimitMeta));
    }
    if (data.containsKey('shared_users')) {
      context.handle(
          _sharedUsersMeta,
          sharedUsers.isAcceptableOrUnknown(
              data['shared_users']!, _sharedUsersMeta));
    }
    if (data.containsKey('upload_used_bytes')) {
      context.handle(
          _uploadUsedBytesMeta,
          uploadUsedBytes.isAcceptableOrUnknown(
              data['upload_used_bytes']!, _uploadUsedBytesMeta));
    }
    if (data.containsKey('download_used_bytes')) {
      context.handle(
          _downloadUsedBytesMeta,
          downloadUsedBytes.isAcceptableOrUnknown(
              data['download_used_bytes']!, _downloadUsedBytesMeta));
    }
    if (data.containsKey('uptime_limit_seconds')) {
      context.handle(
          _uptimeLimitSecondsMeta,
          uptimeLimitSeconds.isAcceptableOrUnknown(
              data['uptime_limit_seconds']!, _uptimeLimitSecondsMeta));
    }
    if (data.containsKey('uptime_used_seconds')) {
      context.handle(
          _uptimeUsedSecondsMeta,
          uptimeUsedSeconds.isAcceptableOrUnknown(
              data['uptime_used_seconds']!, _uptimeUsedSecondsMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('last_synced_at')) {
      context.handle(
          _lastSyncedAtMeta,
          lastSyncedAt.isAcceptableOrUnknown(
              data['last_synced_at']!, _lastSyncedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
        {name},
      ];
  @override
  Profile map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Profile(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      mikrotikId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}mikrotik_id']),
      rateLimit: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}rate_limit']),
      sharedUsers: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}shared_users'])!,
      uploadUsedBytes: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}upload_used_bytes'])!,
      downloadUsedBytes: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}download_used_bytes'])!,
      uptimeLimitSeconds: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}uptime_limit_seconds']),
      uptimeUsedSeconds: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}uptime_used_seconds'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      lastSyncedAt: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}last_synced_at']),
    );
  }

  @override
  $ProfilesTable createAlias(String alias) {
    return $ProfilesTable(attachedDatabase, alias);
  }
}

class Profile extends DataClass implements Insertable<Profile> {
  final int id;
  final String name;
  final String? mikrotikId;
  final String? rateLimit;
  final int sharedUsers;
  final int uploadUsedBytes;
  final int downloadUsedBytes;
  final int? uptimeLimitSeconds;
  final int uptimeUsedSeconds;
  final DateTime createdAt;
  final DateTime? lastSyncedAt;
  const Profile(
      {required this.id,
      required this.name,
      this.mikrotikId,
      this.rateLimit,
      required this.sharedUsers,
      required this.uploadUsedBytes,
      required this.downloadUsedBytes,
      this.uptimeLimitSeconds,
      required this.uptimeUsedSeconds,
      required this.createdAt,
      this.lastSyncedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || mikrotikId != null) {
      map['mikrotik_id'] = Variable<String>(mikrotikId);
    }
    if (!nullToAbsent || rateLimit != null) {
      map['rate_limit'] = Variable<String>(rateLimit);
    }
    map['shared_users'] = Variable<int>(sharedUsers);
    map['upload_used_bytes'] = Variable<int>(uploadUsedBytes);
    map['download_used_bytes'] = Variable<int>(downloadUsedBytes);
    if (!nullToAbsent || uptimeLimitSeconds != null) {
      map['uptime_limit_seconds'] = Variable<int>(uptimeLimitSeconds);
    }
    map['uptime_used_seconds'] = Variable<int>(uptimeUsedSeconds);
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || lastSyncedAt != null) {
      map['last_synced_at'] = Variable<DateTime>(lastSyncedAt);
    }
    return map;
  }

  ProfilesCompanion toCompanion(bool nullToAbsent) {
    return ProfilesCompanion(
      id: Value(id),
      name: Value(name),
      mikrotikId: mikrotikId == null && nullToAbsent
          ? const Value.absent()
          : Value(mikrotikId),
      rateLimit: rateLimit == null && nullToAbsent
          ? const Value.absent()
          : Value(rateLimit),
      sharedUsers: Value(sharedUsers),
      uploadUsedBytes: Value(uploadUsedBytes),
      downloadUsedBytes: Value(downloadUsedBytes),
      uptimeLimitSeconds: uptimeLimitSeconds == null && nullToAbsent
          ? const Value.absent()
          : Value(uptimeLimitSeconds),
      uptimeUsedSeconds: Value(uptimeUsedSeconds),
      createdAt: Value(createdAt),
      lastSyncedAt: lastSyncedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastSyncedAt),
    );
  }

  factory Profile.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Profile(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      mikrotikId: serializer.fromJson<String?>(json['mikrotikId']),
      rateLimit: serializer.fromJson<String?>(json['rateLimit']),
      sharedUsers: serializer.fromJson<int>(json['sharedUsers']),
      uploadUsedBytes: serializer.fromJson<int>(json['uploadUsedBytes']),
      downloadUsedBytes: serializer.fromJson<int>(json['downloadUsedBytes']),
      uptimeLimitSeconds: serializer.fromJson<int?>(json['uptimeLimitSeconds']),
      uptimeUsedSeconds: serializer.fromJson<int>(json['uptimeUsedSeconds']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      lastSyncedAt: serializer.fromJson<DateTime?>(json['lastSyncedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'mikrotikId': serializer.toJson<String?>(mikrotikId),
      'rateLimit': serializer.toJson<String?>(rateLimit),
      'sharedUsers': serializer.toJson<int>(sharedUsers),
      'uploadUsedBytes': serializer.toJson<int>(uploadUsedBytes),
      'downloadUsedBytes': serializer.toJson<int>(downloadUsedBytes),
      'uptimeLimitSeconds': serializer.toJson<int?>(uptimeLimitSeconds),
      'uptimeUsedSeconds': serializer.toJson<int>(uptimeUsedSeconds),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'lastSyncedAt': serializer.toJson<DateTime?>(lastSyncedAt),
    };
  }

  Profile copyWith(
          {int? id,
          String? name,
          Value<String?> mikrotikId = const Value.absent(),
          Value<String?> rateLimit = const Value.absent(),
          int? sharedUsers,
          int? uploadUsedBytes,
          int? downloadUsedBytes,
          Value<int?> uptimeLimitSeconds = const Value.absent(),
          int? uptimeUsedSeconds,
          DateTime? createdAt,
          Value<DateTime?> lastSyncedAt = const Value.absent()}) =>
      Profile(
        id: id ?? this.id,
        name: name ?? this.name,
        mikrotikId: mikrotikId.present ? mikrotikId.value : this.mikrotikId,
        rateLimit: rateLimit.present ? rateLimit.value : this.rateLimit,
        sharedUsers: sharedUsers ?? this.sharedUsers,
        uploadUsedBytes: uploadUsedBytes ?? this.uploadUsedBytes,
        downloadUsedBytes: downloadUsedBytes ?? this.downloadUsedBytes,
        uptimeLimitSeconds: uptimeLimitSeconds.present
            ? uptimeLimitSeconds.value
            : this.uptimeLimitSeconds,
        uptimeUsedSeconds: uptimeUsedSeconds ?? this.uptimeUsedSeconds,
        createdAt: createdAt ?? this.createdAt,
        lastSyncedAt:
            lastSyncedAt.present ? lastSyncedAt.value : this.lastSyncedAt,
      );
  Profile copyWithCompanion(ProfilesCompanion data) {
    return Profile(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      mikrotikId:
          data.mikrotikId.present ? data.mikrotikId.value : this.mikrotikId,
      rateLimit: data.rateLimit.present ? data.rateLimit.value : this.rateLimit,
      sharedUsers:
          data.sharedUsers.present ? data.sharedUsers.value : this.sharedUsers,
      uploadUsedBytes: data.uploadUsedBytes.present
          ? data.uploadUsedBytes.value
          : this.uploadUsedBytes,
      downloadUsedBytes: data.downloadUsedBytes.present
          ? data.downloadUsedBytes.value
          : this.downloadUsedBytes,
      uptimeLimitSeconds: data.uptimeLimitSeconds.present
          ? data.uptimeLimitSeconds.value
          : this.uptimeLimitSeconds,
      uptimeUsedSeconds: data.uptimeUsedSeconds.present
          ? data.uptimeUsedSeconds.value
          : this.uptimeUsedSeconds,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      lastSyncedAt: data.lastSyncedAt.present
          ? data.lastSyncedAt.value
          : this.lastSyncedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Profile(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('mikrotikId: $mikrotikId, ')
          ..write('rateLimit: $rateLimit, ')
          ..write('sharedUsers: $sharedUsers, ')
          ..write('uploadUsedBytes: $uploadUsedBytes, ')
          ..write('downloadUsedBytes: $downloadUsedBytes, ')
          ..write('uptimeLimitSeconds: $uptimeLimitSeconds, ')
          ..write('uptimeUsedSeconds: $uptimeUsedSeconds, ')
          ..write('createdAt: $createdAt, ')
          ..write('lastSyncedAt: $lastSyncedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      name,
      mikrotikId,
      rateLimit,
      sharedUsers,
      uploadUsedBytes,
      downloadUsedBytes,
      uptimeLimitSeconds,
      uptimeUsedSeconds,
      createdAt,
      lastSyncedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Profile &&
          other.id == this.id &&
          other.name == this.name &&
          other.mikrotikId == this.mikrotikId &&
          other.rateLimit == this.rateLimit &&
          other.sharedUsers == this.sharedUsers &&
          other.uploadUsedBytes == this.uploadUsedBytes &&
          other.downloadUsedBytes == this.downloadUsedBytes &&
          other.uptimeLimitSeconds == this.uptimeLimitSeconds &&
          other.uptimeUsedSeconds == this.uptimeUsedSeconds &&
          other.createdAt == this.createdAt &&
          other.lastSyncedAt == this.lastSyncedAt);
}

class ProfilesCompanion extends UpdateCompanion<Profile> {
  final Value<int> id;
  final Value<String> name;
  final Value<String?> mikrotikId;
  final Value<String?> rateLimit;
  final Value<int> sharedUsers;
  final Value<int> uploadUsedBytes;
  final Value<int> downloadUsedBytes;
  final Value<int?> uptimeLimitSeconds;
  final Value<int> uptimeUsedSeconds;
  final Value<DateTime> createdAt;
  final Value<DateTime?> lastSyncedAt;
  const ProfilesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.mikrotikId = const Value.absent(),
    this.rateLimit = const Value.absent(),
    this.sharedUsers = const Value.absent(),
    this.uploadUsedBytes = const Value.absent(),
    this.downloadUsedBytes = const Value.absent(),
    this.uptimeLimitSeconds = const Value.absent(),
    this.uptimeUsedSeconds = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.lastSyncedAt = const Value.absent(),
  });
  ProfilesCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    this.mikrotikId = const Value.absent(),
    this.rateLimit = const Value.absent(),
    this.sharedUsers = const Value.absent(),
    this.uploadUsedBytes = const Value.absent(),
    this.downloadUsedBytes = const Value.absent(),
    this.uptimeLimitSeconds = const Value.absent(),
    this.uptimeUsedSeconds = const Value.absent(),
    required DateTime createdAt,
    this.lastSyncedAt = const Value.absent(),
  })  : name = Value(name),
        createdAt = Value(createdAt);
  static Insertable<Profile> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? mikrotikId,
    Expression<String>? rateLimit,
    Expression<int>? sharedUsers,
    Expression<int>? uploadUsedBytes,
    Expression<int>? downloadUsedBytes,
    Expression<int>? uptimeLimitSeconds,
    Expression<int>? uptimeUsedSeconds,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? lastSyncedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (mikrotikId != null) 'mikrotik_id': mikrotikId,
      if (rateLimit != null) 'rate_limit': rateLimit,
      if (sharedUsers != null) 'shared_users': sharedUsers,
      if (uploadUsedBytes != null) 'upload_used_bytes': uploadUsedBytes,
      if (downloadUsedBytes != null) 'download_used_bytes': downloadUsedBytes,
      if (uptimeLimitSeconds != null)
        'uptime_limit_seconds': uptimeLimitSeconds,
      if (uptimeUsedSeconds != null) 'uptime_used_seconds': uptimeUsedSeconds,
      if (createdAt != null) 'created_at': createdAt,
      if (lastSyncedAt != null) 'last_synced_at': lastSyncedAt,
    });
  }

  ProfilesCompanion copyWith(
      {Value<int>? id,
      Value<String>? name,
      Value<String?>? mikrotikId,
      Value<String?>? rateLimit,
      Value<int>? sharedUsers,
      Value<int>? uploadUsedBytes,
      Value<int>? downloadUsedBytes,
      Value<int?>? uptimeLimitSeconds,
      Value<int>? uptimeUsedSeconds,
      Value<DateTime>? createdAt,
      Value<DateTime?>? lastSyncedAt}) {
    return ProfilesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      mikrotikId: mikrotikId ?? this.mikrotikId,
      rateLimit: rateLimit ?? this.rateLimit,
      sharedUsers: sharedUsers ?? this.sharedUsers,
      uploadUsedBytes: uploadUsedBytes ?? this.uploadUsedBytes,
      downloadUsedBytes: downloadUsedBytes ?? this.downloadUsedBytes,
      uptimeLimitSeconds: uptimeLimitSeconds ?? this.uptimeLimitSeconds,
      uptimeUsedSeconds: uptimeUsedSeconds ?? this.uptimeUsedSeconds,
      createdAt: createdAt ?? this.createdAt,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (mikrotikId.present) {
      map['mikrotik_id'] = Variable<String>(mikrotikId.value);
    }
    if (rateLimit.present) {
      map['rate_limit'] = Variable<String>(rateLimit.value);
    }
    if (sharedUsers.present) {
      map['shared_users'] = Variable<int>(sharedUsers.value);
    }
    if (uploadUsedBytes.present) {
      map['upload_used_bytes'] = Variable<int>(uploadUsedBytes.value);
    }
    if (downloadUsedBytes.present) {
      map['download_used_bytes'] = Variable<int>(downloadUsedBytes.value);
    }
    if (uptimeLimitSeconds.present) {
      map['uptime_limit_seconds'] = Variable<int>(uptimeLimitSeconds.value);
    }
    if (uptimeUsedSeconds.present) {
      map['uptime_used_seconds'] = Variable<int>(uptimeUsedSeconds.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (lastSyncedAt.present) {
      map['last_synced_at'] = Variable<DateTime>(lastSyncedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProfilesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('mikrotikId: $mikrotikId, ')
          ..write('rateLimit: $rateLimit, ')
          ..write('sharedUsers: $sharedUsers, ')
          ..write('uploadUsedBytes: $uploadUsedBytes, ')
          ..write('downloadUsedBytes: $downloadUsedBytes, ')
          ..write('uptimeLimitSeconds: $uptimeLimitSeconds, ')
          ..write('uptimeUsedSeconds: $uptimeUsedSeconds, ')
          ..write('createdAt: $createdAt, ')
          ..write('lastSyncedAt: $lastSyncedAt')
          ..write(')'))
        .toString();
  }
}

class $CardsTable extends Cards with TableInfo<$CardsTable, Card> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CardsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _usernameMeta =
      const VerificationMeta('username');
  @override
  late final GeneratedColumn<String> username = GeneratedColumn<String>(
      'username', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 1, maxTextLength: 100),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _passwordMeta =
      const VerificationMeta('password');
  @override
  late final GeneratedColumn<String> password = GeneratedColumn<String>(
      'password', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _profileIdMeta =
      const VerificationMeta('profileId');
  @override
  late final GeneratedColumn<int> profileId = GeneratedColumn<int>(
      'profile_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      $customConstraints: 'NOT NULL REFERENCES profiles(id)');
  static const VerificationMeta _sharedUsersMeta =
      const VerificationMeta('sharedUsers');
  @override
  late final GeneratedColumn<int> sharedUsers = GeneratedColumn<int>(
      'shared_users', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(1));
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
      'status', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('active'));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _expiresAtMeta =
      const VerificationMeta('expiresAt');
  @override
  late final GeneratedColumn<DateTime> expiresAt = GeneratedColumn<DateTime>(
      'expires_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _lastUsedAtMeta =
      const VerificationMeta('lastUsedAt');
  @override
  late final GeneratedColumn<DateTime> lastUsedAt = GeneratedColumn<DateTime>(
      'last_used_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _uploadBytesMeta =
      const VerificationMeta('uploadBytes');
  @override
  late final GeneratedColumn<int> uploadBytes = GeneratedColumn<int>(
      'upload_bytes', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _downloadBytesMeta =
      const VerificationMeta('downloadBytes');
  @override
  late final GeneratedColumn<int> downloadBytes = GeneratedColumn<int>(
      'download_bytes', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _uptimeSecondsMeta =
      const VerificationMeta('uptimeSeconds');
  @override
  late final GeneratedColumn<int> uptimeSeconds = GeneratedColumn<int>(
      'uptime_seconds', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _mikrotikUserIdMeta =
      const VerificationMeta('mikrotikUserId');
  @override
  late final GeneratedColumn<String> mikrotikUserId = GeneratedColumn<String>(
      'mikrotik_user_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        username,
        password,
        profileId,
        sharedUsers,
        status,
        createdAt,
        expiresAt,
        lastUsedAt,
        uploadBytes,
        downloadBytes,
        uptimeSeconds,
        mikrotikUserId
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cards';
  @override
  VerificationContext validateIntegrity(Insertable<Card> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('username')) {
      context.handle(_usernameMeta,
          username.isAcceptableOrUnknown(data['username']!, _usernameMeta));
    } else if (isInserting) {
      context.missing(_usernameMeta);
    }
    if (data.containsKey('password')) {
      context.handle(_passwordMeta,
          password.isAcceptableOrUnknown(data['password']!, _passwordMeta));
    }
    if (data.containsKey('profile_id')) {
      context.handle(_profileIdMeta,
          profileId.isAcceptableOrUnknown(data['profile_id']!, _profileIdMeta));
    } else if (isInserting) {
      context.missing(_profileIdMeta);
    }
    if (data.containsKey('shared_users')) {
      context.handle(
          _sharedUsersMeta,
          sharedUsers.isAcceptableOrUnknown(
              data['shared_users']!, _sharedUsersMeta));
    }
    if (data.containsKey('status')) {
      context.handle(_statusMeta,
          status.isAcceptableOrUnknown(data['status']!, _statusMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('expires_at')) {
      context.handle(_expiresAtMeta,
          expiresAt.isAcceptableOrUnknown(data['expires_at']!, _expiresAtMeta));
    }
    if (data.containsKey('last_used_at')) {
      context.handle(
          _lastUsedAtMeta,
          lastUsedAt.isAcceptableOrUnknown(
              data['last_used_at']!, _lastUsedAtMeta));
    }
    if (data.containsKey('upload_bytes')) {
      context.handle(
          _uploadBytesMeta,
          uploadBytes.isAcceptableOrUnknown(
              data['upload_bytes']!, _uploadBytesMeta));
    }
    if (data.containsKey('download_bytes')) {
      context.handle(
          _downloadBytesMeta,
          downloadBytes.isAcceptableOrUnknown(
              data['download_bytes']!, _downloadBytesMeta));
    }
    if (data.containsKey('uptime_seconds')) {
      context.handle(
          _uptimeSecondsMeta,
          uptimeSeconds.isAcceptableOrUnknown(
              data['uptime_seconds']!, _uptimeSecondsMeta));
    }
    if (data.containsKey('mikrotik_user_id')) {
      context.handle(
          _mikrotikUserIdMeta,
          mikrotikUserId.isAcceptableOrUnknown(
              data['mikrotik_user_id']!, _mikrotikUserIdMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
        {username},
      ];
  @override
  Card map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Card(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      username: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}username'])!,
      password: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}password']),
      profileId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}profile_id'])!,
      sharedUsers: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}shared_users'])!,
      status: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}status'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      expiresAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}expires_at']),
      lastUsedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}last_used_at']),
      uploadBytes: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}upload_bytes'])!,
      downloadBytes: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}download_bytes'])!,
      uptimeSeconds: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}uptime_seconds'])!,
      mikrotikUserId: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}mikrotik_user_id']),
    );
  }

  @override
  $CardsTable createAlias(String alias) {
    return $CardsTable(attachedDatabase, alias);
  }
}

class Card extends DataClass implements Insertable<Card> {
  final int id;
  final String username;
  final String? password;
  final int profileId;
  final int sharedUsers;
  final String status;
  final DateTime createdAt;
  final DateTime? expiresAt;
  final DateTime? lastUsedAt;
  final int uploadBytes;
  final int downloadBytes;
  final int uptimeSeconds;
  final String? mikrotikUserId;
  const Card(
      {required this.id,
      required this.username,
      this.password,
      required this.profileId,
      required this.sharedUsers,
      required this.status,
      required this.createdAt,
      this.expiresAt,
      this.lastUsedAt,
      required this.uploadBytes,
      required this.downloadBytes,
      required this.uptimeSeconds,
      this.mikrotikUserId});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['username'] = Variable<String>(username);
    if (!nullToAbsent || password != null) {
      map['password'] = Variable<String>(password);
    }
    map['profile_id'] = Variable<int>(profileId);
    map['shared_users'] = Variable<int>(sharedUsers);
    map['status'] = Variable<String>(status);
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || expiresAt != null) {
      map['expires_at'] = Variable<DateTime>(expiresAt);
    }
    if (!nullToAbsent || lastUsedAt != null) {
      map['last_used_at'] = Variable<DateTime>(lastUsedAt);
    }
    map['upload_bytes'] = Variable<int>(uploadBytes);
    map['download_bytes'] = Variable<int>(downloadBytes);
    map['uptime_seconds'] = Variable<int>(uptimeSeconds);
    if (!nullToAbsent || mikrotikUserId != null) {
      map['mikrotik_user_id'] = Variable<String>(mikrotikUserId);
    }
    return map;
  }

  CardsCompanion toCompanion(bool nullToAbsent) {
    return CardsCompanion(
      id: Value(id),
      username: Value(username),
      password: password == null && nullToAbsent
          ? const Value.absent()
          : Value(password),
      profileId: Value(profileId),
      sharedUsers: Value(sharedUsers),
      status: Value(status),
      createdAt: Value(createdAt),
      expiresAt: expiresAt == null && nullToAbsent
          ? const Value.absent()
          : Value(expiresAt),
      lastUsedAt: lastUsedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastUsedAt),
      uploadBytes: Value(uploadBytes),
      downloadBytes: Value(downloadBytes),
      uptimeSeconds: Value(uptimeSeconds),
      mikrotikUserId: mikrotikUserId == null && nullToAbsent
          ? const Value.absent()
          : Value(mikrotikUserId),
    );
  }

  factory Card.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Card(
      id: serializer.fromJson<int>(json['id']),
      username: serializer.fromJson<String>(json['username']),
      password: serializer.fromJson<String?>(json['password']),
      profileId: serializer.fromJson<int>(json['profileId']),
      sharedUsers: serializer.fromJson<int>(json['sharedUsers']),
      status: serializer.fromJson<String>(json['status']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      expiresAt: serializer.fromJson<DateTime?>(json['expiresAt']),
      lastUsedAt: serializer.fromJson<DateTime?>(json['lastUsedAt']),
      uploadBytes: serializer.fromJson<int>(json['uploadBytes']),
      downloadBytes: serializer.fromJson<int>(json['downloadBytes']),
      uptimeSeconds: serializer.fromJson<int>(json['uptimeSeconds']),
      mikrotikUserId: serializer.fromJson<String?>(json['mikrotikUserId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'username': serializer.toJson<String>(username),
      'password': serializer.toJson<String?>(password),
      'profileId': serializer.toJson<int>(profileId),
      'sharedUsers': serializer.toJson<int>(sharedUsers),
      'status': serializer.toJson<String>(status),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'expiresAt': serializer.toJson<DateTime?>(expiresAt),
      'lastUsedAt': serializer.toJson<DateTime?>(lastUsedAt),
      'uploadBytes': serializer.toJson<int>(uploadBytes),
      'downloadBytes': serializer.toJson<int>(downloadBytes),
      'uptimeSeconds': serializer.toJson<int>(uptimeSeconds),
      'mikrotikUserId': serializer.toJson<String?>(mikrotikUserId),
    };
  }

  Card copyWith(
          {int? id,
          String? username,
          Value<String?> password = const Value.absent(),
          int? profileId,
          int? sharedUsers,
          String? status,
          DateTime? createdAt,
          Value<DateTime?> expiresAt = const Value.absent(),
          Value<DateTime?> lastUsedAt = const Value.absent(),
          int? uploadBytes,
          int? downloadBytes,
          int? uptimeSeconds,
          Value<String?> mikrotikUserId = const Value.absent()}) =>
      Card(
        id: id ?? this.id,
        username: username ?? this.username,
        password: password.present ? password.value : this.password,
        profileId: profileId ?? this.profileId,
        sharedUsers: sharedUsers ?? this.sharedUsers,
        status: status ?? this.status,
        createdAt: createdAt ?? this.createdAt,
        expiresAt: expiresAt.present ? expiresAt.value : this.expiresAt,
        lastUsedAt: lastUsedAt.present ? lastUsedAt.value : this.lastUsedAt,
        uploadBytes: uploadBytes ?? this.uploadBytes,
        downloadBytes: downloadBytes ?? this.downloadBytes,
        uptimeSeconds: uptimeSeconds ?? this.uptimeSeconds,
        mikrotikUserId:
            mikrotikUserId.present ? mikrotikUserId.value : this.mikrotikUserId,
      );
  Card copyWithCompanion(CardsCompanion data) {
    return Card(
      id: data.id.present ? data.id.value : this.id,
      username: data.username.present ? data.username.value : this.username,
      password: data.password.present ? data.password.value : this.password,
      profileId: data.profileId.present ? data.profileId.value : this.profileId,
      sharedUsers:
          data.sharedUsers.present ? data.sharedUsers.value : this.sharedUsers,
      status: data.status.present ? data.status.value : this.status,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      expiresAt: data.expiresAt.present ? data.expiresAt.value : this.expiresAt,
      lastUsedAt:
          data.lastUsedAt.present ? data.lastUsedAt.value : this.lastUsedAt,
      uploadBytes:
          data.uploadBytes.present ? data.uploadBytes.value : this.uploadBytes,
      downloadBytes: data.downloadBytes.present
          ? data.downloadBytes.value
          : this.downloadBytes,
      uptimeSeconds: data.uptimeSeconds.present
          ? data.uptimeSeconds.value
          : this.uptimeSeconds,
      mikrotikUserId: data.mikrotikUserId.present
          ? data.mikrotikUserId.value
          : this.mikrotikUserId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Card(')
          ..write('id: $id, ')
          ..write('username: $username, ')
          ..write('password: $password, ')
          ..write('profileId: $profileId, ')
          ..write('sharedUsers: $sharedUsers, ')
          ..write('status: $status, ')
          ..write('createdAt: $createdAt, ')
          ..write('expiresAt: $expiresAt, ')
          ..write('lastUsedAt: $lastUsedAt, ')
          ..write('uploadBytes: $uploadBytes, ')
          ..write('downloadBytes: $downloadBytes, ')
          ..write('uptimeSeconds: $uptimeSeconds, ')
          ..write('mikrotikUserId: $mikrotikUserId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      username,
      password,
      profileId,
      sharedUsers,
      status,
      createdAt,
      expiresAt,
      lastUsedAt,
      uploadBytes,
      downloadBytes,
      uptimeSeconds,
      mikrotikUserId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Card &&
          other.id == this.id &&
          other.username == this.username &&
          other.password == this.password &&
          other.profileId == this.profileId &&
          other.sharedUsers == this.sharedUsers &&
          other.status == this.status &&
          other.createdAt == this.createdAt &&
          other.expiresAt == this.expiresAt &&
          other.lastUsedAt == this.lastUsedAt &&
          other.uploadBytes == this.uploadBytes &&
          other.downloadBytes == this.downloadBytes &&
          other.uptimeSeconds == this.uptimeSeconds &&
          other.mikrotikUserId == this.mikrotikUserId);
}

class CardsCompanion extends UpdateCompanion<Card> {
  final Value<int> id;
  final Value<String> username;
  final Value<String?> password;
  final Value<int> profileId;
  final Value<int> sharedUsers;
  final Value<String> status;
  final Value<DateTime> createdAt;
  final Value<DateTime?> expiresAt;
  final Value<DateTime?> lastUsedAt;
  final Value<int> uploadBytes;
  final Value<int> downloadBytes;
  final Value<int> uptimeSeconds;
  final Value<String?> mikrotikUserId;
  const CardsCompanion({
    this.id = const Value.absent(),
    this.username = const Value.absent(),
    this.password = const Value.absent(),
    this.profileId = const Value.absent(),
    this.sharedUsers = const Value.absent(),
    this.status = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.expiresAt = const Value.absent(),
    this.lastUsedAt = const Value.absent(),
    this.uploadBytes = const Value.absent(),
    this.downloadBytes = const Value.absent(),
    this.uptimeSeconds = const Value.absent(),
    this.mikrotikUserId = const Value.absent(),
  });
  CardsCompanion.insert({
    this.id = const Value.absent(),
    required String username,
    this.password = const Value.absent(),
    required int profileId,
    this.sharedUsers = const Value.absent(),
    this.status = const Value.absent(),
    required DateTime createdAt,
    this.expiresAt = const Value.absent(),
    this.lastUsedAt = const Value.absent(),
    this.uploadBytes = const Value.absent(),
    this.downloadBytes = const Value.absent(),
    this.uptimeSeconds = const Value.absent(),
    this.mikrotikUserId = const Value.absent(),
  })  : username = Value(username),
        profileId = Value(profileId),
        createdAt = Value(createdAt);
  static Insertable<Card> custom({
    Expression<int>? id,
    Expression<String>? username,
    Expression<String>? password,
    Expression<int>? profileId,
    Expression<int>? sharedUsers,
    Expression<String>? status,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? expiresAt,
    Expression<DateTime>? lastUsedAt,
    Expression<int>? uploadBytes,
    Expression<int>? downloadBytes,
    Expression<int>? uptimeSeconds,
    Expression<String>? mikrotikUserId,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (username != null) 'username': username,
      if (password != null) 'password': password,
      if (profileId != null) 'profile_id': profileId,
      if (sharedUsers != null) 'shared_users': sharedUsers,
      if (status != null) 'status': status,
      if (createdAt != null) 'created_at': createdAt,
      if (expiresAt != null) 'expires_at': expiresAt,
      if (lastUsedAt != null) 'last_used_at': lastUsedAt,
      if (uploadBytes != null) 'upload_bytes': uploadBytes,
      if (downloadBytes != null) 'download_bytes': downloadBytes,
      if (uptimeSeconds != null) 'uptime_seconds': uptimeSeconds,
      if (mikrotikUserId != null) 'mikrotik_user_id': mikrotikUserId,
    });
  }

  CardsCompanion copyWith(
      {Value<int>? id,
      Value<String>? username,
      Value<String?>? password,
      Value<int>? profileId,
      Value<int>? sharedUsers,
      Value<String>? status,
      Value<DateTime>? createdAt,
      Value<DateTime?>? expiresAt,
      Value<DateTime?>? lastUsedAt,
      Value<int>? uploadBytes,
      Value<int>? downloadBytes,
      Value<int>? uptimeSeconds,
      Value<String?>? mikrotikUserId}) {
    return CardsCompanion(
      id: id ?? this.id,
      username: username ?? this.username,
      password: password ?? this.password,
      profileId: profileId ?? this.profileId,
      sharedUsers: sharedUsers ?? this.sharedUsers,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      lastUsedAt: lastUsedAt ?? this.lastUsedAt,
      uploadBytes: uploadBytes ?? this.uploadBytes,
      downloadBytes: downloadBytes ?? this.downloadBytes,
      uptimeSeconds: uptimeSeconds ?? this.uptimeSeconds,
      mikrotikUserId: mikrotikUserId ?? this.mikrotikUserId,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (username.present) {
      map['username'] = Variable<String>(username.value);
    }
    if (password.present) {
      map['password'] = Variable<String>(password.value);
    }
    if (profileId.present) {
      map['profile_id'] = Variable<int>(profileId.value);
    }
    if (sharedUsers.present) {
      map['shared_users'] = Variable<int>(sharedUsers.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (expiresAt.present) {
      map['expires_at'] = Variable<DateTime>(expiresAt.value);
    }
    if (lastUsedAt.present) {
      map['last_used_at'] = Variable<DateTime>(lastUsedAt.value);
    }
    if (uploadBytes.present) {
      map['upload_bytes'] = Variable<int>(uploadBytes.value);
    }
    if (downloadBytes.present) {
      map['download_bytes'] = Variable<int>(downloadBytes.value);
    }
    if (uptimeSeconds.present) {
      map['uptime_seconds'] = Variable<int>(uptimeSeconds.value);
    }
    if (mikrotikUserId.present) {
      map['mikrotik_user_id'] = Variable<String>(mikrotikUserId.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CardsCompanion(')
          ..write('id: $id, ')
          ..write('username: $username, ')
          ..write('password: $password, ')
          ..write('profileId: $profileId, ')
          ..write('sharedUsers: $sharedUsers, ')
          ..write('status: $status, ')
          ..write('createdAt: $createdAt, ')
          ..write('expiresAt: $expiresAt, ')
          ..write('lastUsedAt: $lastUsedAt, ')
          ..write('uploadBytes: $uploadBytes, ')
          ..write('downloadBytes: $downloadBytes, ')
          ..write('uptimeSeconds: $uptimeSeconds, ')
          ..write('mikrotikUserId: $mikrotikUserId')
          ..write(')'))
        .toString();
  }
}

class $SessionsTable extends Sessions with TableInfo<$SessionsTable, Session> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SessionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _cardIdMeta = const VerificationMeta('cardId');
  @override
  late final GeneratedColumn<int> cardId = GeneratedColumn<int>(
      'card_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      $customConstraints: 'NOT NULL REFERENCES cards(id) ON DELETE CASCADE');
  static const VerificationMeta _startedAtMeta =
      const VerificationMeta('startedAt');
  @override
  late final GeneratedColumn<DateTime> startedAt = GeneratedColumn<DateTime>(
      'started_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _endedAtMeta =
      const VerificationMeta('endedAt');
  @override
  late final GeneratedColumn<DateTime> endedAt = GeneratedColumn<DateTime>(
      'ended_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _uploadBytesMeta =
      const VerificationMeta('uploadBytes');
  @override
  late final GeneratedColumn<int> uploadBytes = GeneratedColumn<int>(
      'upload_bytes', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _downloadBytesMeta =
      const VerificationMeta('downloadBytes');
  @override
  late final GeneratedColumn<int> downloadBytes = GeneratedColumn<int>(
      'download_bytes', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _framedIpAddressMeta =
      const VerificationMeta('framedIpAddress');
  @override
  late final GeneratedColumn<String> framedIpAddress = GeneratedColumn<String>(
      'framed_ip_address', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _lastSeenAtMeta =
      const VerificationMeta('lastSeenAt');
  @override
  late final GeneratedColumn<DateTime> lastSeenAt = GeneratedColumn<DateTime>(
      'last_seen_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        cardId,
        startedAt,
        endedAt,
        uploadBytes,
        downloadBytes,
        framedIpAddress,
        lastSeenAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sessions';
  @override
  VerificationContext validateIntegrity(Insertable<Session> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('card_id')) {
      context.handle(_cardIdMeta,
          cardId.isAcceptableOrUnknown(data['card_id']!, _cardIdMeta));
    } else if (isInserting) {
      context.missing(_cardIdMeta);
    }
    if (data.containsKey('started_at')) {
      context.handle(_startedAtMeta,
          startedAt.isAcceptableOrUnknown(data['started_at']!, _startedAtMeta));
    } else if (isInserting) {
      context.missing(_startedAtMeta);
    }
    if (data.containsKey('ended_at')) {
      context.handle(_endedAtMeta,
          endedAt.isAcceptableOrUnknown(data['ended_at']!, _endedAtMeta));
    }
    if (data.containsKey('upload_bytes')) {
      context.handle(
          _uploadBytesMeta,
          uploadBytes.isAcceptableOrUnknown(
              data['upload_bytes']!, _uploadBytesMeta));
    }
    if (data.containsKey('download_bytes')) {
      context.handle(
          _downloadBytesMeta,
          downloadBytes.isAcceptableOrUnknown(
              data['download_bytes']!, _downloadBytesMeta));
    }
    if (data.containsKey('framed_ip_address')) {
      context.handle(
          _framedIpAddressMeta,
          framedIpAddress.isAcceptableOrUnknown(
              data['framed_ip_address']!, _framedIpAddressMeta));
    }
    if (data.containsKey('last_seen_at')) {
      context.handle(
          _lastSeenAtMeta,
          lastSeenAt.isAcceptableOrUnknown(
              data['last_seen_at']!, _lastSeenAtMeta));
    } else if (isInserting) {
      context.missing(_lastSeenAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Session map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Session(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      cardId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}card_id'])!,
      startedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}started_at'])!,
      endedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}ended_at']),
      uploadBytes: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}upload_bytes'])!,
      downloadBytes: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}download_bytes'])!,
      framedIpAddress: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}framed_ip_address']),
      lastSeenAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}last_seen_at'])!,
    );
  }

  @override
  $SessionsTable createAlias(String alias) {
    return $SessionsTable(attachedDatabase, alias);
  }
}

class Session extends DataClass implements Insertable<Session> {
  final int id;
  final int cardId;
  final DateTime startedAt;
  final DateTime? endedAt;
  final int uploadBytes;
  final int downloadBytes;
  final String? framedIpAddress;
  final DateTime lastSeenAt;
  const Session(
      {required this.id,
      required this.cardId,
      required this.startedAt,
      this.endedAt,
      required this.uploadBytes,
      required this.downloadBytes,
      this.framedIpAddress,
      required this.lastSeenAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['card_id'] = Variable<int>(cardId);
    map['started_at'] = Variable<DateTime>(startedAt);
    if (!nullToAbsent || endedAt != null) {
      map['ended_at'] = Variable<DateTime>(endedAt);
    }
    map['upload_bytes'] = Variable<int>(uploadBytes);
    map['download_bytes'] = Variable<int>(downloadBytes);
    if (!nullToAbsent || framedIpAddress != null) {
      map['framed_ip_address'] = Variable<String>(framedIpAddress);
    }
    map['last_seen_at'] = Variable<DateTime>(lastSeenAt);
    return map;
  }

  SessionsCompanion toCompanion(bool nullToAbsent) {
    return SessionsCompanion(
      id: Value(id),
      cardId: Value(cardId),
      startedAt: Value(startedAt),
      endedAt: endedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(endedAt),
      uploadBytes: Value(uploadBytes),
      downloadBytes: Value(downloadBytes),
      framedIpAddress: framedIpAddress == null && nullToAbsent
          ? const Value.absent()
          : Value(framedIpAddress),
      lastSeenAt: Value(lastSeenAt),
    );
  }

  factory Session.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Session(
      id: serializer.fromJson<int>(json['id']),
      cardId: serializer.fromJson<int>(json['cardId']),
      startedAt: serializer.fromJson<DateTime>(json['startedAt']),
      endedAt: serializer.fromJson<DateTime?>(json['endedAt']),
      uploadBytes: serializer.fromJson<int>(json['uploadBytes']),
      downloadBytes: serializer.fromJson<int>(json['downloadBytes']),
      framedIpAddress: serializer.fromJson<String?>(json['framedIpAddress']),
      lastSeenAt: serializer.fromJson<DateTime>(json['lastSeenAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'cardId': serializer.toJson<int>(cardId),
      'startedAt': serializer.toJson<DateTime>(startedAt),
      'endedAt': serializer.toJson<DateTime?>(endedAt),
      'uploadBytes': serializer.toJson<int>(uploadBytes),
      'downloadBytes': serializer.toJson<int>(downloadBytes),
      'framedIpAddress': serializer.toJson<String?>(framedIpAddress),
      'lastSeenAt': serializer.toJson<DateTime>(lastSeenAt),
    };
  }

  Session copyWith(
          {int? id,
          int? cardId,
          DateTime? startedAt,
          Value<DateTime?> endedAt = const Value.absent(),
          int? uploadBytes,
          int? downloadBytes,
          Value<String?> framedIpAddress = const Value.absent(),
          DateTime? lastSeenAt}) =>
      Session(
        id: id ?? this.id,
        cardId: cardId ?? this.cardId,
        startedAt: startedAt ?? this.startedAt,
        endedAt: endedAt.present ? endedAt.value : this.endedAt,
        uploadBytes: uploadBytes ?? this.uploadBytes,
        downloadBytes: downloadBytes ?? this.downloadBytes,
        framedIpAddress: framedIpAddress.present
            ? framedIpAddress.value
            : this.framedIpAddress,
        lastSeenAt: lastSeenAt ?? this.lastSeenAt,
      );
  Session copyWithCompanion(SessionsCompanion data) {
    return Session(
      id: data.id.present ? data.id.value : this.id,
      cardId: data.cardId.present ? data.cardId.value : this.cardId,
      startedAt: data.startedAt.present ? data.startedAt.value : this.startedAt,
      endedAt: data.endedAt.present ? data.endedAt.value : this.endedAt,
      uploadBytes:
          data.uploadBytes.present ? data.uploadBytes.value : this.uploadBytes,
      downloadBytes: data.downloadBytes.present
          ? data.downloadBytes.value
          : this.downloadBytes,
      framedIpAddress: data.framedIpAddress.present
          ? data.framedIpAddress.value
          : this.framedIpAddress,
      lastSeenAt:
          data.lastSeenAt.present ? data.lastSeenAt.value : this.lastSeenAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Session(')
          ..write('id: $id, ')
          ..write('cardId: $cardId, ')
          ..write('startedAt: $startedAt, ')
          ..write('endedAt: $endedAt, ')
          ..write('uploadBytes: $uploadBytes, ')
          ..write('downloadBytes: $downloadBytes, ')
          ..write('framedIpAddress: $framedIpAddress, ')
          ..write('lastSeenAt: $lastSeenAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, cardId, startedAt, endedAt, uploadBytes,
      downloadBytes, framedIpAddress, lastSeenAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Session &&
          other.id == this.id &&
          other.cardId == this.cardId &&
          other.startedAt == this.startedAt &&
          other.endedAt == this.endedAt &&
          other.uploadBytes == this.uploadBytes &&
          other.downloadBytes == this.downloadBytes &&
          other.framedIpAddress == this.framedIpAddress &&
          other.lastSeenAt == this.lastSeenAt);
}

class SessionsCompanion extends UpdateCompanion<Session> {
  final Value<int> id;
  final Value<int> cardId;
  final Value<DateTime> startedAt;
  final Value<DateTime?> endedAt;
  final Value<int> uploadBytes;
  final Value<int> downloadBytes;
  final Value<String?> framedIpAddress;
  final Value<DateTime> lastSeenAt;
  const SessionsCompanion({
    this.id = const Value.absent(),
    this.cardId = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.endedAt = const Value.absent(),
    this.uploadBytes = const Value.absent(),
    this.downloadBytes = const Value.absent(),
    this.framedIpAddress = const Value.absent(),
    this.lastSeenAt = const Value.absent(),
  });
  SessionsCompanion.insert({
    this.id = const Value.absent(),
    required int cardId,
    required DateTime startedAt,
    this.endedAt = const Value.absent(),
    this.uploadBytes = const Value.absent(),
    this.downloadBytes = const Value.absent(),
    this.framedIpAddress = const Value.absent(),
    required DateTime lastSeenAt,
  })  : cardId = Value(cardId),
        startedAt = Value(startedAt),
        lastSeenAt = Value(lastSeenAt);
  static Insertable<Session> custom({
    Expression<int>? id,
    Expression<int>? cardId,
    Expression<DateTime>? startedAt,
    Expression<DateTime>? endedAt,
    Expression<int>? uploadBytes,
    Expression<int>? downloadBytes,
    Expression<String>? framedIpAddress,
    Expression<DateTime>? lastSeenAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (cardId != null) 'card_id': cardId,
      if (startedAt != null) 'started_at': startedAt,
      if (endedAt != null) 'ended_at': endedAt,
      if (uploadBytes != null) 'upload_bytes': uploadBytes,
      if (downloadBytes != null) 'download_bytes': downloadBytes,
      if (framedIpAddress != null) 'framed_ip_address': framedIpAddress,
      if (lastSeenAt != null) 'last_seen_at': lastSeenAt,
    });
  }

  SessionsCompanion copyWith(
      {Value<int>? id,
      Value<int>? cardId,
      Value<DateTime>? startedAt,
      Value<DateTime?>? endedAt,
      Value<int>? uploadBytes,
      Value<int>? downloadBytes,
      Value<String?>? framedIpAddress,
      Value<DateTime>? lastSeenAt}) {
    return SessionsCompanion(
      id: id ?? this.id,
      cardId: cardId ?? this.cardId,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      uploadBytes: uploadBytes ?? this.uploadBytes,
      downloadBytes: downloadBytes ?? this.downloadBytes,
      framedIpAddress: framedIpAddress ?? this.framedIpAddress,
      lastSeenAt: lastSeenAt ?? this.lastSeenAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (cardId.present) {
      map['card_id'] = Variable<int>(cardId.value);
    }
    if (startedAt.present) {
      map['started_at'] = Variable<DateTime>(startedAt.value);
    }
    if (endedAt.present) {
      map['ended_at'] = Variable<DateTime>(endedAt.value);
    }
    if (uploadBytes.present) {
      map['upload_bytes'] = Variable<int>(uploadBytes.value);
    }
    if (downloadBytes.present) {
      map['download_bytes'] = Variable<int>(downloadBytes.value);
    }
    if (framedIpAddress.present) {
      map['framed_ip_address'] = Variable<String>(framedIpAddress.value);
    }
    if (lastSeenAt.present) {
      map['last_seen_at'] = Variable<DateTime>(lastSeenAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SessionsCompanion(')
          ..write('id: $id, ')
          ..write('cardId: $cardId, ')
          ..write('startedAt: $startedAt, ')
          ..write('endedAt: $endedAt, ')
          ..write('uploadBytes: $uploadBytes, ')
          ..write('downloadBytes: $downloadBytes, ')
          ..write('framedIpAddress: $framedIpAddress, ')
          ..write('lastSeenAt: $lastSeenAt')
          ..write(')'))
        .toString();
  }
}

class $AiDiagnosticsTable extends AiDiagnostics
    with TableInfo<$AiDiagnosticsTable, AiDiagnostic> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AiDiagnosticsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _modeMeta = const VerificationMeta('mode');
  @override
  late final GeneratedColumn<String> mode = GeneratedColumn<String>(
      'mode', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _mikrotikIpMeta =
      const VerificationMeta('mikrotikIp');
  @override
  late final GeneratedColumn<String> mikrotikIp = GeneratedColumn<String>(
      'mikrotik_ip', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _startedAtMeta =
      const VerificationMeta('startedAt');
  @override
  late final GeneratedColumn<DateTime> startedAt = GeneratedColumn<DateTime>(
      'started_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _endedAtMeta =
      const VerificationMeta('endedAt');
  @override
  late final GeneratedColumn<DateTime> endedAt = GeneratedColumn<DateTime>(
      'ended_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _userQueryMeta =
      const VerificationMeta('userQuery');
  @override
  late final GeneratedColumn<String> userQuery = GeneratedColumn<String>(
      'user_query', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _aiResponseMeta =
      const VerificationMeta('aiResponse');
  @override
  late final GeneratedColumn<String> aiResponse = GeneratedColumn<String>(
      'ai_response', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _aiProviderMeta =
      const VerificationMeta('aiProvider');
  @override
  late final GeneratedColumn<String> aiProvider = GeneratedColumn<String>(
      'ai_provider', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _aiModelMeta =
      const VerificationMeta('aiModel');
  @override
  late final GeneratedColumn<String> aiModel = GeneratedColumn<String>(
      'ai_model', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _tokensUsedMeta =
      const VerificationMeta('tokensUsed');
  @override
  late final GeneratedColumn<int> tokensUsed = GeneratedColumn<int>(
      'tokens_used', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _snapshotJsonMeta =
      const VerificationMeta('snapshotJson');
  @override
  late final GeneratedColumn<String> snapshotJson = GeneratedColumn<String>(
      'snapshot_json', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _isFavoriteMeta =
      const VerificationMeta('isFavorite');
  @override
  late final GeneratedColumn<bool> isFavorite = GeneratedColumn<bool>(
      'is_favorite', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_favorite" IN (0, 1))'),
      defaultValue: const Constant(false));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        mode,
        mikrotikIp,
        startedAt,
        endedAt,
        userQuery,
        aiResponse,
        aiProvider,
        aiModel,
        tokensUsed,
        snapshotJson,
        isFavorite
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'ai_diagnostics';
  @override
  VerificationContext validateIntegrity(Insertable<AiDiagnostic> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('mode')) {
      context.handle(
          _modeMeta, mode.isAcceptableOrUnknown(data['mode']!, _modeMeta));
    } else if (isInserting) {
      context.missing(_modeMeta);
    }
    if (data.containsKey('mikrotik_ip')) {
      context.handle(
          _mikrotikIpMeta,
          mikrotikIp.isAcceptableOrUnknown(
              data['mikrotik_ip']!, _mikrotikIpMeta));
    }
    if (data.containsKey('started_at')) {
      context.handle(_startedAtMeta,
          startedAt.isAcceptableOrUnknown(data['started_at']!, _startedAtMeta));
    } else if (isInserting) {
      context.missing(_startedAtMeta);
    }
    if (data.containsKey('ended_at')) {
      context.handle(_endedAtMeta,
          endedAt.isAcceptableOrUnknown(data['ended_at']!, _endedAtMeta));
    }
    if (data.containsKey('user_query')) {
      context.handle(_userQueryMeta,
          userQuery.isAcceptableOrUnknown(data['user_query']!, _userQueryMeta));
    } else if (isInserting) {
      context.missing(_userQueryMeta);
    }
    if (data.containsKey('ai_response')) {
      context.handle(
          _aiResponseMeta,
          aiResponse.isAcceptableOrUnknown(
              data['ai_response']!, _aiResponseMeta));
    } else if (isInserting) {
      context.missing(_aiResponseMeta);
    }
    if (data.containsKey('ai_provider')) {
      context.handle(
          _aiProviderMeta,
          aiProvider.isAcceptableOrUnknown(
              data['ai_provider']!, _aiProviderMeta));
    }
    if (data.containsKey('ai_model')) {
      context.handle(_aiModelMeta,
          aiModel.isAcceptableOrUnknown(data['ai_model']!, _aiModelMeta));
    }
    if (data.containsKey('tokens_used')) {
      context.handle(
          _tokensUsedMeta,
          tokensUsed.isAcceptableOrUnknown(
              data['tokens_used']!, _tokensUsedMeta));
    }
    if (data.containsKey('snapshot_json')) {
      context.handle(
          _snapshotJsonMeta,
          snapshotJson.isAcceptableOrUnknown(
              data['snapshot_json']!, _snapshotJsonMeta));
    }
    if (data.containsKey('is_favorite')) {
      context.handle(
          _isFavoriteMeta,
          isFavorite.isAcceptableOrUnknown(
              data['is_favorite']!, _isFavoriteMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AiDiagnostic map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AiDiagnostic(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      mode: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}mode'])!,
      mikrotikIp: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}mikrotik_ip']),
      startedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}started_at'])!,
      endedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}ended_at']),
      userQuery: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}user_query'])!,
      aiResponse: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}ai_response'])!,
      aiProvider: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}ai_provider']),
      aiModel: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}ai_model']),
      tokensUsed: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}tokens_used']),
      snapshotJson: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}snapshot_json']),
      isFavorite: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_favorite'])!,
    );
  }

  @override
  $AiDiagnosticsTable createAlias(String alias) {
    return $AiDiagnosticsTable(attachedDatabase, alias);
  }
}

class AiDiagnostic extends DataClass implements Insertable<AiDiagnostic> {
  final int id;
  final String mode;
  final String? mikrotikIp;
  final DateTime startedAt;
  final DateTime? endedAt;
  final String userQuery;
  final String aiResponse;
  final String? aiProvider;
  final String? aiModel;
  final int? tokensUsed;
  final String? snapshotJson;
  final bool isFavorite;
  const AiDiagnostic(
      {required this.id,
      required this.mode,
      this.mikrotikIp,
      required this.startedAt,
      this.endedAt,
      required this.userQuery,
      required this.aiResponse,
      this.aiProvider,
      this.aiModel,
      this.tokensUsed,
      this.snapshotJson,
      required this.isFavorite});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['mode'] = Variable<String>(mode);
    if (!nullToAbsent || mikrotikIp != null) {
      map['mikrotik_ip'] = Variable<String>(mikrotikIp);
    }
    map['started_at'] = Variable<DateTime>(startedAt);
    if (!nullToAbsent || endedAt != null) {
      map['ended_at'] = Variable<DateTime>(endedAt);
    }
    map['user_query'] = Variable<String>(userQuery);
    map['ai_response'] = Variable<String>(aiResponse);
    if (!nullToAbsent || aiProvider != null) {
      map['ai_provider'] = Variable<String>(aiProvider);
    }
    if (!nullToAbsent || aiModel != null) {
      map['ai_model'] = Variable<String>(aiModel);
    }
    if (!nullToAbsent || tokensUsed != null) {
      map['tokens_used'] = Variable<int>(tokensUsed);
    }
    if (!nullToAbsent || snapshotJson != null) {
      map['snapshot_json'] = Variable<String>(snapshotJson);
    }
    map['is_favorite'] = Variable<bool>(isFavorite);
    return map;
  }

  AiDiagnosticsCompanion toCompanion(bool nullToAbsent) {
    return AiDiagnosticsCompanion(
      id: Value(id),
      mode: Value(mode),
      mikrotikIp: mikrotikIp == null && nullToAbsent
          ? const Value.absent()
          : Value(mikrotikIp),
      startedAt: Value(startedAt),
      endedAt: endedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(endedAt),
      userQuery: Value(userQuery),
      aiResponse: Value(aiResponse),
      aiProvider: aiProvider == null && nullToAbsent
          ? const Value.absent()
          : Value(aiProvider),
      aiModel: aiModel == null && nullToAbsent
          ? const Value.absent()
          : Value(aiModel),
      tokensUsed: tokensUsed == null && nullToAbsent
          ? const Value.absent()
          : Value(tokensUsed),
      snapshotJson: snapshotJson == null && nullToAbsent
          ? const Value.absent()
          : Value(snapshotJson),
      isFavorite: Value(isFavorite),
    );
  }

  factory AiDiagnostic.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AiDiagnostic(
      id: serializer.fromJson<int>(json['id']),
      mode: serializer.fromJson<String>(json['mode']),
      mikrotikIp: serializer.fromJson<String?>(json['mikrotikIp']),
      startedAt: serializer.fromJson<DateTime>(json['startedAt']),
      endedAt: serializer.fromJson<DateTime?>(json['endedAt']),
      userQuery: serializer.fromJson<String>(json['userQuery']),
      aiResponse: serializer.fromJson<String>(json['aiResponse']),
      aiProvider: serializer.fromJson<String?>(json['aiProvider']),
      aiModel: serializer.fromJson<String?>(json['aiModel']),
      tokensUsed: serializer.fromJson<int?>(json['tokensUsed']),
      snapshotJson: serializer.fromJson<String?>(json['snapshotJson']),
      isFavorite: serializer.fromJson<bool>(json['isFavorite']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'mode': serializer.toJson<String>(mode),
      'mikrotikIp': serializer.toJson<String?>(mikrotikIp),
      'startedAt': serializer.toJson<DateTime>(startedAt),
      'endedAt': serializer.toJson<DateTime?>(endedAt),
      'userQuery': serializer.toJson<String>(userQuery),
      'aiResponse': serializer.toJson<String>(aiResponse),
      'aiProvider': serializer.toJson<String?>(aiProvider),
      'aiModel': serializer.toJson<String?>(aiModel),
      'tokensUsed': serializer.toJson<int?>(tokensUsed),
      'snapshotJson': serializer.toJson<String?>(snapshotJson),
      'isFavorite': serializer.toJson<bool>(isFavorite),
    };
  }

  AiDiagnostic copyWith(
          {int? id,
          String? mode,
          Value<String?> mikrotikIp = const Value.absent(),
          DateTime? startedAt,
          Value<DateTime?> endedAt = const Value.absent(),
          String? userQuery,
          String? aiResponse,
          Value<String?> aiProvider = const Value.absent(),
          Value<String?> aiModel = const Value.absent(),
          Value<int?> tokensUsed = const Value.absent(),
          Value<String?> snapshotJson = const Value.absent(),
          bool? isFavorite}) =>
      AiDiagnostic(
        id: id ?? this.id,
        mode: mode ?? this.mode,
        mikrotikIp: mikrotikIp.present ? mikrotikIp.value : this.mikrotikIp,
        startedAt: startedAt ?? this.startedAt,
        endedAt: endedAt.present ? endedAt.value : this.endedAt,
        userQuery: userQuery ?? this.userQuery,
        aiResponse: aiResponse ?? this.aiResponse,
        aiProvider: aiProvider.present ? aiProvider.value : this.aiProvider,
        aiModel: aiModel.present ? aiModel.value : this.aiModel,
        tokensUsed: tokensUsed.present ? tokensUsed.value : this.tokensUsed,
        snapshotJson:
            snapshotJson.present ? snapshotJson.value : this.snapshotJson,
        isFavorite: isFavorite ?? this.isFavorite,
      );
  AiDiagnostic copyWithCompanion(AiDiagnosticsCompanion data) {
    return AiDiagnostic(
      id: data.id.present ? data.id.value : this.id,
      mode: data.mode.present ? data.mode.value : this.mode,
      mikrotikIp:
          data.mikrotikIp.present ? data.mikrotikIp.value : this.mikrotikIp,
      startedAt: data.startedAt.present ? data.startedAt.value : this.startedAt,
      endedAt: data.endedAt.present ? data.endedAt.value : this.endedAt,
      userQuery: data.userQuery.present ? data.userQuery.value : this.userQuery,
      aiResponse:
          data.aiResponse.present ? data.aiResponse.value : this.aiResponse,
      aiProvider:
          data.aiProvider.present ? data.aiProvider.value : this.aiProvider,
      aiModel: data.aiModel.present ? data.aiModel.value : this.aiModel,
      tokensUsed:
          data.tokensUsed.present ? data.tokensUsed.value : this.tokensUsed,
      snapshotJson: data.snapshotJson.present
          ? data.snapshotJson.value
          : this.snapshotJson,
      isFavorite:
          data.isFavorite.present ? data.isFavorite.value : this.isFavorite,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AiDiagnostic(')
          ..write('id: $id, ')
          ..write('mode: $mode, ')
          ..write('mikrotikIp: $mikrotikIp, ')
          ..write('startedAt: $startedAt, ')
          ..write('endedAt: $endedAt, ')
          ..write('userQuery: $userQuery, ')
          ..write('aiResponse: $aiResponse, ')
          ..write('aiProvider: $aiProvider, ')
          ..write('aiModel: $aiModel, ')
          ..write('tokensUsed: $tokensUsed, ')
          ..write('snapshotJson: $snapshotJson, ')
          ..write('isFavorite: $isFavorite')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      mode,
      mikrotikIp,
      startedAt,
      endedAt,
      userQuery,
      aiResponse,
      aiProvider,
      aiModel,
      tokensUsed,
      snapshotJson,
      isFavorite);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AiDiagnostic &&
          other.id == this.id &&
          other.mode == this.mode &&
          other.mikrotikIp == this.mikrotikIp &&
          other.startedAt == this.startedAt &&
          other.endedAt == this.endedAt &&
          other.userQuery == this.userQuery &&
          other.aiResponse == this.aiResponse &&
          other.aiProvider == this.aiProvider &&
          other.aiModel == this.aiModel &&
          other.tokensUsed == this.tokensUsed &&
          other.snapshotJson == this.snapshotJson &&
          other.isFavorite == this.isFavorite);
}

class AiDiagnosticsCompanion extends UpdateCompanion<AiDiagnostic> {
  final Value<int> id;
  final Value<String> mode;
  final Value<String?> mikrotikIp;
  final Value<DateTime> startedAt;
  final Value<DateTime?> endedAt;
  final Value<String> userQuery;
  final Value<String> aiResponse;
  final Value<String?> aiProvider;
  final Value<String?> aiModel;
  final Value<int?> tokensUsed;
  final Value<String?> snapshotJson;
  final Value<bool> isFavorite;
  const AiDiagnosticsCompanion({
    this.id = const Value.absent(),
    this.mode = const Value.absent(),
    this.mikrotikIp = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.endedAt = const Value.absent(),
    this.userQuery = const Value.absent(),
    this.aiResponse = const Value.absent(),
    this.aiProvider = const Value.absent(),
    this.aiModel = const Value.absent(),
    this.tokensUsed = const Value.absent(),
    this.snapshotJson = const Value.absent(),
    this.isFavorite = const Value.absent(),
  });
  AiDiagnosticsCompanion.insert({
    this.id = const Value.absent(),
    required String mode,
    this.mikrotikIp = const Value.absent(),
    required DateTime startedAt,
    this.endedAt = const Value.absent(),
    required String userQuery,
    required String aiResponse,
    this.aiProvider = const Value.absent(),
    this.aiModel = const Value.absent(),
    this.tokensUsed = const Value.absent(),
    this.snapshotJson = const Value.absent(),
    this.isFavorite = const Value.absent(),
  })  : mode = Value(mode),
        startedAt = Value(startedAt),
        userQuery = Value(userQuery),
        aiResponse = Value(aiResponse);
  static Insertable<AiDiagnostic> custom({
    Expression<int>? id,
    Expression<String>? mode,
    Expression<String>? mikrotikIp,
    Expression<DateTime>? startedAt,
    Expression<DateTime>? endedAt,
    Expression<String>? userQuery,
    Expression<String>? aiResponse,
    Expression<String>? aiProvider,
    Expression<String>? aiModel,
    Expression<int>? tokensUsed,
    Expression<String>? snapshotJson,
    Expression<bool>? isFavorite,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (mode != null) 'mode': mode,
      if (mikrotikIp != null) 'mikrotik_ip': mikrotikIp,
      if (startedAt != null) 'started_at': startedAt,
      if (endedAt != null) 'ended_at': endedAt,
      if (userQuery != null) 'user_query': userQuery,
      if (aiResponse != null) 'ai_response': aiResponse,
      if (aiProvider != null) 'ai_provider': aiProvider,
      if (aiModel != null) 'ai_model': aiModel,
      if (tokensUsed != null) 'tokens_used': tokensUsed,
      if (snapshotJson != null) 'snapshot_json': snapshotJson,
      if (isFavorite != null) 'is_favorite': isFavorite,
    });
  }

  AiDiagnosticsCompanion copyWith(
      {Value<int>? id,
      Value<String>? mode,
      Value<String?>? mikrotikIp,
      Value<DateTime>? startedAt,
      Value<DateTime?>? endedAt,
      Value<String>? userQuery,
      Value<String>? aiResponse,
      Value<String?>? aiProvider,
      Value<String?>? aiModel,
      Value<int?>? tokensUsed,
      Value<String?>? snapshotJson,
      Value<bool>? isFavorite}) {
    return AiDiagnosticsCompanion(
      id: id ?? this.id,
      mode: mode ?? this.mode,
      mikrotikIp: mikrotikIp ?? this.mikrotikIp,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      userQuery: userQuery ?? this.userQuery,
      aiResponse: aiResponse ?? this.aiResponse,
      aiProvider: aiProvider ?? this.aiProvider,
      aiModel: aiModel ?? this.aiModel,
      tokensUsed: tokensUsed ?? this.tokensUsed,
      snapshotJson: snapshotJson ?? this.snapshotJson,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (mode.present) {
      map['mode'] = Variable<String>(mode.value);
    }
    if (mikrotikIp.present) {
      map['mikrotik_ip'] = Variable<String>(mikrotikIp.value);
    }
    if (startedAt.present) {
      map['started_at'] = Variable<DateTime>(startedAt.value);
    }
    if (endedAt.present) {
      map['ended_at'] = Variable<DateTime>(endedAt.value);
    }
    if (userQuery.present) {
      map['user_query'] = Variable<String>(userQuery.value);
    }
    if (aiResponse.present) {
      map['ai_response'] = Variable<String>(aiResponse.value);
    }
    if (aiProvider.present) {
      map['ai_provider'] = Variable<String>(aiProvider.value);
    }
    if (aiModel.present) {
      map['ai_model'] = Variable<String>(aiModel.value);
    }
    if (tokensUsed.present) {
      map['tokens_used'] = Variable<int>(tokensUsed.value);
    }
    if (snapshotJson.present) {
      map['snapshot_json'] = Variable<String>(snapshotJson.value);
    }
    if (isFavorite.present) {
      map['is_favorite'] = Variable<bool>(isFavorite.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AiDiagnosticsCompanion(')
          ..write('id: $id, ')
          ..write('mode: $mode, ')
          ..write('mikrotikIp: $mikrotikIp, ')
          ..write('startedAt: $startedAt, ')
          ..write('endedAt: $endedAt, ')
          ..write('userQuery: $userQuery, ')
          ..write('aiResponse: $aiResponse, ')
          ..write('aiProvider: $aiProvider, ')
          ..write('aiModel: $aiModel, ')
          ..write('tokensUsed: $tokensUsed, ')
          ..write('snapshotJson: $snapshotJson, ')
          ..write('isFavorite: $isFavorite')
          ..write(')'))
        .toString();
  }
}

class $ExecutedCommandsTable extends ExecutedCommands
    with TableInfo<$ExecutedCommandsTable, ExecutedCommand> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ExecutedCommandsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _commandMeta =
      const VerificationMeta('command');
  @override
  late final GeneratedColumn<String> command = GeneratedColumn<String>(
      'command', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _riskLevelMeta =
      const VerificationMeta('riskLevel');
  @override
  late final GeneratedColumn<String> riskLevel = GeneratedColumn<String>(
      'risk_level', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _successMeta =
      const VerificationMeta('success');
  @override
  late final GeneratedColumn<bool> success = GeneratedColumn<bool>(
      'success', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("success" IN (0, 1))'));
  static const VerificationMeta _outputMeta = const VerificationMeta('output');
  @override
  late final GeneratedColumn<String> output = GeneratedColumn<String>(
      'output', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _errorMeta = const VerificationMeta('error');
  @override
  late final GeneratedColumn<String> error = GeneratedColumn<String>(
      'error', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _durationMsMeta =
      const VerificationMeta('durationMs');
  @override
  late final GeneratedColumn<int> durationMs = GeneratedColumn<int>(
      'duration_ms', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _executedAtMeta =
      const VerificationMeta('executedAt');
  @override
  late final GeneratedColumn<DateTime> executedAt = GeneratedColumn<DateTime>(
      'executed_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _diagnosticIdMeta =
      const VerificationMeta('diagnosticId');
  @override
  late final GeneratedColumn<int> diagnosticId = GeneratedColumn<int>(
      'diagnostic_id', aliasedName, true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      $customConstraints: 'REFERENCES ai_diagnostics(id) ON DELETE SET NULL');
  @override
  List<GeneratedColumn> get $columns => [
        id,
        command,
        riskLevel,
        success,
        output,
        error,
        durationMs,
        executedAt,
        diagnosticId
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'executed_commands';
  @override
  VerificationContext validateIntegrity(Insertable<ExecutedCommand> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('command')) {
      context.handle(_commandMeta,
          command.isAcceptableOrUnknown(data['command']!, _commandMeta));
    } else if (isInserting) {
      context.missing(_commandMeta);
    }
    if (data.containsKey('risk_level')) {
      context.handle(_riskLevelMeta,
          riskLevel.isAcceptableOrUnknown(data['risk_level']!, _riskLevelMeta));
    }
    if (data.containsKey('success')) {
      context.handle(_successMeta,
          success.isAcceptableOrUnknown(data['success']!, _successMeta));
    } else if (isInserting) {
      context.missing(_successMeta);
    }
    if (data.containsKey('output')) {
      context.handle(_outputMeta,
          output.isAcceptableOrUnknown(data['output']!, _outputMeta));
    }
    if (data.containsKey('error')) {
      context.handle(
          _errorMeta, error.isAcceptableOrUnknown(data['error']!, _errorMeta));
    }
    if (data.containsKey('duration_ms')) {
      context.handle(
          _durationMsMeta,
          durationMs.isAcceptableOrUnknown(
              data['duration_ms']!, _durationMsMeta));
    }
    if (data.containsKey('executed_at')) {
      context.handle(
          _executedAtMeta,
          executedAt.isAcceptableOrUnknown(
              data['executed_at']!, _executedAtMeta));
    } else if (isInserting) {
      context.missing(_executedAtMeta);
    }
    if (data.containsKey('diagnostic_id')) {
      context.handle(
          _diagnosticIdMeta,
          diagnosticId.isAcceptableOrUnknown(
              data['diagnostic_id']!, _diagnosticIdMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ExecutedCommand map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ExecutedCommand(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      command: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}command'])!,
      riskLevel: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}risk_level']),
      success: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}success'])!,
      output: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}output']),
      error: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}error']),
      durationMs: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}duration_ms']),
      executedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}executed_at'])!,
      diagnosticId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}diagnostic_id']),
    );
  }

  @override
  $ExecutedCommandsTable createAlias(String alias) {
    return $ExecutedCommandsTable(attachedDatabase, alias);
  }
}

class ExecutedCommand extends DataClass implements Insertable<ExecutedCommand> {
  final int id;
  final String command;
  final String? riskLevel;
  final bool success;
  final String? output;
  final String? error;
  final int? durationMs;
  final DateTime executedAt;
  final int? diagnosticId;
  const ExecutedCommand(
      {required this.id,
      required this.command,
      this.riskLevel,
      required this.success,
      this.output,
      this.error,
      this.durationMs,
      required this.executedAt,
      this.diagnosticId});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['command'] = Variable<String>(command);
    if (!nullToAbsent || riskLevel != null) {
      map['risk_level'] = Variable<String>(riskLevel);
    }
    map['success'] = Variable<bool>(success);
    if (!nullToAbsent || output != null) {
      map['output'] = Variable<String>(output);
    }
    if (!nullToAbsent || error != null) {
      map['error'] = Variable<String>(error);
    }
    if (!nullToAbsent || durationMs != null) {
      map['duration_ms'] = Variable<int>(durationMs);
    }
    map['executed_at'] = Variable<DateTime>(executedAt);
    if (!nullToAbsent || diagnosticId != null) {
      map['diagnostic_id'] = Variable<int>(diagnosticId);
    }
    return map;
  }

  ExecutedCommandsCompanion toCompanion(bool nullToAbsent) {
    return ExecutedCommandsCompanion(
      id: Value(id),
      command: Value(command),
      riskLevel: riskLevel == null && nullToAbsent
          ? const Value.absent()
          : Value(riskLevel),
      success: Value(success),
      output:
          output == null && nullToAbsent ? const Value.absent() : Value(output),
      error:
          error == null && nullToAbsent ? const Value.absent() : Value(error),
      durationMs: durationMs == null && nullToAbsent
          ? const Value.absent()
          : Value(durationMs),
      executedAt: Value(executedAt),
      diagnosticId: diagnosticId == null && nullToAbsent
          ? const Value.absent()
          : Value(diagnosticId),
    );
  }

  factory ExecutedCommand.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ExecutedCommand(
      id: serializer.fromJson<int>(json['id']),
      command: serializer.fromJson<String>(json['command']),
      riskLevel: serializer.fromJson<String?>(json['riskLevel']),
      success: serializer.fromJson<bool>(json['success']),
      output: serializer.fromJson<String?>(json['output']),
      error: serializer.fromJson<String?>(json['error']),
      durationMs: serializer.fromJson<int?>(json['durationMs']),
      executedAt: serializer.fromJson<DateTime>(json['executedAt']),
      diagnosticId: serializer.fromJson<int?>(json['diagnosticId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'command': serializer.toJson<String>(command),
      'riskLevel': serializer.toJson<String?>(riskLevel),
      'success': serializer.toJson<bool>(success),
      'output': serializer.toJson<String?>(output),
      'error': serializer.toJson<String?>(error),
      'durationMs': serializer.toJson<int?>(durationMs),
      'executedAt': serializer.toJson<DateTime>(executedAt),
      'diagnosticId': serializer.toJson<int?>(diagnosticId),
    };
  }

  ExecutedCommand copyWith(
          {int? id,
          String? command,
          Value<String?> riskLevel = const Value.absent(),
          bool? success,
          Value<String?> output = const Value.absent(),
          Value<String?> error = const Value.absent(),
          Value<int?> durationMs = const Value.absent(),
          DateTime? executedAt,
          Value<int?> diagnosticId = const Value.absent()}) =>
      ExecutedCommand(
        id: id ?? this.id,
        command: command ?? this.command,
        riskLevel: riskLevel.present ? riskLevel.value : this.riskLevel,
        success: success ?? this.success,
        output: output.present ? output.value : this.output,
        error: error.present ? error.value : this.error,
        durationMs: durationMs.present ? durationMs.value : this.durationMs,
        executedAt: executedAt ?? this.executedAt,
        diagnosticId:
            diagnosticId.present ? diagnosticId.value : this.diagnosticId,
      );
  ExecutedCommand copyWithCompanion(ExecutedCommandsCompanion data) {
    return ExecutedCommand(
      id: data.id.present ? data.id.value : this.id,
      command: data.command.present ? data.command.value : this.command,
      riskLevel: data.riskLevel.present ? data.riskLevel.value : this.riskLevel,
      success: data.success.present ? data.success.value : this.success,
      output: data.output.present ? data.output.value : this.output,
      error: data.error.present ? data.error.value : this.error,
      durationMs:
          data.durationMs.present ? data.durationMs.value : this.durationMs,
      executedAt:
          data.executedAt.present ? data.executedAt.value : this.executedAt,
      diagnosticId: data.diagnosticId.present
          ? data.diagnosticId.value
          : this.diagnosticId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ExecutedCommand(')
          ..write('id: $id, ')
          ..write('command: $command, ')
          ..write('riskLevel: $riskLevel, ')
          ..write('success: $success, ')
          ..write('output: $output, ')
          ..write('error: $error, ')
          ..write('durationMs: $durationMs, ')
          ..write('executedAt: $executedAt, ')
          ..write('diagnosticId: $diagnosticId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, command, riskLevel, success, output,
      error, durationMs, executedAt, diagnosticId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ExecutedCommand &&
          other.id == this.id &&
          other.command == this.command &&
          other.riskLevel == this.riskLevel &&
          other.success == this.success &&
          other.output == this.output &&
          other.error == this.error &&
          other.durationMs == this.durationMs &&
          other.executedAt == this.executedAt &&
          other.diagnosticId == this.diagnosticId);
}

class ExecutedCommandsCompanion extends UpdateCompanion<ExecutedCommand> {
  final Value<int> id;
  final Value<String> command;
  final Value<String?> riskLevel;
  final Value<bool> success;
  final Value<String?> output;
  final Value<String?> error;
  final Value<int?> durationMs;
  final Value<DateTime> executedAt;
  final Value<int?> diagnosticId;
  const ExecutedCommandsCompanion({
    this.id = const Value.absent(),
    this.command = const Value.absent(),
    this.riskLevel = const Value.absent(),
    this.success = const Value.absent(),
    this.output = const Value.absent(),
    this.error = const Value.absent(),
    this.durationMs = const Value.absent(),
    this.executedAt = const Value.absent(),
    this.diagnosticId = const Value.absent(),
  });
  ExecutedCommandsCompanion.insert({
    this.id = const Value.absent(),
    required String command,
    this.riskLevel = const Value.absent(),
    required bool success,
    this.output = const Value.absent(),
    this.error = const Value.absent(),
    this.durationMs = const Value.absent(),
    required DateTime executedAt,
    this.diagnosticId = const Value.absent(),
  })  : command = Value(command),
        success = Value(success),
        executedAt = Value(executedAt);
  static Insertable<ExecutedCommand> custom({
    Expression<int>? id,
    Expression<String>? command,
    Expression<String>? riskLevel,
    Expression<bool>? success,
    Expression<String>? output,
    Expression<String>? error,
    Expression<int>? durationMs,
    Expression<DateTime>? executedAt,
    Expression<int>? diagnosticId,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (command != null) 'command': command,
      if (riskLevel != null) 'risk_level': riskLevel,
      if (success != null) 'success': success,
      if (output != null) 'output': output,
      if (error != null) 'error': error,
      if (durationMs != null) 'duration_ms': durationMs,
      if (executedAt != null) 'executed_at': executedAt,
      if (diagnosticId != null) 'diagnostic_id': diagnosticId,
    });
  }

  ExecutedCommandsCompanion copyWith(
      {Value<int>? id,
      Value<String>? command,
      Value<String?>? riskLevel,
      Value<bool>? success,
      Value<String?>? output,
      Value<String?>? error,
      Value<int?>? durationMs,
      Value<DateTime>? executedAt,
      Value<int?>? diagnosticId}) {
    return ExecutedCommandsCompanion(
      id: id ?? this.id,
      command: command ?? this.command,
      riskLevel: riskLevel ?? this.riskLevel,
      success: success ?? this.success,
      output: output ?? this.output,
      error: error ?? this.error,
      durationMs: durationMs ?? this.durationMs,
      executedAt: executedAt ?? this.executedAt,
      diagnosticId: diagnosticId ?? this.diagnosticId,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (command.present) {
      map['command'] = Variable<String>(command.value);
    }
    if (riskLevel.present) {
      map['risk_level'] = Variable<String>(riskLevel.value);
    }
    if (success.present) {
      map['success'] = Variable<bool>(success.value);
    }
    if (output.present) {
      map['output'] = Variable<String>(output.value);
    }
    if (error.present) {
      map['error'] = Variable<String>(error.value);
    }
    if (durationMs.present) {
      map['duration_ms'] = Variable<int>(durationMs.value);
    }
    if (executedAt.present) {
      map['executed_at'] = Variable<DateTime>(executedAt.value);
    }
    if (diagnosticId.present) {
      map['diagnostic_id'] = Variable<int>(diagnosticId.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ExecutedCommandsCompanion(')
          ..write('id: $id, ')
          ..write('command: $command, ')
          ..write('riskLevel: $riskLevel, ')
          ..write('success: $success, ')
          ..write('output: $output, ')
          ..write('error: $error, ')
          ..write('durationMs: $durationMs, ')
          ..write('executedAt: $executedAt, ')
          ..write('diagnosticId: $diagnosticId')
          ..write(')'))
        .toString();
  }
}

class $BackupsTable extends Backups with TableInfo<$BackupsTable, Backup> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BackupsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _filenameMeta =
      const VerificationMeta('filename');
  @override
  late final GeneratedColumn<String> filename = GeneratedColumn<String>(
      'filename', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _filePathMeta =
      const VerificationMeta('filePath');
  @override
  late final GeneratedColumn<String> filePath = GeneratedColumn<String>(
      'file_path', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _fileSizeBytesMeta =
      const VerificationMeta('fileSizeBytes');
  @override
  late final GeneratedColumn<int> fileSizeBytes = GeneratedColumn<int>(
      'file_size_bytes', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _mikrotikIpMeta =
      const VerificationMeta('mikrotikIp');
  @override
  late final GeneratedColumn<String> mikrotikIp = GeneratedColumn<String>(
      'mikrotik_ip', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _isRestoredMeta =
      const VerificationMeta('isRestored');
  @override
  late final GeneratedColumn<bool> isRestored = GeneratedColumn<bool>(
      'is_restored', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_restored" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
      'notes', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        filename,
        filePath,
        fileSizeBytes,
        mikrotikIp,
        createdAt,
        isRestored,
        notes
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'backups';
  @override
  VerificationContext validateIntegrity(Insertable<Backup> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('filename')) {
      context.handle(_filenameMeta,
          filename.isAcceptableOrUnknown(data['filename']!, _filenameMeta));
    } else if (isInserting) {
      context.missing(_filenameMeta);
    }
    if (data.containsKey('file_path')) {
      context.handle(_filePathMeta,
          filePath.isAcceptableOrUnknown(data['file_path']!, _filePathMeta));
    } else if (isInserting) {
      context.missing(_filePathMeta);
    }
    if (data.containsKey('file_size_bytes')) {
      context.handle(
          _fileSizeBytesMeta,
          fileSizeBytes.isAcceptableOrUnknown(
              data['file_size_bytes']!, _fileSizeBytesMeta));
    }
    if (data.containsKey('mikrotik_ip')) {
      context.handle(
          _mikrotikIpMeta,
          mikrotikIp.isAcceptableOrUnknown(
              data['mikrotik_ip']!, _mikrotikIpMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('is_restored')) {
      context.handle(
          _isRestoredMeta,
          isRestored.isAcceptableOrUnknown(
              data['is_restored']!, _isRestoredMeta));
    }
    if (data.containsKey('notes')) {
      context.handle(
          _notesMeta, notes.isAcceptableOrUnknown(data['notes']!, _notesMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Backup map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Backup(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      filename: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}filename'])!,
      filePath: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}file_path'])!,
      fileSizeBytes: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}file_size_bytes']),
      mikrotikIp: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}mikrotik_ip']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      isRestored: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_restored'])!,
      notes: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}notes']),
    );
  }

  @override
  $BackupsTable createAlias(String alias) {
    return $BackupsTable(attachedDatabase, alias);
  }
}

class Backup extends DataClass implements Insertable<Backup> {
  final int id;
  final String filename;
  final String filePath;
  final int? fileSizeBytes;
  final String? mikrotikIp;
  final DateTime createdAt;
  final bool isRestored;
  final String? notes;
  const Backup(
      {required this.id,
      required this.filename,
      required this.filePath,
      this.fileSizeBytes,
      this.mikrotikIp,
      required this.createdAt,
      required this.isRestored,
      this.notes});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['filename'] = Variable<String>(filename);
    map['file_path'] = Variable<String>(filePath);
    if (!nullToAbsent || fileSizeBytes != null) {
      map['file_size_bytes'] = Variable<int>(fileSizeBytes);
    }
    if (!nullToAbsent || mikrotikIp != null) {
      map['mikrotik_ip'] = Variable<String>(mikrotikIp);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['is_restored'] = Variable<bool>(isRestored);
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    return map;
  }

  BackupsCompanion toCompanion(bool nullToAbsent) {
    return BackupsCompanion(
      id: Value(id),
      filename: Value(filename),
      filePath: Value(filePath),
      fileSizeBytes: fileSizeBytes == null && nullToAbsent
          ? const Value.absent()
          : Value(fileSizeBytes),
      mikrotikIp: mikrotikIp == null && nullToAbsent
          ? const Value.absent()
          : Value(mikrotikIp),
      createdAt: Value(createdAt),
      isRestored: Value(isRestored),
      notes:
          notes == null && nullToAbsent ? const Value.absent() : Value(notes),
    );
  }

  factory Backup.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Backup(
      id: serializer.fromJson<int>(json['id']),
      filename: serializer.fromJson<String>(json['filename']),
      filePath: serializer.fromJson<String>(json['filePath']),
      fileSizeBytes: serializer.fromJson<int?>(json['fileSizeBytes']),
      mikrotikIp: serializer.fromJson<String?>(json['mikrotikIp']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      isRestored: serializer.fromJson<bool>(json['isRestored']),
      notes: serializer.fromJson<String?>(json['notes']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'filename': serializer.toJson<String>(filename),
      'filePath': serializer.toJson<String>(filePath),
      'fileSizeBytes': serializer.toJson<int?>(fileSizeBytes),
      'mikrotikIp': serializer.toJson<String?>(mikrotikIp),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'isRestored': serializer.toJson<bool>(isRestored),
      'notes': serializer.toJson<String?>(notes),
    };
  }

  Backup copyWith(
          {int? id,
          String? filename,
          String? filePath,
          Value<int?> fileSizeBytes = const Value.absent(),
          Value<String?> mikrotikIp = const Value.absent(),
          DateTime? createdAt,
          bool? isRestored,
          Value<String?> notes = const Value.absent()}) =>
      Backup(
        id: id ?? this.id,
        filename: filename ?? this.filename,
        filePath: filePath ?? this.filePath,
        fileSizeBytes:
            fileSizeBytes.present ? fileSizeBytes.value : this.fileSizeBytes,
        mikrotikIp: mikrotikIp.present ? mikrotikIp.value : this.mikrotikIp,
        createdAt: createdAt ?? this.createdAt,
        isRestored: isRestored ?? this.isRestored,
        notes: notes.present ? notes.value : this.notes,
      );
  Backup copyWithCompanion(BackupsCompanion data) {
    return Backup(
      id: data.id.present ? data.id.value : this.id,
      filename: data.filename.present ? data.filename.value : this.filename,
      filePath: data.filePath.present ? data.filePath.value : this.filePath,
      fileSizeBytes: data.fileSizeBytes.present
          ? data.fileSizeBytes.value
          : this.fileSizeBytes,
      mikrotikIp:
          data.mikrotikIp.present ? data.mikrotikIp.value : this.mikrotikIp,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      isRestored:
          data.isRestored.present ? data.isRestored.value : this.isRestored,
      notes: data.notes.present ? data.notes.value : this.notes,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Backup(')
          ..write('id: $id, ')
          ..write('filename: $filename, ')
          ..write('filePath: $filePath, ')
          ..write('fileSizeBytes: $fileSizeBytes, ')
          ..write('mikrotikIp: $mikrotikIp, ')
          ..write('createdAt: $createdAt, ')
          ..write('isRestored: $isRestored, ')
          ..write('notes: $notes')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, filename, filePath, fileSizeBytes,
      mikrotikIp, createdAt, isRestored, notes);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Backup &&
          other.id == this.id &&
          other.filename == this.filename &&
          other.filePath == this.filePath &&
          other.fileSizeBytes == this.fileSizeBytes &&
          other.mikrotikIp == this.mikrotikIp &&
          other.createdAt == this.createdAt &&
          other.isRestored == this.isRestored &&
          other.notes == this.notes);
}

class BackupsCompanion extends UpdateCompanion<Backup> {
  final Value<int> id;
  final Value<String> filename;
  final Value<String> filePath;
  final Value<int?> fileSizeBytes;
  final Value<String?> mikrotikIp;
  final Value<DateTime> createdAt;
  final Value<bool> isRestored;
  final Value<String?> notes;
  const BackupsCompanion({
    this.id = const Value.absent(),
    this.filename = const Value.absent(),
    this.filePath = const Value.absent(),
    this.fileSizeBytes = const Value.absent(),
    this.mikrotikIp = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.isRestored = const Value.absent(),
    this.notes = const Value.absent(),
  });
  BackupsCompanion.insert({
    this.id = const Value.absent(),
    required String filename,
    required String filePath,
    this.fileSizeBytes = const Value.absent(),
    this.mikrotikIp = const Value.absent(),
    required DateTime createdAt,
    this.isRestored = const Value.absent(),
    this.notes = const Value.absent(),
  })  : filename = Value(filename),
        filePath = Value(filePath),
        createdAt = Value(createdAt);
  static Insertable<Backup> custom({
    Expression<int>? id,
    Expression<String>? filename,
    Expression<String>? filePath,
    Expression<int>? fileSizeBytes,
    Expression<String>? mikrotikIp,
    Expression<DateTime>? createdAt,
    Expression<bool>? isRestored,
    Expression<String>? notes,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (filename != null) 'filename': filename,
      if (filePath != null) 'file_path': filePath,
      if (fileSizeBytes != null) 'file_size_bytes': fileSizeBytes,
      if (mikrotikIp != null) 'mikrotik_ip': mikrotikIp,
      if (createdAt != null) 'created_at': createdAt,
      if (isRestored != null) 'is_restored': isRestored,
      if (notes != null) 'notes': notes,
    });
  }

  BackupsCompanion copyWith(
      {Value<int>? id,
      Value<String>? filename,
      Value<String>? filePath,
      Value<int?>? fileSizeBytes,
      Value<String?>? mikrotikIp,
      Value<DateTime>? createdAt,
      Value<bool>? isRestored,
      Value<String?>? notes}) {
    return BackupsCompanion(
      id: id ?? this.id,
      filename: filename ?? this.filename,
      filePath: filePath ?? this.filePath,
      fileSizeBytes: fileSizeBytes ?? this.fileSizeBytes,
      mikrotikIp: mikrotikIp ?? this.mikrotikIp,
      createdAt: createdAt ?? this.createdAt,
      isRestored: isRestored ?? this.isRestored,
      notes: notes ?? this.notes,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (filename.present) {
      map['filename'] = Variable<String>(filename.value);
    }
    if (filePath.present) {
      map['file_path'] = Variable<String>(filePath.value);
    }
    if (fileSizeBytes.present) {
      map['file_size_bytes'] = Variable<int>(fileSizeBytes.value);
    }
    if (mikrotikIp.present) {
      map['mikrotik_ip'] = Variable<String>(mikrotikIp.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (isRestored.present) {
      map['is_restored'] = Variable<bool>(isRestored.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BackupsCompanion(')
          ..write('id: $id, ')
          ..write('filename: $filename, ')
          ..write('filePath: $filePath, ')
          ..write('fileSizeBytes: $fileSizeBytes, ')
          ..write('mikrotikIp: $mikrotikIp, ')
          ..write('createdAt: $createdAt, ')
          ..write('isRestored: $isRestored, ')
          ..write('notes: $notes')
          ..write(')'))
        .toString();
  }
}

class $CardsFtsTable extends CardsFts with TableInfo<$CardsFtsTable, CardsFt> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CardsFtsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _rowidMeta = const VerificationMeta('rowid');
  @override
  late final GeneratedColumn<int> rowid = GeneratedColumn<int>(
      'rowid', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _usernameMeta =
      const VerificationMeta('username');
  @override
  late final GeneratedColumn<String> username = GeneratedColumn<String>(
      'username', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _passwordMeta =
      const VerificationMeta('password');
  @override
  late final GeneratedColumn<String> password = GeneratedColumn<String>(
      'password', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _profileNameMeta =
      const VerificationMeta('profileName');
  @override
  late final GeneratedColumn<String> profileName = GeneratedColumn<String>(
      'profile_name', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns =>
      [rowid, username, password, profileName];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cards_fts';
  @override
  VerificationContext validateIntegrity(Insertable<CardsFt> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('rowid')) {
      context.handle(
          _rowidMeta, rowid.isAcceptableOrUnknown(data['rowid']!, _rowidMeta));
    } else if (isInserting) {
      context.missing(_rowidMeta);
    }
    if (data.containsKey('username')) {
      context.handle(_usernameMeta,
          username.isAcceptableOrUnknown(data['username']!, _usernameMeta));
    } else if (isInserting) {
      context.missing(_usernameMeta);
    }
    if (data.containsKey('password')) {
      context.handle(_passwordMeta,
          password.isAcceptableOrUnknown(data['password']!, _passwordMeta));
    }
    if (data.containsKey('profile_name')) {
      context.handle(
          _profileNameMeta,
          profileName.isAcceptableOrUnknown(
              data['profile_name']!, _profileNameMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => const {};
  @override
  CardsFt map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CardsFt(
      rowid: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}rowid'])!,
      username: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}username'])!,
      password: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}password']),
      profileName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}profile_name']),
    );
  }

  @override
  $CardsFtsTable createAlias(String alias) {
    return $CardsFtsTable(attachedDatabase, alias);
  }

  @override
  bool get withoutRowId => true;
}

class CardsFt extends DataClass implements Insertable<CardsFt> {
  final int rowid;
  final String username;
  final String? password;
  final String? profileName;
  const CardsFt(
      {required this.rowid,
      required this.username,
      this.password,
      this.profileName});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['rowid'] = Variable<int>(rowid);
    map['username'] = Variable<String>(username);
    if (!nullToAbsent || password != null) {
      map['password'] = Variable<String>(password);
    }
    if (!nullToAbsent || profileName != null) {
      map['profile_name'] = Variable<String>(profileName);
    }
    return map;
  }

  CardsFtsCompanion toCompanion(bool nullToAbsent) {
    return CardsFtsCompanion(
      rowid: Value(rowid),
      username: Value(username),
      password: password == null && nullToAbsent
          ? const Value.absent()
          : Value(password),
      profileName: profileName == null && nullToAbsent
          ? const Value.absent()
          : Value(profileName),
    );
  }

  factory CardsFt.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CardsFt(
      rowid: serializer.fromJson<int>(json['rowid']),
      username: serializer.fromJson<String>(json['username']),
      password: serializer.fromJson<String?>(json['password']),
      profileName: serializer.fromJson<String?>(json['profileName']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'rowid': serializer.toJson<int>(rowid),
      'username': serializer.toJson<String>(username),
      'password': serializer.toJson<String?>(password),
      'profileName': serializer.toJson<String?>(profileName),
    };
  }

  CardsFt copyWith(
          {int? rowid,
          String? username,
          Value<String?> password = const Value.absent(),
          Value<String?> profileName = const Value.absent()}) =>
      CardsFt(
        rowid: rowid ?? this.rowid,
        username: username ?? this.username,
        password: password.present ? password.value : this.password,
        profileName: profileName.present ? profileName.value : this.profileName,
      );
  CardsFt copyWithCompanion(CardsFtsCompanion data) {
    return CardsFt(
      rowid: data.rowid.present ? data.rowid.value : this.rowid,
      username: data.username.present ? data.username.value : this.username,
      password: data.password.present ? data.password.value : this.password,
      profileName:
          data.profileName.present ? data.profileName.value : this.profileName,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CardsFt(')
          ..write('rowid: $rowid, ')
          ..write('username: $username, ')
          ..write('password: $password, ')
          ..write('profileName: $profileName')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(rowid, username, password, profileName);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CardsFt &&
          other.rowid == this.rowid &&
          other.username == this.username &&
          other.password == this.password &&
          other.profileName == this.profileName);
}

class CardsFtsCompanion extends UpdateCompanion<CardsFt> {
  final Value<int> rowid;
  final Value<String> username;
  final Value<String?> password;
  final Value<String?> profileName;
  const CardsFtsCompanion({
    this.rowid = const Value.absent(),
    this.username = const Value.absent(),
    this.password = const Value.absent(),
    this.profileName = const Value.absent(),
  });
  CardsFtsCompanion.insert({
    required int rowid,
    required String username,
    this.password = const Value.absent(),
    this.profileName = const Value.absent(),
  })  : rowid = Value(rowid),
        username = Value(username);
  static Insertable<CardsFt> custom({
    Expression<int>? rowid,
    Expression<String>? username,
    Expression<String>? password,
    Expression<String>? profileName,
  }) {
    return RawValuesInsertable({
      if (rowid != null) 'rowid': rowid,
      if (username != null) 'username': username,
      if (password != null) 'password': password,
      if (profileName != null) 'profile_name': profileName,
    });
  }

  CardsFtsCompanion copyWith(
      {Value<int>? rowid,
      Value<String>? username,
      Value<String?>? password,
      Value<String?>? profileName}) {
    return CardsFtsCompanion(
      rowid: rowid ?? this.rowid,
      username: username ?? this.username,
      password: password ?? this.password,
      profileName: profileName ?? this.profileName,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    if (username.present) {
      map['username'] = Variable<String>(username.value);
    }
    if (password.present) {
      map['password'] = Variable<String>(password.value);
    }
    if (profileName.present) {
      map['profile_name'] = Variable<String>(profileName.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CardsFtsCompanion(')
          ..write('rowid: $rowid, ')
          ..write('username: $username, ')
          ..write('password: $password, ')
          ..write('profileName: $profileName')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $ProfilesTable profiles = $ProfilesTable(this);
  late final $CardsTable cards = $CardsTable(this);
  late final $SessionsTable sessions = $SessionsTable(this);
  late final $AiDiagnosticsTable aiDiagnostics = $AiDiagnosticsTable(this);
  late final $ExecutedCommandsTable executedCommands =
      $ExecutedCommandsTable(this);
  late final $BackupsTable backups = $BackupsTable(this);
  late final $CardsFtsTable cardsFts = $CardsFtsTable(this);
  late final CardsDao cardsDao = CardsDao(this as AppDatabase);
  late final ProfilesDao profilesDao = ProfilesDao(this as AppDatabase);
  late final AiDiagnosticsDao aiDiagnosticsDao =
      AiDiagnosticsDao(this as AppDatabase);
  late final ExecutedCommandsDao executedCommandsDao =
      ExecutedCommandsDao(this as AppDatabase);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
        profiles,
        cards,
        sessions,
        aiDiagnostics,
        executedCommands,
        backups,
        cardsFts
      ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules(
        [
          WritePropagation(
            on: TableUpdateQuery.onTableName('cards',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('sessions', kind: UpdateKind.delete),
            ],
          ),
          WritePropagation(
            on: TableUpdateQuery.onTableName('ai_diagnostics',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('executed_commands', kind: UpdateKind.update),
            ],
          ),
        ],
      );
  @override
  DriftDatabaseOptions get options =>
      const DriftDatabaseOptions(storeDateTimeAsText: true);
}

typedef $$ProfilesTableCreateCompanionBuilder = ProfilesCompanion Function({
  Value<int> id,
  required String name,
  Value<String?> mikrotikId,
  Value<String?> rateLimit,
  Value<int> sharedUsers,
  Value<int> uploadUsedBytes,
  Value<int> downloadUsedBytes,
  Value<int?> uptimeLimitSeconds,
  Value<int> uptimeUsedSeconds,
  required DateTime createdAt,
  Value<DateTime?> lastSyncedAt,
});
typedef $$ProfilesTableUpdateCompanionBuilder = ProfilesCompanion Function({
  Value<int> id,
  Value<String> name,
  Value<String?> mikrotikId,
  Value<String?> rateLimit,
  Value<int> sharedUsers,
  Value<int> uploadUsedBytes,
  Value<int> downloadUsedBytes,
  Value<int?> uptimeLimitSeconds,
  Value<int> uptimeUsedSeconds,
  Value<DateTime> createdAt,
  Value<DateTime?> lastSyncedAt,
});

final class $$ProfilesTableReferences
    extends BaseReferences<_$AppDatabase, $ProfilesTable, Profile> {
  $$ProfilesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$CardsTable, List<Card>> _cardsRefsTable(
          _$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.cards,
          aliasName: $_aliasNameGenerator(db.profiles.id, db.cards.profileId));

  $$CardsTableProcessedTableManager get cardsRefs {
    final manager = $$CardsTableTableManager($_db, $_db.cards)
        .filter((f) => f.profileId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_cardsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$ProfilesTableFilterComposer
    extends Composer<_$AppDatabase, $ProfilesTable> {
  $$ProfilesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get mikrotikId => $composableBuilder(
      column: $table.mikrotikId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get rateLimit => $composableBuilder(
      column: $table.rateLimit, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get sharedUsers => $composableBuilder(
      column: $table.sharedUsers, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get uploadUsedBytes => $composableBuilder(
      column: $table.uploadUsedBytes,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get downloadUsedBytes => $composableBuilder(
      column: $table.downloadUsedBytes,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get uptimeLimitSeconds => $composableBuilder(
      column: $table.uptimeLimitSeconds,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get uptimeUsedSeconds => $composableBuilder(
      column: $table.uptimeUsedSeconds,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get lastSyncedAt => $composableBuilder(
      column: $table.lastSyncedAt, builder: (column) => ColumnFilters(column));

  Expression<bool> cardsRefs(
      Expression<bool> Function($$CardsTableFilterComposer f) f) {
    final $$CardsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.cards,
        getReferencedColumn: (t) => t.profileId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$CardsTableFilterComposer(
              $db: $db,
              $table: $db.cards,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$ProfilesTableOrderingComposer
    extends Composer<_$AppDatabase, $ProfilesTable> {
  $$ProfilesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get mikrotikId => $composableBuilder(
      column: $table.mikrotikId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get rateLimit => $composableBuilder(
      column: $table.rateLimit, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get sharedUsers => $composableBuilder(
      column: $table.sharedUsers, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get uploadUsedBytes => $composableBuilder(
      column: $table.uploadUsedBytes,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get downloadUsedBytes => $composableBuilder(
      column: $table.downloadUsedBytes,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get uptimeLimitSeconds => $composableBuilder(
      column: $table.uptimeLimitSeconds,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get uptimeUsedSeconds => $composableBuilder(
      column: $table.uptimeUsedSeconds,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get lastSyncedAt => $composableBuilder(
      column: $table.lastSyncedAt,
      builder: (column) => ColumnOrderings(column));
}

class $$ProfilesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ProfilesTable> {
  $$ProfilesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get mikrotikId => $composableBuilder(
      column: $table.mikrotikId, builder: (column) => column);

  GeneratedColumn<String> get rateLimit =>
      $composableBuilder(column: $table.rateLimit, builder: (column) => column);

  GeneratedColumn<int> get sharedUsers => $composableBuilder(
      column: $table.sharedUsers, builder: (column) => column);

  GeneratedColumn<int> get uploadUsedBytes => $composableBuilder(
      column: $table.uploadUsedBytes, builder: (column) => column);

  GeneratedColumn<int> get downloadUsedBytes => $composableBuilder(
      column: $table.downloadUsedBytes, builder: (column) => column);

  GeneratedColumn<int> get uptimeLimitSeconds => $composableBuilder(
      column: $table.uptimeLimitSeconds, builder: (column) => column);

  GeneratedColumn<int> get uptimeUsedSeconds => $composableBuilder(
      column: $table.uptimeUsedSeconds, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get lastSyncedAt => $composableBuilder(
      column: $table.lastSyncedAt, builder: (column) => column);

  Expression<T> cardsRefs<T extends Object>(
      Expression<T> Function($$CardsTableAnnotationComposer a) f) {
    final $$CardsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.cards,
        getReferencedColumn: (t) => t.profileId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$CardsTableAnnotationComposer(
              $db: $db,
              $table: $db.cards,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$ProfilesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ProfilesTable,
    Profile,
    $$ProfilesTableFilterComposer,
    $$ProfilesTableOrderingComposer,
    $$ProfilesTableAnnotationComposer,
    $$ProfilesTableCreateCompanionBuilder,
    $$ProfilesTableUpdateCompanionBuilder,
    (Profile, $$ProfilesTableReferences),
    Profile,
    PrefetchHooks Function({bool cardsRefs})> {
  $$ProfilesTableTableManager(_$AppDatabase db, $ProfilesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProfilesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ProfilesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ProfilesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String?> mikrotikId = const Value.absent(),
            Value<String?> rateLimit = const Value.absent(),
            Value<int> sharedUsers = const Value.absent(),
            Value<int> uploadUsedBytes = const Value.absent(),
            Value<int> downloadUsedBytes = const Value.absent(),
            Value<int?> uptimeLimitSeconds = const Value.absent(),
            Value<int> uptimeUsedSeconds = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime?> lastSyncedAt = const Value.absent(),
          }) =>
              ProfilesCompanion(
            id: id,
            name: name,
            mikrotikId: mikrotikId,
            rateLimit: rateLimit,
            sharedUsers: sharedUsers,
            uploadUsedBytes: uploadUsedBytes,
            downloadUsedBytes: downloadUsedBytes,
            uptimeLimitSeconds: uptimeLimitSeconds,
            uptimeUsedSeconds: uptimeUsedSeconds,
            createdAt: createdAt,
            lastSyncedAt: lastSyncedAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String name,
            Value<String?> mikrotikId = const Value.absent(),
            Value<String?> rateLimit = const Value.absent(),
            Value<int> sharedUsers = const Value.absent(),
            Value<int> uploadUsedBytes = const Value.absent(),
            Value<int> downloadUsedBytes = const Value.absent(),
            Value<int?> uptimeLimitSeconds = const Value.absent(),
            Value<int> uptimeUsedSeconds = const Value.absent(),
            required DateTime createdAt,
            Value<DateTime?> lastSyncedAt = const Value.absent(),
          }) =>
              ProfilesCompanion.insert(
            id: id,
            name: name,
            mikrotikId: mikrotikId,
            rateLimit: rateLimit,
            sharedUsers: sharedUsers,
            uploadUsedBytes: uploadUsedBytes,
            downloadUsedBytes: downloadUsedBytes,
            uptimeLimitSeconds: uptimeLimitSeconds,
            uptimeUsedSeconds: uptimeUsedSeconds,
            createdAt: createdAt,
            lastSyncedAt: lastSyncedAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) =>
                  (e.readTable(table), $$ProfilesTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: ({cardsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (cardsRefs) db.cards],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (cardsRefs)
                    await $_getPrefetchedData<Profile, $ProfilesTable, Card>(
                        currentTable: table,
                        referencedTable:
                            $$ProfilesTableReferences._cardsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$ProfilesTableReferences(db, table, p0).cardsRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.profileId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$ProfilesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $ProfilesTable,
    Profile,
    $$ProfilesTableFilterComposer,
    $$ProfilesTableOrderingComposer,
    $$ProfilesTableAnnotationComposer,
    $$ProfilesTableCreateCompanionBuilder,
    $$ProfilesTableUpdateCompanionBuilder,
    (Profile, $$ProfilesTableReferences),
    Profile,
    PrefetchHooks Function({bool cardsRefs})>;
typedef $$CardsTableCreateCompanionBuilder = CardsCompanion Function({
  Value<int> id,
  required String username,
  Value<String?> password,
  required int profileId,
  Value<int> sharedUsers,
  Value<String> status,
  required DateTime createdAt,
  Value<DateTime?> expiresAt,
  Value<DateTime?> lastUsedAt,
  Value<int> uploadBytes,
  Value<int> downloadBytes,
  Value<int> uptimeSeconds,
  Value<String?> mikrotikUserId,
});
typedef $$CardsTableUpdateCompanionBuilder = CardsCompanion Function({
  Value<int> id,
  Value<String> username,
  Value<String?> password,
  Value<int> profileId,
  Value<int> sharedUsers,
  Value<String> status,
  Value<DateTime> createdAt,
  Value<DateTime?> expiresAt,
  Value<DateTime?> lastUsedAt,
  Value<int> uploadBytes,
  Value<int> downloadBytes,
  Value<int> uptimeSeconds,
  Value<String?> mikrotikUserId,
});

final class $$CardsTableReferences
    extends BaseReferences<_$AppDatabase, $CardsTable, Card> {
  $$CardsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ProfilesTable _profileIdTable(_$AppDatabase db) => db.profiles
      .createAlias($_aliasNameGenerator(db.cards.profileId, db.profiles.id));

  $$ProfilesTableProcessedTableManager get profileId {
    final $_column = $_itemColumn<int>('profile_id')!;

    final manager = $$ProfilesTableTableManager($_db, $_db.profiles)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_profileIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static MultiTypedResultKey<$SessionsTable, List<Session>> _sessionsRefsTable(
          _$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.sessions,
          aliasName: $_aliasNameGenerator(db.cards.id, db.sessions.cardId));

  $$SessionsTableProcessedTableManager get sessionsRefs {
    final manager = $$SessionsTableTableManager($_db, $_db.sessions)
        .filter((f) => f.cardId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_sessionsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$CardsTableFilterComposer extends Composer<_$AppDatabase, $CardsTable> {
  $$CardsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get username => $composableBuilder(
      column: $table.username, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get password => $composableBuilder(
      column: $table.password, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get sharedUsers => $composableBuilder(
      column: $table.sharedUsers, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get expiresAt => $composableBuilder(
      column: $table.expiresAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get lastUsedAt => $composableBuilder(
      column: $table.lastUsedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get uploadBytes => $composableBuilder(
      column: $table.uploadBytes, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get downloadBytes => $composableBuilder(
      column: $table.downloadBytes, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get uptimeSeconds => $composableBuilder(
      column: $table.uptimeSeconds, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get mikrotikUserId => $composableBuilder(
      column: $table.mikrotikUserId,
      builder: (column) => ColumnFilters(column));

  $$ProfilesTableFilterComposer get profileId {
    final $$ProfilesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.profileId,
        referencedTable: $db.profiles,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ProfilesTableFilterComposer(
              $db: $db,
              $table: $db.profiles,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  Expression<bool> sessionsRefs(
      Expression<bool> Function($$SessionsTableFilterComposer f) f) {
    final $$SessionsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.sessions,
        getReferencedColumn: (t) => t.cardId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$SessionsTableFilterComposer(
              $db: $db,
              $table: $db.sessions,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$CardsTableOrderingComposer
    extends Composer<_$AppDatabase, $CardsTable> {
  $$CardsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get username => $composableBuilder(
      column: $table.username, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get password => $composableBuilder(
      column: $table.password, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get sharedUsers => $composableBuilder(
      column: $table.sharedUsers, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get expiresAt => $composableBuilder(
      column: $table.expiresAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get lastUsedAt => $composableBuilder(
      column: $table.lastUsedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get uploadBytes => $composableBuilder(
      column: $table.uploadBytes, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get downloadBytes => $composableBuilder(
      column: $table.downloadBytes,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get uptimeSeconds => $composableBuilder(
      column: $table.uptimeSeconds,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get mikrotikUserId => $composableBuilder(
      column: $table.mikrotikUserId,
      builder: (column) => ColumnOrderings(column));

  $$ProfilesTableOrderingComposer get profileId {
    final $$ProfilesTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.profileId,
        referencedTable: $db.profiles,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ProfilesTableOrderingComposer(
              $db: $db,
              $table: $db.profiles,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$CardsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CardsTable> {
  $$CardsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get username =>
      $composableBuilder(column: $table.username, builder: (column) => column);

  GeneratedColumn<String> get password =>
      $composableBuilder(column: $table.password, builder: (column) => column);

  GeneratedColumn<int> get sharedUsers => $composableBuilder(
      column: $table.sharedUsers, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get expiresAt =>
      $composableBuilder(column: $table.expiresAt, builder: (column) => column);

  GeneratedColumn<DateTime> get lastUsedAt => $composableBuilder(
      column: $table.lastUsedAt, builder: (column) => column);

  GeneratedColumn<int> get uploadBytes => $composableBuilder(
      column: $table.uploadBytes, builder: (column) => column);

  GeneratedColumn<int> get downloadBytes => $composableBuilder(
      column: $table.downloadBytes, builder: (column) => column);

  GeneratedColumn<int> get uptimeSeconds => $composableBuilder(
      column: $table.uptimeSeconds, builder: (column) => column);

  GeneratedColumn<String> get mikrotikUserId => $composableBuilder(
      column: $table.mikrotikUserId, builder: (column) => column);

  $$ProfilesTableAnnotationComposer get profileId {
    final $$ProfilesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.profileId,
        referencedTable: $db.profiles,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ProfilesTableAnnotationComposer(
              $db: $db,
              $table: $db.profiles,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  Expression<T> sessionsRefs<T extends Object>(
      Expression<T> Function($$SessionsTableAnnotationComposer a) f) {
    final $$SessionsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.sessions,
        getReferencedColumn: (t) => t.cardId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$SessionsTableAnnotationComposer(
              $db: $db,
              $table: $db.sessions,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$CardsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $CardsTable,
    Card,
    $$CardsTableFilterComposer,
    $$CardsTableOrderingComposer,
    $$CardsTableAnnotationComposer,
    $$CardsTableCreateCompanionBuilder,
    $$CardsTableUpdateCompanionBuilder,
    (Card, $$CardsTableReferences),
    Card,
    PrefetchHooks Function({bool profileId, bool sessionsRefs})> {
  $$CardsTableTableManager(_$AppDatabase db, $CardsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CardsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CardsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CardsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> username = const Value.absent(),
            Value<String?> password = const Value.absent(),
            Value<int> profileId = const Value.absent(),
            Value<int> sharedUsers = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime?> expiresAt = const Value.absent(),
            Value<DateTime?> lastUsedAt = const Value.absent(),
            Value<int> uploadBytes = const Value.absent(),
            Value<int> downloadBytes = const Value.absent(),
            Value<int> uptimeSeconds = const Value.absent(),
            Value<String?> mikrotikUserId = const Value.absent(),
          }) =>
              CardsCompanion(
            id: id,
            username: username,
            password: password,
            profileId: profileId,
            sharedUsers: sharedUsers,
            status: status,
            createdAt: createdAt,
            expiresAt: expiresAt,
            lastUsedAt: lastUsedAt,
            uploadBytes: uploadBytes,
            downloadBytes: downloadBytes,
            uptimeSeconds: uptimeSeconds,
            mikrotikUserId: mikrotikUserId,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String username,
            Value<String?> password = const Value.absent(),
            required int profileId,
            Value<int> sharedUsers = const Value.absent(),
            Value<String> status = const Value.absent(),
            required DateTime createdAt,
            Value<DateTime?> expiresAt = const Value.absent(),
            Value<DateTime?> lastUsedAt = const Value.absent(),
            Value<int> uploadBytes = const Value.absent(),
            Value<int> downloadBytes = const Value.absent(),
            Value<int> uptimeSeconds = const Value.absent(),
            Value<String?> mikrotikUserId = const Value.absent(),
          }) =>
              CardsCompanion.insert(
            id: id,
            username: username,
            password: password,
            profileId: profileId,
            sharedUsers: sharedUsers,
            status: status,
            createdAt: createdAt,
            expiresAt: expiresAt,
            lastUsedAt: lastUsedAt,
            uploadBytes: uploadBytes,
            downloadBytes: downloadBytes,
            uptimeSeconds: uptimeSeconds,
            mikrotikUserId: mikrotikUserId,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) =>
                  (e.readTable(table), $$CardsTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: ({profileId = false, sessionsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (sessionsRefs) db.sessions],
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
                if (profileId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.profileId,
                    referencedTable: $$CardsTableReferences._profileIdTable(db),
                    referencedColumn:
                        $$CardsTableReferences._profileIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [
                  if (sessionsRefs)
                    await $_getPrefetchedData<Card, $CardsTable, Session>(
                        currentTable: table,
                        referencedTable:
                            $$CardsTableReferences._sessionsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$CardsTableReferences(db, table, p0).sessionsRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.cardId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$CardsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $CardsTable,
    Card,
    $$CardsTableFilterComposer,
    $$CardsTableOrderingComposer,
    $$CardsTableAnnotationComposer,
    $$CardsTableCreateCompanionBuilder,
    $$CardsTableUpdateCompanionBuilder,
    (Card, $$CardsTableReferences),
    Card,
    PrefetchHooks Function({bool profileId, bool sessionsRefs})>;
typedef $$SessionsTableCreateCompanionBuilder = SessionsCompanion Function({
  Value<int> id,
  required int cardId,
  required DateTime startedAt,
  Value<DateTime?> endedAt,
  Value<int> uploadBytes,
  Value<int> downloadBytes,
  Value<String?> framedIpAddress,
  required DateTime lastSeenAt,
});
typedef $$SessionsTableUpdateCompanionBuilder = SessionsCompanion Function({
  Value<int> id,
  Value<int> cardId,
  Value<DateTime> startedAt,
  Value<DateTime?> endedAt,
  Value<int> uploadBytes,
  Value<int> downloadBytes,
  Value<String?> framedIpAddress,
  Value<DateTime> lastSeenAt,
});

final class $$SessionsTableReferences
    extends BaseReferences<_$AppDatabase, $SessionsTable, Session> {
  $$SessionsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $CardsTable _cardIdTable(_$AppDatabase db) => db.cards
      .createAlias($_aliasNameGenerator(db.sessions.cardId, db.cards.id));

  $$CardsTableProcessedTableManager get cardId {
    final $_column = $_itemColumn<int>('card_id')!;

    final manager = $$CardsTableTableManager($_db, $_db.cards)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_cardIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$SessionsTableFilterComposer
    extends Composer<_$AppDatabase, $SessionsTable> {
  $$SessionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get startedAt => $composableBuilder(
      column: $table.startedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get endedAt => $composableBuilder(
      column: $table.endedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get uploadBytes => $composableBuilder(
      column: $table.uploadBytes, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get downloadBytes => $composableBuilder(
      column: $table.downloadBytes, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get framedIpAddress => $composableBuilder(
      column: $table.framedIpAddress,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get lastSeenAt => $composableBuilder(
      column: $table.lastSeenAt, builder: (column) => ColumnFilters(column));

  $$CardsTableFilterComposer get cardId {
    final $$CardsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.cardId,
        referencedTable: $db.cards,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$CardsTableFilterComposer(
              $db: $db,
              $table: $db.cards,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$SessionsTableOrderingComposer
    extends Composer<_$AppDatabase, $SessionsTable> {
  $$SessionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get startedAt => $composableBuilder(
      column: $table.startedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get endedAt => $composableBuilder(
      column: $table.endedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get uploadBytes => $composableBuilder(
      column: $table.uploadBytes, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get downloadBytes => $composableBuilder(
      column: $table.downloadBytes,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get framedIpAddress => $composableBuilder(
      column: $table.framedIpAddress,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get lastSeenAt => $composableBuilder(
      column: $table.lastSeenAt, builder: (column) => ColumnOrderings(column));

  $$CardsTableOrderingComposer get cardId {
    final $$CardsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.cardId,
        referencedTable: $db.cards,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$CardsTableOrderingComposer(
              $db: $db,
              $table: $db.cards,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$SessionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SessionsTable> {
  $$SessionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get startedAt =>
      $composableBuilder(column: $table.startedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get endedAt =>
      $composableBuilder(column: $table.endedAt, builder: (column) => column);

  GeneratedColumn<int> get uploadBytes => $composableBuilder(
      column: $table.uploadBytes, builder: (column) => column);

  GeneratedColumn<int> get downloadBytes => $composableBuilder(
      column: $table.downloadBytes, builder: (column) => column);

  GeneratedColumn<String> get framedIpAddress => $composableBuilder(
      column: $table.framedIpAddress, builder: (column) => column);

  GeneratedColumn<DateTime> get lastSeenAt => $composableBuilder(
      column: $table.lastSeenAt, builder: (column) => column);

  $$CardsTableAnnotationComposer get cardId {
    final $$CardsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.cardId,
        referencedTable: $db.cards,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$CardsTableAnnotationComposer(
              $db: $db,
              $table: $db.cards,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$SessionsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $SessionsTable,
    Session,
    $$SessionsTableFilterComposer,
    $$SessionsTableOrderingComposer,
    $$SessionsTableAnnotationComposer,
    $$SessionsTableCreateCompanionBuilder,
    $$SessionsTableUpdateCompanionBuilder,
    (Session, $$SessionsTableReferences),
    Session,
    PrefetchHooks Function({bool cardId})> {
  $$SessionsTableTableManager(_$AppDatabase db, $SessionsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SessionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SessionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SessionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> cardId = const Value.absent(),
            Value<DateTime> startedAt = const Value.absent(),
            Value<DateTime?> endedAt = const Value.absent(),
            Value<int> uploadBytes = const Value.absent(),
            Value<int> downloadBytes = const Value.absent(),
            Value<String?> framedIpAddress = const Value.absent(),
            Value<DateTime> lastSeenAt = const Value.absent(),
          }) =>
              SessionsCompanion(
            id: id,
            cardId: cardId,
            startedAt: startedAt,
            endedAt: endedAt,
            uploadBytes: uploadBytes,
            downloadBytes: downloadBytes,
            framedIpAddress: framedIpAddress,
            lastSeenAt: lastSeenAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int cardId,
            required DateTime startedAt,
            Value<DateTime?> endedAt = const Value.absent(),
            Value<int> uploadBytes = const Value.absent(),
            Value<int> downloadBytes = const Value.absent(),
            Value<String?> framedIpAddress = const Value.absent(),
            required DateTime lastSeenAt,
          }) =>
              SessionsCompanion.insert(
            id: id,
            cardId: cardId,
            startedAt: startedAt,
            endedAt: endedAt,
            uploadBytes: uploadBytes,
            downloadBytes: downloadBytes,
            framedIpAddress: framedIpAddress,
            lastSeenAt: lastSeenAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) =>
                  (e.readTable(table), $$SessionsTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: ({cardId = false}) {
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
                if (cardId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.cardId,
                    referencedTable: $$SessionsTableReferences._cardIdTable(db),
                    referencedColumn:
                        $$SessionsTableReferences._cardIdTable(db).id,
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

typedef $$SessionsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $SessionsTable,
    Session,
    $$SessionsTableFilterComposer,
    $$SessionsTableOrderingComposer,
    $$SessionsTableAnnotationComposer,
    $$SessionsTableCreateCompanionBuilder,
    $$SessionsTableUpdateCompanionBuilder,
    (Session, $$SessionsTableReferences),
    Session,
    PrefetchHooks Function({bool cardId})>;
typedef $$AiDiagnosticsTableCreateCompanionBuilder = AiDiagnosticsCompanion
    Function({
  Value<int> id,
  required String mode,
  Value<String?> mikrotikIp,
  required DateTime startedAt,
  Value<DateTime?> endedAt,
  required String userQuery,
  required String aiResponse,
  Value<String?> aiProvider,
  Value<String?> aiModel,
  Value<int?> tokensUsed,
  Value<String?> snapshotJson,
  Value<bool> isFavorite,
});
typedef $$AiDiagnosticsTableUpdateCompanionBuilder = AiDiagnosticsCompanion
    Function({
  Value<int> id,
  Value<String> mode,
  Value<String?> mikrotikIp,
  Value<DateTime> startedAt,
  Value<DateTime?> endedAt,
  Value<String> userQuery,
  Value<String> aiResponse,
  Value<String?> aiProvider,
  Value<String?> aiModel,
  Value<int?> tokensUsed,
  Value<String?> snapshotJson,
  Value<bool> isFavorite,
});

final class $$AiDiagnosticsTableReferences
    extends BaseReferences<_$AppDatabase, $AiDiagnosticsTable, AiDiagnostic> {
  $$AiDiagnosticsTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$ExecutedCommandsTable, List<ExecutedCommand>>
      _executedCommandsRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.executedCommands,
              aliasName: $_aliasNameGenerator(
                  db.aiDiagnostics.id, db.executedCommands.diagnosticId));

  $$ExecutedCommandsTableProcessedTableManager get executedCommandsRefs {
    final manager = $$ExecutedCommandsTableTableManager(
            $_db, $_db.executedCommands)
        .filter((f) => f.diagnosticId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache =
        $_typedResult.readTableOrNull(_executedCommandsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$AiDiagnosticsTableFilterComposer
    extends Composer<_$AppDatabase, $AiDiagnosticsTable> {
  $$AiDiagnosticsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get mode => $composableBuilder(
      column: $table.mode, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get mikrotikIp => $composableBuilder(
      column: $table.mikrotikIp, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get startedAt => $composableBuilder(
      column: $table.startedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get endedAt => $composableBuilder(
      column: $table.endedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get userQuery => $composableBuilder(
      column: $table.userQuery, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get aiResponse => $composableBuilder(
      column: $table.aiResponse, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get aiProvider => $composableBuilder(
      column: $table.aiProvider, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get aiModel => $composableBuilder(
      column: $table.aiModel, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get tokensUsed => $composableBuilder(
      column: $table.tokensUsed, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get snapshotJson => $composableBuilder(
      column: $table.snapshotJson, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isFavorite => $composableBuilder(
      column: $table.isFavorite, builder: (column) => ColumnFilters(column));

  Expression<bool> executedCommandsRefs(
      Expression<bool> Function($$ExecutedCommandsTableFilterComposer f) f) {
    final $$ExecutedCommandsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.executedCommands,
        getReferencedColumn: (t) => t.diagnosticId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ExecutedCommandsTableFilterComposer(
              $db: $db,
              $table: $db.executedCommands,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$AiDiagnosticsTableOrderingComposer
    extends Composer<_$AppDatabase, $AiDiagnosticsTable> {
  $$AiDiagnosticsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get mode => $composableBuilder(
      column: $table.mode, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get mikrotikIp => $composableBuilder(
      column: $table.mikrotikIp, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get startedAt => $composableBuilder(
      column: $table.startedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get endedAt => $composableBuilder(
      column: $table.endedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get userQuery => $composableBuilder(
      column: $table.userQuery, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get aiResponse => $composableBuilder(
      column: $table.aiResponse, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get aiProvider => $composableBuilder(
      column: $table.aiProvider, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get aiModel => $composableBuilder(
      column: $table.aiModel, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get tokensUsed => $composableBuilder(
      column: $table.tokensUsed, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get snapshotJson => $composableBuilder(
      column: $table.snapshotJson,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isFavorite => $composableBuilder(
      column: $table.isFavorite, builder: (column) => ColumnOrderings(column));
}

class $$AiDiagnosticsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AiDiagnosticsTable> {
  $$AiDiagnosticsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get mode =>
      $composableBuilder(column: $table.mode, builder: (column) => column);

  GeneratedColumn<String> get mikrotikIp => $composableBuilder(
      column: $table.mikrotikIp, builder: (column) => column);

  GeneratedColumn<DateTime> get startedAt =>
      $composableBuilder(column: $table.startedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get endedAt =>
      $composableBuilder(column: $table.endedAt, builder: (column) => column);

  GeneratedColumn<String> get userQuery =>
      $composableBuilder(column: $table.userQuery, builder: (column) => column);

  GeneratedColumn<String> get aiResponse => $composableBuilder(
      column: $table.aiResponse, builder: (column) => column);

  GeneratedColumn<String> get aiProvider => $composableBuilder(
      column: $table.aiProvider, builder: (column) => column);

  GeneratedColumn<String> get aiModel =>
      $composableBuilder(column: $table.aiModel, builder: (column) => column);

  GeneratedColumn<int> get tokensUsed => $composableBuilder(
      column: $table.tokensUsed, builder: (column) => column);

  GeneratedColumn<String> get snapshotJson => $composableBuilder(
      column: $table.snapshotJson, builder: (column) => column);

  GeneratedColumn<bool> get isFavorite => $composableBuilder(
      column: $table.isFavorite, builder: (column) => column);

  Expression<T> executedCommandsRefs<T extends Object>(
      Expression<T> Function($$ExecutedCommandsTableAnnotationComposer a) f) {
    final $$ExecutedCommandsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.executedCommands,
        getReferencedColumn: (t) => t.diagnosticId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ExecutedCommandsTableAnnotationComposer(
              $db: $db,
              $table: $db.executedCommands,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$AiDiagnosticsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $AiDiagnosticsTable,
    AiDiagnostic,
    $$AiDiagnosticsTableFilterComposer,
    $$AiDiagnosticsTableOrderingComposer,
    $$AiDiagnosticsTableAnnotationComposer,
    $$AiDiagnosticsTableCreateCompanionBuilder,
    $$AiDiagnosticsTableUpdateCompanionBuilder,
    (AiDiagnostic, $$AiDiagnosticsTableReferences),
    AiDiagnostic,
    PrefetchHooks Function({bool executedCommandsRefs})> {
  $$AiDiagnosticsTableTableManager(_$AppDatabase db, $AiDiagnosticsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AiDiagnosticsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AiDiagnosticsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AiDiagnosticsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> mode = const Value.absent(),
            Value<String?> mikrotikIp = const Value.absent(),
            Value<DateTime> startedAt = const Value.absent(),
            Value<DateTime?> endedAt = const Value.absent(),
            Value<String> userQuery = const Value.absent(),
            Value<String> aiResponse = const Value.absent(),
            Value<String?> aiProvider = const Value.absent(),
            Value<String?> aiModel = const Value.absent(),
            Value<int?> tokensUsed = const Value.absent(),
            Value<String?> snapshotJson = const Value.absent(),
            Value<bool> isFavorite = const Value.absent(),
          }) =>
              AiDiagnosticsCompanion(
            id: id,
            mode: mode,
            mikrotikIp: mikrotikIp,
            startedAt: startedAt,
            endedAt: endedAt,
            userQuery: userQuery,
            aiResponse: aiResponse,
            aiProvider: aiProvider,
            aiModel: aiModel,
            tokensUsed: tokensUsed,
            snapshotJson: snapshotJson,
            isFavorite: isFavorite,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String mode,
            Value<String?> mikrotikIp = const Value.absent(),
            required DateTime startedAt,
            Value<DateTime?> endedAt = const Value.absent(),
            required String userQuery,
            required String aiResponse,
            Value<String?> aiProvider = const Value.absent(),
            Value<String?> aiModel = const Value.absent(),
            Value<int?> tokensUsed = const Value.absent(),
            Value<String?> snapshotJson = const Value.absent(),
            Value<bool> isFavorite = const Value.absent(),
          }) =>
              AiDiagnosticsCompanion.insert(
            id: id,
            mode: mode,
            mikrotikIp: mikrotikIp,
            startedAt: startedAt,
            endedAt: endedAt,
            userQuery: userQuery,
            aiResponse: aiResponse,
            aiProvider: aiProvider,
            aiModel: aiModel,
            tokensUsed: tokensUsed,
            snapshotJson: snapshotJson,
            isFavorite: isFavorite,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$AiDiagnosticsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({executedCommandsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (executedCommandsRefs) db.executedCommands
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (executedCommandsRefs)
                    await $_getPrefetchedData<AiDiagnostic, $AiDiagnosticsTable,
                            ExecutedCommand>(
                        currentTable: table,
                        referencedTable: $$AiDiagnosticsTableReferences
                            ._executedCommandsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$AiDiagnosticsTableReferences(db, table, p0)
                                .executedCommandsRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.diagnosticId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$AiDiagnosticsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $AiDiagnosticsTable,
    AiDiagnostic,
    $$AiDiagnosticsTableFilterComposer,
    $$AiDiagnosticsTableOrderingComposer,
    $$AiDiagnosticsTableAnnotationComposer,
    $$AiDiagnosticsTableCreateCompanionBuilder,
    $$AiDiagnosticsTableUpdateCompanionBuilder,
    (AiDiagnostic, $$AiDiagnosticsTableReferences),
    AiDiagnostic,
    PrefetchHooks Function({bool executedCommandsRefs})>;
typedef $$ExecutedCommandsTableCreateCompanionBuilder
    = ExecutedCommandsCompanion Function({
  Value<int> id,
  required String command,
  Value<String?> riskLevel,
  required bool success,
  Value<String?> output,
  Value<String?> error,
  Value<int?> durationMs,
  required DateTime executedAt,
  Value<int?> diagnosticId,
});
typedef $$ExecutedCommandsTableUpdateCompanionBuilder
    = ExecutedCommandsCompanion Function({
  Value<int> id,
  Value<String> command,
  Value<String?> riskLevel,
  Value<bool> success,
  Value<String?> output,
  Value<String?> error,
  Value<int?> durationMs,
  Value<DateTime> executedAt,
  Value<int?> diagnosticId,
});

final class $$ExecutedCommandsTableReferences extends BaseReferences<
    _$AppDatabase, $ExecutedCommandsTable, ExecutedCommand> {
  $$ExecutedCommandsTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static $AiDiagnosticsTable _diagnosticIdTable(_$AppDatabase db) =>
      db.aiDiagnostics.createAlias($_aliasNameGenerator(
          db.executedCommands.diagnosticId, db.aiDiagnostics.id));

  $$AiDiagnosticsTableProcessedTableManager? get diagnosticId {
    final $_column = $_itemColumn<int>('diagnostic_id');
    if ($_column == null) return null;
    final manager = $$AiDiagnosticsTableTableManager($_db, $_db.aiDiagnostics)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_diagnosticIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$ExecutedCommandsTableFilterComposer
    extends Composer<_$AppDatabase, $ExecutedCommandsTable> {
  $$ExecutedCommandsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get command => $composableBuilder(
      column: $table.command, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get riskLevel => $composableBuilder(
      column: $table.riskLevel, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get success => $composableBuilder(
      column: $table.success, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get output => $composableBuilder(
      column: $table.output, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get error => $composableBuilder(
      column: $table.error, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get durationMs => $composableBuilder(
      column: $table.durationMs, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get executedAt => $composableBuilder(
      column: $table.executedAt, builder: (column) => ColumnFilters(column));

  $$AiDiagnosticsTableFilterComposer get diagnosticId {
    final $$AiDiagnosticsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.diagnosticId,
        referencedTable: $db.aiDiagnostics,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$AiDiagnosticsTableFilterComposer(
              $db: $db,
              $table: $db.aiDiagnostics,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$ExecutedCommandsTableOrderingComposer
    extends Composer<_$AppDatabase, $ExecutedCommandsTable> {
  $$ExecutedCommandsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get command => $composableBuilder(
      column: $table.command, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get riskLevel => $composableBuilder(
      column: $table.riskLevel, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get success => $composableBuilder(
      column: $table.success, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get output => $composableBuilder(
      column: $table.output, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get error => $composableBuilder(
      column: $table.error, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get durationMs => $composableBuilder(
      column: $table.durationMs, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get executedAt => $composableBuilder(
      column: $table.executedAt, builder: (column) => ColumnOrderings(column));

  $$AiDiagnosticsTableOrderingComposer get diagnosticId {
    final $$AiDiagnosticsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.diagnosticId,
        referencedTable: $db.aiDiagnostics,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$AiDiagnosticsTableOrderingComposer(
              $db: $db,
              $table: $db.aiDiagnostics,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$ExecutedCommandsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ExecutedCommandsTable> {
  $$ExecutedCommandsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get command =>
      $composableBuilder(column: $table.command, builder: (column) => column);

  GeneratedColumn<String> get riskLevel =>
      $composableBuilder(column: $table.riskLevel, builder: (column) => column);

  GeneratedColumn<bool> get success =>
      $composableBuilder(column: $table.success, builder: (column) => column);

  GeneratedColumn<String> get output =>
      $composableBuilder(column: $table.output, builder: (column) => column);

  GeneratedColumn<String> get error =>
      $composableBuilder(column: $table.error, builder: (column) => column);

  GeneratedColumn<int> get durationMs => $composableBuilder(
      column: $table.durationMs, builder: (column) => column);

  GeneratedColumn<DateTime> get executedAt => $composableBuilder(
      column: $table.executedAt, builder: (column) => column);

  $$AiDiagnosticsTableAnnotationComposer get diagnosticId {
    final $$AiDiagnosticsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.diagnosticId,
        referencedTable: $db.aiDiagnostics,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$AiDiagnosticsTableAnnotationComposer(
              $db: $db,
              $table: $db.aiDiagnostics,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$ExecutedCommandsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ExecutedCommandsTable,
    ExecutedCommand,
    $$ExecutedCommandsTableFilterComposer,
    $$ExecutedCommandsTableOrderingComposer,
    $$ExecutedCommandsTableAnnotationComposer,
    $$ExecutedCommandsTableCreateCompanionBuilder,
    $$ExecutedCommandsTableUpdateCompanionBuilder,
    (ExecutedCommand, $$ExecutedCommandsTableReferences),
    ExecutedCommand,
    PrefetchHooks Function({bool diagnosticId})> {
  $$ExecutedCommandsTableTableManager(
      _$AppDatabase db, $ExecutedCommandsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ExecutedCommandsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ExecutedCommandsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ExecutedCommandsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> command = const Value.absent(),
            Value<String?> riskLevel = const Value.absent(),
            Value<bool> success = const Value.absent(),
            Value<String?> output = const Value.absent(),
            Value<String?> error = const Value.absent(),
            Value<int?> durationMs = const Value.absent(),
            Value<DateTime> executedAt = const Value.absent(),
            Value<int?> diagnosticId = const Value.absent(),
          }) =>
              ExecutedCommandsCompanion(
            id: id,
            command: command,
            riskLevel: riskLevel,
            success: success,
            output: output,
            error: error,
            durationMs: durationMs,
            executedAt: executedAt,
            diagnosticId: diagnosticId,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String command,
            Value<String?> riskLevel = const Value.absent(),
            required bool success,
            Value<String?> output = const Value.absent(),
            Value<String?> error = const Value.absent(),
            Value<int?> durationMs = const Value.absent(),
            required DateTime executedAt,
            Value<int?> diagnosticId = const Value.absent(),
          }) =>
              ExecutedCommandsCompanion.insert(
            id: id,
            command: command,
            riskLevel: riskLevel,
            success: success,
            output: output,
            error: error,
            durationMs: durationMs,
            executedAt: executedAt,
            diagnosticId: diagnosticId,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$ExecutedCommandsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({diagnosticId = false}) {
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
                if (diagnosticId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.diagnosticId,
                    referencedTable: $$ExecutedCommandsTableReferences
                        ._diagnosticIdTable(db),
                    referencedColumn: $$ExecutedCommandsTableReferences
                        ._diagnosticIdTable(db)
                        .id,
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

typedef $$ExecutedCommandsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $ExecutedCommandsTable,
    ExecutedCommand,
    $$ExecutedCommandsTableFilterComposer,
    $$ExecutedCommandsTableOrderingComposer,
    $$ExecutedCommandsTableAnnotationComposer,
    $$ExecutedCommandsTableCreateCompanionBuilder,
    $$ExecutedCommandsTableUpdateCompanionBuilder,
    (ExecutedCommand, $$ExecutedCommandsTableReferences),
    ExecutedCommand,
    PrefetchHooks Function({bool diagnosticId})>;
typedef $$BackupsTableCreateCompanionBuilder = BackupsCompanion Function({
  Value<int> id,
  required String filename,
  required String filePath,
  Value<int?> fileSizeBytes,
  Value<String?> mikrotikIp,
  required DateTime createdAt,
  Value<bool> isRestored,
  Value<String?> notes,
});
typedef $$BackupsTableUpdateCompanionBuilder = BackupsCompanion Function({
  Value<int> id,
  Value<String> filename,
  Value<String> filePath,
  Value<int?> fileSizeBytes,
  Value<String?> mikrotikIp,
  Value<DateTime> createdAt,
  Value<bool> isRestored,
  Value<String?> notes,
});

class $$BackupsTableFilterComposer
    extends Composer<_$AppDatabase, $BackupsTable> {
  $$BackupsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get filename => $composableBuilder(
      column: $table.filename, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get filePath => $composableBuilder(
      column: $table.filePath, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get fileSizeBytes => $composableBuilder(
      column: $table.fileSizeBytes, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get mikrotikIp => $composableBuilder(
      column: $table.mikrotikIp, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isRestored => $composableBuilder(
      column: $table.isRestored, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get notes => $composableBuilder(
      column: $table.notes, builder: (column) => ColumnFilters(column));
}

class $$BackupsTableOrderingComposer
    extends Composer<_$AppDatabase, $BackupsTable> {
  $$BackupsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get filename => $composableBuilder(
      column: $table.filename, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get filePath => $composableBuilder(
      column: $table.filePath, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get fileSizeBytes => $composableBuilder(
      column: $table.fileSizeBytes,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get mikrotikIp => $composableBuilder(
      column: $table.mikrotikIp, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isRestored => $composableBuilder(
      column: $table.isRestored, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get notes => $composableBuilder(
      column: $table.notes, builder: (column) => ColumnOrderings(column));
}

class $$BackupsTableAnnotationComposer
    extends Composer<_$AppDatabase, $BackupsTable> {
  $$BackupsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get filename =>
      $composableBuilder(column: $table.filename, builder: (column) => column);

  GeneratedColumn<String> get filePath =>
      $composableBuilder(column: $table.filePath, builder: (column) => column);

  GeneratedColumn<int> get fileSizeBytes => $composableBuilder(
      column: $table.fileSizeBytes, builder: (column) => column);

  GeneratedColumn<String> get mikrotikIp => $composableBuilder(
      column: $table.mikrotikIp, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<bool> get isRestored => $composableBuilder(
      column: $table.isRestored, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);
}

class $$BackupsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $BackupsTable,
    Backup,
    $$BackupsTableFilterComposer,
    $$BackupsTableOrderingComposer,
    $$BackupsTableAnnotationComposer,
    $$BackupsTableCreateCompanionBuilder,
    $$BackupsTableUpdateCompanionBuilder,
    (Backup, BaseReferences<_$AppDatabase, $BackupsTable, Backup>),
    Backup,
    PrefetchHooks Function()> {
  $$BackupsTableTableManager(_$AppDatabase db, $BackupsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BackupsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BackupsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BackupsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> filename = const Value.absent(),
            Value<String> filePath = const Value.absent(),
            Value<int?> fileSizeBytes = const Value.absent(),
            Value<String?> mikrotikIp = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<bool> isRestored = const Value.absent(),
            Value<String?> notes = const Value.absent(),
          }) =>
              BackupsCompanion(
            id: id,
            filename: filename,
            filePath: filePath,
            fileSizeBytes: fileSizeBytes,
            mikrotikIp: mikrotikIp,
            createdAt: createdAt,
            isRestored: isRestored,
            notes: notes,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String filename,
            required String filePath,
            Value<int?> fileSizeBytes = const Value.absent(),
            Value<String?> mikrotikIp = const Value.absent(),
            required DateTime createdAt,
            Value<bool> isRestored = const Value.absent(),
            Value<String?> notes = const Value.absent(),
          }) =>
              BackupsCompanion.insert(
            id: id,
            filename: filename,
            filePath: filePath,
            fileSizeBytes: fileSizeBytes,
            mikrotikIp: mikrotikIp,
            createdAt: createdAt,
            isRestored: isRestored,
            notes: notes,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$BackupsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $BackupsTable,
    Backup,
    $$BackupsTableFilterComposer,
    $$BackupsTableOrderingComposer,
    $$BackupsTableAnnotationComposer,
    $$BackupsTableCreateCompanionBuilder,
    $$BackupsTableUpdateCompanionBuilder,
    (Backup, BaseReferences<_$AppDatabase, $BackupsTable, Backup>),
    Backup,
    PrefetchHooks Function()>;
typedef $$CardsFtsTableCreateCompanionBuilder = CardsFtsCompanion Function({
  required int rowid,
  required String username,
  Value<String?> password,
  Value<String?> profileName,
});
typedef $$CardsFtsTableUpdateCompanionBuilder = CardsFtsCompanion Function({
  Value<int> rowid,
  Value<String> username,
  Value<String?> password,
  Value<String?> profileName,
});

class $$CardsFtsTableFilterComposer
    extends Composer<_$AppDatabase, $CardsFtsTable> {
  $$CardsFtsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get rowid => $composableBuilder(
      column: $table.rowid, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get username => $composableBuilder(
      column: $table.username, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get password => $composableBuilder(
      column: $table.password, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get profileName => $composableBuilder(
      column: $table.profileName, builder: (column) => ColumnFilters(column));
}

class $$CardsFtsTableOrderingComposer
    extends Composer<_$AppDatabase, $CardsFtsTable> {
  $$CardsFtsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get rowid => $composableBuilder(
      column: $table.rowid, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get username => $composableBuilder(
      column: $table.username, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get password => $composableBuilder(
      column: $table.password, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get profileName => $composableBuilder(
      column: $table.profileName, builder: (column) => ColumnOrderings(column));
}

class $$CardsFtsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CardsFtsTable> {
  $$CardsFtsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get rowid =>
      $composableBuilder(column: $table.rowid, builder: (column) => column);

  GeneratedColumn<String> get username =>
      $composableBuilder(column: $table.username, builder: (column) => column);

  GeneratedColumn<String> get password =>
      $composableBuilder(column: $table.password, builder: (column) => column);

  GeneratedColumn<String> get profileName => $composableBuilder(
      column: $table.profileName, builder: (column) => column);
}

class $$CardsFtsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $CardsFtsTable,
    CardsFt,
    $$CardsFtsTableFilterComposer,
    $$CardsFtsTableOrderingComposer,
    $$CardsFtsTableAnnotationComposer,
    $$CardsFtsTableCreateCompanionBuilder,
    $$CardsFtsTableUpdateCompanionBuilder,
    (CardsFt, BaseReferences<_$AppDatabase, $CardsFtsTable, CardsFt>),
    CardsFt,
    PrefetchHooks Function()> {
  $$CardsFtsTableTableManager(_$AppDatabase db, $CardsFtsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CardsFtsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CardsFtsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CardsFtsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> rowid = const Value.absent(),
            Value<String> username = const Value.absent(),
            Value<String?> password = const Value.absent(),
            Value<String?> profileName = const Value.absent(),
          }) =>
              CardsFtsCompanion(
            rowid: rowid,
            username: username,
            password: password,
            profileName: profileName,
          ),
          createCompanionCallback: ({
            required int rowid,
            required String username,
            Value<String?> password = const Value.absent(),
            Value<String?> profileName = const Value.absent(),
          }) =>
              CardsFtsCompanion.insert(
            rowid: rowid,
            username: username,
            password: password,
            profileName: profileName,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$CardsFtsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $CardsFtsTable,
    CardsFt,
    $$CardsFtsTableFilterComposer,
    $$CardsFtsTableOrderingComposer,
    $$CardsFtsTableAnnotationComposer,
    $$CardsFtsTableCreateCompanionBuilder,
    $$CardsFtsTableUpdateCompanionBuilder,
    (CardsFt, BaseReferences<_$AppDatabase, $CardsFtsTable, CardsFt>),
    CardsFt,
    PrefetchHooks Function()>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$ProfilesTableTableManager get profiles =>
      $$ProfilesTableTableManager(_db, _db.profiles);
  $$CardsTableTableManager get cards =>
      $$CardsTableTableManager(_db, _db.cards);
  $$SessionsTableTableManager get sessions =>
      $$SessionsTableTableManager(_db, _db.sessions);
  $$AiDiagnosticsTableTableManager get aiDiagnostics =>
      $$AiDiagnosticsTableTableManager(_db, _db.aiDiagnostics);
  $$ExecutedCommandsTableTableManager get executedCommands =>
      $$ExecutedCommandsTableTableManager(_db, _db.executedCommands);
  $$BackupsTableTableManager get backups =>
      $$BackupsTableTableManager(_db, _db.backups);
  $$CardsFtsTableTableManager get cardsFts =>
      $$CardsFtsTableTableManager(_db, _db.cardsFts);
}
