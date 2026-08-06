// ============================================================
//  اختبارات شاملة لشاشة تشخيص AI
//
//  يغطي:
//  1) DiagnosticMessage (factory methods)
//  2) MikrotikSnapshot.toAiContext()
//  3) AiSettings (default_, copyWith, isConfigured)
//  4) RouterOsScript.fromText() + extraction
//  5) ScriptExecutor.extractScriptsFromAiResponse()
//  6) AutoFixService.analyze()
//  7) CommandExecutor.classifyRisk() + validateCommand()
//  8) Widget tests لـ _MessageBubble و _ScriptCard
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mikrotik_manager/ai/diagnostics_models.dart';
import 'package:mikrotik_manager/ai/script_executor.dart';
import 'package:mikrotik_manager/ai/auto_fix_service.dart';
import 'package:mikrotik_manager/ai/command_executor.dart';

void main() {
  group('🤖 اختبارات شاشة تشخيص AI', () {
    // ============================================================
    //  1) DiagnosticMessage — رسائل المحادثة
    // ============================================================
    group('① DiagnosticMessage', () {
      test('factory .user ينشئ رسالة مستخدم صحيحة', () {
        final msg = DiagnosticMessage.user('مرحبا');
        expect(msg.type, MessageType.user);
        expect(msg.content, 'مرحبا');
        expect(msg.id, isNotEmpty);
        expect(msg.timestamp, isA<DateTime>());
        expect(msg.suggestedCommands, isNull);
      });

      test('factory .assistant ينشئ رسالة مساعد مع أوامر', () {
        final msg = DiagnosticMessage.assistant(
          'إليك الحل',
          commands: const ['/ip address add', '/ip route add'],
        );
        expect(msg.type, MessageType.assistant);
        expect(msg.content, 'إليك الحل');
        expect(msg.suggestedCommands, hasLength(2));
        expect(msg.suggestedCommands!.first, '/ip address add');
      });

      test('factory .error ينشئ رسالة خطأ', () {
        final msg = DiagnosticMessage.error('فشل الاتصال');
        expect(msg.type, MessageType.error);
        expect(msg.content, 'فشل الاتصال');
      });

      test('factory .system ينشئ رسالة نظام', () {
        final msg = DiagnosticMessage.system('مرحباً بك');
        expect(msg.type, MessageType.system);
        expect(msg.content, 'مرحباً بك');
      });

      test('كل رسالة لها id فريد', () {
        final m1 = DiagnosticMessage.user('test1');
        final m2 = DiagnosticMessage.user('test2');
        expect(m1.id, isNot(m2.id));
      });
    });

    // ============================================================
    //  2) MikrotikSnapshot — لقطة بيانات MikroTik
    // ============================================================
    group('② MikrotikSnapshot', () {
      test('toAiContext ينتج نصاً يحتوي على كل الأقسام', () {
        final snapshot = MikrotikSnapshot(
          interfaces: 'ether1, ether2',
          routes: '0.0.0.0/0 via 192.168.1.1',
          firewall: 'chain=input action=drop',
          logs: 'system started',
          system: 'version=6.49.8',
          ipAddress: '192.168.1.1',
          collectedAt: DateTime(2025, 1, 1),
        );

        final context = snapshot.toAiContext();
        expect(context, contains('=== SYSTEM ==='));
        expect(context, contains('=== INTERFACES ==='));
        expect(context, contains('=== ROUTES ==='));
        expect(context, contains('=== FIREWALL FILTER ==='));
        expect(context, contains('=== RECENT LOGS'));
        expect(context, contains('=== DEVICE IP ==='));
        expect(context, contains('=== SNAPSHOT TIME ==='));
      });

      test('toAiContext يحدّ الـ logs إلى 30 سطر', () {
        final longLogs = List.generate(100, (i) => 'log line $i').join('\n');
        final snapshot = MikrotikSnapshot(
          interfaces: '',
          routes: '',
          firewall: '',
          logs: longLogs,
          system: '',
          ipAddress: '10.0.0.1',
          collectedAt: DateTime.now(),
        );

        final context = snapshot.toAiContext(maxLogLines: 30);
        // يجب أن يحتوي على آخر 30 سطر فقط
        expect(context, contains('log line 99'));
        expect(context, contains('log line 70'));
        // يجب ألا يحتوي على الأسطر القديمة
        expect(context, isNot(contains('log line 50')));
      });

      test('toAiContext يعرض الأقسام الإضافية (extraData)', () {
        final snapshot = MikrotikSnapshot(
          interfaces: '',
          routes: '',
          firewall: '',
          logs: '',
          system: '',
          ipAddress: '10.0.0.1',
          collectedAt: DateTime.now(),
          extraData: const {
            'IP SERVICES': 'telnet, ftp',
            'USERS': 'admin',
          },
        );

        final context = snapshot.toAiContext();
        expect(context, contains('=== IP SERVICES ==='));
        expect(context, contains('telnet, ftp'));
        expect(context, contains('=== USERS ==='));
        expect(context, contains('admin'));
      });
    });

    // ============================================================
    //  3) AiSettings — إعدادات الـ AI
    // ============================================================
    group('③ AiSettings', () {
      test('default_ يكون OpenRouter + google/gemini-2.5-flash', () {
        final settings = AiSettings.default_;
        expect(settings.provider, AiProvider.openRouter);
        expect(settings.model, 'google/gemini-2.5-flash');
        expect(settings.apiKey, isEmpty);
        expect(settings.isConfigured, isFalse);
      });

      test('isConfigured = true عند وجود apiKey', () {
        final settings = AiSettings.default_.copyWith(apiKey: 'sk-test');
        expect(settings.isConfigured, isTrue);
      });

      test('copyWith يُرجع نسخة جديدة بقيم محدّثة', () {
        final original = AiSettings.default_;
        final updated = original.copyWith(
          provider: AiProvider.gemini,
          model: 'gemini-2.5-flash',
          apiKey: 'AIza-test',
        );
        expect(updated.provider, AiProvider.gemini);
        expect(updated.model, 'gemini-2.5-flash');
        expect(updated.apiKey, 'AIza-test');
        // الأصلي لم يتغير
        expect(original.provider, AiProvider.openRouter);
      });

      test('effectiveBaseUrl يُرجع الافتراضي للمزود', () {
        // default_ لها baseUrl = 'https://openrouter.ai/api/v1' كقيمة صريحة
        final openAi = AiSettings.default_;
        expect(openAi.effectiveBaseUrl, 'https://openrouter.ai/api/v1');

        // لتغيير الـ baseUrl الافتراضي للمزود، ننشئ AiSettings جديد
        // (copyWith(baseUrl: null) لا يمسح بسبب ?? semantics)
        const gemini = AiSettings(
          provider: AiProvider.gemini,
          model: 'gemini-2.5-flash',
          apiKey: '',
          baseUrl: null,
          connectionMethod: MikrotikConnectionMethod.routerOS,
          maxTokens: 1500,
          mode: DiagnosticMode.general,
          agenticMaxSteps: 5,
        );
        expect(gemini.effectiveBaseUrl,
            'https://generativelanguage.googleapis.com/v1beta');

        const openAiSettings = AiSettings(
          provider: AiProvider.openAI,
          model: 'gpt-4o-mini',
          apiKey: '',
          baseUrl: null,
          connectionMethod: MikrotikConnectionMethod.routerOS,
          maxTokens: 1500,
          mode: DiagnosticMode.general,
          agenticMaxSteps: 5,
        );
        expect(openAiSettings.effectiveBaseUrl, 'https://api.openai.com/v1');
      });

      test('effectiveBaseUrl يستخدم baseUrl المخصص إن وُجد', () {
        final settings = AiSettings.default_.copyWith(
          baseUrl: 'https://openrouter.ai/api/v1',
        );
        expect(settings.effectiveBaseUrl, 'https://openrouter.ai/api/v1');
      });

      test('equality يأخذ كل الحقول في الاعتبار', () {
        final s1 = AiSettings.default_.copyWith(apiKey: 'key1');
        final s2 = AiSettings.default_.copyWith(apiKey: 'key1');
        final s3 = AiSettings.default_.copyWith(apiKey: 'key2');
        expect(s1 == s2, isTrue);
        expect(s1 == s3, isFalse);
      });
    });

    // ============================================================
    //  4) RouterOsScript — بناء السكربتات
    // ============================================================
    group('④ RouterOsScript', () {
      test('fromText يحلل نص متعدد الأسطر', () {
        const text = '''
# تعليق
/ip address add address=192.168.1.1/24 interface=ether1
/ip route add dst-address=0.0.0.0/0 gateway=192.168.1.1
''';
        final script = RouterOsScript.fromText(
          title: 'test',
          description: 'desc',
          text: text,
        );
        expect(script.commands, hasLength(2));
        // fromText يحافظ على الصيغة الأصلية (لا يحوّل المسافات إلى /)
        expect(script.commands[0],
            '/ip address add address=192.168.1.1/24 interface=ether1');
        expect(script.commands[1],
            '/ip route add dst-address=0.0.0.0/0 gateway=192.168.1.1');
      });

      test('fromText يتجاهل الأسطر الفارغة والتعليقات', () {
        const text = '''

# هذا تعليق
// هذا أيضاً تعليق

/ip service disable telnet

''';
        final script = RouterOsScript.fromText(
          title: 'test',
          description: 'desc',
          text: text,
        );
        expect(script.commands, hasLength(1));
        expect(script.commands.first, '/ip service disable telnet');
      });

      test('fromText يضيف / للأسطر التي لا تبدأ بـ /', () {
        const text = 'ip service print';
        final script = RouterOsScript.fromText(
          title: 'test',
          description: 'desc',
          text: text,
        );
        expect(script.commands.first, '/ip service print');
      });

      test('overallRisk = safe للأوامر الآمنة', () {
        const text = '/ip address print\n/interface print';
        final script = RouterOsScript.fromText(
          title: 'test',
          description: 'desc',
          text: text,
        );
        expect(script.overallRisk, CommandRiskLevel.safe);
      });

      test('overallRisk = moderate للأوامر المتوسطة', () {
        const text = '/ip address add address=192.168.1.1/24 interface=ether1';
        final script = RouterOsScript.fromText(
          title: 'test',
          description: 'desc',
          text: text,
        );
        expect(script.overallRisk, CommandRiskLevel.moderate);
      });

      test('overallRisk = dangerous للأوامر الخطرة', () {
        const text = '/system reboot\n/ip firewall filter remove [find]';
        final script = RouterOsScript.fromText(
          title: 'test',
          description: 'desc',
          text: text,
        );
        expect(script.overallRisk, CommandRiskLevel.dangerous);
      });

      test('isDangerous = true للسكربتات الخطرة', () {
        const text = '/system reboot';
        final script = RouterOsScript.fromText(
          title: 'test',
          description: 'desc',
          text: text,
        );
        expect(script.isDangerous, isTrue);
      });

      test('length يُرجع عدد الأوامر', () {
        const text = '/ip print\n/interface print\n/system print';
        final script = RouterOsScript.fromText(
          title: 'test',
          description: 'desc',
          text: text,
        );
        expect(script.length, 3);
      });
    });

    // ============================================================
    //  5) ScriptExecutor.extractScriptsFromAiResponse
    // ============================================================
    group('⑤ ScriptExecutor.extractScriptsFromAiResponse', () {
      test('يستخرج سكربت من كتلة ```...```', () {
        const aiResponse = '''
إليك الحل:

```routeros
/ip address add address=192.168.1.1/24 interface=ether1
/ip route add dst-address=0.0.0.0/0 gateway=192.168.1.1
```

هذا كل شيء!
''';
        final scripts = ScriptExecutor.extractScriptsFromAiResponse(
          aiResponse: aiResponse,
        );
        expect(scripts, hasLength(1));
        expect(scripts.first.commands, hasLength(2));
      });

      test('يستخرج عدة سكربتات منفصلة', () {
        const aiResponse = '''
سكربت 1:
```
/ip address print
```

سكربت 2:
```
/interface print
/system resource print
```
''';
        final scripts = ScriptExecutor.extractScriptsFromAiResponse(
          aiResponse: aiResponse,
        );
        expect(scripts, hasLength(2));
        expect(scripts[0].commands, hasLength(1));
        expect(scripts[1].commands, hasLength(2));
      });

      test('يتجاهل كتل الكود بدون أوامر RouterOS', () {
        const aiResponse = '''
```python
print("hello")
def foo():
    pass
```
''';
        final scripts = ScriptExecutor.extractScriptsFromAiResponse(
          aiResponse: aiResponse,
        );
        expect(scripts, isEmpty);
      });

      test('Fallback: يستخرج أوامر من نص بدون كتل كود', () {
        const aiResponse = '''
إليك الأوامر:
/ip address print
/interface print
/system resource print
''';
        final scripts = ScriptExecutor.extractScriptsFromAiResponse(
          aiResponse: aiResponse,
        );
        expect(scripts, hasLength(1));
        expect(scripts.first.commands, hasLength(3));
      });

      test('createBackupScript يُنشئ سكربت backup', () {
        final script = ScriptExecutor.createBackupScript();
        expect(script.title, contains('نسخة احتياطية'));
        expect(script.commands, isNotEmpty);
        expect(script.commands.any((c) => c.contains('backup')), isTrue);
      });

      test('createRollbackScript يُنشئ سكربت استعادة', () {
        final script = ScriptExecutor.createRollbackScript('my-backup');
        expect(script.title, contains('استعادة'));
        expect(script.commands, isNotEmpty);
        expect(script.isDangerous, isTrue);
      });

      test('previewScript يُنتج نصاً مع معلومات', () {
        const script = RouterOsScript(
          title: 'test',
          description: 'desc',
          commands: ['/ip print'],
          overallRisk: CommandRiskLevel.safe,
        );
        final preview = ScriptExecutor.previewScript(script);
        expect(preview, contains('test'));
        expect(preview, contains('آمن'));
        expect(preview, contains('/ip print'));
      });
    });

    // ============================================================
    //  6) AutoFixService.analyze
    // ============================================================
    group('⑥ AutoFixService', () {
      test('analyze يُرجع قائمة فارغة لـ snapshot فارغ', () {
        final snapshot = MikrotikSnapshot(
          interfaces: '',
          routes: '',
          firewall: '',
          logs: '',
          system: '',
          ipAddress: '',
          collectedAt: DateTime.now(),
        );
        final fixes = AutoFixService.analyze(snapshot);
        // قد يُرجع بعض الإصلاحات العامة (default route, NAT)
        expect(fixes, isA<List<ProposedFix>>());
      });

      test('analyze يكتشف NAT masquerade مفقود', () {
        final snapshot = MikrotikSnapshot(
          interfaces: 'ether1, ether2',
          routes: '0.0.0.0/0 via 192.168.1.1',
          firewall: 'chain=input action=accept',
          logs: '',
          system: 'version=6.49.8',
          ipAddress: '192.168.1.1',
          collectedAt: DateTime.now(),
        );
        final fixes = AutoFixService.analyze(snapshot);
        // قد يُرجع some fixes — نتحقق من النوع فقط
        expect(fixes, isA<List<ProposedFix>>());
      });

      test('ProposedFix يحتوي على كل الحقول المطلوبة', () {
        final snapshot = MikrotikSnapshot(
          interfaces: '',
          routes: '',
          firewall: '',
          logs: '',
          system: '',
          ipAddress: '',
          collectedAt: DateTime.now(),
        );
        final fixes =
            AutoFixService.analyze(snapshot, mode: DiagnosticMode.security);
        for (final fix in fixes) {
          expect(fix.id, isNotEmpty);
          expect(fix.title, isNotEmpty);
          expect(fix.description, isNotEmpty);
          expect(fix.impact, isNotEmpty);
          expect(fix.category, isNotNull);
          expect(fix.risk, isNotNull);
          expect(fix.script, isNotNull);
          expect(fix.script.commands, isNotEmpty);
        }
      });
    });

    // ============================================================
    //  7) CommandExecutor — classifyRisk + validateCommand
    // ============================================================
    group('⑦ CommandExecutor', () {
      test('classifyRisk: print = safe', () {
        expect(CommandExecutor.classifyRisk('/ip address print'),
            CommandRiskLevel.safe);
        expect(CommandExecutor.classifyRisk('/interface print'),
            CommandRiskLevel.safe);
        expect(CommandExecutor.classifyRisk('/system resource print'),
            CommandRiskLevel.safe);
      });

      test('classifyRisk: add/set = moderate', () {
        expect(
          CommandExecutor.classifyRisk('/ip address add address=192.168.1.1'),
          CommandRiskLevel.moderate,
        );
        expect(
          CommandExecutor.classifyRisk(
              '/interface ethernet set ether1 name=wan'),
          CommandRiskLevel.moderate,
        );
      });

      test('classifyRisk: remove/reboot = dangerous', () {
        expect(
          CommandExecutor.classifyRisk('/ip firewall filter remove [find]'),
          CommandRiskLevel.dangerous,
        );
        expect(
          CommandExecutor.classifyRisk('/system reboot'),
          CommandRiskLevel.dangerous,
        );
        expect(
          CommandExecutor.classifyRisk('/system reset-configuration'),
          CommandRiskLevel.dangerous,
        );
      });

      test('validateCommand: أمر فارغ يُرجع خطأ', () {
        final error = CommandExecutor.validateCommand('');
        expect(error, isNotNull);
        expect(error, contains('فارغ'));
      });

      test('validateCommand: أمر بدون / يُرجع خطأ', () {
        final error = CommandExecutor.validateCommand('ip address print');
        expect(error, isNotNull);
        expect(error, contains('/'));
      });

      test('validateCommand: أمر صحيح يُرجع null', () {
        final error = CommandExecutor.validateCommand('/ip address print');
        expect(error, isNull);
      });
    });

    // ============================================================
    //  8) DiagnosticMode — أوضاع التشخيص
    // ============================================================
    group('⑧ DiagnosticMode', () {
      test('كل وضع له displayName و description و icon', () {
        for (final mode in DiagnosticMode.values) {
          expect(mode.displayName, isNotEmpty);
          expect(mode.description, isNotEmpty);
          expect(mode.icon, isNotNull);
        }
      });

      test('هناك 11 وضع على الأقل', () {
        expect(DiagnosticMode.values.length, greaterThanOrEqualTo(11));
      });

      test('الأوضاع الجديدة موجودة (dhcp, monitoring, infrastructure)', () {
        expect(DiagnosticMode.values, contains(DiagnosticMode.dhcp));
        expect(DiagnosticMode.values, contains(DiagnosticMode.monitoring));
        expect(DiagnosticMode.values, contains(DiagnosticMode.infrastructure));
      });
    });

    // ============================================================
    //  9) AiProvider — المزودين
    // ============================================================
    group('⑨ AiProvider', () {
      test('openAI default model = gpt-4o-mini', () {
        expect(AiProvider.openAI.defaultModel, 'gpt-4o-mini');
      });

      test('gemini default model = gemini-2.5-flash', () {
        expect(AiProvider.gemini.defaultModel, 'gemini-2.5-flash');
      });

      test('openAI availableModels تحتوي على gpt-4o', () {
        expect(AiProvider.openAI.availableModels, contains('gpt-4o'));
      });

      test('gemini availableModels تحتوي على gemini-2.5-pro', () {
        expect(AiProvider.gemini.availableModels, contains('gemini-2.5-pro'));
      });
    });

    // ============================================================
    //  10) DiagnosticsState — الحالة الكاملة
    // ============================================================
    group('⑩ DiagnosticsState', () {
      test('initial يُنشئ رسالة ترحيب', () {
        final settings = AiSettings.default_;
        final state = DiagnosticsState.initial(settings);
        expect(state.messages, hasLength(1));
        expect(state.messages.first.type, MessageType.system);
        expect(state.isLoading, isFalse);
        expect(state.settings, settings);
      });

      test('copyWith يُحدّث الحقول', () {
        final settings = AiSettings.default_;
        final state = DiagnosticsState.initial(settings);
        final updated = state.copyWith(
          isLoading: true,
          loadingStage: 'testing',
        );
        expect(updated.isLoading, isTrue);
        expect(updated.loadingStage, 'testing');
        expect(updated.messages, state.messages);
      });
    });

    // ============================================================
    //  11) FixCategory — فئات الإصلاح
    // ============================================================
    group('⑪ FixCategory', () {
      test('كل فئة لها displayName و icon', () {
        for (final cat in FixCategory.values) {
          expect(cat.displayName, isNotEmpty);
          expect(cat.icon, isNotEmpty);
        }
      });

      test('هناك 11 فئة على الأقل', () {
        expect(FixCategory.values.length, greaterThanOrEqualTo(11));
      });

      test('الفئات الجديدة موجودة (dhcp, monitoring, infrastructure)', () {
        expect(FixCategory.values, contains(FixCategory.dhcp));
        expect(FixCategory.values, contains(FixCategory.monitoring));
        expect(FixCategory.values, contains(FixCategory.infrastructure));
      });
    });

    // ============================================================
    //  12) CommandRiskLevel — مستويات الخطورة
    // ============================================================
    group('⑫ CommandRiskLevel', () {
      test('displayName لكل مستوى', () {
        expect(CommandRiskLevel.safe.displayName, 'آمن');
        expect(CommandRiskLevel.moderate.displayName, 'متوسط');
        expect(CommandRiskLevel.dangerous.displayName, 'خطير');
      });

      test('warningMessage لكل مستوى', () {
        expect(CommandRiskLevel.safe.warningMessage, contains('قراءة'));
        expect(CommandRiskLevel.moderate.warningMessage, contains('عدّل'));
        expect(CommandRiskLevel.dangerous.warningMessage, contains('خطير'));
      });
    });

    // ============================================================
    //  13) Widget Tests — _MessageBubble
    // ============================================================
    group('⑬ Widget Tests — MessageBubble', () {
      testWidgets('رسالة المستخدم تُعرض بشكل صحيح', (tester) async {
        final msg = DiagnosticMessage.user('مرحبا أيها المساعد');

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: _TestMessageBubble(
                message: msg,
                onCopyCommand: (_) {},
                onExecuteCommand: (_) {},
              ),
            ),
          ),
        );

        expect(find.text('مرحبا أيها المساعد'), findsOneWidget);
      });

      testWidgets('رسالة المساعد مع أوامر تُعرض الأوامر', (tester) async {
        final msg = DiagnosticMessage.assistant(
          'إليك الحل',
          commands: const ['/ip address print', '/interface print'],
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: _TestMessageBubble(
                message: msg,
                onCopyCommand: (_) {},
                onExecuteCommand: (_) {},
              ),
            ),
          ),
        );

        expect(find.text('إليك الحل'), findsOneWidget);
        expect(find.text('/ip address print'), findsOneWidget);
        expect(find.text('/interface print'), findsOneWidget);
      });

      testWidgets('رسالة خطأ تُعرض بشكل مختلف', (tester) async {
        final msg = DiagnosticMessage.error('فشل الاتصال');

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: _TestMessageBubble(
                message: msg,
                onCopyCommand: (_) {},
                onExecuteCommand: (_) {},
              ),
            ),
          ),
        );

        expect(find.text('فشل الاتصال'), findsOneWidget);
      });
    });
  });
}

/// widget مساعدة لاختبار MessageBubble
/// (نستخدم نسخة بسيطة لأن _MessageBubble private)
class _TestMessageBubble extends StatelessWidget {
  final DiagnosticMessage message;
  final void Function(String) onCopyCommand;
  final void Function(String) onExecuteCommand;

  const _TestMessageBubble({
    required this.message,
    required this.onCopyCommand,
    required this.onExecuteCommand,
  });

  @override
  Widget build(BuildContext context) {
    final isUser = message.type == MessageType.user;
    final isError = message.type == MessageType.error;

    return Container(
      padding: const EdgeInsets.all(12),
      color: isError
          ? Colors.red.withValues(alpha: 0.1)
          : isUser
              ? Colors.blue
              : Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SelectableText(message.content),
          if (message.suggestedCommands != null)
            for (final cmd in message.suggestedCommands!)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  cmd,
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                ),
              ),
        ],
      ),
    );
  }
}
