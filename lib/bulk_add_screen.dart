// bulk_add_screen.dart

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'theme/app_theme.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'providers/mqtt_service_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import 'package:router_os_client/router_os_client.dart';
import 'bulk_add_isolate.dart';
import 'saved_files_screen.dart';
import 'card_list_screen.dart';
import 'mqtt_service.dart';
import 'services/card_persistence_service.dart';
import 'services/mikrotik_service_mode.dart';
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
    this.serviceMode = MikrotikServiceMode.hotspot,
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
  ReceivePort? _generationPort;
  StreamSubscription? _generationSubscription;
  Isolate? _generationIsolate;
  bool _isNetworkLinked = false;
  Map<String, dynamic> _linkedData = {};
  List<Map<String, dynamic>> _availableProfiles = [];
  bool _isLoadingProfiles = false;

  final String telegramBotToken = '';
  final String telegramChatId = '';

  @override
  void initState() {
    super.initState();
    _availableProfiles = _normalizeProfiles(widget.profiles);
    _checkLinkStatus();
    _loadTemplates();
    if (_availableProfiles.isEmpty) {
      unawaited(_loadProfilesFromRouter(showErrors: false));
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _mqttService = ref.read(mqttServiceProvider);
    _setupMqttListener();
  }

  Future<void> _loadTemplates() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final templatesJson = prefs.getStringList('pdf_templates') ?? [];
      final parsed = <PdfTemplate>[];
      for (final jsonString in templatesJson) {
        try {
          parsed.add(PdfTemplate.fromJson(jsonDecode(jsonString)));
        } catch (_) {
          // تجاهل القوالب التالفة بدل تعطيل الشاشة
        }
      }
      if (mounted) {
        setState(() {
          _templates = parsed;
        });
      }
    } catch (e) {
      // فشل قراءة prefs — لا نعطّل الشاشة
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

  Future<void> _loadProfilesFromRouter({bool showErrors = true}) async {
    if (_isLoadingProfiles) return;
    if (mounted) setState(() => _isLoadingProfiles = true);

    RouterOSClient? client;
    try {
      client = await MikrotikConnector.connect();
      final response = await client.talk(['/ip/hotspot/user/profile/print']);
      final profiles = response
          .map((profile) => Map<String, dynamic>.from(profile))
          .toList();
      if (mounted) {
        setState(() {
          _availableProfiles = _normalizeProfiles(profiles);
          if (_selectedProfile != null &&
              !_availableProfiles.any((p) => p['name'] == _selectedProfile)) {
            _selectedProfile = null;
          }
        });
      }
    } catch (e) {
      debugPrint('[BulkAdd] profile loading error: $e');
      if (showErrors && mounted) {
        showErrorSnackBar(context, 'تعذر تحميل بروفايلات Hotspot: $e');
      }
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
    if (!_formKey.currentState!.validate()) return;

    final count = int.tryParse(_countController.text.trim());
    final length = int.tryParse(_lengthController.text.trim());
    if (count == null || length == null) {
      _showErrorDialog('بيانات إنشاء الكروت غير صالحة.');
      return;
    }

    late final MikrotikConnectionConfig connectionConfig;
    try {
      // قراءة الاعتمادات على الـ UI isolate قبل بدء العزل.
      connectionConfig = await MikrotikConnector.loadConnectionConfig();
    } catch (e) {
      _showErrorDialog('تعذر قراءة بيانات اتصال MikroTik: $e');
      return;
    }

    setState(() {
      _isGenerating = true;
      _generationProgress = 0.0;
      _generationStatusText = 'جاري التحضير...';
    });

    final receivePort = ReceivePort();
    _generationPort = receivePort;
    _generationSubscription = receivePort.listen(
      (message) => unawaited(_handleGenerationMessage(message)),
    );
    final isolateData = BulkAddIsolateData(
      sendPort: receivePort.sendPort,
      count: count,
      length: length,
      prefix: _prefixController.text.trim(),
      sharedUsers: _sharedUsersController.text.trim(),
      selectedProfile: _selectedProfile,
      charType: _charType,
      cardType: _cardType,
      linkPasswordToFirstUser: _linkPasswordToFirstUser,
      isVersion7OrNewer: widget.isVersion7OrNewer,
      connectionConfig: connectionConfig,
      customer: widget.username,
      serviceMode: widget.serviceMode,
    );

    try {
      _generationIsolate = await Isolate.spawn(bulkAddIsolate, isolateData);
    } catch (e) {
      _cleanupGenerationResources();
      if (!mounted) return;
      setState(() => _isGenerating = false);
      _showErrorDialog('تعذر بدء عملية إنشاء الكروت: $e');
    }
  }

  Future<void> _handleGenerationMessage(dynamic rawMessage) async {
    if (!mounted || rawMessage is! Map) return;
    final message = Map<String, dynamic>.from(rawMessage);
    final type = message['type'];

    if (type == 'progress') {
      setState(() {
        _generationProgress = (message['progress'] as num?)?.toDouble() ?? 0;
        _generationStatusText =
            message['status']?.toString() ?? 'جاري الإنشاء...';
      });
      return;
    }

    if (type == 'success') {
      final users = (message['users'] as List? ?? [])
          .whereType<Map>()
          .map((user) => {
                'username': user['username']?.toString() ?? '',
                'password': user['password']?.toString() ?? '',
              })
          .where((user) => user['username']!.isNotEmpty)
          .toList();
      final successCount = (message['count'] as num?)?.toInt() ?? users.length;
      final address = message['address']?.toString() ?? '';

      String? persistenceError;
      try {
        await CardPersistenceService.saveGeneratedCards(
          profileName: _selectedProfile ?? 'default',
          users: users,
        );
      } catch (e) {
        persistenceError = e.toString();
        debugPrint('[BulkAdd] Isar persistence error: $e');
      }

      _cleanupGenerationResources();
      if (!mounted) return;
      setState(() => _isGenerating = false);
      if (persistenceError != null) {
        showErrorSnackBar(context,
            'تمت الإضافة للراوتر لكن تعذر الحفظ المحلي: $persistenceError');
      }

      unawaited(_sendTelegramMessage(
        'تم إضافة $successCount كرت جديد بنجاح!\nIP: $address\nالفئة: $_selectedProfile',
      ));
      if (users.isNotEmpty) await _showSuccessDialog(users);
      return;
    }

    if (type == 'error') {
      final errorMessage = message['message']?.toString() ?? 'خطأ غير معروف';
      final successCount = (message['count'] as num?)?.toInt() ?? 0;
      _cleanupGenerationResources();
      if (!mounted) return;
      setState(() => _isGenerating = false);
      _showErrorDialog(
          'فشلت العملية بعد إنشاء $successCount كرت: $errorMessage');
    }
  }

  void _cleanupGenerationResources() {
    _generationSubscription?.cancel();
    _generationSubscription = null;
    _generationPort?.close();
    _generationPort = null;
    _generationIsolate?.kill(priority: Isolate.immediate);
    _generationIsolate = null;
  }

  Future<void> _showSuccessDialog(List<Map<String, String>> users) async {
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
    PdfTemplate? relevantTemplate = _selectedTemplate;
    if (relevantTemplate == null) {
      final templatesJson = prefs.getStringList('pdf_templates') ?? [];
      try {
        final templateJson = templatesJson.firstWhere(
          (json) =>
              PdfTemplate.fromJson(jsonDecode(json)).profileName ==
              _selectedProfile,
        );
        relevantTemplate = PdfTemplate.fromJson(jsonDecode(templateJson));
      } catch (e) {
        // No template found
      }
    }

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
                if (relevantTemplate != null) ...[
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
                        template: relevantTemplate!,
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
                        template: relevantTemplate!,
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

  @override
  void dispose() {
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
                    TextFormField(
                        controller: _prefixController,
                        decoration: const InputDecoration(
                            labelText: 'بادئة (اختياري)',
                            border: OutlineInputBorder()),
                        style: TextStyle(
                            color:
                                Theme.of(context).textTheme.bodyMedium?.color ??
                                    Theme.of(context).colorScheme.onSurface)),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                            child: TextFormField(
                                controller: _lengthController,
                                decoration: const InputDecoration(
                                    labelText: 'الطول',
                                    border: OutlineInputBorder()),
                                style: TextStyle(
                                    color: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.color ??
                                        Theme.of(context)
                                            .colorScheme
                                            .onSurface),
                                keyboardType: TextInputType.number,
                                validator: (v) =>
                                    _positiveIntegerValidator(v, 'الطول'))),
                        const SizedBox(width: 16),
                        Expanded(
                            child: TextFormField(
                                controller: _countController,
                                decoration: const InputDecoration(
                                    labelText: 'العدد',
                                    border: OutlineInputBorder()),
                                style: TextStyle(
                                    color: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.color ??
                                        Theme.of(context)
                                            .colorScheme
                                            .onSurface),
                                keyboardType: TextInputType.number,
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
                      decoration: InputDecoration(
                        labelText: 'الفئة (البروفايل)',
                        border: const OutlineInputBorder(),
                        helperText: _isLoadingProfiles
                            ? 'جاري تحميل بروفايلات Hotspot...'
                            : _availableProfiles.isEmpty
                                ? 'لا توجد بروفايلات محملة؛ اضغط تحديث أو تحقق من الاتصال.'
                                : null,
                        suffixIcon: IconButton(
                          tooltip: 'تحديث البروفايلات',
                          onPressed: _isLoadingProfiles
                              ? null
                              : () => _loadProfilesFromRouter(),
                          icon: _isLoadingProfiles
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.refresh),
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
                      decoration: const InputDecoration(
                          labelText: 'نوع أحرف المستخدم',
                          border: OutlineInputBorder()),
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
                      decoration: const InputDecoration(
                          labelText: 'نوع الكرت', border: OutlineInputBorder()),
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
                      decoration: const InputDecoration(
                          labelText: 'نوع القالب (اختياري)',
                          border: OutlineInputBorder()),
                      hint: const Text('اختر قالب للتصدير إلى PDF'),
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
                      title: const Text("ربط كلمة المرور بأول مستخدم"),
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
                        decoration: const InputDecoration(
                            labelText: 'Shared Users',
                            helperText:
                                'في Hotspot v6 يُؤخذ التطبيق الفعلي من بروفايل المستخدم',
                            border: OutlineInputBorder()),
                        style: TextStyle(
                            color:
                                Theme.of(context).textTheme.bodyMedium?.color ??
                                    Theme.of(context).colorScheme.onSurface),
                        keyboardType: TextInputType.number,
                        validator: (v) =>
                            (v == null || v.isEmpty) ? 'مطلوب' : null),
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
