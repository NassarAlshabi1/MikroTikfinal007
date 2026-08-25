// ============================================================
//  CardsDao (Isar) — Data Access Object لجدول الكروت
//
//  يحل محل قاعدة البيانات السابقة CardsDao القديم.
//  يحافظ على نفس الـ API لتقليل التغييرات في المستهلكين.
// ============================================================

import 'package:isar/isar.dart';

import '../isar/card_collection.dart';

class CardsStatistics {
  final int totalCards;
  final int activeCards;
  final int disabledCards;
  final int expiredCards;
  final int totalUploadBytes;
  final int totalDownloadBytes;

  const CardsStatistics({
    required this.totalCards,
    required this.activeCards,
    required this.disabledCards,
    required this.expiredCards,
    required this.totalUploadBytes,
    required this.totalDownloadBytes,
  });

  int get totalBytes => totalUploadBytes + totalDownloadBytes;

  double get totalUploadGB => totalUploadBytes / (1024 * 1024 * 1024);

  double get totalDownloadGB => totalDownloadBytes / (1024 * 1024 * 1024);
}

class CardsDao {
  final Isar _isar;
  CardsDao(this._isar);

  // ============================================================
  //  CRUD Operations
  // ============================================================

  /// إضافة كرت جديد
  Future<int> insertCard(CardCollection card) async {
    await _isar.writeTxn(() => _isar.cardCollections.put(card));
    return card.id;
  }

  /// إضافة عدة كروت في transaction واحد (atomic)
  Future<void> insertCards(List<CardCollection> newCards) async {
    await _isar.writeTxn(() => _isar.cardCollections.putAll(newCards));
  }

  /// تحديث كرت
  Future<bool> updateCard(CardCollection card) async {
    await _isar.writeTxn(() => _isar.cardCollections.put(card));
    return true;
  }

  /// حذف كرت
  Future<bool> deleteCard(int id) async {
    return await _isar.writeTxn(() => _isar.cardCollections.delete(id));
  }

  /// حذف كل الكروت
  Future<int> deleteAllCards() async {
    return await _isar.writeTxn(() async {
      final count = await _isar.cardCollections.count();
      await _isar.cardCollections.clear();
      return count;
    });
  }

  // ============================================================
  //  Queries
  // ============================================================

  /// كل الكروت (مرتبة بالأحدث)
  Future<List<CardCollection>> getAllCards() async {
    return await _isar.cardCollections
        .where()
        .sortByCreatedAtDesc()
        .findAll();
  }

  /// كرت بالـ ID
  Future<CardCollection?> getCardById(int id) async {
    return await _isar.cardCollections.get(id);
  }

  /// كرت بالـ username
  Future<CardCollection?> getCardByUsername(String username) async {
    return await _isar.cardCollections
        .where()
        .usernameEqualTo(username)
        .findFirst();
  }

  /// الكروت النشطة فقط
  Future<List<CardCollection>> getActiveCards() async {
    return await _isar.cardCollections
        .filter()
        .statusEqualTo('active')
        .findAll();
  }

  /// الكروت المنتهية
  Future<List<CardCollection>> getExpiredCards() async {
    return await _isar.cardCollections
        .filter()
        .statusEqualTo('expired')
        .findAll();
  }

  /// الكروت المنتهية بين تاريخين
  Future<List<CardCollection>> getCardsExpiringBetween(
    DateTime start,
    DateTime end,
  ) async {
    return await _isar.cardCollections
        .filter()
        .statusEqualTo('active')
        .expiresAtBetween(start, end)
        .findAll();
  }

  /// أعلى N مستخدمين استهلاكاً
  Future<List<CardCollection>> getTopConsumers(int limit) async {
    final all = await _isar.cardCollections
        .filter()
        .statusEqualTo('active')
        .findAll();
    all.sort((a, b) => b.totalBytes.compareTo(a.totalBytes));
    return all.take(limit).toList();
  }

  // ============================================================
  //  Stream Queries (reactive)
  // ============================================================

  /// Stream لكل الكروت
  Stream<List<CardCollection>> watchAllCards() {
    return _isar.cardCollections
        .where()
        .sortByCreatedAtDesc()
        .watch(fireImmediately: true);
  }

  /// Stream للكروت النشطة
  Stream<List<CardCollection>> watchActiveCards() {
    return _isar.cardCollections
        .filter()
        .statusEqualTo('active')
        .watch(fireImmediately: true);
  }

  /// Stream لكرت واحد
  Stream<CardCollection?> watchCardById(int id) {
    return _isar.cardCollections.watchObject(id, fireImmediately: true);
  }

  // ============================================================
  //  Statistics
  // ============================================================

  /// إحصائيات شاملة
  Future<CardsStatistics> getStatistics() async {
    final allCards = await _isar.cardCollections.where().findAll();

    int activeCount = 0;
    int disabledCount = 0;
    int expiredCount = 0;
    int totalUpload = 0;
    int totalDownload = 0;

    for (final card in allCards) {
      switch (card.status) {
        case 'active':
          activeCount++;
          break;
        case 'disabled':
          disabledCount++;
          break;
        case 'expired':
          expiredCount++;
          break;
      }
      totalUpload += card.uploadBytes;
      totalDownload += card.downloadBytes;
    }

    return CardsStatistics(
      totalCards: allCards.length,
      activeCards: activeCount,
      disabledCards: disabledCount,
      expiredCards: expiredCount,
      totalUploadBytes: totalUpload,
      totalDownloadBytes: totalDownload,
    );
  }

  // ============================================================
  //  Search — بحث فوري عبر Isar indexes
  // ============================================================

  /// بحث في الكروت (يستخدم username filter)
  Future<List<CardCollection>> searchCards(String query) async {
    if (query.isEmpty) return getAllCards();

    return await _isar.cardCollections
        .filter()
        .usernameContains(query, caseSensitive: false)
        .findAll();
  }

  // ============================================================
  //  Bulk Operations
  // ============================================================

  /// تحديث حالة عدة كروت في transaction
  Future<void> updateStatusBatch(List<int> ids, String newStatus) async {
    await _isar.writeTxn(() async {
      final cards = await _isar.cardCollections.getAll(ids);
      for (var i = 0; i < cards.length; i++) {
        if (cards[i] != null) {
          cards[i]!.status = newStatus;
        }
      }
      await _isar.cardCollections.putAll(cards.whereType<CardCollection>().toList());
    });
  }

  /// حذف الكروت المنتهية قبل تاريخ محدد
  Future<int> deleteExpiredBefore(DateTime date) async {
    return await _isar.writeTxn(() async {
      final expired = await _isar.cardCollections
          .filter()
          .statusEqualTo('expired')
          .expiresAtLessThan(date)
          .findAll();
      for (final card in expired) {
        await _isar.cardCollections.delete(card.id);
      }
      return expired.length;
    });
  }
}
