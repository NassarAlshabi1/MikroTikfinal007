import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'mikrotik_card_repository.dart';
import 'snackbar_helpers.dart';

class CardSyncScreen extends StatefulWidget {
  const CardSyncScreen({super.key});

  @override
  State<CardSyncScreen> createState() => _CardSyncScreenState();
}

class _CardSyncScreenState extends State<CardSyncScreen> {
  final _searchController = TextEditingController();
  final _repository = MikrotikCardRepository.instance;

  MikrotikCardSource _source = MikrotikCardSource.userManager;
  List<MikrotikCard> _cards = const [];
  List<MikrotikCard> _visibleCards = const [];
  DateTime? _lastSyncedAt;
  String? _errorMessage;
  bool _isLoading = false;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _sync();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _sync({bool forceRefresh = false}) async {
    if (_isRefreshing) return;
    setState(() {
      if (_cards.isEmpty) {
        _isLoading = true;
      } else {
        _isRefreshing = true;
      }
      _errorMessage = null;
    });

    try {
      final result = await _repository.sync(
        source: _source,
        forceRefresh: forceRefresh,
      );
      if (!mounted) return;
      setState(() {
        _cards = result.cards;
        _lastSyncedAt = result.syncedAt;
        _applySearch(_searchController.text, notify: false);
      });
      if (forceRefresh && !result.fromCache) {
        showSuccessSnackBar(
          context,
          'تمت مزامنة ${result.cards.length} كرت خلال ${result.elapsed.inMilliseconds} مللي ثانية.',
        );
      }
    } on MikrotikCardOperationException catch (error) {
      if (mounted) setState(() => _errorMessage = error.message);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isRefreshing = false;
        });
      }
    }
  }

  void _applySearch(String value, {bool notify = true}) {
    final cards = _repository.searchLocal(source: _source, query: value);
    if (notify && mounted) {
      setState(() => _visibleCards = cards);
      return;
    }
    _visibleCards = cards;
  }

  void _changeSource(MikrotikCardSource source) {
    if (source == _source || _isLoading || _isRefreshing) return;
    setState(() {
      _source = source;
      _cards = const [];
      _visibleCards = const [];
      _lastSyncedAt = null;
      _errorMessage = null;
      _isLoading = false;
    });
    _sync();
  }

  String get _syncDescription {
    if (_lastSyncedAt == null) return 'لم تُجرَ مزامنة بعد';
    final time = _lastSyncedAt!;
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return 'آخر مزامنة اليوم $hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('بحث ومزامنة الكروت'),
        actions: [
          IconButton(
            tooltip: 'مزامنة الآن',
            onPressed: _isLoading || _isRefreshing
                ? null
                : () => _sync(forceRefresh: true),
            icon: _isRefreshing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2.4),
                  )
                : const Icon(Icons.sync_rounded),
          ),
        ],
      ),
      body: Column(
        children: [
          _Header(
            source: _source,
            cardCount: _cards.length,
            visibleCount: _visibleCards.length,
            syncDescription: _syncDescription,
            isBusy: _isLoading || _isRefreshing,
            onSourceChanged: _changeSource,
            onSync: () => _sync(forceRefresh: true),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              controller: _searchController,
              textInputAction: TextInputAction.search,
              onChanged: _applySearch,
              decoration: InputDecoration(
                hintText: 'ابحث باسم الكرت أو الفئة أو الملاحظة',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _searchController.text.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'مسح البحث',
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () {
                          _searchController.clear();
                          _applySearch('');
                        },
                      ),
              ),
            ),
          ),
          Expanded(child: _buildContent(context)),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    final error = _errorMessage;
    if (error != null) {
      return _ErrorState(
        message: error,
        onRetry: () => _sync(forceRefresh: true),
      );
    }

    if (_cards.isEmpty) {
      return _EmptyState(
        title: 'لا توجد كروت في ${_source.label}',
        message:
            'تحقق من وضع الاتصال وصلاحيات مستخدم RouterOS، ثم أعد المزامنة.',
        actionLabel: 'مزامنة الآن',
        onAction: () => _sync(forceRefresh: true),
      );
    }

    if (_visibleCards.isEmpty) {
      return _EmptyState(
        title: 'لا توجد نتائج مطابقة',
        message: 'جرّب جزءاً آخر من اسم الكرت أو الفئة أو الملاحظة.',
        actionLabel: 'مسح البحث',
        onAction: () {
          _searchController.clear();
          _applySearch('');
        },
      );
    }

    return RefreshIndicator(
      onRefresh: () => _sync(forceRefresh: true),
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: _visibleCards.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) => _CardTile(card: _visibleCards[index]),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.source,
    required this.cardCount,
    required this.visibleCount,
    required this.syncDescription,
    required this.isBusy,
    required this.onSourceChanged,
    required this.onSync,
  });

  final MikrotikCardSource source;
  final int cardCount;
  final int visibleCount;
  final String syncDescription;
  final bool isBusy;
  final ValueChanged<MikrotikCardSource> onSourceChanged;
  final VoidCallback onSync;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        border: Border(bottom: BorderSide(color: colors.outlineVariant)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SegmentedButton<MikrotikCardSource>(
            segments: const [
              ButtonSegment(
                value: MikrotikCardSource.userManager,
                icon: Icon(Icons.manage_accounts_outlined),
                label: Text('مدير المستخدمين'),
              ),
              ButtonSegment(
                value: MikrotikCardSource.hotspot,
                icon: Icon(Icons.wifi_rounded),
                label: Text('Hotspot'),
              ),
            ],
            selected: {source},
            showSelectedIcon: false,
            onSelectionChanged:
                isBusy ? null : (selection) => onSourceChanged(selection.first),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Text(
                  '$visibleCount نتيجة من أصل $cardCount كرت',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              Text(
                syncDescription,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          FilledButton.tonalIcon(
            onPressed: isBusy ? null : onSync,
            icon: const Icon(Icons.sync_rounded),
            label: const Text('مزامنة الكروت من الراوتر'),
          ),
        ],
      ),
    );
  }
}

class _CardTile extends StatelessWidget {
  const _CardTile({required this.card});

  final MikrotikCard card;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final statusColor = card.isDisabled ? colors.error : colors.primary;
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: statusColor.withValues(alpha: .14),
          foregroundColor: statusColor,
          child: Icon(
              card.isDisabled ? Icons.person_off_outlined : Icons.key_outlined),
        ),
        title: Text(
          card.username,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 5),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('الفئة: ${card.profile}'),
              if (card.comment.isNotEmpty)
                Text(
                  card.comment,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        ),
        trailing: IconButton(
          tooltip: 'نسخ اسم الكرت',
          icon: const Icon(Icons.copy_outlined),
          onPressed: () async {
            await Clipboard.setData(ClipboardData(text: card.username));
            if (context.mounted) {
              showSuccessSnackBar(context, 'تم نسخ اسم الكرت.');
            }
          },
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.manage_search_outlined, size: 58),
            const SizedBox(height: 16),
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 18),
            FilledButton.tonal(onPressed: onAction, child: Text(actionLabel)),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.wifi_off_rounded, size: 56, color: colors.error),
            const SizedBox(height: 16),
            Text('تعذر إتمام المزامنة',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      ),
    );
  }
}
