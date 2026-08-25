import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';
import 'package:mikrotik_manager/database/daos/profiles_dao.dart';
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
        await Directory.systemTemp.createTemp('mikrotik_isar_regression_');
    final isar = await Isar.open(
      [CardCollectionSchema, ProfileCollectionSchema],
      directory: databaseDirectory.path,
      name: 'regression_test',
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

  test('RouterOS profile parsing accepts dynamic values and durations', () {
    final profile = ProfileCollection.fromMikrotikData({
      'name': 'premium',
      '.id': '*1',
      'shared-users': 3,
      'rate-limit': '5M/5M',
      'uptime-used': '1d2h30m',
      'uptime-limit': '7d',
    });

    expect(profile.name, 'premium');
    expect(profile.sharedUsers, 3);
    expect(profile.uptimeUsedSeconds, 95_400);
    expect(profile.uptimeLimitSeconds, 604_800);
    expect(profile.lastSyncedAt, isNotNull);
  });

  test('explicit profile deletion cascades to dependent cards', () async {
    final isar = await IsarProvider().instance;
    final profile = ProfileCollection.fromData(
      name: 'to-delete',
      createdAt: DateTime.now(),
    );
    await isar.writeTxn(() async {
      await isar.profileCollections.put(profile);
      await isar.cardCollections.put(
        CardCollection.fromData(
          username: 'dependent-card',
          profileId: profile.id,
          createdAt: DateTime.now(),
        ),
      );
    });

    final deleted = await ProfilesDao(isar).deleteProfile(profile.id);

    expect(deleted, isTrue);
    expect(await isar.profileCollections.get(profile.id), isNull);
    expect(
      await isar.cardCollections
          .where()
          .usernameEqualTo('dependent-card')
          .findFirst(),
      isNull,
    );
  });

  test('activating generated cards does not fabricate lastUsedAt', () async {
    final isar = await IsarProvider().instance;
    final preparation = await CardPersistenceService.prepareGeneratedCards(
      profileName: 'default',
      users: [
        {'username': 'usage-test', 'password': 'p1'},
      ],
    );
    expect(preparation.canProceed, isTrue);

    final beforeActivation = await isar.cardCollections
        .where()
        .usernameEqualTo('usage-test')
        .findFirst();
    expect(beforeActivation?.lastUsedAt, isNull);

    await CardPersistenceService.markGeneratedCardsActive(
      profileName: 'default',
      users: [
        {'username': 'usage-test', 'password': 'p1'},
      ],
    );

    final afterActivation = await isar.cardCollections
        .where()
        .usernameEqualTo('usage-test')
        .findFirst();
    expect(afterActivation?.status, 'active');
    expect(afterActivation?.lastUsedAt, isNull);
  });

  test('profile sync is upsert-only and preserves local profiles', () async {
    final isar = await IsarProvider().instance;
    final local = ProfileCollection.fromData(
      name: 'local-only',
      createdAt: DateTime.now(),
    );
    await isar.writeTxn(() async {
      await isar.profileCollections.put(local);
    });

    await ProfilesDao(isar).syncProfiles([
      {
        'name': 'router-profile',
        '.id': '*2',
        'shared-users': '2',
        'rate-limit': '1M/1M',
      },
    ]);

    expect(
      await isar.profileCollections
          .where()
          .nameEqualTo('local-only')
          .findFirst(),
      isNotNull,
    );
    expect(
      await isar.profileCollections
          .where()
          .nameEqualTo('router-profile')
          .findFirst(),
      isNotNull,
    );
  });
}
