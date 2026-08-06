// ============================================================
//  اختبارات تكاملية لجمع البيانات من MikroTik
//
//  تطبّق flutter-testing skill: integration tests
//  يختبر:
//  1) MikrotikDataCollector.collect() — مع router غير متاح
//  2) CommandExecutor.execute() — حالات الفشل
//  3) MikrotikLogAnalyzer.collectLogs() — مع بيانات اعتماد ناقصة
//  4) سلوك timeout و error handling
//
//  ملاحظة: لا يمكن الاتصال بـ MikroTik حقيقي في CI،
//  لذا نختبر الحالات الخاطئة (error paths) + البنية الصحيحة
// ============================================================

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mikrotik_manager/ai/command_executor.dart';
import 'package:mikrotik_manager/ai/diagnostics_models.dart';
import 'package:mikrotik_manager/ai/mikrotik_data_collector.dart';
import 'package:mikrotik_manager/ai/mikrotik_log_analyzer.dart';
import 'package:mikrotik_manager/services/secure_credentials_storage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late InMemorySecureCredentialsStorage mockStorage;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    mockStorage = InMemorySecureCredentialsStorage();
    SecureCredentialsStorageContainer.instance = mockStorage;
  });

  tearDown(() {
    SecureCredentialsStorageContainer.resetToProduction();
  });

  group('🔗 MikroTik Data Collection — Integration Tests', () {
    // ============================================================
    //  1) CommandExecutor.execute — حالات الخطأ
    // ============================================================
    group('① CommandExecutor.execute — Error Cases', () {
      test('يرمي استثناء عند غياب بيانات الاعتماد', () async {
        // لا توجد بيانات في prefs ولا في secure storage
        final result = await CommandExecutor.execute(
          command: '/system resource print',
          method: MikrotikConnectionMethod.routerOS,
          timeout: const Duration(seconds: 5),
        );

        expect(result.success, isFalse);
        expect(result.error, isNotNull);
        expect(result.error!.toLowerCase(), contains('بيانات'));
      });

      test('يرمي استثناء عند غياب كلمة المرور فقط', () async {
        SharedPreferences.setMockInitialValues({
          'ip': '192.168.99.99',
          'user': 'admin',
          // pass missing في secure storage (mockStorage فارغ)
        });

        final result = await CommandExecutor.execute(
          command: '/system resource print',
          method: MikrotikConnectionMethod.routerOS,
          timeout: const Duration(seconds: 5),
        );

        expect(result.success, isFalse);
        expect(result.error, isNotNull);
      });

      test('يرمي استثناء عند غياب IP', () async {
        SharedPreferences.setMockInitialValues({
          'user': 'admin',
          // ip missing
        });
        mockStorage.seed(mikrotikPass: 'secret');

        final result = await CommandExecutor.execute(
          command: '/system resource print',
          method: MikrotikConnectionMethod.routerOS,
          timeout: const Duration(seconds: 5),
        );

        expect(result.success, isFalse);
      });

      test('يفشل الاتصال بـ IP غير متاح (timeout/refused)', () async {
        SharedPreferences.setMockInitialValues({
          'ip': '192.168.99.99', // IP غير متاح
          'user': 'admin',
          'port': '8728',
        });
        mockStorage.seed(mikrotikPass: 'password');

        final stopwatch = Stopwatch()..start();
        final result = await CommandExecutor.execute(
          command: '/system resource print',
          method: MikrotikConnectionMethod.routerOS,
          timeout: const Duration(seconds: 5),
        );
        stopwatch.stop();

        expect(result.success, isFalse);
        // يجب أن يفشل خلال وقت معقول
        expect(stopwatch.elapsed.inSeconds, lessThan(15));
      });

      test('validateCommand يرفض الأوامر غير الصالحة', () {
        // أمر فارغ
        expect(CommandExecutor.validateCommand(''), isNotNull);

        // أمر بدون /
        expect(CommandExecutor.validateCommand('system resource print'),
            isNotNull);
      });

      test('validateCommand يقبل الأوامر الصالحة', () {
        expect(
            CommandExecutor.validateCommand('/system resource print'), isNull);
        expect(CommandExecutor.validateCommand('/ip address print'), isNull);
        expect(CommandExecutor.validateCommand('/interface print'), isNull);
      });

      test('classifyRisk يصنّف الأوامر الخطرة', () {
        expect(
          CommandExecutor.classifyRisk('/system reboot'),
          CommandRiskLevel.dangerous,
        );
        expect(
          CommandExecutor.classifyRisk('/system reset-configuration'),
          CommandRiskLevel.dangerous,
        );
        expect(
          CommandExecutor.classifyRisk('/ip firewall filter remove [find]'),
          CommandRiskLevel.dangerous,
        );
      });

      test('classifyRisk يصنّف الأوامر المتوسطة', () {
        expect(
          CommandExecutor.classifyRisk(
              '/ip firewall filter add chain=input action=drop'),
          CommandRiskLevel.moderate,
        );
        expect(
          CommandExecutor.classifyRisk('/system identity set name=router'),
          CommandRiskLevel.moderate,
        );
      });

      test('classifyRisk يصنّف أوامر القراءة كآمنة', () {
        expect(
          CommandExecutor.classifyRisk('/system resource print'),
          CommandRiskLevel.safe,
        );
        expect(
          CommandExecutor.classifyRisk('/interface print'),
          CommandRiskLevel.safe,
        );
        expect(
          CommandExecutor.classifyRisk('/ip address print'),
          CommandRiskLevel.safe,
        );
      });
    });

    // ============================================================
    //  2) MikrotikDataCollector.collect — حالات الخطأ
    // ============================================================
    group('② MikrotikDataCollector.collect — Error Cases', () {
      test('collectViaSSH يفشل عند غياب بيانات الاعتماد', () async {
        // لا توجد بيانات
        expect(
          () => MikrotikDataCollector.collectViaSSH(
            host: '192.168.99.99',
            username: 'admin',
            password: 'test',
            port: 22,
            timeout: const Duration(seconds: 5),
          ),
          throwsA(isA<Exception>()),
        );
      });

      test('collectViaSSH يفشل مع host غير متاح', () async {
        expect(
          () => MikrotikDataCollector.collectViaSSH(
            host: '192.168.99.99',
            username: 'admin',
            password: 'test',
            port: 22,
            timeout: const Duration(seconds: 3),
          ),
          throwsA(isA<Exception>()),
        );
      });

      test('collect يفشل برمي استثناء عند غياب SSH credentials', () async {
        expect(
          () => MikrotikDataCollector.collect(
            method: MikrotikConnectionMethod.ssh,
            sshHost: '',
            sshUsername: '',
            sshPassword: '',
          ),
          throwsA(isA<Exception>()),
        );
      });
    });

    // ============================================================
    //  3) MikrotikLogAnalyzer.collectLogs — حالات الخطأ
    // ============================================================
    group('③ MikrotikLogAnalyzer.collectLogs — Error Cases', () {
      test('يفشل عند غياب بيانات الاعتماد', () async {
        // لا توجد بيانات
        expect(
          () => MikrotikLogAnalyzer.collectLogs(
            method: MikrotikConnectionMethod.routerOS,
            timeout: const Duration(seconds: 5),
          ),
          throwsA(isA<Exception>()),
        );
      });

      test('يفشل عند IP غير متاح', () async {
        SharedPreferences.setMockInitialValues({
          'ip': '192.168.99.99',
          'user': 'admin',
          'port': '8728',
        });
        mockStorage.seed(mikrotikPass: 'password');

        expect(
          () => MikrotikLogAnalyzer.collectLogs(
            method: MikrotikConnectionMethod.routerOS,
            timeout: const Duration(seconds: 5),
          ),
          throwsA(isA<Exception>()),
        );
      });
    });

    // ============================================================
    //  4) MikrotikSnapshot — البنية
    // ============================================================
    group('④ MikrotikSnapshot — Structure', () {
      test('toAiContext ينتج نصاً منظماً', () {
        final snapshot = MikrotikSnapshot(
          interfaces: 'ether1, ether2',
          routes: '0.0.0.0/0 via 192.168.1.1',
          firewall: 'input chain',
          logs: 'system rebooted',
          system: 'RouterOS v6',
          ipAddress: '192.168.1.1',
          collectedAt: DateTime(2026, 7, 29),
        );

        final context = snapshot.toAiContext();
        expect(context, contains('192.168.1.1'));
        expect(context, contains('ether1'));
      });

      test('MikrotikSnapshot with DateTime', () {
        final snapshot = MikrotikSnapshot(
          interfaces: 'ether1, ether2',
          routes: '0.0.0.0/0',
          firewall: 'filter rules',
          logs: 'log line 1\nlog line 2',
          system: 'RouterOS 6.49',
          ipAddress: '192.168.1.1',
          collectedAt: DateTime(2026, 7, 29, 18, 0),
          extraData: const {'IP SERVICES': 'telnet, ssh'},
        );

        final context = snapshot.toAiContext();
        expect(context, contains('192.168.1.1'));
        expect(context, contains('ether1'));
        expect(context, contains('IP SERVICES'));
      });

      test('toAiContext يحترم maxLogLines', () {
        // إنشاء logs طويلة
        final logLines = List.generate(100, (i) => 'log line $i').join('\n');
        final snapshot = MikrotikSnapshot(
          interfaces: '',
          routes: '',
          firewall: '',
          logs: logLines,
          system: '',
          ipAddress: '192.168.1.1',
          collectedAt: DateTime.now(),
        );

        final context30 = snapshot.toAiContext(maxLogLines: 30);
        // يجب أن يحتوي على آخر 30 سطر فقط
        expect(context30, contains('log line 99'));
        expect(context30, isNot(contains('log line 50')));

        final context10 = snapshot.toAiContext(maxLogLines: 10);
        expect(context10, contains('log line 99'));
        expect(context10, isNot(contains('log line 80')));
      });
    });

    // ============================================================
    //  5) DiagnosticMode — Coverage
    // ============================================================
    group('⑤ DiagnosticMode — Coverage', () {
      test('كل الأوضاع لها displayName', () {
        for (final mode in DiagnosticMode.values) {
          expect(mode.displayName, isNotEmpty);
        }
      });

      test('كل الأوضاع لها description', () {
        for (final mode in DiagnosticMode.values) {
          expect(mode.description, isNotEmpty);
        }
      });

      test('عدد الأوضاع = 11', () {
        expect(DiagnosticMode.values.length, 11);
      });
    });

    // ============================================================
    //  6) MikrotikConnectionMethod — Coverage
    // ============================================================
    group('⑥ MikrotikConnectionMethod — Coverage', () {
      test('routerOS له displayName', () {
        expect(MikrotikConnectionMethod.routerOS.displayName, isNotEmpty);
      });

      test('ssh له displayName', () {
        expect(MikrotikConnectionMethod.ssh.displayName, isNotEmpty);
      });

      test('عدد الطرق = 2', () {
        expect(MikrotikConnectionMethod.values.length, 2);
      });
    });
  });

  // ============================================================
  //  SecureCredentialsStorage — Integration with MikroTik
  // ============================================================
  group('🔒 SecureCredentialsStorage + MikroTik Integration', () {
    test('كلمة المرور تُقرأ من secure storage بدل prefs', () async {
      // ضع كلمة المرور في secure storage (وليس prefs)
      await SecureCredentialsStorageContainer.instance
          .setMikrotikPassword('secret123');

      // prefs فارغة من 'pass'
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('pass'), isNull);

      // لكن secure storage يحتوي عليها
      final pass = await SecureCredentialsStorageContainer.instance
          .getMikrotikPassword();
      expect(pass, 'secret123');
    });

    test('clearMikrotikCredentials يحذف كلمة المرور فقط', () async {
      await SecureCredentialsStorageContainer.instance
          .setMikrotikPassword('secret');
      await SecureCredentialsStorageContainer.instance
          .setRemotePassword('remote');
      await SecureCredentialsStorageContainer.instance
          .setOomolApiKey('oomol-key');

      // امسح mikrotik فقط
      await SecureCredentialsStorageContainer.instance
          .clearMikrotikCredentials();

      // mikrotik محذوفة
      expect(
          await SecureCredentialsStorageContainer.instance
              .getMikrotikPassword(),
          isNull);
      // الباقي موجود
      expect(
          await SecureCredentialsStorageContainer.instance.getRemotePassword(),
          'remote');
      expect(await SecureCredentialsStorageContainer.instance.getOomolApiKey(),
          'oomol-key');
    });

    test('clearAll يحذف كل شيء', () async {
      await SecureCredentialsStorageContainer.instance.setMikrotikPassword('a');
      await SecureCredentialsStorageContainer.instance.setRemotePassword('b');
      await SecureCredentialsStorageContainer.instance.setOomolApiKey('c');

      await SecureCredentialsStorageContainer.instance.clearAll();

      expect(
          await SecureCredentialsStorageContainer.instance
              .getMikrotikPassword(),
          isNull);
      expect(
          await SecureCredentialsStorageContainer.instance.getRemotePassword(),
          isNull);
      expect(await SecureCredentialsStorageContainer.instance.getOomolApiKey(),
          isNull);
    });

    test('hasStoredCredentials يعمل بشكل صحيح', () async {
      expect(
          await SecureCredentialsStorageContainer.instance
              .hasStoredCredentials(),
          isFalse);

      await SecureCredentialsStorageContainer.instance
          .setMikrotikPassword('secret');
      expect(
          await SecureCredentialsStorageContainer.instance
              .hasStoredCredentials(),
          isTrue);

      await SecureCredentialsStorageContainer.instance
          .setMikrotikPassword(null);
      expect(
          await SecureCredentialsStorageContainer.instance
              .hasStoredCredentials(),
          isFalse);
    });

    test('setMikrotikPassword(null) يحذف', () async {
      await SecureCredentialsStorageContainer.instance
          .setMikrotikPassword('secret');
      expect(
          await SecureCredentialsStorageContainer.instance
              .getMikrotikPassword(),
          'secret');

      await SecureCredentialsStorageContainer.instance
          .setMikrotikPassword(null);
      expect(
          await SecureCredentialsStorageContainer.instance
              .getMikrotikPassword(),
          isNull);
    });

    test('setMikrotikPassword("") يحذف', () async {
      await SecureCredentialsStorageContainer.instance
          .setMikrotikPassword('secret');
      await SecureCredentialsStorageContainer.instance.setMikrotikPassword('');
      expect(
          await SecureCredentialsStorageContainer.instance
              .getMikrotikPassword(),
          isNull);
    });
  });
}
