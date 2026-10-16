import 'package:flutter_test/flutter_test.dart';
import 'package:mikronet/core/mikrotik/mikrotik_client.dart';
import 'package:mikronet/features/cards/data/expired_users_api.dart';

void main() {
  group('UserManagerPaths v6/v7', () {
    tearDown(() => MikrotikClient.version = 0);

    test('v6 paths use /tool/user-manager', () {
      expect(UserManagerPaths.v6.users, startsWith('/tool/user-manager/'));
      expect(UserManagerPaths.v6.profiles, startsWith('/tool/user-manager/'));
      expect(UserManagerPaths.v6.sessions, startsWith('/tool/user-manager/'));
      expect(UserManagerPaths.v6.supportsUserProfiles, isFalse);
    });

    test('v7 paths use /user-manager', () {
      expect(UserManagerPaths.v7.users, startsWith('/user-manager/'));
      expect(UserManagerPaths.v7.profiles, startsWith('/user-manager/'));
      expect(UserManagerPaths.v7.sessions, startsWith('/user-manager/'));
      expect(UserManagerPaths.v7.supportsUserProfiles, isTrue);
    });

    test('activePaths follows detected router version', () {
      MikrotikClient.version = 6;
      expect(ExpiredUsersApi.activePaths, same(UserManagerPaths.v6));
      MikrotikClient.version = 7;
      expect(ExpiredUsersApi.activePaths, same(UserManagerPaths.v7));
      // إصدار غير معروف يعامل كـ v6 (الافتراضي الأقدم)
      MikrotikClient.version = 0;
      expect(ExpiredUsersApi.activePaths, same(UserManagerPaths.v6));
    });
  });
}
