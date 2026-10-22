import 'package:flutter_test/flutter_test.dart';
import 'package:mikronet/features/sites/data/sites_api.dart';

void main() {
  group('SitesApi.formatDnsServers', () {
    test('trims both server values and joins them with a comma', () {
      expect(
        SitesApi.formatDnsServers(main: ' 8.8.8.8 ', secondary: ' 1.1.1.1 '),
        '8.8.8.8,1.1.1.1',
      );
    });

    test('supports a single DNS server without a trailing comma', () {
      expect(SitesApi.formatDnsServers(main: ' 2001:4860:4860::8888 '),
          '2001:4860:4860::8888');
    });

    test('ignores a blank secondary server', () {
      expect(SitesApi.formatDnsServers(main: 'router.example', secondary: '  '),
          'router.example');
    });
  });
}
