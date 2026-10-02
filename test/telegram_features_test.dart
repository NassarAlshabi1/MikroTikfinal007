import 'package:flutter_test/flutter_test.dart';
import 'package:mikronet/services/telegram_features.dart';
import 'package:mikronet/services/telegram_health.dart';
import 'package:mikronet/services/telegram_messages.dart';

/// اختبارات **تكامل Telegram** — منطق نقي بلا أي اتصال شبكة.
///
/// تغطي: كتالوج الميزات السبع، التفعيل/التعطيل، تنقية الإعدادات المحفوظة،
/// وبناء نصوص الرسائل (ردم/إنترنت) لكل ميزة.
void main() {
  group('كتالوج المميزات', () {
    test('سبع ميزات بمعرّفات فريدة', () {
      final ids = TelegramFeatureCatalog.ids;
      expect(ids.length, 7);
      expect(ids.toSet().length, 7, reason: 'لا تكرار في المعرّفات');
    });

    test('كل ميزة لها عنوان وشرح وشارة غير فارغة', () {
      for (final f in TelegramFeatureCatalog.all) {
        expect(f.title.trim(), isNotEmpty, reason: f.id);
        expect(f.subtitle.trim(), isNotEmpty, reason: f.id);
        expect(f.badge.trim(), isNotEmpty, reason: f.id);
      }
    });

    test('المعرّفات الأساسية موجودة (كما في الشاشة)', () {
      for (final id in [
        'netwatch',
        'devices_status',
        'router_status',
        'sales',
        'active_users',
        'disk_alert',
        'daily_summary',
      ]) {
        expect(TelegramFeatureCatalog.byId(id), isNotNull, reason: id);
      }
    });

    test('معرّف غير معروف ← null (بلا تخمين)', () {
      expect(TelegramFeatureCatalog.byId('whatever'), isNull);
    });
  });

  group('تفعيل المميزات', () {
    test('الافتراضي: كل الميزات مفعّلة', () {
      final flags = TelegramFeatureCatalog.defaultFlags();
      expect(TelegramFeatureCatalog.enabledCount(flags), 7);
    });

    test('تفعيل/تعطيل الكل', () {
      var flags = TelegramFeatureCatalog.defaultFlags();
      flags = TelegramFeatureCatalog.setAll(flags, false);
      expect(TelegramFeatureCatalog.enabledCount(flags), 0);

      flags = TelegramFeatureCatalog.setAll(flags, true);
      expect(TelegramFeatureCatalog.enabledCount(flags), 7);
    });

    test('تبديل ميزة واحدة لا يمسّ البقية', () {
      var flags = TelegramFeatureCatalog.defaultFlags();
      flags = TelegramFeatureCatalog.toggle(flags, 'sales');

      expect(flags['sales'], isFalse);
      expect(flags['netwatch'], isTrue);
      expect(TelegramFeatureCatalog.enabledCount(flags), 6);
    });

    test('isEnabled تعمل مع مفاتيح مفقودة', () {
      expect(TelegramFeatureCatalog.isEnabled({}, 'sales'), isFalse);
      expect(TelegramFeatureCatalog.isEnabled({'sales': true}, 'sales'), isTrue);
    });

    test('تنقية الإعدادات: المعرّف غير المعروف يُحذف والناقص يُضاف', () {
      final normalized = TelegramFeatureCatalog.normalize({
        'sales': '1',
        'netwatch': false,
        'ghost_feature': true, // معرّف غير معروف
      });

      expect(normalized.containsKey('ghost_feature'), isFalse);
      expect(normalized['sales'], isTrue);
      expect(normalized['netwatch'], isFalse);
      expect(normalized.length, 7);
      expect(normalized['disk_alert'], isTrue, reason: 'الناقص يأخذ الافتراضي');
    });

    test('تنقية خريطة فارغة/باطلة ← الافتراضي', () {
      expect(TelegramFeatureCatalog.normalize(null).length, 7);
      expect(TelegramFeatureCatalog.normalize({}).length, 7);
    });
  });

  group('نصوص الرسائل', () {
    test('رسالة انقطاع جهاز بث تحتوي الاسم والعنوان والحالة', () {
      final text = TelegramMessages.netwatch(
        device: 'tower-01',
        ip: '10.5.50.2',
        isUp: false,
        at: DateTime(2026, 10, 3, 14, 5),
      );

      expect(text, contains('tower-01'));
      expect(text, contains('10.5.50.2'));
      expect(text, contains('انقطع'));
      expect(text, contains('2026-10-03 14:05'));
    });

    test('رسالة عودة الجهاز تعرض «عاد إلى الشبكة»', () {
      final text = TelegramMessages.netwatch(device: 'tower-02', isUp: true);
      expect(text, contains('عاد إلى الشبكة'));
    });

    test('تقرير أجهزة البث يحسب المنقطعة ويضع تحذيرًا', () {
      final warn = TelegramMessages.devicesStatus(total: 12, online: 9, offline: 3);
      expect(warn, contains('12'));
      expect(warn, contains('9'));
      expect(warn, contains('3'));
      expect(warn, contains('⚠️'));

      final ok = TelegramMessages.devicesStatus(total: 5, online: 5, offline: 0);
      expect(ok, contains('✅'));
    });

    test('حالة الراوتر تعرض كل الحقول', () {
      final text = TelegramMessages.routerStatus(
        cpu: '18%',
        freeMemory: '142 MiB',
        uptime: '12d 4h',
        version: '7.15.3',
      );
      expect(text, contains('18%'));
      expect(text, contains('142 MiB'));
      expect(text, contains('12d 4h'));
      expect(text, contains('7.15.3'));
    });

    test('تقرير المبيعات يعرض العدد والإجمالي بمنزلتين', () {
      final text = TelegramMessages.sales(cardsCount: 24, total: 4800.5);
      expect(text, contains('24'));
      expect(text, contains('4800.50'));
    });

    test('تنبيه المساحة يعرض الحرة والإجمالي والنسبة', () {
      final text = TelegramMessages.diskAlert(
        free: '96 MiB',
        total: '128 MiB',
        percentFree: 25,
      );
      expect(text, contains('96 MiB'));
      expect(text, contains('128 MiB'));
      expect(text, contains('25%'));
    });

    test('الملخص اليومي يجمع الأرقام ويظهر تحذير الأجهزة المنقطعة', () {
      final text = TelegramMessages.dailySummary(
        cardsCount: 24,
        total: 4800,
        activeUsers: 37,
        routerUptime: '12d 4h',
        offlineDevices: 2,
      );
      expect(text, contains('24'));
      expect(text, contains('4800.00'));
      expect(text, contains('37'));
      expect(text, contains('12d 4h'));
      expect(text, contains('أجهزة منقطعة'));
    });

    test('رسالة تجربة كل ميزة تُبنى بلا خطأ وبعنوان الميزة', () {
      for (final feature in TelegramFeatureCatalog.all) {
        final text = TelegramMessages.testFor(feature.id);
        expect(text, contains(feature.title), reason: feature.id);
        expect(text, contains('تجربة'), reason: feature.id);
      }
    });

    test('معرّف غير معروف في التجربة ← رسالة واضحة بلا استثناء', () {
      expect(TelegramMessages.testFor('ghost'), contains('غير معروفة'));
    });

    test('تنسيق التاريخ يعرض أصفارًا بادئة', () {
      expect(
        TelegramMessages.formatDateTime(DateTime(2026, 1, 5, 9, 7)),
        '2026-01-05 09:07',
      );
    });
  });

  group('فحص صحة الشبكة (منطق نقي)', () {
    test('تحويل الأحجام: MiB/GiB/KiB/B ورقم مجرّد', () {
      expect(TelegramHealth.parseSize('96 MiB'), 96 * 1024 * 1024);
      expect(TelegramHealth.parseSize('1.5GiB'), 1.5 * 1024 * 1024 * 1024);
      expect(TelegramHealth.parseSize('2048 KiB'), 2048 * 1024);
      expect(TelegramHealth.parseSize('512 B'), 512);
      expect(TelegramHealth.parseSize('1073741824'), 1073741824);
    });

    test('صيغة غير مفهومة ⇒ null بلا تخمين', () {
      expect(TelegramHealth.parseSize(''), isNull);
      expect(TelegramHealth.parseSize('كثير'), isNull);
      expect(TelegramHealth.parseSize('abc MB'), isNull);
      expect(TelegramHealth.parseSize('12 PB'), isNull);
    });

    test('نسبة الحرة تُحسب بدقة', () {
      expect(TelegramHealth.freePercent('64 MiB', '128 MiB'), 50.0);
      expect(TelegramHealth.freePercent('32 MiB', '128 MiB'), 25.0);
    });

    test('الإجمالي صفر أو صيغة مجهولة ⇒ null', () {
      expect(TelegramHealth.freePercent('1 MiB', '0'), isNull);
      expect(TelegramHealth.freePercent('x', '128 MiB'), isNull);
    });

    test('تنبيه المساحة يظهر تحت 15% فقط', () {
      expect(TelegramHealth.needsDiskAlert('10 MiB', '128 MiB'), isTrue);
      expect(TelegramHealth.needsDiskAlert('30 MiB', '128 MiB'), isFalse);
      expect(TelegramHealth.needsDiskAlert('غير معروف', '128 MiB'), isFalse);
    });

    test('قراءة رد الـping: received=1 ⇒ وصل', () {
      expect(
        TelegramHealth.pingReachable([
          {'received': '1', 'sent': '1', 'time': '1ms'}
        ]),
        isTrue,
      );
    });

    test('قراءة رد الـping: timeout أو received=0 ⇒ لم يصل', () {
      expect(
        TelegramHealth.pingReachable([
          {'status': 'timeout', 'received': '0', 'sent': '1'}
        ]),
        isFalse,
      );
      expect(TelegramHealth.pingReachable([]), isFalse);
    });

    test('قراءة رد الـping: time بلا status ⇒ وصل', () {
      expect(TelegramHealth.pingReachable([{'time': '3ms'}]), isTrue);
    });
  });
}
