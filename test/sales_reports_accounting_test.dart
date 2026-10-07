// Unit tests for Financial Accounting & Sales Synchronization
// الحسابات المالية #مبيعات_شبكتك

import 'package:flutter_test/flutter_test.dart';
import 'package:mikronet/api/reports_api.dart';
import 'package:mikronet/models/selles_model.dart';

void main() {
  group('ReportsApi Date Parser Tests', () {
    test('parses RouterOS v6 format: jul/16/2025 11:32:32', () {
      final dt = ReportsApi.parsePaymentDate('jul/16/2025 11:32:32');
      expect(dt, isNotNull);
      expect(dt!.year, equals(2025));
      expect(dt.month, equals(7));
      expect(dt.day, equals(16));
      expect(dt.hour, equals(11));
      expect(dt.minute, equals(32));
      expect(dt.second, equals(32));
    });

    test('parses ISO format: 2026-10-07 14:05:00', () {
      final dt = ReportsApi.parsePaymentDate('2026-10-07 14:05:00');
      expect(dt, isNotNull);
      expect(dt!.year, equals(2026));
      expect(dt.month, equals(10));
      expect(dt.day, equals(7));
      expect(dt.hour, equals(14));
      expect(dt.minute, equals(5));
    });

    test('parses slashed date format: 2026/03/15 08:30:00', () {
      final dt = ReportsApi.parsePaymentDate('2026/03/15 08:30:00');
      expect(dt, isNotNull);
      expect(dt!.year, equals(2026));
      expect(dt.month, equals(3));
      expect(dt.day, equals(15));
      expect(dt.hour, equals(8));
    });

    test('handles invalid date strings gracefully', () {
      expect(ReportsApi.parsePaymentDate(''), isNull);
      expect(ReportsApi.parsePaymentDate('invalid_date_format'), isNull);
    });
  });

  group('SellesReportModel Database Mapping & Deduplication', () {
    test('converts correctly between SQLite map and Model', () {
      final dbMap = {
        'id': 1,
        'card_username': 'user1001',
        'profile_name': '1_hour_card',
        'price': 250.0,
        'sale_date': 'jul/16/2025 11:32:32',
        'timestamp': 1752665552000,
        'router_serial': 'HCD8829910',
        'source': 'usermanager',
      };

      final model = SellesReportModel.fromDatabase(dbMap);
      expect(model.id, equals(1));
      expect(model.card, equals('user1001'));
      expect(model.profile, equals('1_hour_card'));
      expect(model.price, equals(250.0));
      expect(model.date, equals('jul/16/2025 11:32:32'));
      expect(model.timestamp, equals(1752665552000));

      final serialized = model.toDatabase(routerSerial: 'HCD8829910');
      expect(serialized['card_username'], equals('user1001'));
      expect(serialized['profile_name'], equals('1_hour_card'));
      expect(serialized['price'], equals(250.0));
      expect(serialized['router_serial'], equals('HCD8829910'));
    });
  });
}
