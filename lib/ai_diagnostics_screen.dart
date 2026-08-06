// ============================================================
//  AI Diagnostics Screen — شاشة التشخيص بالذكاء الاصطناعي
//  - محادثة تفاعلية مع الـ AI
//  - زر تشخيص سريع يجمع بيانات MikroTik
//  - عرض الأوامر المقترحة مع زر نسخ
//  - تنفيذ سكربتات متعددة الأوامر (Script execution)
//  - إصلاح تلقائي (Auto-Fix) بدون AI
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'ai/diagnostics_models.dart';
import 'ai/diagnostics_provider.dart';
import 'ai/ai_settings_screen.dart';
import 'ai/diagnostics_history_screen.dart';
import 'ai/command_executor.dart';
import 'ai/script_executor.dart';
import 'ai/auto_fix_service.dart';
import 'ai/fix_plan_dialog.dart';
import 'snackbar_helpers.dart';

import 'theme/app_theme.dart';
import 'services/secure_clipboard.dart';

class AiDiagnosticsScreen extends ConsumerStatefulWidget {
  const AiDiagnosticsScreen({super.key});

  @override
  ConsumerState<AiDiagnosticsScreen> createState() =>
      _AiDiagnosticsScreenState();
}

class _AiDiagnosticsScreenState extends ConsumerState<AiDiagnosticsScreen> {
  final _inputController = TextEditingController();
  final _scrollController = ScrollController();
  bool _inputEnabled = true;

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _handleSend() async {
    final text = _inputController.text.trim();
    if (text.isEmpty) return;

    _inputController.clear();
    setState(() => _inputEnabled = false);

    try {
      // إذا كانت أول رسالة، نشغّل تشخيص كامل
      final hasSnapshot = ref.read(diagnosticsProvider).lastSnapshot != null;
      if (hasSnapshot) {
        await ref.read(diagnosticsProvider.notifier).askFollowUp(text);
      } else {
        await ref.read(diagnosticsProvider.notifier).runDiagnostics(
              userQuery: text,
            );
      }
    } finally {
      if (mounted) {
        setState(() => _inputEnabled = true);
        _scrollToBottom();
      }
    }
  }

  Future<void> _handleQuickDiagnose() async {
    setState(() => _inputEnabled = false);
    try {
      await ref.read(diagnosticsProvider.notifier).runDiagnostics();
    } finally {
      if (mounted) {
        setState(() => _inputEnabled = true);
        _scrollToBottom();
      }
    }
  }

  /// تشخيص وكيل عميق: يستقصي البيانات خطوة بخطوة (أوامر قراءة تلقائية)
  /// حتى الوصول للسبب الجذري، ثم يقترح إصلاحاً لتنفيذه بموافقة المستخدم.
  Future<void> _handleAgenticDiagnose() async {
    final text = _inputController.text.trim();
    _inputController.clear();
    setState(() => _inputEnabled = false);
    try {
      await ref.read(diagnosticsProvider.notifier).runAgenticDiagnostics(
            userQuery: text.isEmpty ? null : text,
          );
    } finally {
      if (mounted) {
        setState(() => _inputEnabled = true);
        _scrollToBottom();
      }
    }
  }

  Future<void> _copyCommand(String command) async {
    await SecureClipboard.copy(command, sensitive: false);
    if (mounted) showSuccessSnackBar(context, 'تم نسخ الأمر: $command');
  }

  Future<void> _copyAllDiagnostics() async {
    final state = ref.read(diagnosticsProvider);
    if (state.messages.isEmpty) return;
    final buffer = StringBuffer();
    for (final msg in state.messages) {
      final prefix = msg.type == MessageType.user
          ? '👤 أنت'
          : msg.type == MessageType.error
              ? '❌ خطأ'
              : msg.type == MessageType.system
                  ? 'ℹ️ نظام'
                  : '🤖 AI';
      buffer.writeln('[$prefix]');
      buffer.writeln(msg.content);
      buffer.writeln('');
    }
    await SecureClipboard.copy(buffer.toString().trim(), sensitive: false);
    if (mounted) {
      showSuccessSnackBar(
          context, 'تم نسخ ${state.messages.length} رسالة من التشخيص');
    }
  }

  Future<void> _copyMessage(String content) async {
    await SecureClipboard.copy(content, sensitive: false);
    if (mounted) showSuccessSnackBar(context, 'تم نسخ نص الرسالة');
  }

  /// ينفذ أمر RouterOS مباشرة (مع تأكيد المستخدم حسب الخطورة)
  Future<void> _handleExecuteCommand(String command) async {
    final riskLevel = CommandExecutor.classifyRisk(command);

    // اعرض تحذير للأوامر المتوسطة والخطرة
    if (riskLevel != CommandRiskLevel.safe) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Row(
            children: [
              Icon(
                riskLevel == CommandRiskLevel.dangerous
                    ? Icons.dangerous
                    : Icons.warning,
                color: riskLevel == CommandRiskLevel.dangerous
                    ? Theme.of(context).appColors.error
                    : Theme.of(context).appColors.warning,
              ),
              const SizedBox(width: 8),
              Text('تنفيذ أمر ${riskLevel.displayName}'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(riskLevel.warningMessage),
              const SizedBox(height: 16),
              const Text(
                'الأمر:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).textTheme.bodySmall?.color,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: SelectableText(
                  command,
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: riskLevel == CommandRiskLevel.dangerous
                    ? Theme.of(context).appColors.error
                    : Theme.of(context).primaryColor,
              ),
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text('تنفيذ',
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface)),
            ),
          ],
        ),
      );

      if (confirmed != true) return;
    }

    // نفّذ الأمر
    setState(() => _inputEnabled = false);
    try {
      final result =
          await ref.read(diagnosticsProvider.notifier).executeCommand(command);
      // حدّث السجل
      ref.read(historyManagerProvider.notifier).refresh();
      if (mounted) {
        if (result.success) {
          showSuccessSnackBar(context,
              'تم تنفيذ الأمر بنجاح (${result.elapsed.inMilliseconds}ms)');
        } else {
          showErrorSnackBar(context, 'فشل: ${result.error ?? "خطأ غير معروف"}');
        }
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) showErrorSnackBar(context, 'خطأ: $e');
    } finally {
      if (mounted) setState(() => _inputEnabled = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(diagnosticsProvider);

    // مزامنة الإعدادات مع الـ diagnostics notifier فقط عند تغيّرها فعلياً.
    // (سابقاً كان هذا يتم داخل build عبر whenData + addPostFrameCallback مما
    //  يسبّب حلقة إعادة بناء مستمرة كل إطار — تستنزف البطارية والأداء.)
    ref.listen(aiSettingsNotifierProvider, (previous, next) {
      next.whenData((settings) {
        ref.read(diagnosticsProvider.notifier).updateSettings(settings);
      });
    });

    // scroll تلقائي عند وصول رسالة جديدة
    ref.listen(diagnosticsProvider, (previous, next) {
      if (previous?.messages.length != next.messages.length) {
        _scrollToBottom();
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('تشخيص بالذكاء الاصطناعي'),
        actions: [
          // زر الإصلاح التلقائي (Auto-Fix)
          IconButton(
            icon: Icon(Icons.auto_fix_high,
                color: Theme.of(context).appColors.warning),
            tooltip: 'إصلاح تلقائي (بدون AI)',
            onPressed:
                state.isLoading ? null : () => _showAutoFixPanel(context),
          ),
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'سجل التشخيصات',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const DiagnosticsHistoryScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.cleaning_services),
            tooltip: 'مسح المحادثة',
            onPressed: () async {
              await ref.read(diagnosticsProvider.notifier).clearChat();
              ref.read(historyManagerProvider.notifier).refresh();
            },
          ),
          IconButton(
            icon: const Icon(Icons.copy_all),
            tooltip: 'نسخ كل التشخيص',
            onPressed: state.messages.isEmpty ? null : _copyAllDiagnostics,
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'إعدادات الـ AI',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const AiSettingsScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // شريط حالة الإعدادات
          if (!state.settings.isConfigured)
            _buildNotConfiguredBanner()
          else
            _buildStatusBar(state),

          // قائمة الرسائل
          Expanded(
            child: RepaintBoundary(
              child: ListView.builder(
                scrollCacheExtent: const ScrollCacheExtent.pixels(300),
                controller: _scrollController,
                padding: const EdgeInsets.all(12),
                itemCount: state.messages.length,
                itemBuilder: (context, index) {
                  final msg = state.messages[index];
                  return _MessageBubble(
                    message: msg,
                    onCopyCommand: _copyCommand,
                    onExecuteCommand: _handleExecuteCommand,
                    onExecuteScript: _handleExecuteScript,
                    onCopyAllCommands: (commands) async {
                      await SecureClipboard.copy(
                        commands.join('\n'),
                        sensitive: false,
                      );
                      if (context.mounted) {
                        showSuccessSnackBar(
                            context, 'تم نسخ ${commands.length} أمر');
                      }
                    },
                    onCopyMessage: _copyMessage,
                  );
                },
              ),
            ),
          ),

          // شريط حالة التحميل
          if (state.isLoading)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
              child: Row(
                children: [
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      state.loadingStage ?? 'جاري المعالجة...',
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),

          // ===== صندوق الإدخال + زر التشخيص السريع =====
          // 🔧 إصلاح حرج: كان _buildInputBar معرّفاً لكن غير مستدعى!
          // بدون هذا السطر، المستخدم لا يستطيع إرسال رسائل أو تشغيل التشخيص
          _buildInputBar(state),
        ],
      ),
    );
  }

  /// ينفذ سكربت RouterOS كامل (عدة أوامر بالتسلسل)
  Future<void> _handleExecuteScript(RouterOsScript script) async {
    // أولاً: اعرض معاينة السكربت واطلب تأكيد المستخدم
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(
              script.isDangerous ? Icons.dangerous : Icons.movie,
              color: script.isDangerous
                  ? Theme.of(context).appColors.error
                  : (script.hasModerate
                      ? Theme.of(context).appColors.warning
                      : Theme.of(context).appColors.success),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'تنفيذ سكربت: ${script.title}',
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  script.description,
                  style: TextStyle(
                      fontSize: 13,
                      color: Theme.of(context).textTheme.bodySmall?.color),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).textTheme.bodySmall?.color,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: SelectableText(
                    ScriptExecutor.previewScript(script),
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11,
                      color: Theme.of(context).appColors.success,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                if (script.isDangerous)
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .appColors
                          .error
                          .withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                          color: Theme.of(context)
                              .appColors
                              .error
                              .withValues(alpha: 0.5)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.warning,
                            color: Theme.of(context).appColors.error, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'هذا السكربت يحتوي على أوامر خطرة. سيتم عمل backup تلقائياً قبل التنفيذ.',
                            style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context).appColors.error),
                          ),
                        ),
                      ],
                    ),
                  )
                else if (script.hasModerate)
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .appColors
                          .warning
                          .withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info,
                            color: Theme.of(context).appColors.warning,
                            size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'سيتم عمل backup تلقائياً قبل التنفيذ.',
                            style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context).appColors.warning),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: script.isDangerous
                  ? Theme.of(context).appColors.error
                  : Theme.of(context).primaryColor,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            icon: Icon(Icons.play_arrow,
                color: Theme.of(context).colorScheme.onSurface),
            label: Text('تنفيذ',
                style:
                    TextStyle(color: Theme.of(context).colorScheme.onSurface)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // تنفيذ السكربت عبر الـ provider
    setState(() => _inputEnabled = false);
    try {
      final result =
          await ref.read(diagnosticsProvider.notifier).executeScript(script);
      if (mounted) {
        if (result.overallSuccess) {
          showSuccessSnackBar(
            context,
            '✅ تم تنفيذ السكربت بنجاح (${result.successCount}/${result.script.commands.length})',
          );
        } else {
          showErrorSnackBar(
            context,
            '⚠️ اكتمل مع ${result.failureCount} خطأ',
          );
        }
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) showErrorSnackBar(context, 'خطأ: $e');
    } finally {
      if (mounted) setState(() => _inputEnabled = true);
    }
  }

  /// يعرض لوحة الإصلاحات التلقائية المقترحة
  void _showAutoFixPanel(BuildContext context) {
    final fixes = ref.read(diagnosticsProvider.notifier).getProposedAutoFixes();
    final hasSnapshot = ref.read(diagnosticsProvider).lastSnapshot != null;

    if (fixes.isEmpty) {
      // لا توجد إصلاحات — اعرض رسالة
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.check_circle,
                  color: Theme.of(context).appColors.success),
              const SizedBox(width: 8),
              const Text('لا توجد إصلاحات'),
            ],
          ),
          content: Text(
            !hasSnapshot
                ? 'لم يتم جمع بيانات من MikroTik بعد. اضغط زر "تشخيص سريع" أولاً.'
                : 'لم يتم اكتشاف مشاكل تتطلب إصلاحاً تلقائياً. كل شيء يبدو جيداً!',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('حسناً'),
            ),
          ],
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ===== رأس اللوحة =====
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.auto_fix_high,
                      color: Theme.of(context).appColors.warning, size: 24),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'الإصلاحات التلقائية المقترحة',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${fixes.length} إصلاح مقترح — بدون الحاجة للـ AI',
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).hintColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // ===== قائمة الإصلاحات =====
            Flexible(
              child: RepaintBoundary(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: fixes.length,
                  itemBuilder: (ctx, index) {
                    final fix = fixes[index];
                    return _buildAutoFixTile(fix);
                  },
                ),
              ),
            ),

            const Divider(height: 1),
            // ===== زر تطبيق كل الإصلاحات الآمنة =====
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  // زر خطة شاملة (dry-run + snapshot + apply + rollback)
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _showFixPlanDialog(ctx, fixes),
                      icon: Icon(Icons.checklist,
                          color: Theme.of(context).appColors.primary),
                      label: Text(
                        '📋 خطة شاملة (معاينة + تنفيذ آمن + استعادة)',
                        style: TextStyle(
                            color: Theme.of(context).appColors.primary),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                            color: Theme.of(context).appColors.primary),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // زر التطبيق السريع للإصلاحات الآمنة فقط
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        _applyAllSafeFixes(fixes);
                      },
                      icon: Icon(Icons.bolt,
                          color: Theme.of(context).colorScheme.onSurface),
                      label: Text(
                        'تطبيق كل الإصلاحات الآمنة فقط',
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).appColors.success,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// بناء عنصر إصلاح في القائمة
  Widget _buildAutoFixTile(ProposedFix fix) {
    final riskColor = fix.risk == CommandRiskLevel.dangerous
        ? Theme.of(context).appColors.error
        : fix.risk == CommandRiskLevel.moderate
            ? Theme.of(context).appColors.warning
            : Theme.of(context).appColors.success;

    return ExpansionTile(
      leading: CircleAvatar(
        backgroundColor: riskColor.withValues(alpha: 0.2),
        child: Text(
          fix.category.icon,
          style: const TextStyle(fontSize: 18),
        ),
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              fix.title,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ),
          if (fix.autoApplySafe)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color:
                    Theme.of(context).appColors.success.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'تلقائي',
                style: TextStyle(
                    fontSize: 10, color: Theme.of(context).appColors.success),
              ),
            ),
        ],
      ),
      subtitle: Text(
        '${fix.category.displayName} • ${fix.risk.displayName}',
        style: TextStyle(fontSize: 11, color: riskColor),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '📝 الوصف:',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                fix.description,
                style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).textTheme.bodySmall?.color),
              ),
              const SizedBox(height: 8),
              const Text(
                '⚠️ الأثر:',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                fix.impact,
                style: TextStyle(
                    fontSize: 12, color: Theme.of(context).appColors.warning),
              ),
              const SizedBox(height: 8),
              const Text(
                '🔧 الأوامر:',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).textTheme.bodySmall?.color,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: SelectableText(
                  fix.script.commands.join('\n'),
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 11,
                    color: Theme.of(context).appColors.success,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () {
                      // نسخ الأوامر فقط
                      final commands = fix.script.commands.join('\n');
                      SecureClipboard.copy(commands, sensitive: false);
                      if (mounted) {
                        showSuccessSnackBar(context,
                            'تم نسخ ${fix.script.commands.length} أمر');
                      }
                    },
                    icon: const Icon(Icons.copy, size: 16),
                    label: const Text('نسخ'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      _handleExecuteScript(fix.script);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: riskColor,
                    ),
                    icon: Icon(Icons.play_arrow,
                        size: 16,
                        color: Theme.of(context).colorScheme.onSurface),
                    label: Text('تنفيذ',
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// يطبّق كل الإصلاحات الآمنة (safe) بالتسلسل
  Future<void> _applyAllSafeFixes(List<ProposedFix> fixes) async {
    final safeFixes = fixes.where((f) => f.autoApplySafe).toList();

    if (safeFixes.isEmpty) {
      showSuccessSnackBar(context,
          'لا توجد إصلاحات آمنة للتطبيق التلقائي. راجع الإصلاحات يدوياً.');
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.bolt, color: Theme.of(context).appColors.success),
            const SizedBox(width: 8),
            const Text('تطبيق الإصلاحات الآمنة'),
          ],
        ),
        content: Text(
          'سيتم تطبيق ${safeFixes.length} إصلاح آمن بالتسلسل:\n\n'
          '${safeFixes.map((f) => "✅ ${f.title}").join('\n')}\n\n'
          'هل تريد المتابعة؟',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).appColors.success),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text('تطبيق',
                style:
                    TextStyle(color: Theme.of(context).colorScheme.onSurface)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // تنفيذ كل إصلاح آمن بالتسلسل
    setState(() => _inputEnabled = false);
    var successCount = 0;
    var failureCount = 0;

    for (final fix in safeFixes) {
      try {
        final result =
            await ref.read(diagnosticsProvider.notifier).applyAutoFix(fix);
        if (result.overallSuccess) {
          successCount++;
        } else {
          failureCount++;
        }
      } catch (e) {
        failureCount++;
        debugPrint('AutoFix failed: $e');
      }
    }

    if (mounted) {
      showSuccessSnackBar(
        context,
        '✅ $successCount نجح، $failureCount فشل من ${safeFixes.length} إصلاح',
      );
      _scrollToBottom();
      setState(() => _inputEnabled = true);
    }
  }

  /// يفتح نافذة خطة الإصلاح الشاملة (dry-run + تنفيذ آمن + rollback)
  /// مستوحى من router diagnostics (plan_changes + apply_plan + rollback_change)
  Future<void> _showFixPlanDialog(
      BuildContext parentContext, List<ProposedFix> fixes) async {
    // أغلق نافذة قائمة الإصلاحات أولاً
    Navigator.of(parentContext).pop();

    // جلب الـ snapshot الحالي من الـ provider
    final diagState = ref.read(diagnosticsProvider);
    final snapshot = diagState.lastSnapshot;
    if (snapshot == null) {
      showSuccessSnackBar(
          context, 'لا توجد بيانات تشخيص متاحة. شغّل التشخيص أولاً.');
      return;
    }

    // إنشاء خطة
    final plan = PlanService.createPlan(
      fixes: fixes,
      snapshot: snapshot,
      title: 'خطة إصلاح (${fixes.length} إصلاحات)',
    );

    // تحديد طريقة الاتصال
    const method = MikrotikConnectionMethod.routerOS;

    if (!mounted) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => FixPlanDialog(
        plan: plan,
        method: method,
      ),
    );

    // بعد إغلاق النافذة، حدّث الحالة
    if (mounted) {
      _scrollToBottom();
      setState(() {});
    }
  }

  Widget _buildNotConfiguredBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      color: Theme.of(context).appColors.warning.withValues(alpha: 0.2),
      child: Row(
        children: [
          Icon(Icons.warning_amber, color: Theme.of(context).appColors.warning),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'لم يتم إعداد مفتاح AI. اضغط على أيقونة الإعدادات.',
              style: TextStyle(fontSize: 13),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const AiSettingsScreen()),
            ),
            child: const Text('إعداد'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBar(DiagnosticsState state) {
    final isGeminiFlash25 = state.settings.provider == AiProvider.gemini &&
        state.settings.model == 'gemini-2.5-flash';
    final isOpenRouterFlash =
        state.settings.provider == AiProvider.openRouter &&
            state.settings.model == 'google/gemini-2.5-flash';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      color: Theme.of(context).colorScheme.surface,
      child: Row(
        children: [
          Icon(
            state.settings.provider == AiProvider.openAI
                ? Icons.smart_toy
                : state.settings.provider == AiProvider.openRouter
                    ? Icons.swap_horiz
                    : Icons.auto_awesome,
            size: 16,
            color: state.settings.provider == AiProvider.openRouter
                ? Colors.purpleAccent
                : Theme.of(context).textTheme.bodySmall?.color,
          ),
          const SizedBox(width: 8),
          // ===== زر تبديل المزود/الموديل السريع =====
          InkWell(
            onTap: () => _showQuickModelSelector(context),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isOpenRouterFlash
                    ? Colors.purpleAccent.withValues(alpha: 0.25)
                    : isGeminiFlash25
                        ? Theme.of(context)
                            .appColors
                            .info
                            .withValues(alpha: 0.25)
                        : Theme.of(context)
                            .primaryColor
                            .withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
                border: isOpenRouterFlash
                    ? Border.all(
                        color: Colors.purpleAccent.withValues(alpha: 0.5))
                    : isGeminiFlash25
                        ? Border.all(
                            color: Theme.of(context)
                                .appColors
                                .info
                                .withValues(alpha: 0.5))
                        : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isOpenRouterFlash
                        ? Icons.swap_horiz
                        : isGeminiFlash25
                            ? Icons.bolt
                            : Icons.memory,
                    size: 12,
                    color: isOpenRouterFlash
                        ? Colors.purpleAccent
                        : isGeminiFlash25
                            ? Theme.of(context).appColors.info
                            : Theme.of(context).textTheme.bodySmall?.color,
                  ),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      '${state.settings.provider.displayName} • ${state.settings.model}',
                      style: TextStyle(
                        fontSize: 11,
                        color: isOpenRouterFlash
                            ? Colors.purpleAccent
                            : isGeminiFlash25
                                ? Theme.of(context).appColors.info
                                : Theme.of(context).colorScheme.onSurface,
                        fontWeight: isOpenRouterFlash || isGeminiFlash25
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.keyboard_arrow_down,
                      size: 14, color: Theme.of(context).hintColor),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          // ===== selector لوضع التشخيص =====
          InkWell(
            onTap: () => _showModeSelector(context, state.settings.mode),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(state.settings.mode.icon,
                      size: 12, color: Theme.of(context).colorScheme.onSurface),
                  const SizedBox(width: 4),
                  Text(
                    state.settings.mode.displayName,
                    style: TextStyle(
                        fontSize: 11,
                        color: Theme.of(context).colorScheme.onSurface),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// نافذة منبثقة لاختيار الموديل بسرعة (مع تمييز Gemini 2.5 Flash كموصى به)
  void _showQuickModelSelector(BuildContext context) {
    final settingsAsync = ref.read(aiSettingsNotifierProvider);
    final settings = settingsAsync.valueOrNull ?? AiSettings.default_;

    // قائمة الموديلات الموصى بها (تبرز Gemini 2.5 Flash)
    const recommendedGemini = 'gemini-2.5-flash';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ===== رأس النافذة =====
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.swap_horiz,
                      color: Theme.of(context).appColors.info),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'اختر الموديل',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.settings, size: 20),
                    tooltip: 'إعدادات متقدمة',
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const AiSettingsScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // ===== قسم: OpenRouter (الافتراضي) =====
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Row(
                  children: [
                    Icon(Icons.swap_horiz,
                        size: 14, color: Colors.purpleAccent),
                    SizedBox(width: 4),
                    Text(
                      'OpenRouter (نماذج متعددة)',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.purpleAccent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            for (final model in AiProvider.openRouter.availableModels)
              _buildModelTile(
                ctx: ctx,
                provider: AiProvider.openRouter,
                model: model,
                isSelected: settings.provider == AiProvider.openRouter &&
                    settings.model == model,
                isRecommended: model == 'google/gemini-2.5-flash',
                description: _openRouterModelDescription(model),
              ),

            const Divider(height: 1),

            // ===== قسم: Gemini =====
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Row(
                  children: [
                    Icon(Icons.auto_awesome,
                        size: 14, color: Theme.of(context).appColors.info),
                    const SizedBox(width: 4),
                    Text(
                      'Google Gemini',
                      style: TextStyle(
                        fontSize: 13,
                        color: Theme.of(context).appColors.info,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            for (final model in AiProvider.gemini.availableModels)
              _buildModelTile(
                ctx: ctx,
                provider: AiProvider.gemini,
                model: model,
                isSelected: settings.provider == AiProvider.gemini &&
                    settings.model == model,
                isRecommended: model == recommendedGemini,
                description: _geminiModelDescription(model),
              ),

            const Divider(height: 1),

            // ===== قسم: OpenAI =====
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Row(
                  children: [
                    Icon(Icons.smart_toy,
                        size: 14, color: Theme.of(context).appColors.success),
                    const SizedBox(width: 4),
                    Text(
                      'OpenAI (ChatGPT)',
                      style: TextStyle(
                        fontSize: 13,
                        color: Theme.of(context).appColors.success,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            for (final model in AiProvider.openAI.availableModels)
              _buildModelTile(
                ctx: ctx,
                provider: AiProvider.openAI,
                model: model,
                isSelected: settings.provider == AiProvider.openAI &&
                    settings.model == model,
                isRecommended: false,
                description: _openAiModelDescription(model),
              ),

            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  /// وصف موجز لنماذج Gemini
  String _geminiModelDescription(String model) {
    switch (model) {
      case 'gemini-2.5-flash':
        return 'سريع واقتصادي — مثالي للتشخيص اليومي ⚡';
      case 'gemini-2.5-pro':
        return 'الأكثر ذكاءً — للمشاكل المعقدة (أعلى تكلفة)';
      case 'gemini-1.5-flash':
        return 'نسخة سابقة سريعة (1.5)';
      case 'gemini-1.5-pro':
        return 'نسخة سابقة متقدمة (1.5)';
      default:
        return '';
    }
  }

  /// وصف موجز لنماذج OpenAI
  String _openAiModelDescription(String model) {
    switch (model) {
      case 'gpt-4o-mini':
        return 'اقتصادي وسريع';
      case 'gpt-4o':
        return 'متقدم ومتوازن';
      case 'gpt-4-turbo':
        return 'قوي للمشاكل المعقدة';
      default:
        return '';
    }
  }

  /// وصف موجز لنماذج OpenRouter
  String _openRouterModelDescription(String model) {
    switch (model) {
      case 'google/gemini-2.5-flash':
        return 'سريع واقتصادي — مثالي للتشخيص ⚡';
      case 'google/gemini-2.5-pro':
        return 'الأذكى — للمشاكل المعقدة';
      case 'meta-llama/llama-3.3-70b-instruct':
        return 'Llama 3.3 — مفتوح المصدر قوي';
      case 'qwen/qwen-2.5-72b-instruct':
        return 'Qwen 2.5 — دعم عربي ممتاز';
      case 'deepseek/deepseek-chat-v3-0324':
        return 'DeepSeek — قوي واقتصادي';
      case 'mistralai/mistral-small-3.1-24b-instruct':
        return 'Mistral — سريع وخفيف';
      default:
        return '';
    }
  }

  /// بناء عنصر موديل في القائمة
  Widget _buildModelTile({
    required BuildContext ctx,
    required AiProvider provider,
    required String model,
    required bool isSelected,
    required bool isRecommended,
    required String description,
  }) {
    return ListTile(
      leading: Icon(
        isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
        color: isSelected
            ? Theme.of(context).appColors.info
            : (isRecommended
                ? Theme.of(context).appColors.warning
                : Theme.of(context).disabledColor),
        size: 22,
      ),
      title: Row(
        children: [
          Flexible(
            child: Text(
              model,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 13,
                fontWeight: isSelected || isRecommended
                    ? FontWeight.bold
                    : FontWeight.normal,
                color: isSelected
                    ? Theme.of(context).appColors.info
                    : (isRecommended
                        ? Theme.of(context).appColors.warning
                        : Theme.of(context).colorScheme.onSurface),
              ),
            ),
          ),
          if (isRecommended) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color:
                    Theme.of(context).appColors.warning.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                    color: Theme.of(context)
                        .appColors
                        .warning
                        .withValues(alpha: 0.5)),
              ),
              child: Text(
                'موصى به',
                style: TextStyle(
                    fontSize: 10,
                    color: Theme.of(context).appColors.warning,
                    fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ],
      ),
      subtitle: description.isEmpty
          ? null
          : Text(
              description,
              style:
                  TextStyle(fontSize: 11, color: Theme.of(context).hintColor),
            ),
      trailing: isRecommended
          ? Icon(Icons.bolt,
              color: Theme.of(context).appColors.warning, size: 18)
          : null,
      onTap: () async {
        await ref
            .read(aiSettingsNotifierProvider.notifier)
            .setProviderAndModel(provider, model);
        // حدّث الـ diagnostics notifier بالإعدادات الجديدة
        final newSettings = (ref.read(aiSettingsNotifierProvider).valueOrNull ??
                AiSettings.default_)
            .copyWith(provider: provider, model: model);
        ref.read(diagnosticsProvider.notifier).updateSettings(newSettings);
        if (ctx.mounted) Navigator.of(ctx).pop();
      },
    );
  }

  /// يعرض نافذة اختيار وضع التشخيص
  void _showModeSelector(BuildContext context, DiagnosticMode currentMode) {
    final settingsAsync = ref.read(aiSettingsNotifierProvider);
    final settings = settingsAsync.valueOrNull ?? AiSettings.default_;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'اختر نوع التشخيص',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            const Divider(height: 1),
            ...DiagnosticMode.values.map((mode) {
              final isSelected = mode == currentMode;
              return ListTile(
                leading: Icon(mode.icon,
                    color: isSelected
                        ? Theme.of(context).primaryColor
                        : Theme.of(context).textTheme.bodySmall?.color),
                title: Text(mode.displayName),
                subtitle: Text(
                  mode.description,
                  style: TextStyle(
                      fontSize: 12, color: Theme.of(context).hintColor),
                ),
                trailing: isSelected
                    ? Icon(Icons.check_circle,
                        color: Theme.of(context).primaryColor)
                    : null,
                onTap: () {
                  ref.read(aiSettingsNotifierProvider.notifier).setMode(mode);
                  ref.read(diagnosticsProvider.notifier).updateSettings(
                        settings.copyWith(mode: mode),
                      );
                  Navigator.of(ctx).pop();
                },
              );
            }),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildInputBar(DiagnosticsState state) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          border: Border(
            top: BorderSide(
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.1)),
          ),
        ),
        child: Row(
          children: [
            // زر التشخيص السريع (لقطة واحدة)
            IconButton(
              icon: const Icon(Icons.auto_fix_high),
              tooltip: 'تشخيص سريع (لقطة واحدة)',
              onPressed: state.isLoading ? null : _handleQuickDiagnose,
              color: Theme.of(context).primaryColor,
            ),
            // زر التشخيص العميق الوكيل (استقصاء خطوة بخطوة)
            IconButton(
              icon: const Icon(Icons.psychology),
              tooltip: 'تشخيص عميق وكيل (استقصاء خطوة بخطوة)',
              onPressed: state.isLoading ? null : _handleAgenticDiagnose,
              color: Colors.deepPurpleAccent,
            ),
            // حقل الإدخال
            Expanded(
              child: TextField(
                controller: _inputController,
                enabled: _inputEnabled && !state.isLoading,
                decoration: InputDecoration(
                  hintText: 'اكتب سؤالك أو صف المشكلة...',
                  hintStyle: const TextStyle(fontSize: 13),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Theme.of(context).scaffoldBackgroundColor,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                ),
                style: const TextStyle(fontSize: 14),
                maxLines: 3,
                minLines: 1,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _handleSend(),
              ),
            ),
            const SizedBox(width: 8),
            // زر الإرسال
            IconButton(
              icon: const Icon(Icons.send),
              onPressed: _inputEnabled && !state.isLoading ? _handleSend : null,
              color: Theme.of(context).primaryColor,
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
//  فقاعة الرسالة
// ============================================================
class _MessageBubble extends StatelessWidget {
  final DiagnosticMessage message;
  final void Function(String) onCopyCommand;
  final void Function(String) onExecuteCommand;
  final void Function(RouterOsScript)? onExecuteScript;
  final void Function(List<String>)? onCopyAllCommands;
  final void Function(String)? onCopyMessage;

  const _MessageBubble({
    required this.message,
    required this.onCopyCommand,
    required this.onExecuteCommand,
    this.onExecuteScript,
    this.onCopyAllCommands,
    this.onCopyMessage,
  });

  @override
  Widget build(BuildContext context) {
    final isUser = message.type == MessageType.user;
    final isError = message.type == MessageType.error;
    final isSystem = message.type == MessageType.system;

    if (isSystem) {
      return _buildSystemMessage(context);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) _buildAvatar(context),
          Flexible(
            child: Stack(
              children: [
                Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.85,
                  ),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isError
                        ? Theme.of(context)
                            .appColors
                            .error
                            .withValues(alpha: 0.1)
                        : isUser
                            ? Theme.of(context).primaryColor
                            : Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: Radius.circular(isUser ? 16 : 4),
                      bottomRight: Radius.circular(isUser ? 4 : 16),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // محتوى الرسالة
                      SelectableText(
                        message.content,
                        style: TextStyle(
                          color: isUser
                              ? Theme.of(context).colorScheme.onSurface
                              : Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withValues(alpha: 0.9),
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),
                      // الأوامر المقترحة
                      if (message.suggestedCommands != null &&
                          message.suggestedCommands!.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Divider(
                            height: 1, color: Theme.of(context).dividerColor),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'أوامر مقترحة (اضغط للنسخ):',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Theme.of(context).hintColor,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            // ===== زر نسخ الكل =====
                            if (onCopyAllCommands != null)
                              TextButton.icon(
                                onPressed: () => onCopyAllCommands!(
                                    message.suggestedCommands!),
                                icon: Icon(Icons.copy_all,
                                    size: 14,
                                    color: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.color),
                                label: Text('نسخ الكل',
                                    style: TextStyle(
                                        fontSize: 11,
                                        color: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.color)),
                                style: TextButton.styleFrom(
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 6),
                                  minimumSize: const Size(0, 28),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        for (final cmd in message.suggestedCommands!)
                          _CommandChip(
                            command: cmd,
                            onCopy: () => onCopyCommand(cmd),
                            onExecute: () => onExecuteCommand(cmd),
                          ),
                        // ===== زر تنفيذ السكربت كاملاً =====
                        if (onExecuteScript != null &&
                            message.suggestedCommands!.length > 1) ...[
                          const SizedBox(height: 8),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                final script = RouterOsScript.fromText(
                                  title: 'سكربت AI',
                                  description:
                                      'سكربت مُولّد من اقتراحات الـ AI (${message.suggestedCommands!.length} أوامر)',
                                  text: message.suggestedCommands!.join('\n'),
                                );
                                onExecuteScript!(script);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(context).primaryColor,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 10),
                              ),
                              icon: Icon(Icons.play_circle_fill,
                                  color:
                                      Theme.of(context).colorScheme.onSurface,
                                  size: 18),
                              label: Text(
                                'تنفيذ السكربت كاملاً (${message.suggestedCommands!.length} أوامر)',
                                style: TextStyle(
                                    color:
                                        Theme.of(context).colorScheme.onSurface,
                                    fontSize: 12),
                              ),
                            ),
                          ),
                        ],
                      ],
                      // ===== استخراج السكربتات من محتوى الرسالة نفسها =====
                      // للرسائل التي لا تحتوي على suggestedCommands لكنها تحتوي
                      // على سكربتات داخل كتل ```...``` أو أسطر تبدأ بـ /
                      if (onExecuteScript != null &&
                          (message.suggestedCommands == null ||
                              message.suggestedCommands!.isEmpty) &&
                          message.type == MessageType.assistant) ...[
                        ..._buildExtractedScripts(
                            context, message, onExecuteScript!),
                      ],
                    ],
                  ),
                ),
                if (onCopyMessage != null && !isUser)
                  Positioned(
                    top: 4,
                    left: 4,
                    child: Material(
                      color: Colors.transparent,
                      child: IconButton(
                        onPressed: () => onCopyMessage!(message.content),
                        icon: Icon(Icons.copy,
                            size: 16,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.5)),
                        tooltip: 'نسخ نص الرسالة',
                        padding: const EdgeInsets.all(4),
                        constraints: const BoxConstraints(),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (isUser) _buildAvatar(context),
        ],
      ),
    );
  }

  /// يبني أزرار السكربتات المستخرجة من رسالة الـ AI
  /// يستخدم ScriptExecutor.extractScriptsFromAiResponse لاستخراج
  /// السكربتات من كتل ```...``` أو من أسطر تبدأ بـ / مباشرة
  List<Widget> _buildExtractedScripts(
    BuildContext context,
    DiagnosticMessage message,
    void Function(RouterOsScript) onExecuteScript,
  ) {
    final scripts = ScriptExecutor.extractScriptsFromAiResponse(
      aiResponse: message.content,
    );

    if (scripts.isEmpty) return [];

    return [
      const SizedBox(height: 12),
      Divider(height: 1, color: Theme.of(context).dividerColor),
      const SizedBox(height: 8),
      Row(
        children: [
          Icon(Icons.code,
              size: 14, color: Theme.of(context).appColors.warning),
          const SizedBox(width: 4),
          Text(
            'سكربتات جاهزة للتنفيذ (${scripts.length})',
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).appColors.warning,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
      const SizedBox(height: 6),
      for (var i = 0; i < scripts.length; i++) ...[
        _ScriptCard(
          script: scripts[i],
          onExecute: () => onExecuteScript(scripts[i]),
        ),
        if (i < scripts.length - 1) const SizedBox(height: 8),
      ],
    ];
  }

  Widget _buildAvatar(BuildContext context) {
    final isUser = message.type == MessageType.user;
    return CircleAvatar(
      radius: 16,
      backgroundColor: isUser
          ? Theme.of(context).appColors.info
          : Theme.of(context).primaryColor,
      child: Icon(
        isUser
            ? Icons.person
            : message.type == MessageType.error
                ? Icons.error_outline
                : Icons.smart_toy,
        size: 18,
        color: Theme.of(context).colorScheme.onSurface,
      ),
    );
  }

  Widget _buildSystemMessage(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).primaryColor.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline,
              size: 18, color: Theme.of(context).primaryColor),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message.content,
              style: TextStyle(
                  fontSize: 13,
                  color: Theme.of(context).textTheme.bodySmall?.color),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
//  chip لأمر قابل للنسخ والتنفيذ
// ============================================================
class _CommandChip extends StatelessWidget {
  final String command;
  final VoidCallback onCopy;
  final VoidCallback onExecute;

  const _CommandChip({
    required this.command,
    required this.onCopy,
    required this.onExecute,
  });

  /// مستوى خطورة الأمر (لعرض أيقونة مناسبة)
  CommandRiskLevel get _riskLevel => CommandExecutor.classifyRisk(command);

  @override
  Widget build(BuildContext context) {
    final riskEmoji = _riskLevel == CommandRiskLevel.dangerous
        ? '🚨'
        : _riskLevel == CommandRiskLevel.moderate
            ? '⚠️'
            : '✅';

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: _riskLevel == CommandRiskLevel.dangerous
                ? Theme.of(context).appColors.error.withValues(alpha: 0.5)
                : Theme.of(context).dividerColor,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // الأمر نفسه + مستوى الخطورة
            Row(
              children: [
                Text(riskEmoji, style: const TextStyle(fontSize: 14)),
                const SizedBox(width: 6),
                Icon(Icons.terminal,
                    size: 14, color: Theme.of(context).appColors.success),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    command,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                      color: Theme.of(context).appColors.success,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            // أزرار النسخ والتنفيذ
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: onCopy,
                  icon: const Icon(Icons.copy, size: 14),
                  label: const Text('نسخ', style: TextStyle(fontSize: 12)),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: const Size(0, 30),
                    foregroundColor:
                        Theme.of(context).textTheme.bodySmall?.color,
                  ),
                ),
                const SizedBox(width: 4),
                ElevatedButton.icon(
                  onPressed: onExecute,
                  icon: const Icon(Icons.play_arrow, size: 14),
                  label: const Text('تنفيذ', style: TextStyle(fontSize: 12)),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    minimumSize: const Size(0, 30),
                    backgroundColor: _riskLevel == CommandRiskLevel.dangerous
                        ? Theme.of(context).appColors.error
                        : Theme.of(context).primaryColor,
                    foregroundColor: Theme.of(context).colorScheme.onSurface,
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

// ============================================================
//  بطاقة عرض سكربت قابل للتنفيذ (مستخرج من رد الـ AI)
// ============================================================
class _ScriptCard extends StatelessWidget {
  final RouterOsScript script;
  final VoidCallback onExecute;

  const _ScriptCard({
    required this.script,
    required this.onExecute,
  });

  @override
  Widget build(BuildContext context) {
    final riskColor = script.isDangerous
        ? Theme.of(context).appColors.error
        : script.hasModerate
            ? Theme.of(context).appColors.warning
            : Theme.of(context).appColors.success;

    final riskIcon = script.isDangerous
        ? Icons.dangerous
        : script.hasModerate
            ? Icons.warning
            : Icons.check_circle;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: riskColor.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ===== رأس البطاقة: العنوان + الخطورة =====
          Row(
            children: [
              Icon(riskIcon, size: 16, color: riskColor),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  script.title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: riskColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: riskColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  script.overallRisk.displayName,
                  style: TextStyle(fontSize: 10, color: riskColor),
                ),
              ),
            ],
          ),
          if (script.description.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              script.description,
              style:
                  TextStyle(fontSize: 11, color: Theme.of(context).hintColor),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 8),
          // ===== معاينة الأوامر (أول 5) =====
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Theme.of(context).textTheme.bodySmall?.color,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = 0; i < script.commands.length && i < 5; i++)
                  Text(
                    '${i + 1}. ${script.commands[i]}',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 10,
                      color: Theme.of(context).appColors.success,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                if (script.commands.length > 5)
                  Text(
                    '... و ${script.commands.length - 5} أوامر أخرى',
                    style: TextStyle(
                      fontSize: 10,
                      color: Theme.of(context).disabledColor,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // ===== أزرار الإجراءات =====
          Row(
            children: [
              Text(
                '${script.commands.length} أوامر',
                style:
                    TextStyle(fontSize: 11, color: Theme.of(context).hintColor),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () {
                  final commandsText = script.commands.join('\n');
                  SecureClipboard.copy(commandsText, sensitive: false);
                },
                icon: const Icon(Icons.copy, size: 14),
                label: const Text('نسخ', style: TextStyle(fontSize: 11)),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  minimumSize: const Size(0, 28),
                  foregroundColor: Theme.of(context).textTheme.bodySmall?.color,
                ),
              ),
              const SizedBox(width: 4),
              ElevatedButton.icon(
                onPressed: onExecute,
                icon: Icon(Icons.play_arrow,
                    size: 14, color: Theme.of(context).colorScheme.onSurface),
                label: Text('تنفيذ',
                    style: TextStyle(
                        fontSize: 11,
                        color: Theme.of(context).colorScheme.onSurface)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: riskColor,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  minimumSize: const Size(0, 28),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
