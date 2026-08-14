import 'package:isar/isar.dart';

import '../database/isar/profile_collection.dart';
import '../database/isar/card_collection.dart';
import '../database/isar_provider.dart';

/// يحفظ الكروت التي أُنشئت بنجاح في Isar بعد تأكيدها من الراوتر.
class CardPersistenceService {
  CardPersistenceService._();

  static Future<int> saveGeneratedCards({
    required String profileName,
    required List<Map<String, String>> users,
  }) async {
    if (profileName.trim().isEmpty || users.isEmpty) return 0;

    final isar = await IsarProvider().instance;
    return isar.writeTxn(() async {
      var profile = await isar.profileCollections
          .where()
          .nameEqualTo(profileName)
          .findFirst();

      profile ??= ProfileCollection.fromData(
        name: profileName,
        createdAt: DateTime.now(),
        lastSyncedAt: DateTime.now(),
      );
      profile.lastSyncedAt = DateTime.now();
      await isar.profileCollections.put(profile);

      var persistedCount = 0;
      for (final user in users) {
        final username = user['username']?.trim() ?? '';
        if (username.isEmpty) continue;

        final existing = await isar.cardCollections
            .where()
            .usernameEqualTo(username)
            .findFirst();
        final card = existing ??
            CardCollection.fromData(
              username: username,
              profileId: profile.id,
              createdAt: DateTime.now(),
            );
        card.password =
            (user['password'] ?? '').isEmpty ? null : user['password'];
        card.profileId = profile.id;
        card.status = 'active';
        card.sharedUsers = profile.sharedUsers;
        if (existing == null) {
          card.createdAt = DateTime.now();
        }
        await isar.cardCollections.put(card);
        persistedCount++;
      }
      return persistedCount;
    });
  }
}
