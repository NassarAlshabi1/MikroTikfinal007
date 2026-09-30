import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mikrotik_manager/features/dashboard/data/dashboard_repository_impl.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late DashboardRepositoryImpl repository;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    repository = DashboardRepositoryImpl();
  });

  test('loads and normalizes cached dashboard status', () async {
    SharedPreferences.setMockInitialValues({
      'cached_dashboard_status': jsonEncode({
        'cpuUsage': 17,
        'memoryUsage': 42.5,
        'uptime': '1d2h',
        'dataDownloaded': 100,
        'dataUploaded': 20,
        'activeUsers': 7,
        'version': '6.49.17',
      }),
    });

    final status = await repository.loadCachedStatus();

    expect(status, isNotNull);
    expect(status!.cpuUsage, 17.0);
    expect(status.memoryUsage, 42.5);
    expect(status.activeUsers, 7);
    expect(status.version, '6.49.17');
  });

  test('rejects malformed cache instead of failing dashboard startup', () async {
    SharedPreferences.setMockInitialValues({
      'cached_dashboard_status': '{not-json',
    });

    expect(await repository.loadCachedStatus(), isNull);
  });

  test('rejects cache values with incompatible types', () async {
    SharedPreferences.setMockInitialValues({
      'cached_dashboard_status': jsonEncode({'cpuUsage': 'not-a-number'}),
    });

    expect(await repository.loadCachedStatus(), isNull);
  });

  test('loads linked client name from valid persisted data', () async {
    SharedPreferences.setMockInitialValues({
      'is_network_linked': true,
      'qahtani_linked_data': jsonEncode({
        'client_info': {'name': 'Branch Router'},
      }),
    });

    final link = await repository.loadNetworkLinkStatus();

    expect(link.isLinked, isTrue);
    expect(link.clientName, 'Branch Router');
  });

  test('handles malformed linked data without reporting an unlinked network',
      () async {
    SharedPreferences.setMockInitialValues({
      'is_network_linked': true,
      'qahtani_linked_data': 'invalid',
    });

    final link = await repository.loadNetworkLinkStatus();

    expect(link.isLinked, isTrue);
    expect(link.clientName, isEmpty);
  });
}
