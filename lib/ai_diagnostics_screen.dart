// ============================================================
//  AI Diagnostics Screen — شاشة التشخيص بالذكاء الاصطناعي
//  - محادثة تفاعلية مع الـ AI
//  - زر تشخيص سريع يجمع بيانات MikroTik
//  - عرض الأوامر المقترحة مع زر نسخ
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'ai/diagnostics_models.dart';
import 'ai/diagnostics_provider.dart';
import 'ai/ai_settings_screen.dart';
import 'ai/diagnostics_history_screen.dart';
import 'ai/command_executor.dart';
import 'snackbar_helpers.dart';

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

  Future<void> _copyCommand(String command) async {
    await Clipboard.setData(ClipboardData(text: command));
    if (mounted) showSuccessSnackBar(context, 'تم نسخ الأمر: $command');
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
                    ? Colors.red
                    : Colors.orange,
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
                  color: Colors.black54,
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
                    ? Colors.red
                    : Theme.of(context).primaryColor,
              ),
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('تنفيذ', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );

      if (confirmed != true) return;
    }

    // نفّذ الأمر
    setState(() => _inputEnabled = false);
    try {
      final result = await ref
          .read(diagnosticsProvider.notifier)
          .executeCommand(command);
      // حدّث السجل
      ref.read(historyManagerProvider.notifier).refresh();
      if (mounted) {
        if (result.success) {
          showSuccessSnackBar(
              context, 'تم تنفيذ الأمر بنجاح (${result.elapsed.inMilliseconds}ms)');
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
              // حدّث قائمة السجل
              ref.read(historyManagerProvider.notifier).refresh();
            },
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
                controller: _scrollController,
                padding: const EdgeInsets.all(12),
                cacheExtent: 300,
                itemCount: state.messages.length,
                itemBuilder: (context, index) {
                  final msg = state.messages[index];
                  return _MessageBubble(
                    message: msg,
                    onCopyCommand: _copyCommand,
                    onExecuteCommand: _handleExecuteCommand,
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

          // صندوق الإدخال + زر التشخيص السريع
          _buildInputBar(state),
        ],
      ),
    );
  }

  Widget _buildNotConfiguredBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      color: Colors.orange.withValues(alpha: 0.2),
      child: Row(
        children: [
          const Icon(Icons.warning_amber, color: Colors.orange),
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
    final isGeminiFlash25 =
        state.settings.provider == AiProvider.gemini &&
        state.settings.model == 'gemini-2.5-flash';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      color: Theme.of(context).cardColor,
      child: Row(
        children: [
          Icon(
            state.settings.provider == AiProvider.openAI
                ? Icons.smart_toy
                : Icons.auto_awesome,
            size: 16,
            color: Colors.white70,
          ),
          const SizedBox(width: 8),
          // ===== زر تبديل المزود/الموديل السريع =====
          InkWell(
            onTap: () => _showQuickModelSelector(context),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isGeminiFlash25
                    ? Colors.blueAccent.withValues(alpha: 0.25)
                    : Theme.of(context).primaryColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
                border: isGeminiFlash25
                    ? Border.all(color: Colors.blueAccent.withValues(alpha: 0.5))
                    : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isGeminiFlash25 ? Icons.bolt : Icons.memory,
                    size: 12,
                    color: isGeminiFlash25
                        ? Colors.blueAccent
                        : Colors.white70,
                  ),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      '${state.settings.provider.displayName} • ${state.settings.model}',
                      style: TextStyle(
                        fontSize: 11,
                        color: isGeminiFlash25
                            ? Colors.blueAccent
                            : Colors.white,
                        fontWeight: isGeminiFlash25
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.keyboard_arrow_down,
                      size: 14, color: Colors.white54),
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
                  Icon(state.settings.mode.icon, size: 12, color: Colors.white),
                  const SizedBox(width: 4),
                  Text(
                    state.settings.mode.displayName,
                    style: const TextStyle(fontSize: 11, color: Colors.white),
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
    final settings =
        settingsAsync.valueOrNull ?? AiSettings.default_;

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
                  const Icon(Icons.swap_horiz, color: Colors.blueAccent),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'اختر الموديل',
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
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

            // ===== قسم: Gemini (مع تمييز gemini-2.5-flash) =====
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Row(
                  children: [
                    Icon(Icons.auto_awesome, size: 14, color: Colors.blueAccent),
                    SizedBox(width: 4),
                    Text(
                      'Google Gemini',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.blueAccent,
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
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Row(
                  children: [
                    Icon(Icons.smart_toy, size: 14, color: Colors.greenAccent),
                    SizedBox(width: 4),
                    Text(
                      'OpenAI (ChatGPT)',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.greenAccent,
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
            ? Colors.blueAccent
            : (isRecommended ? Colors.amber : Colors.white38),
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
                fontWeight:
                    isSelected || isRecommended ? FontWeight.bold : FontWeight.normal,
                color: isSelected
                    ? Colors.blueAccent
                    : (isRecommended ? Colors.amber.shade200 : Colors.white),
              ),
            ),
          ),
          if (isRecommended) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.amber.withValues(alpha: 0.5)),
              ),
              child: const Text(
                'موصى به',
                style: TextStyle(fontSize: 10, color: Colors.amber, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ],
      ),
      subtitle: description.isEmpty
          ? null
          : Text(
              description,
              style: const TextStyle(fontSize: 11, color: Colors.white54),
            ),
      trailing: isRecommended
          ? const Icon(Icons.bolt, color: Colors.amber, size: 18)
          : null,
      onTap: () async {
        await ref
            .read(aiSettingsNotifierProvider.notifier)
            .setProviderAndModel(provider, model);
        // حدّث الـ diagnostics notifier بالإعدادات الجديدة
        final newSettings =
            (ref.read(aiSettingsNotifierProvider).valueOrNull ??
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
                        : Colors.white70),
                title: Text(mode.displayName),
                subtitle: Text(
                  mode.description,
                  style: const TextStyle(fontSize: 12, color: Colors.white54),
                ),
                trailing: isSelected
                    ? Icon(Icons.check_circle,
                        color: Theme.of(context).primaryColor)
                    : null,
                onTap: () {
                  ref
                      .read(aiSettingsNotifierProvider.notifier)
                      .setMode(mode);
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
          color: Theme.of(context).cardColor,
          border: Border(
            top: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
          ),
        ),
        child: Row(
          children: [
            // زر التشخيص السريع
            IconButton(
              icon: const Icon(Icons.auto_fix_high),
              tooltip: 'تشخيص سريع',
              onPressed: state.isLoading ? null : _handleQuickDiagnose,
              color: Theme.of(context).primaryColor,
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

  const _MessageBubble({
    required this.message,
    required this.onCopyCommand,
    required this.onExecuteCommand,
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
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.85,
              ),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isError
                    ? Colors.red.withValues(alpha: 0.1)
                    : isUser
                        ? Theme.of(context).primaryColor
                        : Theme.of(context).cardColor,
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
                      color: isUser ? Colors.white : Colors.white.withValues(alpha: 0.9),
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                  // الأوامر المقترحة
                  if (message.suggestedCommands != null &&
                      message.suggestedCommands!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    const Divider(height: 1, color: Colors.white24),
                    const SizedBox(height: 8),
                    const Text(
                      'أوامر مقترحة (اضغط للنسخ):',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white54,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 6),
                    for (final cmd in message.suggestedCommands!)
                      _CommandChip(
                        command: cmd,
                        onCopy: () => onCopyCommand(cmd),
                        onExecute: () => onExecuteCommand(cmd),
                      ),
                  ],
                ],
              ),
            ),
          ),
          if (isUser) _buildAvatar(context),
        ],
      ),
    );
  }

  Widget _buildAvatar(BuildContext context) {
    final isUser = message.type == MessageType.user;
    return CircleAvatar(
      radius: 16,
      backgroundColor: isUser ? Colors.blue : Theme.of(context).primaryColor,
      child: Icon(
        isUser
            ? Icons.person
            : message.type == MessageType.error
                ? Icons.error_outline
                : Icons.smart_toy,
        size: 18,
        color: Colors.white,
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
              style: const TextStyle(fontSize: 13, color: Colors.white70),
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
          color: Colors.black.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: _riskLevel == CommandRiskLevel.dangerous
                ? Colors.red.withValues(alpha: 0.5)
                : Colors.white24,
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
                const Icon(Icons.terminal, size: 14, color: Colors.greenAccent),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    command,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                      color: Colors.greenAccent,
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
                    foregroundColor: Colors.white70,
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
                        ? Colors.red
                        : Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
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
