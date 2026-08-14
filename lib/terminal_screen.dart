// ============================================================
//  Terminal Screen — تيرمنال تفاعلي لأوامر MikroTik RouterOS
//  - ينفّذ الأوامر عبر RouterOS API (8728) أو SSH (22)
//  - يعرض المخرجات كوحدة طرفية (console) مع سجل الأوامر
//  - تأكيد للأوامر الخطرة + أوامر سريعة جاهزة مصنّفة
//  - زر "تدقيق شامل" لتنفيذ كل أوامر الفئة بالتسلسل
// ============================================================

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'ai/command_executor.dart';
import 'ai/diagnostics_models.dart';
import 'snackbar_helpers.dart';

import 'theme/app_theme.dart';
import 'services/secure_clipboard.dart';

/// نوع سطر في مخرجات التيرمنال
enum _LineKind { prompt, output, error, info, header }

/// سطر واحد في شاشة التيرمنال
class _TermLine {
  final String text;
  final _LineKind kind;
  const _TermLine(this.text, this.kind);
}

/// فئات الأوامر السريعة في التيرمنال
enum _CmdCategory {
  system, // معلومات النظام
  security, // تدقيق أمني (firewall, services, users)
  qos, // طباعة QoS / Queues
  network, // واجهات وعناوين IP
  diagnostics, // تشخيص شبكي (ping/traceroute/bandwidth-test من الموجّه)
  advanced, // أدوات متقدمة (VRRP/certificates/interface lists/backup)
}

extension _CmdCategoryX on _CmdCategory {
  String get displayName {
    switch (this) {
      case _CmdCategory.system:
        return 'النظام';
      case _CmdCategory.security:
        return 'تدقيق أمني';
      case _CmdCategory.qos:
        return 'QoS';
      case _CmdCategory.network:
        return 'الشبكة';
      case _CmdCategory.diagnostics:
        return 'تشخيص شبكي';
      case _CmdCategory.advanced:
        return 'أدوات متقدمة';
    }
  }

  IconData get icon {
    switch (this) {
      case _CmdCategory.system:
        return Icons.memory;
      case _CmdCategory.security:
        return Icons.security;
      case _CmdCategory.qos:
        return Icons.speed;
      case _CmdCategory.network:
        return Icons.lan;
      case _CmdCategory.diagnostics:
        return Icons.network_ping;
      case _CmdCategory.advanced:
        return Icons.engineering;
    }
  }
}

class TerminalScreen extends StatefulWidget {
  const TerminalScreen({super.key});

  @override
  State<TerminalScreen> createState() => _TerminalScreenState();
}

class _TerminalScreenState extends State<TerminalScreen> {
  final _inputController = TextEditingController();
  final _scrollController = ScrollController();
  final _inputFocus = FocusNode();

  final List<_TermLine> _lines = [];
  final List<String> _history = []; // سجل الأوامر المُنفّذة (للاسترجاع)
  int _historyCursor = 0; // مؤشر التنقل في السجل

  MikrotikConnectionMethod _method = MikrotikConnectionMethod.routerOS;
  bool _busy = false;
  String _deviceIp = '';

  /// الفئة النشطة حالياً للأوامر السريعة
  _CmdCategory _activeCategory = _CmdCategory.security;

  /// خريطة الأوامر السريعة مصنّفة حسب الفئة
  static const _categorizedCommands = <_CmdCategory, List<String>>{
    _CmdCategory.system: <String>[
      '/system resource print',
      '/system identity print',
      '/system routerboard print',
      '/system package print',
      '/system clock print',
      '/log print',
    ],
    // فئة التدقيق الأمني — لرؤية firewall (filter+nat) + services + users كاملة
    _CmdCategory.security: <String>[
      '/ip firewall filter print',
      '/ip firewall nat print',
      '/ip firewall mangle print',
      '/ip firewall address-list print',
      '/ip firewall connection print',
      '/ip service print',
      '/user print',
      '/user group print',
      '/ip ssh print',
      '/system note print',
    ],
    // فئة QoS — طباعة كل أنواع الطوابير
    _CmdCategory.qos: <String>[
      '/queue simple print',
      '/queue tree print',
      '/queue type print',
      '/queue interface print',
      '/queue simple stats',
    ],
    _CmdCategory.network: <String>[
      '/interface print',
      '/ip address print',
      '/ip route print',
      '/ip dhcp-server lease print',
      '/ip dhcp-server network print',
      '/ip dns print',
      '/ip arp print',
    ],
    // فئة التشخيص الشبكي — أوامر تُنفّذ من الموجّه نفسه (router-originated)
    // مستوحاة من MikroMCP: ping, traceroute, bandwidth-test, fetch, torch
    // ملاحظة: هذه أوامر v6 متوافقة بالكامل (لا حاجة لـ v7)
    _CmdCategory.diagnostics: <String>[
      '/ping count=5 address=8.8.8.8',
      '/ping count=5 address=1.1.1.1',
      '/tool traceroute address=8.8.8.8',
      '/tool bandwidth-test address=127.0.0.1 protocol=tcp direction=both duration=10',
      '/tool torch port=80 ip-protocol=tcp',
      '/tool fetch url="https://www.google.com" mode=https keep-result=no',
      '/ip firewall connection print',
      '/tool netwatch print',
    ],
    // فئة الأدوات المتقدمة — VRRP, certificates, interface lists, backup, export
    // مستوحاة من MikroMCP: list_vrrp_instances, list_certificates, list_interface_lists, create_backup, export_config
    _CmdCategory.advanced: <String>[
      '/interface vrrp print',
      '/interface vrrp print detail',
      '/certificate print',
      '/interface list print',
      '/interface list member print',
      '/system backup save name=manual-backup',
      '/export',
      '/system history print',
      '/system script print',
      '/system scheduler print',
    ],
  };

  @override
  void initState() {
    super.initState();
    _loadDeviceInfo();
    _lines.add(const _TermLine(
      'MikroTik Terminal — اكتب أمر RouterOS ثم اضغط تنفيذ.\n'
      'مثال: /system resource print\n'
      'استخدم الفئات أعلاه للوصول السريع لأوامر التدقيق الأمني و QoS.',
      _LineKind.info,
    ));
  }

  Future<void> _loadDeviceInfo() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() => _deviceIp = prefs.getString('ip') ?? 'mikrotik');
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    _inputFocus.dispose();
    super.dispose();
  }

  String get _prompt => '[admin@$_deviceIp] >';

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _append(_TermLine line) {
    setState(() => _lines.add(line));
    _scrollToBottom();
  }

  Future<void> _runCommand([String? preset]) async {
    if (_busy) return;
    final command = (preset ?? _inputController.text).trim();
    if (command.isEmpty) return;

    // تأكيد للأوامر الخطرة فقط (reboot/reset/remove...)
    final risk = CommandExecutor.classifyRisk(command);
    if (risk == CommandRiskLevel.dangerous) {
      final ok = await _confirmDangerous(command);
      if (ok != true) return;
    }

    _inputController.clear();
    _history.add(command);
    _historyCursor = _history.length;

    // اعرض الأمر بصيغة prompt
    _append(_TermLine('$_prompt $command', _LineKind.prompt));

    setState(() => _busy = true);
    try {
      final result = await CommandExecutor.execute(
        command: command,
        method: _method,
        timeout: const Duration(seconds: 30),
      );

      if (result.success) {
        final out = result.output.trim();
        _append(_TermLine(
          out.isEmpty ? '(تم — بدون مخرجات)' : out,
          _LineKind.output,
        ));
      } else {
        _append(_TermLine(
          'خطأ: ${result.error ?? "فشل غير معروف"}',
          _LineKind.error,
        ));
      }
    } catch (e) {
      _append(_TermLine('استثناء: $e', _LineKind.error));
    } finally {
      if (mounted) {
        setState(() => _busy = false);
        _inputFocus.requestFocus();
      }
    }
  }

  /// ينفّذ كل أوامر الفئة النشطة بالتسلسل مع رؤوس فاصلة بين كل أمر.
  /// مفيد جداً للتدقيق الأمني: يعرض firewall + nat + services + users دفعة واحدة.
  ///
  /// استثناء: فئة "تشخيص شبكي" تتجاوز أوامر bandwidth-test و torch
  /// لأنها تتطلب stream/timer ولا تصلح لتنفيذ batch.
  Future<void> _runAuditAll() async {
    if (_busy) return;
    var commands = _categorizedCommands[_activeCategory] ?? const <String>[];
    if (commands.isEmpty) return;

    // استثناء الأوامر التفاعلية/الطويلة من التدقيق الشامل
    if (_activeCategory == _CmdCategory.diagnostics) {
      commands = commands.where((c) {
        final lc = c.toLowerCase();
        // bandwidth-test و torch يحتاجان stream ومدة محددة
        // لا تصلح للتنفيذ التسلسلي الآلي
        if (lc.contains('bandwidth-test')) return false;
        if (lc.contains('torch')) return false;
        return true;
      }).toList();
    }

    if (commands.isEmpty) {
      _append(const _TermLine(
        'لا توجد أوامر صالحة للتدقيق الشامل في فئة "تشخيص شبكي". '
        'نفّذ bandwidth-test و torch يدوياً.',
        _LineKind.info,
      ));
      return;
    }

    final ok = await _confirmAuditAll(commands);
    if (ok != true) return;

    _append(const _TermLine(
      '═══════════════════════════════════════════',
      _LineKind.header,
    ));
    _append(_TermLine(
      'تدقيق شامل — ${_activeCategory.displayName} (${commands.length} أوامر)',
      _LineKind.header,
    ));
    _append(const _TermLine(
      '═══════════════════════════════════════════',
      _LineKind.header,
    ));

    setState(() => _busy = true);
    int success = 0;
    int failed = 0;
    try {
      for (var i = 0; i < commands.length; i++) {
        final cmd = commands[i];

        // رأس فاصل لكل أمر
        _append(_TermLine(
          '\n─── [${i + 1}/${commands.length}] $cmd ───',
          _LineKind.header,
        ));
        _append(_TermLine('$_prompt $cmd', _LineKind.prompt));

        try {
          // مهلة أطول لفئة التشخيص (ping/traceroute قد تستغرق وقتاً)
          final cmdTimeout = _activeCategory == _CmdCategory.diagnostics
              ? const Duration(seconds: 60)
              : const Duration(seconds: 30);
          final result = await CommandExecutor.execute(
            command: cmd,
            method: _method,
            timeout: cmdTimeout,
          );
          if (result.success) {
            final out = result.output.trim();
            _append(_TermLine(
              out.isEmpty ? '(تم — بدون مخرجات)' : out,
              _LineKind.output,
            ));
            success++;
          } else {
            _append(_TermLine(
              'خطأ: ${result.error ?? "فشل غير معروف"}',
              _LineKind.error,
            ));
            failed++;
          }
        } catch (e) {
          _append(_TermLine('استثناء: $e', _LineKind.error));
          failed++;
        }
      }
    } finally {
      _append(const _TermLine(
        '═══════════════════════════════════════════',
        _LineKind.header,
      ));
      _append(_TermLine(
        'انتهى التدقيق — نجاح: $success | فشل: $failed',
        _LineKind.info,
      ));
      _append(const _TermLine(
        '═══════════════════════════════════════════',
        _LineKind.header,
      ));
      if (mounted) {
        setState(() => _busy = false);
        _inputFocus.requestFocus();
      }
    }
  }

  Future<bool?> _confirmAuditAll(List<String> commands) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(_activeCategory.icon,
                color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            Text('تدقيق ${_activeCategory.displayName}'),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'سيتم تنفيذ ${commands.length} أوامر قراءة (آمنة) بالتسلسل. '
                'هذا يتيح رؤية شاملة لإعدادات ${_activeCategory.displayName} لتقييم الثغرات.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 12),
              Container(
                constraints: const BoxConstraints(maxHeight: 220),
                padding: const EdgeInsets.all(8),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: commands.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 2),
                  itemBuilder: (_, i) => Text(
                    '${i + 1}. ${commands[i]}',
                    style:
                        const TextStyle(fontFamily: 'monospace', fontSize: 12),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.pop(ctx, true),
            icon: const Icon(Icons.playlist_play),
            label: const Text('تنفيذ الكل'),
          ),
        ],
      ),
    );
  }

  Future<bool?> _confirmDangerous(String command) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.dangerous, color: Theme.of(context).appColors.error),
            const SizedBox(width: 8),
            const Text('أمر خطير'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('قد يقطع هذا الأمر الاتصال أو يحذف بيانات. متأكد؟'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              width: double.infinity,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.onSurface,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                command,
                style: TextStyle(
                    fontFamily: 'monospace',
                    color: Theme.of(context).appColors.warning),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).appColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('تنفيذ'),
          ),
        ],
      ),
    );
  }

  void _recallHistory(int direction) {
    if (_history.isEmpty) return;
    _historyCursor = (_historyCursor + direction).clamp(0, _history.length);
    final text =
        _historyCursor < _history.length ? _history[_historyCursor] : '';
    _inputController.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }

  Future<void> _copyAll() async {
    final buffer = _lines
        .map((l) => l.kind == _LineKind.prompt ? l.text : l.text)
        .join('\n');
    await SecureClipboard.copy(buffer, sensitive: false);
    if (mounted) showSuccessSnackBar(context, 'تم نسخ مخرجات التيرمنال');
  }

  void _clear() {
    setState(() {
      _lines.clear();
      _lines.add(const _TermLine('تم مسح الشاشة.', _LineKind.info));
    });
  }

  Color _colorFor(_LineKind kind) {
    final c = context.appColors;
    switch (kind) {
      case _LineKind.prompt:
        return c.info; // أزرق فاتح (Electric Blue)
      case _LineKind.output:
        return c.success; // أخضر (Neon Green)
      case _LineKind.error:
        return c.error; // أحمر
      case _LineKind.header:
        return c.warning; // برتقالي ذهبي للرؤوس الفاصلة
      case _LineKind.info:
        return c.textTertiary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final commands = _categorizedCommands[_activeCategory] ?? const <String>[];

    return Scaffold(
      backgroundColor: context.appColors.background,
      appBar: AppBar(
        title: const Text('تيرمنال MikroTik'),
        actions: [
          // تبديل طريقة الاتصال
          PopupMenuButton<MikrotikConnectionMethod>(
            icon: const Icon(Icons.settings_ethernet),
            tooltip: 'طريقة الاتصال',
            initialValue: _method,
            onSelected: (m) => setState(() => _method = m),
            itemBuilder: (_) => MikrotikConnectionMethod.values
                .map((m) => PopupMenuItem(
                      value: m,
                      child: Row(
                        children: [
                          if (m == _method)
                            const Icon(Icons.check, size: 16)
                          else
                            const SizedBox(width: 16),
                          const SizedBox(width: 8),
                          Text(m.displayName),
                        ],
                      ),
                    ))
                .toList(),
          ),
          IconButton(
            icon: const Icon(Icons.copy_all),
            tooltip: 'نسخ الكل',
            onPressed: _copyAll,
          ),
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            tooltip: 'مسح الشاشة',
            onPressed: _busy ? null : _clear,
          ),
        ],
      ),
      body: Column(
        children: [
          // شريط طريقة الاتصال الحالية
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            color: context.appColors.surface,
            child: Row(
              children: [
                Icon(
                  _method == MikrotikConnectionMethod.ssh
                      ? Icons.terminal
                      : Icons.api,
                  size: 14,
                  color: Theme.of(context).appColors.success,
                ),
                const SizedBox(width: 6),
                Text(
                  _method.displayName,
                  style: TextStyle(
                      color: Theme.of(context).textTheme.bodySmall?.color,
                      fontSize: 12),
                ),
                const Spacer(),
                if (_busy)
                  const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
          ),

          // منطقة المخرجات
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(12),
              itemCount: _lines.length,
              itemBuilder: (context, index) {
                final line = _lines[index];
                final isHeader = line.kind == _LineKind.header;
                return Padding(
                  padding: EdgeInsets.only(bottom: isHeader ? 4 : 6),
                  child: SelectableText(
                    line.text,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: isHeader ? 13 : 13,
                      height: 1.35,
                      color: _colorFor(line.kind),
                      fontWeight: line.kind == _LineKind.prompt || isHeader
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                );
              },
            ),
          ),

          // منتقي الفئة + زر التدقيق الشامل
          _buildCategoryBar(),

          // أوامر سريعة حسب الفئة المحددة
          SizedBox(
            height: 42,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              itemCount: commands.length,
              separatorBuilder: (_, __) => const SizedBox(width: 6),
              itemBuilder: (_, i) {
                final cmd = commands[i];
                return Center(
                  child: ActionChip(
                    backgroundColor: context.appColors.surfaceVariant,
                    side: BorderSide(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.1)),
                    label: Text(
                      cmd,
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 11,
                        color: Theme.of(context).textTheme.bodySmall?.color,
                      ),
                    ),
                    onPressed: _busy ? null : () => _runCommand(cmd),
                  ),
                );
              },
            ),
          ),

          // صندوق الإدخال
          _buildInputBar(),
        ],
      ),
    );
  }

  /// شريط الفئات مع زر "تدقيق شامل"
  Widget _buildCategoryBar() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      color: context.appColors.background,
      child: Row(
        children: [
          // أيقونة الفئة الحالية
          Icon(
            _activeCategory.icon,
            size: 16,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 6),
          // منتقي الفئات (قابل للتمرير)
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _CmdCategory.values.map((cat) {
                  final selected = cat == _activeCategory;
                  return Padding(
                    padding: const EdgeInsetsDirectional.only(end: 4),
                    child: FilterChip(
                      selected: selected,
                      label: Text(
                        cat.displayName,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight:
                              selected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      onSelected: _busy
                          ? null
                          : (_) => setState(() => _activeCategory = cat),
                      selectedColor: Theme.of(context).colorScheme.primary,
                      labelStyle: TextStyle(
                        color: selected
                            ? Theme.of(context).colorScheme.onPrimary
                            : Theme.of(context).textTheme.bodySmall?.color,
                      ),
                      backgroundColor: context.appColors.surfaceVariant,
                      side: BorderSide(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.1),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          // زر التدقيق الشامل
          FilledButton.icon(
            onPressed: _busy ? null : _runAuditAll,
            icon: const Icon(Icons.playlist_play, size: 16),
            label: const Text('تدقيق شامل', style: TextStyle(fontSize: 12)),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              minimumSize: const Size(0, 32),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputBar() {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.all(8),
        color: context.appColors.surface,
        child: Row(
          children: [
            // استرجاع السجل (أعلى/أسفل)
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _historyButton(
                    Icons.keyboard_arrow_up, () => _recallHistory(-1)),
                _historyButton(
                    Icons.keyboard_arrow_down, () => _recallHistory(1)),
              ],
            ),
            const SizedBox(width: 4),
            Expanded(
              child: TextField(
                controller: _inputController,
                focusNode: _inputFocus,
                enabled: !_busy,
                autocorrect: false,
                enableSuggestions: false,
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 14,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                decoration: InputDecoration(
                  isDense: true,
                  prefixText: '> ',
                  prefixStyle: TextStyle(
                    color: Theme.of(context).appColors.success,
                    fontFamily: 'monospace',
                    fontSize: 14,
                  ),
                  hintText: 'اكتب أمر RouterOS...',
                  hintStyle: TextStyle(
                      color: Theme.of(context).dividerColor, fontSize: 13),
                  filled: true,
                  fillColor: context.appColors.background,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                ),
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _runCommand(),
              ),
            ),
            const SizedBox(width: 6),
            CircleAvatar(
              backgroundColor: _busy
                  ? Theme.of(context).appColors.muted
                  : Theme.of(context).primaryColor,
              child: IconButton(
                icon: Icon(Icons.play_arrow,
                    color: Theme.of(context).colorScheme.onSurface),
                onPressed: _busy ? null : () => _runCommand(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _historyButton(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: _history.isEmpty ? null : onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: Icon(
          icon,
          size: 18,
          color: _history.isEmpty
              ? Theme.of(context).dividerColor
              : Theme.of(context).hintColor,
        ),
      ),
    );
  }
}
