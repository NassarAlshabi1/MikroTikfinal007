// ============================================================
//  Agentic Service — حلقة التشخيص الوكيلة (Agentic Loop)
//
//  الفكرة:
//   1) الـ AI يطلب أوامر قراءة آمنة لجمع معلومات دقيقة
//   2) التطبيق ينفّذها تلقائياً (قراءة فقط) ويُعيد المخرجات
//   3) يكرّر حتى يصل للسبب الجذري
//   4) يقدّم تقريراً نهائياً + إصلاحاً مقترحاً يُنفَّذ بموافقة المستخدم
//
//  حاجز الأمان: لا يُنفَّذ تلقائياً إلا ما يجتاز فحص "قراءة فقط".
//  أوامر التعديل (set/add/remove/reset...) لا تُنفَّذ إطلاقاً هنا.
// ============================================================

import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'ai_service.dart';
import 'command_executor.dart';
import 'diagnostics_models.dart';
import 'system_prompts.dart';

class AgenticService {
  AgenticService._();

  // ============================================================
  //  حاجز الأمان: تصنيف الأوامر "قراءة فقط"
  // ============================================================

  /// أفعال تعديل ممنوعة من التنفيذ التلقائي (defense in depth)
  static const List<String> _mutatingTokens = [
    'set ',
    'add ',
    'remove',
    'unset',
    'reset',
    'reboot',
    'shutdown',
    'disable',
    'enable',
    'move ',
    'edit',
    'import',
    'upgrade',
    'downgrade',
    'delete',
    'password',
    'scheduler',
    '/tool fetch',
    'deauthenticate',
    'make-backup',
    'run ',
    'clear ',
    'comment',
    'sniffer save',
    'gen-key',
    'create',
    'restore',
    'reset-configuration',
    'blink',
  ];

  /// أفعال قراءة مسموح بها للتنفيذ التلقائي
  static const List<String> _readVerbs = [
    'print',
    'export',
    'get',
    'monitor',
    'find',
  ];

  /// هل الأمر آمن للتنفيذ التلقائي (قراءة فقط)؟
  ///
  /// يجمع بين تصنيف [CommandExecutor.classifyRisk] وفحص صريح لأفعال التعديل،
  /// ويشترط وجود فعل قراءة فعلي — أي شك ⇒ يُعتبر غير آمن.
  static bool isReadOnly(String command) {
    final cmd = command.trim();
    if (cmd.isEmpty || !cmd.startsWith('/')) return false;

    final lower = cmd.toLowerCase();

    // 1) لا يحتوي أي فعل تعديل
    for (final token in _mutatingTokens) {
      if (lower.contains(token)) return false;
    }

    // 2) يجب أن يحتوي فعل قراءة صريح
    final hasReadVerb = _readVerbs.any((v) => lower.contains(v));
    if (!hasReadVerb) return false;

    // 3) طبقة أخيرة: يجب أن يصنّفه المنفّذ كـ safe
    return CommandExecutor.classifyRisk(cmd) == CommandRiskLevel.safe;
  }

  // ============================================================
  //  خطوة قرار واحدة في الحلقة
  // ============================================================

  /// يطلب من الـ AI قراره التالي بناءً على البيانات + سجل الاستقصاء حتى الآن.
  ///
  /// [investigationLog] — نتائج أوامر القراءة المنفّذة في الخطوات السابقة.
  /// [forceFinal] — يُجبر الـ AI على تقديم التقرير النهائي (عند بلوغ حد الخطوات).
  static Future<AgentDecision> decideNextStep({
    required AiSettings settings,
    required String userQuery,
    required String snapshotContext,
    required List<CommandResult> investigationLog,
    List<DiagnosticMessage> conversationHistory = const [],
    bool forceFinal = false,
  }) async {
    final systemPrompt = _buildAgenticSystemPrompt(settings.mode);

    final messages = <Map<String, String>>[
      // محادثة سابقة (نص فقط) للحفاظ على السياق
      for (final msg in conversationHistory.takeLast(6))
        if (msg.type == MessageType.user || msg.type == MessageType.assistant)
          {
            'role': msg.type == MessageType.user ? 'user' : 'assistant',
            'content': msg.content,
          },
      {
        'role': 'user',
        'content': _buildTurnContent(
          userQuery: userQuery,
          snapshotContext: snapshotContext,
          investigationLog: investigationLog,
          forceFinal: forceFinal,
        ),
      },
    ];

    final raw = await AiService.chat(
      settings: settings,
      systemPrompt: systemPrompt,
      messages: messages,
      temperature: 0.3,
    );

    return _parseDecision(raw, forceFinal: forceFinal);
  }

  // ============================================================
  //  بناء البرومبت
  // ============================================================

  static String _buildAgenticSystemPrompt(DiagnosticMode mode) {
    final base = promptForMode(mode);
    return '''$base

# 🔁 وضع التشخيص الوكيل (Agentic)
أنت الآن تعمل بأسلوب "الاستقصاء خطوة بخطوة". بدل إجابة واحدة، يمكنك طلب
أوامر **قراءة فقط** لتنفيذها تلقائياً ورؤية مخرجاتها الحقيقية قبل إصدار حكمك.

## بروتوكول الرد (إلزامي)
- ردّك يجب أن يكون **كائن JSON واحد فقط** — بدون أي نص خارج الـ JSON، وبدون علامات ```.
- استخدم أحد شكلين:

1) لطلب مزيد من المعلومات (استقصاء):
{
  "action": "investigate",
  "thought": "سبب حاجتك لهذه الأوامر (جملة عربية قصيرة)",
  "commands": ["/interface print detail", "/ip address print"]
}

2) عند وصولك للسبب الجذري (التقرير النهائي):
{
  "action": "final",
  "thought": "خلاصة موجزة",
  "report": "تقرير Markdown كامل بالعربية: المشاكل + السبب الجذري + الحل + التحقق + الوقاية",
  "fix_commands": ["/ip firewall filter add ...", "..."]
}

## قواعد صارمة
- في "commands" ضع **أوامر قراءة فقط** (print/get/export/monitor/find). ممنوع منعاً باتاً
  أوامر التعديل (set/add/remove/reset/reboot/enable/disable...) داخل "commands"؛
  ستُرفض ولن تُنفَّذ.
- أوامر الإصلاح الفعلية ضعها **فقط** في "fix_commands" ضمن الرد النهائي — وهي لا تُنفَّذ
  إلا بموافقة المستخدم اليدوية.
- اطلب في كل خطوة أقل عدد ممكن من الأوامر المفيدة (1 إلى 4).
- لا تكرّر طلب أمر نفّذته من قبل (النتائج متوفرة في سجل الاستقصاء).
- إذا كفت البيانات، انتقل مباشرةً إلى "final". لا تُطل الاستقصاء بلا فائدة.
- استخدم **أوامر RouterOS v6 فقط**.
- أعِد JSON صالحاً بنحوٍ يمكن تحليله برمجياً (بدون فواصل زائدة).''';
  }

  static String _buildTurnContent({
    required String userQuery,
    required String snapshotContext,
    required List<CommandResult> investigationLog,
    required bool forceFinal,
  }) {
    final buffer = StringBuffer();
    buffer.writeln('سؤال/مشكلة المستخدم: $userQuery');
    buffer.writeln();
    buffer.writeln('=== لقطة أولية من جهاز MikroTik ===');
    buffer.writeln(snapshotContext);
    buffer.writeln();

    if (investigationLog.isEmpty) {
      buffer.writeln('=== سجل الاستقصاء ===');
      buffer.writeln('(لم تُنفَّذ أوامر استقصاء بعد)');
    } else {
      buffer.writeln('=== سجل الاستقصاء (أوامر نُفِّذت ونتائجها) ===');
      for (var i = 0; i < investigationLog.length; i++) {
        final r = investigationLog[i];
        buffer.writeln('--- أمر #${i + 1}: ${r.command} ---');
        if (r.success) {
          final out = r.output.trim();
          buffer.writeln(out.isEmpty ? '(لا مخرجات)' : _clip(out, 2500));
        } else {
          buffer.writeln('فشل: ${r.error ?? "خطأ غير معروف"}');
        }
        buffer.writeln();
      }
    }

    buffer.writeln();
    if (forceFinal) {
      buffer.writeln(
          '⚠️ بلغت الحد الأقصى لخطوات الاستقصاء. قدّم الآن التقرير النهائي '
          '(action = "final") بناءً على المعلومات المتوفرة فقط.');
    } else {
      buffer.writeln(
          'قرّر خطوتك التالية وأعِد كائن JSON فقط حسب البروتوكول أعلاه.');
    }
    return buffer.toString();
  }

  static String _clip(String s, int max) =>
      s.length <= max ? s : '${s.substring(0, max)}\n… (اقتُطع)';

  // ============================================================
  //  تحليل رد الـ AI إلى AgentDecision
  // ============================================================

  static AgentDecision _parseDecision(String raw, {required bool forceFinal}) {
    final jsonMap = _extractJsonObject(raw);

    if (jsonMap == null) {
      // فشل استخراج JSON — نعامل النص الخام كتقرير نهائي (fallback آمن)
      debugPrint('[AgenticService] JSON parse failed, treating as final text');
      return AgentDecision(
        action: AgentActionType.finalAnswer,
        report: raw.trim(),
        fixCommands: _extractInlineCommands(raw),
      );
    }

    final actionStr = (jsonMap['action'] ?? '').toString().toLowerCase();
    final thought = (jsonMap['thought'] ?? '').toString();

    final isInvestigate = actionStr == 'investigate' && !forceFinal;

    if (isInvestigate) {
      final commands = _asStringList(jsonMap['commands']);
      if (commands.isEmpty) {
        // لا أوامر رغم طلب الاستقصاء — عاملها كنهائية لتجنّب حلقة فارغة
        return AgentDecision(
          action: AgentActionType.finalAnswer,
          thought: thought,
          report: (jsonMap['report'] ?? raw).toString().trim(),
          fixCommands: _asStringList(jsonMap['fix_commands']),
        );
      }
      return AgentDecision(
        action: AgentActionType.investigate,
        thought: thought,
        commands: commands,
      );
    }

    // نهائي
    return AgentDecision(
      action: AgentActionType.finalAnswer,
      thought: thought,
      report: (jsonMap['report'] ?? '').toString().trim().isNotEmpty
          ? jsonMap['report'].toString().trim()
          : raw.trim(),
      fixCommands: _asStringList(jsonMap['fix_commands']),
    );
  }

  static List<String> _asStringList(dynamic value) {
    if (value is List) {
      return value
          .map((e) => e.toString().trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }
    if (value is String && value.trim().isNotEmpty) {
      return [value.trim()];
    }
    return const [];
  }

  /// يستخرج أول كائن JSON متوازن الأقواس من نص قد يحوي ```json أو نصاً إضافياً.
  static Map<String, dynamic>? _extractJsonObject(String raw) {
    var text = raw.trim();

    // إزالة أسوار الكود ```json ... ```
    final fence = RegExp(r'```(?:json)?\s*([\s\S]*?)```');
    final fenceMatch = fence.firstMatch(text);
    if (fenceMatch != null) {
      text = fenceMatch.group(1)!.trim();
    }

    final start = text.indexOf('{');
    if (start < 0) return null;

    // موازنة الأقواس مع احترام السلاسل النصية
    var depth = 0;
    var inString = false;
    var escaped = false;
    for (var i = start; i < text.length; i++) {
      final ch = text[i];
      if (inString) {
        if (escaped) {
          escaped = false;
        } else if (ch == '\\') {
          escaped = true;
        } else if (ch == '"') {
          inString = false;
        }
        continue;
      }
      if (ch == '"') {
        inString = true;
      } else if (ch == '{') {
        depth++;
      } else if (ch == '}') {
        depth--;
        if (depth == 0) {
          final candidate = text.substring(start, i + 1);
          try {
            final decoded = jsonDecode(candidate);
            if (decoded is Map<String, dynamic>) return decoded;
          } catch (e) {
            debugPrint('[AgenticService] jsonDecode error: $e');
            return null;
          }
        }
      }
    }
    return null;
  }

  /// fallback: يستخرج أوامر RouterOS من نص حر (أسطر تبدأ بـ /)
  static List<String> _extractInlineCommands(String content) {
    final commands = <String>[];
    final linePattern = RegExp(r'^(\/[^\n]+)$', multiLine: true);
    for (final match in linePattern.allMatches(content)) {
      final cmd = match.group(1)?.trim();
      if (cmd != null && !commands.contains(cmd)) commands.add(cmd);
    }
    return commands;
  }
}
