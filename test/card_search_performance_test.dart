import 'package:flutter_test/flutter_test.dart';
import 'package:mikrotik_manager/mikrotik_card_repository.dart';

void main() {
  final cards = List<MikrotikCard>.generate(
    10000,
    (index) => MikrotikCard(
      id: '*${index + 1}',
      username: 'CARD-${index.toString().padLeft(5, '0')}',
      profile: index.isEven ? 'daily-1GB' : 'monthly-20GB',
      isDisabled: index % 17 == 0,
      comment: 'branch-${index % 12} voucher $index',
      source: MikrotikCardSource.hotspot,
    ),
    growable: false,
  );

  test('local card search returns correct results', () {
    final byName = MikrotikCardRepository.filterCards(
      cards: cards,
      query: 'CARD-09999',
    );
    final byProfile = MikrotikCardRepository.filterCards(
      cards: cards,
      query: 'monthly-20GB',
    );
    final byComment = MikrotikCardRepository.filterCards(
      cards: cards,
      query: 'branch-7',
    );

    expect(byName, hasLength(1));
    expect(byName.single.username, 'CARD-09999');
    expect(byProfile, hasLength(5000));
    expect(byComment, hasLength(833));
  });

  test('local card search remains responsive for repeated queries', () {
    const queries = <String>[
      'CARD-00001',
      'CARD-04500',
      'CARD-09999',
      'daily-1GB',
      'monthly-20GB',
      'branch-0',
      'branch-11',
      'voucher 9000',
    ];

    final stopwatch = Stopwatch()..start();
    var matchedCards = 0;
    for (var iteration = 0; iteration < 25; iteration++) {
      for (final query in queries) {
        matchedCards += MikrotikCardRepository.filterCards(
          cards: cards,
          query: query,
        ).length;
      }
    }
    stopwatch.stop();

    expect(matchedCards, greaterThan(0));
    expect(
      stopwatch.elapsed,
      lessThan(const Duration(seconds: 2)),
      reason: 'يجب أن تبقى فلترة 10,000 كرت سريعة داخل الجهاز.',
    );
    // ignore: avoid_print
    print(
      'Card search benchmark: 200 queries over 10,000 cards in '
      '${stopwatch.elapsedMilliseconds} ms.',
    );
  });
}
