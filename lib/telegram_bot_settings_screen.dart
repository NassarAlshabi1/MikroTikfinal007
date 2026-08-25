import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import 'services/telegram_bot_settings.dart';
import 'theme/app_theme.dart';

class TelegramBotSettingsScreen extends StatefulWidget {
  const TelegramBotSettingsScreen({super.key});

  @override
  State<TelegramBotSettingsScreen> createState() =>
      _TelegramBotSettingsScreenState();
}

class _TelegramBotSettingsScreenState
    extends State<TelegramBotSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _tokenController = TextEditingController();
  final _chatIdsController = TextEditingController();
  final _userIdsController = TextEditingController();
  final _pollController = TextEditingController();
  final _targetController = TextEditingController();
  final _monitorIntervalController = TextEditingController();
  final _interfaceController = TextEditingController();
  final _trafficIntervalController = TextEditingController();
  final _reportTimeController = TextEditingController();
  final _offsetFileController = TextEditingController();
  final _stateFileController = TextEditingController();

  final _store = const TelegramBotSettingsStore();
  bool _loading = true;
  bool _saving = false;
  bool _testing = false;
  bool _obscureToken = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final settings = await _store.load();
    if (!mounted) return;
    _tokenController.text = settings.botToken;
    _chatIdsController.text = settings.allowedChatIds;
    _userIdsController.text = settings.allowedUserIds;
    _pollController.text = settings.pollSeconds.toString();
    _targetController.text = settings.monitorTarget;
    _monitorIntervalController.text = settings.monitorIntervalSeconds.toString();
    _interfaceController.text = settings.trafficInterface;
    _trafficIntervalController.text = settings.trafficIntervalSeconds.toString();
    _reportTimeController.text = settings.dailyReportTime;
    _offsetFileController.text = settings.offsetFile;
    _stateFileController.text = settings.trafficStateFile;
    setState(() => _loading = false);
  }

  @override
  void dispose() {
    _tokenController.dispose();
    _chatIdsController.dispose();
    _userIdsController.dispose();
    _pollController.dispose();
    _targetController.dispose();
    _monitorIntervalController.dispose();
    _interfaceController.dispose();
    _trafficIntervalController.dispose();
    _reportTimeController.dispose();
    _offsetFileController.dispose();
    _stateFileController.dispose();
    super.dispose();
  }

  int? _number(TextEditingController controller) =>
      int.tryParse(controller.text.trim());

  String? _required(String? value, String label) {
    if (value == null || value.trim().isEmpty) return 'أدخل $label';
    return null;
  }

  String? _positiveNumber(String? value, String label, {int minimum = 1}) {
    final parsed = int.tryParse(value?.trim() ?? '');
    if (parsed == null || parsed < minimum) {
      return '$label يجب أن يكون رقماً لا يقل عن $minimum';
    }
    return null;
  }

  String? _chatIds(String? value) {
    final raw = value?.trim() ?? '';
    if (raw.isEmpty) return 'أدخل Chat ID واحداً على الأقل';
    final valid = raw.split(',').every((id) => RegExp(r'^-?\d+$').hasMatch(id.trim()));
    return valid ? null : 'استخدم Chat IDs رقمية مفصولة بفواصل';
  }

  String? _userIds(String? value) {
    final raw = value?.trim() ?? '';
    if (raw.isEmpty) return 'أدخل Telegram User ID واحداً على الأقل';
    final valid = raw.split(',').every((id) => RegExp(r'^\d+$').hasMatch(id.trim()));
    return valid ? null : 'استخدم User IDs رقمية مفصولة بفواصل';
  }

  String? _time(String? value) {
    final raw = value?.trim() ?? '';
    return RegExp(r'^(?:[01]\d|2[0-3]):[0-5]\d$').hasMatch(raw)
        ? null
        : 'استخدم الوقت بصيغة HH:MM مثل 23:59';
  }

  Future<TelegramBotSettings?> _readForm() async {
    if (!(_formKey.currentState?.validate() ?? false)) return null;
    return TelegramBotSettings(
      botToken: _tokenController.text.trim(),
      allowedChatIds: _chatIdsController.text.trim(),
      allowedUserIds: _userIdsController.text.trim(),
      pollSeconds: _number(_pollController)!,
      monitorTarget: _targetController.text.trim(),
      monitorIntervalSeconds: _number(_monitorIntervalController)!,
      trafficInterface: _interfaceController.text.trim(),
      trafficIntervalSeconds: _number(_trafficIntervalController)!,
      dailyReportTime: _reportTimeController.text.trim(),
      offsetFile: _offsetFileController.text.trim(),
      trafficStateFile: _stateFileController.text.trim(),
    );
  }

  Future<void> _save() async {
    final settings = await _readForm();
    if (settings == null) return;
    setState(() => _saving = true);
    try {
      await _store.save(settings);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('تم حفظ إعدادات Telegram Bot في التخزين الآمن والمحلي'),
        behavior: SnackBarBehavior.floating,
      ));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _testTelegramApi() async {
    final token = _tokenController.text.trim();
    if (token.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('أدخل Bot Token أولاً لاختبار Telegram API'),
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }
    setState(() => _testing = true);
    try {
      final response = await Dio().get<Map<String, dynamic>>(
        'https://api.telegram.org/bot$token/getMe',
        options: Options(
          responseType: ResponseType.json,
          sendTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
        ),
      );
      final ok = response.data?['ok'] == true;
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(ok
            ? 'نجح اتصال Telegram API. التوكن صالح.'
            : 'رفض Telegram API التوكن.'),
        behavior: SnackBarBehavior.floating,
      ));
    } on DioException {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('تعذر الوصول إلى Telegram API. تحقق من الإنترنت والتوكن.'),
        behavior: SnackBarBehavior.floating,
      ));
    } finally {
      if (mounted) setState(() => _testing = false);
    }
  }

  InputDecoration _decoration(String label, {String? hint, IconData? icon}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: icon == null ? null : Icon(icon),
      border: const OutlineInputBorder(),
      filled: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    String? hint,
    IconData? icon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffixIcon,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      decoration: _decoration(label, hint: hint, icon: icon).copyWith(
        suffixIcon: suffixIcon,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('إعداد Telegram Bot')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildIntroCard(context),
                  const SizedBox(height: 16),
                  _buildTelegramCard(context),
                  const SizedBox(height: 16),
                  _buildMonitoringCard(context),
                  const SizedBox(height: 16),
                  _buildStorageCard(context),
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: _saving ? null : _save,
                    icon: _saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save_outlined),
                    label: Text(_saving ? 'جاري الحفظ...' : 'حفظ الإعدادات'),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: _testing ? null : _testTelegramApi,
                    icon: _testing
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.wifi_find),
                    label: Text(_testing
                        ? 'جاري اختبار API...'
                        : 'اختبار Telegram API'),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildIntroCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.security, color: context.theme.appColors.primary),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text('لوحة تحكم آمنة لـ RouterOS v6',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 10),
            const Text(
              'يعمل Telegram Bot كخدمة Python مستقلة على جهاز Linux المحلي. التطبيق يحفظ الإعدادات ويختبر Telegram API، بينما يبقى Bot Token مشفراً ولا يُكتب في ملفات المشروع.',
              style: TextStyle(height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTelegramCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Telegram API', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            _field(
              controller: _tokenController,
              label: 'Bot Token',
              hint: 'يُحفظ في التخزين الآمن فقط',
              icon: Icons.key_outlined,
              obscureText: _obscureToken,
              validator: (value) => _required(value, 'Bot Token'),
              suffixIcon: IconButton(
                onPressed: () => setState(() => _obscureToken = !_obscureToken),
                icon: Icon(_obscureToken
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined),
              ),
            ),
            const SizedBox(height: 12),
            _field(
              controller: _chatIdsController,
              label: 'Allowed Chat IDs',
              hint: '5944227208 أو عدة أرقام مفصولة بفواصل',
              icon: Icons.group_outlined,
              validator: _chatIds,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            _field(
              controller: _userIdsController,
              label: 'Allowed Telegram User IDs',
              hint: 'User ID الخاص بحسابك أو عدة أرقام مفصولة بفواصل',
              icon: Icons.person_outline,
              validator: _userIds,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 8),
            Text(
              'يجب أن يطابق Chat ID وUser ID معًا حتى يقبل البوت الطلبات الحساسة مثل /reboot.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonitoringCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('المراقبة والاستهلاك',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            _field(
              controller: _pollController,
              label: 'فترة Telegram Polling بالثواني',
              icon: Icons.sync,
              validator: (value) =>
                  _positiveNumber(value, 'فترة polling', minimum: 1),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            _field(
              controller: _targetController,
              label: 'هدف فحص الإنترنت',
              hint: '1.1.1.1',
              icon: Icons.public,
              validator: (value) => _required(value, 'هدف الفحص'),
            ),
            const SizedBox(height: 12),
            _field(
              controller: _monitorIntervalController,
              label: 'فترة فحص انقطاع الإنترنت بالثواني',
              icon: Icons.timer_outlined,
              validator: (value) => _positiveNumber(
                  value, 'فترة فحص الإنترنت', minimum: 10),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            _field(
              controller: _interfaceController,
              label: 'واجهة الإنترنت الخارجية',
              hint: 'ether1',
              icon: Icons.swap_horiz,
              validator: (value) => _required(value, 'واجهة الإنترنت'),
            ),
            const SizedBox(height: 12),
            _field(
              controller: _trafficIntervalController,
              label: 'فترة قراءة عدادات الاستهلاك بالثواني',
              icon: Icons.data_usage,
              validator: (value) => _positiveNumber(
                  value, 'فترة الاستهلاك', minimum: 30),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            _field(
              controller: _reportTimeController,
              label: 'وقت التقرير اليومي',
              hint: '23:59',
              icon: Icons.schedule,
              validator: _time,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStorageCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('مسارات الحالة على Linux',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            _field(
              controller: _offsetFileController,
              label: 'ملف Telegram offset',
              icon: Icons.receipt_long_outlined,
              validator: (value) => _required(value, 'مسار offset'),
            ),
            const SizedBox(height: 12),
            _field(
              controller: _stateFileController,
              label: 'ملف حالة الاستهلاك',
              icon: Icons.save_outlined,
              validator: (value) => _required(value, 'مسار حالة الاستهلاك'),
            ),
            const SizedBox(height: 8),
            Text(
              'يجب أن تكون هذه المسارات قابلة للكتابة من مستخدم خدمة البوت، ولا تُستخدم داخل تطبيق Android نفسه.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
