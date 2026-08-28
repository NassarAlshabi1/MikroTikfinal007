import 'dart:io';

import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';

/// مولّد سكربت RouterOS v6 جاهز للتطبيق.
///
/// يأخذ القالب الآمن من [templateAsset] (بدون أي أسرار حقيقية) ويستبدل فيه
/// قيم الإعدادات المدخلة من شاشة Telegram Bot، ثم ينتج ملفاً جاهزاً للنسخ
/// إلى الراوتر عبر Share. بهذا لا يحتاج المستخدم إلى تحرير قيم REPLACE_*
/// يدوياً في محرر نصوص.
class RouterOsScriptGenerator {
  /// مسار القالب الآمن داخل أصول التطبيق.
  static const templateAsset = 'assets/routeros/telegram-um-final-v6.rsc';

  const RouterOsScriptGenerator();

  /// يقرأ القالب الآمن من أصول التطبيق.
  Future<String> loadTemplate() => rootBundle.loadString(templateAsset);

  /// يبني نص السكربت النهائي من القالب والإعدادات الممررة.
  ///
  /// يُستبدل كل ظهور لقيمة كل متغير (التعريف الأولي + إعادة الزرع داخل
  /// tgBotLib1 بعد إعادة التشغيل). لاحظ أن سكربت v6 يقارن Chat ID وUser ID
  /// بمقارنة نصية مباشرة، لذا يُستخدم أول معرف فقط من القوائم المفصولة بفواصل.
  static String buildScript(
    String template, {
    required String botToken,
    required String allowedChatId,
    required String allowedUserId,
    required String umCustomer,
    required String umProfile,
    required String defaultLimit,
    int pollSeconds = 10,
  }) {
    var script = template;
    void replaceGlobal(String name, String value) {
      final pattern = RegExp('($name\\s+")[^"]*(")');
      script = script.replaceAllMapped(
          pattern, (m) => '${m.group(1)}$value${m.group(2)}');
    }

    replaceGlobal('TG_BOT_TOKEN', botToken.trim());
    replaceGlobal('TG_ALLOWED_CHAT_ID', allowedChatId.trim());
    replaceGlobal('TG_ALLOWED_USER_ID', allowedUserId.trim());
    replaceGlobal('TG_UM_CUSTOMER', umCustomer.trim());
    replaceGlobal('TG_UM_PROFILE', umProfile.trim());
    replaceGlobal('TG_DEF_LIMIT', defaultLimit.trim());

    // فترة استطلاع أوامر Telegram في مجدول الراوتر.
    final scheduler = RegExp(r'(name="tg-poll-job"[^\n]*interval=)(\d+)s');
    script = script.replaceAllMapped(
        scheduler, (m) => '${m.group(1)}${pollSeconds.clamp(5, 600)}s');

    return script;
  }

  /// يبني السكربت من القالب المخزن في الأصول.
  Future<String> generate({
    required String botToken,
    required String allowedChatId,
    required String allowedUserId,
    required String umCustomer,
    required String umProfile,
    required String defaultLimit,
    int pollSeconds = 10,
  }) async {
    final template = await loadTemplate();
    return buildScript(
      template,
      botToken: botToken,
      allowedChatId: allowedChatId,
      allowedUserId: allowedUserId,
      umCustomer: umCustomer,
      umProfile: umProfile,
      defaultLimit: defaultLimit,
      pollSeconds: pollSeconds,
    );
  }

  /// يكتب السكربت في مجلد مؤقت ويعيد الملف لمشاركته عبر Share.
  Future<File> writeScript(String content,
      {String fileName = 'mikrotik-telegram-um-v6.rsc'}) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}${Platform.pathSeparator}$fileName');
    return file.writeAsString(content, flush: true);
  }
}
