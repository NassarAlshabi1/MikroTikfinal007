import 'dart:async';
import 'dart:io';

import 'package:dart_ping/dart_ping.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'network_map_screen.dart';
import 'rogue_dhcp_detector_screen.dart';

enum DiagnosticStatus { idle, running, success, warning, failure }

enum SeverityLevel { info, low, medium, high, critical }

class _NetworkDiagnostic {
  _NetworkDiagnostic({
    required this.id,
    required this.title,
    required this.description,
    this.status = DiagnosticStatus.idle,
    this.message,
    this.latencyMs,
  });

  final String id;
  final String title;
  final String description;
  DiagnosticStatus status;
  String? message;
  double? latencyMs;
}

class NetworkRecommendation {
  NetworkRecommendation({
    required this.title,
    required this.description,
    required this.severity,
    required this.steps,
    this.icon,
    this.action,
    this.actionLabel,
  });

  final String title;
  final String description;
  final SeverityLevel severity;
  final List<String> steps;
  final IconData? icon;
  final VoidCallback? action;
  final String? actionLabel;
}

class NetworkDoctorScreen extends StatefulWidget {
  const NetworkDoctorScreen({super.key});

  @override
  State<NetworkDoctorScreen> createState() => _NetworkDoctorScreenState();
}

class _NetworkDoctorScreenState extends State<NetworkDoctorScreen> {
  final NetworkInfo _networkInfo = NetworkInfo();
  final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 5),
    ),
  );
  late final List<_NetworkDiagnostic> _tests = [
    _NetworkDiagnostic(
      id: 'gateway',
      title: 'اتصال الراوتر',
      description: 'التحقق من الوصول إلى البوابة الرئيسية للشبكة',
    ),
    _NetworkDiagnostic(
      id: 'internet',
      title: 'اتصال الإنترنت الخارجي',
      description: 'التأكد من الوصول إلى الإنترنت عبر بروتوكول HTTP',
    ),
    _NetworkDiagnostic(
      id: 'dns',
      title: 'فحص DNS',
      description: 'اختبار حل أسماء النطاقات إلى عناوين IP',
    ),
    _NetworkDiagnostic(
      id: 'latency',
      title: 'زمن الاستجابة العام',
      description: 'قياس متوسط التأخير مع خادم عالمي',
    ),
  ];
  bool _isRunning = false;
  String? _wifiName;
  String? _wifiBssid;
  String? _wifiIp;
  String? _gatewayIp;

  final List<NetworkRecommendation> _recommendations = [];

  int get _total => _tests.length;
  int get _successCount => _tests.where((t) => t.status == DiagnosticStatus.success).length;
  int get _warningCount => _tests.where((t) => t.status == DiagnosticStatus.warning).length;
  int get _failureCount => _tests.where((t) => t.status == DiagnosticStatus.failure).length;
  bool get _hasIssues => _warningCount > 0 || _failureCount > 0;

  @override
  void initState() {
    super.initState();
    _loadNetworkInfo();
    _runDiagnostics();
  }

  Future<void> _loadNetworkInfo() async {
    final wifiName = await _networkInfo.getWifiName();
    final wifiBssid = await _networkInfo.getWifiBSSID();
    final wifiIp = await _networkInfo.getWifiIP();
    final gatewayIp = await _networkInfo.getWifiGatewayIP();
    if (!mounted) return;
    setState(() {
      _wifiName = wifiName;
      _wifiBssid = wifiBssid;
      _wifiIp = wifiIp;
      _gatewayIp = gatewayIp;
    });
  }

  Future<void> _runDiagnostics() async {
    if (_isRunning) return;
    setState(() {
      _isRunning = true;
      _recommendations.clear();
      for (final test in _tests) {
        test.status = DiagnosticStatus.idle;
        test.message = null;
        test.latencyMs = null;
      }
    });
    for (final test in _tests) {
      await _executeTest(test);
    }
    _generateRecommendations();
    if (!mounted) return;
    setState(() {
      _isRunning = false;
    });
  }

  Future<void> _executeTest(_NetworkDiagnostic test) async {
    _updateTest(test.id, DiagnosticStatus.running, 'جاري الفحص...');
    try {
      switch (test.id) {
        case 'gateway':
          await _checkGateway(test);
          break;
        case 'internet':
          await _checkInternet(test);
          break;
        case 'dns':
          await _checkDns(test);
          break;
        case 'latency':
          await _checkLatency(test);
          break;
        default:
          throw Exception('اختبار غير معروف');
      }
    } catch (e) {
      final message = e is Exception ? e.toString().replaceFirst('Exception: ', '') : e.toString();
      _updateTest(test.id, DiagnosticStatus.failure, 'فشل الاختبار: $message');
    }
  }

  Future<void> _checkGateway(_NetworkDiagnostic test) async {
    var gateway = _gatewayIp;
    gateway ??= await _networkInfo.getWifiGatewayIP();
    if (gateway == null || gateway.isEmpty) {
      _updateTest(test.id, DiagnosticStatus.warning, 'تعذر تحديد عنوان البوابة. تحقق من الاتصال بالشبكة.');
      return;
    }
    final latency = await _pingHost(gateway);
    final label = latency >= 120
        ? 'الزمن مرتفع (${latency.toStringAsFixed(1)} مللي ثانية)'
        : 'استجابة ممتازة (${latency.toStringAsFixed(1)} مللي ثانية)';
    final status = latency >= 120 ? DiagnosticStatus.warning : DiagnosticStatus.success;
    _updateTest(test.id, status, label, latency: latency);
  }

  Future<void> _checkInternet(_NetworkDiagnostic test) async {
    final stopwatch = Stopwatch()..start();
    final response = await _dio.get('https://www.google.com/generate_204');
    stopwatch.stop();
    if (response.statusCode == 204) {
      final latency = stopwatch.elapsedMilliseconds.toDouble();
      final label = latency >= 800
          ? 'الاتصال متاح لكن الاستجابة بطيئة (${latency.toStringAsFixed(0)} مللي ثانية)'
          : 'الاتصال بالإنترنت يعمل (${latency.toStringAsFixed(0)} مللي ثانية)';
      final status = latency >= 800 ? DiagnosticStatus.warning : DiagnosticStatus.success;
      _updateTest(test.id, status, label, latency: latency);
    } else {
      throw Exception('استجابة غير متوقعة من مزود الإنترنت (${response.statusCode})');
    }
  }

  Future<void> _checkDns(_NetworkDiagnostic test) async {
    final addresses = await InternetAddress.lookup('google.com');
    if (addresses.isEmpty) {
      throw Exception('لم يتم العثور على نتيجة لحل google.com');
    }
    final joined = addresses.map((address) => address.address).join(' • ');
    _updateTest(test.id, DiagnosticStatus.success, 'تم الحل بنجاح: $joined');
  }

  Future<void> _checkLatency(_NetworkDiagnostic test) async {
    final latency = await _pingHost('8.8.8.8');
    final label = latency >= 150
        ? 'زمن الاستجابة مرتفع (${latency.toStringAsFixed(1)} مللي ثانية)'
        : 'زمن الاستجابة جيد (${latency.toStringAsFixed(1)} مللي ثانية)';
    final status = latency >= 150 ? DiagnosticStatus.warning : DiagnosticStatus.success;
    _updateTest(test.id, status, label, latency: latency);
  }

  Future<double> _pingHost(String host) async {
    final ping = Ping(host, count: 4, timeout: 2);
    double total = 0;
    int success = 0;
    await for (final event in ping.stream) {
      final response = event.response;
      if (response != null && response.time != null) {
        success += 1;
        total += response.time!.inMilliseconds.toDouble();
      } else if (event.error != null) {
        throw Exception('تعذر الوصول إلى $host');
      }
    }
    if (success == 0) {
      throw Exception('لا توجد استجابة من $host');
    }
    return total / success;
  }

  void _updateTest(String id, DiagnosticStatus status, String message, {double? latency}) {
    if (!mounted) return;
    setState(() {
      final index = _tests.indexWhere((test) => test.id == id);
      if (index != -1) {
        _tests[index].status = status;
        _tests[index].message = message;
        _tests[index].latencyMs = latency;
      }
    });
  }

  void _generateRecommendations() {
    _recommendations.clear();

    final gatewayTest = _tests.firstWhere((t) => t.id == 'gateway');
    final internetTest = _tests.firstWhere((t) => t.id == 'internet');
    final dnsTest = _tests.firstWhere((t) => t.id == 'dns');
    final latencyTest = _tests.firstWhere((t) => t.id == 'latency');

    if (gatewayTest.status == DiagnosticStatus.failure) {
      _recommendations.add(
        NetworkRecommendation(
          title: 'فشل الاتصال بالراوتر',
          description: 'لا يمكن الوصول إلى البوابة الافتراضية. هذه مشكلة خطيرة تمنع اتصالك بالشبكة.',
          severity: SeverityLevel.critical,
          icon: Icons.router,
          steps: [
            'تحقق من أن جهازك متصل بشبكة Wi-Fi',
            'أعد تشغيل الراوتر (افصل الكهرباء لمدة 10 ثوان)',
            'تأكد من أن كابل الإنترنت موصول بشكل صحيح',
            'حاول الاتصال بشبكة Wi-Fi مرة أخرى',
            'إذا استمرت المشكلة، اتصل بمزود الخدمة',
          ],
        ),
      );
    } else if (gatewayTest.status == DiagnosticStatus.warning && gatewayTest.latencyMs != null && gatewayTest.latencyMs! >= 120) {
      _recommendations.add(
        NetworkRecommendation(
          title: 'بطء الاتصال بالراوتر',
          description: 'زمن الاستجابة للراوتر مرتفع (${gatewayTest.latencyMs!.toStringAsFixed(0)} مللي ثانية). قد يؤثر هذا على سرعة الشبكة.',
          severity: SeverityLevel.medium,
          icon: Icons.speed,
          steps: [
            'اقترب من الراوتر لتحسين إشارة Wi-Fi',
            'قلل عدد الأجهزة المتصلة بالراوتر',
            'غير قناة Wi-Fi إلى قناة أقل ازدحاماً',
            'أعد تشغيل الراوتر لتحديث الاتصالات',
            'تحقق من عدم وجود تطبيقات تستهلك النطاق الترددي',
          ],
        ),
      );
    }

    if (internetTest.status == DiagnosticStatus.failure) {
      _recommendations.add(
        NetworkRecommendation(
          title: 'انقطاع الإنترنت',
          description: 'الراوتر يعمل لكن لا يوجد اتصال بالإنترنت الخارجي.',
          severity: SeverityLevel.high,
          icon: Icons.cloud_off,
          steps: [
            'تحقق من أن الراوتر متصل بخط الإنترنت',
            'أعد تشغيل المودم والراوتر بالترتيب',
            'تحقق من حالة اشتراكك مع مزود الخدمة',
            'افحص كابلات الإنترنت من وإلى الراوتر',
            'تواصل مع مزود الخدمة إذا استمرت المشكلة',
          ],
        ),
      );
    } else if (internetTest.status == DiagnosticStatus.warning && internetTest.latencyMs != null && internetTest.latencyMs! >= 800) {
      _recommendations.add(
        NetworkRecommendation(
          title: 'بطء الإنترنت الخارجي',
          description: 'الإنترنت يعمل لكن الاستجابة بطيئة جداً (${internetTest.latencyMs!.toStringAsFixed(0)} مللي ثانية).',
          severity: SeverityLevel.medium,
          icon: Icons.network_check,
          steps: [
            'أغلق التطبيقات التي تستهلك البيانات (تحميلات، فيديو)',
            'افصل الأجهزة غير المستخدمة من الشبكة',
            'تحقق من سرعة الإنترنت في speedtest.net',
            'أعد تشغيل الراوتر لتحديث الاتصال',
            'اتصل بمزود الخدمة إذا كانت السرعة أقل من المتفق عليه',
          ],
        ),
      );
    }

    if (dnsTest.status == DiagnosticStatus.failure) {
      _recommendations.add(
        NetworkRecommendation(
          title: 'مشكلة في DNS',
          description: 'تعذر حل أسماء المواقع إلى عناوين IP. قد لا تتمكن من فتح المواقع.',
          severity: SeverityLevel.high,
          icon: Icons.dns,
          steps: [
            'غيّر DNS الخاص بجهازك إلى 8.8.8.8 (Google)',
            'أو استخدم 1.1.1.1 (Cloudflare) كبديل',
            'أعد تشغيل الراوتر لتحديث إعدادات DNS',
            'امسح ذاكرة DNS المؤقتة على جهازك',
            'تحقق من إعدادات DNS في لوحة تحكم الراوتر',
          ],
          action: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('للتغيير إلى Google DNS: الإعدادات > Wi-Fi > إعدادات متقدمة > DNS'),
                duration: Duration(seconds: 5),
              ),
            );
          },
          actionLabel: 'كيفية تغيير DNS',
        ),
      );
    }

    if (latencyTest.status == DiagnosticStatus.warning && latencyTest.latencyMs != null && latencyTest.latencyMs! >= 150) {
      _recommendations.add(
        NetworkRecommendation(
          title: 'زمن استجابة مرتفع',
          description: 'زمن الاستجابة للخوادم العالمية مرتفع (${latencyTest.latencyMs!.toStringAsFixed(0)} مللي ثانية). قد تواجه بطء في التصفح.',
          severity: SeverityLevel.low,
          icon: Icons.timer,
          steps: [
            'تحقق من قوة إشارة Wi-Fi واقترب من الراوتر',
            'أغلق التطبيقات التي تستخدم الإنترنت في الخلفية',
            'استخدم كابل إيثرنت بدلاً من Wi-Fi إن أمكن',
            'أعد تشغيل جهازك والراوتر',
            'تحقق من عدم وجود تداخل من شبكات Wi-Fi مجاورة',
          ],
        ),
      );
    }

    if (_failureCount == 0 && _warningCount == 0) {
      _recommendations.add(
        NetworkRecommendation(
          title: '✨ الشبكة تعمل بشكل ممتاز!',
          description: 'جميع الاختبارات نجحت. شبكتك في حالة صحية ممتازة.',
          severity: SeverityLevel.info,
          icon: Icons.celebration,
          steps: [
            'استمتع بتصفح سريع ومستقر',
            'يمكنك إجراء الفحص دورياً للتأكد من استمرار الأداء',
            'استخدم أدوات الشبكة المتقدمة لمزيد من التحليل',
          ],
        ),
      );
    } else if (_failureCount == 0 && _warningCount > 0) {
      _recommendations.add(
        NetworkRecommendation(
          title: 'الشبكة تعمل مع بعض التحذيرات',
          description: 'الشبكة متصلة لكن هناك بعض نقاط الضعف التي يمكن تحسينها.',
          severity: SeverityLevel.low,
          icon: Icons.info_outline,
          steps: [
            'راجع التحذيرات أعلاه لمعرفة نقاط التحسين',
            'اتبع الحلول المقترحة لتحسين الأداء',
            'أعد الفحص بعد تطبيق الحلول للتأكد من التحسن',
          ],
        ),
      );
    }

    if (_gatewayIp == null) {
      _recommendations.add(
        NetworkRecommendation(
          title: 'تعذر تحديد البوابة الافتراضية',
          description: 'لم نتمكن من العثور على عنوان البوابة تلقائياً.',
          severity: SeverityLevel.medium,
          icon: Icons.help_outline,
          steps: [
            'تأكد من اتصالك بشبكة Wi-Fi',
            'افتح إعدادات Wi-Fi وتحقق من معلومات الشبكة',
            'ابحث عن "Router" أو "Gateway" في معلومات الشبكة',
            'سجل عنوان البوابة للرجوع إليه لاحقاً',
          ],
        ),
      );
    }

    final avgLatency = _tests.where((t) => t.latencyMs != null).fold<double>(0, (sum, t) => sum + t.latencyMs!) / _tests.where((t) => t.latencyMs != null).length;
    if (!avgLatency.isNaN && avgLatency > 200) {
      _recommendations.add(
        NetworkRecommendation(
          title: 'نصيحة: تحسين الأداء العام',
          description: 'متوسط زمن الاستجابة في شبكتك يبلغ ${avgLatency.toStringAsFixed(0)} مللي ثانية.',
          severity: SeverityLevel.info,
          icon: Icons.tips_and_updates,
          steps: [
            'استخدم نطاق 5GHz بدلاً من 2.4GHz إن كان راوترك يدعمه',
            'قلل المسافة بين جهازك والراوتر',
            'تحديث firmware الراوتر لآخر إصدار',
            'فكّر في ترقية خطة الإنترنت إذا كنت تحتاج سرعة أعلى',
          ],
        ),
      );
    }
  }

  Color _statusColor(DiagnosticStatus status, BuildContext context) {
    switch (status) {
      case DiagnosticStatus.success:
        return const Color(0xFF2E7D32);
      case DiagnosticStatus.warning:
        return const Color(0xFFF9A825);
      case DiagnosticStatus.failure:
        return const Color(0xFFC62828);
      case DiagnosticStatus.running:
        return Theme.of(context).colorScheme.primary;
      case DiagnosticStatus.idle:
        return Colors.grey;
    }
  }

  IconData _statusIcon(DiagnosticStatus status) {
    switch (status) {
      case DiagnosticStatus.success:
        return Icons.check_circle;
      case DiagnosticStatus.warning:
        return Icons.error_outline;
      case DiagnosticStatus.failure:
        return Icons.highlight_off;
      case DiagnosticStatus.running:
        return Icons.autorenew;
      case DiagnosticStatus.idle:
        return Icons.radio_button_unchecked;
    }
  }

  String _statusLabel(DiagnosticStatus status) {
    switch (status) {
      case DiagnosticStatus.success:
        return 'ناجح';
      case DiagnosticStatus.warning:
        return 'تحذير';
      case DiagnosticStatus.failure:
        return 'فشل';
      case DiagnosticStatus.running:
        return 'جاري الفحص';
      case DiagnosticStatus.idle:
        return 'في الانتظار';
    }
  }

  Color _severityColor(SeverityLevel severity) {
    switch (severity) {
      case SeverityLevel.info:
        return const Color(0xFF1976D2);
      case SeverityLevel.low:
        return const Color(0xFFF9A825);
      case SeverityLevel.medium:
        return const Color(0xFFF57C00);
      case SeverityLevel.high:
        return const Color(0xFFD32F2F);
      case SeverityLevel.critical:
        return const Color(0xFF9C27B0);
    }
  }

  IconData _severityIcon(SeverityLevel severity) {
    switch (severity) {
      case SeverityLevel.info:
        return Icons.lightbulb_outline;
      case SeverityLevel.low:
        return Icons.info_outline;
      case SeverityLevel.medium:
        return Icons.warning_amber;
      case SeverityLevel.high:
        return Icons.error_outline;
      case SeverityLevel.critical:
        return Icons.dangerous;
    }
  }

  String _severityLabel(SeverityLevel severity) {
    switch (severity) {
      case SeverityLevel.info:
        return 'نصيحة';
      case SeverityLevel.low:
        return 'منخفض';
      case SeverityLevel.medium:
        return 'متوسط';
      case SeverityLevel.high:
        return 'عالي';
      case SeverityLevel.critical:
        return 'حرج';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('طبيب الشبكة'),
        centerTitle: true,
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: _runDiagnostics,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildNetworkSummaryCard(theme),
              const SizedBox(height: 16),
              _buildStatusChips(theme),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _isRunning ? null : _runDiagnostics,
                icon: _isRunning
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh),
                label: Text(_isRunning ? 'جاري فحص الشبكة...' : 'إعادة فحص الشبكة'),
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
              ),
              const SizedBox(height: 20),
              Text('نتائج الفحص التفصيلية', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              ..._tests.map((test) => _buildDiagnosticCard(test, theme)).toList(),
              if (_recommendations.isNotEmpty) ..[
                const SizedBox(height: 24),
                Row(
                  children: [
                    Icon(Icons.auto_fix_high, color: theme.colorScheme.primary, size: 22),
                    const SizedBox(width: 8),
                    Text(
                      'حلول ذكية مقترحة',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ..._recommendations.map((rec) => _buildRecommendationCard(rec, theme)).toList(),
              ],
              const SizedBox(height: 24),
              Text('أدوات متقدمة', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              _buildAdvancedTools(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNetworkSummaryCard(ThemeData theme) {
    final textColor = theme.textTheme.bodyMedium?.color;
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.network_check, color: theme.colorScheme.primary),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('ملخص الاتصال', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      Text(
                        _wifiName != null ? 'شبكة Wi-Fi: $_wifiName' : 'لم يتم التعرف على شبكة Wi-Fi',
                        style: theme.textTheme.bodyMedium?.copyWith(color: textColor?.withOpacity(0.8)),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _wifiIp != null ? 'عنوان الجهاز: $_wifiIp' : 'لا يوجد عنوان IP محلي متاح',
                        style: theme.textTheme.bodyMedium?.copyWith(color: textColor?.withOpacity(0.8)),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _gatewayIp != null ? 'البوابة: $_gatewayIp' : 'لم يتم تحديد عنوان البوابة',
                        style: theme.textTheme.bodyMedium?.copyWith(color: textColor?.withOpacity(0.8)),
                      ),
                      if (_wifiBssid != null) ...[
                        const SizedBox(height: 4),
                        Text('BSSID: $_wifiBssid', style: theme.textTheme.bodyMedium?.copyWith(color: textColor?.withOpacity(0.8))),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChips(ThemeData theme) {
    final items = [
      {'label': 'ناجحة', 'value': _successCount, 'color': const Color(0xFF2E7D32)},
      {'label': 'تحذيرات', 'value': _warningCount, 'color': const Color(0xFFF9A825)},
      {'label': 'فاشلة', 'value': _failureCount, 'color': const Color(0xFFC62828)},
    ];
    return Row(
      children: [
        Expanded(
          child: Card(
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('إجمالي الاختبارات', style: theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor)),
                      const SizedBox(height: 4),
                      Text('$_total', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  Wrap(
                    spacing: 12,
                    children: items
                        .map(
                          (item) => Chip(
                            backgroundColor: (item['color'] as Color).withOpacity(0.1),
                            label: Text('${item['label']}: ${item['value']}'),
                            labelStyle: TextStyle(color: item['color'] as Color, fontWeight: FontWeight.w600),
                          ),
                        )
                        .toList(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDiagnosticCard(_NetworkDiagnostic test, ThemeData theme) {
    final color = _statusColor(test.status, theme);
    final icon = _statusIcon(test.status);
    final message = test.message;
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(test.title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(test.description, style: theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor)),
                      const SizedBox(height: 8),
                      Text(
                        _statusLabel(test.status),
                        style: theme.textTheme.bodyMedium?.copyWith(color: color, fontWeight: FontWeight.w600),
                      ),
                      if (message != null) ...[
                        const SizedBox(height: 6),
                        Text(
                          message,
                          style: theme.textTheme.bodyMedium?.copyWith(color: theme.textTheme.bodyMedium?.color?.withOpacity(0.85)),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendationCard(NetworkRecommendation rec, ThemeData theme) {
    final color = _severityColor(rec.severity);
    final icon = rec.icon ?? _severityIcon(rec.severity);
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: color.withOpacity(0.3), width: 1.5),
      ),
      margin: const EdgeInsets.only(bottom: 16),
      child: Theme(
        data: theme.copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          leading: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color),
          ),
          title: Text(
            rec.title,
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Text(rec.description, style: theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'الأولوية: ${_severityLabel(rec.severity)}',
                  style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.check_circle_outline, color: color, size: 18),
                      const SizedBox(width: 8),
                      Text('الخطوات المقترحة:', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ...rec.steps.asMap().entries.map((entry) {
                    final index = entry.key;
                    final step = entry.value;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                '${index + 1}',
                                style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              step,
                              style: theme.textTheme.bodyMedium,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                  if (rec.action != null && rec.actionLabel != null) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: rec.action,
                        icon: const Icon(Icons.help_outline, size: 18),
                        label: Text(rec.actionLabel!),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: color,
                          side: BorderSide(color: color),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdvancedTools(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(MaterialPageRoute(builder: (context) => const NetworkMapScreen()));
                    },
                    icon: const Icon(Icons.hub_outlined),
                    label: const Text('خريطة الشبكة'),
                    style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(MaterialPageRoute(builder: (context) => const RogueDhcpDetectorScreen()));
                    },
                    icon: const Icon(Icons.security_outlined),
                    label: const Text('كشف DHCP الدخيل'),
                    style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
