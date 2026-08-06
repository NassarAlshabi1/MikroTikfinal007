// ============================================================
//  MikrotikLogAnalyzer — AI pipeline لتحليل logs من MikroTik RouterOS
//
//  يقوم بـ:
//  1. تجميع الـ logs من /log print (أو من MikrotikSnapshot.logs)
//  2. تصنيف الأحداث حسب النوع (error, warning, info, security, dhcp, ...)
//  3. كشف الأنماط الحرجة (هجمات، فشل اتصال، فقدان حزم، ...)
//  4. إنتاج تقرير قابل للعرض + توصيات
//  5. التكامل مع AiService للتحليل العميق
//  6. التكامل مع OomolMcpClient لتشغيل pipeline سحابي عند الحاجة
//
//  المصادر المستوحاة:
//  - hreskiv/mikr: syslog receiver + threshold alerts
//  - eworm-de/routeros-scripts: patterns جاهزة
//  - Mikrotik-AI-Cloud: AI-driven analysis
// ============================================================

import 'package:flutter/foundation.dart';

import 'command_executor.dart';
import 'diagnostics_models.dart';

/// مستوى خطورة حدث في الـ log
enum LogSeverity {
  critical, // 🔴 خطير جداً
  warning, // 🟡 تحذير
  info, // 🟢 معلومات
  debug, // ⚪ تتبع
}

extension LogSeverityX on LogSeverity {
  String get displayName {
    switch (this) {
      case LogSeverity.critical:
        return 'حرج';
      case LogSeverity.warning:
        return 'تحذير';
      case LogSeverity.info:
        return 'معلومة';
      case LogSeverity.debug:
        return 'تتبع';
    }
  }

  String get emoji {
    switch (this) {
      case LogSeverity.critical:
        return '🔴';
      case LogSeverity.warning:
        return '🟡';
      case LogSeverity.info:
        return '🟢';
      case LogSeverity.debug:
        return '⚪';
    }
  }
}

/// فئة حدث في الـ log
enum LogCategory {
  security, // هجمات، تسجيل دخول فاشل، firewall drops
  system, // إعادة تشغيل، تحديثات، أخطاء kernel
  interface, // وصلة منقطعة، link down/up
  dhcp, // تعارض IP، lease conflicts
  wireless, // roaming، ضعف إشارة
  vpn, // فشل اتصال IPsec/OpenVPN
  routing, // BGP/OSPF flapping، route loss
  hotspot, // login failed، session timeout
  queue, // queue overflow، PCQ issues
  dns, // DNS failures، cache issues
  hardware, // درجة حرارة، voltage، fan
  other, // غير مصنّف
}

extension LogCategoryX on LogCategory {
  String get displayName {
    switch (this) {
      case LogCategory.security:
        return 'أمن';
      case LogCategory.system:
        return 'نظام';
      case LogCategory.interface:
        return 'واجهة';
      case LogCategory.dhcp:
        return 'DHCP';
      case LogCategory.wireless:
        return 'لاسلكي';
      case LogCategory.vpn:
        return 'VPN';
      case LogCategory.routing:
        return 'توجيه';
      case LogCategory.hotspot:
        return 'Hotspot';
      case LogCategory.queue:
        return 'QoS';
      case LogCategory.dns:
        return 'DNS';
      case LogCategory.hardware:
        return 'عتاد';
      case LogCategory.other:
        return 'أخرى';
    }
  }

  String get emoji {
    switch (this) {
      case LogCategory.security:
        return '🛡️';
      case LogCategory.system:
        return '⚙️';
      case LogCategory.interface:
        return '🔗';
      case LogCategory.dhcp:
        return '🌐';
      case LogCategory.wireless:
        return '📶';
      case LogCategory.vpn:
        return '🔐';
      case LogCategory.routing:
        return '🗺️';
      case LogCategory.hotspot:
        return '📡';
      case LogCategory.queue:
        return '📊';
      case LogCategory.dns:
        return '🔤';
      case LogCategory.hardware:
        return '🔌';
      case LogCategory.other:
        return '📌';
    }
  }
}

/// حدث مُحلّل في الـ log
@immutable
class AnalyzedLogEvent {
  final String rawLine;
  final LogSeverity severity;
  final LogCategory category;
  final String topic; // موضوع محدد (مثلاً "Failed SSH login")
  final String? source; // عنوان IP أو interface
  final DateTime? timestamp;
  final String? recommendation; // توصية إصلاح (إن أمكن)
  final List<String> tags; // وسوم إضافية للبحث

  const AnalyzedLogEvent({
    required this.rawLine,
    required this.severity,
    required this.category,
    required this.topic,
    this.source,
    this.timestamp,
    this.recommendation,
    this.tags = const [],
  });
}

/// نتيجة تحليل logs
@immutable
class LogAnalysisResult {
  final List<AnalyzedLogEvent> events;
  final int totalLines;
  final DateTime analyzedAt;
  final Map<LogSeverity, int> severityCounts;
  final Map<LogCategory, int> categoryCounts;
  final List<String> topIssues; // أهم المشاكل المكتشفة
  final List<String> recommendations; // توصيات للإصلاح
  final String summary; // ملخص نصي

  const LogAnalysisResult({
    required this.events,
    required this.totalLines,
    required this.analyzedAt,
    required this.severityCounts,
    required this.categoryCounts,
    required this.topIssues,
    required this.recommendations,
    required this.summary,
  });

  /// عدد الأحداث الحرجة
  int get criticalCount => severityCounts[LogSeverity.critical] ?? 0;

  /// عدد التحذيرات
  int get warningCount => severityCounts[LogSeverity.warning] ?? 0;

  /// هل توجد مشاكل حرجة؟
  bool get hasCriticalIssues => criticalCount > 0;

  /// صحة الـ log (0-100، كلما ارتفع كان أفضل)
  int get healthScore {
    if (totalLines == 0) return 100;
    // معادلة بسيطة: 100 - (critical*5 + warning*1)
    final penalty = (criticalCount * 5) + (warningCount * 1);
    return (100 - penalty).clamp(0, 100);
  }
}

// ============================================================
//  MikrotikLogAnalyzer — المحلل الفعلي
// ============================================================

class MikrotikLogAnalyzer {
  MikrotikLogAnalyzer._();

  // ⚡dart-optimization: تحويل RegExp من local variables إلى static final
  // ليتم ترجمتها مرة واحدة بدل إنشائها لكل سطر (hot path optimization).
  static final RegExp _ipPattern =
      RegExp(r'(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})');
  static final RegExp _timestampPattern =
      RegExp(r'(\w{3})/(\d{1,2})/(\d{4})\s+(\d{2}:\d{2}:\d{2})');
  static const List<String> _months = [
    'jan',
    'feb',
    'mar',
    'apr',
    'may',
    'jun',
    'jul',
    'aug',
    'sep',
    'oct',
    'nov',
    'dec',
  ];

  /// يجمع الـ logs من الراوتر عبر SSH أو RouterOS API
  ///
  /// [maxLines] يحدّ عدد الأسطر (لتفادي إغراق الذاكرة)
  static Future<String> collectLogs({
    MikrotikConnectionMethod method = MikrotikConnectionMethod.routerOS,
    int maxLines = 500,
    Duration timeout = const Duration(seconds: 30),
  }) async {
    // استخدام CommandExecutor لتنفيذ /log print
    // نطلب آخر N سطر (نستخدم print دون detail لتسريع القراءة)
    final result = await CommandExecutor.execute(
      command: '/log print without-paging',
      method: method,
      timeout: timeout,
    );

    if (!result.success) {
      throw Exception('Failed to collect logs: ${result.error}');
    }

    final lines = result.output.split('\n');
    if (lines.length > maxLines) {
      return lines.sublist(lines.length - maxLines).join('\n');
    }
    return result.output;
  }

  /// يحلل نص logs خام ويرجع LogAnalysisResult
  ///
  /// يمكن تمرير logs من MikrotikSnapshot.logs أو من collectLogs()
  static LogAnalysisResult analyze(String rawLogs) {
    final lines =
        rawLogs.split('\n').where((l) => l.trim().isNotEmpty).toList();
    final events = <AnalyzedLogEvent>[];
    final severityCounts = <LogSeverity, int>{};
    final categoryCounts = <LogCategory, int>{};
    final issues = <String>[];
    final recommendations = <String>{};

    for (final line in lines) {
      final event = _analyzeLine(line);
      if (event != null) {
        events.add(event);
        severityCounts[event.severity] =
            (severityCounts[event.severity] ?? 0) + 1;
        categoryCounts[event.category] =
            (categoryCounts[event.category] ?? 0) + 1;
        if (event.recommendation != null) {
          recommendations.add(event.recommendation!);
        }
      }
    }

    // تجميع أهم المشاكل (top 5)
    final groupedIssues = <String, int>{};
    for (final e in events.where((e) =>
        e.severity == LogSeverity.critical ||
        e.severity == LogSeverity.warning)) {
      groupedIssues[e.topic] = (groupedIssues[e.topic] ?? 0) + 1;
    }
    final sortedIssues = groupedIssues.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    issues.addAll(sortedIssues.take(5).map((e) => '${e.key} (${e.value}×)'));

    // بناء الملخص
    final summary = _buildSummary(
      totalLines: lines.length,
      events: events,
      severityCounts: severityCounts,
      categoryCounts: categoryCounts,
    );

    return LogAnalysisResult(
      events: events,
      totalLines: lines.length,
      analyzedAt: DateTime.now(),
      severityCounts: severityCounts,
      categoryCounts: categoryCounts,
      topIssues: issues,
      recommendations: recommendations.toList(),
      summary: summary,
    );
  }

  /// يحلل سطر واحد من الـ log
  static AnalyzedLogEvent? _analyzeLine(String line) {
    final lower = line.toLowerCase();
    String? source;
    List<String> tags = [];

    // ⚡dart-optimization: استخدم الـ patterns المُترجمة مسبقاً
    final ipMatch = _ipPattern.firstMatch(line);
    if (ipMatch != null) {
      source = ipMatch.group(1);
      tags.add('has-ip');
    }

    // استخراج timestamp (مثلاً "jan/15/2024 14:30:45" أو "14:30:45")
    DateTime? ts;
    // ⚡dart-optimization: استخدم الـ pattern المُترجم مسبقاً
    final tsMatch1 = _timestampPattern.firstMatch(line);
    if (tsMatch1 != null) {
      try {
        // MikroTik format: jan/15/2024 14:30:45
        final monthIdx = _months.indexOf(tsMatch1.group(1)!.toLowerCase());
        if (monthIdx >= 0) {
          final day = int.parse(tsMatch1.group(2)!);
          final year = int.parse(tsMatch1.group(3)!);
          final timeParts =
              tsMatch1.group(4)!.split(':').map(int.parse).toList();
          ts = DateTime(year, monthIdx + 1, day, timeParts[0], timeParts[1],
              timeParts[2]);
        }
      } on FormatException {
        // تجاهل أخطاء parse — ليست مهمة
      }
    }

    // ─── تصنيف حسب الكلمات المفتاحية ───

    // 1. SECURITY — هجمات، login فاشل، firewall drops
    if (lower.contains('login failure') ||
        lower.contains('login failed') ||
        lower.contains('failed login') ||
        lower.contains('authentication failed')) {
      return AnalyzedLogEvent(
        rawLine: line,
        severity: LogSeverity.critical,
        category: LogCategory.security,
        topic: 'محاولة تسجيل دخول فاشلة',
        source: source,
        timestamp: ts,
        recommendation:
            'فعّل limit على /ip firewall filter للـ SSH/Winbox/API. '
            'اقتراح: add chain=input protocol=tcp dst-port=22 action=add-src-to-address-list '
            'address-list=ssh_blacklist address-list-timeout=1d',
        tags: ['brute-force', ...tags],
      );
    }

    if (lower.contains('connection from') && lower.contains('denied')) {
      return AnalyzedLogEvent(
        rawLine: line,
        severity: LogSeverity.warning,
        category: LogCategory.security,
        topic: 'اتصال مرفوض',
        source: source,
        timestamp: ts,
        recommendation: 'راجع /ip serviceallowed-addresses',
        tags: tags,
      );
    }

    if (lower.contains('firewall') &&
        (lower.contains('drop') || lower.contains('reject'))) {
      return AnalyzedLogEvent(
        rawLine: line,
        severity: LogSeverity.info,
        category: LogCategory.security,
        topic: 'firewall drop/reject',
        source: source,
        timestamp: ts,
        tags: tags,
      );
    }

    // 2. SYSTEM — reboot, kernel, crash
    if (lower.contains('reboot') || lower.contains('rebooting')) {
      return AnalyzedLogEvent(
        rawLine: line,
        severity: LogSeverity.warning,
        category: LogCategory.system,
        topic: 'إعادة تشغيل',
        timestamp: ts,
        recommendation: 'تحقق من سبب الـ reboot: /system history print',
        tags: tags,
      );
    }

    if (lower.contains('kernel') &&
        (lower.contains('error') || lower.contains('panic'))) {
      return AnalyzedLogEvent(
        rawLine: line,
        severity: LogSeverity.critical,
        category: LogCategory.system,
        topic: 'خطأ في kernel',
        timestamp: ts,
        recommendation:
            'حدّث RouterOS لأحدث إصدار stable. أبلغ عن الـ panic إذا تكرر.',
        tags: tags,
      );
    }

    if (lower.contains('out of memory') || lower.contains('oom')) {
      return AnalyzedLogEvent(
        rawLine: line,
        severity: LogSeverity.critical,
        category: LogCategory.system,
        topic: 'نفاد الذاكرة (OOM)',
        timestamp: ts,
        recommendation:
            'قلّل connection-tracking active-max. راجع /tool profile print.',
        tags: tags,
      );
    }

    // 3. INTERFACE — link down/up
    if (lower.contains('link down') || lower.contains('link is down')) {
      return AnalyzedLogEvent(
        rawLine: line,
        severity: LogSeverity.warning,
        category: LogCategory.interface,
        topic: 'انقطاع وصلة (link down)',
        timestamp: ts,
        recommendation:
            'تحقق من الكابل و PoE. راجع /interface ethernet monitor.',
        tags: tags,
      );
    }

    if (lower.contains('link up') || lower.contains('link is up')) {
      return AnalyzedLogEvent(
        rawLine: line,
        severity: LogSeverity.info,
        category: LogCategory.interface,
        topic: 'استعادة وصلة (link up)',
        timestamp: ts,
        tags: tags,
      );
    }

    // 4. DHCP — conflicts, lease issues
    if (lower.contains('dhcp') &&
        (lower.contains('conflict') || lower.contains('duplicate'))) {
      return AnalyzedLogEvent(
        rawLine: line,
        severity: LogSeverity.warning,
        category: LogCategory.dhcp,
        topic: 'تعارض DHCP',
        source: source,
        timestamp: ts,
        recommendation:
            'فعّل /ip dhcp-server configuration add-conflicts-to-conflict-list=yes',
        tags: tags,
      );
    }

    if (lower.contains('dhcp') && lower.contains('declined')) {
      return AnalyzedLogEvent(
        rawLine: line,
        severity: LogSeverity.warning,
        category: LogCategory.dhcp,
        topic: 'DHCP decline',
        source: source,
        timestamp: ts,
        recommendation: 'تحقق من وجود rogue DHCP server على الشبكة.',
        tags: tags,
      );
    }

    // 5. WIRELESS — signal, roaming
    if (lower.contains('wireless') &&
        (lower.contains('disconnect') || lower.contains('deauth'))) {
      return AnalyzedLogEvent(
        rawLine: line,
        severity: LogSeverity.info,
        category: LogCategory.wireless,
        topic: 'فصل عميل لاسلكي',
        source: source,
        timestamp: ts,
        tags: tags,
      );
    }

    // 6. VPN — IPsec/OpenVPN failures
    if ((lower.contains('ipsec') ||
            lower.contains('openvpn') ||
            lower.contains('l2tp') ||
            lower.contains('sstp')) &&
        (lower.contains('fail') ||
            lower.contains('error') ||
            lower.contains('timeout'))) {
      return AnalyzedLogEvent(
        rawLine: line,
        severity: LogSeverity.warning,
        category: LogCategory.vpn,
        topic: 'فشل اتصال VPN',
        source: source,
        timestamp: ts,
        recommendation:
            'تحقق من مفاتيح IPsec / شهادات OpenVPN / NAT traversal.',
        tags: tags,
      );
    }

    // 7. ROUTING — BGP/OSPF flapping
    if ((lower.contains('bgp') || lower.contains('ospf')) &&
        (lower.contains('down') ||
            lower.contains('lost') ||
            lower.contains('flap'))) {
      return AnalyzedLogEvent(
        rawLine: line,
        severity: LogSeverity.warning,
        category: LogCategory.routing,
        topic: 'BGP/OSPF session flapping',
        source: source,
        timestamp: ts,
        recommendation: 'تحقق من استقرار الوصلة و BFD إن كان مفعّلاً.',
        tags: tags,
      );
    }

    // 8. HOTSPOT — login failed, session timeout
    if (lower.contains('hotspot') &&
        (lower.contains('login') || lower.contains('timeout'))) {
      return AnalyzedLogEvent(
        rawLine: line,
        severity: LogSeverity.info,
        category: LogCategory.hotspot,
        topic: 'حدث Hotspot',
        source: source,
        timestamp: ts,
        tags: tags,
      );
    }

    // 9. HARDWARE — temperature, voltage, fan
    if (lower.contains('temperature') ||
        lower.contains('voltage') ||
        lower.contains('fan')) {
      final sev = lower.contains('high') ||
              lower.contains('critical') ||
              lower.contains('over')
          ? LogSeverity.critical
          : LogSeverity.warning;
      return AnalyzedLogEvent(
        rawLine: line,
        severity: sev,
        category: LogCategory.hardware,
        topic: 'تنبيه عتاد',
        timestamp: ts,
        recommendation:
            'راجع /system health print. تحقق من التهوية ومصدر الطاقة.',
        tags: tags,
      );
    }

    // 10. DNS failures
    if (lower.contains('dns') &&
        (lower.contains('fail') || lower.contains('timeout'))) {
      return AnalyzedLogEvent(
        rawLine: line,
        severity: LogSeverity.warning,
        category: LogCategory.dns,
        topic: 'فشل DNS',
        timestamp: ts,
        recommendation: 'تحقق من /ip dns print + upstream servers.',
        tags: tags,
      );
    }

    // 11. QUEUE overflow
    if (lower.contains('queue') &&
        (lower.contains('overflow') || lower.contains('drop'))) {
      return AnalyzedLogEvent(
        rawLine: line,
        severity: LogSeverity.warning,
        category: LogCategory.queue,
        topic: 'queue overflow',
        timestamp: ts,
        recommendation: 'راجع /queue simple stats. اضبط max-limit أو PCQ.',
        tags: tags,
      );
    }

    // ─── تصنيف عام حسب الكلمات error/warning/info ───
    if (lower.contains('error') || lower.contains('critical')) {
      return AnalyzedLogEvent(
        rawLine: line,
        severity: LogSeverity.critical,
        category: LogCategory.other,
        topic: 'خطأ عام',
        source: source,
        timestamp: ts,
        tags: tags,
      );
    }

    if (lower.contains('warning') || lower.contains('warn')) {
      return AnalyzedLogEvent(
        rawLine: line,
        severity: LogSeverity.warning,
        category: LogCategory.other,
        topic: 'تحذير عام',
        source: source,
        timestamp: ts,
        tags: tags,
      );
    }

    if (lower.contains('info') || lower.contains('message')) {
      return AnalyzedLogEvent(
        rawLine: line,
        severity: LogSeverity.info,
        category: LogCategory.other,
        topic: 'معلومة',
        source: source,
        timestamp: ts,
        tags: tags,
      );
    }

    // سطر غير مصنّف
    return AnalyzedLogEvent(
      rawLine: line,
      severity: LogSeverity.debug,
      category: LogCategory.other,
      topic: 'سطر غير مصنّف',
      source: source,
      timestamp: ts,
      tags: tags,
    );
  }

  /// يبني ملخص نصي قابل للعرض
  static String _buildSummary({
    required int totalLines,
    required List<AnalyzedLogEvent> events,
    required Map<LogSeverity, int> severityCounts,
    required Map<LogCategory, int> categoryCounts,
  }) {
    final buffer = StringBuffer()
      ..writeln('═══════════════════════════════════════')
      ..writeln('📊 تقرير تحليل Logs MikroTik')
      ..writeln('═══════════════════════════════════════')
      ..writeln('📦 إجمالي الأسطر: $totalLines')
      ..writeln('🔍 أحداث مُحلّلة: ${events.length}');

    if (events.isNotEmpty) {
      buffer.writeln('───────────────────────────────────────');
      buffer.writeln('⚠️ التوزيع حسب الخطورة:');
      for (final sev in LogSeverity.values) {
        final count = severityCounts[sev] ?? 0;
        if (count > 0) {
          buffer.writeln('   ${sev.emoji} ${sev.displayName}: $count');
        }
      }

      buffer.writeln('───────────────────────────────────────');
      buffer.writeln('📁 التوزيع حسب الفئة:');
      final sortedCats = categoryCounts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      for (final cat in sortedCats) {
        buffer.writeln(
            '   ${cat.key.emoji} ${cat.key.displayName}: ${cat.value}');
      }
    }

    buffer.writeln('═══════════════════════════════════════');
    return buffer.toString();
  }

  /// يحول النتيجة إلى context نصي للـ AI (لتحليل أعمق)
  ///
  /// يُستخدم مع AiService.analyze() لطلب توصيات ذكية
  static String toAiContext(LogAnalysisResult result, {int maxEvents = 30}) {
    final buffer = StringBuffer()
      ..writeln('=== MIKROTIK LOG ANALYSIS (local) ===')
      ..writeln('Total lines: ${result.totalLines}')
      ..writeln('Analyzed events: ${result.events.length}')
      ..writeln('Critical: ${result.criticalCount}')
      ..writeln('Warnings: ${result.warningCount}')
      ..writeln('Health score: ${result.healthScore}/100')
      ..writeln();

    // أهم الأحداث الحرجة
    final criticalEvents = result.events
        .where((e) => e.severity == LogSeverity.critical)
        .take(maxEvents)
        .toList();
    if (criticalEvents.isNotEmpty) {
      buffer.writeln('=== CRITICAL EVENTS (${criticalEvents.length}) ===');
      for (final e in criticalEvents) {
        buffer.writeln(
            '[${e.category.emoji} ${e.category.displayName}] ${e.topic}');
        if (e.source != null) buffer.writeln('  Source: ${e.source}');
        buffer.writeln(
            '  Raw: ${e.rawLine.substring(0, e.rawLine.length > 200 ? 200 : e.rawLine.length)}');
      }
      buffer.writeln();
    }

    // أهم التحذيرات
    final warningEvents = result.events
        .where((e) => e.severity == LogSeverity.warning)
        .take(maxEvents ~/ 2)
        .toList();
    if (warningEvents.isNotEmpty) {
      buffer.writeln('=== WARNING EVENTS (${warningEvents.length}) ===');
      for (final e in warningEvents) {
        buffer.writeln(
            '[${e.category.emoji}] ${e.topic}: ${e.rawLine.substring(0, e.rawLine.length > 150 ? 150 : e.rawLine.length)}');
      }
      buffer.writeln();
    }

    // التوصيات المحلية
    if (result.recommendations.isNotEmpty) {
      buffer.writeln('=== LOCAL RECOMMENDATIONS ===');
      for (final r in result.recommendations) {
        buffer.writeln('• $r');
      }
    }

    buffer.writeln('=== END ANALYSIS ===');
    return buffer.toString();
  }
}
