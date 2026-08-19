import 'package:flutter_test/flutter_test.dart';
import 'package:mikrotik_manager/mikrotik_card_repository.dart';

void main() {
  group('MikrotikCardSource', () {
    test('exposes labels and RouterOS commands for both sources', () {
      expect(MikrotikCardSource.userManager.label, 'مدير المستخدمين');
      expect(
        MikrotikCardSource.userManager.command,
        '/tool/user-manager/user/print',
      );
      expect(MikrotikCardSource.hotspot.label, 'Hotspot');
      expect(MikrotikCardSource.hotspot.command, '/ip/hotspot/user/print');
    });
  });

  group('MikrotikCard.fromRouterResponse', () {
    test('normalizes a User Manager response and derives active state', () {
      final card = MikrotikCard.fromRouterResponse(
        {
          '.id': '*11',
          'username': '  Noor  ',
          'actual-profile': '  1-hour  ',
          'disabled': 'FALSE',
          'comment': '  Family account  ',
        },
        MikrotikCardSource.userManager,
      );

      expect(card.id, '*11');
      expect(card.username, 'Noor');
      expect(card.profile, '1-hour');
      expect(card.comment, 'Family account');
      expect(card.isDisabled, isFalse);
      expect(card.statusLabel, 'نشط');
      expect(card.normalizedSearchText, 'noor 1-hour family account');
    });

    test('maps a Hotspot response and applies safe defaults', () {
      final card = MikrotikCard.fromRouterResponse(
        {
          '.id': 8,
          'name': '  Guest-10 ',
          'profile': '   ',
          'disabled': true,
        },
        MikrotikCardSource.hotspot,
      );

      expect(card.id, '8');
      expect(card.username, 'Guest-10');
      expect(card.profile, 'غير محدد');
      expect(card.comment, isEmpty);
      expect(card.isDisabled, isTrue);
      expect(card.statusLabel, 'معطّل');
    });

    test('handles omitted optional RouterOS fields without throwing', () {
      final card = MikrotikCard.fromRouterResponse(
        const {},
        MikrotikCardSource.userManager,
      );

      expect(card.id, isEmpty);
      expect(card.username, isEmpty);
      expect(card.profile, 'غير محدد');
      expect(card.comment, isEmpty);
      expect(card.isDisabled, isFalse);
    });
  });

  group('MikrotikCardRepository.filterCards', () {
    final cards = <MikrotikCard>[
      MikrotikCard(
        id: '*1',
        username: 'Nour',
        profile: 'Daily',
        isDisabled: false,
        comment: 'Reception',
        source: MikrotikCardSource.hotspot,
      ),
      MikrotikCard(
        id: '*2',
        username: 'Salem',
        profile: 'Weekly',
        isDisabled: true,
        comment: 'Office',
        source: MikrotikCardSource.userManager,
      ),
      MikrotikCard(
        id: '*3',
        username: 'Guest-77',
        profile: 'Daily',
        isDisabled: false,
        comment: 'Walk in',
        source: MikrotikCardSource.hotspot,
      ),
    ];

    test('returns an unmodifiable full list for an empty query', () {
      final result = MikrotikCardRepository.filterCards(
        cards: cards,
        query: '  ',
      );

      expect(result, hasLength(3));
      expect(
        () => result.add(cards.first),
        throwsUnsupportedError,
      );
    });

    test('searches username, profile, and comment case-insensitively', () {
      expect(
        MikrotikCardRepository.filterCards(cards: cards, query: 'NOUR'),
        [cards[0]],
      );
      expect(
        MikrotikCardRepository.filterCards(cards: cards, query: 'daily'),
        [cards[0], cards[2]],
      );
      expect(
        MikrotikCardRepository.filterCards(cards: cards, query: 'OFFICE'),
        [cards[1]],
      );
    });

    test('returns no cards when the local query has no match', () {
      final result = MikrotikCardRepository.filterCards(
        cards: cards,
        query: 'does-not-exist',
      );

      expect(result, isEmpty);
    });
  });

  test('repository cache operations are safe before any synchronization', () {
    final repository = MikrotikCardRepository.instance;
    repository.clearCache();

    expect(
      repository.searchLocal(
        source: MikrotikCardSource.userManager,
        query: 'anything',
      ),
      isEmpty,
    );

    repository.clearCache(MikrotikCardSource.hotspot);
    repository.clearCache();
  });

  test('operation exception exposes the actionable message', () {
    const exception = MikrotikCardOperationException('فشل اختبار المزامنة');

    expect(exception.message, 'فشل اختبار المزامنة');
    expect(exception.toString(), 'فشل اختبار المزامنة');
    expect(exception.cause, isNull);
  });
}
