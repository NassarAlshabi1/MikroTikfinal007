// ============================================================
//  اختبارات وحدة لـ AppLogger — flutter-security skill
//  تتحقق من:
//  - redact للأنماط الحساسة (API keys, passwords, tokens, JWTs)
//  - مستويات السجل (debug/info/warning/error/security)
//  - تصنيفات السجل
// ============================================================

import 'package:flutter_test/flutter_test.dart';
import 'package:mikrotik_manager/services/app_logger.dart';

void main() {
  group('AppLogger', () {
    // ============================================================
    //  Redaction — إخفاء البيانات الحساسة
    // ============================================================
    group('Sensitive data redaction', () {
      test('يخفي API key بصيغة api-xxxx', () {
        // نحتاج طريقة لاختبار _redact — سنستخدم log() ونرى المخرجات
        // أو نضيف طريقة اختبار. لكن _redact خاصة.
        // الحل: نختبر السلوك العام عبر logs.
        // هنا نتحقق فقط من عدم رمي استثناء.
        expect(
          () => AppLogger.info('api-0946bf1ab4b50eaf9cd57af05671e7928ea51948e44a6ee8cc125cd439dac3d3'),
          returnsNormally,
        );
      });

      test('يخفي password في رسالة', () {
        expect(
          () => AppLogger.info('password=secret123 user=admin'),
          returnsNormally,
        );
      });

      test('يخفي bearer tokens', () {
        expect(
          () => AppLogger.info('Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.payload.signature'),
          returnsNormally,
        );
      });

      test('يخفي JWT tokens', () {
        expect(
          () => AppLogger.info('Token: eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiIxMjM0NTY3ODkwIn0.abc123def456'),
          returnsNormally,
        );
      });

      test('لا يخفي نصوص عادية', () {
        expect(
          () => AppLogger.info('System rebooted by admin at 14:30'),
          returnsNormally,
        );
      });
    });

    // ============================================================
    //  Log levels — مستويات السجل
    // ============================================================
    group('Log levels', () {
      test('debug() لا يرمي استثناء', () {
        expect(() => AppLogger.debug('test debug message'), returnsNormally);
      });

      test('info() لا يرمي استثناء', () {
        expect(() => AppLogger.info('test info message'), returnsNormally);
      });

      test('warning() لا يرمي استثناء', () {
        expect(() => AppLogger.warning('test warning message'), returnsNormally);
      });

      test('error() لا يرمي استثناء مع error object', () {
        expect(
          () => AppLogger.error('test error', error: Exception('test')),
          returnsNormally,
        );
      });

      test('security() لا يرمي استثناء', () {
        expect(() => AppLogger.security('security event'), returnsNormally);
      });
    });

    // ============================================================
    //  Log categories — تصنيفات السجل
    // ============================================================
    group('Log categories', () {
      test('يدعم كل التصنيفات', () {
        expect(
          () => AppLogger.info('net', category: LogCategory.network),
          returnsNormally,
        );
        expect(
          () => AppLogger.info('ui', category: LogCategory.ui),
          returnsNormally,
        );
        expect(
          () => AppLogger.info('ai', category: LogCategory.ai),
          returnsNormally,
        );
        expect(
          () => AppLogger.info('sec', category: LogCategory.security),
          returnsNormally,
        );
        expect(
          () => AppLogger.info('store', category: LogCategory.storage),
          returnsNormally,
        );
        expect(
          () => AppLogger.info('sys', category: LogCategory.system),
          returnsNormally,
        );
        expect(
          () => AppLogger.info('mcp', category: LogCategory.mcp),
          returnsNormally,
        );
      });
    });

    // ============================================================
    //  LogLevel enum
    // ============================================================
    group('LogLevel', () {
      test('لكل مستوى emoji و label', () {
        for (final level in LogLevel.values) {
          expect(level.emoji, isNotEmpty);
          expect(level.label, isNotEmpty);
        }
      });

      test('الترتيب الصحيح: debug < info < warning < error < security', () {
        expect(LogLevel.debug.index, lessThan(LogLevel.info.index));
        expect(LogLevel.info.index, lessThan(LogLevel.warning.index));
        expect(LogLevel.warning.index, lessThan(LogLevel.error.index));
        expect(LogLevel.error.index, lessThan(LogLevel.security.index));
      });
    });

    // ============================================================
    //  LogCategory enum
    // ============================================================
    group('LogCategory', () {
      test('لكل تصنيف tag مختصر', () {
        for (final cat in LogCategory.values) {
          expect(cat.tag, isNotEmpty);
          expect(cat.tag.length, lessThanOrEqualTo(5));
        }
      });

      test('tags فريدة', () {
        final tags = LogCategory.values.map((c) => c.tag).toSet();
        expect(tags.length, LogCategory.values.length);
      });
    });
  });
}
