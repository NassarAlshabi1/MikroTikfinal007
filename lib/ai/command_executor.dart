// ============================================================
//  Command Executor — ينفّذ أوامر RouterOS مباشرة
//  يدعم:
//  - RouterOS API (عبر router_os_client الموجود)
//  - SSH (عبر dartssh2)
//  - معاينة قبل التنفيذ (تأكيد المستخدم)
//  - تصنيف الأوامر آمنة/خطرة
// ============================================================

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:router_os_client/router_os_client.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dartssh2/dartssh2.dart';

import '../services/secure_credentials_storage.dart';
import 'diagnostics_models.dart';

/// نتيجة تنفيذ أمر
class CommandResult {
  final String command;
  final bool success;
  final String output;
  final String? error;
  final Duration elapsed;
  final DateTime executedAt;

  const CommandResult({
    required this.command,
    required this.success,
    required this.output,
    this.error,
    required this.elapsed,
    required this.executedAt,
  });

  Map<String, dynamic> toJson() => {
        'command': command,
        'success': success,
        'output': output,
        'error': error,
        'elapsedMs': elapsed.inMilliseconds,
        'executedAt': executedAt.toIso8601String(),
      };
}

/// مستوى خطورة الأمر
enum CommandRiskLevel {
  safe,      // قراءة فقط (print, monitor)
  moderate,  // تعديل إعدادات (set, add)
  dangerous, // حذف أو إعادة ضبط (remove, reset, reboot)
}

extension CommandRiskLevelExtension on CommandRiskLevel {
  String get displayName {
    switch (this) {
      case CommandRiskLevel.safe:
        return 'آمن';
      case CommandRiskLevel.moderate:
        return 'متوسط';
      case CommandRiskLevel.dangerous:
        return 'خطير';
    }
  }

  String get warningMessage {
    switch (this) {
      case CommandRiskLevel.safe:
        return 'هذا أمر قراءة فقط — آمن للتنفيذ';
      case CommandRiskLevel.moderate:
        return '⚠️ هذا الأمر يعدّل الإعدادات. تأكد من معرفتك بالتأثير';
      case CommandRiskLevel.dangerous:
        return '🚨 أمر خطير! قد يقطع الاتصال أو يحذف بيانات. كن حذراً جداً';
    }
  }
}

class CommandExecutor {
  CommandExecutor._();

  /// يصنّف الأمر حسب الخطورة
  static CommandRiskLevel classifyRisk(String command) {
    final lower = command.toLowerCase().trim();

    // أوامر خطيرة جداً
    if (lower.contains('reboot') ||
        lower.contains('shutdown') ||
        lower.contains('system reset') ||
        lower.contains('factory-reset') ||
        lower.contains('remove ') ||
        lower.contains('unset ') ||
        (lower.contains('disable ') && lower.contains('ether1'))) {
      return CommandRiskLevel.dangerous;
    }

    // أوامر متوسطة الخطورة (تعديل)
    if (lower.contains('set ') ||
        lower.contains('add ') ||
        lower.contains('enable ') ||
        lower.contains('disable ') ||
        lower.contains('move ') ||
        lower.contains('comment ')) {
      return CommandRiskLevel.moderate;
    }

    // أوامر آمنة (قراءة فقط)
    if (lower.contains('print') ||
        lower.contains('monitor') ||
        lower.contains('export') ||
        (lower.contains('find ') && !lower.contains('remove'))) {
      return CommandRiskLevel.safe;
    }

    // افتراضي: متوسط
    return CommandRiskLevel.moderate;
  }

  /// يتحقق من صحة الأمر (syntax أساسي)
  static String? validateCommand(String command) {
    final trimmed = command.trim();
    if (trimmed.isEmpty) return 'الأمر فارغ';
    if (!trimmed.startsWith('/')) {
      return 'أوامر RouterOS يجب أن تبدأ بـ / (مثال: /interface print)';
    }
    // منع الأوامر التي قد تكون خطرة جداً
    if (trimmed.toLowerCase().contains('/system identity set') &&
        !trimmed.toLowerCase().contains('name=')) {
      return 'أمر /system identity set يتطلب name=...';
    }
    return null; // صحيح
  }

  /// ينفذ أمر RouterOS واحد
  static Future<CommandResult> execute({
    required String command,
    required MikrotikConnectionMethod method,
    Duration timeout = const Duration(seconds: 30),
  }) async {
    final stopwatch = Stopwatch()..start();
    final executedAt = DateTime.now();

    // تحقق من صحة الأمر
    final validationError = validateCommand(command);
    if (validationError != null) {
      stopwatch.stop();
      return CommandResult(
        command: command,
        success: false,
        output: '',
        error: validationError,
        elapsed: stopwatch.elapsed,
        executedAt: executedAt,
      );
    }

    try {
      final String output;
      switch (method) {
        case MikrotikConnectionMethod.routerOS:
          output = await _executeViaRouterOS(command, timeout);
          break;
        case MikrotikConnectionMethod.ssh:
          output = await _executeViaSSH(command, timeout);
          break;
      }

      stopwatch.stop();
      return CommandResult(
        command: command,
        success: true,
        output: output,
        elapsed: stopwatch.elapsed,
        executedAt: executedAt,
      );
    } catch (e) {
      stopwatch.stop();
      return CommandResult(
        command: command,
        success: false,
        output: '',
        error: e.toString(),
        elapsed: stopwatch.elapsed,
        executedAt: executedAt,
      );
    }
  }

  /// ينفذ عدة أوامر بالتسلسل (Script mode)
  static Future<List<CommandResult>> executeBatch({
    required List<String> commands,
    required MikrotikConnectionMethod method,
    Duration perCommandTimeout = const Duration(seconds: 30),
    bool stopOnError = false,
  }) async {
    final results = <CommandResult>[];
    for (final cmd in commands) {
      final result = await execute(
        command: cmd,
        method: method,
        timeout: perCommandTimeout,
      );
      results.add(result);
      if (stopOnError && !result.success) break;
    }
    return results;
  }

  // ============================================================
  //  تنفيذ عبر RouterOS API
  // ============================================================
  static Future<String> _executeViaRouterOS(
      String command, Duration timeout) async {
    final prefs = await SharedPreferences.getInstance();
    final ip = prefs.getString('ip');
    final user = prefs.getString('user');
    // 🔒 قراءة كلمة المرور من flutter_secure_storage
    final pass = await SecureCredentialsStorage.instance.getMikrotikPassword();
    final portStr = prefs.getString('port') ?? '8728';
    final port = int.tryParse(portStr) ?? 8728;

    if (ip == null || user == null || pass == null) {
      throw Exception('بيانات اعتماد MikroTik غير موجودة');
    }

    final client = RouterOSClient(
      address: ip,
      user: user,
      password: pass,
      port: port,
      verbose: false,
    );

    try {
      final ok = await client.login().timeout(const Duration(seconds: 10));
      if (!ok) throw Exception('فشل تسجيل الدخول');

      // تحويل الأمر النصي (بصيغة CLI) إلى صيغة RouterOS API.
      // مثال: "/interface print" → ["/interface/print"]
      //        "/ip address print" → ["/ip/address/print"]
      final args = _toApiSentence(command);
      debugPrint('[CommandExecutor] RouterOS executing: $args');

      final response = await client.talk(args).timeout(timeout);
      final buffer = StringBuffer();
      for (final item in response) {
        final entries = item.entries.where((e) => e.key != '.id' || true);
        buffer.writeln(entries.map((e) => '${e.key}=${e.value}').join('  '));
      }
      return buffer.toString().trim();
    } finally {
      try {
        client.close();
      } catch (_) {}
    }
  }

  // ============================================================
  //  تنفيذ عبر SSH
  // ============================================================
  static Future<String> _executeViaSSH(String command, Duration timeout) async {
    final prefs = await SharedPreferences.getInstance();
    final ip = prefs.getString('ip');
    final user = prefs.getString('user');
    // 🔒 قراءة كلمة المرور من flutter_secure_storage
    final pass = await SecureCredentialsStorage.instance.getMikrotikPassword();
    final portStr = prefs.getString('ssh_port') ?? '22';
    final port = int.tryParse(portStr) ?? 22;

    if (ip == null || user == null || pass == null) {
      throw Exception('بيانات اعتماد MikroTik غير موجودة');
    }

    final socket = await SSHSocket.connect(ip, port, timeout: timeout);
    final client = SSHClient(
      socket,
      username: user,
      onPasswordRequest: () => pass,
    );

    try {
      debugPrint('[CommandExecutor] SSH executing: $command');
      // client.run() يُرجع Uint8List للمخرجات الفعلية.
      // (client.execute() يُرجع SSHSession وليس النص — كان .toString()
      //  يعطي "Instance of 'SSHSession'".)
      final result = await client.run(command).timeout(timeout);
      return utf8.decode(result, allowMalformed: true).trim();
    } finally {
      client.close();
    }
  }

  /// يحوّل أمر RouterOS بصيغة CLI إلى صيغة API التي يقبلها `talk`.
  ///
  /// - المسار والفعل (الكلمات التي لا تحتوي على `=`) تُدمج بشرطة مائلة:
  ///   "/interface print" → "/interface/print"
  /// - الوسائط بصيغة key=value تُمرّر مسبوقة بـ `=`:
  ///   "/ip dns set servers=8.8.8.8" → ["/ip/dns/set", "=servers=8.8.8.8"]
  ///
  /// ملاحظة: الأوامر ذات الوسائط الموضعية (مثل تحديد اسم واجهة بدون key=)
  /// أدق تنفيذاً عبر SSH؛ صيغة API مناسبة أساساً لأوامر القراءة والإعداد بالمفاتيح.
  static List<String> _toApiSentence(String command) {
    final tokens = _parseCommand(command);
    if (tokens.isEmpty) return const [];

    final words = <String>[]; // مكوّنات المسار + الفعل
    final params = <String>[]; // وسائط بصيغة API (=attr=val أو ?query=val)
    var inParams = false;

    for (final token in tokens) {
      final isQuery = token.startsWith('?'); // مُرشِّح استعلام RouterOS
      if (!inParams && !token.contains('=') && !isQuery) {
        words.add(token);
      } else {
        inParams = true;
        // البروتوكول يميّز ?query عن =attribute؛ نُبقي البادئات كما هي
        if (token.startsWith('=') || isQuery) {
          params.add(token);
        } else {
          params.add('=$token');
        }
      }
    }

    // دمج الكلمات بشرطة مائلة مع ضمان بادئة واحدة "/"
    var sentence = words.join('/');
    if (!sentence.startsWith('/')) sentence = '/$sentence';
    sentence = sentence.replaceAll(RegExp(r'/{2,}'), '/');

    return [sentence, ...params];
  }

  /// يحوّل أمر نصي إلى List<String> (احترام علامات الاقتباس)
  static List<String> _parseCommand(String command) {
    final args = <String>[];
    final regex = RegExp(r'''("[^"]*"|'[^']*'|\S+)''');
    for (final match in regex.allMatches(command)) {
      var arg = match.group(1) ?? '';
      // إزالة علامات الاقتباس
      if ((arg.startsWith('"') && arg.endsWith('"')) ||
          (arg.startsWith("'") && arg.endsWith("'"))) {
        arg = arg.substring(1, arg.length - 1);
      }
      args.add(arg);
    }
    return args;
  }
}
