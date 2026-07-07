// ============================================================
//  AppDatabase — قاعدة بيانات SQLite احترافية باستخدام drift
//
//  المميزات:
//  - 7 جداول رئيسية + FTS5 للبحث النصي
//  - Views لتبسيط الاستعلامات
//  - Triggers للمزامنة التلقائية
//  - WAL mode للأداء المتزامن
//  - Type-safe queries عبر drift
// ============================================================

import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'app_database.g.dart';

// ============================================================
//  Tables (Schema Definition)
// ============================================================

/// جدول الكروت — يخزّن كل كرت MikroTik مع حالته واستهلاكه
class Cards extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get username => text().withLength(min: 1, max: 100)();
  TextColumn get password => text().nullable()();
  IntColumn get profileId => integer().customConstraint('REFERENCES profiles(id)')();
  IntColumn get sharedUsers => integer().withDefault(const Constant(1))();
  TextColumn get status => text().withDefault(const Constant('active'))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get expiresAt => dateTime().nullable()();
  DateTimeColumn get lastUsedAt => dateTime().nullable()();
  IntColumn get uploadBytes => integer().withDefault(const Constant(0))();
  IntColumn get downloadBytes => integer().withDefault(const Constant(0))();
  IntColumn get uptimeSeconds => integer().withDefault(const Constant(0))();
  TextColumn get mikrotikUserId => text().nullable()(); // .id من RouterOS

  @override
  List<Set<Column>> get uniqueKeys => [
        {username},
      ];
}

/// جدول الملفات الشخصية (Profiles)
class Profiles extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  TextColumn get mikrotikId => text().nullable()();
  TextColumn get rateLimit => text().nullable()(); // "1M/1M"
  IntColumn get sharedUsers => integer().withDefault(const Constant(1))();
  IntColumn get uploadUsedBytes => integer().withDefault(const Constant(0))();
  IntColumn get downloadUsedBytes => integer().withDefault(const Constant(0))();
  IntColumn get uptimeLimitSeconds => integer().nullable()();
  IntColumn get uptimeUsedSeconds => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get lastSyncedAt => dateTime().nullable()();

  @override
  List<Set<Column>> get uniqueKeys => [
        {name},
      ];
}

/// جدول جلسات الاتصال (Sessions) — للمراقبة التاريخية
class Sessions extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get cardId => integer().customConstraint('REFERENCES cards(id) ON DELETE CASCADE')();
  DateTimeColumn get startedAt => dateTime()();
  DateTimeColumn get endedAt => dateTime().nullable()();
  IntColumn get uploadBytes => integer().withDefault(const Constant(0))();
  IntColumn get downloadBytes => integer().withDefault(const Constant(0))();
  TextColumn get framedIpAddress => text().nullable()();
  DateTimeColumn get lastSeenAt => dateTime()();
}

/// جدول سجل التشخيصات AI (بدل JSON في SharedPreferences)
class AiDiagnostics extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get mode => text()(); // 'general', 'security', 'qos', etc.
  TextColumn get mikrotikIp => text().nullable()();
  DateTimeColumn get startedAt => dateTime()();
  DateTimeColumn get endedAt => dateTime().nullable()();
  TextColumn get userQuery => text()();
  TextColumn get aiResponse => text()();
  TextColumn get aiProvider => text().nullable()();
  TextColumn get aiModel => text().nullable()();
  IntColumn get tokensUsed => integer().nullable()();
  TextColumn get snapshotJson => text().nullable()();
  BoolColumn get isFavorite => boolean().withDefault(const Constant(false))();
}

/// جدول الأوامر المنفّذة (Audit Trail)
class ExecutedCommands extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get command => text()();
  TextColumn get riskLevel => text().nullable()(); // 'safe', 'moderate', 'dangerous'
  BoolColumn get success => boolean()();
  TextColumn get output => text().nullable()();
  TextColumn get error => text().nullable()();
  IntColumn get durationMs => integer().nullable()();
  DateTimeColumn get executedAt => dateTime()();
  IntColumn get diagnosticId => integer().nullable()().customConstraint(
        'REFERENCES ai_diagnostics(id) ON DELETE SET NULL')();
}

/// جدول النسخ الاحتياطية
class Backups extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get filename => text()();
  TextColumn get filePath => text()();
  IntColumn get fileSizeBytes => integer().nullable()();
  TextColumn get mikrotikIp => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  BoolColumn get isRestored => boolean().withDefault(const Constant(false))();
  TextColumn get notes => text().nullable()();
}

/// جدول FTS5 للبحث النصي الكامل في الكروت
/// (يُنشأ كـ raw SQL لأن drift لا يدعم FTS5 مباشرة)
class CardsFts extends Table {
  IntColumn get rowid => integer()();
  TextColumn get username => text()();
  TextColumn get password => text().nullable()();
  TextColumn get profileName => text().nullable()();

  @override
  bool get withoutRowId => true;
}

// ============================================================
//  Database Definition
// ============================================================

@DriftDatabase(
  tables: [
    Cards,
    Profiles,
    Sessions,
    AiDiagnostics,
    ExecutedCommands,
    Backups,
    CardsFts,
  ],
  daos: [
    CardsDao,
    ProfilesDao,
    AiDiagnosticsDao,
    ExecutedCommandsDao,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  /// للـ testing — يمرر اتصال in-memory
  AppDatabase.forTesting(QueryExecutor e) : super(e);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
          // إنشاء indexes
          await customStatement('CREATE INDEX IF NOT EXISTS idx_cards_status ON cards(status)');
          await customStatement('CREATE INDEX IF NOT EXISTS idx_cards_profile ON cards(profile_id)');
          await customStatement('CREATE INDEX IF NOT EXISTS idx_cards_created ON cards(created_at DESC)');
          await customStatement('CREATE INDEX IF NOT EXISTS idx_sessions_card ON sessions(card_id)');
          await customStatement('CREATE INDEX IF NOT EXISTS idx_sessions_active ON sessions(ended_at) WHERE ended_at IS NULL');
          await customStatement('CREATE INDEX IF NOT EXISTS idx_diagnostics_mode ON ai_diagnostics(mode)');
          await customStatement('CREATE INDEX IF NOT EXISTS idx_diagnostics_started ON ai_diagnostics(started_at DESC)');
          await customStatement('CREATE INDEX IF NOT EXISTS idx_commands_executed ON executed_commands(executed_at DESC)');

          // تفعيل WAL mode للأداء المتزامن
          await customStatement('PRAGMA journal_mode = WAL');
          await customStatement('PRAGMA synchronous = NORMAL');
          await customStatement('PRAGMA foreign_keys = ON');

          // إنشاء FTS5 للبحث النصي الكامل
          await customStatement('''
            CREATE VIRTUAL TABLE IF NOT EXISTS cards_fts USING fts5(
              username, password, profile_name,
              content='cards', content_rowid='id'
            )
          ''');

          // Triggers لمزامنة FTS مع الجدول الرئيسي
          await customStatement('''
            CREATE TRIGGER IF NOT EXISTS cards_ai AFTER INSERT ON cards BEGIN
              INSERT INTO cards_fts(rowid, username, password, profile_name)
              VALUES (new.id, new.username, new.password, 
                (SELECT name FROM profiles WHERE id = new.profile_id));
            END
          ''');
          await customStatement('''
            CREATE TRIGGER IF NOT EXISTS cards_ad AFTER DELETE ON cards BEGIN
              INSERT INTO cards_fts(cards_fts, rowid, username, password, profile_name)
              VALUES('delete', old.id, old.username, old.password, '');
            END
          ''');
          await customStatement('''
            CREATE TRIGGER IF NOT EXISTS cards_au AFTER UPDATE ON cards BEGIN
              INSERT INTO cards_fts(cards_fts, rowid, username, password, profile_name)
              VALUES('delete', old.id, old.username, old.password, '');
              INSERT INTO cards_fts(rowid, username, password, profile_name)
              VALUES (new.id, new.username, new.password,
                (SELECT name FROM profiles WHERE id = new.profile_id));
            END
          ''');

          // View لتبسيط الاستعلامات
          await customStatement('''
            CREATE VIEW IF NOT EXISTS active_cards_with_profiles AS
            SELECT c.id, c.username, c.status, c.created_at,
                   c.upload_bytes, c.download_bytes,
                   p.name as profile_name, p.rate_limit,
                   (c.upload_bytes + c.download_bytes) as total_bytes
            FROM cards c
            JOIN profiles p ON c.profile_id = p.id
            WHERE c.status = 'active'
          ''');
        },
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );
}

/// يفتح اتصال SQLite على ملف في مجلد التطبيق
LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'mikrotik_manager.sqlite'));
    return NativeDatabase.createInBackground(
      file,
      setup: (db) {
        db.execute('PRAGMA foreign_keys = ON');
      },
    );
  });
}
