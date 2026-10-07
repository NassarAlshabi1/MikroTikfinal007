import 'package:flutter_test/flutter_test.dart';
import 'package:mikronet/services/cable_diagnostics.dart';

/// اختبارات **فحص الكيبل** — حمولات RouterOS حقيقية بلا أي اتصال شبكة.
///
/// أمثلة مخرجات `/interface ethernet cable-test ether1`:
/// ```
///       name: ether1
///     status: link-ok
/// cable-pairs: ok-ok-ok-ok
/// ```
/// وفي حالة عطل:
/// ```
/// cable-pairs: ok-open-ok-short
/// ```
void main() {
  group('CableTestResult.parse — الأزواج والحالة', () {
    test('كيبل سليم: ok-ok-ok-ok ← درجة سليم بلا أعطال', () {
      final result = CableTestResult.parse(
        interfaceName: "ether1",
        rows: [
          {"name": "ether1", "status": "link-ok", "cable-pairs": "ok-ok-ok-ok"},
        ],
      );

      expect(result.supported, isTrue);
      expect(result.pairs.length, 4);
      expect(result.pairs.every((pair) => pair.isOk), isTrue);
      expect(result.hasFaultPairs, isFalse);
      expect(result.severity, CableSeverity.ok);
      expect(result.statusLabel, contains("سليم"));
    });

    test('عطل مختلط: ok-open-ok-short ← عطل مع تحديد الأزواج', () {
      final result = CableTestResult.parse(
        interfaceName: "ether1",
        rows: [
          {"name": "ether1", "status": "open", "cable-pairs": "ok-open-ok-short"},
        ],
      );

      expect(result.pairs.length, 4);
      expect(result.pairs[0].status, CablePairStatus.ok);
      expect(result.pairs[1].status, CablePairStatus.open);
      expect(result.pairs[2].status, CablePairStatus.ok);
      expect(result.pairs[3].status, CablePairStatus.short);
      expect(result.severity, CableSeverity.fault);
      expect(result.summary, contains("2"));
      expect(result.summary, contains("4"));
    });

    test('صيغة بأقواس وفواصل: [ok, ok, ok, ok]', () {
      final result = CableTestResult.parse(
        interfaceName: "ether2",
        rows: [
          {"name": "ether2", "status": "link-ok", "cable-pairs": "[\"ok\", \"ok\", \"ok\", \"ok\"]"},
        ],
      );

      expect(result.pairs.length, 4);
      expect(result.severity, CableSeverity.ok);
    });

    test('صيغة بفواصل منقوطة: ok;ok;ok;ok', () {
      final pairs = CableTestResult.parsePairsString("ok;ok;open;ok");
      expect(pairs.length, 4);
      expect(pairs[2].status, CablePairStatus.open);
    });

    test('صفوف منفصلة لكل زوج (بعض الإصدارات)', () {
      final result = CableTestResult.parse(
        interfaceName: "ether3",
        rows: [
          {"name": "ether3", "pair": "1-2", "status": "ok"},
          {"name": "ether3", "pair": "3-6", "status": "ok"},
          {"name": "ether3", "pair": "4-5", "status": "short"},
          {"name": "ether3", "pair": "7-8", "status": "ok"},
        ],
      );

      expect(result.pairs.length, 4);
      expect(result.pairs[2].status, CablePairStatus.short);
      expect(result.severity, CableSeverity.fault);
    });

    test('حقول مستقلة pair1..pair4', () {
      final result = CableTestResult.parse(
        interfaceName: "ether4",
        rows: [
          {"name": "ether4", "pair1": "ok", "pair2": "ok", "pair3": "ok", "pair4": "open"},
        ],
      );

      expect(result.pairs.length, 4);
      expect(result.pairs[3].status, CablePairStatus.open);
    });

    test('لا نتائج ← غير مدعوم برسالة عربية واضحة', () {
      final result = CableTestResult.parse(interfaceName: "sfp1", rows: const []);

      expect(result.supported, isFalse);
      expect(result.severity, CableSeverity.unknown);
      expect(result.errorMessage, contains("SFP"));
    });

    test('no-link مع أزواج سليمة ← تحذير لا عطل', () {
      final result = CableTestResult.parse(
        interfaceName: "ether5",
        rows: [
          {"name": "ether5", "status": "no-link", "cable-pairs": "ok-ok-ok-ok"},
        ],
      );

      expect(result.severity, CableSeverity.warning);
      expect(result.statusLabel, contains("لا يوجد اتصال"));
    });

    test('حالة غير مفهومة لا تُخمَّن كسليمة', () {
      final result = CableTestResult.parse(
        interfaceName: "ether6",
        rows: [
          {"name": "ether6", "status": "weird-state", "cable-pairs": "zz-zz-zz-zz"},
        ],
      );

      expect(result.severity, CableSeverity.unknown);
      expect(result.pairs.every((pair) => pair.status == CablePairStatus.unknown), isTrue);
    });
  });

  group('EthernetLinkInfo.parse — السرعة وduplex', () {
    test('1Gbps مع duplex كامل', () {
      final link = EthernetLinkInfo.parse(
        interfaceName: "ether1",
        rows: [
          {
            "name": "ether1",
            "status": "link-ok",
            "rate": "1Gbps",
            "full-duplex": "true",
            "auto-negotiation": "true",
          },
        ],
      );

      expect(link.hasLink, isTrue);
      expect(link.rateMbps, 1000);
      expect(link.rateLabel, "1 Gbps");
      expect(link.isGigabit, isTrue);
      expect(link.isDegraded, isFalse);
      expect(link.fullDuplex, isTrue);
      expect(link.duplexLabel, contains("كامل"));
    });

    test('100Mbps على منفذ جيجابت ← سرعة مخفّضة', () {
      final link = EthernetLinkInfo.parse(
        interfaceName: "ether2",
        rows: [
          {"name": "ether2", "status": "link-ok", "rate": "100Mbps", "full-duplex": "true"},
        ],
      );

      expect(link.rateMbps, 100);
      expect(link.isDegraded, isTrue);
    });

    test('صيغ سرعة مختلفة: 10Mbps · 2.5Gbps · 1000000000', () {
      expect(EthernetLinkInfo.parseRateMbps("10Mbps"), 10);
      expect(EthernetLinkInfo.parseRateMbps("2.5Gbps"), 2500);
      expect(EthernetLinkInfo.parseRateMbps("1000000000"), 1000);
      expect(EthernetLinkInfo.parseRateMbps(""), isNull);
      expect(EthernetLinkInfo.parseRateMbps("غير معروف"), isNull);
    });

    test('لا رابط ← hasLink=false وليس مخفّضًا', () {
      final link = EthernetLinkInfo.parse(
        interfaceName: "ether3",
        rows: [
          {"name": "ether3", "status": "no-link", "rate": ""},
        ],
      );

      expect(link.hasLink, isFalse);
      expect(link.isDegraded, isFalse);
      expect(link.rateLabel, "غير معروف");
    });
  });

  group('CableDiagnostics.combine — التشخيص والتوصيات', () {
    test('كابل سليم + رابط 1Gbps ← تشخيص سليم', () {
      final cable = CableTestResult.parse(
        interfaceName: "ether1",
        rows: [
          {"name": "ether1", "status": "link-ok", "cable-pairs": "ok-ok-ok-ok"},
        ],
      );
      final link = EthernetLinkInfo.parse(
        interfaceName: "ether1",
        rows: [
          {"name": "ether1", "status": "link-ok", "rate": "1Gbps", "full-duplex": "true"},
        ],
      );

      final diagnosis = CableDiagnostics.combine(cable: cable, link: link);

      expect(diagnosis.severity, CableSeverity.ok);
      expect(diagnosis.headline, contains("سليم"));
      expect(diagnosis.headline, contains("1 Gbps"));
      expect(diagnosis.recommendations, isNotEmpty);
    });

    test('عطل في الأزواج ← درجة عطل وتوصيات إصلاح الكيبل', () {
      final cable = CableTestResult.parse(
        interfaceName: "ether1",
        rows: [
          {"name": "ether1", "status": "open", "cable-pairs": "ok-open-ok-ok"},
        ],
      );
      final link = EthernetLinkInfo.parse(
        interfaceName: "ether1",
        rows: [
          {"name": "ether1", "status": "link-ok", "rate": "100Mbps"},
        ],
      );

      final diagnosis = CableDiagnostics.combine(cable: cable, link: link);

      expect(diagnosis.severity, CableSeverity.fault);
      expect(diagnosis.headline, contains("عطل"));
      expect(diagnosis.details, contains("الزوج 2"));
      expect(diagnosis.recommendations.any((item) => item.contains("RJ45")), isTrue);
      expect(diagnosis.recommendations.any((item) => item.contains("100 Mbps")), isTrue);
    });

    test('أزواج سليمة لكن السرعة 100Mbps ← تحذير مع توصيات الفئة/الطرف الآخر', () {
      final cable = CableTestResult.parse(
        interfaceName: "ether1",
        rows: [
          {"name": "ether1", "status": "link-ok", "cable-pairs": "ok-ok-ok-ok"},
        ],
      );
      final link = EthernetLinkInfo.parse(
        interfaceName: "ether1",
        rows: [
          {"name": "ether1", "status": "link-ok", "rate": "100Mbps"},
        ],
      );

      final diagnosis = CableDiagnostics.combine(cable: cable, link: link);

      expect(diagnosis.severity, CableSeverity.warning);
      expect(diagnosis.headline, contains("مخفّضة"));
      expect(diagnosis.recommendations.any((item) => item.contains("CAT5e")), isTrue);
      expect(diagnosis.recommendations.any((item) => item.contains("1Gbps")), isTrue);
    });

    test('no-link ← تحذير «لا يوجد اتصال» بتوصيات فحص الطرف الآخر', () {
      final cable = CableTestResult.parse(
        interfaceName: "ether1",
        rows: [
          {"name": "ether1", "status": "no-link", "cable-pairs": "ok-ok-ok-ok"},
        ],
      );

      final diagnosis = CableDiagnostics.combine(cable: cable);

      expect(diagnosis.severity, CableSeverity.warning);
      expect(diagnosis.headline, contains("لا يوجد اتصال"));
    });

    test('غير مدعوم (CHR/SFP) ← شرح واضح بلا ادّعاء عطل', () {
      final cable = CableTestResult.unsupported("sfp1", CableDiagnostics.friendlyError("not supported"));

      final diagnosis = CableDiagnostics.combine(cable: cable);

      expect(diagnosis.severity, CableSeverity.unknown);
      expect(diagnosis.details, contains("SFP"));
      expect(diagnosis.recommendations.length, greaterThanOrEqualTo(2));
    });

    test('لا فحص بعد ← دعوة لتنفيذ الفحص', () {
      final diagnosis = CableDiagnostics.combine();

      expect(diagnosis.severity, CableSeverity.unknown);
      expect(diagnosis.details, contains("فحص الكيبل"));
    });
  });

  group('رسائل الأخطاء وأوامر الفحص', () {
    test('رسائل RouterOS تُترجم لعربية واضحة', () {
      expect(CableDiagnostics.friendlyError("no such command"), contains("لا يوفّر"));
      expect(CableDiagnostics.friendlyError("not supported"), contains("SFP"));
      expect(CableDiagnostics.friendlyError("timeout"), contains("انتهت مدة"));
      expect(CableDiagnostics.friendlyError(""), contains("تعذّر"));
    });

    test('أوامر المحاولة تحتوي اسم المنفذ وبترتيب صحيح', () {
      final commands = CableDiagnostics.cableTestCommandCandidates("ether5");
      expect(commands.length, greaterThanOrEqualTo(2));
      expect(commands.first, contains("/interface/ethernet/cable-test"));
      expect(commands.first.any((part) => part.contains("ether5")), isTrue);

      final monitor = CableDiagnostics.monitorCommandCandidates("ether5");
      expect(monitor.first, contains("/interface/ethernet/monitor"));
      expect(monitor.first.any((part) => part.contains("ether5")), isTrue);
    });
  });
}
