import 'package:flutter_test/flutter_test.dart';
import 'package:mikrotik_manager/services/user_manager_profile_parser.dart';

void main() {
  group('UserManagerProfileParser', () {
    test('parses the normal RouterOS name field', () {
      final result = UserManagerProfileParser.parse([
        {'name': 'basic', 'rate-limit': '1M/1M'},
      ]);

      expect(result, hasLength(1));
      expect(result.single['name'], 'basic');
    });

    test('accepts legacy prefixed and profile-name aliases', () {
      final result = UserManagerProfileParser.parse([
        {'=name': 'legacy'},
        {'profile-name': 'premium'},
      ]);

      expect(result.map((row) => row['name']), ['legacy', 'premium']);
    });

    test('removes empty names and duplicate profiles', () {
      final result = UserManagerProfileParser.parse([
        {'name': 'basic'},
        {'name': ' basic '},
        {'name': ''},
        {'rate-limit': '1M/1M'},
      ]);

      expect(result, hasLength(1));
      expect(result.single['name'], 'basic');
    });

    test('returns an empty list when User Manager has no profiles', () {
      expect(UserManagerProfileParser.parse([]), isEmpty);
    });
  });
}
