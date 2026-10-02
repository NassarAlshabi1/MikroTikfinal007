import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:mikrotik_manager/services/mikrotik_service_mode.dart';
import 'package:mikrotik_manager/services/router_os_card_gateway.dart';

void main() {
  test('ينفذ إضافة Hotspot ثم يتحقق من وجود الكرت', () async {
    final talker = FakeRouterOsTalker(existingNames: {'10000001'});
    final gateway = RouterOsCardGateway(talker);

    final created = await gateway.addCard(
      mode: MikrotikServiceMode.hotspot,
      username: '10000001',
      password: '10000001',
      profile: 'default',
      sharedUsers: '1',
      isVersion7OrNewer: false,
      customer: 'admin',
    );
    final verified = await gateway.verifyUsers(
      mode: MikrotikServiceMode.hotspot,
      users: [created.toMap()],
    );

    expect(created.username, '10000001');
    expect(verified.single['username'], '10000001');
    expect(talker.commands.first.first, '/ip/hotspot/user/add');
    expect(
        talker.commands
            .any((command) => command.first == '/ip/hotspot/user/print'),
        isTrue);
  });

  test('ينشئ مستخدم User Manager قبل تفعيل البروفايل', () async {
    final talker = FakeRouterOsTalker(existingNames: {});
    final gateway = RouterOsCardGateway(talker);

    final result = await gateway.createCardAndActivateProfile(
      mode: MikrotikServiceMode.userManager,
      username: 'user-1',
      password: 'pass-1',
      profile: 'profile-1',
      sharedUsers: '1',
      isVersion7OrNewer: false,
      customer: 'admin',
    );

    expect(
      talker.commands.map((command) => command.first),
      [
        '/tool/user-manager/user/add',
        '/tool/user-manager/user/create-and-activate-profile',
      ],
    );
    expect(result.card.username, 'user-1');
    expect(result.activationWarning, isNull);
  });

  test('يحفظ المستخدم إذا تعذر تفعيل البروفايل بعد إضافته', () async {
    final talker = FakeRouterOsTalker(
      existingNames: {},
      throwOnCommand: '/tool/user-manager/user/create-and-activate-profile',
    );
    final gateway = RouterOsCardGateway(talker);

    final result = await gateway.createCardAndActivateProfile(
      mode: MikrotikServiceMode.userManager,
      username: 'user-2',
      password: 'pass-2',
      profile: 'profile-1',
      sharedUsers: '1',
      isVersion7OrNewer: false,
      customer: 'admin',
    );

    expect(result.card.username, 'user-2');
    expect(result.activationWarning, contains('تعذر تفعيل البروفايل'));
    expect(talker.commands, hasLength(2));
  });

  test('يعيد confirmedUsers ويبلغ عن المفقود في الفشل الجزئي', () async {
    final talker = FakeRouterOsTalker(existingNames: {'10000001'});
    final gateway = RouterOsCardGateway(talker);

    expect(
      () => gateway.verifyUsers(
        mode: MikrotikServiceMode.hotspot,
        users: const [
          {'username': '10000001', 'password': 'p1'},
          {'username': '10000002', 'password': 'p2'},
        ],
      ),
      throwsA(
        isA<RouterOsVerificationException>().having(
          (error) => error.confirmedUsers,
          'confirmedUsers',
          hasLength(1),
        ),
      ),
    );
  });

  test('يعيد محاولة قراءة التحقق عند خطأ شبكة مؤقت', () async {
    final talker = FakeRouterOsTalker(
      existingNames: {'10000001'},
      transientFailures: 2,
    );
    final gateway = RouterOsCardGateway(talker);

    final verified = await gateway.verifyUsers(
      mode: MikrotikServiceMode.hotspot,
      users: const [
        {'username': '10000001', 'password': 'p1'},
      ],
    );

    expect(verified, hasLength(1));
    // verifyUsers now uses a single bulk fetch (_allUsersCommand),
    // so it retries that single call up to 3 times on transient errors.
    expect(talker.printAttempts, 3);
  });
}

class FakeRouterOsTalker implements RouterOsTalker {
  FakeRouterOsTalker({
    required this.existingNames,
    this.transientFailures = 0,
    this.throwOnCommand,
  });

  final Set<String> existingNames;
  final String? throwOnCommand;
  int transientFailures;
  int printAttempts = 0;
  final List<List<String>> commands = [];

  @override
  String get address => 'mock-router';

  @override
  Future<List<Map<String, String>>> talk(List<String> command) async {
    commands.add(command);
    if (command.first == throwOnCommand) {
      throw StateError('simulated RouterOS failure');
    }
    if (command.first.endsWith('/print')) {
      printAttempts++;
      if (transientFailures > 0) {
        transientFailures--;
        throw const SocketException('temporary failure');
      }

      // Detect bulk fetch vs single-user query.
      // Bulk: no '?name=' filter → return ALL existing users.
      // Single: has '?name=' → return matching user.
      final hasFilter = command.any((part) => part.startsWith('?name='));
      if (!hasFilter) {
        // Bulk fetch (_allUsersCommand) — return all existing users
        return existingNames
            .map((name) => <String, String>{'.id': '*1', 'name': name})
            .toList();
      }

      final username =
          command.firstWhere((part) => part.startsWith('?name=')).substring(6);
      if (existingNames.contains(username)) {
        return [
          {'.id': '*1', 'name': username},
        ];
      }
      return const [];
    }
    return const [
      {'.id': '*1'},
    ];
  }
}
