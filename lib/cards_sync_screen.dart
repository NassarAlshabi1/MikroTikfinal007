import 'dart:async';

import 'package:flutter/material.dart';
import 'package:router_os_client/router_os_client.dart';

import 'mikrotik_connector.dart';
import 'theme/app_theme.dart';
import 'services/router_os_card_gateway.dart' show RouterOsClientTalker;
import 'services/secure_clipboard.dart';
import 'services/um_cards_sync_service.dart';

// ── Screen ──

class CardsSyncScreen extends StatefulWidget {
  const CardsSyncScreen({super.key});

  @override
  State<CardsSyncScreen> createState() => _CardsSyncScreenState();
}

class _CardsSyncScreenState extends State<CardsSyncScreen>
    with TickerProviderStateMixin {
  // ── State ──
  // لا تحميل عند الفتح — المزامنة اختيارية عبر زر المزامنة.
  bool _isLoading = false;
  String? _errorMessage;
  List<UmSyncedCard> _allCards = [];
  List<UmSyncedCard> _filteredCards = [];
  final Set<String> _selectedNames = {};
  String _searchQuery = '';
  String? _profileFilter;
  bool _showExpiredOnly = false;
  bool _showActiveOnly = false;

  /// هل نفّذ المستخدم المزامنة يدوياً؟ المزامنة اختيارية ولا تجري
  /// أي اتصال بالراوتر عند فتح الشاشة.
  bool _hasSynced = false;

  // Profiles extracted from cards
  List<String> _profiles = [];

  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeInOut);
    // لا مزامنة تلقائية — المزامنة اختيارية عبر زر المزامنة.
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  // ── Data ──

  Future<void> _syncCards({bool retry = true}) async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    RouterOSClient? client;
    try {
      client = await MikrotikConnector.connect();

      // كروت User Manager فقط — لا يُقرأ الهوتسبوت هنا إطلاقاً.
      const service = UmCardsSyncService();
      final cards = await service.fetchCards(RouterOsClientTalker(client));

      final profileSet = <String>{};
      for (final card in cards) {
        if (card.profile.isNotEmpty) profileSet.add(card.profile);
      }
      final sortedProfiles = profileSet.toList()..sort();

      if (mounted) {
        setState(() {
          _allCards = cards;
          _profiles = sortedProfiles;
          _hasSynced = true;
          _isLoading = false;
        });
        _applyFilters();
        _animCtrl.forward(from: 0);
      }
    } catch (e) {
      if (retry && MikrotikConnector.isSocketClosedError(e)) {
        MikrotikConnector.forceDisconnect();
        return _syncCards(retry: false);
      }
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'فشل جلب كروت اليوزرمنجر: ${e.toString()}';
        });
      }
    } finally {
      MikrotikConnector.release(client);
    }
  }

  void _applyFilters() {
    var list = List<UmSyncedCard>.from(_allCards);

    // Profile filter
    if (_profileFilter != null && _profileFilter!.isNotEmpty) {
      list = list.where((c) => c.profile == _profileFilter).toList();
    }

    // Expired / Active filter
    if (_showExpiredOnly) {
      list = list.where((c) => c.isExpired).toList();
    } else if (_showActiveOnly) {
      list = list.where((c) => c.isActive).toList();
    }

    // Search
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list
          .where((c) =>
              c.name.toLowerCase().contains(q) ||
              c.profile.toLowerCase().contains(q) ||
              c.comment.toLowerCase().contains(q))
          .toList();
    }

    setState(() => _filteredCards = list);
  }

  // ── Bulk actions ──

  void _selectAllVisible() {
    setState(() {
      for (final c in _filteredCards) {
        _selectedNames.add(c.name);
      }
    });
  }

  void _deselectAll() {
    setState(() => _selectedNames.clear());
  }

  void _toggleSelectByProfile(String? profile) {
    setState(() {
      final targets =
          _filteredCards.where((c) => profile == null || c.profile == profile);
      final allSelected = targets.every((c) => _selectedNames.contains(c.name));
      if (allSelected) {
        for (final c in targets) {
          _selectedNames.remove(c.name);
        }
      } else {
        for (final c in targets) {
          _selectedNames.add(c.name);
        }
      }
    });
  }

  Future<void> _deleteSelected() async {
    if (_selectedNames.isEmpty) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف كروت اليوزرمنجر المحددة'),
        content: Text(
            'هل أنت متأكد من حذف ${_selectedNames.length} كرت من User Manager على الراوتر؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('حذف'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    if (!mounted) return;
    setState(() => _isLoading = true);

    RouterOSClient? client;
    int deleted = 0;
    try {
      client = await MikrotikConnector.connect();

      for (final card in _allCards) {
        if (!_selectedNames.contains(card.name)) continue;
        if (card.mikrotikId == null || card.mikrotikId!.isEmpty) continue;
        try {
          await client.talk([
            '/tool/user-manager/user/remove',
            '=.id=${card.mikrotikId}',
          ]).timeout(const Duration(seconds: 10));
          deleted++;
        } catch (_) {}
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم حذف $deleted من ${_selectedNames.length} كرت'),
            backgroundColor: deleted == _selectedNames.length
                ? context.theme.appColors.success
                : context.theme.appColors.warning,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ أثناء الحذف: $e'),
            backgroundColor: context.theme.appColors.error,
          ),
        );
      }
    } finally {
      MikrotikConnector.release(client);
      _selectedNames.clear();
      await _syncCards();
    }
  }

  void _copyCard(UmSyncedCard card) {
    final text = '${card.name}\t${card.password}';
    SecureClipboard.copy(text, sensitive: true);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تم نسخ: ${card.name}'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _copyProfileCards(String? profile) {
    final cards = profile == null
        ? _filteredCards
        : _filteredCards.where((c) => c.profile == profile).toList();
    if (cards.isEmpty) return;

    final buffer = StringBuffer();
    for (final c in cards) {
      buffer.writeln('${c.name}\t${c.password}');
    }
    SecureClipboard.copy(buffer.toString().trimRight(), sensitive: true);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تم نسخ ${cards.length} كرت'),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  // ── Helpers ──

  int get _expiredCount => _allCards.where((c) => c.isExpired).length;
  int get _activeCount => _allCards.where((c) => c.isActive).length;

  // ── Build ──

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('مزامنة كروت اليوزرمنجر',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          if (_selectedNames.isNotEmpty)
            IconButton(
              icon: Icon(Icons.delete_outline,
                  color: context.theme.appColors.error),
              onPressed: _deleteSelected,
              tooltip: 'حذف المحدد (${_selectedNames.length})',
            ),
          IconButton(
            icon: const Icon(Icons.refresh, size: 20),
            onPressed: _syncCards,
            tooltip: 'مزامنة',
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: theme.primaryColor),
                  const SizedBox(height: 16),
                  Text('جاري مزامنة كروت اليوزرمنجر...',
                      style: TextStyle(
                          color: cs.onSurface.withValues(alpha: 0.6),
                          fontSize: 13)),
                ],
              ),
            )
          : _errorMessage != null
              ? _buildError(theme)
              : !_hasSynced
                  ? _buildIdle(theme)
                  : _buildContent(theme),
    );
  }

  /// حالة الخمول قبل أول مزامنة — المزامنة اختيارية عبر الزر فقط.
  Widget _buildIdle(ThemeData theme) {
    final cs = theme.colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: theme.primaryColor.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.sync, size: 44, color: theme.primaryColor),
            ),
            const SizedBox(height: 20),
            Text('المزامنة اختيارية',
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: cs.onSurface)),
            const SizedBox(height: 8),
            Text(
              'لا يتم أي اتصال بالراوتر عند فتح الشاشة. اضغط زر المزامنة '
              'لجلب كروت User Manager (الاسم، كلمة المرور، البروفايل، '
              'والحد الزمني) متى شئت.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 12,
                  height: 1.6,
                  color: cs.onSurface.withValues(alpha: 0.6)),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _syncCards,
              icon: const Icon(Icons.sync, size: 18),
              label: const Text('مزامنة الآن', style: TextStyle(fontSize: 13)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError(ThemeData theme) {
    final cs = theme.colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline,
                size: 64, color: context.theme.appColors.error),
            const SizedBox(height: 20),
            Text(_errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14)),
            const SizedBox(height: 10),
            Text(
              'تأكد أن حزمة User Manager مثبتة على الراوتر وأن مستخدم '
              'API لديه صلاحية /tool user-manager',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 11,
                  height: 1.5,
                  color: cs.onSurface.withValues(alpha: 0.45)),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _syncCards,
              icon: const Icon(Icons.refresh, size: 18),
              label:
                  const Text('إعادة المحاولة', style: TextStyle(fontSize: 13)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(ThemeData theme) {
    final cs = theme.colorScheme;

    return FadeTransition(
      opacity: _fadeAnim,
      child: Column(
        children: [
          // ── Stats header ──
          _buildStatsBar(theme),
          // ── Search bar ──
          _buildSearchBar(theme),
          // ── Filter chips ──
          _buildFilterChips(theme),
          // ── Toolbar ──
          _buildToolbar(theme),
          // ── Card list ──
          Expanded(
            child: _filteredCards.isEmpty
                ? Center(
                    child: Text('لا توجد كروت في اليوزرمنجر',
                        style: TextStyle(
                            color: cs.onSurface.withValues(alpha: 0.5),
                            fontSize: 13)),
                  )
                : ListView.builder(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    itemCount: _filteredCards.length,
                    itemBuilder: (ctx, i) =>
                        _buildCardTile(_filteredCards[i], theme),
                  ),
          ),
        ],
      ),
    );
  }

  // ── Stats bar ──

  Widget _buildStatsBar(ThemeData theme) {
    final cs = theme.colorScheme;
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outline.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _statItem('الكل', _allCards.length, cs.onSurface, theme),
          Container(
              width: 1, height: 28, color: cs.outline.withValues(alpha: 0.3)),
          _statItem(
              'مفعل', _activeCount, context.theme.appColors.success, theme),
          Container(
              width: 1, height: 28, color: cs.outline.withValues(alpha: 0.3)),
          _statItem(
              'منتهي', _expiredCount, context.theme.appColors.error, theme),
          Container(
              width: 1, height: 28, color: cs.outline.withValues(alpha: 0.3)),
          _statItem('محدد', _selectedNames.length, theme.primaryColor, theme),
        ],
      ),
    );
  }

  Widget _statItem(String label, int value, Color color, ThemeData theme) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('$value',
            style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.bold, color: color)),
        Text(label,
            style: TextStyle(
                fontSize: 10,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6))),
      ],
    );
  }

  // ── Search ──

  Widget _buildSearchBar(ThemeData theme) {
    final cs = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      child: TextField(
        onChanged: (v) {
          _searchQuery = v;
          _applyFilters();
        },
        style: const TextStyle(fontSize: 13),
        decoration: InputDecoration(
          hintText: 'بحث بالاسم أو البروفايل...',
          hintStyle: TextStyle(
              fontSize: 13, color: cs.onSurface.withValues(alpha: 0.4)),
          prefixIcon: Icon(Icons.search,
              size: 18, color: cs.onSurface.withValues(alpha: 0.5)),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 16),
                  onPressed: () {
                    _searchQuery = '';
                    _applyFilters();
                  },
                )
              : null,
          isDense: true,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: cs.outline.withValues(alpha: 0.3))),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: cs.outline.withValues(alpha: 0.3))),
          filled: true,
          fillColor: cs.surface,
        ),
      ),
    );
  }

  // ── Filter chips ──

  Widget _buildFilterChips(ThemeData theme) {
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
        children: [
          // All
          _filterChip(
              'الكل', _showExpiredOnly == false && _showActiveOnly == false,
              () {
            setState(() {
              _showExpiredOnly = false;
              _showActiveOnly = false;
            });
            _applyFilters();
          }, theme),
          const SizedBox(width: 6),
          // Active
          _filterChip('مفعل', _showActiveOnly, () {
            setState(() {
              _showActiveOnly = !_showActiveOnly;
              _showExpiredOnly = false;
            });
            _applyFilters();
          }, theme, color: context.theme.appColors.success),
          const SizedBox(width: 6),
          // Expired
          _filterChip('منتهي', _showExpiredOnly, () {
            setState(() {
              _showExpiredOnly = !_showExpiredOnly;
              _showActiveOnly = false;
            });
            _applyFilters();
          }, theme, color: context.theme.appColors.error),
          const SizedBox(width: 6),
          // Profile dropdown
          _buildProfileDropdown(theme),
        ],
      ),
    );
  }

  Widget _filterChip(
      String label, bool selected, VoidCallback onTap, ThemeData theme,
      {Color? color}) {
    final chipColor = color ?? theme.primaryColor;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color:
              selected ? chipColor.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: selected
                  ? chipColor
                  : theme.colorScheme.outline.withValues(alpha: 0.3)),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 11,
                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                color: selected
                    ? chipColor
                    : theme.colorScheme.onSurface.withValues(alpha: 0.7))),
      ),
    );
  }

  Widget _buildProfileDropdown(ThemeData theme) {
    final cs = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: _profileFilter != null
                ? theme.primaryColor
                : cs.outline.withValues(alpha: 0.3)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _profileFilter,
          hint: Text('البروفايل',
              style: TextStyle(
                  fontSize: 11, color: cs.onSurface.withValues(alpha: 0.6))),
          isDense: true,
          icon: Icon(Icons.arrow_drop_down,
              size: 16, color: cs.onSurface.withValues(alpha: 0.5)),
          items: [
            const DropdownMenuItem<String>(
              value: null,
              child: Text('الكل', style: TextStyle(fontSize: 11)),
            ),
            ..._profiles.map((p) => DropdownMenuItem(
                  value: p,
                  child: Text(p, style: const TextStyle(fontSize: 11)),
                )),
          ],
          onChanged: (v) {
            setState(() => _profileFilter = v);
            _applyFilters();
          },
        ),
      ),
    );
  }

  // ── Toolbar ──

  Widget _buildToolbar(ThemeData theme) {
    final cs = theme.colorScheme;
    final allVisibleSelected = _filteredCards.isNotEmpty &&
        _filteredCards.every((c) => _selectedNames.contains(c.name));

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 4, 12, 0),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          // Select all / deselect
          GestureDetector(
            onTap: allVisibleSelected ? _deselectAll : _selectAllVisible,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  allVisibleSelected
                      ? Icons.check_box
                      : Icons.check_box_outline_blank,
                  size: 16,
                  color: theme.primaryColor,
                ),
                const SizedBox(width: 4),
                Text(
                  allVisibleSelected ? 'إلغاء التحديد' : 'تحديد الكل',
                  style: TextStyle(
                      fontSize: 11, color: cs.onSurface.withValues(alpha: 0.7)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Select by profile
          GestureDetector(
            onTap: () => _showProfileSelectDialog(theme),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.category,
                    size: 14, color: cs.onSurface.withValues(alpha: 0.5)),
                const SizedBox(width: 4),
                Text('تحديد حسب البروفايل',
                    style: TextStyle(
                        fontSize: 11,
                        color: cs.onSurface.withValues(alpha: 0.7))),
              ],
            ),
          ),
          const Spacer(),
          // Copy all visible
          GestureDetector(
            onTap: () => _copyProfileCards(_profileFilter),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.copy,
                    size: 14, color: cs.onSurface.withValues(alpha: 0.5)),
                const SizedBox(width: 4),
                Text('نسخ الكل (${_filteredCards.length})',
                    style: TextStyle(
                        fontSize: 11,
                        color: cs.onSurface.withValues(alpha: 0.7))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showProfileSelectDialog(ThemeData theme) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title:
            const Text('تحديد حسب البروفايل', style: TextStyle(fontSize: 15)),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _profiles.length,
            itemBuilder: (_, i) {
              final p = _profiles[i];
              final count = _filteredCards.where((c) => c.profile == p).length;
              return ListTile(
                dense: true,
                title: Text(p, style: const TextStyle(fontSize: 13)),
                trailing: Text('$count',
                    style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.onSurface
                            .withValues(alpha: 0.5))),
                onTap: () {
                  Navigator.pop(ctx);
                  _toggleSelectByProfile(p);
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
        ],
      ),
    );
  }

  // ── Card tile ──

  /// نص الاستهلاك الزمني للكرت (خاصية User Manager).
  String _usageText(UmSyncedCard card) {
    if (card.uptimeUsed.isEmpty && card.limitUptime.isEmpty) return '';
    if (card.limitUptime.isEmpty) return 'الاستخدام: ${card.uptimeUsed}';
    if (card.uptimeUsed.isEmpty) return 'الحد الزمني: ${card.limitUptime}';
    return 'الاستخدام: ${card.uptimeUsed} من ${card.limitUptime}';
  }

  Widget _buildCardTile(UmSyncedCard card, ThemeData theme) {
    final cs = theme.colorScheme;
    final isSelected = _selectedNames.contains(card.name);
    final expired = card.isExpired;

    return GestureDetector(
      onLongPress: () {
        setState(() {
          if (isSelected) {
            _selectedNames.remove(card.name);
          } else {
            _selectedNames.add(card.name);
          }
        });
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 3),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.primaryColor.withValues(alpha: 0.1)
              : cs.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? theme.primaryColor
                : expired
                    ? context.theme.appColors.error.withValues(alpha: 0.3)
                    : cs.outline.withValues(alpha: 0.15),
            width: isSelected ? 1.5 : 0.5,
          ),
        ),
        child: Row(
          children: [
            // Checkbox
            GestureDetector(
              onTap: () {
                setState(() {
                  if (isSelected) {
                    _selectedNames.remove(card.name);
                  } else {
                    _selectedNames.add(card.name);
                  }
                });
              },
              child: Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Icon(
                  isSelected
                      ? Icons.check_circle
                      : Icons.radio_button_unchecked,
                  size: 18,
                  color: isSelected
                      ? theme.primaryColor
                      : cs.onSurface.withValues(alpha: 0.3),
                ),
              ),
            ),
            // Info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name + status
                    Row(
                      children: [
                        Expanded(
                          child: Text(card.name,
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: cs.onSurface),
                              overflow: TextOverflow.ellipsis),
                        ),
                        if (expired)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              color: context.theme.appColors.error
                                  .withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text('منتهي',
                                style: TextStyle(
                                    fontSize: 9,
                                    color: context.theme.appColors.error)),
                          ),
                        if (!expired)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              color: context.theme.appColors.success
                                  .withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text('مفعل',
                                style: TextStyle(
                                    fontSize: 9,
                                    color: context.theme.appColors.success)),
                          ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    // Password + Profile
                    Row(
                      children: [
                        Icon(Icons.lock_outline,
                            size: 10,
                            color: cs.onSurface.withValues(alpha: 0.4)),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(card.password,
                              style: TextStyle(
                                  fontSize: 10,
                                  color: cs.onSurface.withValues(alpha: 0.6),
                                  fontFamily: 'monospace'),
                              overflow: TextOverflow.ellipsis),
                        ),
                        if (card.profile.isNotEmpty) ...[
                          Icon(Icons.category,
                              size: 10,
                              color: cs.onSurface.withValues(alpha: 0.4)),
                          const SizedBox(width: 3),
                          Text(card.profile,
                              style: TextStyle(
                                  fontSize: 10,
                                  color: cs.onSurface.withValues(alpha: 0.5))),
                        ],
                      ],
                    ),
                    if (_usageText(card).isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Icon(Icons.timer_outlined,
                              size: 10,
                              color: cs.onSurface.withValues(alpha: 0.4)),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(_usageText(card),
                                style: TextStyle(
                                    fontSize: 10,
                                    color: cs.onSurface.withValues(alpha: 0.5)),
                                overflow: TextOverflow.ellipsis),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
            // Copy button
            GestureDetector(
              onTap: () => _copyCard(card),
              child: Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Icon(Icons.copy,
                    size: 16, color: cs.onSurface.withValues(alpha: 0.4)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
