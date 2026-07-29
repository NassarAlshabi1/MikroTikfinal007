// ============================================================
//  اختبارات وحدة لـ Result + MikrotikError
//  تطبّق flutter-testing skill: pattern-based unit tests
// ============================================================

import 'package:flutter_test/flutter_test.dart';
import 'package:mikrotik_manager/core/app_constants.dart';
import 'package:mikrotik_manager/core/result.dart';

void main() {
  group('Result<E, S>', () {
    // ============================================================
    //  Success
    // ============================================================
    group('Success', () {
      test('يُنشأ بقيمة', () {
        const result = Success<String, int>(42);
        expect(result.value, 42);
        expect(result.isSuccess, isTrue);
        expect(result.isFailure, isFalse);
      });

      test('getOrElse يرجع القيمة', () {
        const result = Success<String, int>(42);
        expect(result.getOrElse(() => 0), 42);
      });

      test('getOrDefault يرجع القيمة', () {
        const result = Success<String, int>(42);
        expect(result.getOrDefault(0), 42);
      });

      test('map يحول القيمة', () {
        const result = Success<String, int>(5);
        final mapped = result.map((v) => v * 2);
        expect(mapped, isA<Success<String, int>>());
        expect((mapped as Success<String, int>).value, 10);
      });

      test('mapError لا يغير القيمة', () {
        const result = Success<String, int>(5);
        final mapped = result.mapError((e) => 'NEW_ERROR');
        expect(mapped, isA<Success<String, int>>());
        expect((mapped as Success<String, int>).value, 5);
      });

      test('when يستدعي onSuccess فقط', () {
        const result = Success<String, int>(42);
        final output = result.when(
          onSuccess: (v) => 'success: $v',
          onFailure: (e) => 'failure: $e',
        );
        expect(output, 'success: 42');
      });
    });

    // ============================================================
    //  Failure
    // ============================================================
    group('Failure', () {
      test('يُنشأ بخطأ', () {
        const result = Failure<String, int>('NETWORK_ERROR');
        expect(result.error, 'NETWORK_ERROR');
        expect(result.isSuccess, isFalse);
        expect(result.isFailure, isTrue);
      });

      test('getOrElse يرجع orElse', () {
        const result = Failure<String, int>('ERROR');
        expect(result.getOrElse(() => 99), 99);
      });

      test('getOrDefault يرجع الافتراضية', () {
        const result = Failure<String, int>('ERROR');
        expect(result.getOrDefault(99), 99);
      });

      test('map لا يغير الخطأ', () {
        const result = Failure<String, int>('ERROR');
        final mapped = result.map((v) => v * 2);
        expect(mapped, isA<Failure<String, int>>());
        expect((mapped as Failure<String, int>).error, 'ERROR');
      });

      test('mapError يحول الخطأ', () {
        const result = Failure<String, int>('OLD_ERROR');
        final mapped = result.mapError((e) => 'NEW_ERROR');
        expect(mapped, isA<Failure<String, int>>());
        expect((mapped as Failure<String, int>).error, 'NEW_ERROR');
      });

      test('when يستدعي onFailure فقط', () {
        const result = Failure<String, int>('ERROR');
        final output = result.when(
          onSuccess: (v) => 'success: $v',
          onFailure: (e) => 'failure: $e',
        );
        expect(output, 'failure: ERROR');
      });
    });

    // ============================================================
    //  Type safety
    // ============================================================
    test('Result مع أنواع مخصصة', () {
      const success = Success<MikrotikError, String>('snapshot data');
      expect(success.value, 'snapshot data');

      const failure = Failure<MikrotikError, String>(TimeoutMikrotikError());
      expect(failure.error, isA<TimeoutMikrotikError>());
    });
  });

  // ============================================================
  //  MikrotikError — sealed class exhaustive matching
  // ============================================================
  group('MikrotikError', () {
    test('TimeoutMikrotikError له userMessage', () {
      const error = TimeoutMikrotikError();
      expect(error.userMessage, contains('مهلة'));
    });

    test('ConnectionRefusedMikrotikError له userMessage', () {
      const error = ConnectionRefusedMikrotikError();
      expect(error.userMessage, contains('رفض'));
    });

    test('AuthenticationFailedMikrotikError له userMessage', () {
      const error = AuthenticationFailedMikrotikError();
      expect(error.userMessage, contains('اعتماد'));
    });

    test('CredentialsMissingMikrotikError له userMessage', () {
      const error = CredentialsMissingMikrotikError();
      expect(error.userMessage, contains('سجّل'));
    });

    test('NetworkMikrotikError مع detail', () {
      const error = NetworkMikrotikError('connection reset');
      expect(error.userMessage, contains('connection reset'));
    });

    test('NetworkMikrotikError بدون detail', () {
      const error = NetworkMikrotikError();
      expect(error.userMessage, contains('خطأ شبكي'));
    });

    test('UnknownMikrotikError يخزن الرسالة', () {
      const error = UnknownMikrotikError('something went wrong');
      expect(error.message, 'something went wrong');
      expect(error.userMessage, contains('something went wrong'));
    });

    test('exhaustive pattern matching عبر switch', () {
      MikrotikError error = const TimeoutMikrotikError();

      String handleMessage(MikrotikError e) {
        return switch (e) {
          TimeoutMikrotikError() => 'timeout',
          ConnectionRefusedMikrotikError() => 'refused',
          AuthenticationFailedMikrotikError() => 'auth',
          CredentialsMissingMikrotikError() => 'missing',
          NetworkMikrotikError(:final detail) => 'network: $detail',
          UnknownMikrotikError(:final message) => 'unknown: $message',
        };
      }

      expect(handleMessage(error), 'timeout');
      expect(handleMessage(const ConnectionRefusedMikrotikError()), 'refused');
      expect(handleMessage(const AuthenticationFailedMikrotikError()), 'auth');
      expect(handleMessage(const CredentialsMissingMikrotikError()), 'missing');
      expect(handleMessage(const NetworkMikrotikError('reset')), 'network: reset');
      expect(handleMessage(const UnknownMikrotikError('oops')), 'unknown: oops');
    });
  });

  // ============================================================
  //  mapExceptionToMikrotikError
  // ============================================================
  group('mapExceptionToMikrotikError', () {
    test('يحوّل TimeoutException', () {
      final error = mapExceptionToMikrotikError(
        Exception('Operation timed out'),
      );
      expect(error, isA<TimeoutMikrotikError>());
    });

    test('يحوّل connection refused', () {
      final error = mapExceptionToMikrotikError(
        Exception('Connection refused by host'),
      );
      expect(error, isA<ConnectionRefusedMikrotikError>());
    });

    test('يحوّل login failure', () {
      final error = mapExceptionToMikrotikError(
        Exception('Login failed for user admin'),
      );
      expect(error, isA<AuthenticationFailedMikrotikError>());
    });

    test('يحوّل credentials missing', () {
      final error = mapExceptionToMikrotikError(
        Exception('Credentials missing'),
      );
      expect(error, isA<CredentialsMissingMikrotikError>());
    });

    test('يحوّل استثناء غير معروف', () {
      final error = mapExceptionToMikrotikError(
        Exception('Some weird error'),
      );
      expect(error, isA<UnknownMikrotikError>());
      expect((error as UnknownMikrotikError).message, contains('Some weird error'));
    });
  });

  // ============================================================
  //  AppConstants
  // ============================================================
  group('AppConstants', () {
    test('MikroTik API ports', () {
      expect(AppConstants.defaultRouterOsApiPort, 8728);
      expect(AppConstants.defaultRouterOsApiSslPort, 8729);
      expect(AppConstants.defaultSshPort, 22);
    });

    test('Timeouts معقولة', () {
      expect(AppConstants.defaultConnectionTimeout.inSeconds, 10);
      expect(AppConstants.defaultCommandTimeout.inSeconds, 30);
    });

    test('Diagnostics limits', () {
      expect(AppConstants.maxLogLines, greaterThan(100));
      expect(AppConstants.maxEventsDisplayed, 100);
    });

    test('Security defaults', () {
      expect(AppConstants.clipboardAutoClearDuration.inSeconds, 30);
      expect(AppConstants.maxLoginAttemptsBeforeLockout, 5);
    });

    test('SharedPreferences keys', () {
      expect(AppConstants.prefsKeyIp, 'ip');
      expect(AppConstants.prefsKeyUser, 'user');
      expect(AppConstants.prefsKeyRememberMe, 'remember_me');
    });
  });
}
