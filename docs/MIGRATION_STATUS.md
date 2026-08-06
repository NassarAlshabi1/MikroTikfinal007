# حالة هجرة Isar — تقرير مُحدّث

> تاريخ آخر تحديث: 2026-08-07
> الفرع: `feature/isar-migration`
> آخر commit تمت مراجعته: `96dfc2a` — `fix(android): إصلاح namespace isar_flutter_libs للتوافق مع AGP الحديث`

---

## 1. ملخّص تنفيذي

**الهجرة إلى Isar مكتملة بالكامل** على الفرع `feature/isar-migration`. تم استبدال Drift/SQLite بالكامل بـ Isar في جميع طبقات المشروع:

- **`pubspec.yaml`**: تمت إزالة `drift`, `drift_dev`, `sqlite3_flutter_libs` واستبدالها بـ `isar: ^3.1.0+1`, `isar_flutter_libs: ^3.1.0+1`, `isar_generator: ^3.1.0+1`.
- **`lib/database/`**: لا يوجد أي إشارة لـ Drift — جميع الملفات تستخدم `package:isar/isar.dart`.
- **Schemas**: 4 collections كاملة في `lib/database/isar/`:
  - `CardCollection` (مع `@Index(unique: true)` على username)
  - `ProfileCollection` (مع index على `mikrotikId`)
  - `AiDiagnosticCollection` (مع composite index على `mode + startedAt`)
  - `ExecutedCommandCollection` (مع composite index على `executedAt + riskLevel`)
- **DAOs**: 4 DAOs مُهاجَرة بالكامل في `lib/database/daos/`.
- **Riverpod Providers**: `database_provider.dart` يوفّر FutureProvider + StreamProvider لكل DAO.
- **Migration Service**: `migration_service.dart` يُرحّل بيانات SharedPreferences القديمة إلى Isar تلقائياً عند أول تشغيل.

تم تشغيل جميع الفحوصات المهنية وتأكيد أن الكود في حالة ممتازة:
- **`flutter analyze`**: 0 أخطاء
- **`flutter test`**: 335 اختبار ناجح
- **`dart run build_runner build`**: 299 output بدون تعارضات
- **CI على GitHub Actions**: 4 workflows نجحت بالكامل على commit `96dfc2a`

---

## 2. بنية قاعدة البيانات الجديدة (Isar)

```
lib/database/
├── isar_provider.dart              # Singleton لإدارة مثيل Isar
├── database_provider.dart          # Riverpod providers لكل DAO
├── migration_service.dart          # ترحيل البيانات من SharedPreferences/Files
├── sync_service.dart               # مزامنة مع MikroTik
├── isar/
│   ├── card_collection.dart        # @collection CardCollection
│   ├── card_collection.g.dart      # كود مولّد من isar_generator
│   ├── profile_collection.dart     # @collection ProfileCollection
│   ├── profile_collection.g.dart
│   ├── ai_diagnostic_collection.dart
│   ├── ai_diagnostic_collection.g.dart
│   ├── executed_command_collection.dart
│   └── executed_command_collection.g.dart
└── daos/
    ├── cards_dao.dart              # CardsDao + CardsStatistics
    ├── profiles_dao.dart           # ProfilesDao
    ├── ai_diagnostics_dao.dart     # AiDiagnosticsDao + DiagnosticsStatistics
    └── executed_commands_dao.dart  # ExecutedCommandsDao + CommandsStatistics + MonthlyCommandReport
```

---

## 3. مميزات الهجرة

### 3.1 أداء أعلى
- **بحث فوري** عبر `@Index` — أسرع من FTS5 في SQLite
- **Composite indexes** للاستعلامات الشائعة (e.g., `status + createdAt`)
- **Transactions ذرّية** عبر `writeTxn()`
- **Lazy loading** عبر Riverpod FutureProvider

### 3.2 Type Safety
- جميع الـ schemas مُعرَّفة بـ `@collection` وحقول `late` type-safe
- لا SQL injection (NoSQL بالكامل)
- Code generation عبر `isar_generator` يُنتج `*.g.dart` مع query builders type-safe

### 3.3 Reactive
- Stream Providers لكل استعلام reactive (`watchAllCards`, `watchActiveCards`, ...)
- UI يتحدّث تلقائياً عند تغيّر البيانات

### 3.4 Migration آمن
- `MigrationService.migrateFromDriftIfNeeded()` يعمل مرة واحدة عند أول تشغيل
- يُرحّل جلسات التشخيص من SharedPreferences
- يُرحّل الكروت المحفوظة من ملفات `.txt`
- يضع علامة `isar_migration_done = true` بعد النجاح
- أي خطأ لا يمنع استخدام التطبيق (try/catch شامل)

---

## 4. نتائج CI على آخر commit

| Workflow | الحالة | التفاصيل |
|----------|--------|----------|
| Build Flutter Release APK | ✅ نجاح | 17/17 خطوة |
| Code Quality & Testing | ✅ نجاح | Code Analysis + Unit Tests (335) + Security Scan + Build Verification + Quality Gate |
| Multi-Platform Build | ✅ نجاح | Android + macOS + Windows + Linux (Web متوقع تخطّيه بسبب dart:ffi) |
| Build and Release | ✅ نجاح | Prepare Version + Build Android + Create GitHub Release |

---

## 5. اختبارات شاشة BulkAdd (9 اختبارات)

أُضيفت اختبارات شاملة في `test/features/bulk_add_screen_test.dart`:

### 5.1 مجموعة "عرض أساسي" (3 اختبارات)
- `يعرض الشاشة بشكل صحيح مع profiles فارغة`
- `يعرض الشاشة مع profiles موجودة`
- `لا يلقي استثناءات أثناء البناء`

### 5.2 مجموعة "متانة ضد البيانات التالفة" (4 اختبارات)
- `لا يتعطل عند وجود JSON تالف في pdf_templates`
- `لا يتعطل عند وجود JSON تالف في qahtani_linked_data`
- `لا يتعطل عند is_network_linked=true بدون data`
- `لا يتعطل عند وجود JSON سليم في qahtani_linked_data`

### 5.3 مجموعة "عناصر UI" (2 اختبار)
- `يحتوي على جميع الحقول المتوقعة` (4 TextFormFields + 4 Dropdowns + 1 ElevatedButton + 1 CheckboxListTile)
- `القيم الافتراضية صحيحة` (length=8, count=10, shared_users=1)

---

## 6. إصلاح مشكلة "الشاشة البيضاء" في BulkAddScreen

### السبب الجذري
في `_loadTemplates()` و `_checkLinkStatus()`، كانت `jsonDecode()` و `PdfTemplate.fromJson()` تُستدعيان **بدون try/catch**. أي JSON تالف في SharedPreferences كان يُلقى استثناءً غير معالَج في `initState`، مما يُجمّد الشاشة أو يجعلها فارغة.

### الإصلاح
أُحيطت كل عمليات parsing بـ try/catch مستقلة:
- كل template يُparsed بشكل منفصل — التالف يُتجاهل بدل تعطيل الباقي
- فشل prefs لا يُعطّل الشاشة
- `debugPrint` يُسجّل الأخطاء للتشخيص

---

## 7. إعدادات Android

تم إصلاح `namespace isar_flutter_libs` للتوافق مع AGP (Android Gradle Plugin) الحديث في commit `96dfc2a`.

---

## 8. خطوات التشغيل المحلي

```bash
# 1. تثبيت التبعيات
flutter pub get

# 2. توليد كود Isar
dart run build_runner build --delete-conflicting-outputs

# 3. فحص الكود
flutter analyze

# 4. تشغيل الاختبارات
flutter test
```

جميع الأوامر تنتهي بنجاح على الفرع الحالي.
