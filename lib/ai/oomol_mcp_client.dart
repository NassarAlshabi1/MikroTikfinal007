// ============================================================
//  OomolMcpClient — عميل MCP للاتصال بـ oomol-cloud-mcp-server
//
//  يشغّل خادم MCP كـ subprocess عبر `npx -y oomol-cloud-mcp-sdk`
//  ويتواصل معه عبر JSON-RPC 2.0 على stdio.
//
//  الأدوات الـ 14 المتاحة:
//  - create_task / execute_task / create_block_task / execute_block_task
//  - list_tasks / get_latest_tasks / get_task / get_task_result / await_result
//  - get_dashboard / set_tasks_pause / pause_user_queue / resume_user_queue
//  - upload_file
//
//  الاستخدام:
//  ```dart
//  final client = OomolMcpClient(apiKey: 'api-...');
//  await client.connect();
//  final dash = await client.getDashboard();
//  print(dash.maxConcurrency);
//  await client.disconnect();
//  ```
// ============================================================

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

/// معلومات الـ Dashboard من OOMOL Cloud
class OomolDashboard {
  final int maxConcurrency;
  final int maxQueueSize;
  final int queued;
  final int scheduling;
  final int scheduled;
  final int running;
  final bool paused;
  final String? pauseType;
  final bool canResume;

  const OomolDashboard({
    required this.maxConcurrency,
    required this.maxQueueSize,
    required this.queued,
    required this.scheduling,
    required this.scheduled,
    required this.running,
    required this.paused,
    this.pauseType,
    required this.canResume,
  });

  factory OomolDashboard.fromJson(Map<String, dynamic> json) {
    final limits = json['limits'] as Map<String, dynamic>? ?? {};
    final count = json['count'] as Map<String, dynamic>? ?? {};
    final pause = json['pause'] as Map<String, dynamic>? ?? {};
    return OomolDashboard(
      maxConcurrency: limits['maxConcurrency'] as int? ?? 0,
      maxQueueSize: limits['maxQueueSize'] as int? ?? 0,
      queued: count['queued'] as int? ?? 0,
      scheduling: count['scheduling'] as int? ?? 0,
      scheduled: count['scheduled'] as int? ?? 0,
      running: count['running'] as int? ?? 0,
      paused: pause['paused'] as bool? ?? false,
      pauseType: pause['type'] as String?,
      canResume: pause['canResume'] as bool? ?? false,
    );
  }

  /// إجمالي المهام النشطة
  int get activeTasks => queued + scheduling + scheduled + running;

  /// هل الحساب نشط (يسمح بالمهام)؟
  bool get isActive => !paused && maxConcurrency > 0;
}

/// عنصر مهمة في قائمة المهام
class OomolTask {
  final String taskId;
  final String taskType; // user | shared
  final String ownerId;
  final String? subscriptionId;
  final String? packageId;
  final String
      status; // queued | scheduling | scheduled | running | success | failed
  final int progress;
  final String workload; // serverless
  final String workloadId;
  final String? resultUrl;
  final String? failedMessage;
  final int createdAt;
  final int updatedAt;
  final int? startTime;
  final int? endTime;

  const OomolTask({
    required this.taskId,
    required this.taskType,
    required this.ownerId,
    this.subscriptionId,
    this.packageId,
    required this.status,
    required this.progress,
    required this.workload,
    required this.workloadId,
    this.resultUrl,
    this.failedMessage,
    required this.createdAt,
    required this.updatedAt,
    this.startTime,
    this.endTime,
  });

  factory OomolTask.fromJson(Map<String, dynamic> j) => OomolTask(
        taskId: j['taskID'] as String? ?? '',
        taskType: j['taskType'] as String? ?? 'user',
        ownerId: j['ownerID'] as String? ?? '',
        subscriptionId: j['subscriptionID'] as String?,
        packageId: j['packageID'] as String?,
        status: j['status'] as String? ?? 'unknown',
        progress: (j['progress'] as num?)?.toInt() ?? 0,
        workload: j['workload'] as String? ?? 'serverless',
        workloadId: j['workloadID'] as String? ?? '',
        resultUrl: j['resultURL'] as String?,
        failedMessage: j['failedMessage'] as String?,
        createdAt: j['createdAt'] as int? ?? 0,
        updatedAt: j['updatedAt'] as int? ?? 0,
        startTime: j['startTime'] as int?,
        endTime: j['endTime'] as int?,
      );

  bool get isSuccess => status == 'success';
  bool get isFailed => status == 'failed';
  bool get isRunning =>
      status == 'running' ||
      status == 'queued' ||
      status == 'scheduling' ||
      status == 'scheduled';

  DateTime? get createdAtDate =>
      createdAt > 0 ? DateTime.fromMillisecondsSinceEpoch(createdAt) : null;
  DateTime? get startTimeDate => startTime != null && startTime! > 0
      ? DateTime.fromMillisecondsSinceEpoch(startTime!)
      : null;
  DateTime? get endTimeDate => endTime != null && endTime! > 0
      ? DateTime.fromMillisecondsSinceEpoch(endTime!)
      : null;
}

/// نتيجة استدعاء أداة MCP
class McpToolResult {
  final String text;
  final bool isError;

  const McpToolResult({required this.text, this.isError = false});

  /// يحاول تحويل النص إلى JSON (إن أمكن)
  /// يرجع Object? لتجنّب dynamic (dart-optimization)
  Object? get asJson {
    try {
      return jsonDecode(text);
    } on FormatException {
      return text;
    }
  }
}

/// معلومات أداة MCP
class McpToolInfo {
  final String name;
  final String description;
  final Map<String, dynamic> inputSchema;

  const McpToolInfo({
    required this.name,
    required this.description,
    required this.inputSchema,
  });

  factory McpToolInfo.fromJson(Map<String, dynamic> j) => McpToolInfo(
        name: j['name'] as String? ?? '',
        description: j['description'] as String? ?? '',
        inputSchema: (j['inputSchema'] as Map<String, dynamic>?) ?? {},
      );

  List<String> get paramNames {
    final props = inputSchema['properties'] as Map<String, dynamic>?;
    if (props == null) return const [];
    return props.keys.toList();
  }

  List<String> get requiredParams {
    final req = inputSchema['required'] as List<dynamic>?;
    if (req == null) return const [];
    return req.cast<String>();
  }
}

/// استثناء OOMOL MCP
class OomolMcpException implements Exception {
  final String message;
  final int? code;
  const OomolMcpException(this.message, [this.code]);

  @override
  String toString() => 'OomolMcpException: $message';
}

// ============================================================
//  OomolMcpClient — العميل الفعلي
// ============================================================

class OomolMcpClient {
  static const String _serverPackage = 'oomol-cloud-mcp-sdk';

  final String apiKey;
  final String? baseUrl;
  final String? packageName;
  final String? packageVersion;

  Process? _process;
  StreamSubscription<String>? _stdoutSub;
  final Map<int, Completer<Map<String, dynamic>>> _pending = {};
  final _notifications = StreamController<Map<String, dynamic>>.broadcast();

  int _nextId = 1;
  bool _initialized = false;

  OomolMcpClient({
    required this.apiKey,
    this.baseUrl,
    this.packageName,
    this.packageVersion,
  }) : assert(apiKey.isNotEmpty, 'API key cannot be empty');

  /// هل العميل متصل بالخادم؟
  bool get isConnected => _process != null && _initialized;

  /// تدفق الإشعارات القادمة من الخادم
  Stream<Map<String, dynamic>> get notifications => _notifications.stream;

  /// يشغّل خادم MCP كـ subprocess ويتصل به
  Future<void> connect({Duration timeout = const Duration(seconds: 30)}) async {
    if (isConnected) return;

    debugPrint('[OomolMcpClient] Starting subprocess: npx -y $_serverPackage');

    // بناء بيئة الـ process
    final env = Map<String, String>.from(Platform.environment)
      ..['OOMOL_API_KEY'] = apiKey;
    if (baseUrl != null) env['OOMOL_BASE_URL'] = baseUrl!;
    if (packageName != null) env['OOMOL_PACKAGE_NAME'] = packageName!;
    if (packageVersion != null) env['OOMOL_PACKAGE_VERSION'] = packageVersion!;

    // تشغيل npx
    _process = await Process.start(
      'npx',
      ['-y', _serverPackage],
      environment: env,
    );

    // الاستماع للـ stdout
    _stdoutSub = _process!.stdout
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen(_handleLine, onError: (e) {
      debugPrint('[OomolMcpClient] stdout error: $e');
    });

    // الاستماع للـ stderr (للتشخيص)
    _process!.stderr.transform(utf8.decoder).listen((data) {
      // stderr يحوي logs تشخيصية (لا تعتبر أخطاء حقيقية)
      debugPrint('[OomolMcpClient] server stderr: ${data.trim()}');
    });

    // التحقق من أن العملية لم تمت
    if (_process == null) {
      throw const OomolMcpException('Failed to start MCP server process');
    }

    // إرسال initialize
    try {
      final initResp = await _sendRequest(
        'initialize',
        {
          'protocolVersion': '2024-11-05',
          'capabilities': <String, dynamic>{},
          'clientInfo': {
            'name': 'mikrotik-flutter-app',
            'version': '2.0.0',
          },
        },
        timeout: timeout,
      );

      debugPrint('[OomolMcpClient] Connected: ${initResp['serverInfo']}');

      // إرسال notifications/initialized
      _sendNotification('notifications/initialized', {});
      _initialized = true;
    } catch (e) {
      await disconnect();
      throw OomolMcpException('initialize failed: $e');
    }
  }

  /// يغلق الاتصال ويوقف الخادم
  Future<void> disconnect() async {
    debugPrint('[OomolMcpClient] Disconnecting...');
    await _stdoutSub?.cancel();
    _stdoutSub = null;
    _process?.kill(ProcessSignal.sigterm);
    await _process?.exitCode.timeout(
      const Duration(seconds: 5),
      onTimeout: () {
        _process?.kill(ProcessSignal.sigkill);
        return -1;
      },
    ).catchError((_) => -1);
    _process = null;
    _initialized = false;
    // إلغاء أي طلبات معلّقة
    for (final c in _pending.values) {
      c.completeError(const OomolMcpException('Client disconnected'));
    }
    _pending.clear();
  }

  // ============================================================
  //  بروتوكول JSON-RPC
  // ============================================================

  void _handleLine(String line) {
    if (line.trim().isEmpty) return;
    Map<String, dynamic>? msg;
    try {
      msg = jsonDecode(line) as Map<String, dynamic>;
    } catch (_) {
      return; // ليس JSON صالح
    }

    // Response لطلب سابق
    final id = msg['id'];
    if (id is int && _pending.containsKey(id)) {
      final completer = _pending.remove(id)!;
      if (msg.containsKey('error')) {
        final err = msg['error'] as Map<String, dynamic>;
        completer.completeError(OomolMcpException(
          err['message'] as String? ?? 'Unknown error',
          err['code'] as int?,
        ));
      } else {
        completer.complete(msg['result'] as Map<String, dynamic>);
      }
      return;
    }

    // Notification (بدون id)
    if (id == null && msg.containsKey('method')) {
      _notifications.add(msg);
    }
  }

  Future<Map<String, dynamic>> _sendRequest(
    String method,
    Map<String, dynamic> params, {
    Duration timeout = const Duration(seconds: 30),
  }) async {
    if (_process == null) {
      throw const OomolMcpException('Not connected. Call connect() first.');
    }

    final id = _nextId++;
    final req = jsonEncode({
      'jsonrpc': '2.0',
      'id': id,
      'method': method,
      'params': params,
    });

    final completer = Completer<Map<String, dynamic>>();
    _pending[id] = completer;

    try {
      _process!.stdin.writeln(req);
      debugPrint('[OomolMcpClient] → $method (id=$id)');
    } catch (e) {
      _pending.remove(id);
      throw OomolMcpException('Failed to write to stdin: $e');
    }

    return completer.future.timeout(timeout, onTimeout: () {
      _pending.remove(id);
      throw OomolMcpException('Request $method (id=$id) timed out');
    });
  }

  void _sendNotification(String method, Map<String, dynamic> params) {
    if (_process == null) return;
    final notif = jsonEncode({
      'jsonrpc': '2.0',
      'method': method,
      'params': params,
    });
    try {
      _process!.stdin.writeln(notif);
    } catch (e) {
      debugPrint('[OomolMcpClient] Failed to send notification: $e');
    }
  }

  // ============================================================
  //  استدعاء الأدوات
  // ============================================================

  /// يستدعي أداة MCP عامة باسمها
  Future<McpToolResult> callTool(
    String name,
    Map<String, dynamic> arguments, {
    Duration timeout = const Duration(seconds: 60),
  }) async {
    final result = await _sendRequest(
      'tools/call',
      {'name': name, 'arguments': arguments},
      timeout: timeout,
    );

    final content = result['content'] as List<dynamic>?;
    if (content == null || content.isEmpty) {
      return const McpToolResult(text: '');
    }

    final firstContent = content.first as Map<String, dynamic>;
    final text = firstContent['text'] as String? ?? '';
    final isError = result['isError'] as bool? ?? false;
    return McpToolResult(text: text, isError: isError);
  }

  /// يستدعي tools/list ويرجع كل الأدوات المتاحة
  Future<List<McpToolInfo>> listTools() async {
    final result = await _sendRequest('tools/list', {});
    final tools = result['tools'] as List<dynamic>? ?? [];
    return tools
        .map((t) => McpToolInfo.fromJson(t as Map<String, dynamic>))
        .toList();
  }

  // ============================================================
  //  واجهات سهلة للأدوات الـ 14
  // ============================================================

  /// get_dashboard — حدود الحساب وحالة الطوابير
  Future<OomolDashboard> getDashboard() async {
    final r = await callTool('get_dashboard', {});
    if (r.isError) throw OomolMcpException(r.text);
    final data = r.asJson;
    if (data is! Map<String, dynamic>) {
      throw OomolMcpException('Invalid dashboard response: ${r.text}');
    }
    return OomolDashboard.fromJson(data);
  }

  /// list_tasks — قائمة مهام المستخدم
  Future<List<OomolTask>> listTasks({
    int size = 20,
    String? status,
    String? taskType,
    String? workloadId,
    String? packageId,
    String? nextToken,
  }) async {
    final args = <String, dynamic>{'size': size};
    if (status != null) args['status'] = status;
    if (taskType != null) args['taskType'] = taskType;
    if (workloadId != null) args['workloadID'] = workloadId;
    if (packageId != null) args['packageID'] = packageId;
    if (nextToken != null) args['nextToken'] = nextToken;

    final r = await callTool('list_tasks', args);
    if (r.isError) throw OomolMcpException(r.text);
    final data = r.asJson;
    if (data is! Map<String, dynamic>) return const [];
    final tasks = data['tasks'] as List<dynamic>? ?? [];
    return tasks
        .map((t) => OomolTask.fromJson(t as Map<String, dynamic>))
        .toList();
  }

  /// create_task — إنشاء مهمة serverless
  ///
  /// ملاحظة: يتطلب package منشور على منصة OOMOL
  Future<String> createTask({
    required String packageName,
    required String packageVersion,
    required String blockName,
    Map<String, dynamic> inputValues = const {},
  }) async {
    final r = await callTool(
        'create_task',
        {
          'packageName': packageName,
          'packageVersion': packageVersion,
          'blockName': blockName,
          'inputValues': inputValues,
        },
        timeout: const Duration(seconds: 30));
    if (r.isError) throw OomolMcpException(r.text);
    final data = r.asJson;
    if (data is Map<String, dynamic>) {
      final taskId = data['taskID'] as String?;
      if (taskId != null) return taskId;
    }
    throw OomolMcpException('Unexpected create_task response: ${r.text}');
  }

  /// execute_task — إنشاء + انتظار النتيجة
  Future<Map<String, dynamic>> executeTask({
    required String packageName,
    required String packageVersion,
    required String blockName,
    Map<String, dynamic> inputValues = const {},
    int intervalMs = 2000,
    int timeoutMs = 300000,
  }) async {
    final r = await callTool(
        'execute_task',
        {
          'packageName': packageName,
          'packageVersion': packageVersion,
          'blockName': blockName,
          'inputValues': inputValues,
          'intervalMs': intervalMs,
          'timeoutMs': timeoutMs,
        },
        timeout: Duration(milliseconds: timeoutMs + 30000));
    if (r.isError) throw OomolMcpException(r.text);
    final data = r.asJson;
    if (data is Map<String, dynamic>) return data;
    return {'text': r.text};
  }

  /// get_task — تفاصيل مهمة
  Future<OomolTask> getTask(String taskId) async {
    final r = await callTool('get_task', {'taskID': taskId});
    if (r.isError) throw OomolMcpException(r.text);
    final data = r.asJson;
    if (data is Map<String, dynamic>) {
      return OomolTask.fromJson(data);
    }
    throw OomolMcpException('Unexpected get_task response: ${r.text}');
  }

  /// await_result — انتظار نتيجة مهمة
  Future<Map<String, dynamic>> awaitResult(
    String taskId, {
    int intervalMs = 2000,
    int timeoutMs = 300000,
  }) async {
    final r = await callTool(
        'await_result',
        {
          'taskID': taskId,
          'intervalMs': intervalMs,
          'timeoutMs': timeoutMs,
        },
        timeout: Duration(milliseconds: timeoutMs + 30000));
    if (r.isError) throw OomolMcpException(r.text);
    final data = r.asJson;
    if (data is Map<String, dynamic>) return data;
    return {'text': r.text};
  }

  /// upload_file — رفع ملف base64
  ///
  /// ملاحظة: قد يفشل في بعض البيئات (يحتاج XMLHttpRequest)
  Future<String> uploadFile({
    required String fileName,
    required String base64Data,
    String mimeType = 'application/octet-stream',
  }) async {
    final r = await callTool(
        'upload_file',
        {
          'fileName': fileName,
          'fileData': base64Data,
          'mimeType': mimeType,
        },
        timeout: const Duration(seconds: 120));
    if (r.isError) throw OomolMcpException(r.text);
    final data = r.asJson;
    if (data is Map<String, dynamic>) {
      // محاولة استخراج URL من استجابة شائعة
      final url = data['url'] as String? ??
          data['resultURL'] as String? ??
          data['fileUrl'] as String?;
      if (url != null) return url;
    }
    return r.text;
  }

  /// pause_user_queue — إيقاف الطابور
  Future<void> pauseUserQueue() async {
    final r = await callTool('pause_user_queue', {});
    if (r.isError) throw OomolMcpException(r.text);
  }

  /// resume_user_queue — استئناف الطابور
  Future<void> resumeUserQueue() async {
    final r = await callTool('resume_user_queue', {});
    if (r.isError) throw OomolMcpException(r.text);
  }

  /// set_tasks_pause — تحكم موحد في الإيقاف/الاستئناف
  Future<void> setTasksPause(bool paused) async {
    final r = await callTool('set_tasks_pause', {'paused': paused});
    if (r.isError) throw OomolMcpException(r.text);
  }
}
