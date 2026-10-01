import '../../../services/um_cards_sync_service.dart';

enum CardUsageReportFilter {
  used('used', 'الكروت المستخدمة'),
  expired('expired', 'الكروت المنتهية/المعطّلة');

  const CardUsageReportFilter(this.fileSuffix, this.title);

  final String fileSuffix;
  final String title;
}

/// A read-only view over the current User Manager snapshot.
///
/// A card may belong to both groups: a used card can also be expired or
/// disabled. Missing/unparseable `uptime-used` values are not counted as used.
class CardUsageReport {
  CardUsageReport(List<UmSyncedCard> source)
      : cards = List.unmodifiable(source),
        totalCount = source.length,
        usedCount = source.where((card) => card.isUsed).length,
        expiredCount = source.where((card) => card.isExpired).length,
        overlappingCount =
            source.where((card) => card.isUsed && card.isExpired).length,
        unknownUsageCount = source
            .where((card) => parseRouterDuration(card.uptimeUsed) == null)
            .length;

  final List<UmSyncedCard> cards;
  final int totalCount;
  final int usedCount;
  final int expiredCount;
  final int overlappingCount;
  final int unknownUsageCount;

  List<UmSyncedCard> rows({
    required CardUsageReportFilter filter,
    String query = '',
  }) {
    final normalizedQuery = query.trim().toLowerCase();
    final result = cards.where((card) {
      final matchesFilter = switch (filter) {
        CardUsageReportFilter.used => card.isUsed,
        CardUsageReportFilter.expired => card.isExpired,
      };
      if (!matchesFilter) return false;
      if (normalizedQuery.isEmpty) return true;
      return card.name.toLowerCase().contains(normalizedQuery) ||
          card.profile.toLowerCase().contains(normalizedQuery);
    }).toList();

    // UmCardsSyncService already supplies a stable profile/name ordering.
    // Keep it so keystroke filtering stays linear without sorting every time.
    return result;
  }
}

String cardUsageReportStatus(
  UmSyncedCard card,
  CardUsageReportFilter filter,
) {
  if (filter == CardUsageReportFilter.used) {
    if (!card.isExpired) return 'مستخدم';
    return card.isDisabled ? 'مستخدم ومعطّل' : 'مستخدم ومنتهي';
  }
  if (card.isDisabled) return 'معطّل';
  return 'انتهى حد الاستخدام';
}
