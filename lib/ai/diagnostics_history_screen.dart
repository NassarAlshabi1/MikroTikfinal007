// ============================================================
//  Diagnostics History Screen — مراجعة الجلسات السابقة
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'diagnostics_history.dart';
import 'diagnostics_models.dart';
import 'diagnostics_provider.dart';
import 'command_executor.dart';

import '../theme/app_theme.dart';
class DiagnosticsHistoryScreen extends ConsumerWidget {
  const DiagnosticsHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(historyManagerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('سجل التشخيصات'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'تحديث',
            onPressed: () => ref.read(historyManagerProvider.notifier).refresh(),
          ),
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            tooltip: 'مسح الكل',
            onPressed: () => _confirmClearAll(context, ref),
          ),
        ],
      ),
      body: historyAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: Theme.of(context).appColors.error),
              const SizedBox(height: 16),
              Text('خطأ في تحميل السجل: $e'),
            ],
          ),
        ),
        data: (sessions) {
          if (sessions.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history,
                      size: 64, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3)),
                  SizedBox(height: 16),
                  Text(
                    'لا توجد جلسات محفوظة',
                    style: TextStyle(fontSize: 16, color: Theme.of(context).hintColor),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'كل جلسة تشخيص تُحفظ تلقائياً هنا',
                    style: TextStyle(fontSize: 13, color: Theme.of(context).disabledColor),
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            itemCount: sessions.length,
            cacheExtent: 250,
            itemBuilder: (context, index) {
              final session = sessions[index];
              return _SessionCard(session: session);
            },
          );
        },
      ),
    );
  }

  void _confirmClearAll(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('مسح كل السجل'),
        content: const Text(
          'هل أنت متأكد من حذف كل الجلسات المحفوظة؟ '
          'لا يمكن التراجع عن هذا الإجراء.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).appColors.error),
            onPressed: () {
              Navigator.of(ctx).pop();
              ref.read(historyManagerProvider.notifier).clearAll();
            },
            child: Text('حذف الكل', style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
          ),
        ],
      ),
    );
  }
}

/// بطاقة جلسة في القائمة
class _SessionCard extends ConsumerWidget {
  final DiagnosticSession session;

  const _SessionCard({required this.session});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ListTile(
        contentPadding:
            EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).primaryColor,
          child: Icon(session.mode.icon, color: Theme.of(context).colorScheme.onSurface, size: 20),
        ),
        title: Text(
          session.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 4),
            Text(
              session.subtitle,
              style: TextStyle(fontSize: 12, color: Theme.of(context).hintColor),
            ),
            SizedBox(height: 4),
            Text(
              _formatDate(session.startedAt),
              style: TextStyle(fontSize: 11, color: Theme.of(context).disabledColor),
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (action) {
            switch (action) {
              case 'view':
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => SessionDetailScreen(session: session),
                  ),
                );
                break;
              case 'delete':
                _confirmDelete(context, ref);
                break;
            }
          },
          itemBuilder: (_) => [
            const PopupMenuItem(value: 'view', child: Text('عرض التفاصيل')),
            PopupMenuItem(
                value: 'delete',
                child: Text('حذف', style: TextStyle(color: Theme.of(context).appColors.error))),
          ],
        ),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => SessionDetailScreen(session: session),
            ),
          );
        },
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف الجلسة'),
        content: const Text('هل تريد حذف هذه الجلسة؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).appColors.error),
            onPressed: () {
              Navigator.of(ctx).pop();
              ref
                  .read(historyManagerProvider.notifier)
                  .deleteSession(session.id);
            },
            child: Text('حذف', style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'الآن';
    if (diff.inHours < 1) return 'قبل ${diff.inMinutes} دقيقة';
    if (diff.inDays < 1) return 'قبل ${diff.inHours} ساعة';
    if (diff.inDays < 7) return 'قبل ${diff.inDays} يوم';
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

// ============================================================
//  شاشة تفاصيل الجلسة
// ============================================================
class SessionDetailScreen extends StatelessWidget {
  final DiagnosticSession session;

  const SessionDetailScreen({super.key, required this.session});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(session.mode.displayName),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'المحادثة', icon: Icon(Icons.chat)),
              Tab(text: 'الأوامر المنفّذة', icon: Icon(Icons.terminal)),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // تبويب المحادثة
            ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: session.messages.length,
              itemBuilder: (context, index) {
                final msg = session.messages[index];
                return _DetailMessageBubble(message: msg);
              },
            ),
            // تبويب الأوامر
            session.executedCommands.isEmpty
                ? Center(
                    child: Text(
                      'لم يتم تنفيذ أي أوامر في هذه الجلسة',
                      style: TextStyle(color: Theme.of(context).hintColor),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: session.executedCommands.length,
                    itemBuilder: (context, index) {
                      final cmd = session.executedCommands[index];
                      return _CommandResultCard(result: cmd);
                    },
                  ),
          ],
        ),
      ),
    );
  }
}

class _DetailMessageBubble extends StatelessWidget {
  final DiagnosticMessage message;

  const _DetailMessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.type == MessageType.user;
    final isError = message.type == MessageType.error;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isError
            ? Theme.of(context).appColors.error.withValues(alpha: 0.1)
            : isUser
                ? Theme.of(context).primaryColor
                : Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isUser
                    ? Icons.person
                    : isError
                        ? Icons.error
                        : Icons.smart_toy,
                size: 16,
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
              const SizedBox(width: 8),
              Text(
                isUser
                    ? 'أنت'
                    : isError
                        ? 'خطأ'
                        : 'AI',
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).textTheme.bodySmall?.color,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Spacer(),
              Text(
                '${message.timestamp.hour.toString().padLeft(2, '0')}:'
                '${message.timestamp.minute.toString().padLeft(2, '0')}',
                style: TextStyle(fontSize: 10, color: Theme.of(context).disabledColor),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SelectableText(
            message.content,
            style: const TextStyle(fontSize: 13, height: 1.5),
          ),
        ],
      ),
    );
  }
}

class _CommandResultCard extends StatelessWidget {
  final CommandResult result;

  const _CommandResultCard({required this.result});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ExpansionTile(
        leading: Icon(
          result.success ? Icons.check_circle : Icons.error,
          color: result.success ? Theme.of(context).appColors.success : Theme.of(context).appColors.error,
        ),
        title: Text(
          result.command,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
        ),
        subtitle: Text(
          '${result.success ? "نجح" : "فشل"} • ${result.elapsed.inMilliseconds}ms',
          style: TextStyle(
            fontSize: 11,
            color: result.success ? Theme.of(context).appColors.success : Theme.of(context).appColors.error,
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (result.output.isNotEmpty) ...[
                  Text(
                    'المخرجات:',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).textTheme.bodySmall?.color),
                  ),
                  SizedBox(height: 4),
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).textTheme.bodySmall?.color,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: SelectableText(
                      result.output,
                      style: const TextStyle(
                          fontFamily: 'monospace', fontSize: 11),
                    ),
                  ),
                ],
                if (result.error != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'الخطأ:',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).appColors.error),
                  ),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).appColors.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: SelectableText(
                      result.error!,
                      style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 11,
                          color: Theme.of(context).appColors.error),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
