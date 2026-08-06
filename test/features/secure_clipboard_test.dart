// ============================================================
//  اختبارات وحدة لـ SecureClipboard — flutter-security skill
//
//  ملاحظة: Clipboard.setData تتطلب PlatformChannel، لذا نحتاج
//  TestWidgetsFlutterBinding.ensureInitialized() + mock.
// ============================================================

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mikrotik_manager/services/secure_clipboard.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Mock Clipboard channel — الاسم الصحيح هو 'flutter/clipboard'
  final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  const channel = MethodChannel('flutter/clipboard');

  setUp(() {
    messenger.setMockMethodCallHandler(channel, (MethodCall methodCall) async {
      if (methodCall.method == 'Clipboard.setData') return null;
      if (methodCall.method == 'Clipboard.getData') {
        return <String, dynamic>{'text': ''};
      }
      return null;
    });
  });

  tearDown(() {
    SecureClipboard.cancelAutoClear();
    messenger.setMockMethodCallHandler(channel, null);
  });

  group('SecureClipboard', () {
    test('copy لا يرمي استثناء لنص فارغ', () async {
      await SecureClipboard.copy('');
    });

    test('copy بنص عادي لا يرمي استثناء', () async {
      await SecureClipboard.copy('test text');
      await Future.delayed(const Duration(milliseconds: 10));
    });

    test('copy بنص حساس يبدأ مؤقت المسح', () async {
      await SecureClipboard.copy('secret password', sensitive: true);
      expect(SecureClipboard.hasPendingClear, isTrue);
    });

    test('copy بنص غير حساس لا يبدأ مؤقت', () async {
      await SecureClipboard.copy('not sensitive', sensitive: false);
      expect(SecureClipboard.hasPendingClear, isFalse);
    });

    test('cancelAutoClear يلغي المؤقت', () async {
      await SecureClipboard.copy('secret', sensitive: true);
      expect(SecureClipboard.hasPendingClear, isTrue);
      SecureClipboard.cancelAutoClear();
      expect(SecureClipboard.hasPendingClear, isFalse);
    });

    test('المسح الفوري يلغي المؤقت', () async {
      await SecureClipboard.copy('secret', sensitive: true);
      expect(SecureClipboard.hasPendingClear, isTrue);
      await SecureClipboard.clearNow();
      expect(SecureClipboard.hasPendingClear, isFalse);
    });
  });
}
