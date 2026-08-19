import 'package:flutter_test/flutter_test.dart';
import 'package:mikrotik_manager/ai/diagnostics_models.dart';
import 'package:mikrotik_manager/ai/system_prompts.dart';

void main() {
  group('Professional AI system prompts', () {
    test('كل أوضاع التشخيص تستخدم العقد الاحترافي الموحد', () {
      for (final mode in DiagnosticMode.values) {
        final prompt = promptForMode(mode);
        expect(prompt, contains('عقد الإجابة الاحترافي'));
        expect(prompt, contains('RouterOS 6.49.19'));
        expect(prompt, contains('الخلاصة التنفيذية'));
        expect(prompt, contains('لا تخترع'));
        expect(prompt, contains('لم يُنفّذ'));
        expect(prompt, contains('بوابة RouterOS v6'));
        expect(prompt, contains('أمر تحقق قراءة فقط'));
      }
    });

    test('Prompt Hotspot يثبت مسار Hotspot المحلي ويمنع الخلط', () {
      final prompt = promptForMode(DiagnosticMode.hotspot);

      expect(prompt, contains('/ip/hotspot/user/add'));
      expect(prompt, contains('=name=...'));
      expect(prompt, contains('shared-users'));
      expect(prompt, contains('actual-profile'));
      expect(prompt, contains('Hotspot المحلي'));
    });

    test('Prompt العام يمنع أوامر RouterOS v7 وطلبات التنفيذ الصامت', () {
      final prompt = promptForMode(DiagnosticMode.general);

      expect(prompt, contains('لا تقترح أوامر v7-only'));
      expect(prompt, contains('WireGuard'));
      expect(prompt, contains('لا تُخرج سكربت تعديل أو حذف'));
      expect(prompt, contains('اقتراح فقط'));
      expect(prompt, contains('لا تستخدم `placeholders`'));
      expect(prompt, contains('إذا تعارضت بيانات المستخدم مع snapshot'));
    });

    test('أوصاف أوضاع التشخيص لا تعرض تقنيات RouterOS v7', () {
      for (final mode in DiagnosticMode.values) {
        expect(mode.displayName.toLowerCase(), isNot(contains('v7')));
        expect(mode.description.toLowerCase(), isNot(contains('v7')));
        expect(mode.description.toLowerCase(), isNot(contains('wireguard')));
      }
    });
  });
}
