import 'package:flutter_test/flutter_test.dart';
import 'package:mikrotik_manager/features/sales_reports/domain/card_usage_report.dart';
import 'package:mikrotik_manager/features/sales_reports/services/sales_report_exporter.dart';
import 'package:mikrotik_manager/services/um_cards_sync_service.dart';

void main() {
  const cards = [
    UmSyncedCard(
      name: 'active-used',
      password: 'secret-one',
      profile: 'Gold',
      uptimeUsed: '2h',
      limitUptime: '1d',
    ),
    UmSyncedCard(
      name: 'disabled-used',
      password: 'secret-two',
      profile: 'Gold',
      disabled: 'true',
      uptimeUsed: '3h',
      limitUptime: '1d',
    ),
    UmSyncedCard(
      name: 'limit-reached',
      profile: 'Silver',
      uptimeUsed: '1d',
      limitUptime: '1d',
    ),
    UmSyncedCard(name: 'unused', profile: 'Silver', uptimeUsed: '0s'),
    UmSyncedCard(name: 'unknown', profile: 'Gold'),
  ];

  group('CardUsageReport', () {
    final report = CardUsageReport(cards);

    test('classifies usage and expiry from User Manager uptime fields', () {
      expect(report.totalCount, 5);
      expect(report.usedCount, 3);
      expect(report.expiredCount, 2);
      expect(report.overlappingCount, 2);
      expect(report.unknownUsageCount, 1);
    });

    test('used and expired groups can overlap; disabled cards are expired', () {
      expect(
        report
            .rows(filter: CardUsageReportFilter.used)
            .map((card) => card.name),
        containsAll(['active-used', 'disabled-used', 'limit-reached']),
      );
      expect(
        report
            .rows(filter: CardUsageReportFilter.expired)
            .map((card) => card.name),
        containsAll(['disabled-used', 'limit-reached']),
      );
    });

    test(
      'date-expired cards appear in expired rows with an accurate status',
      () {
        const dateExpired = UmSyncedCard(
          name: 'date-expired',
          expires: '2000-01-01 23:59:59',
        );
        final dateReport = CardUsageReport([dateExpired]);

        expect(
          dateReport.rows(filter: CardUsageReportFilter.expired),
          [dateExpired],
        );
        expect(
          cardUsageReportStatus(dateExpired, CardUsageReportFilter.expired),
          'انتهى تاريخ الصلاحية',
        );
      },
    );

    test('search matches card names and profiles', () {
      expect(
        report
            .rows(filter: CardUsageReportFilter.used, query: 'silver')
            .map((card) => card.name),
        ['limit-reached'],
      );
      expect(
        report
            .rows(filter: CardUsageReportFilter.expired, query: 'disabled')
            .map((card) => card.name),
        ['disabled-used'],
      );
    });
  });

  test(
    'CSV export includes usage fields, safely quotes cells, and omits secrets',
    () {
      final csv = SalesReportExporter.buildCsv(
        cards: const [
          UmSyncedCard(
            name: '=SUM(1,1)',
            password: 'do-not-export-this',
            profile: 'Gold, special',
            uptimeUsed: '1h "active"',
            limitUptime: '1d',
            expires: '2026-10-01',
          ),
        ],
        filter: CardUsageReportFilter.used,
        lastSyncedAt: DateTime.utc(2026, 10, 2, 12, 30),
      );

      expect(csv, startsWith('\uFEFF'));
      expect(csv, contains('uptime_used'));
      expect(csv, contains('expires_at'));
      expect(csv, contains('2026-10-01'));
      expect(csv, contains("'=SUM(1,1)"));
      expect(csv, contains('"Gold, special"'));
      expect(csv, isNot(contains('do-not-export-this')));
      expect(csv, isNot(contains('password')));
    },
  );
}
