// ============================================================
//  Script Executor — ينفّذ سكربتات RouterOS متعددة الأوامر
//
//  المميزات:
//  - تحليل السكربت (parsing) لأسطر متعددة
//  - تنفيذ تسلسلي مع تتبع حالة كل أمر
//  - إيقاف عند الخطأ (اختياري)
//  - تصنيف خطورة السكربت ككل (آمن/متوسط/خطير)
//  - دعم التعليقات (#) والأسطر الفارغة
//  - دعم كتل :do / :while / :for (تنفيذها كـ script واحد)
//  - وضع المعاينة (preview-only) لعرض ما سينفذ دون تطبيقه
// ============================================================

import 'package:flutter/foundation.dart';

import 'command_executor.dart';
import 'diagnostics_models.dart';

/// يمثل سكربت RouterOS — مجموعة أوامر مع metadata
@immutable
class RouterOsScript {
  final String title;            // عنوان السكربت
  final String description;      // وصف مختصر
  final List<String> commands;   // قائمة الأوامر
  final CommandRiskLevel overallRisk; // أعلى مستوى خطورة بين الأوامر
  final String? category;        // تصنيف (security, qos, vpn, ...)

  const RouterOsScript({
    required this.title,
    required this.description,
    required this.commands,
    required this.overallRisk,
    this.category,
  });

  /// يبني سكربت من نص كامل (مثلاً من كود ```...``` يُرجعه الـ AI)
  /// يتجاهل التعليقات والأسطر الفارغة
  factory RouterOsScript.fromText({
    required String title,
    required String description,
    required String text,
    String? category,
  }) {
    final lines = text.split('\n');
    final commands = <String>[];
    final buffer = StringBuffer();
    var inMultiline = false;

    for (final rawLine in lines) {
      final line = rawLine.trim();

      // تجاهل التعليقات والأسطر الفارغة
      if (line.isEmpty || line.startsWith('#') || line.startsWith('//')) {
        continue;
      }

      // اكتشاف بداية كتل multiline (:do, :while, :for, :if)
      if (line.startsWith(':do') ||
          line.startsWith(':while') ||
          line.startsWith(':for') ||
          line.startsWith(':if')) {
        inMultiline = true;
        buffer.writeln(line);
        continue;
      }

      // إذا كنا داخل كتلة multiline، نواصل التجميع حتى نهاية الكتلة (})
      if (inMultiline) {
        buffer.writeln(line);
        if (line.contains('}')) {
          commands.add(buffer.toString().trim());
          buffer.clear();
          inMultiline = false;
        }
        continue;
      }

      // أمر عادي على سطر واحد
      // أضف '/' في البداية إن لم يكن موجوداً (معاملة CLI)
      final normalized = line.startsWith('/') ? line : '/$line';
      commands.add(normalized);
    }

    // في حال تبقى شيء في buffer
    if (buffer.isNotEmpty) {
      commands.add(buffer.toString().trim());
    }

    // حساب مستوى الخطورة العام = الأعلى بين الأوامر
    var overallRisk = CommandRiskLevel.safe;
    for (final cmd in commands) {
      final risk = CommandExecutor.classifyRisk(cmd);
      if (risk == CommandRiskLevel.dangerous) {
        overallRisk = CommandRiskLevel.dangerous;
        break;
      } else if (risk == CommandRiskLevel.moderate) {
        overallRisk = CommandRiskLevel.moderate;
      }
    }

    return RouterOsScript(
      title: title,
      description: description,
      commands: commands,
      overallRisk: overallRisk,
      category: category,
    );
  }

  /// عدد الأوامر
  int get length => commands.length;

  /// هل يحتوي على أوامر خطرة
  bool get isDangerous => overallRisk == CommandRiskLevel.dangerous;

  /// هل يحتوي على أوامر متوسطة الخطورة
  bool get hasModerate =>
      overallRisk == CommandRiskLevel.moderate ||
      overallRisk == CommandRiskLevel.dangerous;

  @override
  String toString() => 'RouterOsScript($title, ${commands.length} cmds, risk=$overallRisk)';
}

/// نتيجة تنفيذ سكربت كامل
@immutable
class ScriptExecutionResult {
  final RouterOsScript script;
  final List<CommandResult> results; // نتائج كل أمر على حدة
  final bool overallSuccess;  // نجاح كل الأوامر
  final Duration totalElapsed;
  final DateTime executedAt;
  final String summary;       // ملخص قابل للعرض

  const ScriptExecutionResult({
    required this.script,
    required this.results,
    required this.overallSuccess,
    required this.totalElapsed,
    required this.executedAt,
    required this.summary,
  });

  /// عدد الأوامر الناجحة
  int get successCount => results.where((r) => r.success).length;

  /// عدد الأوامر الفاشلة
  int get failureCount => results.where((r) => !r.success).length;
}

class ScriptExecutor {
  ScriptExecutor._();

  /// يحلل نص الـ AI ويستخرج السكربتات منه
  /// يبحث عن كتل الكود ```...``` ويعتبر كل واحدة سكربت منفصل
  static List<RouterOsScript> extractScriptsFromAiResponse({
    required String aiResponse,
    String? category,
  }) {
    final scripts = <RouterOsScript>[];

    // Pattern: كتل كود ```...``` مع عنوان اختياري
    final codeBlockPattern = RegExp(r'```(?:\w+)?\n?([\s\S]*?)```');
    final matches = codeBlockPattern.allMatches(aiResponse).toList();

    // نبحث عن عنوان السكربت قبله (سطر يبدأ بـ # أو **)
    for (var i = 0; i < matches.length; i++) {
      final match = matches[i];
      final block = match.group(1) ?? '';

      // تجاهل الكتل التي لا تحتوي على أوامر RouterOS (لا يوجد / بداية سطر)
      final hasRouterOsCmd = RegExp(r'^\s*/\w+', multiLine: true).hasMatch(block);
      if (!hasRouterOsCmd) continue;

      // ابحث عن عنوان قبل الكتلة (آخر سطر غير فارغ قبلها)
      final beforeText = aiResponse.substring(0, match.start);
      final beforeLines = beforeText.split('\n').reversed;
      var title = 'سكربت ${i + 1}';
      var description = '';
      for (final line in beforeLines) {
        final trimmed = line.trim();
        if (trimmed.isEmpty) continue;
        // عناوين Markdown: ### Title أو **Title**
        if (trimmed.startsWith('###') || trimmed.startsWith('##')) {
          title = trimmed.replaceAll(RegExp(r'^#+\s*'), '');
          break;
        }
        if (trimmed.startsWith('**') && trimmed.endsWith('**')) {
          title = trimmed.substring(2, trimmed.length - 2);
          break;
        }
        // أول سطر نصي غير عنوان نعتبره وصف
        if (description.isEmpty && trimmed.length > 10) {
          description = trimmed;
        }
        if (trimmed.startsWith('###') || trimmed.startsWith('##') || trimmed.startsWith('**')) {
          break;
        }
      }

      final script = RouterOsScript.fromText(
        title: title,
        description: description.isEmpty ? title : description,
        text: block,
        category: category,
      );

      if (script.commands.isNotEmpty) {
        scripts.add(script);
      }
    }

    return scripts;
  }

  /// ينفذ سكربت كامل (سلسلة من الأوامر)
  ///
  /// [onProgress] يُستدعى بعد كل أمر لتحديث الـ UI
  /// [stopOnError] إن true، يتوقف عند أول أمر فاشل
  static Future<ScriptExecutionResult> execute({
    required RouterOsScript script,
    MikrotikConnectionMethod method = MikrotikConnectionMethod.routerOS,
    bool stopOnError = false,
    Duration perCommandTimeout = const Duration(seconds: 30),
    void Function(int currentIndex, int total, CommandResult result)? onProgress,
  }) async {
    final stopwatch = Stopwatch()..start();
    final results = <CommandResult>[];

    debugPrint('[ScriptExecutor] Executing "${script.title}" '
        '(${script.commands.length} commands, risk=${script.overallRisk})');

    for (var i = 0; i < script.commands.length; i++) {
      final command = script.commands[i];
      debugPrint('[ScriptExecutor] [$i+1/${script.commands.length}] $command');

      final result = await CommandExecutor.execute(
        command: command,
        method: method,
        timeout: perCommandTimeout,
      );
      results.add(result);

      // إشعار التقدم
      onProgress?.call(i, script.commands.length, result);

      // إيقاف عند الخطأ إن طُلب
      if (stopOnError && !result.success) {
        debugPrint('[ScriptExecutor] Stopped at command ${i + 1} due to error');
        break;
      }
    }

    stopwatch.stop();
    final successCount = results.where((r) => r.success).length;
    final failureCount = results.length - successCount;
    final overallSuccess = failureCount == 0;

    // بناء ملخص
    final summary = StringBuffer()
      ..writeln('سكربت: ${script.title}')
      ..writeln('الأوامر: ${script.commands.length}')
      ..writeln('✅ ناجحة: $successCount')
      ..writeln('❌ فاشلة: $failureCount')
      ..writeln('الزمن الكلي: ${stopwatch.elapsed.inMilliseconds}ms');

    if (failureCount > 0) {
      summary.writeln('\nالأوامر الفاشلة:');
      for (final r in results.where((r) => !r.success)) {
        summary.writeln('  • ${r.command}');
        summary.writeln('    └─ ${r.error ?? "خطأ غير معروف"}');
      }
    }

    return ScriptExecutionResult(
      script: script,
      results: results,
      overallSuccess: overallSuccess,
      totalElapsed: stopwatch.elapsed,
      executedAt: DateTime.now(),
      summary: summary.toString(),
    );
  }

  /// يحلل سكربت ويعرضه بدون تنفيذ (preview)
  /// يُرجع تقرير مفصّل عن الأوامر ومستويات خطورتها
  static String previewScript(RouterOsScript script) {
    final buffer = StringBuffer()
      ..writeln('═══════════════════════════════════════')
      ..writeln('🎬 معاينة السكربت: ${script.title}')
      ..writeln('═══════════════════════════════════════')
      ..writeln('📝 الوصف: ${script.description}')
      ..writeln('📦 عدد الأوامر: ${script.commands.length}')
      ..writeln('⚠️ مستوى الخطورة: ${script.overallRisk.displayName}')
      ..writeln('📁 التصنيف: ${script.category ?? "غير محدد"}')
      ..writeln('───────────────────────────────────────');

    for (var i = 0; i < script.commands.length; i++) {
      final cmd = script.commands[i];
      final risk = CommandExecutor.classifyRisk(cmd);
      final riskIcon = risk == CommandRiskLevel.dangerous
          ? '🚨'
          : risk == CommandRiskLevel.moderate
              ? '⚠️'
              : '✅';
      buffer.writeln('${i + 1}. $riskIcon [$risk.displayName] $cmd');
    }

    buffer.writeln('═══════════════════════════════════════');
    if (script.isDangerous) {
      buffer.writeln('🚨 تحذير: هذا السكربت يحتوي على أوامر خطرة!');
      buffer.writeln('   تأكد من عمل backup قبل التنفيذ:');
      buffer.writeln('   /system backup save name=before-ai-fix');
    } else if (script.hasModerate) {
      buffer.writeln('⚠️ هذا السكربت يعدّل الإعدادات. راجع الأوامر بعناية.');
    } else {
      buffer.writeln('✅ السكربت آمن — أوامر قراءة فقط.');
    }
    buffer.writeln('═══════════════════════════════════════');

    return buffer.toString();
  }

  /// ينشئ سكربت backup قبل تطبيق أي إصلاحات
  static RouterOsScript createBackupScript({String? label}) {
    final stamp = DateTime.now().toIso8601String().split('T')[0];
    final name = label ?? 'before-ai-fix-$stamp';
    return RouterOsScript(
      title: 'نسخة احتياطية قبل الإصلاح',
      description: 'يحفظ backup كامل + export للإعدادات الحالية',
      overallRisk: CommandRiskLevel.safe,
      category: 'safety',
      commands: [
        '/system backup save name=$name',
        '/export file=$name-export',
        '/system history print',
      ],
    );
  }

  /// ينشئ سكربت استعادة بعد فشل الإصلاح
  static RouterOsScript createRollbackScript(String backupName) {
    return RouterOsScript(
      title: 'استعادة من نسخة احتياطية',
      description: 'يستعيد الإعدادات من backup محدد — قد يقطع الاتصال',
      overallRisk: CommandRiskLevel.dangerous,
      category: 'safety',
      commands: [
        '/system backup load name=$backupName',
      ],
    );
  }
}
