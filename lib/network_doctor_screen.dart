import 'dart:async';
import 'dart:io';
import 'package:dart_ping/dart_ping.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:share_plus/share_plus.dart';

import 'features/diagnostics/domain/latency_metrics.dart';
import 'network_map_screen.dart';
import 'rogue_dhcp_detector_screen.dart';

import 'theme/app_theme.dart';

enum DiagnosticStatus { pending, running, success, warning, error }

enum SeverityLevel { info, low, medium, high }

class NetworkRecommendation {
  final String title;
  final String description;
  final SeverityLevel severity;
  final IconData icon;
  final List<String> steps;
  bool expanded;

  NetworkRecommendation({
    required this.title,
    required this.description,
    required this.severity,
    required this.icon,
    required this.steps,
    this.expanded = false,
  });
}

class _NetworkDiagnostic {
  final String id;
  final String title;
  final String description;
  DiagnosticStatus status;
  String message;
  double? latencyMs;
  LatencyMetrics? latencyMetrics;
  double? downloadSpeedMbps;
  double? uploadSpeedMbps;
  DateTime? checkedAt;

  _NetworkDiagnostic({
    required this.id,
    required this.title,
    required this.description,
    // ignore: unused_element_parameter
    this.status = DiagnosticStatus.pending,
    // ignore: unused_element_parameter
    this.message = 'لم يتم الفحص بعد',
    // ignore: unused_element_parameter
    this.latencyMs,
    // ignore: unused_element_parameter
    this.downloadSpeedMbps,
    // ignore: unused_element_parameter
    this.uploadSpeedMbps,
  });
}

class NetworkDoctorScreen extends StatefulWidget {
  const NetworkDoctorScreen({super.key});

  @override
  State<NetworkDoctorScreen> createState() => _NetworkDoctorScreenState();
}

class _NetworkDoctorScreenState extends State<NetworkDoctorScreen>
    with SingleTickerProviderStateMixin {
  late final Dio _dio;
  late final TabController _tabController;
  bool _isRunningAll = false;
  String? _gatewayIp;
  final List<_NetworkDiagnostic> _tests = [
    _NetworkDiagnostic(
      id: 'gateway',
      title: 'اتصال الراوتر',
      description: 'التحقق من الوصول إلى البوابة الافتراضية',
    ),
    _NetworkDiagnostic(
      id: 'internet',
      title: 'اتصال الإنترنت الخارجي',
      description: 'التحقق من الوصول إلى الإنترنت',
    ),
    _NetworkDiagnostic(
      id: 'dns',
      title: 'فحص DNS',
      description: 'التحقق من القدرة على حل أسماء النطاقات',
    ),
    _NetworkDiagnostic(
      id: 'latency',
      title: 'زمن الاستجابة وجودة الاتصال',
      description: 'قياس المتوسط والتذبذب وفقد الحزم عبر أربع محاولات',
    ),
    _NetworkDiagnostic(
      id: 'speed_test',
      title: 'اختبار سرعة الإنترنت',
      description: 'قياس سرعة التحميل والرفع الفعلية',
    ),
  ];

  final List<NetworkRecommendation> _recommendations = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        sendTimeout: const Duration(seconds: 15),
      ),
    );
    _resolveGateway();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _dio.close();
    super.dispose();
  }

  Future<void> _resolveGateway() async {
    try {
      final gw = await NetworkInfo().getWifiGatewayIP();
      if (mounted) setState(() => _gatewayIp = gw);
    } catch (_) {}
  }

  Future<void> _runAll() async {
    if (!mounted || _isRunningAll || _isAnyTestRunning) return;
    setState(() {
      _isRunningAll = true;
      _clearTestData();
    });
    for (final test in _tests) {
      if (!mounted) return;
      if (test.id == 'speed_test') {
        final proceed = await _confirmSpeedTest();
        if (!mounted) return;
        if (proceed != true) continue;
      }
      await _executeTest(test);
    }
    if (!mounted) return;
    _generateRecommendations();
    setState(() => _isRunningAll = false);
    _tabController.animateTo(1);
  }

  Future<void> _executeTest(_NetworkDiagnostic test) async {
    _updateTest(test.id, DiagnosticStatus.running, 'جاري الفحص...');
    _generateRecommendations();
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
        case 'speed_test':
          await _checkSpeedTest(test);
          break;
        default:
          _updateTest(test.id, DiagnosticStatus.error, 'فحص غير معروف');
      }
    } catch (e) {
      _updateTest(
        test.id,
        DiagnosticStatus.error,
        'فشل الفحص: ${e.toString()}',
      );
    } finally {
      _generateRecommendations();
    }
  }

  void _updateTest(String id, DiagnosticStatus status, String message) {
    if (!mounted) return;
    setState(() {
      final index = _tests.indexWhere((test) => test.id == id);
      if (index == -1) return;

      final test = _tests[index];
      test.status = status;
      test.message = message;
      test.checkedAt = status == DiagnosticStatus.running
          ? null
          : DateTime.now();
      if (status == DiagnosticStatus.running && id == 'latency') {
        test.latencyMs = null;
        test.latencyMetrics = null;
      }
      if (status == DiagnosticStatus.running && id == 'speed_test') {
        test.downloadSpeedMbps = null;
        test.uploadSpeedMbps = null;
      }
    });
  }

  void _updateTestWithSpeed(
    String id,
    DiagnosticStatus status,
    String message, {
    double? downloadSpeed,
    double? uploadSpeed,
  }) {
    if (!mounted) return;
    setState(() {
      final index = _tests.indexWhere((test) => test.id == id);
      if (index != -1) {
        _tests[index].status = status;
        _tests[index].message = message;
        _tests[index].downloadSpeedMbps = downloadSpeed;
        _tests[index].uploadSpeedMbps = uploadSpeed;
        _tests[index].checkedAt = DateTime.now();
      }
    });
  }

  Future<void> _checkGateway(_NetworkDiagnostic test) async {
    final gw = _gatewayIp;
    if (gw == null || gw.isEmpty) {
      throw Exception('تعذر تحديد بوابة الشبكة');
    }
    final p = Ping(gw, count: 2, timeout: 2);
    double success = 0;
    await for (final r in p.stream) {
      if (r.response != null) success += 1;
    }
    if (success >= 1) {
      _updateTest(
        test.id,
        DiagnosticStatus.success,
        'تم الوصول إلى البوابة $gw',
      );
    } else {
      _updateTest(
        test.id,
        DiagnosticStatus.error,
        'تعذر الوصول إلى البوابة $gw',
      );
    }
  }

  Future<void> _checkInternet(_NetworkDiagnostic test) async {
    try {
      final r = await _dio.get('https://www.google.com/generate_204');
      if (r.statusCode == 204 || r.statusCode == 200) {
        _updateTest(
          test.id,
          DiagnosticStatus.success,
          'الاتصال بالإنترنت يعمل',
        );
      } else {
        _updateTest(
          test.id,
          DiagnosticStatus.warning,
          'استجابة غير متوقعة من الإنترنت',
        );
      }
    } on DioException catch (e) {
      _updateTest(
        test.id,
        DiagnosticStatus.error,
        'لا يوجد اتصال بالإنترنت: ${e.message}',
      );
    }
  }

  Future<void> _checkDns(_NetworkDiagnostic test) async {
    try {
      final result = await InternetAddress.lookup('google.com');
      if (result.isNotEmpty && result.first.rawAddress.isNotEmpty) {
        _updateTest(test.id, DiagnosticStatus.success, 'خادم DNS يعمل');
      } else {
        _updateTest(
          test.id,
          DiagnosticStatus.warning,
          'لا يمكن حل أسماء النطاقات',
        );
      }
    } catch (e) {
      _updateTest(
        test.id,
        DiagnosticStatus.error,
        'فشل فحص DNS: ${e.toString()}',
      );
    }
  }

  Future<void> _checkLatency(_NetworkDiagnostic test) async {
    const packetsSent = 4;
    final ping = Ping('1.1.1.1', count: packetsSent, timeout: 2);
    final samplesMs = <double>[];

    await for (final result in ping.stream) {
      final roundTrip = result.response?.time;
      if (roundTrip != null) {
        samplesMs.add(roundTrip.inMicroseconds / 1000);
      }
    }

    final metrics = LatencyMetrics.fromSamples(
      samplesMs,
      packetsSent: packetsSent,
    );
    if (metrics.averageMs == null) {
      _updateLatencyTest(
        test,
        DiagnosticStatus.error,
        'لم يصل أي رد من خادم القياس؛ فقد الحزم 100%.',
        metrics,
      );
      return;
    }

    final average = metrics.averageMs!;
    final packetLoss = metrics.packetLossPercent ?? 0;
    final jitter = metrics.jitterMs ?? 0;
    final status = average > 150 || packetLoss >= 25 || jitter >= 30
        ? DiagnosticStatus.warning
        : DiagnosticStatus.success;
    final message =
        'المتوسط ${average.toStringAsFixed(1)} مللي ثانية؛ فقد الحزم ${packetLoss.toStringAsFixed(0)}%';
    _updateLatencyTest(test, status, message, metrics);
  }

  void _updateLatencyTest(
    _NetworkDiagnostic test,
    DiagnosticStatus status,
    String message,
    LatencyMetrics metrics,
  ) {
    if (!mounted) return;
    setState(() {
      test.latencyMs = metrics.averageMs;
      test.latencyMetrics = metrics;
      test.status = status;
      test.message = message;
      test.checkedAt = DateTime.now();
    });
  }

  Future<void> _checkSpeedTest(_NetworkDiagnostic test) async {
    const downloadTestUrl =
        'https://speed.cloudflare.com/__down?bytes=10000000';
    const uploadTestUrl = 'https://speed.cloudflare.com/__up';

    // إنشاء Dio instance منفصل مع timeout أطول لاختبار السرعة
    final speedTestDio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 60),
        sendTimeout: const Duration(seconds: 60),
      ),
    );

    try {
      final downloadStopwatch = Stopwatch()..start();
      final downloadResponse = await speedTestDio.get(
        downloadTestUrl,
        options: Options(responseType: ResponseType.bytes),
      );
      downloadStopwatch.stop();

      final downloadBytes = (downloadResponse.data as List<int>).length;
      final downloadTimeSeconds =
          downloadStopwatch.elapsedMicroseconds / 1000000;
      if (downloadBytes == 0 || downloadTimeSeconds == 0) {
        throw Exception('لم تصل بيانات كافية لحساب سرعة التحميل');
      }
      final downloadSpeedMbps =
          (downloadBytes * 8 / downloadTimeSeconds) / 1000000;

      final uploadData = Uint8List(5000000);
      final uploadStopwatch = Stopwatch()..start();
      await speedTestDio.post(
        uploadTestUrl,
        data: uploadData,
        options: Options(headers: {'Content-Type': 'application/octet-stream'}),
      );
      uploadStopwatch.stop();

      final uploadBytes = uploadData.length;
      final uploadTimeSeconds = uploadStopwatch.elapsedMicroseconds / 1000000;
      if (uploadTimeSeconds == 0) {
        throw Exception('لم يصل رد كافٍ لحساب سرعة الرفع');
      }
      final uploadSpeedMbps = (uploadBytes * 8 / uploadTimeSeconds) / 1000000;

      final message =
          'التحميل: ${downloadSpeedMbps.toStringAsFixed(2)} Mbps\nالرفع: ${uploadSpeedMbps.toStringAsFixed(2)} Mbps';
      final status = downloadSpeedMbps < 1.0
          ? DiagnosticStatus.warning
          : DiagnosticStatus.success;

      _updateTestWithSpeed(
        test.id,
        status,
        message,
        downloadSpeed: downloadSpeedMbps,
        uploadSpeed: uploadSpeedMbps,
      );
    } catch (e) {
      throw Exception('فشل اختبار السرعة: ${e.toString()}');
    } finally {
      speedTestDio.close();
    }
  }

  void _generateRecommendations() {
    _recommendations.clear();
    final gateway = _tests.firstWhere((t) => t.id == 'gateway');
    final internet = _tests.firstWhere((t) => t.id == 'internet');
    final dns = _tests.firstWhere((t) => t.id == 'dns');
    final latency = _tests.firstWhere((t) => t.id == 'latency');
    final speedTest = _tests.firstWhere((t) => t.id == 'speed_test');

    if (gateway.status == DiagnosticStatus.error) {
      _recommendations.add(
        NetworkRecommendation(
          title: 'تعذر الوصول إلى الراوتر',
          description:
              'لا يمكن الاتصال بالبوابة الافتراضية${_gatewayIp != null ? ' ($_gatewayIp)' : ''}.',
          severity: SeverityLevel.high,
          icon: Icons.router,
          steps: [
            'تحقق من اتصالك بشبكة Wi‑Fi',
            'تأكد من عنوان IP للبوابة',
            'أعد تشغيل الراوتر',
            'تحقق من الكابلات والتوصيلات',
          ],
        ),
      );
    }

    if (internet.status == DiagnosticStatus.error) {
      _recommendations.add(
        NetworkRecommendation(
          title: 'لا يوجد اتصال بالإنترنت',
          description: 'تعذر الوصول إلى الإنترنت من الشبكة الحالية.',
          severity: SeverityLevel.high,
          icon: Icons.public_off,
          steps: [
            'تحقق من حالة الاشتراك لدى مزود الخدمة',
            'أعد تشغيل المودم والراوتر',
            'تحقق من وجود انقطاع عام في المنطقة',
          ],
        ),
      );
    }

    if (dns.status == DiagnosticStatus.error ||
        dns.status == DiagnosticStatus.warning) {
      _recommendations.add(
        NetworkRecommendation(
          title: 'مشكلة في DNS',
          description: 'قد لا تعمل خدمة حل أسماء النطاقات بالشكل الصحيح.',
          severity: SeverityLevel.medium,
          icon: Icons.dns,
          steps: [
            'جرّب استخدام خوادم DNS عامة مثل 1.1.1.1 أو 8.8.8.8',
            'تحقق من إعدادات DNS على الراوتر',
          ],
        ),
      );
    }

    final latencyMetrics = latency.latencyMetrics;
    final packetLoss = latencyMetrics?.packetLossPercent;
    if (packetLoss != null && packetLoss >= 25) {
      _recommendations.add(
        NetworkRecommendation(
          title: 'فقد حزم في الاتصال',
          description:
              'فُقد ${packetLoss.toStringAsFixed(0)}% من حزم اختبار الاتصال؛ قد يسبب ذلك تقطعاً أو تأخراً.',
          severity: packetLoss >= 50
              ? SeverityLevel.high
              : SeverityLevel.medium,
          icon: Icons.network_check,
          steps: [
            'أعد الاختبار قرب الراوتر ثم عبر اتصال سلكي إن أمكن.',
            'تحقق من الكابل أو جودة إشارة Wi‑Fi والتداخل اللاسلكي.',
            'أوقف مؤقتاً التنزيلات الكثيفة وأعد الاختبار للمقارنة.',
          ],
        ),
      );
    }

    final jitter = latencyMetrics?.jitterMs;
    if (jitter != null && jitter >= 30) {
      _recommendations.add(
        NetworkRecommendation(
          title: 'تذبذب في زمن الاستجابة',
          description:
              'متوسط التغير بين الردود ${jitter.toStringAsFixed(1)} مللي ثانية؛ قد يؤثر على المكالمات والألعاب.',
          severity: SeverityLevel.medium,
          icon: Icons.multiline_chart,
          steps: [
            'أعد الاختبار أكثر من مرة في أوقات مختلفة.',
            'قارن النتيجة بين Wi‑Fi والاتصال السلكي.',
            'تحقق من ازدحام الشبكة والأجهزة التي ترفع أو تنزّل البيانات.',
          ],
        ),
      );
    }

    if (latency.latencyMs != null) {
      if (latency.latencyMs! > 150) {
        _recommendations.add(
          NetworkRecommendation(
            title: 'زمن استجابة مرتفع',
            description:
                'المتوسط ${latency.latencyMs!.toStringAsFixed(0)} مللي ثانية أعلى من المتوقع.',
            severity: SeverityLevel.medium,
            icon: Icons.punch_clock,
            steps: [
              'تحقق من الأجهزة التي قد تستهلك النطاق بشكل كبير',
              'جرّب إعادة تشغيل الراوتر',
              'اختبر الكابل أو شبكة الـ Wi‑Fi',
            ],
          ),
        );
      } else if (latency.latencyMs! <= 50 &&
          (packetLoss == null || packetLoss < 25) &&
          (jitter == null || jitter < 30)) {
        _recommendations.add(
          NetworkRecommendation(
            title: 'زمن استجابة ممتاز',
            description:
                'المتوسط ${latency.latencyMs!.toStringAsFixed(0)} مللي ثانية مناسب للألعاب والبث.',
            severity: SeverityLevel.info,
            icon: Icons.speed,
            steps: ['لا توجد إجراءات مطلوبة'],
          ),
        );
      }
    }

    if (speedTest.id == 'speed_test' && speedTest.downloadSpeedMbps != null) {
      if (speedTest.downloadSpeedMbps! < 1.0) {
        _recommendations.add(
          NetworkRecommendation(
            title: 'سرعة إنترنت بطيئة جداً',
            description:
                'سرعة التحميل ${speedTest.downloadSpeedMbps!.toStringAsFixed(2)} Mbps أقل من المتوقع بكثير.',
            severity: SeverityLevel.high,
            icon: Icons.slow_motion_video,
            steps: [
              'تحقق من عدد الأجهزة المتصلة بالشبكة',
              'أعد تشغيل الراوتر والمودم',
              'افحص إذا كان هناك تطبيقات تستهلك النطاق الترددي',
              'اتصل بمزود الخدمة للتحقق من سرعة الباقة',
              'تأكد من عدم وجود مشاكل في الكابلات',
            ],
          ),
        );
      } else if (speedTest.downloadSpeedMbps! >= 10.0) {
        _recommendations.add(
          NetworkRecommendation(
            title: 'سرعة إنترنت ممتازة',
            description:
                'سرعة التحميل ${speedTest.downloadSpeedMbps!.toStringAsFixed(2)} Mbps جيدة للتصفح والبث.',
            severity: SeverityLevel.info,
            icon: Icons.speed,
            steps: [
              'يمكنك الاستمتاع ببث الفيديو بجودة عالية',
              'سرعة مناسبة للألعاب عبر الإنترنت',
              'التحميلات ستكون سريعة',
            ],
          ),
        );
      }
    }
    if (mounted) setState(() {});
  }

  Future<bool?> _confirmSpeedTest() {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تحذير اختبار السرعة'),
        content: const Text(
          'سيتم استهلاك نحو 15 ميجابايت (10 للتحميل و5 للرفع). هل تريد المتابعة؟',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('متابعة'),
          ),
        ],
      ),
    );
  }

  int get _countSuccess =>
      _tests.where((t) => t.status == DiagnosticStatus.success).length;
  int get _countWarning =>
      _tests.where((t) => t.status == DiagnosticStatus.warning).length;
  int get _countError =>
      _tests.where((t) => t.status == DiagnosticStatus.error).length;
  int get _countPending =>
      _tests.where((t) => t.status == DiagnosticStatus.pending).length;
  int get _countCompleted => _tests
      .where(
        (test) =>
            test.status == DiagnosticStatus.success ||
            test.status == DiagnosticStatus.warning ||
            test.status == DiagnosticStatus.error,
      )
      .length;

  Color _statusColor(DiagnosticStatus s) {
    switch (s) {
      case DiagnosticStatus.success:
        return Theme.of(context).appColors.success;
      case DiagnosticStatus.warning:
        return Theme.of(context).appColors.warning;
      case DiagnosticStatus.error:
        return Theme.of(context).appColors.error;
      case DiagnosticStatus.running:
        return Theme.of(context).primaryColor;
      default:
        return Theme.of(context).textTheme.bodyMedium?.color ??
            Theme.of(context).appColors.muted;
    }
  }

  String _statusLabel(DiagnosticStatus s) {
    switch (s) {
      case DiagnosticStatus.success:
        return 'ناجح';
      case DiagnosticStatus.warning:
        return 'تحذير';
      case DiagnosticStatus.error:
        return 'فشل';
      case DiagnosticStatus.running:
        return 'جاري...';
      case DiagnosticStatus.pending:
        return 'بالانتظار';
    }
  }

  String _formatTimestamp(DateTime value) {
    final local = value.toLocal();
    String twoDigits(int number) => number.toString().padLeft(2, '0');

    return '${local.year}-${twoDigits(local.month)}-${twoDigits(local.day)} '
        '${twoDigits(local.hour)}:${twoDigits(local.minute)}';
  }

  String _buildNetworkReport() {
    final gateway = _gatewayIp ?? 'غير متاحة';
    final report = StringBuffer()
      ..writeln('تقرير فحص اتصال الشبكة')
      ..writeln('وقت إعداد التقرير: ${DateTime.now().toLocal()}')
      ..writeln(
        'المصدر: اختبارات اتصال من الهاتف؛ ليست قراءة لإعدادات الراوتر.',
      )
      ..writeln('البوابة: $gateway')
      ..writeln()
      ..writeln('الملخص')
      ..writeln(
        'ناجح: $_countSuccess | تحذير: $_countWarning | فشل: $_countError | لم يُفحص: $_countPending',
      )
      ..writeln()
      ..writeln('تفاصيل الفحوصات');

    for (final test in _tests) {
      report.writeln('- ${test.title}: ${_statusLabel(test.status)}');
      final message = test.message.replaceAll('\n', '\n  ');
      report.writeln('  $message');
      if (test.checkedAt != null) {
        report.writeln('  وقت الفحص: ${_formatTimestamp(test.checkedAt!)}');
      }
      if (test.latencyMetrics != null) {
        report.writeln('  ${_formatLatencyMetrics(test.latencyMetrics!)}');
      }
      if (test.downloadSpeedMbps != null || test.uploadSpeedMbps != null) {
        final download =
            test.downloadSpeedMbps?.toStringAsFixed(2) ?? 'غير متاح';
        final upload = test.uploadSpeedMbps?.toStringAsFixed(2) ?? 'غير متاح';
        report.writeln('  التحميل: $download Mbps | الرفع: $upload Mbps');
      }
    }

    report.writeln();
    report.writeln('التوصيات');
    if (_recommendations.isEmpty) {
      final hasIncompleteTests = _countPending > 0 || _isAnyTestRunning;
      final hasAlerts = _countWarning > 0 || _countError > 0;
      report.writeln(
        !_hasCompletedTest
            ? 'لا توجد نتائج مكتملة بعد؛ شغّل الفحوصات قبل استخلاص نتيجة.'
            : hasIncompleteTests
            ? 'لا توجد توصيات نهائية بعد؛ ما زالت فحوصات غير مكتملة.'
            : hasAlerts
            ? 'لم تُنشأ توصيات تلقائية؛ راجع حالات التحذير أو الفشل.'
            : 'اكتملت الفحوصات دون توصيات.',
      );
    } else {
      for (final recommendation in _recommendations) {
        report.writeln(
          '- ${recommendation.title}: ${recommendation.description}',
        );
        for (final step in recommendation.steps) {
          report.writeln('  • $step');
        }
      }
    }

    return report.toString().trim();
  }

  Future<void> _copyNetworkReport() async {
    try {
      await Clipboard.setData(ClipboardData(text: _buildNetworkReport()));
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('تم نسخ تقرير فحص الشبكة.')));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('تعذر نسخ تقرير الفحص.')));
    }
  }

  Future<void> _shareNetworkReport() async {
    try {
      await SharePlus.instance.share(
        ShareParams(text: _buildNetworkReport(), subject: 'تقرير فحص الشبكة'),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('تعذر مشاركة تقرير الفحص.')));
    }
  }

  void _clearTestData() {
    for (final test in _tests) {
      test.status = DiagnosticStatus.pending;
      test.message = 'لم يتم الفحص بعد';
      test.latencyMs = null;
      test.latencyMetrics = null;
      test.downloadSpeedMbps = null;
      test.uploadSpeedMbps = null;
      test.checkedAt = null;
    }
    _recommendations.clear();
  }

  void _resetResults() {
    setState(_clearTestData);
    _tabController.animateTo(0);
  }

  String _formatLatencyMetrics(LatencyMetrics metrics) {
    final details = <String>[];
    final average = metrics.averageMs;
    final minimum = metrics.minimumMs;
    final maximum = metrics.maximumMs;
    final jitter = metrics.jitterMs;
    final packetLoss = metrics.packetLossPercent;

    if (average != null) {
      details.add('المتوسط ${average.toStringAsFixed(1)} مللي ثانية');
    }
    if (minimum != null && maximum != null) {
      details.add(
        'النطاق ${minimum.toStringAsFixed(1)}–${maximum.toStringAsFixed(1)} مللي ثانية',
      );
    }
    if (jitter != null) {
      details.add('التذبذب التقريبي ${jitter.toStringAsFixed(1)} مللي ثانية');
    }
    if (packetLoss != null) {
      details.add(
        'فقد الحزم ${packetLoss.toStringAsFixed(0)}% '
        '(${metrics.packetsReceived}/${metrics.packetsSent})',
      );
    }
    return details.join(' • ');
  }

  bool get _isAnyTestRunning =>
      _tests.any((test) => test.status == DiagnosticStatus.running);

  bool get _hasCompletedTest => _tests.any(
    (test) =>
        test.status == DiagnosticStatus.success ||
        test.status == DiagnosticStatus.warning ||
        test.status == DiagnosticStatus.error,
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'فحص الشبكة',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _isRunningAll || _isAnyTestRunning ? null : _runAll,
            icon: _isRunningAll
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.play_circle_fill),
            tooltip: 'تشغيل جميع الفحوصات',
            color: theme.primaryColor,
          ),
          PopupMenuButton<String>(
            enabled: _hasCompletedTest && !_isRunningAll && !_isAnyTestRunning,
            tooltip: 'تقرير ونتائج الفحص',
            icon: const Icon(Icons.share_outlined),
            onSelected: (action) {
              switch (action) {
                case 'copy':
                  _copyNetworkReport();
                  break;
                case 'share':
                  _shareNetworkReport();
                  break;
                case 'reset':
                  _resetResults();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem<String>(
                value: 'copy',
                child: Text('نسخ التقرير'),
              ),
              const PopupMenuItem<String>(
                value: 'share',
                child: Text('مشاركة التقرير'),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem<String>(
                value: 'reset',
                child: Text('مسح النتائج وإعادة البدء'),
              ),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'الملخص'),
            Tab(text: 'الفحوصات'),
            Tab(text: 'التوصيات والأدوات'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTabPage([
            _buildSummaryCard(),
            const SizedBox(height: 12),
            _buildStatsRow(),
            const SizedBox(height: 12),
            _buildProgressCard(),
            const SizedBox(height: 12),
            _buildSummaryStateCard(),
          ]),
          _buildTabPage([_buildTestsSection()]),
          _buildTabPage([
            _buildRecommendationsSection(),
            const SizedBox(height: 16),
            _buildAdvancedTools(),
          ]),
        ],
      ),
    );
  }

  Widget _buildTabPage(List<Widget> children) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }

  Widget _buildSummaryStateCard() {
    final theme = Theme.of(context);
    final color = _hasCompletedTest
        ? theme.colorScheme.primary
        : theme.colorScheme.onSurfaceVariant;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            _hasCompletedTest ? Icons.fact_check_outlined : Icons.info_outline,
            color: color,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _hasCompletedTest
                  ? 'النتائج أدناه تخص الاختبارات التي شُغّلت على هذا الهاتف.'
                  : 'لم تُشغّل الفحوصات بعد؛ لا تعتبر الحالة سليمة حتى تنفذ اختباراً واحداً على الأقل.',
              style: theme.textTheme.bodySmall?.copyWith(height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
    final theme = Theme.of(context);
    final primary = theme.primaryColor;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            primary.withValues(alpha: 0.6),
            primary.withValues(alpha: 0.3),
          ],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: primary.withValues(alpha: 0.2),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.health_and_safety,
                  color: Theme.of(context).colorScheme.onSurface,
                  size: 36,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ملخص الفحوصات',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'تشخيص شامل لحالة الشبكة',
                      style: TextStyle(
                        color: Theme.of(context).textTheme.bodySmall?.color,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isRunningAll || _isAnyTestRunning ? null : _runAll,
              icon: _isRunningAll
                  ? SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    )
                  : const Icon(Icons.play_arrow),
              label: Text(
                _isRunningAll ? 'جاري التشغيل...' : 'تشغيل جميع الفحوصات',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.2),
                foregroundColor: Theme.of(context).colorScheme.onSurface,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    return Row(
      children: [
        Expanded(
          child: _buildChip(
            'ناجحة',
            _countSuccess.toString(),
            Theme.of(context).appColors.success,
            Icons.check_circle,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildChip(
            'تحذير',
            _countWarning.toString(),
            Theme.of(context).appColors.warning,
            Icons.warning,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildChip(
            'فشل',
            _countError.toString(),
            Theme.of(context).appColors.error,
            Icons.error,
          ),
        ),
      ],
    );
  }

  Widget _buildProgressCard() {
    final theme = Theme.of(context);
    final progress = _tests.isEmpty ? 0.0 : _countCompleted / _tests.length;
    final runningCount = _tests
        .where((test) => test.status == DiagnosticStatus.running)
        .length;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'الفحوصات المكتملة',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text('$_countCompleted/${_tests.length}'),
            ],
          ),
          const SizedBox(height: 10),
          LinearProgressIndicator(value: progress),
          const SizedBox(height: 8),
          Text(
            runningCount > 0
                ? 'جارٍ تنفيذ $runningCount اختبار؛ متبقٍ $_countPending.'
                : 'المتبقي: $_countPending',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChip(String title, String value, Color color, IconData icon) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              color:
                  Theme.of(context).textTheme.bodySmall?.color ??
                  Theme.of(context).textTheme.bodySmall?.color,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTestsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Text(
            'الفحوصات',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color:
                  Theme.of(context).textTheme.titleLarge?.color ??
                  Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ),
        const SizedBox(height: 8),
        ..._tests.map(
          (t) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildTestCard(t),
          ),
        ),
      ],
    );
  }

  Widget _buildTestCard(_NetworkDiagnostic t) {
    final theme = Theme.of(context);
    final color = _statusColor(t.status);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(Icons.network_check, color: color, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t.title,
                      style: TextStyle(
                        color:
                            Theme.of(context).textTheme.titleMedium?.color ??
                            Theme.of(context).colorScheme.onSurface,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      t.description,
                      style: TextStyle(
                        color:
                            Theme.of(context).textTheme.bodySmall?.color ??
                            Theme.of(context).textTheme.bodySmall?.color,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: color.withValues(alpha: 0.5),
                    width: 1,
                  ),
                ),
                child: Text(
                  _statusLabel(t.status),
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (t.id == 'latency' && t.latencyMetrics != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.timer,
                    color:
                        Theme.of(
                          context,
                        ).iconTheme.color?.withValues(alpha: 0.7) ??
                        Theme.of(context).textTheme.bodySmall?.color,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      _formatLatencyMetrics(t.latencyMetrics!),
                      style: TextStyle(
                        color:
                            Theme.of(context).textTheme.bodyMedium?.color ??
                            Theme.of(context).colorScheme.onSurface,
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          if (t.id == 'speed_test' &&
              (t.downloadSpeedMbps != null || t.uploadSpeedMbps != null))
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Icon(
                    Icons.speed,
                    color:
                        Theme.of(
                          context,
                        ).iconTheme.color?.withValues(alpha: 0.7) ??
                        Theme.of(context).textTheme.bodySmall?.color,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'التحميل: ${t.downloadSpeedMbps?.toStringAsFixed(2) ?? '-'} Mbps • الرفع: ${t.uploadSpeedMbps?.toStringAsFixed(2) ?? '-'} Mbps',
                      style: TextStyle(
                        color:
                            Theme.of(context).textTheme.bodyMedium?.color ??
                            Theme.of(context).colorScheme.onSurface,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(10),
            ),
            width: double.infinity,
            child: Text(
              t.message,
              style: TextStyle(
                color:
                    Theme.of(context).textTheme.bodySmall?.color ??
                    Theme.of(context).textTheme.bodySmall?.color,
                fontSize: 13,
              ),
            ),
          ),
          if (t.checkedAt != null) ...[
            const SizedBox(height: 6),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: Text(
                'آخر فحص: ${_formatTimestamp(t.checkedAt!)}',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isRunningAll || _isAnyTestRunning
                      ? null
                      : () async {
                          if (t.id == 'speed_test') {
                            final proceed = await _confirmSpeedTest();
                            if (proceed != true) return;
                          }
                          await _executeTest(t);
                        },
                  icon: t.status == DiagnosticStatus.running
                      ? SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        )
                      : const Icon(Icons.play_arrow, size: 20),
                  label: const Text('تشغيل'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              if (t.id == 'speed_test') ...[
                const SizedBox(width: 10),
                Container(
                  height: 48,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).appColors.warning.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Theme.of(
                        context,
                      ).appColors.warning.withValues(alpha: 0.3),
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Row(
                    children: [
                      Icon(
                        Icons.warning_amber,
                        color: Theme.of(context).appColors.warning,
                        size: 18,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '~15MB',
                        style: TextStyle(
                          color: Theme.of(context).appColors.warning,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationsSection() {
    final hasIncompleteTests = _countPending > 0 || _isAnyTestRunning;
    final allClear =
        _hasCompletedTest &&
        !hasIncompleteTests &&
        _countWarning == 0 &&
        _countError == 0;
    final emptyMessage = !_hasCompletedTest
        ? 'شغّل الفحوصات أولاً لعرض توصيات مبنية على النتائج.'
        : hasIncompleteTests
        ? 'لا توجد توصيات نهائية بعد؛ أكمل الفحوصات المتبقية للحصول على صورة أوضح.'
        : allClear
        ? 'اكتملت الفحوصات دون ظهور مؤشرات تتطلب توصية.'
        : 'لا توجد توصيات تلقائية، لكن راجع حالات التحذير أو الفشل في تبويب الفحوصات.';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Text(
            'التوصيات',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color:
                  Theme.of(context).textTheme.titleLarge?.color ??
                  Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ),
        const SizedBox(height: 8),
        if (_recommendations.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Theme.of(context).dividerColor),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  allClear ? Icons.check_circle : Icons.info_outline,
                  color: allClear
                      ? Theme.of(context).appColors.success
                      : Theme.of(context).appColors.info,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    emptyMessage,
                    style: TextStyle(
                      color:
                          Theme.of(context).textTheme.bodyMedium?.color ??
                          Theme.of(context).colorScheme.onSurface,
                      fontSize: 15,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ..._recommendations.map(
          (r) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildRecommendationCard(r),
          ),
        ),
      ],
    );
  }

  Widget _buildRecommendationCard(NetworkRecommendation r) {
    final theme = Theme.of(context);
    Color sevColor;
    String severityLabel;

    switch (r.severity) {
      case SeverityLevel.high:
        sevColor = Theme.of(context).appColors.error;
        severityLabel = 'عاجل';
        break;
      case SeverityLevel.medium:
        sevColor = Theme.of(context).appColors.warning;
        severityLabel = 'متوسط';
        break;
      case SeverityLevel.low:
        sevColor = Theme.of(context).appColors.warning;
        severityLabel = 'منخفض';
        break;
      case SeverityLevel.info:
        sevColor = Theme.of(context).appColors.info;
        severityLabel = 'معلومة';
        break;
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: sevColor.withValues(alpha: 0.4), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: sevColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(r.icon, color: sevColor, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            r.title,
                            style: TextStyle(
                              color:
                                  Theme.of(
                                    context,
                                  ).textTheme.titleMedium?.color ??
                                  Theme.of(context).colorScheme.onSurface,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: sevColor.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            severityLabel,
                            style: TextStyle(
                              color: sevColor,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      r.description,
                      style: TextStyle(
                        color:
                            Theme.of(context).textTheme.bodySmall?.color ??
                            Theme.of(context).textTheme.bodySmall?.color,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () {
                  setState(() => r.expanded = !r.expanded);
                },
                icon: Icon(
                  r.expanded ? Icons.expand_less : Icons.expand_more,
                  color:
                      Theme.of(
                        context,
                      ).iconTheme.color?.withValues(alpha: 0.6) ??
                      Theme.of(context).textTheme.bodySmall?.color,
                ),
              ),
            ],
          ),
          if (r.expanded) ...[
            const SizedBox(height: 16),
            Divider(
              color: Theme.of(context).dividerColor.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 12),
            Text(
              'خطوات الحل:',
              style: TextStyle(
                color:
                    Theme.of(context).textTheme.titleSmall?.color ??
                    Theme.of(context).colorScheme.onSurface,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ...r.steps.asMap().entries.map((entry) {
              final index = entry.key + 1;
              final step = entry.value;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: sevColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '$index',
                        style: TextStyle(
                          color: sevColor,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        step,
                        style: TextStyle(
                          color:
                              Theme.of(context).textTheme.bodyMedium?.color ??
                              Theme.of(context).colorScheme.onSurface,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  Widget _buildAdvancedTools() {
    final theme = Theme.of(context);
    final primary = theme.primaryColor;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Text(
            'أدوات متقدمة',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color:
                  Theme.of(context).textTheme.titleLarge?.color ??
                  Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const NetworkMapScreen(),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(18),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: primary.withValues(alpha: 0.3),
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: primary.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          Icons.hub_outlined,
                          size: 32,
                          color: primary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'خريطة الشبكة',
                        style: TextStyle(
                          color:
                              Theme.of(context).textTheme.titleSmall?.color ??
                              Theme.of(context).colorScheme.onSurface,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: InkWell(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const RogueDhcpDetectorScreen(),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(18),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: Theme.of(
                        context,
                      ).appColors.error.withValues(alpha: 0.3),
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).appColors.error.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          Icons.security,
                          size: 32,
                          color: Theme.of(context).appColors.error,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'كاشف DHCP الدخيل',
                        style: TextStyle(
                          color:
                              Theme.of(context).textTheme.titleSmall?.color ??
                              Theme.of(context).colorScheme.onSurface,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
