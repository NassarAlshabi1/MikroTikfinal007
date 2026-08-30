import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:mikrotik_manager/services/router_os_card_gateway.dart'
    show RouterOsTalker;
import 'package:mikrotik_manager/services/um_cards_sync_service.dart';

void main() {
  group('parseRouterDuration', () {
    test('يحلل الوحدات المفردة', () {
      expect(parseRouterDuration('10s'), 10);
      expect(parseRouterDuration('5m'), 300);
      expect(parseRouterDuration('3h'), 3 * 3600);
      expect(parseRouterDuration('2d'), 2 * 86400);
      expect(parseRouterDuration('1w'), 7 * 86400);
    });

    test('يحلل الوحدات المركبة', () {
      expect(
        parseRouterDuration('1d2h3m4s'),
        86400 + 2 * 3600 + 3 * 60 + 4,
      );
      expect(
        parseRouterDuration('1w2d3h'),
        7 * 86400 + 2 * 86400 + 3 * 3600,
      );
    });

    test('يحلل الجزء الزمني HH:MM:SS', () {
      expect(parseRouterDuration('03:00:00'), 3 * 3600);
      expect(parseRouterDuration('23:59:59'), 23 * 3600 + 59 * 60 + 59);
      expect(parseRouterDuration('02:30'), 2 * 3600 + 30 * 60);
    });

    test('يحلل الوحدات والجزء الزمني معاً', () {
      // صيغة v6 الشائعة بعد الأسابيع والأيام.
      expect(
        parseRouterDuration('1w2d 03:04:05'),
        7 * 86400 + 2 * 86400 + 3 * 3600 + 4 * 60 + 5,
      );
      // بدون فراغ بين الأيام والوقت.
      expect(
        parseRouterDuration('4d23:59:59'),
        4 * 86400 + 23 * 3600 + 59 * 60 + 59,
      );
    });

    test('يعيد null للقيم غير القابلة للتحليل', () {
      expect(parseRouterDuration(null), isNull);
      expect(parseRouterDuration(''), isNull);
      expect(parseRouterDuration('   '), isNull);
      expect(parseRouterDuration('never'), isNull);
      expect(parseRouterDuration('غير معروف'), isNull);
    });

    test('يحلل الرقم المجرد كثوانٍ', () {
      expect(parseRouterDuration('120'), 120);
    });
  });

  group('UmSyncedCard.isExpired', () {
    test('المعطل منتهي', () {
      const card = UmSyncedCard(name: 'a', disabled: 'yes');
      expect(card.isExpired, isTrue);
      expect(card.isActive, isFalse);
    });

    test('من استهلك حدّه الزمني منتهٍ', () {
      const card = UmSyncedCard(
        name: 'a',
        limitUptime: '1d',
        uptimeUsed: '1d 00:00:01',
      );
      expect(card.isExpired, isTrue);
    });

    test('الذي لم يستهلك حدّه مفعل', () {
      const card = UmSyncedCard(
        name: 'a',
        limitUptime: '1w',
        uptimeUsed: '2d 03:00:00',
      );
      expect(card.isExpired, isFalse);
      expect(card.isActive, isTrue);
    });

    test('بلا حد زمني ولا تعطيل يبقى مفعلاً', () {
      const card = UmSyncedCard(name: 'a');
      expect(card.isExpired, isFalse);
    });

    test('الحد الصفري لا يعتبر حد انتهاء', () {
      const card = UmSyncedCard(
        name: 'a',
        limitUptime: '0s',
        uptimeUsed: '0s',
      );
      expect(card.isExpired, isFalse);
    });
  });

  group('UmCardsSyncService.fetchCards', () {
    test('يقرأ كروت User Manager ويحولها للنموذج', () async {
      final talker = _FakeUmTalker(userRows: [
        {
          '.id': '*1',
          'name': '10000001',
          'password': 'pass1',
          'disabled': 'false',
          'profile': 'p1m',
          'limit-uptime': '1w',
          'uptime-used': '1d 02:00:00',
          'comment': 'batch-1',
        },
        {
          '.id': '*2',
          'name': '10000002',
          'password': 'pass2',
          'disabled': 'true',
          'limit-uptime': '1d',
          'uptime-used': '2d',
        },
      ]);

      final cards = await const UmCardsSyncService().fetchCards(talker);

      expect(cards, hasLength(2));
      // الترتيب: البروفايل الفارغ أولاً ثم p1m.
      expect(cards.map((c) => c.name).toList(), ['10000002', '10000001']);

      final byName = {for (final c in cards) c.name: c};
      final active = byName['10000001']!;
      final disabled = byName['10000002']!;

      expect(active.password, 'pass1');
      expect(active.profile, 'p1m');
      expect(active.limitUptime, '1w');
      expect(active.uptimeUsed, '1d 02:00:00');
      expect(active.comment, 'batch-1');
      expect(active.mikrotikId, '*1');
      expect(active.isExpired, isFalse);
      expect(disabled.isExpired, isTrue);

      // لا يصدر أي أمر هوتسبوت إطلاقاً.
      expect(
        talker.commands.any((c) => c.first.startsWith('/ip/hotspot')),
        isFalse,
      );
      expect(
        talker.commands.any((c) => c.first == '/tool/user-manager/user/print'),
        isTrue,
      );
    });

    test('يفضل actual-profile ثم profile ثم جدول الربط', () async {
      final talker = _FakeUmTalker(
        userRows: [
          {
            '.id': '*1',
            'name': 'u_actual',
            'actual-profile': 'gold',
            'profile': 'bronze',
          },
          {'.id': '*2', 'name': 'u_field'},
          {'.id': '*3', 'name': 'u_map'},
        ],
        associationRows: [
          {'user': 'u_map', 'profile': 'silver'},
          {'user': 'u_actual', 'profile': 'ignored'},
        ],
      );

      final cards = await const UmCardsSyncService().fetchCards(talker);
      final byName = {for (final c in cards) c.name: c};

      expect(byName['u_actual']!.profile, 'gold');
      expect(byName['u_field']!.profile, '');
      expect(byName['u_map']!.profile, 'silver');
    });

    test('فشل جدول الربط غير قاتل', () async {
      final talker = _FakeUmTalker(
        userRows: [
          {'.id': '*1', 'name': 'u1', 'actual-profile': 'p1'},
        ],
        failAssociation: true,
      );

      final cards = await const UmCardsSyncService().fetchCards(talker);

      expect(cards, hasLength(1));
      expect(cards.single.profile, 'p1');
    });

    test('يفشل بخطأ واضح عندما لا يتوفر User Manager', () async {
      final talker = _FakeUmTalker(failUserPrint: true);

      expect(
        () => const UmCardsSyncService().fetchCards(talker),
        throwsA(isA<UmCardsSyncException>().having(
          (error) => error.message,
          'message',
          contains('User Manager'),
        )),
      );
    });

    test('يرتب الكروت حسب البروفايل ثم الاسم', () async {
      final talker = _FakeUmTalker(userRows: [
        {'.id': '*1', 'name': 'b', 'profile': 'zeta'},
        {'.id': '*2', 'name': 'a', 'profile': 'zeta'},
        {'.id': '*3', 'name': 'c', 'profile': 'alpha'},
      ]);

      final cards = await const UmCardsSyncService().fetchCards(talker);

      expect(
        cards.map((c) => '${c.profile}/${c.name}').toList(),
        ['alpha/c', 'zeta/a', 'zeta/b'],
      );
    });
  });
}

class _FakeUmTalker implements RouterOsTalker {
  _FakeUmTalker({
    this.userRows = const [],
    this.associationRows = const [],
    this.failUserPrint = false,
    this.failAssociation = false,
  });

  final List<Map<String, String>> userRows;
  final List<Map<String, String>> associationRows;
  final bool failUserPrint;
  final bool failAssociation;
  final List<List<String>> commands = [];

  @override
  String get address => 'mock-router';

  @override
  Future<List<Map<String, String>>> talk(List<String> command) async {
    commands.add(command);
    final path = command.first;
    if (path == '/tool/user-manager/user/print') {
      if (failUserPrint) {
        throw const SocketException('no such command (user manager missing)');
      }
      return userRows;
    }
    if (path == '/tool/user-manager/user/profile/print' ||
        path == '/tool/user-manager/user-profile/print') {
      if (failAssociation) {
        throw const SocketException('no such menu');
      }
      return associationRows;
    }
    return const [];
  }
}
