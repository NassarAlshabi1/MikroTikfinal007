import 'package:flutter_test/flutter_test.dart';
import 'package:mikronet/services/expired_users_classifier.dart';

/// اختبارات توافق User Manager مع **RouterOS v6** و v7.
///
/// الحمولات (payloads) هنا مأخوذة من مخرجات `/tool user-manager user print`
/// الحقيقية في RouterOS 6.x: `username`, `actual-profile`, `uptime-used`,
/// `download-used`, `last-seen`, `customer` — ولا يوجد `name` ولا `limit-uptime`.
void main() {
  /// صف مستخدم بصيغة v6 كما يصل عبر API.
  Map<String, dynamic> v6User({
    required String id,
    required String username,
    String? actualProfile = "PF-1g",
    String uptimeUsed = "0s",
    String downloadUsed = "0",
    String uploadUsed = "0",
    String customer = "admin",
    String lastSeen = "jan/01/2026 10:00:00",
  }) {
    final map = <String, dynamic>{
      ".id": id,
      "username": username,
      "uptime-used": uptimeUsed,
      "download-used": downloadUsed,
      "upload-used": uploadUsed,
      "customer": customer,
      "last-seen": lastSeen,
    };
    if (actualProfile != null) map["actual-profile"] = actualProfile;
    return map;
  }

  group('buildProfileLimits — أشكال v6', () {
    test('قيد مباشر على الباقة (v6) يُقرأ بشكل صحيح', () {
      final limits = ExpiredUsersClassifier.buildProfileLimits(
        profiles: [
          {'name': 'PF-1g', 'name-for-users': '1GB', 'validity': '2w', 'limitation': 'LIM-1g'},
        ],
        limitations: [
          {'name': 'LIM-1g', 'uptime-limit': '1w2d3h4m5s', 'transfer-limit': '1073741824'},
        ],
        links: const [],
      );

      expect(limits.containsKey('PF-1g'), isTrue);
      expect(limits.containsKey('1GB'), isTrue);
      expect(limits['PF-1g']!.uptime, const Duration(days: 9, hours: 3, minutes: 4, seconds: 5));
      expect(limits['PF-1g']!.transfer, 1073741824);
    });

    test('ربط الباقة بالقيد عبر جدول profile-limitation', () {
      final limits = ExpiredUsersClassifier.buildProfileLimits(
        profiles: [
          {'name': 'PF-2g', 'name-for-users': 'PF-2g', 'validity': '1w'},
        ],
        limitations: [
          {'name': 'LIM-2g', 'uptime-limit': '30d', 'transfer-limit': '2.0GiB'},
        ],
        links: [
          {'profile': 'PF-2g', 'limitation': 'LIM-2g'},
        ],
      );

      expect(limits['PF-2g']!.uptime, const Duration(days: 30));
      expect(limits['PF-2g']!.transfer, 2 * 1024 * 1024 * 1024);
    });

    test('باقة بلا قيد ← يُستخدم validity كبديل', () {
      final limits = ExpiredUsersClassifier.buildProfileLimits(
        profiles: [
          {'name': 'PF-3g', 'validity': '4w2d'},
        ],
        limitations: const [],
        links: const [],
      );

      expect(limits['PF-3g']!.uptime, const Duration(days: 30));
      expect(limits['PF-3g']!.transfer, isNull);
    });
  });

  group('تصنيف v6 — استهلاك المدة', () {
    test('كرت استهلك مدته كاملة ← مؤهل للحذف', () {
      final limits = {
        'PF-1w': const ProfileLimit(uptime: Duration(days: 7)),
      };

      final result = ExpiredUsersClassifier.classify(
        users: [
          v6User(
            id: '*1',
            username: 'user_full',
            actualProfile: 'PF-1w',
            uptimeUsed: '1w0s', // 7 أيام بالضبط
            downloadUsed: '1024',
            uploadUsed: '2048',
          ),
        ],
        limitsByProfile: limits,
        statesByUser: const {},
        routerVersion: 6,
      );

      expect(result.exhausted.length, 1);
      expect(result.exhausted.first.username, 'user_full');
      expect(result.exhausted.first.uptimeExhausted, isTrue);
      expect(result.exhausted.first.expiredReason, 'انتهت المدة');
      expect(result.exhausted.first.profileCleared, isFalse);
      expect(result.exhausted.first.usedBytes, 3072);
    });

    test('كرت تخطّى المدة (1w2d3h4m5s ضد 1w) ← مؤهل', () {
      final result = ExpiredUsersClassifier.classify(
        users: [
          v6User(id: '*2', username: 'over', actualProfile: 'PF-1w', uptimeUsed: '1w2d3h4m5s'),
        ],
        limitsByProfile: {'PF-1w': const ProfileLimit(uptime: Duration(days: 7))},
        statesByUser: const {},
        routerVersion: 6,
      );

      expect(result.exhausted.length, 1);
      expect(result.exhausted.first.percent, greaterThan(100));
    });

    test('كرت لم يكمل مدته بفارق ثانية ← غير مؤهل', () {
      final result = ExpiredUsersClassifier.classify(
        users: [
          v6User(
            id: '*3',
            username: 'almost',
            actualProfile: 'PF-1w',
            uptimeUsed: '6d23h59m59s',
          ),
        ],
        limitsByProfile: {'PF-1w': const ProfileLimit(uptime: Duration(days: 7))},
        statesByUser: const {},
        routerVersion: 6,
      );

      expect(result.exhausted, isEmpty);
      expect(result.stillRunning.length, 1);
      expect(result.stillRunning.first.usedLabel, '6d23h59m59s');
    });

    test('مقارنة الباقة عبر القيد: 30d ضد 1w2d (v6)', () {
      final limits = ExpiredUsersClassifier.buildProfileLimits(
        profiles: [
          {'name': 'PF-1g', 'name-for-users': '1GB', 'limitation': 'LIM-1g'},
        ],
        limitations: [
          {'name': 'LIM-1g', 'uptime-limit': '1w2d'},
        ],
        links: const [],
      );

      final result = ExpiredUsersClassifier.classify(
        users: [
          v6User(id: '*4', username: 'viaLimitation', actualProfile: '1GB', uptimeUsed: '30d'),
        ],
        limitsByProfile: limits,
        statesByUser: const {},
        routerVersion: 6,
      );

      expect(result.exhausted.length, 1);
    });
  });

  group('تصنيف v6 — إشارة الباقة المُزالة (!actual-profile)', () {
    test('مستخدم بلا actual-profile مع استهلاك ← منتهٍ (سلوك v6 الأصلي)', () {
      final result = ExpiredUsersClassifier.classify(
        users: [
          v6User(id: '*5', username: 'cleared', actualProfile: null, uptimeUsed: '7s'),
        ],
        limitsByProfile: const {},
        statesByUser: const {},
        routerVersion: 6,
      );

      expect(result.exhausted.length, 1);
      expect(result.exhausted.first.profileCleared, isTrue);
      expect(result.exhausted.first.expiredReason, 'الباقة مُزالة (v6)');
      expect(result.clearedProfileCount, 1);
    });

    test('حقل actual-profile فارغ نصًّا + استهلاك ← منتهٍ', () {
      final result = ExpiredUsersClassifier.classify(
        users: [
          v6User(id: '*6', username: 'emptyProfile', actualProfile: '', uptimeUsed: '1h'),
        ],
        limitsByProfile: const {},
        statesByUser: const {},
        routerVersion: 6,
      );

      expect(result.exhausted.length, 1);
      expect(result.exhausted.first.profileCleared, isTrue);
    });

    test('كرت جديد بلا باقة وبلا استهلاك ← لا يُحذف', () {
      final result = ExpiredUsersClassifier.classify(
        users: [
          v6User(id: '*7', username: 'brandNew', actualProfile: null, uptimeUsed: '0s'),
        ],
        limitsByProfile: const {},
        statesByUser: const {},
        routerVersion: 6,
      );

      expect(result.exhausted, isEmpty);
      expect(result.withoutLimits, 1);
    });

    test('كرت له باقة ولم يستهلك ← لا يُحذف', () {
      final result = ExpiredUsersClassifier.classify(
        users: [
          v6User(id: '*8', username: 'unused', actualProfile: 'PF-1w', uptimeUsed: '0s'),
        ],
        limitsByProfile: {'PF-1w': const ProfileLimit(uptime: Duration(days: 7))},
        statesByUser: const {},
        routerVersion: 6,
      );

      expect(result.exhausted, isEmpty);
      expect(result.stillRunning.length, 1);
      expect(result.stillRunning.first.percent, 0);
    });
  });

  group('تصنيف v6 — قواعد الأمان', () {
    test('مدة غير مفهومة ← يُستبعد ولا يُحذف', () {
      final result = ExpiredUsersClassifier.classify(
        users: [
          v6User(id: '*9', username: 'weird', actualProfile: 'PF-1w', uptimeUsed: '1h30'),
        ],
        limitsByProfile: {'PF-1w': const ProfileLimit(uptime: Duration(days: 7))},
        statesByUser: const {},
        routerVersion: 6,
      );

      expect(result.exhausted, isEmpty);
      expect(result.unparsable, 1);
    });

    test('حد مذكور لكن غير مفهوم ← يُستبعد', () {
      final result = ExpiredUsersClassifier.classify(
        users: [
          {
            '.id': '*10',
            'username': 'badLimit',
            'actual-profile': 'PF-x',
            'uptime-used': '1d',
            'limit-uptime': 'غير معروف',
          },
        ],
        limitsByProfile: const {},
        statesByUser: const {},
        routerVersion: 6,
      );

      expect(result.exhausted, isEmpty);
      expect(result.unparsable, 1);
    });

    test('0s كحد مطلق ← لا يُحذف أبدًا', () {
      final result = ExpiredUsersClassifier.classify(
        users: [
          {
            '.id': '*11',
            'username': 'zeroLimit',
            'actual-profile': 'PF-z',
            'uptime-used': '5d',
            'limit-uptime': '0s',
          },
        ],
        limitsByProfile: const {},
        statesByUser: const {},
        routerVersion: 6,
      );

      expect(result.exhausted, isEmpty);
    });
  });

  group('تصنيف v7 — لا يُستخدم معيار الباقة المُزالة', () {
    test('مستخدم v7 بلا باقة وباستهلاك ← لا يُعتبر منتهيًا تلقائيًا', () {
      final result = ExpiredUsersClassifier.classify(
        users: [
          {
            '.id': '*20',
            'name': 'v7user',
            'group': 'default',
            'uptime-used': '2h',
          },
        ],
        limitsByProfile: const {},
        statesByUser: const {},
        routerVersion: 7,
      );

      expect(result.exhausted, isEmpty);
      expect(result.withoutLimits, 1);
    });

    test('v7: حالة الباقة used ← منتهٍ (سكربت MikroTik المعتمد)', () {
      final result = ExpiredUsersClassifier.classify(
        users: [
          {
            '.id': '*21',
            'name': 'v7used',
            'group': 'admin',
            'uptime-used': '10d',
          },
        ],
        limitsByProfile: const {},
        statesByUser: {'v7used': 'used'},
        routerVersion: 7,
      );

      expect(result.exhausted.length, 1);
      expect(result.exhausted.first.profileStateUsed, isTrue);
      expect(result.exhausted.first.expiredReason, 'الباقة مستهلكة (v7)');
      expect(result.stateUsedCount, 1);
    });
  });

  group('parseBytes — صيغ RouterOS', () {
    test('قيم صحيحة ووحدات', () {
      expect(ExpiredUsersClassifier.parseBytes('1073741824'), 1073741824);
      expect(ExpiredUsersClassifier.parseBytes('1KiB'), 1024);
      expect(ExpiredUsersClassifier.parseBytes('1.5MiB'), (1.5 * 1024 * 1024).round());
      expect(ExpiredUsersClassifier.parseBytes('2GiB'), 2 * 1024 * 1024 * 1024);
      expect(ExpiredUsersClassifier.parseBytes('0'), 0);
      expect(ExpiredUsersClassifier.parseBytes(''), isNull);
      expect(ExpiredUsersClassifier.parseBytes(null), isNull);
    });
  });
}
