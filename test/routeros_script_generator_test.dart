import 'package:flutter_test/flutter_test.dart';
import 'package:mikrotik_manager/services/routeros_script_generator.dart';

void main() {
  const template = '''
# ---------- الإعدادات ----------
:global TG_BOT_TOKEN "REPLACE_WITH_NEW_BOT_TOKEN"
:global TG_ALLOWED_CHAT_ID "5944227208"
:global TG_ALLOWED_USER_ID "5944227208"
:global TG_UM_CUSTOMER "admin"
:global TG_UM_PROFILE "default"
:global TG_DEF_LIMIT "1w"

:global tgBotLib1 do={
    # إعادة زرع الإعدادات إذا فُقدت بعد إعادة تشغيل الراوتر
    :global TG_BOT_TOKEN
    :if ([:typeof \$TG_BOT_TOKEN] != "str") do={ :set TG_BOT_TOKEN "REPLACE_WITH_NEW_BOT_TOKEN" }
    :global TG_ALLOWED_CHAT_ID
    :if ([:typeof \$TG_ALLOWED_CHAT_ID] != "str") do={ :set TG_ALLOWED_CHAT_ID "5944227208" }
}

/system scheduler add name="tg-poll-job" start-time=startup interval=10s policy=read,write,test,policy on-event="/system script run tg-lib1; /system script run tg-lib2; /system script run tg-poll"
''';

  group('RouterOsScriptGenerator.buildScript', () {
    test('replaces token in initial config and re-seed block', () {
      final script = RouterOsScriptGenerator.buildScript(
        template,
        botToken: '123456:ABC-DEF',
        allowedChatId: '111',
        allowedUserId: '222',
        umCustomer: 'reseller1',
        umProfile: '1m',
        defaultLimit: '30d',
        pollSeconds: 15,
      );

      expect(script.contains('REPLACE_WITH_NEW_BOT_TOKEN'), isFalse,
          reason: 'يجب ألا يبقى أي placeholder للتوكن');
      expect(':global TG_BOT_TOKEN "123456:ABC-DEF"'.allMatches(script).length,
          1);
      expect(
          script.contains(':set TG_BOT_TOKEN "123456:ABC-DEF"'), isTrue,
          reason: 'إعادة الزرع بعد إعادة التشغيل يجب أن تستخدم التوكن نفسه');
    });

    test('replaces chat id, user id, customer, profile and limit', () {
      final script = RouterOsScriptGenerator.buildScript(
        template,
        botToken: '123456:ABC-DEF',
        allowedChatId: '111',
        allowedUserId: '222',
        umCustomer: 'reseller1',
        umProfile: '1m',
        defaultLimit: '30d',
        pollSeconds: 15,
      );

      expect(script.contains('TG_ALLOWED_CHAT_ID "111"'), isTrue);
      expect(script.contains(':set TG_ALLOWED_CHAT_ID "111"'), isTrue);
      expect(script.contains('TG_ALLOWED_USER_ID "222"'), isTrue);
      expect(script.contains('TG_UM_CUSTOMER "reseller1"'), isTrue);
      expect(script.contains('TG_UM_PROFILE "1m"'), isTrue);
      expect(script.contains('TG_DEF_LIMIT "30d"'), isTrue);
      // القيم القديمة يجب ألا تبقى في التعريفات
      expect(script.contains('TG_ALLOWED_CHAT_ID "5944227208"'), isFalse);
    });

    test('updates scheduler interval and clamps it', () {
      final script = RouterOsScriptGenerator.buildScript(
        template,
        botToken: 't',
        allowedChatId: '1',
        allowedUserId: '1',
        umCustomer: 'c',
        umProfile: 'p',
        defaultLimit: '1w',
        pollSeconds: 15,
      );
      expect(script.contains('interval=15s'), isTrue);
      expect(script.contains('interval=10s'), isFalse);

      // قيمة أقل من الحد الأدنى تُثبّت على 5
      final clamped = RouterOsScriptGenerator.buildScript(
        template,
        botToken: 't',
        allowedChatId: '1',
        allowedUserId: '1',
        umCustomer: 'c',
        umProfile: 'p',
        defaultLimit: '1w',
        pollSeconds: 1,
      );
      expect(clamped.contains('interval=5s'), isTrue);
    });

    test('keeps unrelated script logic intact', () {
      final script = RouterOsScriptGenerator.buildScript(
        template,
        botToken: 't',
        allowedChatId: '1',
        allowedUserId: '1',
        umCustomer: 'c',
        umProfile: 'p',
        defaultLimit: '1w',
      );

      expect(script.contains('tg-poll-job'), isTrue);
      expect(script.contains('tgBotLib1'), isTrue);
      expect(script.contains('إعادة زرع الإعدادات'), isTrue,
          reason: 'التعليقات العربية داخل السكربت يجب أن تبقى كما هي');
    });
  });
}
