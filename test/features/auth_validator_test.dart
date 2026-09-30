import 'package:flutter_test/flutter_test.dart';
import 'package:mikrotik_manager/features/auth/domain/auth_validator.dart';

void main() {
  group('AuthValidator local connection', () {
    test('requires host and username', () {
      expect(
        AuthValidator.validateLocal(host: '', username: 'admin', port: '8728'),
        isNotNull,
      );
      expect(
        AuthValidator.validateLocal(
          host: '192.168.88.1',
          username: '',
          port: '8728',
        ),
        isNotNull,
      );
    });

    test('accepts a valid RouterOS endpoint', () {
      expect(
        AuthValidator.validateLocal(
          host: '192.168.88.1',
          username: 'admin',
          port: '8728',
        ),
        isNull,
      );
    });
  });

  group('AuthValidator remote connection', () {
    test('requires a domain instead of an IPv4 address', () {
      expect(
        AuthValidator.validateRemote(
          host: '203.0.113.5',
          username: 'admin',
          password: 'secret',
          port: '8729',
        ),
        contains('Domain'),
      );
    });

    test('requires credentials', () {
      expect(
        AuthValidator.validateRemote(
          host: 'router.example.com',
          username: '',
          password: '',
          port: '8729',
        ),
        isNotNull,
      );
    });

    test('accepts a valid remote endpoint', () {
      expect(
        AuthValidator.validateRemote(
          host: 'router.example.com',
          username: 'admin',
          password: 'secret',
          port: '8729',
        ),
        isNull,
      );
    });
  });

  test('rejects ports outside the TCP range', () {
    for (final port in ['0', '65536', 'invalid', '']) {
      expect(
        AuthValidator.validateLocal(
          host: '192.168.88.1',
          username: 'admin',
          port: port,
        ),
        isNotNull,
        reason: 'port $port must be rejected',
      );
    }
  });
}
