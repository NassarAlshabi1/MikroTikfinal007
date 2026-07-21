// ============================================================
//  Terminal Screen — تيرمنال تفاعلي لأوامر MikroTik RouterOS
//  - ينفّذ الأوامر عبر RouterOS API (8728) أو SSH (22)
//  - يعرض المخرجات كوحدة طرفية (console) مع سجل الأوامر
//  - تأكيد للأوامر الخطرة + أوامر سريعة جاهزة
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'ai/command_executor.dart';
import 'ai/diagnostics_models.dart';
import 'snackbar_helpers.dart';

/// نوع سطر في مخرجات التيرمنال
enum _LineKind { prompt, output, error, info }

/// سطر واحد في شاشة التيرمنال
class _TermLine {
  final String text;
  final _LineKind kind;
  const _TermLine(this.text, this.kind);
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

  static const _quickCommands = <String>[
    '/system resource print',
    '/system identity print',
    '/interface print',
    '/ip address print',
    '/ip dhcp-server lease print',
    '/ip firewall filter print',
    '/log print',
  ];

  @override
  void initState() {
    super.initState();
    _loadDeviceInfo();
    _lines.add(const _TermLine(
      'MikroTik Terminal — اكتب أمر RouterOS ثم اضغط تنفيذ.\n'
      'مثال: /system resource print',
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

  Future<bool?> _confirmDangerous(String command) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.dangerous, color: Colors.red),
            const SizedBox(width: 8),
            Text('أمر خطير'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('قد يقطع هذا الأمر الاتصال أو يحذف بيانات. متأكد؟'),
            SizedBox(height: 12),
            Container(
              padding: EdgeInsets.all(8),
              width: double.infinity,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.onSurface,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                command,
                style: const TextStyle(
                    fontFamily: 'monospace', color: Colors.orangeAccent),
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
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
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
    final text = _historyCursor < _history.length
        ? _history[_historyCursor]
        : '';
    _inputController.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }

  Future<void> _copyAll() async {
    final buffer = _lines
        .map((l) => l.kind == _LineKind.prompt ? l.text : l.text)
        .join('\n');
    await Clipboard.setData(ClipboardData(text: buffer));
    if (mounted) showSuccessSnackBar(context, 'تم نسخ مخرجات التيرمنال');
  }

  void _clear() {
    setState(() {
      _lines.clear();
      _lines.add(const _TermLine('تم مسح الشاشة.', _LineKind.info));
    });
  }

  Color _colorFor(_LineKind kind) {
    switch (kind) {
      case _LineKind.prompt:
        return const Color(0xFF4FC3F7); // أزرق فاتح
      case _LineKind.output:
        return Color(0xFFB9F6CA); // أخضر فاتح
      case _LineKind.error:
        return Color(0xFFFF8A80); // أحمر فاتح
      case _LineKind.info:
        return Theme.of(context).hintColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
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
            color: const Color(0xFF161B22),
            child: Row(
              children: [
                Icon(
                  _method == MikrotikConnectionMethod.ssh
                      ? Icons.terminal
                      : Icons.api,
                  size: 14,
                  color: Colors.greenAccent,
                ),
                SizedBox(width: 6),
                Text(
                  _method.displayName,
                  style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color, fontSize: 12),
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
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: SelectableText(
                    line.text,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 13,
                      height: 1.35,
                      color: _colorFor(line.kind),
                      fontWeight: line.kind == _LineKind.prompt
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                );
              },
            ),
          ),

          // أوامر سريعة
          SizedBox(
            height: 42,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              itemCount: _quickCommands.length,
              separatorBuilder: (_, __) => const SizedBox(width: 6),
              itemBuilder: (_, i) {
                final cmd = _quickCommands[i];
                return Center(
                  child: ActionChip(
                    backgroundColor: Color(0xFF21262D),
                    side: BorderSide(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1)),
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

  Widget _buildInputBar() {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.all(8),
        color: const Color(0xFF161B22),
        child: Row(
          children: [
            // استرجاع السجل (أعلى/أسفل)
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _historyButton(Icons.keyboard_arrow_up, () => _recallHistory(-1)),
                _historyButton(Icons.keyboard_arrow_down, () => _recallHistory(1)),
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
                  prefixStyle: const TextStyle(
                    color: Colors.greenAccent,
                    fontFamily: 'monospace',
                    fontSize: 14,
                  ),
                  hintText: 'اكتب أمر RouterOS...',
                  hintStyle: TextStyle(color: Theme.of(context).dividerColor, fontSize: 13),
                  filled: true,
                  fillColor: const Color(0xFF0D1117),
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
            SizedBox(width: 6),
            CircleAvatar(
              backgroundColor:
                  _busy ? Colors.grey : Theme.of(context).primaryColor,
              child: IconButton(
                icon: Icon(Icons.play_arrow, color: Theme.of(context).colorScheme.onSurface),
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
        padding: EdgeInsets.symmetric(horizontal: 2),
        child: Icon(
          icon,
          size: 18,
          color: _history.isEmpty ? Theme.of(context).dividerColor : Theme.of(context).hintColor,
        ),
      ),
    );
  }
}
