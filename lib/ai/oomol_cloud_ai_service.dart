// ============================================================
//  OomolCloudAiService — خدمة AI سحابية عبر OOMOL MCP
//
//  تستخدم OomolMcpClient لتشغيل pipeline تحليل logs على OOMOL Cloud
//  بدلاً من استدعاء OpenAI/Gemini مباشرة.
//
//  المميزات:
//  - تنفيذ serverless على OOMOL Cloud (5 concurrent tasks)
//  - async + polling حتى انتهاء المهمة
//  - ينشئ task + ينتظر النتيجة + يعرضها
//  - يدعم upload_file لرفع logs كبيرة قبل المعالجة
//
//  الاستخدام:
//  ```dart
//  final service = OomolCloudAiService(apiKey: 'api-...');
//  await service.connect();
//  final result = await service.analyzeLogs(logText);
//  print(result);
//  await service.disconnect();
//  ```
//
//  ملاحظة: يتطلب وجود package منشور على OOMOL Cloud.
//  حالياً الحساب الافتراضي لا يحتوي على packages، لذا الخدمة
//  ترجع استجابة fallback ذكية محلية عند الفشل.
// ============================================================

import 'package:flutter/foundation.dart';

import 'oomol_mcp_client.dart';
import 'mikrotik_log_analyzer.dart';

/// إعدادات OOMOL Cloud AI
class OomolAiSettings {
  final String apiKey;
  final String? packageName; // اسم الـ package المنشور على OOMOL
  final String? packageVersion;
  final String? baseUrl;
  final String blockName; // اسم الـ block (افتراضي: main)

  const OomolAiSettings({
    required this.apiKey,
    this.packageName,
    this.packageVersion,
    this.baseUrl,
    this.blockName = 'main',
  });

  bool get isConfigured => apiKey.isNotEmpty && packageName != null;
}

/// نتيجة تحليل OOMOL Cloud
class OomolAnalysisResult {
  final bool success;
  final String? taskId;
  final String content;
  final String? error;
  final bool usedFallback; // هل استخدم تحليل محلي بدلاً من cloud؟
  final LogAnalysisResult? fallbackResult; // النتيجة المحلية (إن استُخدمت)
  final DateTime completedAt;

  const OomolAnalysisResult({
    required this.success,
    this.taskId,
    required this.content,
    this.error,
    required this.usedFallback,
    this.fallbackResult,
    required this.completedAt,
  });
}

class OomolCloudAiService {
  final OomolAiSettings settings;
  OomolMcpClient? _client;

  OomolCloudAiService({required this.settings});

  /// هل الخدمة متصلة؟
  bool get isConnected => _client?.isConnected ?? false;

  /// يتصل بخادم MCP
  Future<void> connect() async {
    if (isConnected) return;
    _client = OomolMcpClient(
      apiKey: settings.apiKey,
      baseUrl: settings.baseUrl,
      packageName: settings.packageName,
      packageVersion: settings.packageVersion,
    );
    await _client!.connect();
  }

  /// يغلق الاتصال
  Future<void> disconnect() async {
    await _client?.disconnect();
    _client = null;
  }

  /// يحصل على معلومات الـ dashboard من OOMOL Cloud
  Future<OomolDashboard?> getDashboard() async {
    if (!isConnected) return null;
    try {
      return await _client!.getDashboard();
    } catch (e) {
      debugPrint('[OomolCloudAiService] getDashboard failed: $e');
      return null;
    }
  }

  /// يحلل logs MikroTik عبر OOMOL Cloud Task
  ///
  /// الخطوات:
  /// 1. تحليل محلي أولي (للحصول على fallback + إحصائيات)
  /// 2. محاولة إنشاء cloud task مع inputValues = { logs, analysis }
  /// 3. انتظار النتيجة (polling)
  /// 4. في حال الفشل (404 package / timeout): استخدام التحليل المحلي
  Future<OomolAnalysisResult> analyzeLogs(String logs) async {
    final localResult = MikrotikLogAnalyzer.analyze(logs);
    final localContext = MikrotikLogAnalyzer.toAiContext(localResult);

    // إن لم يكن الاتصال مهيّأ، استخدم التحليل المحلي فقط
    if (!isConnected || !settings.isConfigured) {
      return OomolAnalysisResult(
        success: true,
        content: localResult.summary,
        usedFallback: true,
        fallbackResult: localResult,
        completedAt: DateTime.now(),
      );
    }

    // محاولة إنشاء cloud task
    try {
      debugPrint('[OomolCloudAiService] Creating cloud task...');
      final taskId = await _client!.createTask(
        packageName: settings.packageName!,
        packageVersion: settings.packageVersion ?? 'latest',
        blockName: settings.blockName,
        inputValues: {
          'logs': logs,
          'localAnalysis': localContext,
          'mode': 'mikrotik_log_analysis',
        },
      );
      debugPrint('[OomolCloudAiService] Task created: $taskId');

      // انتظار النتيجة
      final result = await _client!.awaitResult(
        taskId,
        intervalMs: 2000,
        timeoutMs: 300000, // 5 دقائق
      );

      final status = result['status'] as String? ?? 'unknown';
      if (status == 'success') {
        final resultData = result['resultData'];
        final content = resultData is Map
            ? (resultData['analysis'] as String? ??
                resultData['text'] as String? ??
                resultData.toString())
            : resultData.toString();
        return OomolAnalysisResult(
          success: true,
          taskId: taskId,
          content: content,
          usedFallback: false,
          fallbackResult: localResult,
          completedAt: DateTime.now(),
        );
      } else {
        final failedMsg = result['failedMessage'] as String? ?? 'Task failed';
        return OomolAnalysisResult(
          success: false,
          taskId: taskId,
          content: localResult.summary,
          error: 'Cloud task failed: $failedMsg',
          usedFallback: true,
          fallbackResult: localResult,
          completedAt: DateTime.now(),
        );
      }
    } catch (e) {
      debugPrint('[OomolCloudAiService] Cloud analysis failed: $e');
      return OomolAnalysisResult(
        success: true,
        content: localResult.summary,
        error: e.toString(),
        usedFallback: true,
        fallbackResult: localResult,
        completedAt: DateTime.now(),
      );
    }
  }

  /// يحلل logs من MikrotikSnapshot
  Future<OomolAnalysisResult> analyzeSnapshotLogs(
    String logs, {
    Map<String, String>? extraContext,
  }) async {
    // إن كان هناك سياق إضافي، أرفقه
    String fullLogs = logs;
    if (extraContext != null && extraContext.isNotEmpty) {
      fullLogs += '\n\n=== EXTRA CONTEXT ===\n';
      extraContext.forEach((k, v) {
        fullLogs += '\n--- $k ---\n$v\n';
      });
    }
    return analyzeLogs(fullLogs);
  }
}
