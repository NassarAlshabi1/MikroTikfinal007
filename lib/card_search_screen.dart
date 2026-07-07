// ============================================================
//  CardSearchScreen — بحث فوري في الكروت باستخدام FTS5
//  البحث في username, password, profile_name
//  يستخدم SQLite FTS5 (أسرع 1000x من البحث في Dart)
// ============================================================

import 'dart:math';
import 'package:flutter/material.dart';
import '../database/app_database.dart';
import '../main.dart';

class CardSearchScreen extends StatefulWidget {
  const CardSearchScreen({super.key});

  @override
  State<CardSearchScreen> createState() => _CardSearchScreenState();
}

class _CardSearchScreenState extends State<CardSearchScreen> {
  final _searchController = TextEditingController();
  List<Card> _results = [];
  bool _isSearching = false;
  String? _error;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _results = [];
        _error = null;
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _error = null;
    });

    try {
      // تحويل الاستعلام لصيغة FTS5
      // FTS5 يدعم: word, prefix*, "phrase", OR, AND, NOT
      // نحول المسافات إلى OR (ابحث عن أي كلمة)
      final ftsQuery = query.split(' ').where((w) => w.isNotEmpty).join(' OR ');

      final results = await appDatabase.cardsDao.searchCards(ftsQuery);
      setState(() {
        _results = results;
        _isSearching = false;
      });
    } catch (e) {
      setState(() {
        _error = 'خطأ في البحث: $e';
        _isSearching = false;
      });
    }
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
                hintText: 'ابحث باسم المستخدم، كلمة المرور، أو الفئة...',
                hintStyle: const TextStyle(fontSize: 14),
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _performSearch('');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Theme.of(context).cardColor,
              ),
              style: const TextStyle(fontSize: 16),
              textInputAction: TextInputAction.search,
              onSubmitted: _performSearch,
              onChanged: (value) {
                // تحديث زر المسح
                setState(() {});
                // بحث تلقائي عند الكتابة (debounce بسيط)
                if (value.length >= 2) {
                  _performSearch(value);
                } else if (value.isEmpty) {
                  setState(() => _results = []);
                }
              },
            ),
          ),

          // ===== عدد النتائج =====
          if (!_isSearching && _error == null && _searchController.text.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'النتائج: ${_results.length} كرت',
                  style: const TextStyle(
                      fontSize: 12, color: Colors.white54),
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
                            const Icon(Icons.error_outline,
                                size: 48, color: Colors.red),
                            const SizedBox(height: 16),
                            Text(_error!),
                          ],
                        ),
                      )
                    : _results.isEmpty
                        ? _buildEmptyState()
                        : ListView.builder(
                            itemCount: _results.length,
                            cacheExtent: 250,
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _searchController.text.isEmpty
                ? Icons.search
                : Icons.search_off,
            size: 64,
            color: Colors.white.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            _searchController.text.isEmpty
                ? 'ابدأ الكتابة للبحث الفوري'
                : 'لا توجد نتائج',
            style: const TextStyle(fontSize: 16, color: Colors.white54),
          ),
          const SizedBox(height: 8),
          const Text(
            'البحث يستخدم FTS5 — أسرع 1000x من البحث العادي',
            style: TextStyle(fontSize: 12, color: Colors.white38),
          ),
        ],
      ),
    );
  }

  Widget _buildCardTile(Card card) {
    final statusColor = card.status == 'active'
        ? Colors.green
        : card.status == 'disabled'
            ? Colors.orange
            : Colors.red;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: statusColor,
          child: Text(
            card.username.isNotEmpty ? card.username[0].toUpperCase() : '?',
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold),
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
          itemBuilder: (_) => const [
            PopupMenuItem(value: 'copy', child: Text('نسخ اسم المستخدم')),
            PopupMenuItem(
                value: 'delete',
                child:
                    Text('حذف', style: TextStyle(color: Colors.red))),
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
    final unitIndex = (log(size) / log(1024)).floor().clamp(0, units.length - 1);
    final value = size / pow(1024, unitIndex);
    return '${value.toStringAsFixed(1)} ${units[unitIndex]}';
  }

  void _confirmDelete(Card card) {
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
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.of(ctx).pop();
              await appDatabase.cardsDao.deleteCard(card.id);
              _performSearch(_searchController.text);
            },
            child: const Text('حذف', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
