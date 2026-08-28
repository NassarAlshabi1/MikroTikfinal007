import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import 'services/routeros_script_generator.dart';
import 'services/telegram_bot_settings.dart';
import 'theme/app_theme.dart';

class TelegramBotSettingsScreen extends StatefulWidget {
  const TelegramBotSettingsScreen({super.key});

  @override
  State<TelegramBotSettingsScreen> createState() =>
      _TelegramBotSettingsScreenState();
}

class _TelegramBotSettingsScreenState extends State<TelegramBotSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _tokenController = TextEditingController();
  final _chatIdsController = TextEditingController();
  final _userIdsController = TextEditingController();
  final _workerUrlController = TextEditingController();
  final _workerKeyController = TextEditingController();
  final _umCustomerController = TextEditingController();
  final _umProfileController = TextEditingController();
  final _defaultLimitController = TextEditingController();
  final _routerPollController = TextEditingController();
  final _pollController = TextEditingController();
  final _targetController = TextEditingController();
  final _monitorIntervalController = TextEditingController();
  final _interfaceController = TextEditingController();
  final _trafficIntervalController = TextEditingController();
  final _reportTimeController = TextEditingController();
  final _offsetFileController = TextEditingController();
  final _stateFileController = TextEditingController();

  final _store = const TelegramBotSettingsStore();
  TelegramDeploymentMode _mode = TelegramDeploymentMode.routerOsScript;
  bool _loading = true;
  bool _saving = false;
  bool _testing = false;
  bool _testingWorker = false;
  bool _obscureToken = true;
  bool _obscureWorkerKey = true;
  bool _generating = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final settings = await _store.load();
    final workerKey = await _store.loadWorkerAdminKey();
    if (!mounted) return;
    setState(() {
      _mode = settings.deploymentMode;
      _tokenController.text = settings.botToken;
      _chatIdsController.text = settings.allowedChatIds;
      _userIdsController.text = settings.allowedUserIds;
      _workerUrlController.text = settings.workerUrl;
      _workerKeyController.text = workerKey ?? '';
      _umCustomerController.text = settings.umCustomer;
      _umProfileController.text = settings.umProfile;
      _defaultLimitController.text = settings.defaultCardLimit;
      _routerPollController.text = settings.routerPollSeconds.toString();
      _pollController.text = settings.pollSeconds.toString();
      _targetController.text = settings.monitorTarget;
      _monitorIntervalController.text =
          settings.monitorIntervalSeconds.toString();
      _interfaceController.text = settings.trafficInterface;
      _trafficIntervalController.text =
          settings.trafficIntervalSeconds.toString();
      _reportTimeController.text = settings.dailyReportTime;
      _offsetFileController.text = settings.offsetFile;
      _stateFileController.text = settings.trafficStateFile;
      _loading = false;
    });
  }

  @override
  void dispose() {
    for (final controller in [
      _tokenController,
      _chatIdsController,
      _userIdsController,
      _workerUrlController,
      _workerKeyController,
      _umCustomerController,
      _umProfileController,
      _defaultLimitController,
      _routerPollController,
      _pollController,
      _targetController,
      _monitorIntervalController,
      _interfaceController,
      _trafficIntervalController,
      _reportTimeController,
      _offsetFileController,
      _stateFileController,
    ]) {
      controller.dispose();
    }
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
    final valid =
        raw.split(',').every((id) => RegExp(r'^-?\d+$').hasMatch(id.trim()));
    return valid ? null : 'استخدم Chat IDs رقمية مفصولة بفواصل';
  }

  String? _userIds(String? value) {
    final raw = value?.trim() ?? '';
    if (raw.isEmpty) return 'أدخل Telegram User ID واحداً على الأقل';
    final valid =
        raw.split(',').every((id) => RegExp(r'^\d+$').hasMatch(id.trim()));
    return valid ? null : 'استخدم User IDs رقمية مفصولة بفواصل';
  }

  String? _workerUrl(String? value) {
    final raw = value?.trim() ?? '';
    if (raw.isEmpty) return 'أدخل رابط Cloudflare Worker';
    final uri = Uri.tryParse(raw);
    if (uri == null || !uri.isScheme('https') || uri.host.isEmpty) {
      return 'يجب أن يكون رابط https صالحاً مثل https://nassar-mikrotik.example.workers.dev';
    }
    return null;
  }

  String? _time(String? value) {
    final raw = value?.trim() ?? '';
    return RegExp(r'^(?:[01]\d|2[0-3]):[0-5]\d$').hasMatch(raw)
        ? null
        : 'استخدم الوقت بصيغة HH:MM مثل 23:59';
  }

  String? _cardLimit(String? value) {
    final raw = value?.trim() ?? '';
    if (raw.isEmpty) return 'أدخل مدة الكرت';
    if (!RegExp(r'^\d+[hdwm]$').hasMatch(raw)) {
      return 'استخدم صيغة مثل 1w أو 30d أو 12h أو 4w2d';
    }
    return null;
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    try {
      final settings = TelegramBotSettings(
        deploymentMode: _mode,
        botToken: _tokenController.text.trim(),
        allowedChatIds: _chatIdsController.text.trim(),
        allowedUserIds: _userIdsController.text.trim(),
        workerUrl: _workerUrlController.text.trim(),
        umCustomer: _umCustomerController.text.trim(),
        umProfile: _umProfileController.text.trim(),
        defaultCardLimit: _defaultLimitController.text.trim(),
        pollSeconds: _number(_pollController) ?? 20,
        routerPollSeconds: _number(_routerPollController) ?? 10,
        monitorTarget: _targetController.text.trim(),
        monitorIntervalSeconds: _number(_monitorIntervalController) ?? 30,
        trafficInterface: _interfaceController.text.trim(),
        trafficIntervalSeconds: _number(_trafficIntervalController) ?? 60,
        dailyReportTime: _reportTimeController.text.trim(),
        offsetFile: _offsetFileController.text.trim(),
        trafficStateFile: _stateFileController.text.trim(),
      );
      await _store.save(
        settings,
        workerAdminKey: _mode == TelegramDeploymentMode.cloudflareWorker
            ? _workerKeyController.text.trim()
            : null,
      );
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
        content:
            Text('تعذر الوصول إلى Telegram API. تحقق من الإنترنت والتوكن.'),
        behavior: SnackBarBehavior.floating,
      ));
    } finally {
      if (mounted) setState(() => _testing = false);
    }
  }

  Future<void> _testWorker() async {
    final url = _workerUrlController.text.trim();
    if (url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('أدخل رابط Worker أولاً'),
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }
    setState(() => _testingWorker = true);
    try {
      await Dio().getUri<Object>(
        Uri.parse(url),
        options: Options(
          responseType: ResponseType.plain,
          validateStatus: (status) => status != null && status < 500,
          sendTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
        ),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Worker يستجيب. أي رمز أقل من 500 يعني أن الخدمة تعمل.'),
        behavior: SnackBarBehavior.floating,
      ));
    } on DioException {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('تعذر الوصول إلى Worker. تحقق من الرابط والنشر.'),
        behavior: SnackBarBehavior.floating,
      ));
    } finally {
      if (mounted) setState(() => _testingWorker = false);
    }
  }

  /// يولّد سكربت RouterOS v6 جاهزاً للتطبيق من قيم النموذج ويشاركه كملف.
  Future<void> _generateScript() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    // سكربت v6 يقارن Chat ID وUser ID مقارنة نصية مباشرة، لذا يُستخدم أول معرف.
    final chatId = _chatIdsController.text.split(',').first.trim();
    final userId = _userIdsController.text.split(',').first.trim();
    setState(() => _generating = true);
    try {
      const generator = RouterOsScriptGenerator();
      final script = await generator.generate(
        botToken: _tokenController.text.trim(),
        allowedChatId: chatId,
        allowedUserId: userId,
        umCustomer: _umCustomerController.text.trim(),
        umProfile: _umProfileController.text.trim(),
        defaultLimit: _defaultLimitController.text.trim(),
        pollSeconds: _number(_routerPollController) ?? 10,
      );
      final file = await generator.writeScript(script);
      await SharePlus.instance.share(ShareParams(
        files: [XFile(file.path)],
        text: 'سكربت Telegram Bot جاهز للتطبيق على RouterOS v6',
        subject: 'mikrotik-telegram-um-v6.rsc',
      ));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('تعذر توليد السكربت. تحقق من القيم وحاول مجدداً.'),
        behavior: SnackBarBehavior.floating,
      ));
    } finally {
      if (mounted) setState(() => _generating = false);
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

  String _modeLabel(TelegramDeploymentMode mode) {
    switch (mode) {
      case TelegramDeploymentMode.routerOsScript:
        return 'سكربت داخل الراوتر (RouterOS v6) — موصى به';
      case TelegramDeploymentMode.cloudflareWorker:
        return 'Cloudflare Worker (webhook)';
      case TelegramDeploymentMode.localPython:
        return 'خدمة Python محلية (Linux)';
    }
  }

  String _commandHint(String command) {
    switch (command) {
      case '/help':
      case '/start':
        return 'عرض قائمة الأوامر والتحقق من التشغيل';
      case '/status':
        return 'حالة الراوتر والإنترنت';
      case '/um':
        return 'ملخص User Manager والبروفايلات';
      case '/active':
        return 'المستخدمون النشطون حالياً';
      case '/check':
        return 'فحص حالة كرت: /check <اسم>';
      case '/gen':
        return 'إنشاء كروت: /gen <عدد> <مدة>';
      case '/list':
        return 'عرض آخر الكروت المُنشأة';
      case '/del':
        return 'حذف كرت: /del <اسم>';
      case '/report':
        return 'تقرير المبيعات';
      case '/clean':
        return 'حذف الكروت المنتهية';
      case '/reboot':
        return 'إعادة تشغيل الراوتر (طلبات حساسة)';
      default:
        return command;
    }
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
                  _buildModeCard(context),
                  const SizedBox(height: 16),
                  _buildTelegramCard(context),
                  const SizedBox(height: 16),
                  if (_mode == TelegramDeploymentMode.routerOsScript)
                    _buildRouterScriptCard(context)
                  else if (_mode == TelegramDeploymentMode.cloudflareWorker)
                    _buildWorkerCard(context)
                  else ...[
                    _buildMonitoringCard(context),
                    const SizedBox(height: 16),
                    _buildStorageCard(context),
                  ],
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
                  if (_mode == TelegramDeploymentMode.cloudflareWorker) ...[
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: _testingWorker ? null : _testWorker,
                      icon: _testingWorker
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.cloud_sync_outlined),
                      label: Text(_testingWorker
                          ? 'جاري اختبار Worker...'
                          : 'اختبار Cloudflare Worker'),
                    ),
                  ],
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
              'اختر نمط النشر المناسب لشبكتك. النمط الموصى به يعمل عبر سكربت '
              'داخل الراوتر يستخدم /tool fetch لاستطلاع أوامر Telegram دون فتح '
              'أي منفذ خارجي، ويدعم إدارة كروت User Manager (إنشاء وحذف الكروت '
              'وتقارير المبيعات). يبقى Bot Token ومفتاح Worker مشفرين في '
              'التخزين الآمن ولا يُكتبان في ملفات المشروع.',
              style: TextStyle(height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModeCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('نمط النشر', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            DropdownButtonFormField<TelegramDeploymentMode>(
              initialValue: _mode,
              decoration: _decoration('اختر نمط التشغيل',
                  icon: Icons.hub_outlined),
              items: TelegramDeploymentMode.values
                  .map((mode) => DropdownMenuItem(
                        value: mode,
                        child: Text(_modeLabel(mode), overflow: TextOverflow.ellipsis),
                      ))
                  .toList(),
              onChanged: (mode) {
                if (mode == null || mode == _mode) return;
                setState(() => _mode = mode);
              },
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
            Text('Telegram API',
                style: Theme.of(context).textTheme.titleMedium),
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

  Widget _buildRouterScriptCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('إدارة كروت User Manager',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            _field(
              controller: _umCustomerController,
              label: 'اسم العميل (Customer)',
              hint: 'admin',
              icon: Icons.badge_outlined,
              validator: (value) => _required(value, 'اسم العميل'),
            ),
            const SizedBox(height: 12),
            _field(
              controller: _umProfileController,
              label: 'بروفايل الكروت (Profile)',
              hint: 'default',
              icon: Icons.category_outlined,
              validator: (value) => _required(value, 'البروفايل'),
            ),
            const SizedBox(height: 12),
            _field(
              controller: _defaultLimitController,
              label: 'مدة الكرت الافتراضية',
              hint: '1w أو 30d أو 12h',
              icon: Icons.timelapse,
              validator: _cardLimit,
            ),
            const SizedBox(height: 12),
            _field(
              controller: _routerPollController,
              label: 'فترة استطلاع الأوامر بالثواني',
              hint: '10',
              icon: Icons.update_outlined,
              validator: (value) =>
                  _positiveNumber(value, 'فترة الاستطلاع', minimum: 5),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            Text('أوامر البوت المدعومة داخل الراوتر:',
                style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: const [
                '/help', '/start', '/status', '/um', '/active', '/check',
                '/gen', '/list', '/del', '/report', '/clean', '/reboot',
              ]
                  .map((cmd) => Tooltip(
                        message: _commandHint(cmd),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: context.theme.appColors.surface,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: context.theme.appColors.primary
                                  .withAlpha(77),
                            ),
                          ),
                          child: Text(cmd,
                              style: const TextStyle(
                                  fontSize: 12,
                                  fontFamily: 'monospace')),
                        ),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 12),
            FilledButton.tonalIcon(
              onPressed: _generating ? null : _generateScript,
              icon: _generating
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.build_circle_outlined),
              label: Text(_generating
                  ? 'جاري التوليد...'
                  : 'توليد سكربت الراوتر جاهز التطبيق'),
            ),
            const SizedBox(height: 8),
            Text(
              'يولّد الزر ملف telegram-um-final-v6.rsc بنفس القيم المحفوظة '
              'أعلاه (بما فيها التوكن) جاهزاً للنسخ إلى الراوتر ثم تشغيله. '
              'يعمل السكربت عبر /tool fetch لاستطلاع الأوامر دون فتح أي منفذ. '
              'ملاحظة: سكربت v6 يقبل Chat ID وUser ID واحداً لكل منهما، ويُستخدم '
              'أول معرف من القائمة إذا أدكرت أكثر من واحد.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkerCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Cloudflare Worker',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            _field(
              controller: _workerUrlController,
              label: 'Worker URL',
              hint: 'https://nassar-mikrotik.example.workers.dev',
              icon: Icons.cloud_outlined,
              validator: _workerUrl,
              keyboardType: TextInputType.url,
            ),
            const SizedBox(height: 12),
            _field(
              controller: _workerKeyController,
              label: 'Worker Admin Key (اختياري)',
              hint: 'يُحفظ في التخزين الآمن فقط',
              icon: Icons.vpn_key_outlined,
              obscureText: _obscureWorkerKey,
              suffixIcon: IconButton(
                onPressed: () => setState(
                    () => _obscureWorkerKey = !_obscureWorkerKey),
                icon: Icon(_obscureWorkerKey
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'استخدم هذا النمط إذا كان الراوتر له عنوان عام أو عبر نفق '
              '(Tunnel). ملاحظة: واجهة REST API غير متوفرة في RouterOS v6، '
              'لذا لا يستطيع Worker إرسال أوامر مباشرة إلى راوتر v6 خلف NAT.',
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
              validator: (value) =>
                  _positiveNumber(value, 'فترة فحص الإنترنت', minimum: 10),
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
              validator: (value) =>
                  _positiveNumber(value, 'فترة الاستهلاك', minimum: 30),
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
