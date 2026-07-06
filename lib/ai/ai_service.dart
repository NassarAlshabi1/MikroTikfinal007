// ============================================================
//  AI Service — يتصل بـ OpenAI أو Google Gemini
//  يدعم استخراج الأوامر المقترحة من رد الـ AI
// ============================================================

import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'diagnostics_models.dart';

class AiService {
  AiService._();

  // ============================================================
  //  System Prompt — عقل الـ AI
  // ============================================================
  static const String _systemPrompt = '''
أنت خبير شبكات MikroTik مع شهادات MTCNA, MTCRE, MTCTCE. مهمتك:

1. تحليل البيانات المقدمة من جهاز MikroTik (interfaces, routes, firewall, logs)
2. تحديد المشاكل المحتملة (interfaces down, routing loops, firewall misconfig, errors in logs)
3. اقتراح حلول عملية مع أوامر RouterOS محددة

قواعد الإجابة:
- ابدأ بتشخيص سريع للمشكلة في 2-3 جمل
- اشرح السبب الجذري باختصار
- اقترح أوامر RouterOS للإصلاح داخل كتل منفصلة بهذا الشكل:
  ```
  /command here
  ```
- اكتب بالعربية الفصحى الواضحة
- كن مختصراً ودقيقاً (تجنّب التكرار)
- إذا لم توجد مشكلة واضحة، اذكر ذلك واقترح تحسينات
- لا تخترع أوامر غير موجودة في RouterOS v7

تذكير: المستخدم يعتمد على نصيحتك لتشغيل شبكة حقيقية. كن دقيقاً.
''';

  /// يرسل طلب تحليل للـ AI
  ///
  /// [userQuery] — سؤال/وصف المستخدم للمشكلة
  /// [snapshotContext] — البيانات المجمّعة من MikroTik (من MikrotikSnapshot.toAiContext())
  /// [conversationHistory] — رسائل المحادثة السابقة (للـ multi-turn)
  static Future<AiAnalysisResult> analyze({
    required AiSettings settings,
    required String userQuery,
    required String snapshotContext,
    List<DiagnosticMessage> conversationHistory = const [],
  }) async {
    if (!settings.isConfigured) {
      throw Exception('مفتاح API غير مُعد. افتح الإعدادات وأدخل المفتاح.');
    }

    switch (settings.provider) {
      case AiProvider.openAI:
        return _analyzeWithOpenAI(
          settings: settings,
          userQuery: userQuery,
          snapshotContext: snapshotContext,
          conversationHistory: conversationHistory,
        );
      case AiProvider.gemini:
        return _analyzeWithGemini(
          settings: settings,
          userQuery: userQuery,
          snapshotContext: snapshotContext,
          conversationHistory: conversationHistory,
        );
    }
  }

  // ============================================================
  //  OpenAI (ChatGPT)
  // ============================================================
  static Future<AiAnalysisResult> _analyzeWithOpenAI({
    required AiSettings settings,
    required String userQuery,
    required String snapshotContext,
    required List<DiagnosticMessage> conversationHistory,
  }) async {
    final dio = Dio();
    dio.options.connectTimeout = const Duration(seconds: 30);
    dio.options.receiveTimeout = const Duration(seconds: 60);

    // بناء رسائل المحادثة
    final messages = <Map<String, String>>[
      {'role': 'system', 'content': _systemPrompt},
      // أضف المحادثة السابقة (آخر 10 رسائل لتوفير tokens)
      for (final msg in conversationHistory.takeLast(10))
        if (msg.type == MessageType.user || msg.type == MessageType.assistant)
          {
            'role': msg.type == MessageType.user ? 'user' : 'assistant',
            'content': msg.content,
          },
      // الرسالة الحالية: السؤال + البيانات
      {
        'role': 'user',
        'content': 'سؤال المستخدم: $userQuery\n\n'
            '=== بيانات جهاز MikroTik ===\n$snapshotContext',
      },
    ];

    debugPrint('[AiService] OpenAI request: ${messages.length} messages, '
        'model=${settings.model}, maxTokens=${settings.maxTokens}');

    final response = await dio.post(
      'https://api.openai.com/v1/chat/completions',
      options: Options(
        headers: {
          'Authorization': 'Bearer ${settings.apiKey}',
          'Content-Type': 'application/json',
        },
      ),
      data: {
        'model': settings.model,
        'messages': messages,
        'max_tokens': settings.maxTokens,
        'temperature': 0.4,  // منخفض لإجابات تقنية دقيقة
      },
    );

    final content =
        response.data['choices'][0]['message']['content'] as String;
    final commands = _extractCommands(content);

    return AiAnalysisResult(
      content: content,
      suggestedCommands: commands,
    );
  }

  // ============================================================
  //  Google Gemini
  // ============================================================
  static Future<AiAnalysisResult> _analyzeWithGemini({
    required AiSettings settings,
    required String userQuery,
    required String snapshotContext,
    required List<DiagnosticMessage> conversationHistory,
  }) async {
    final dio = Dio();
    dio.options.connectTimeout = const Duration(seconds: 30);
    dio.options.receiveTimeout = const Duration(seconds: 60);

    // Gemini يستخدم تنسيق contents مختلف
    final contents = <Map<String, dynamic>>[
      // المحادثة السابقة
      for (final msg in conversationHistory.takeLast(10))
        if (msg.type == MessageType.user || msg.type == MessageType.assistant)
          {
            'role': msg.type == MessageType.user ? 'user' : 'model',
            'parts': [
              {'text': msg.content},
            ],
          },
      // الرسالة الحالية
      {
        'role': 'user',
        'parts': [
          {
            'text': '$_systemPrompt\n\n'
                'سؤال المستخدم: $userQuery\n\n'
                '=== بيانات جهاز MikroTik ===\n$snapshotContext',
          },
        ],
      },
    ];

    debugPrint('[AiService] Gemini request: ${contents.length} messages, '
        'model=${settings.model}');

    final response = await dio.post(
      'https://generativelanguage.googleapis.com/v1beta/models/'
      '${settings.model}:generateContent?key=${settings.apiKey}',
      options: Options(headers: {'Content-Type': 'application/json'}),
      data: {
        'contents': contents,
        'generationConfig': {
          'temperature': 0.4,
          'maxOutputTokens': settings.maxTokens,
        },
      },
    );

    final content =
        response.data['candidates'][0]['content']['parts'][0]['text'] as String;
    final commands = _extractCommands(content);

    return AiAnalysisResult(
      content: content,
      suggestedCommands: commands,
    );
  }

  // ============================================================
  //  استخراج أوامر RouterOS من رد الـ AI
  // ============================================================

  /// يستخرج الأوامر من كتل الكود ```...``` أو من أسطر تبدأ بـ /
  static List<String> _extractCommands(String content) {
    final commands = <String>[];

    // Pattern 1: كتل كود ```...```
    final codeBlockPattern = RegExp(r'```(?:\w+)?\n?([\s\S]*?)```');
    for (final match in codeBlockPattern.allMatches(content)) {
      final block = match.group(1) ?? '';
      for (final line in block.split('\n')) {
        final trimmed = line.trim();
        if (trimmed.startsWith('/') && trimmed.isNotEmpty) {
          commands.add(trimmed);
        }
      }
    }

    // Pattern 2: أسطر تبدأ بـ / مباشرة (بدون كتلة كود)
    final linePattern = RegExp(r'^(\/[^\n]+)$', multiLine: true);
    for (final match in linePattern.allMatches(content)) {
      final cmd = match.group(1)?.trim();
      if (cmd != null && !commands.contains(cmd)) {
        commands.add(cmd);
      }
    }

    return commands;
  }
}

/// نتيجة تحليل الـ AI
class AiAnalysisResult {
  final String content;
  final List<String> suggestedCommands;

  const AiAnalysisResult({
    required this.content,
    required this.suggestedCommands,
  });
}

// Extension صغير لـ List.takeLast (لأنه غير متاح في Dart القياسي)
extension TakeLast<T> on List<T> {
  List<T> takeLast(int n) {
    if (n >= length) return List.unmodifiable(this);
    return List.unmodifiable(sublist(length - n));
  }
}
