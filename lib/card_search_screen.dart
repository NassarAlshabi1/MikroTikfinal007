// ============================================================
//  CardSearchScreen — بحث فوري في الكروت باستخدام Isar
//  البحث في username عبر Isar indexes (سريع جداً)
// ============================================================

import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'database/isar/card_collection.dart';
import 'database/isar/profile_collection.dart';
import 'database/daos/cards_dao.dart';
import 'database/daos/profiles_dao.dart';
import 'main.dart';

import 'theme/app_theme.dart';

enum CardSearchStatus { all, active, disabled, expired }

class CardSearchScreen extends StatefulWidget {
  const CardSearchScreen({super.key});

  @override
  State<CardSearchScreen> createState() => _CardSearchScreenState();
}

class _CardSearchScreenState extends State<CardSearchScreen> {
  final _searchController = TextEditingController();
  Timer? _searchDebounce;
  List<CardCollection> _results = [];
  List<ProfileCollection> _profiles = [];
  bool _isSearching = false;
  bool _isLoadingProfiles = true;
  String? _error;
  String _selectedProfileName = '';
  CardSearchStatus _selectedStatus = CardSearchStatus.all;
  int _searchRequestId = 0;

  @override
  void initState() {
    super.initState();
    unawaited(_loadProfiles());
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadProfiles() async {
    try {
      final isar = await appDatabaseProvider.instance;
      final profiles = await ProfilesDao(isar).getAllProfiles();
      if (!mounted) return;
      setState(() {
        _profiles = profiles;
        _isLoadingProfiles = false;
      });
    } catch (e) {
      debugPrint('[CardSearch] profile loading error: $e');
      if (mounted) setState(() => _isLoadingProfiles = false);
    }
  }

  Future<void> _performSearch(String query) async {
    final normalizedQuery = query.trim();
    final hasFilters = _selectedProfileName.isNotEmpty ||
        _selectedStatus != CardSearchStatus.all;
    if (normalizedQuery.isEmpty && !hasFilters) {
      if (!mounted) return;
      setState(() {
        _results = [];
        _error = null;
        _isSearching = false;
      });
      return;
    }

    final requestId = ++_searchRequestId;
    if (mounted) {
      setState(() {
        _isSearching = true;
        _error = null;
      });
    }

    try {
      final isar = await appDatabaseProvider.instance;
      final cardsDao = CardsDao(isar);
      List<CardCollection> results;
      if (normalizedQuery.isEmpty) {
        results = await cardsDao.getAllCards();
      } else {
        final searchTerms = normalizedQuery
            .split(RegExp(r'\s+'))
            .where((term) => term.isNotEmpty)
            .toList();
        results = await cardsDao.searchCards(searchTerms.first);
        if (searchTerms.length > 1) {
          results = results.where((card) {
            final searchable =
                '${card.username} ${card.password ?? ''}'.toLowerCase();
            return searchTerms
                .every((term) => searchable.contains(term.toLowerCase()));
          }).toList();
        }
      }

      if (_selectedProfileName.isNotEmpty) {
        final profile = _profiles.cast<ProfileCollection?>().firstWhere(
              (item) => item?.name == _selectedProfileName,
              orElse: () => null,
            );
        if (profile != null) {
          results =
              results.where((card) => card.profileId == profile.id).toList();
        } else {
          results = [];
        }
      }

      switch (_selectedStatus) {
        case CardSearchStatus.all:
          break;
        case CardSearchStatus.active:
          results = results.where((card) => card.status == 'active').toList();
          break;
        case CardSearchStatus.disabled:
          results = results.where((card) => card.status == 'disabled').toList();
          break;
        case CardSearchStatus.expired:
          results = results.where((card) => card.status == 'expired').toList();
          break;
      }

      if (!mounted || requestId != _searchRequestId) return;
      setState(() {
        _results = results;
        _isSearching = false;
      });
    } catch (e) {
      if (mounted && requestId == _searchRequestId) {
        setState(() {
          _error = 'خطأ في البحث: $e';
          _isSearching = false;
        });
      }
    }
  }

  void _scheduleSearch(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 280), () {
      unawaited(_performSearch(value));
    });
  }

  void _clearSearchOptions() {
    _searchController.clear();
    setState(() {
      _selectedProfileName = '';
      _selectedStatus = CardSearchStatus.all;
      _results = [];
      _error = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('بحث في الكروت'),
      ),
      body: Column(
        children: [
          // ===== صندوق البحث =====
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'ابحث باسم المستخدم أو كلمة المرور...',
                hintStyle: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).appColors.textSecondary,
                ),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: Theme.of(context).appColors.primary,
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        tooltip: 'مسح البحث',
                        icon: Icon(
                          Icons.clear_rounded,
                          color: Theme.of(context).appColors.textSecondary,
                        ),
                        onPressed: () {
                          _searchController.clear();
                          unawaited(_performSearch(''));
                          setState(() {});
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: Theme.of(context).appColors.outline,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: Theme.of(context).appColors.outline,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: Theme.of(context).appColors.inputFocusedBorder,
                    width: 2,
                  ),
                ),
                filled: true,
                fillColor: Theme.of(context).appColors.inputBackground,
              ),
              style: TextStyle(
                fontSize: 16,
                color: Theme.of(context).appColors.textPrimary,
              ),
              textInputAction: TextInputAction.search,
              onSubmitted: _performSearch,
              onChanged: (value) {
                setState(() {});
                if (value.trim().length >= 2 ||
                    _selectedProfileName.isNotEmpty ||
                    _selectedStatus != CardSearchStatus.all) {
                  _scheduleSearch(value);
                } else if (value.trim().isEmpty) {
                  unawaited(_performSearch(value));
                } else {
                  setState(() => _results = []);
                }
              },
            ),
          ),

          _buildSearchOptionsCard(),

          // ===== عدد النتائج =====
          if (!_isSearching &&
              _error == null &&
              (_searchController.text.isNotEmpty ||
                  _selectedProfileName.isNotEmpty ||
                  _selectedStatus != CardSearchStatus.all))
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'النتائج: ${_results.length} كرت',
                  style: TextStyle(
                      fontSize: 12, color: Theme.of(context).hintColor),
                ),
              ),
            ),

          const SizedBox(height: 8),

          // ===== النتائج =====
          Expanded(
            child: _isSearching
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error_outline,
                                size: 48,
                                color: Theme.of(context).appColors.error),
                            const SizedBox(height: 16),
                            Text(_error!),
                          ],
                        ),
                      )
                    : _results.isEmpty
                        ? _buildEmptyState()
                        : ListView.builder(
                            scrollCacheExtent:
                                const ScrollCacheExtent.pixels(250),
                            itemCount: _results.length,
                            itemBuilder: (context, index) {
                              final card = _results[index];
                              return _buildCardTile(card);
                            },
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchOptionsCard() {
    final theme = Theme.of(context);
    final colors = theme.appColors;
    final hasFilters = _selectedProfileName.isNotEmpty ||
        _selectedStatus != CardSearchStatus.all;

    String statusLabel(CardSearchStatus status) {
      switch (status) {
        case CardSearchStatus.all:
          return 'الكل';
        case CardSearchStatus.active:
          return 'نشطة';
        case CardSearchStatus.disabled:
          return 'معطلة';
        case CardSearchStatus.expired:
          return 'منتهية';
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        margin: EdgeInsets.zero,
        color: colors.card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: colors.outlineVariant),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: colors.primary.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.tune_rounded,
                      size: 20,
                      color: colors.primary,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'خيارات البحث',
                          style: TextStyle(
                            color: colors.textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'حدّد فئة الكرت أو حالته لتضييق النتائج',
                          style: TextStyle(
                            color: colors.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (hasFilters)
                    TextButton.icon(
                      onPressed: _clearSearchOptions,
                      icon: Icon(Icons.clear_all_rounded,
                          size: 17, color: colors.primary),
                      label: Text(
                        'مسح',
                        style: TextStyle(color: colors.primary, fontSize: 12),
                      ),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _selectedProfileName,
                isExpanded: true,
                dropdownColor: colors.surface,
                icon: Icon(Icons.keyboard_arrow_down_rounded,
                    color: colors.primary),
                style: TextStyle(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
                decoration: InputDecoration(
                  labelText: 'الفئة (البروفايل)',
                  prefixIcon: Icon(Icons.category_rounded,
                      color: colors.primary, size: 21),
                  suffixIcon: _isLoadingProfiles
                      ? Padding(
                          padding: const EdgeInsets.all(12),
                          child: SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: colors.primary,
                            ),
                          ),
                        )
                      : null,
                  filled: true,
                  fillColor: colors.inputBackground,
                  labelStyle: TextStyle(color: colors.textSecondary),
                  floatingLabelStyle: TextStyle(
                    color: colors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: colors.outline),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: colors.primary, width: 2),
                  ),
                ),
                items: [
                  const DropdownMenuItem<String>(
                    value: '',
                    child: Text('جميع الفئات'),
                  ),
                  ..._profiles.map(
                    (profile) => DropdownMenuItem<String>(
                      value: profile.name,
                      child: Text(profile.name),
                    ),
                  ),
                ],
                onChanged: (value) {
                  setState(() => _selectedProfileName = value ?? '');
                  unawaited(_performSearch(_searchController.text));
                },
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(Icons.filter_alt_outlined,
                      size: 18, color: colors.textSecondary),
                  const SizedBox(width: 6),
                  Text(
                    'حالة الكرت',
                    style: TextStyle(
                      color: colors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 7),
              Wrap(
                spacing: 7,
                runSpacing: 7,
                children: CardSearchStatus.values.map((status) {
                  final selected = _selectedStatus == status;
                  return ChoiceChip(
                    selected: selected,
                    label: Text(statusLabel(status)),
                    avatar: Icon(
                      status == CardSearchStatus.all
                          ? Icons.select_all_rounded
                          : status == CardSearchStatus.active
                              ? Icons.check_circle_outline_rounded
                              : status == CardSearchStatus.disabled
                                  ? Icons.block_rounded
                                  : Icons.hourglass_bottom_rounded,
                      size: 16,
                      color: selected ? colors.onPrimary : colors.textSecondary,
                    ),
                    labelStyle: TextStyle(
                      color: selected ? colors.onPrimary : colors.textPrimary,
                      fontSize: 12,
                      fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                    ),
                    selectedColor: colors.primary,
                    backgroundColor: colors.surfaceVariant,
                    side: BorderSide(
                      color: selected ? colors.primary : colors.outlineVariant,
                    ),
                    onSelected: (_) {
                      setState(() => _selectedStatus = status);
                      unawaited(_performSearch(_searchController.text));
                    },
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _searchController.text.isEmpty ? Icons.search : Icons.search_off,
            size: 64,
            color:
                Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            _searchController.text.isEmpty &&
                    _selectedProfileName.isEmpty &&
                    _selectedStatus == CardSearchStatus.all
                ? 'ابدأ الكتابة أو اختر خيارات البحث'
                : 'لا توجد نتائج',
            style: TextStyle(fontSize: 16, color: Theme.of(context).hintColor),
          ),
          const SizedBox(height: 8),
          Text(
            'البحث يستخدم FTS5 — أسرع 1000x من البحث العادي',
            style:
                TextStyle(fontSize: 12, color: Theme.of(context).disabledColor),
          ),
        ],
      ),
    );
  }

  Widget _buildCardTile(CardCollection card) {
    final statusColor = card.status == 'active'
        ? Theme.of(context).appColors.success
        : card.status == 'disabled'
            ? Theme.of(context).appColors.warning
            : Theme.of(context).appColors.error;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: statusColor,
          child: Text(
            card.username.isNotEmpty ? card.username[0].toUpperCase() : '?',
            style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(
          card.username,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (card.password != null && card.password!.isNotEmpty)
              Text('كلمة المرور: ${card.password}',
                  style: const TextStyle(fontSize: 12)),
            Text(
              'الحالة: ${_statusText(card.status)} • '
              'تنزيل: ${_formatBytes(card.downloadBytes)} • '
              'رفع: ${_formatBytes(card.uploadBytes)}',
              style: TextStyle(fontSize: 11, color: statusColor),
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (action) {
            switch (action) {
              case 'copy':
                // نسخ اسم المستخدم
                break;
              case 'delete':
                _confirmDelete(card);
                break;
            }
          },
          itemBuilder: (_) => [
            const PopupMenuItem(value: 'copy', child: Text('نسخ اسم المستخدم')),
            PopupMenuItem(
                value: 'delete',
                child: Text('حذف',
                    style:
                        TextStyle(color: Theme.of(context).appColors.error))),
          ],
        ),
        isThreeLine: true,
      ),
    );
  }

  String _statusText(String status) {
    switch (status) {
      case 'active':
        return 'نشط';
      case 'disabled':
        return 'معطّل';
      case 'expired':
        return 'منتهي';
      default:
        return status;
    }
  }

  String _formatBytes(int bytes) {
    if (bytes == 0) return '0 B';
    const units = ['B', 'KB', 'MB', 'GB', 'TB'];
    final size = bytes.toDouble();
    final unitIndex =
        (log(size) / log(1024)).floor().clamp(0, units.length - 1);
    final value = size / pow(1024, unitIndex);
    return '${value.toStringAsFixed(1)} ${units[unitIndex]}';
  }

  void _confirmDelete(CardCollection card) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف الكرت'),
        content: Text('هل تريد حذف الكرت "${card.username}"؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).appColors.error),
            onPressed: () async {
              Navigator.of(ctx).pop();
              final isar = await appDatabaseProvider.instance;
              await CardsDao(isar).deleteCard(card.id);
              _performSearch(_searchController.text);
            },
            child: Text('حذف',
                style:
                    TextStyle(color: Theme.of(context).colorScheme.onSurface)),
          ),
        ],
      ),
    );
  }
}
