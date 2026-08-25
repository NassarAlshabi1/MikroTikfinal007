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
  final String title; // عنوان السكربت
  final String description; // وصف مختصر
  final List<String> commands; // قائمة الأوامر
  final CommandRiskLevel overallRisk; // أعلى مستوى خطورة بين الأوامر
  final String? category; // تصنيف (security, qos, vpn, ...)

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
  String toString() =>
      'RouterOsScript($title, ${commands.length} cmds, risk=$overallRisk)';
}

/// نتيجة تنفيذ سكربت كامل
@immutable
class ScriptExecutionResult {
  final RouterOsScript script;
  final List<CommandResult> results; // نتائج كل أمر على حدة
  final bool overallSuccess; // نجاح كل الأوامر
  final Duration totalElapsed;
  final DateTime executedAt;
  final String summary; // ملخص قابل للعرض

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
  ///
  /// الاستراتيجية:
  /// 1. يبحث عن كتل الكود ```...``` التي تحتوي على أوامر RouterOS
  /// 2. إن لم يجد كتل كود، يبحث عن أسطر تبدأ بـ / مباشرة في النص
  /// 3. يربط كل سكربت بأقرب عنوان قبله (###, ##, **)
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
      final hasRouterOsCmd =
          RegExp(r'^\s*/\w+', multiLine: true).hasMatch(block);
      if (!hasRouterOsCmd) continue;

      // ابحث عن عنوان قبل الكتلة (آخر سطر غير فارغ قبلها)
      final beforeText = aiResponse.substring(0, match.start);
      final beforeLines = beforeText.split('\n').reversed;
      var title = 'سكربت ${i + 1}';
      var description = '';
      for (final line in beforeLines) {
        final trimmed = line.trim();
        if (trimmed.isEmpty) continue;
        // عناوين Markdown: ### Title أو ## Title
        if (trimmed.startsWith('###') || trimmed.startsWith('##')) {
          title = trimmed.replaceAll(RegExp(r'^#+\s*'), '');
          break;
        }
        // **Title**
        if (trimmed.startsWith('**') && trimmed.endsWith('**')) {
          title = trimmed.substring(2, trimmed.length - 2);
          break;
        }
        // 🎬 Title (icon pattern)
        if (trimmed.startsWith('🎬')) {
          title = trimmed.replaceAll(RegExp(r'^🎬\s*'), '');
          break;
        }
        // أول سطر نصي غير عنوان نعتبره وصف
        if (description.isEmpty && trimmed.length > 10) {
          description = trimmed;
        }
        if (trimmed.startsWith('###') ||
            trimmed.startsWith('##') ||
            trimmed.startsWith('**')) {
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

    // Fallback: إن لم نجد سكربتات في كتل كود، ابحث عن أسطر تبدأ بـ /
    // مباشرة في النص (للحالات التي لا يستخدم فيها الـ AI كتل كود)
    if (scripts.isEmpty) {
      final inlineCommands = <String>[];
      final lines = aiResponse.split('\n');
      for (final line in lines) {
        final trimmed = line.trim();
        // تجاهل الأسطر داخل كتل ``` (لأنها قد تكون نص توضيحي)
        // اقبل الأسطر التي تبدأ بـ / وتحتوي على أمر RouterOS
        if (trimmed.startsWith('/') &&
            !trimmed.startsWith('//') && // ليست تعليق
            RegExp(r'^/\w+').hasMatch(trimmed) &&
            // استبعد الأسطر التي تبدأ بـ /=== أو /--- (فواصل)
            !RegExp(r'^/[=\-]+$').hasMatch(trimmed)) {
          inlineCommands.add(trimmed);
        }
      }

      if (inlineCommands.isNotEmpty) {
        final script = RouterOsScript.fromText(
          title: 'سكربت AI',
          description:
              'سكربت مُولّد من رد الـ AI (${inlineCommands.length} أوامر)',
          text: inlineCommands.join('\n'),
          category: category,
        );
        if (script.commands.isNotEmpty) {
          scripts.add(script);
        }
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
    void Function(int currentIndex, int total, CommandResult result)?
        onProgress,
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

  // ============================================================
  //  هذا القسم يضيف طبقة أمان إنتاجية لتنفيذ الإصلاحات:
  //  1. dryRun: يُرجِع diff متوقّع دون تطبيق
  //  2. snapshot: ينشئ backup + export قبل أي تنفيذ
  //  3. rollback: يستعيد snapshot عند الفشل
  //  4. idempotency: يتحقق أن الأمر لم يُطبّق مسبقاً
  // ============================================================

  /// يُنشئ snapshot قبل تنفيذ أي تغييرات (backup + export)
  ///
  /// مثال:
  /// ```dart
  /// final snapshot = await ScriptExecutor.createSnapshot(
  ///   method: MikrotikConnectionMethod.ssh,
  ///   label: 'before-qos-fix',
  /// );
  /// // نفّذ الإصلاحات...
  /// // في حال الفشل:
  /// await ScriptExecutor.execute(
  ///   script: snapshot.toRollbackScript(),
  ///   method: MikrotikConnectionMethod.ssh,
  /// );
  /// ```
  static Future<ChangeSnapshot> createSnapshot({
    MikrotikConnectionMethod method = MikrotikConnectionMethod.routerOS,
    String? label,
    String? correlationId,
  }) async {
    final stamp =
        DateTime.now().toIso8601String().replaceAll(':', '-').split('.').first;
    final name = label != null ? '$label-$stamp' : 'snapshot-$stamp';

    final backupScript = RouterOsScript(
      title: 'إنشاء snapshot',
      description: 'backup كامل + export قبل التغييرات',
      overallRisk: CommandRiskLevel.safe,
      category: 'safety',
      commands: [
        '/system backup save name=$name',
        '/export file=$name-export',
      ],
    );

    final result = await execute(
      script: backupScript,
      method: method,
      stopOnError: true,
      perCommandTimeout: const Duration(seconds: 60),
    );

    if (!result.overallSuccess) {
      throw Exception(
          'فشل إنشاء snapshot: ${result.results.where((r) => !r.success).map((r) => r.error).join(", ")}');
    }

    debugPrint(
        '[ScriptExecutor] Snapshot created: $name (corrId=$correlationId)');
    return ChangeSnapshot(
      backupName: name,
      exportFileName: '$name-export',
      createdAt: DateTime.now(),
      correlationId: correlationId,
    );
  }

  /// ينفّذ سكربت بوضع dry-run — يحلل الأوامر ويعرض تأثيرها المتوقّع دون تطبيق
  ///
  /// يُرجِع تقرير مفصل يحتوي على:
  /// - تصنيف كل أمر (آمن/متوسط/خطير)
  /// - هل يحتاج snapshot؟ (نعم إذا كان متوسط/خطير)
  /// - هل هو idempotent؟ (يُحدد من شكل الأمر)
  /// - توصيات الأمان
  ///
  /// ملاحظة: الـ dry-run الحقيقي على مستوى RouterOS غير متاح في v6
  /// لذا هذه الدالة تعمل "تحليل قبل التنفيذ" (pre-execution analysis)
  static DryRunReport dryRun(RouterOsScript script) {
    final analysis = <DryRunCommandAnalysis>[];
    var needsSnapshot = false;
    var hasIdempotency = true;

    for (var i = 0; i < script.commands.length; i++) {
      final cmd = script.commands[i];
      final risk = CommandExecutor.classifyRisk(cmd);
      final idempotent = _isIdempotent(cmd);
      final validationError = CommandExecutor.validateCommand(cmd);
      final willModify = risk != CommandRiskLevel.safe;

      if (willModify) needsSnapshot = true;
      if (!idempotent) hasIdempotency = false;

      analysis.add(DryRunCommandAnalysis(
        index: i,
        command: cmd,
        risk: risk,
        isIdempotent: idempotent,
        willModify: willModify,
        validationError: validationError,
      ));
    }

    return DryRunReport(
      script: script,
      commandAnalysis: analysis,
      needsSnapshot: needsSnapshot,
      hasIdempotency: hasIdempotency,
    );
  }

  /// يتحقق إن كان أمر RouterOS idempotent (يعطي نفس النتيجة عند التكرار)
  ///
  /// - `print`, `monitor`, `find` — آمنة و idempotent (قراءة فقط)
  /// - `set [find ...]` — idempotent (يحدّث قائمة مطابقة)
  /// - `add` بدون `comment=` — غالباً NOT idempotent (ينشئ نسخة جديدة)
  /// - `add ... comment=...` — شبه idempotent (يمكن التحقق منه بالـ comment)
  /// - `remove [find ...]` — idempotent (يحذف كل المطابق)
  /// - `enable/disable [find ...]` — idempotent
  static bool _isIdempotent(String command) {
    final lc = command.toLowerCase();
    // أوامر القراءة آمنة
    if (lc.contains('print') || lc.contains('monitor') || lc.contains('find')) {
      return true;
    }
    // set/remove/enable/disable على [find ...] = idempotent
    if ((lc.contains('set [find') ||
        lc.contains('remove [find') ||
        lc.contains('enable [find') ||
        lc.contains('disable [find'))) {
      return true;
    }
    // add مع comment يعتبر semi-idempotent
    if (lc.contains('add') && lc.contains('comment=')) {
      return true;
    }
    // add بدون comment = NOT idempotent
    if (lc.contains('add')) {
      return false;
    }
    // افتراضي: نعتبره غير idempotent للحذر
    return false;
  }

  /// ينفّذ سكربت بأمان كامل — snapshot + execute + rollback عند الفشل
  ///
  /// 1. ينشئ snapshot قبل التنفيذ (إن احتاج الأمر)
  /// 2. ينفّذ الأوامر بالتسلسل مع stopOnError=true
  /// 3. عند أول فشل: يُنشئ rollback script من الـ snapshot
  /// 4. يُرجِع نتيجة شاملة تحتوي على snapshot + rollback script
  ///
  /// [requireSnapshot] — إن true (افتراضي للسكربتات المتوسطة/الخطيرة)
  ///                     ينشئ snapshot قبل التنفيذ إجبارياً
  static Future<SafeExecutionResult> executeWithSafety({
    required RouterOsScript script,
    MikrotikConnectionMethod method = MikrotikConnectionMethod.routerOS,
    bool requireSnapshot = true,
    String? correlationId,
    Duration perCommandTimeout = const Duration(seconds: 30),
    void Function(int currentIndex, int total, CommandResult result)?
        onProgress,
  }) async {
    // تحليل قبل التنفيذ
    final dryRunReport = dryRun(script);

    // إن كان السكربت آمناً بالكامل (قراءة فقط)، لا حاجة لـ snapshot
    final shouldSnapshot = requireSnapshot && dryRunReport.needsSnapshot;
    ChangeSnapshot? snapshot;
    if (shouldSnapshot) {
      try {
        snapshot = await createSnapshot(
          method: method,
          label: 'safety-${script.category ?? "auto"}',
          correlationId: correlationId,
        );
      } catch (e) {
        return SafeExecutionResult(
          script: script,
          snapshot: null,
          executionResult: null,
          rollbackScript: null,
          dryRunReport: dryRunReport,
          status: SafeExecutionStatus.snapshotFailed,
          errorMessage: 'فشل إنشاء snapshot: $e',
        );
      }
    }

    // تنفيذ السكربت
    final executionResult = await execute(
      script: script,
      method: method,
      stopOnError: true,
      perCommandTimeout: perCommandTimeout,
      onProgress: onProgress,
    );

    // في حال الفشل وأنشأنا snapshot، نُجهّز rollback script
    RouterOsScript? rollbackScript;
    if (!executionResult.overallSuccess && snapshot != null) {
      rollbackScript = snapshot.toRollbackScript();
    }

    return SafeExecutionResult(
      script: script,
      snapshot: snapshot,
      executionResult: executionResult,
      rollbackScript: rollbackScript,
      dryRunReport: dryRunReport,
      status: executionResult.overallSuccess
          ? SafeExecutionStatus.success
          : (snapshot != null
              ? SafeExecutionStatus.failedWithRollbackReady
              : SafeExecutionStatus.failedNoSnapshot),
      errorMessage: executionResult.overallSuccess
          ? null
          : 'فشل ${executionResult.failureCount} من ${script.commands.length} أوامر',
    );
  }
}

// ============================================================
//  نماذج Change Safety Layer
// ============================================================

/// يمثل snapshot قبل التغيير — يحوي backup + export
@immutable
class ChangeSnapshot {
  final String backupName; // اسم ملف الـ backup
  final String exportFileName; // اسم ملف الـ export
  final DateTime createdAt; // وقت الإنشاء
  final String? correlationId; // معرّف لتتبع العملية

  const ChangeSnapshot({
    required this.backupName,
    required this.exportFileName,
    required this.createdAt,
    this.correlationId,
  });

  /// سكربت الاستعادة من هذا snapshot
  RouterOsScript toRollbackScript() => RouterOsScript(
        title: 'استعادة snapshot $backupName',
        description: 'يستعيد الإعدادات من الـ snapshot المُنشأ في $createdAt',
        overallRisk: CommandRiskLevel.dangerous,
        category: 'safety',
        commands: [
          '/system backup load name=$backupName',
        ],
      );
}

/// نتيجة تحليل أمر واحد في dry-run
@immutable
class DryRunCommandAnalysis {
  final int index;
  final String command;
  final CommandRiskLevel risk;
  final bool isIdempotent;
  final bool willModify;
  final String? validationError;

  const DryRunCommandAnalysis({
    required this.index,
    required this.command,
    required this.risk,
    required this.isIdempotent,
    required this.willModify,
    this.validationError,
  });

  /// هل الأمر جاهز للتنفيذ (لا أخطاء تحقق)
  bool get isExecutable => validationError == null;
}

/// تقرير dry-run شامل لسكربت كامل
@immutable
class DryRunReport {
  final RouterOsScript script;
  final List<DryRunCommandAnalysis> commandAnalysis;
  final bool needsSnapshot; // هل يحتاج snapshot قبل التنفيذ؟
  final bool hasIdempotency; // هل كل الأوامر idempotent؟

  const DryRunReport({
    required this.script,
    required this.commandAnalysis,
    required this.needsSnapshot,
    required this.hasIdempotency,
  });

  /// عدد الأوامر القابلة للتنفيذ (بدون أخطاء تحقق)
  int get executableCount =>
      commandAnalysis.where((c) => c.isExecutable).length;

  /// عدد الأوامر الخطرة
  int get dangerousCount =>
      commandAnalysis.where((c) => c.risk == CommandRiskLevel.dangerous).length;

  /// عدد الأوامر غير idempotent
  int get nonIdempotentCount =>
      commandAnalysis.where((c) => !c.isIdempotent).length;

  /// نص التقرير للعرض
  String get displayReport {
    final buffer = StringBuffer()
      ..writeln('═══════════════════════════════════════')
      ..writeln('🔍 تقرير Dry-Run: ${script.title}')
      ..writeln('═══════════════════════════════════════')
      ..writeln('📦 عدد الأوامر: ${script.commands.length}')
      ..writeln('✅ قابلة للتنفيذ: $executableCount')
      ..writeln('🚨 خطرة: $dangerousCount')
      ..writeln('🔁 غير idempotent: $nonIdempotentCount')
      ..writeln('💾 يحتاج snapshot: ${needsSnapshot ? "نعم" : "لا"}')
      ..writeln('───────────────────────────────────────');

    for (final c in commandAnalysis) {
      final riskIcon = c.risk == CommandRiskLevel.dangerous
          ? '🚨'
          : c.risk == CommandRiskLevel.moderate
              ? '⚠️'
              : '✅';
      final idemIcon = c.isIdempotent ? '🔁' : '⚠️';
      buffer.writeln('${c.index + 1}. $riskIcon $idemIcon ${c.command}');
      if (c.validationError != null) {
        buffer.writeln('   ❌ خطأ: ${c.validationError}');
      }
    }

    buffer.writeln('═══════════════════════════════════════');
    if (!needsSnapshot) {
      buffer.writeln('✅ السكربت آمن — أوامر قراءة فقط، لا يحتاج snapshot.');
    } else if (hasIdempotency) {
      buffer.writeln('✅ السكربت قابل للتكرار بأمان (idempotent).');
      buffer.writeln('💾 سيُنشئ snapshot تلقائياً قبل التنفيذ.');
    } else {
      buffer.writeln('⚠️ يحتوي على أوامر غير idempotent — راجع بعناية.');
      buffer.writeln('💾 سيُنشئ snapshot تلقائياً قبل التنفيذ.');
    }
    buffer.writeln('═══════════════════════════════════════');

    return buffer.toString();
  }
}

/// حالة تنفيذ آمن
enum SafeExecutionStatus {
  success, // نجح كل الأوامر
  failedWithRollbackReady, // فشل ولكن snapshot جاهز للاستعادة
  failedNoSnapshot, // فشل ولا snapshot متاح
  snapshotFailed, // فشل إنشاء snapshot قبل التنفيذ
}

extension SafeExecutionStatusX on SafeExecutionStatus {
  String get displayName {
    switch (this) {
      case SafeExecutionStatus.success:
        return 'نجاح';
      case SafeExecutionStatus.failedWithRollbackReady:
        return 'فشل (snapshot جاهز)';
      case SafeExecutionStatus.failedNoSnapshot:
        return 'فشل (بدون snapshot)';
      case SafeExecutionStatus.snapshotFailed:
        return 'فشل إنشاء snapshot';
    }
  }

  bool get isRecoverable => this == SafeExecutionStatus.failedWithRollbackReady;
}

/// نتيجة تنفيذ آمن — تحتوي على snapshot + execution + rollback
@immutable
class SafeExecutionResult {
  final RouterOsScript script;
  final ChangeSnapshot? snapshot;
  final ScriptExecutionResult? executionResult;
  final RouterOsScript? rollbackScript;
  final DryRunReport dryRunReport;
  final SafeExecutionStatus status;
  final String? errorMessage;

  const SafeExecutionResult({
    required this.script,
    required this.snapshot,
    required this.executionResult,
    required this.rollbackScript,
    required this.dryRunReport,
    required this.status,
    this.errorMessage,
  });

  /// هل نجح التنفيذ بالكامل
  bool get isSuccess => status == SafeExecutionStatus.success;

  /// هل يمكن استعادة الحالة (rollback متاح)
  bool get canRollback => rollbackScript != null;
}
