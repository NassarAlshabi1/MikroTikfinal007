// ============================================================
//  CardsDao — Data Access Object لجدول الكروت
//  يوفّر استعلامات type-safe وأداء عالي عبر drift
// ============================================================

import 'package:drift/drift.dart';
import '../app_database.dart';

part 'cards_dao.g.dart';

@DriftAccessor(tables: [Cards, Profiles, CardsFts])
class CardsDao extends DatabaseAccessor<AppDatabase> with _$CardsDaoMixin {
  CardsDao(super.db);

  // ============================================================
  //  CRUD Operations
  // ============================================================

  /// إضافة كرت جديد
  Future<int> insertCard(CardsCompanion card) => into(cards).insert(card);

  /// إضافة عدة كروت في transaction واحد (atomic)
  Future<void> insertCards(List<CardsCompanion> newCards) async {
    await batch((b) => b.insertAll(cards, newCards));
  }

  /// تحديث كرت
  Future<bool> updateCard(Card card) =>
      update(cards).replace(card);

  /// حذف كرت
  Future<int> deleteCard(int id) =>
      (delete(cards)..where((c) => c.id.equals(id))).go();

  /// حذف كل الكروت (للـ reset)
  Future<int> deleteAllCards() => delete(cards).go();

  // ============================================================
  //  Queries
  // ============================================================

  /// كل الكروت (مرتبة بالأحدث)
  Future<List<Card>> getAllCards() =>
      (select(cards)..orderBy([(c) => OrderingTerm.desc(c.createdAt)])).get();

  /// كرت واحد بالـ ID
  Future<Card?> getCardById(int id) =>
      (select(cards)..where((c) => c.id.equals(id))).getSingleOrNull();

  /// كرت بالـ username
  Future<Card?> getCardByUsername(String username) =>
      (select(cards)..where((c) => c.username.equals(username)))
          .getSingleOrNull();

  /// الكروت النشطة فقط
  Future<List<Card>> getActiveCards() =>
      (select(cards)..where((c) => c.status.equals('active')))
          .get();

  /// الكروت المنتهية
  Future<List<Card>> getExpiredCards() =>
      (select(cards)..where((c) => c.status.equals('expired')))
          .get();

  /// الكروت المنتهية هذا الشهر
  Future<List<Card>> getCardsExpiringBetween(
      DateTime start, DateTime end) =>
      (select(cards)
            ..where((c) =>
                c.expiresAt.isBetweenValues(start, end) &
                c.status.equals('active')))
          .get();

  /// أعلى N مستخدمين استهلاكاً
  Future<List<Card>> getTopConsumers(int limit) =>
      (select(cards)
            ..where((c) => c.status.equals('active'))
            ..orderBy([(c) => OrderingTerm.desc(
                c.uploadBytes + c.downloadBytes)])
            ..limit(limit))
          .get();

  // ============================================================
  //  Stream Queries (reactive — يتحدث تلقائياً عند تغيير البيانات)
  // ============================================================

  /// Stream لكل الكروت (للـ reactive UI)
  Stream<List<Card>> watchAllCards() =>
      (select(cards)..orderBy([(c) => OrderingTerm.desc(c.createdAt)]))
          .watch();

  /// Stream للكروت النشطة
  Stream<List<Card>> watchActiveCards() =>
      (select(cards)..where((c) => c.status.equals('active')))
          .watch();

  /// Stream لكرت واحد
  Stream<Card?> watchCardById(int id) =>
      (select(cards)..where((c) => c.id.equals(id)))
          .watchSingleOrNull();

  // ============================================================
  //  Statistics (SQL aggregations — أسرع بكثير من Dart)
  // ============================================================

  /// إحصائيات شاملة في استعلام واحد
  Future<CardsStatistics> getStatistics() async {
    final totalCards = await cards.count().get();

    // عدد الكروت النشطة (selectOnly + where لأن count() يُعيد Selectable<int>
    // بدون where في drift 2.31+)
    final activeResult = await (selectOnly(cards)
          ..addColumns([cards.count()])
          ..where(cards.status.equals('active')))
        .getSingle();
    final activeCount = activeResult.read(cards.count()) ?? 0;

    final disabledResult = await (selectOnly(cards)
          ..addColumns([cards.count()])
          ..where(cards.status.equals('disabled')))
        .getSingle();
    final disabledCount = disabledResult.read(cards.count()) ?? 0;

    final expiredResult = await (selectOnly(cards)
          ..addColumns([cards.count()])
          ..where(cards.status.equals('expired')))
        .getSingle();
    final expiredCount = expiredResult.read(cards.count()) ?? 0;

    // مجموع bytes الرفع والتنزيل عبر aggregate expressions
    final uploadResult = await (selectOnly(cards)
          ..addColumns([cards.uploadBytes.sum()]))
        .getSingle();
    final totalUpload = uploadResult.read(cards.uploadBytes.sum()) ?? 0;

    final downloadResult = await (selectOnly(cards)
          ..addColumns([cards.downloadBytes.sum()]))
        .getSingle();
    final totalDownload = downloadResult.read(cards.downloadBytes.sum()) ?? 0;

    return CardsStatistics(
      totalCards: totalCards,
      activeCards: activeCount,
      disabledCards: disabledCount,
      expiredCards: expiredCount,
      totalUploadBytes: totalUpload,
      totalDownloadBytes: totalDownload,
    );
  }

  // ============================================================
  //  Full-Text Search (FTS5) — بحث فوري في آلاف الكروت
  // ============================================================

  /// بحث نصي كامل في الكروت (سريع جداً مع FTS5)
  Future<List<Card>> searchCards(String query) async {
    if (query.isEmpty) return getAllCards();

    // استخدام FTS5 MATCH للبحث الفوري
    final results = await customSelect(
      'SELECT c.* FROM cards_fts fts '
      'JOIN cards c ON c.id = fts.rowid '
      'WHERE cards_fts MATCH ? '
      'ORDER BY rank '
      'LIMIT 100',
      variables: [Variable.withString(query)],
      readsFrom: {cards, cardsFts},
    ).get();

    return results.map((row) => cards.map(row.data)).toList();
  }

  // ============================================================
  //  Bulk Operations
  // ============================================================

  /// تحديث حالة عدة كروت في transaction
  Future<void> updateStatusBatch(List<int> ids, String newStatus) async {
    await batch((b) => b.update(
          cards,
          CardsCompanion(status: Value(newStatus)),
          (c) => c.id.isIn(ids),
        ));
  }

  /// حذف الكروت المنتهية قبل تاريخ محدد
  Future<int> deleteExpiredBefore(DateTime date) =>
      (delete(cards)
            ..where((c) =>
                c.status.equals('expired') &
                c.expiresAt.isSmallerThanValue(date)))
          .go();
}

/// إحصائيات الكروت (من SQL aggregation)
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
