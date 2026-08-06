// ============================================================
//  OomolSettingsScreen — شاشة إعدادات OOMOL Cloud
//
//  تتيح:
//  1. إدخال/تعديل OOMOL API key
//  2. إدخال اسم الـ package + version المنشور على OOMOL
//  3. اختبار الاتصال (connect → getDashboard)
//  4. عرض معلومات الحساب (maxConcurrency, maxQueueSize)
//  5. عرض قائمة المهام الأخيرة
//  6. إيقاف/استئناف طابور المهام
// ============================================================

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/secure_credentials_storage.dart';
import '../theme/app_theme.dart';
import '../theme/app_colors_extension.dart';
import '../snackbar_helpers.dart';
import 'oomol_mcp_client.dart';

class OomolSettingsScreen extends StatefulWidget {
  const OomolSettingsScreen({super.key});

  @override
  State<OomolSettingsScreen> createState() => _OomolSettingsScreenState();
}

class _OomolSettingsScreenState extends State<OomolSettingsScreen> {
  final _apiKeyController = TextEditingController();
  final _packageNameController = TextEditingController();
  final _packageVersionController = TextEditingController();

  bool _loading = false;
  bool _connecting = false;
  bool _obscureKey = true;
  OomolDashboard? _dashboard;
  List<OomolTask> _tasks = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    _packageNameController.dispose();
    _packageVersionController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    // 🔒 قراءة API key من flutter_secure_storage (مشفّر)
    final apiKey =
        await SecureCredentialsStorageContainer.instance.getOomolApiKey() ?? '';
    setState(() {
      _apiKeyController.text = apiKey;
      _packageNameController.text = prefs.getString('oomol_package_name') ?? '';
      _packageVersionController.text =
          prefs.getString('oomol_package_version') ?? 'latest';
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    // 🔒 حفظ API key في flutter_secure_storage (مشفّر)
    await SecureCredentialsStorageContainer.instance
        .setOomolApiKey(_apiKeyController.text.trim());
    await prefs.setString(
        'oomol_package_name', _packageNameController.text.trim());
    await prefs.setString(
        'oomol_package_version', _packageVersionController.text.trim());
    if (mounted) showSuccessSnackBar(context, 'تم حفظ إعدادات OOMOL');
  }

  Future<void> _testConnection() async {
    if (_apiKeyController.text.trim().isEmpty) {
      showSuccessSnackBar(context, 'أدخل API key أولاً');
      return;
    }

    setState(() {
      _connecting = true;
      _errorMessage = null;
      _dashboard = null;
      _tasks = [];
    });

    final client = OomolMcpClient(apiKey: _apiKeyController.text.trim());
    try {
      await client.connect(timeout: const Duration(seconds: 30));
      final dash = await client.getDashboard();
      final tasks = await client.listTasks(size: 10);
      setState(() {
        _dashboard = dash;
        _tasks = tasks;
      });
      if (mounted) showSuccessSnackBar(context, '✅ تم الاتصال بنجاح!');
    } catch (e) {
      setState(() => _errorMessage = 'فشل الاتصال: $e');
      if (mounted) showSuccessSnackBar(context, '❌ فشل: $e');
    } finally {
      await client.disconnect();
      if (mounted) setState(() => _connecting = false);
    }
  }

  Future<void> _pauseQueue() async {
    setState(() => _loading = true);
    final client = OomolMcpClient(apiKey: _apiKeyController.text.trim());
    try {
      await client.connect();
      await client.pauseUserQueue();
      final dash = await client.getDashboard();
      setState(() => _dashboard = dash);
      if (mounted) showSuccessSnackBar(context, '⏸️ تم إيقاف الطابور');
    } catch (e) {
      if (mounted) showSuccessSnackBar(context, 'فشل: $e');
    } finally {
      await client.disconnect();
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resumeQueue() async {
    setState(() => _loading = true);
    final client = OomolMcpClient(apiKey: _apiKeyController.text.trim());
    try {
      await client.connect();
      await client.resumeUserQueue();
      final dash = await client.getDashboard();
      setState(() => _dashboard = dash);
      if (mounted) showSuccessSnackBar(context, '▶️ تم استئناف الطابور');
    } catch (e) {
      if (mounted) showSuccessSnackBar(context, 'فشل: $e');
    } finally {
      await client.disconnect();
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Scaffold(
      appBar: AppBar(
        title: const Text('☁️ إعدادات OOMOL Cloud'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            tooltip: 'حفظ',
            onPressed: _saveSettings,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── Header ───
            _buildHeader(colors),
            const SizedBox(height: 16),

            // ─── API Key ───
            _buildApiKeyCard(colors),
            const SizedBox(height: 16),

            // ─── Package ───
            _buildPackageCard(colors),
            const SizedBox(height: 16),

            // ─── Test button ───
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _connecting ? null : _testConnection,
                icon: _connecting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.electrical_services),
                label: Text(_connecting ? 'جارٍ الاتصال...' : 'اختبار الاتصال'),
              ),
            ),
            const SizedBox(height: 16),

            // ─── Error ───
            if (_errorMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colors.errorContainer,
                  borderRadius: BorderRadius.circular(8),
                  border:
                      Border.all(color: colors.error.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error, color: colors.error),
                    const SizedBox(width: 8),
                    Expanded(
                      child: SelectableText(
                        _errorMessage!,
                        style: TextStyle(color: colors.onErrorContainer),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // ─── Dashboard info ───
            if (_dashboard != null) ...[
              _buildDashboardCard(colors),
              const SizedBox(height: 16),
              _buildQueueControls(colors),
              const SizedBox(height: 16),
            ],

            // ─── Recent tasks ───
            if (_tasks.isNotEmpty) ...[
              _buildTasksCard(colors),
              const SizedBox(height: 16),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(AppColorsExtension colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colors.primary.withValues(alpha: 0.15),
            colors.secondary.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: colors.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.cloud, color: colors.primary, size: 28),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'OOMOL Cloud Task API v3',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'منصة serverless لتشغيل AI pipelines على السحابة.\n'
                  'يستخدم MCP server للتواصل مع Claude/Cursor وغيرها.',
                  style: TextStyle(fontSize: 11, color: colors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildApiKeyCard(AppColorsExtension colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '🔑 API Key',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _apiKeyController,
            obscureText: _obscureKey,
            decoration: InputDecoration(
              hintText: 'api-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx',
              hintStyle: TextStyle(fontSize: 12, color: colors.textTertiary),
              prefixIcon: const Icon(Icons.key),
              suffixIcon: IconButton(
                icon:
                    Icon(_obscureKey ? Icons.visibility_off : Icons.visibility),
                onPressed: () => setState(() => _obscureKey = !_obscureKey),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'احصل على API key من console.oomol.com',
            style: TextStyle(fontSize: 11, color: colors.textTertiary),
          ),
        ],
      ),
    );
  }

  Widget _buildPackageCard(AppColorsExtension colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '📦 Package',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'اسم الـ package المنشور على OOMOL Cloud (لإنشاء مهام)',
            style: TextStyle(fontSize: 11, color: colors.textSecondary),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _packageNameController,
            decoration: InputDecoration(
              labelText: 'Package Name',
              hintText: '@your-org/your-package',
              prefixIcon: const Icon(Icons.inventory_2),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _packageVersionController,
            decoration: InputDecoration(
              labelText: 'Package Version',
              hintText: 'latest or 1.0.0',
              prefixIcon: const Icon(Icons.tag),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardCard(AppColorsExtension colors) {
    final d = _dashboard!;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.successContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.success.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.dashboard, color: colors.success, size: 20),
              const SizedBox(width: 8),
              Text(
                '📊 معلومات الحساب',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: colors.onSuccessContainer,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildInfoChip(
                colors,
                icon: Icons.flash_on,
                label: 'متزامن',
                value: '${d.activeTasks}/${d.maxConcurrency}',
              ),
              const SizedBox(width: 8),
              _buildInfoChip(
                colors,
                icon: Icons.queue,
                label: 'طابور',
                value: '${d.queued}/${d.maxQueueSize}',
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildInfoChip(
                colors,
                icon: Icons.play_arrow,
                label: 'قيد التشغيل',
                value: '${d.running}',
              ),
              const SizedBox(width: 8),
              _buildInfoChip(
                colors,
                icon: d.paused ? Icons.pause_circle : Icons.check_circle,
                label: 'الحالة',
                value: d.paused ? 'متوقف' : 'نشط',
                color: d.paused ? colors.warning : colors.success,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(
    AppColorsExtension colors, {
    required IconData icon,
    required String label,
    required String value,
    Color? color,
  }) {
    final chipColor = color ?? colors.primary;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: colors.card,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: chipColor),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: chipColor,
                    ),
                  ),
                  Text(
                    label,
                    style: TextStyle(fontSize: 9, color: colors.textTertiary),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQueueControls(AppColorsExtension colors) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _loading ? null : _pauseQueue,
            icon: _loading
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.pause),
            label: const Text('إيقاف الطابور'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: FilledButton.icon(
            onPressed: _loading ? null : _resumeQueue,
            icon: _loading
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.play_arrow),
            label: const Text('استئناف'),
          ),
        ),
      ],
    );
  }

  Widget _buildTasksCard(AppColorsExtension colors) {
    return Container(
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              '📋 المهام الأخيرة (${_tasks.length})',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: colors.textPrimary,
              ),
            ),
          ),
          const Divider(height: 1),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _tasks.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (_, i) {
              final t = _tasks[i];
              return _buildTaskTile(colors, t);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTaskTile(AppColorsExtension colors, OomolTask t) {
    final statusColor = t.isSuccess
        ? colors.success
        : t.isFailed
            ? colors.error
            : t.isRunning
                ? colors.info
                : colors.textTertiary;

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: statusColor.withValues(alpha: 0.15),
        child: Icon(
          t.isSuccess
              ? Icons.check
              : t.isFailed
                  ? Icons.close
                  : Icons.hourglass_top,
          color: statusColor,
          size: 18,
        ),
      ),
      title: Text(
        '${t.taskId.substring(0, t.taskId.length > 24 ? 24 : t.taskId.length)}...',
        style: TextStyle(
          fontFamily: 'monospace',
          fontSize: 11,
          color: colors.textPrimary,
        ),
      ),
      subtitle: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              t.status,
              style: TextStyle(
                  fontSize: 9, color: statusColor, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '${t.progress}%',
            style: TextStyle(fontSize: 10, color: colors.textSecondary),
          ),
          if (t.createdAtDate != null) ...[
            const SizedBox(width: 6),
            // 🎨flutter-fix-layout-issues: Flexible + ellipsis للـ timestamp
            Flexible(
              child: Text(
                t.createdAtDate!.toLocal().toString().substring(0, 16),
                style: TextStyle(fontSize: 10, color: colors.textTertiary),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
