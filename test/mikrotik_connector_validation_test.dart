import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mikrotik_manager/mikrotik_connector.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Future<void> expectCredentialsError(
    Map<String, Object> values,
    String expectedMessage,
  ) async {
    SharedPreferences.setMockInitialValues(values);

    await expectLater(
      MikrotikConnector.connect(),
      throwsA(
        isA<MikrotikCredentialsMissingException>().having(
          (error) => error.message,
          'message',
          expectedMessage,
        ),
      ),
    );
  }

  group('MikrotikConnector credential validation', () {
    test('rejects a missing router address before network access', () async {
      await expectCredentialsError(
        {'user': 'admin', 'pass': 'secret'},
        'عنوان IP غير محدد. الرجاء إدخال عنوان الراوتر.',
      );
    });

    test('rejects a blank router address', () async {
      await expectCredentialsError(
        {'ip': '   ', 'user': 'admin', 'pass': 'secret'},
        'عنوان IP غير محدد. الرجاء إدخال عنوان الراوتر.',
      );
    });

    test('rejects a missing router username', () async {
      await expectCredentialsError(
        {'ip': '192.168.88.1', 'pass': 'secret'},
        'اسم المستخدم غير محدد.',
      );
    });

    test('rejects a blank router username', () async {
      await expectCredentialsError(
        {'ip': '192.168.88.1', 'user': ' ', 'pass': 'secret'},
        'اسم المستخدم غير محدد.',
      );
    });

    test('rejects a missing router password', () async {
      await expectCredentialsError(
        {'ip': '192.168.88.1', 'user': 'admin'},
        'كلمة المرور غير محددة.',
      );
    });

    test('rejects ports outside the valid TCP range', () async {
      await expectCredentialsError(
        {
          'ip': '192.168.88.1',
          'user': 'admin',
          'pass': 'secret',
          'port': '70000',
        },
        'رقم المنفذ غير صالح: 70000',
      );
    });

    test('uses a readable exception string for credentials errors', () {
      const exception = MikrotikCredentialsMissingException('بيانات ناقصة');

      expect(
        exception.toString(),
        'MikrotikCredentialsMissingException: بيانات ناقصة',
      );
    });

    test('retains the optional original connection error', () {
      final original = StateError('socket closed');
      final exception = MikrotikConnectionException('تعذر الاتصال', original);

      expect(exception.message, 'تعذر الاتصال');
      expect(exception.originalException, same(original));
      expect(
        exception.toString(),
        'MikrotikConnectionException: تعذر الاتصال',
      );
    });
  });
}
