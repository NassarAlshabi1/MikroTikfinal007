import 'package:flutter_test/flutter_test.dart';
import 'package:mikrotik_manager/services/mikrotik_card_commands.dart';
import 'package:mikrotik_manager/services/mikrotik_service_mode.dart';

void main() {
  group('MikrotikCardCommands Hotspot v6', () {
    test('يبني أمر Hotspot محلي بالحقول الصحيحة', () {
      final command = MikrotikCardCommands.addUser(
        mode: MikrotikServiceMode.hotspot,
        username: '100001',
        password: '100001',
        profile: 'default',
        sharedUsers: '1',
        isVersion7OrNewer: false,
        customer: 'unused',
      );

      expect(command, [
        '/ip/hotspot/user/add',
        '=name=100001',
        '=password=100001',
        '=profile=default',
      ]);
      expect(command.join(' '), isNot(contains('user-manager')));
      expect(command.join(' '), isNot(contains('shared-users')));
      expect(command.join(' '), isNot(contains('customer')));
    });

    test('يحذف password عندما يكون نمط الكرت username-only', () {
      final command = MikrotikCardCommands.addUser(
        mode: MikrotikServiceMode.hotspot,
        username: '100002',
        password: '',
        profile: 'profile-1',
        sharedUsers: '1',
        isVersion7OrNewer: false,
        customer: 'unused',
      );

      expect(command, [
        '/ip/hotspot/user/add',
        '=name=100002',
        '=profile=profile-1',
      ]);
    });
  });

  test('يحافظ على مسار User Manager عند طلبه صراحة', () {
    final command = MikrotikCardCommands.addUser(
      mode: MikrotikServiceMode.userManager,
      username: 'user-1',
      password: 'pass-1',
      profile: 'p1',
      sharedUsers: '2',
      isVersion7OrNewer: false,
      customer: 'admin',
    );

    expect(command, contains('/tool/user-manager/user/add'));
    expect(command, contains('=username=user-1'));
    expect(command, contains('=shared-users=2'));
    expect(command, contains('=customer=admin'));
  });
}
