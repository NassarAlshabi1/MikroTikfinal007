import 'dart:async';
import 'dart:io';

import 'package:dart_ping/dart_ping.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'network_map_screen.dart';
import 'rogue_dhcp_detector_screen.dart';

enum DiagnosticStatus { idle, running, success, warning, failure }

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

  int get _total => _tests.length;
  int get _successCount => _tests.where((t) => t.status == DiagnosticStatus.success).length;
  int get _warningCount => _tests.where((t) => t.status == DiagnosticStatus.warning).length;
  int get _failureCount => _tests.where((t) => t.status == DiagnosticStatus.failure).length;

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
      for (final test in _tests) {
        test.status = DiagnosticStatus.idle;
        test.message = null;
        test.latencyMs = null;
      }
    });
    for (final test in _tests) {
      await _executeTest(test);
    }
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
