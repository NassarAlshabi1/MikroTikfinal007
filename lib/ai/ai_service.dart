// ============================================================
//  AI Service — يتصل بـ OpenAI أو Google Gemini
//  يدعم استخراج الأوامر المقترحة من رد الـ AI
// ============================================================

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'diagnostics_models.dart';
import 'system_prompts.dart';

class AiService {
  AiService._();

  // الـ System Prompt يُختار ديناميكياً حسب DiagnosticMode
  // (تم نقله إلى system_prompts.dart لدعم 7 أوضاع تشخيص)

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
      throw const AiServiceException(
          'مفتاح API غير مُعد. افتح الإعدادات وأدخل المفتاح.');
    }

    try {
      switch (settings.provider) {
        case AiProvider.openAI:
        case AiProvider.openRouter: // 🔧 OpenRouter متوافق مع OpenAI API
        case AiProvider.custom: // 🔧 المزود المخصص يستخدم OpenAI API
          return await _analyzeWithOpenAI(
            settings: settings,
            userQuery: userQuery,
            snapshotContext: snapshotContext,
            conversationHistory: conversationHistory,
          );
        case AiProvider.gemini:
          return await _analyzeWithGemini(
            settings: settings,
            userQuery: userQuery,
            snapshotContext: snapshotContext,
            conversationHistory: conversationHistory,
          );
      }
    } on DioException catch (e) {
      throw AiServiceException(_mapDioError(e));
    } on AiServiceException {
      rethrow;
    } catch (e) {
      throw AiServiceException('تعذّر الحصول على رد من الـ AI: $e');
    }
  }

  /// محادثة عامة منخفضة المستوى — تُستخدم من محرّك التشخيص الوكيل (Agentic).
  ///
  /// [systemPrompt] — تعليمات النظام (بروتوكول القرار)
  /// [messages] — رسائل بصيغة {role, content} (user/assistant)
  /// تُعيد النص الخام لرد الـ AI (بدون استخراج أوامر).
  static Future<String> chat({
    required AiSettings settings,
    required String systemPrompt,
    required List<Map<String, String>> messages,
    double temperature = 0.3,
  }) async {
    if (!settings.isConfigured) {
      throw const AiServiceException(
          'مفتاح API غير مُعد. افتح الإعدادات وأدخل المفتاح.');
    }
    try {
      switch (settings.provider) {
        case AiProvider.openAI:
        case AiProvider.openRouter: // المزود المخصص يستخدم OpenAI API
        case AiProvider.custom: // المزود المخصص يستخدم OpenAI API
          return await _chatOpenAI(
            settings: settings,
            systemPrompt: systemPrompt,
            messages: messages,
            temperature: temperature,
          );
        case AiProvider.gemini:
          return await _chatGemini(
            settings: settings,
            systemPrompt: systemPrompt,
            messages: messages,
            temperature: temperature,
          );
      }
    } on DioException catch (e) {
      throw AiServiceException(_mapDioError(e));
    } on AiServiceException {
      rethrow;
    } catch (e) {
      throw AiServiceException('تعذّر الحصول على رد من الـ AI: $e');
    }
  }

  static Future<String> _chatOpenAI({
    required AiSettings settings,
    required String systemPrompt,
    required List<Map<String, String>> messages,
    required double temperature,
  }) async {
    final dio = Dio();
    dio.options.connectTimeout = const Duration(seconds: 30);
    dio.options.receiveTimeout = const Duration(seconds: 90);

    final baseUrl = settings.effectiveBaseUrl.replaceAll(RegExp(r'\/+$'), '');
    final endpoint = '$baseUrl/chat/completions';

    final payloadMessages = <Map<String, String>>[
      {'role': 'system', 'content': systemPrompt},
      ...messages,
    ];

    final response = await dio.post(
      endpoint,
      options: Options(headers: {
        'Authorization': 'Bearer ${settings.apiKey}',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      }, responseType: ResponseType.json),
      data: {
        'model': settings.effectiveModel,
        'messages': payloadMessages,
        'max_tokens': settings.maxTokens,
        'temperature': temperature,
      },
    );
    final data = response.data as Map<String, dynamic>;
    return data['choices'][0]['message']['content'] as String;
  }

  static Future<String> _chatGemini({
    required AiSettings settings,
    required String systemPrompt,
    required List<Map<String, String>> messages,
    required double temperature,
  }) async {
    final dio = Dio();
    dio.options.connectTimeout = const Duration(seconds: 30);
    dio.options.receiveTimeout = const Duration(seconds: 90);

    final baseUrl = settings.baseUrl != null && settings.baseUrl!.isNotEmpty
        ? settings.baseUrl!.replaceAll(RegExp(r'\/+$'), '')
        : 'https://generativelanguage.googleapis.com/v1beta';
    final endpoint = '$baseUrl/models/${settings.model}:generateContent';

    final contents = <Map<String, dynamic>>[
      for (final msg in messages)
        {
          'role': msg['role'] == 'assistant' ? 'model' : 'user',
          'parts': [
            {'text': msg['content'] ?? ''},
          ],
        },
    ];

    final response = await dio.post(
      endpoint,
      queryParameters: {'key': settings.apiKey},
      options: Options(headers: {'Content-Type': 'application/json'}),
      data: {
        'systemInstruction': {
          'parts': [
            {'text': systemPrompt},
          ],
        },
        'contents': contents,
        'generationConfig': {
          'temperature': temperature,
          'maxOutputTokens': settings.maxTokens,
        },
      },
    );
    return response.data['candidates'][0]['content']['parts'][0]['text']
        as String;
  }

  /// يحوّل أخطاء الشبكة/الخادم إلى رسائل عربية مفهومة
  static String _mapDioError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'انتهت مهلة الاتصال بمزوّد الـ AI. تحقّق من الإنترنت وحاول مجدداً.';
      case DioExceptionType.connectionError:
        return 'تعذّر الاتصال بمزوّد الـ AI. تحقّق من اتصال الإنترنت.';
      case DioExceptionType.cancel:
        return 'أُلغي الطلب.';
      default:
        final code = e.response?.statusCode;
        switch (code) {
          case 401:
            return 'مفتاح API غير صالح أو منتهي. تحقّق من المفتاح في الإعدادات.';
          case 403:
            return 'الوصول مرفوض (403). تأكّد من صلاحيات المفتاح.';
          case 429:
            return 'تجاوزت حد الطلبات (429). انتظر قليلاً ثم أعد المحاولة.';
          case 400:
            return 'طلب غير صالح (400). قد يكون الموديل غير مدعوم أو المدخلات كبيرة.';
          default:
            if (code != null && code >= 500) {
              return 'خطأ مؤقت في خادم المزوّد ($code). حاول لاحقاً.';
            }
            return 'فشل الاتصال بمزوّد الـ AI${code != null ? " ($code)" : ""}.';
        }
    }
  }

  // ============================================================
  //  OpenAI (ChatGPT) & OpenAI-compatible APIs
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

    // استخدام baseUrl مخصص (OpenRouter, Azure, Ollama, إلخ) أو الافتراضي
    final baseUrl = settings.effectiveBaseUrl.replaceAll(RegExp(r'\/+$'), '');
    final endpoint = '$baseUrl/chat/completions';

    // اختيار الـ System Prompt المناسب للوضع المختار
    final systemPrompt = promptForMode(settings.mode);

    // بناء رسائل المحادثة
    final messages = <Map<String, String>>[
      {'role': 'system', 'content': systemPrompt},
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
        'model=${settings.effectiveModel}, maxTokens=${settings.maxTokens}, endpoint=$endpoint');

    final response = await dio.post(
      endpoint,
      options: Options(
        headers: {
          'Authorization': 'Bearer ${settings.apiKey}',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        responseType: ResponseType.json,
      ),
      data: {
        'model': settings.effectiveModel,
        'messages': messages,
        'max_tokens': settings.maxTokens,
        'temperature': 0.4, // منخفض لإجابات تقنية دقيقة
      },
    );

    final data = response.data as Map<String, dynamic>;
    if (data.containsKey('error')) {
      final error = data['error'] as Map<String, dynamic>;
      throw AiServiceException(
          'خطأ من الـ AI: ${error['message'] ?? error['code'] ?? 'خطأ غير معروف'}');
    }
    final content = data['choices'][0]['message']['content'] as String;
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

    // استخدام baseUrl مخصص إن وُجد (للأسباب المتوافقة مع Gemini API)
    final baseUrl = settings.baseUrl != null && settings.baseUrl!.isNotEmpty
        ? settings.baseUrl!.replaceAll(RegExp(r'\/+$'), '')
        : 'https://generativelanguage.googleapis.com/v1beta';
    final endpoint = '$baseUrl/models/${settings.model}:generateContent';

    // اختيار الـ System Prompt المناسب للوضع المختار
    final systemPrompt = promptForMode(settings.mode);

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
            'text': '$systemPrompt\n\n'
                'سؤال المستخدم: $userQuery\n\n'
                '=== بيانات جهاز MikroTik ===\n$snapshotContext',
          },
        ],
      },
    ];

    debugPrint('[AiService] Gemini request: ${contents.length} messages, '
        'model=${settings.model}, endpoint=$endpoint');

    final response = await dio.post(
      endpoint,
      queryParameters: {'key': settings.apiKey},
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

/// استثناء برسالة عربية جاهزة للعرض للمستخدم
class AiServiceException implements Exception {
  final String message;
  const AiServiceException(this.message);

  @override
  String toString() => message;
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
