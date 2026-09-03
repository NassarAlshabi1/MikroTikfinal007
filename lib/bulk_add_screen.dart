// bulk_add_screen.dart

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'theme/app_theme.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'providers/mqtt_service_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import 'package:router_os_client/router_os_client.dart';
import 'saved_files_screen.dart';
import 'card_list_screen.dart';
import 'card_generation_jobs_screen.dart';
import 'mqtt_service.dart';
import 'services/bulk_card_generation_service.dart';
import 'services/card_generation_job_service.dart';
import 'services/card_persistence_service.dart';
import 'database/isar/card_generation_job.dart';
import 'services/mikrotik_service_mode.dart';
import 'services/pdf_template_storage.dart';
import 'mikrotik_connector.dart';
import 'pdf_templates_screen.dart';
import 'pdf_generator.dart';
import 'snackbar_helpers.dart';

class BulkAddScreen extends ConsumerStatefulWidget {
  final List<Map<String, dynamic>> profiles;
  final bool isVersion7OrNewer;
  final String username;
  final MikrotikServiceMode serviceMode;

  const BulkAddScreen({
    super.key,
    required this.profiles,
    required this.isVersion7OrNewer,
    required this.username,
    this.serviceMode = MikrotikServiceMode.userManager,
  });

  @override
  ConsumerState<BulkAddScreen> createState() => _BulkAddScreenState();
}

class _BulkAddScreenState extends ConsumerState<BulkAddScreen> {
  final _formKey = GlobalKey<FormState>();

  bool _isGenerating = false;
  double _generationProgress = 0.0;
  String _generationStatusText = '';
  String? _addCardsJobId;
  Timer? _addCardsTimer;
  bool _isJobAcknowledged = false;

  final _prefixController = TextEditingController();
  final _lengthController = TextEditingController(text: '8');
  final _countController = TextEditingController(text: '10');
  final _sharedUsersController = TextEditingController(text: '1');

  String? _selectedProfile;
  String _charType = 'numbers';
  String _cardType = 'username_only';
  bool _linkPasswordToFirstUser = false;

  // القوالب والقالب المختار
  List<PdfTemplate> _templates = [];
  PdfTemplate? _selectedTemplate;

  late MqttService _mqttService;
  StreamSubscription? _mqttSubscription;
  BulkGenerationSession? _generationSession;
  StreamSubscription<GenerationEvent>? _generationSubscription;
  bool _isNetworkLinked = false;
  Map<String, dynamic> _linkedData = {};
  List<Map<String, dynamic>> _availableProfiles = [];
  bool _isLoadingProfiles = false;
  List<Map<String, String>> _reservedGenerationUsers = [];
  String? _generationJobId;
  List<CardGenerationJob> _resumableJobs = const [];

  final String telegramBotToken = '';
  final String telegramChatId = '';

  @override
  void initState() {
    super.initState();
    _availableProfiles = _normalizeProfiles(widget.profiles);
    _checkLinkStatus();
    _loadTemplates();
    unawaited(_initializeLocalBulkData());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _mqttService = ref.read(mqttServiceProvider);
    _setupMqttListener();
  }

  Future<void> _loadTemplates() async {
    try {
      final parsed = await PdfTemplateStorage.load();
      if (mounted) {
        setState(() {
          _templates = parsed;
        });
      }
    } catch (e) {
      debugPrint('[BulkAdd] _loadTemplates error: $e');
    }
  }

  List<Map<String, dynamic>> _normalizeProfiles(
      List<Map<String, dynamic>> profiles) {
    final names = <String>{};
    return profiles
        .map((profile) => Map<String, dynamic>.from(profile))
        .where((profile) {
      final name = profile['name']?.toString().trim() ?? '';
      return name.isNotEmpty && names.add(name);
    }).toList();
  }

  Future<void> _initializeLocalBulkData() async {
    try {
      await CardPersistenceService.cleanupStalePendingCards();
      // يُنهي العمليات العالقة من جلسات سابقة (القفل في الذاكرة فقط، فلا
      // يصمد أمام إغلاق التطبيق) حتى لا تبقى شبحاً قابل للاستئناف في الواجهة.
      await CardGenerationJobService.expireStaleJobs();
      await CardGenerationJobService.deleteOldTerminalJobs();
      final jobs = await CardGenerationJobService.loadResumable();
      if (mounted) setState(() => _resumableJobs = jobs);
    } catch (e) {
      debugPrint('[BulkAdd] local job cleanup error: $e');
    }
    // فئات الكروت مصدرها User Manager في MikroTik؛ القائمة الممررة أو الكاش
    // تستخدم فقط كبيانات أولية/بديلة أثناء تعذر الاتصال.
    await _loadProfilesFromSources();
  }

  Future<void> _loadProfilesFromSources() async {
    // لا نعتمد على profiles القادمة من الشاشة الأم؛ قد تكون قديمة أو محلية.
    final loadedFromRouter = await _loadProfilesFromRouter(showErrors: false);
    if (loadedFromRouter) return;

    try {
      final cachedProfiles = await CardPersistenceService.loadCachedProfiles();
      if (cachedProfiles.isNotEmpty && mounted) {
        setState(() {
          _availableProfiles = _normalizeProfiles(cachedProfiles);
        });
      }
    } catch (e) {
      debugPrint('[BulkAdd] cached profile loading error: $e');
    }
  }

  static const _userManagerProfilesCommand = '/tool/user-manager/profile/print';
  static const _profileSourceLabel = 'User Manager';

  Future<bool> _loadProfilesFromRouter({bool showErrors = true}) async {
    if (_isLoadingProfiles) return false;
    if (mounted) setState(() => _isLoadingProfiles = true);

    RouterOSClient? client;
    try {
      client = await MikrotikConnector.connect();
      final response = await client.talk([
        _userManagerProfilesCommand,
        '=.proplist=.id,name,rate-limit,shared-users,session-timeout',
      ]);
      final profiles = response
          .whereType<Map>()
          .map((profile) => Map<String, dynamic>.from(profile))
          .toList(growable: false);
      final normalizedProfiles = _normalizeProfiles(profiles);

      // لا نمسح القائمة الممررة من الشاشة الأم إذا أعاد الراوتر استجابة فارغة.
      // هذا يحافظ على إمكانية إنشاء الكروت حتى مع صلاحية API جزئية أو راوتر بلا
      // بروفايلات ظاهرة في هذه اللحظة.
      if (normalizedProfiles.isEmpty) return false;

      try {
        await CardPersistenceService.cacheHotspotProfiles(normalizedProfiles);
      } catch (e) {
        debugPrint('[BulkAdd] profile cache error: $e');
      }
      if (mounted) {
        setState(() {
          _availableProfiles = normalizedProfiles;
          if (_selectedProfile != null &&
              !_availableProfiles.any((p) => p['name'] == _selectedProfile)) {
            _selectedProfile = null;
          }
        });
      }
      return true;
    } catch (e) {
      debugPrint('[BulkAdd] profile loading error: $e');
      if (showErrors && mounted) {
        showErrorSnackBar(
          context,
          'تعذر تحميل فئات User Manager من MikroTik: $e',
        );
      }
      return false;
    } finally {
      MikrotikConnector.release(client);
      if (mounted) setState(() => _isLoadingProfiles = false);
    }
  }

  Future<void> _checkLinkStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isLinked = prefs.getBool('is_network_linked') ?? false;
      if (!isLinked) return;
      final dataString = prefs.getString('qahtani_linked_data');
      if (dataString == null) return;
      final decoded = jsonDecode(dataString);
      if (decoded is! Map<String, dynamic>) return;
      if (mounted) {
        setState(() {
          _isNetworkLinked = true;
          _linkedData = decoded;
        });
      }
    } catch (e) {
      debugPrint('[BulkAdd] _checkLinkStatus error: $e');
    }
  }

  void _setupMqttListener() {
    _mqttSubscription?.cancel();
    _mqttSubscription = _mqttService.messages.listen((message) {
      if (!mounted) return;

      final jobId = message['job_id'];
      if (_addCardsJobId == null || jobId != _addCardsJobId) return;

      final status = message['status'];

      switch (status) {
        case 'acknowledged':
          _addCardsTimer?.cancel();
          setState(() {
            _isJobAcknowledged = true;
          });
          Navigator.of(context, rootNavigator: true).pop();
          _showWaitingDialog(
              "تم استلام الطلب، جاري الإضافة إلى م/نصار الشعبي...");
          break;

        case 'job_status_response':
          final jobStatus = message['job_status'];
          if (jobStatus == 'not_found') {
            _addCardsTimer?.cancel();
            Navigator.of(context, rootNavigator: true).pop();
            _showErrorDialog("فشل إرسال الطلب، الرجاء المحاولة مرة أخرى.");
          }
          break;

        case 'cards_added_success':
          _addCardsTimer?.cancel();
          Navigator.of(context, rootNavigator: true).pop();
          showSuccessSnackBar(
              context, message['message'] ?? 'تمت العملية بنجاح.');
          break;

        case 'error':
          _addCardsTimer?.cancel();
          Navigator.of(context, rootNavigator: true).pop();
          _showErrorDialog(message['message'] ?? 'حدث خطأ.');
          break;
      }
    });
  }

  Future<void> _sendTelegramMessage(String message) async {
    final dio = Dio();
    if (telegramBotToken.isEmpty || telegramChatId.isEmpty) return;
    final url = 'https://api.telegram.org/bot$telegramBotToken/sendMessage';
    try {
      await dio.post(url, data: {'chat_id': telegramChatId, 'text': message});
    } catch (e) {
      // print("Failed to send Telegram message: $e");
    }
  }

  Future<void> _generateUsers() async {
    if (_isGenerating) return;
    if (!_formKey.currentState!.validate()) return;

    final count = int.tryParse(_countController.text.trim());
    final length = int.tryParse(_lengthController.text.trim());
    final selectedProfile = _selectedProfile?.trim();
    if (count == null ||
        length == null ||
        selectedProfile == null ||
        selectedProfile.isEmpty) {
      _showErrorDialog('بيانات إنشاء الكروت غير صالحة.');
      return;
    }

    late final MikrotikConnectionConfig connectionConfig;
    try {
      connectionConfig = await MikrotikConnector.loadConnectionConfig();
    } catch (e) {
      if (mounted) _showErrorDialog('تعذر قراءة بيانات اتصال MikroTik: $e');
      return;
    }

    final request = BulkGenerationRequest(
      count: count,
      length: length,
      prefix: _prefixController.text.trim(),
      sharedUsers: _sharedUsersController.text.trim(),
      profileName: selectedProfile,
      charType: _charType,
      cardType: _cardType,
      linkPasswordToFirstUser: _linkPasswordToFirstUser,
      isVersion7OrNewer: widget.isVersion7OrNewer,
      connectionConfig: connectionConfig,
      customer: widget.username,
      serviceMode: widget.serviceMode,
    );

    if (mounted) {
      setState(() {
        _isGenerating = true;
        _generationProgress = 0.0;
        _generationStatusText = 'جاري التحضير...';
      });
    }
    await _startGenerationSession(
        () => BulkCardGenerationService.startNew(request));
  }

  Future<void> _startGenerationSession(
    Future<BulkGenerationSession> Function() start,
  ) async {
    try {
      final session = await start();
      if (!mounted) {
        session.close();
        return;
      }
      _generationSession = session;
      _generationJobId = session.jobId;
      _generationSubscription = session.events.listen(
        (event) => unawaited(_handleGenerationMessage(event)),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isGenerating = false);
      _showErrorDialog('تعذر بدء عملية إنشاء الكروت: $e');
    }
  }

  Future<void> _resumeJob(CardGenerationJob job) async {
    if (_isGenerating) return;
    _selectedProfile = job.profileName;
    if (mounted) {
      setState(() {
        _isGenerating = true;
        _generationProgress = job.requestedCount == 0
            ? 0
            : job.confirmedCount / job.requestedCount;
        _generationStatusText = 'جاري استئناف العملية ${job.jobId}...';
        _resumableJobs =
            _resumableJobs.where((item) => item.id != job.id).toList();
      });
    }
    await _startGenerationSession(
      () => BulkCardGenerationService.resume(
        job,
        fallbackCustomer: widget.username,
      ),
    );
  }

  Future<void> _handleGenerationMessage(dynamic rawMessage) async {
    if (!mounted) return;
    final event = rawMessage is GenerationEvent
        ? rawMessage
        : GenerationEvent.fromRaw(rawMessage);
    final message = <String, dynamic>{
      'type': event.type,
      'users': event.users.map((card) => card.toMap()).toList(growable: false),
      'progress': event.progress,
      'status': event.status,
      'message': event.message,
      'count': event.count,
      'failedCount': event.failedCount,
      'warning': event.warning,
      'address': event.address,
      'resumable': event.resumable,
    };
    final type = event.type;

    if (type == 'prepared') {
      // الحجز وفحص التكرار تمّا داخل الـ Isolate (على نفس الملف مع مزامنة
      // Isar التلقائية). هنا نُسجّل القائمة وحدّث حالة الجوب فقط دون أي
      // عمل Isar ثقيل على Isolate الواجهة — لا انتظار ولا تجمد.
      final users = _usersFromMessage(message['users']);
      if (users.isEmpty) {
        _cleanupGenerationResources();
        if (mounted) {
          setState(() => _isGenerating = false);
          _showErrorDialog('تعذر تجهيز دفعة الكروت محلياً.');
        }
        return;
      }

      _reservedGenerationUsers = users;
      final isResumable = message['resumable'] == true;
      final jobId = _generationJobId;
      if (isResumable) {
        if (jobId != null) {
          await CardGenerationJobService.markRunning(jobId);
        }
      } else if (jobId != null) {
        await CardGenerationJobService.markReady(
          jobId,
          reservedCount: users.length,
          plannedUsers: users,
        );
      }
      if (!mounted) return;
      setState(() {
        _generationStatusText =
            'تم حجز الأسماء محلياً، جاري الإضافة إلى MikroTik...';
      });
      return;
    }

    if (type == 'progress') {
      final progress = (message['progress'] as num?)?.toDouble() ?? 0;
      setState(() {
        // الشاردات تعمل بالتوازي وكل واحد يبلغ عن تقدمه الجزئي؛ نمنع تراجع
        // الشريط حتى لا يتحرك للخلف بين تقارير الشاردات.
        if (progress > _generationProgress) {
          _generationProgress = progress;
        }
        _generationStatusText =
            message['status']?.toString() ?? 'جاري الإنشاء...';
      });
      final jobId = _generationJobId;
      if (jobId != null) {
        // نستخدم التقدم المُقيّد (غير المتراجع) حتى لا يسجل مؤشر الجوب
        // قيماً تنقص بين تقارير الشاردات المتوازية.
        final clamped = _generationProgress;
        final nextIndex = (clamped * _reservedGenerationUsers.length).round();
        unawaited(CardGenerationJobService.markProgress(
          jobId,
          nextIndex: nextIndex,
          lastUsername:
              nextIndex > 0 && nextIndex <= _reservedGenerationUsers.length
                  ? _reservedGenerationUsers[nextIndex - 1]['username']
                  : null,
        ));
      }
      return;
    }

    if (type == 'success') {
      final users = _usersFromMessage(message['users']);
      final successCount = (message['count'] as num?)?.toInt() ?? users.length;
      final failedCount = (message['failedCount'] as num?)?.toInt() ?? 0;
      final warning = message['warning']?.toString() ?? '';
      final address = message['address']?.toString() ?? '';
      final jobId = _generationJobId;
      String? persistenceError;
      var activatedCount = 0;

      try {
        activatedCount = await CardPersistenceService.markGeneratedCardsActive(
          profileName: _selectedProfile!,
          users: users,
          generationJobId: jobId,
        );
        if (activatedCount != users.length) {
          persistenceError =
              'تم تأكيد $activatedCount من أصل ${users.length} كرت في Isar.';
        }
      } catch (e) {
        persistenceError = e.toString();
        debugPrint('[BulkAdd] Isar activation error: $e');
      }

      // تنظيف احتياطي: أي كرت محجوز محلياً لم يؤكده الراوتر (مرفوض/غير
      // مكتمل) يُحذف من pending حتى لا يبقى شبحاً قابلاً للاستئناف. الـ
      // Isolate ينظف عادةً بنفسه؛ هذا شبكة أمان (Web/حالات نادرة).
      if (jobId != null) {
        final confirmedNames =
            users.map((user) => user['username']).whereType<String>().toSet();
        final unconfirmed = _reservedGenerationUsers
            .where((user) => !confirmedNames.contains(user['username']))
            .toList(growable: false);
        if (unconfirmed.isNotEmpty) {
          try {
            await CardPersistenceService.removePendingGeneratedCards(
              unconfirmed,
              generationJobId: jobId,
            );
          } catch (e) {
            debugPrint('[BulkAdd] pending cleanup error: $e');
          }
        }
      }

      if (jobId != null) {
        final existingJob = await CardGenerationJobService.find(jobId);
        final previousConfirmed = existingJob?.confirmedCount ?? 0;
        final totalConfirmed = previousConfirmed + activatedCount;
        if (persistenceError == null) {
          await CardGenerationJobService.markCompleted(
            jobId,
            confirmedCount: totalConfirmed,
          );
        } else {
          await CardGenerationJobService.markPartialFailure(
            jobId,
            confirmedCount: totalConfirmed,
            failedCount:
                (existingJob?.requestedCount ?? users.length) - totalConfirmed,
            error: persistenceError,
          );
        }
      }

      _reservedGenerationUsers = [];
      _cleanupGenerationResources();
      if (!mounted) return;
      setState(() => _isGenerating = false);
      if (persistenceError != null) {
        showErrorSnackBar(context,
            'تمت الإضافة للراوتر لكن توجد مشكلة في تثبيت الحفظ المحلي: $persistenceError');
      } else if (warning.isNotEmpty) {
        showErrorSnackBar(context, warning);
      }

      final telegramMessage = StringBuffer(
        'تم إضافة $successCount كرت جديد بنجاح!\nIP: $address\nالفئة: $_selectedProfile',
      );
      if (failedCount > 0) {
        telegramMessage.write('\nفشل $failedCount كرت.');
      }
      unawaited(_sendTelegramMessage(telegramMessage.toString()));
      if (users.isNotEmpty) {
        await _showSuccessDialog(
          users,
          failedCount: failedCount,
          warning: warning,
        );
      }
      return;
    }

    if (type == 'error') {
      final errorMessage = message['message']?.toString() ?? 'خطأ غير معروف';
      final successCount = (message['count'] as num?)?.toInt() ?? 0;
      final confirmedUsers = _usersFromMessage(message['users']);
      final confirmedNames = confirmedUsers
          .map((user) => user['username'])
          .whereType<String>()
          .toSet();
      final pendingUsers = _reservedGenerationUsers
          .where((user) => !confirmedNames.contains(user['username']))
          .toList(growable: false);
      final jobId = _generationJobId;
      String? persistenceError;
      var activatedCount = 0;

      try {
        if (confirmedUsers.isNotEmpty) {
          activatedCount =
              await CardPersistenceService.markGeneratedCardsActive(
            profileName: _selectedProfile!,
            users: confirmedUsers,
            generationJobId: jobId,
          );
        }
        if (pendingUsers.isNotEmpty) {
          await CardPersistenceService.removePendingGeneratedCards(
            pendingUsers,
            generationJobId: jobId,
          );
        }
      } catch (e) {
        persistenceError = e.toString();
        debugPrint('[BulkAdd] partial Isar cleanup error: $e');
      }

      if (jobId != null) {
        final existingJob = await CardGenerationJobService.find(jobId);
        final previousConfirmed = existingJob?.confirmedCount ?? 0;
        final totalConfirmed = previousConfirmed + activatedCount;
        final requested =
            existingJob?.requestedCount ?? _reservedGenerationUsers.length;
        if (totalConfirmed > 0 || persistenceError != null) {
          await CardGenerationJobService.markPartialFailure(
            jobId,
            confirmedCount: totalConfirmed,
            failedCount: math.max(requested - totalConfirmed, 0),
            error: persistenceError ?? errorMessage,
          );
        } else {
          await CardGenerationJobService.markFailed(
            jobId,
            error: errorMessage,
            confirmedCount: 0,
            failedCount: requested,
          );
        }
      }

      _reservedGenerationUsers = [];
      _cleanupGenerationResources();
      if (!mounted) return;
      setState(() => _isGenerating = false);
      final localMessage = persistenceError == null
          ? ''
          : ' تعذر تنظيف الحجز المحلي: $persistenceError';
      _showErrorDialog(
        'فشلت العملية بعد إنشاء $successCount كرت. الكروت المؤكدة محفوظة محلياً، '
        '$errorMessage$localMessage',
      );
    }
  }

  List<Map<String, String>> _usersFromMessage(dynamic rawUsers) {
    if (rawUsers is! List) return [];
    return rawUsers
        .whereType<Map>()
        .map(
          (user) => <String, String>{
            'username': user['username']?.toString().trim() ?? '',
            'password': user['password']?.toString() ?? '',
            if ((user['mikrotikUserId']?.toString().trim() ?? '').isNotEmpty)
              'mikrotikUserId': user['mikrotikUserId'].toString().trim(),
          },
        )
        .where((user) => user['username']!.isNotEmpty)
        .toList(growable: false);
  }

  Future<void> _cancelGeneration({bool silent = false}) async {
    final session = _generationSession;
    if (!_isGenerating && session == null) return;
    if (session != null) {
      try {
        await BulkCardGenerationService.cancel(
          session,
          pendingCards: _reservedGenerationUsers
              .map(GeneratedCard.fromMap)
              .toList(growable: false),
        );
      } catch (e) {
        debugPrint('[BulkAdd] cancel error: $e');
        session.close();
      }
    }
    _reservedGenerationUsers = [];
    _cleanupGenerationResources();
    if (!silent && mounted) {
      setState(() {
        _isGenerating = false;
        _generationProgress = 0;
        _generationStatusText = 'تم إلغاء العملية.';
      });
      showSuccessSnackBar(
          context, 'تم إلغاء عملية إنشاء الكروت وتنظيف الحجز المحلي.');
    }
  }

  void _cleanupGenerationResources() {
    _generationSubscription?.cancel();
    _generationSubscription = null;
    _generationSession?.close();
    _generationSession = null;
    _generationJobId = null;
  }

  Future<void> _showSuccessDialog(
    List<Map<String, String>> users, {
    int failedCount = 0,
    String warning = '',
  }) async {
    final List<String> userListForFile = users.map((user) {
      if (_cardType == 'username_only') return user['username']!;
      return 'username: ${user['username']}, password: ${user['password']}';
    }).toList();

    final String fileContent = userListForFile.join('\n');

    final directory = await getApplicationDocumentsDirectory();
    String timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final filePath = '${directory.path}/new_cards_$timestamp.txt';
    final file = File(filePath);
    await file.writeAsString(fileContent);

    final prefs = await SharedPreferences.getInstance();
    final savedFile = SavedFile(
        path: filePath,
        profileName: _selectedProfile!,
        userCount: users.length,
        date: DateTime.now());
    final existingFiles = prefs.getStringList('saved_files') ?? [];
    existingFiles.add(jsonEncode(savedFile.toJson()));
    await prefs.setStringList('saved_files', existingFiles);

    // استخدام القالب المختار من المستخدم، أو البحث عن قالب مطابق للـ profile
    final relevantTemplate = _selectedTemplate ??
        await PdfTemplateStorage.findForProfile(_selectedProfile ?? '');
    final selectedPdfTemplate = relevantTemplate;

    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Center(child: Text('عملية ناجحة')),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Center(child: Text('تم إنشاء ${users.length} كرت بنجاح!')),
                if (failedCount > 0) ...[
                  const SizedBox(height: 8),
                  Center(
                    child: Text(
                      'فشل $failedCount كرت (رفضها الراوتر).',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
                if (warning.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Center(
                    child: Text(
                      warning,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Theme.of(context).appColors.warning,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  icon: const Icon(Icons.visibility),
                  label: const Text('عرض الكروت'),
                  onPressed: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (context) =>
                              CardListScreen(cardList: userListForFile)),
                    );
                  },
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  icon: const Icon(Icons.share),
                  label: const Text('مشاركة كملف نصي'),
                  onPressed: () async {
                    Navigator.of(context).pop();
                    await SharePlus.instance.share(ShareParams(
                        files: [XFile(filePath)], text: 'New MikroTik Users'));
                  },
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor),
                ),
                if (selectedPdfTemplate != null) ...[
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.preview_outlined),
                    label: const Text('معاينة PDF النهائية'),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor),
                    onPressed: () {
                      Navigator.of(context).pop();
                      final List<String> usernamesOnly =
                          users.map((u) => u['username']!).toList();
                      PdfGenerator.previewPdf(
                        context,
                        cardUsernames: usernamesOnly,
                        template: selectedPdfTemplate,
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.picture_as_pdf),
                    label: const Text('مشاركة PDF'),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor),
                    onPressed: () {
                      Navigator.of(context).pop();
                      final List<String> usernamesOnly =
                          users.map((u) => u['username']!).toList();
                      PdfGenerator.sharePdf(
                        context,
                        cardUsernames: usernamesOnly,
                        template: selectedPdfTemplate,
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.save_alt),
                    label: const Text('حفظ PDF'),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor),
                    onPressed: () async {
                      Navigator.of(context).pop();
                      final List<String> usernamesOnly =
                          users.map((u) => u['username']!).toList();
                      await PdfGenerator.savePdf(
                        context,
                        cardUsernames: usernamesOnly,
                        template: selectedPdfTemplate,
                      );
                    },
                  ),
                ],
                if (_isNetworkLinked) ...[
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.add_to_queue),
                    label: const Text('إضافة لـ م/نصار الشعبي'),
                    onPressed: () {
                      Navigator.of(context).pop();
                      _showAddCardsToQahtaniDialog(users);
                    },
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor),
                  ),
                ],
                TextButton(
                    child: const Text('إغلاق'),
                    onPressed: () => Navigator.of(context).pop())
              ],
            ),
          ),
        );
      },
    );
  }

  void _showAddCardsToQahtaniDialog(List<Map<String, String>> cards) {
    String? selectedUnitId;
    final units = (_linkedData['network_details']?['units'] as List?) ?? [];

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('اختر فئة م/نصار الشعبي'),
          content: DropdownButtonFormField<String>(
            style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.bold),
            dropdownColor: Theme.of(context).colorScheme.surface,
            hint: Text('اختر الفئة',
                style: TextStyle(
                    color: context.theme.appColors.muted,
                    fontWeight: FontWeight.bold)),
            items: units.map((unit) {
              return DropdownMenuItem<String>(
                value: unit['id'],
                child: Text(unit['name'],
                    style: TextStyle(
                        color: context.theme.appColors.onSurface,
                        fontWeight: FontWeight.bold)),
              );
            }).toList(),
            onChanged: (value) {
              selectedUnitId = value;
            },
            validator: (value) => value == null ? 'الرجاء اختيار فئة' : null,
          ),
          actions: [
            TextButton(
              child: const Text('إلغاء'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              child: const Text('تأكيد وإضافة'),
              onPressed: () {
                if (selectedUnitId != null) {
                  Navigator.of(context).pop();
                  _sendCardsToQahtani(cards, selectedUnitId!);
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _sendCardsToQahtani(
      List<Map<String, String>> cards, String selectedUnitId) {
    _showWaitingDialog("جاري إرسال الكروت...");

    setState(() {
      _addCardsJobId = _mqttService.generateUniqueId();
      _isJobAcknowledged = false;
    });

    _addCardsTimer?.cancel();
    _addCardsTimer = Timer(const Duration(seconds: 10), _checkAddCardsStatus);

    final List<String> cardUsernamesOnly =
        cards.map((cardMap) => cardMap['username']!).toList();
    final String cardsAsString = cardUsernamesOnly.join('\n');

    _mqttService.publish({
      'command': 'add_wifi_cards',
      'network_id': _linkedData['network_details']?['network_id'],
      'unit_id': selectedUnitId,
      'cards': cardsAsString,
      'job_id': _addCardsJobId,
    });
  }

  void _checkAddCardsStatus() {
    if (!mounted) return;

    if (_isJobAcknowledged) {
      // print("⏰ [إضافة كروت] الطلب تم استلامه، ننتظر...");
      return;
    }

    // print("⏰ [إضافة كروت] لم يتم استلام تأكيد، جاري فحص حالة الطلب...");
    _mqttService.publish({
      'command': 'get_job_status',
      'job_id': _addCardsJobId,
    });
  }

  void _showWaitingDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Row(children: [
          const CircularProgressIndicator(),
          const SizedBox(width: 20),
          Expanded(child: Text(message)),
        ]),
      ),
    );
  }

  void _showErrorDialog(String message) {
    if (!mounted) return;
    showErrorSnackBar(context, message);
  }

  String? _positiveIntegerValidator(String? value, String label) {
    final parsed = int.tryParse(value?.trim() ?? '');
    if (parsed == null) return '$label يجب أن يكون رقماً صحيحاً';
    if (parsed < 1) return '$label يجب أن يكون أكبر من صفر';
    return null;
  }

  String? _sharedUsersValidator(String? value) {
    final parsed = int.tryParse(value?.trim() ?? '');
    if (parsed == null) return 'Shared Users يجب أن يكون رقماً صحيحاً';
    if (parsed < 1 || parsed > 1000) {
      return 'Shared Users يجب أن يكون بين 1 و1000';
    }
    return null;
  }

  Widget _buildResumableJobsCard() {
    return Card(
      color: context.theme.appColors.warningContainer,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'توجد عمليات إنشاء غير مكتملة',
              style: TextStyle(
                color: context.theme.appColors.onWarningContainer,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ..._resumableJobs.map(
              (job) => ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  '${job.profileName} — ${job.confirmedCount}/${job.requestedCount}',
                  style: TextStyle(
                    color: context.theme.appColors.onWarningContainer,
                  ),
                ),
                subtitle: Text(
                  'الحالة: ${job.status} · آخر تحديث: ${DateFormat('yyyy-MM-dd HH:mm').format(job.updatedAt)}',
                  style: TextStyle(
                    color: context.theme.appColors.onWarningContainer,
                  ),
                ),
                trailing: FilledButton(
                  onPressed: _isGenerating ? null : () => _resumeJob(job),
                  child: const Text('استئناف'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _fieldDecoration({
    required String labelText,
    String? helperText,
    String? hintText,
    IconData? prefixIcon,
    Widget? suffixIcon,
  }) {
    final colors = Theme.of(context).appColors;
    final outline = OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: colors.outline, width: 1.2),
    );
    final focused = OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: colors.inputFocusedBorder, width: 2),
    );

    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      helperText: helperText,
      filled: true,
      fillColor: colors.inputBackground,
      labelStyle: TextStyle(
        color: colors.textSecondary,
        fontWeight: FontWeight.w600,
      ),
      floatingLabelStyle: TextStyle(
        color: colors.primary,
        fontWeight: FontWeight.bold,
      ),
      hintStyle: TextStyle(color: colors.textSecondary),
      helperStyle: TextStyle(color: colors.textSecondary),
      prefixIcon: prefixIcon == null
          ? null
          : Icon(prefixIcon, color: colors.primary, size: 23),
      suffixIcon: suffixIcon,
      border: outline,
      enabledBorder: outline,
      focusedBorder: focused,
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: colors.error, width: 1.2),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: colors.error, width: 2),
      ),
    );
  }

  TextStyle _fieldTextStyle() {
    final colors = Theme.of(context).appColors;
    return TextStyle(
      color: colors.textPrimary,
      fontWeight: FontWeight.w600,
    );
  }

  @override
  void dispose() {
    if (_isGenerating || _generationSession != null) {
      unawaited(_cancelGeneration(silent: true));
    } else {
      _cleanupGenerationResources();
    }
    _prefixController.dispose();
    _lengthController.dispose();
    _countController.dispose();
    _sharedUsersController.dispose();
    _mqttSubscription?.cancel();
    _addCardsTimer?.cancel();
    _cleanupGenerationResources();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إضافة كروت جماعية'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
      ),
      body: _isGenerating
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(_generationStatusText,
                        style: const TextStyle(fontSize: 18)),
                    const SizedBox(height: 20),
                    LinearProgressIndicator(
                      value: _generationProgress,
                      minHeight: 10,
                    ),
                    const SizedBox(height: 10),
                    Text('${(_generationProgress * 100).toStringAsFixed(0)}%'),
                    const SizedBox(height: 20),
                    OutlinedButton.icon(
                      onPressed: () => _cancelGeneration(),
                      icon: const Icon(Icons.cancel_outlined),
                      label: const Text('إلغاء العملية'),
                    ),
                  ],
                ),
              ),
            )
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_resumableJobs.isNotEmpty) ...[
                      _buildResumableJobsCard(),
                      const SizedBox(height: 16),
                    ],
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: TextButton.icon(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const CardGenerationJobsScreen(),
                          ),
                        ),
                        icon: const Icon(Icons.history),
                        label: const Text('سجل عمليات التوليد'),
                      ),
                    ),
                    TextFormField(
                      controller: _prefixController,
                      decoration: _fieldDecoration(
                        labelText: 'بادئة (اختياري)',
                        prefixIcon: Icons.text_fields_rounded,
                      ),
                      style: _fieldTextStyle(),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                            child: TextFormField(
                                controller: _lengthController,
                                decoration: _fieldDecoration(
                                  labelText: 'الطول',
                                  prefixIcon: Icons.straighten_rounded,
                                ),
                                style: _fieldTextStyle(),
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                                validator: (v) =>
                                    _positiveIntegerValidator(v, 'الطول'))),
                        const SizedBox(width: 16),
                        Expanded(
                            child: TextFormField(
                                controller: _countController,
                                decoration: _fieldDecoration(
                                  labelText: 'العدد',
                                  prefixIcon: Icons.confirmation_number_rounded,
                                ),
                                style: _fieldTextStyle(),
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                                validator: (v) =>
                                    _positiveIntegerValidator(v, 'العدد'))),
                      ],
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedProfile,
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontWeight: FontWeight.bold),
                      dropdownColor: Theme.of(context).colorScheme.surface,
                      decoration: _fieldDecoration(
                        labelText: 'الفئة (البروفايل)',
                        helperText: _isLoadingProfiles
                            ? 'جاري تحميل فئات $_profileSourceLabel من MikroTik...'
                            : _availableProfiles.isEmpty
                                ? 'لا توجد بروفايلات محملة (فئات)؛ اضغط تحديث أو تحقق من الاتصال.'
                                : 'المصدر: فئات $_profileSourceLabel الحالية من MikroTik',
                        prefixIcon: Icons.category_rounded,
                        suffixIcon: IconButton(
                          tooltip: 'تحديث البروفايلات',
                          color: Theme.of(context).appColors.primary,
                          onPressed: _isLoadingProfiles
                              ? null
                              : () => _loadProfilesFromRouter(),
                          icon: _isLoadingProfiles
                              ? SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Theme.of(context).appColors.primary,
                                  ),
                                )
                              : const Icon(Icons.refresh_rounded),
                        ),
                      ),
                      hint: Text('اختر فئة',
                          style: TextStyle(
                              color: context.theme.appColors.muted,
                              fontWeight: FontWeight.bold)),
                      items: _availableProfiles
                          .map((p) => DropdownMenuItem<String>(
                                value: p['name'].toString(),
                                child: Text(
                                  p['name'].toString(),
                                  style: TextStyle(
                                    color:
                                        Theme.of(context).colorScheme.onSurface,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ))
                          .toList(),
                      onChanged: (v) => setState(() => _selectedProfile = v),
                      validator: (v) =>
                          (v == null) ? 'الرجاء اختيار فئة' : null,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: _charType,
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontWeight: FontWeight.bold),
                      dropdownColor: Theme.of(context).colorScheme.surface,
                      decoration: _fieldDecoration(
                        labelText: 'نوع أحرف المستخدم',
                        prefixIcon: Icons.text_format_rounded,
                      ),
                      items: [
                        DropdownMenuItem(
                            value: 'mixed',
                            child: Text('حروف وأرقام',
                                style: TextStyle(
                                    color:
                                        Theme.of(context).colorScheme.onSurface,
                                    fontWeight: FontWeight.bold))),
                        DropdownMenuItem(
                            value: 'letters',
                            child: Text('حروف فقط',
                                style: TextStyle(
                                    color:
                                        Theme.of(context).colorScheme.onSurface,
                                    fontWeight: FontWeight.bold))),
                        DropdownMenuItem(
                            value: 'numbers',
                            child: Text('أرقام فقط',
                                style: TextStyle(
                                    color:
                                        Theme.of(context).colorScheme.onSurface,
                                    fontWeight: FontWeight.bold))),
                      ],
                      onChanged: (v) => setState(() => _charType = v!),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: _cardType,
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontWeight: FontWeight.bold),
                      dropdownColor: Theme.of(context).colorScheme.surface,
                      decoration: _fieldDecoration(
                        labelText: 'نوع الكرت',
                        prefixIcon: Icons.badge_rounded,
                      ),
                      items: [
                        DropdownMenuItem(
                            value: 'username_only',
                            child: Text('اسم مستخدم فقط',
                                style: TextStyle(
                                    color:
                                        Theme.of(context).colorScheme.onSurface,
                                    fontWeight: FontWeight.bold))),
                        DropdownMenuItem(
                            value: 'username_and_password_equal',
                            child: Text('اسم مستخدم وكلمة مرور متساوية',
                                style: TextStyle(
                                    color:
                                        Theme.of(context).colorScheme.onSurface,
                                    fontWeight: FontWeight.bold))),
                        DropdownMenuItem(
                            value: 'username_and_password_different',
                            child: Text('اسم مستخدم وكلمة مرور مختلفة',
                                style: TextStyle(
                                    color:
                                        Theme.of(context).colorScheme.onSurface,
                                    fontWeight: FontWeight.bold))),
                      ],
                      onChanged: (v) => setState(() => _cardType = v!),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedTemplate?.profileName,
                      decoration: _fieldDecoration(
                        labelText: 'نوع القالب (اختياري)',
                        hintText: 'اختر قالباً للتصدير إلى PDF',
                        prefixIcon: Icons.picture_as_pdf_rounded,
                      ),
                      hint: Text(
                        'اختر قالباً للتصدير إلى PDF',
                        style: TextStyle(
                          color: Theme.of(context).appColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      items: _templates
                          .map((template) => DropdownMenuItem(
                              value: template.profileName,
                              child: Text(template.profileName)))
                          .toList(),
                      onChanged: (v) {
                        setState(() {
                          _selectedTemplate = _templates.firstWhere(
                            (t) => t.profileName == v,
                            orElse: () => _templates.first,
                          );
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    CheckboxListTile(
                      title: Text(
                        'ربط كلمة المرور بأول مستخدم',
                        style: TextStyle(
                          color: Theme.of(context).appColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      activeColor: Theme.of(context).appColors.primary,
                      checkColor: Theme.of(context).appColors.onPrimary,
                      value: _linkPasswordToFirstUser,
                      onChanged: (newValue) {
                        setState(() {
                          _linkPasswordToFirstUser = newValue ?? false;
                        });
                      },
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: EdgeInsets.zero,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _sharedUsersController,
                      decoration: _fieldDecoration(
                        labelText: 'Shared Users',
                        helperText:
                            'في User Manager v6 يُطبّق العدد على المستخدم أثناء إنشاء الكرت',
                        prefixIcon: Icons.people_alt_rounded,
                      ),
                      style: _fieldTextStyle(),
                      keyboardType: TextInputType.number,
                      validator: _sharedUsersValidator,
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton.icon(
                      onPressed: _isGenerating ? null : _generateUsers,
                      icon: const Icon(Icons.apps_outage_rounded),
                      label: const Text('إنشاء الكروت'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
