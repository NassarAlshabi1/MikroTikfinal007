import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';
import 'package:mikrotik_manager/database/isar/card_collection.dart';
import 'package:mikrotik_manager/database/isar/profile_collection.dart';
import 'package:mikrotik_manager/database/isar_provider.dart';
import 'package:mikrotik_manager/services/card_persistence_service.dart';

void main() {
  late Directory databaseDirectory;

  setUpAll(() async {
    await Isar.initializeIsarCore(download: true);
  });

  setUp(() async {
    databaseDirectory =
        await Directory.systemTemp.createTemp('mikrotik_bulk_isar_');
    final isar = await Isar.open(
      [CardCollectionSchema, ProfileCollectionSchema],
      directory: databaseDirectory.path,
      name: 'bulk_test',
      inspector: false,
    );
    IsarProvider().setTestInstance(isar);
  });

  tearDown(() async {
    await IsarProvider().close();
    if (databaseDirectory.existsSync()) {
      await databaseDirectory.delete(recursive: true);
    }
  });

  test('يحجز الدفعة pending ثم يثبتها active بعد نجاح RouterOS', () async {
    final users = [
      {'username': 'card001', 'password': ''},
      {'username': 'card002', 'password': 'pass002'},
    ];

    final preparation = await CardPersistenceService.prepareGeneratedCards(
      profileName: 'default',
      users: users,
      sharedUsers: 2,
    );

    expect(preparation.canProceed, isTrue);
    expect(preparation.reservedUsers, hasLength(2));

    final isar = await IsarProvider().instance;
    final pending =
        await isar.cardCollections.filter().statusEqualTo('pending').findAll();
    expect(pending, hasLength(2));
    expect(pending.first.sharedUsers, 2);

    final activated = await CardPersistenceService.markGeneratedCardsActive(
      profileName: 'default',
      users: users,
    );

    expect(activated, 2);
    final active =
        await isar.cardCollections.filter().statusEqualTo('active').findAll();
    expect(active, hasLength(2));
    expect(active.map((card) => card.password), containsAll([null, 'pass002']));
  });

  test('يرفض الاسم المكرر محلياً دون إدخال دفعة ثانية', () async {
    final user = [
      {'username': 'duplicate01', 'password': 'secret'},
    ];

    final first = await CardPersistenceService.prepareGeneratedCards(
      profileName: 'default',
      users: user,
    );
    final second = await CardPersistenceService.prepareGeneratedCards(
      profileName: 'default',
      users: user,
    );

    expect(first.canProceed, isTrue);
    expect(second.canProceed, isFalse);
    expect(second.conflicts, contains('duplicate01'));

    final isar = await IsarProvider().instance;
    expect(await isar.cardCollections.count(), 1);
  });

  test('ينظف pending ويحتفظ بالكرت المؤكد عند الفشل الجزئي', () async {
    final users = [
      {'username': 'partial01', 'password': 'p1'},
      {'username': 'partial02', 'password': 'p2'},
      {'username': 'partial03', 'password': 'p3'},
    ];

    final preparation = await CardPersistenceService.prepareGeneratedCards(
      profileName: 'default',
      users: users,
    );
    expect(preparation.canProceed, isTrue);

    final confirmed = [users.first];
    await CardPersistenceService.markGeneratedCardsActive(
      profileName: 'default',
      users: confirmed,
    );
    await CardPersistenceService.removePendingGeneratedCards(
        users.skip(1).toList());

    final isar = await IsarProvider().instance;
    final cards = await isar.cardCollections.where().findAll();
    expect(cards, hasLength(1));
    expect(cards.single.username, 'partial01');
    expect(cards.single.status, 'active');
  });
}
