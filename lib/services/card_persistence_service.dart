import 'package:isar/isar.dart';

import '../database/isar/profile_collection.dart';
import '../database/isar/card_collection.dart';
import '../database/isar_provider.dart';

/// نتيجة حجز أسماء الكروت قبل إرسالها إلى RouterOS.
class CardPreparationResult {
  final List<Map<String, String>> reservedUsers;
  final List<String> conflicts;

  const CardPreparationResult({
    required this.reservedUsers,
    required this.conflicts,
  });

  bool get canProceed => conflicts.isEmpty && reservedUsers.isNotEmpty;
}

/// يحافظ على دورة حياة الكروت المولدة محلياً:
/// pending قبل الإرسال، ثم active بعد تأكيد RouterOS.
class CardPersistenceService {
  CardPersistenceService._();

  /// يقرأ بروفايلات Hotspot المخزنة محلياً لاستخدامها أثناء انقطاع الراوتر.
  static Future<List<Map<String, dynamic>>> loadCachedProfiles() async {
    final isar = await IsarProvider().instance;
    final profiles =
        await isar.profileCollections.where().sortByName().findAll();
    return profiles
        .map((profile) => <String, dynamic>{
              'name': profile.name,
              'shared-users': profile.sharedUsers.toString(),
              'rate-limit': profile.rateLimit,
              '.id': profile.mikrotikId,
            })
        .toList();
  }

  /// يحذف حجوزات pending التي بقيت بعد إغلاق التطبيق أو انقطاعه.
  static Future<int> cleanupStalePendingCards({
    Duration olderThan = const Duration(hours: 2),
  }) async {
    final isar = await IsarProvider().instance;
    final cutoff = DateTime.now().subtract(olderThan);
    return isar.writeTxn(() async {
      final stale = await isar.cardCollections
          .filter()
          .statusEqualTo('pending')
          .createdAtLessThan(cutoff)
          .findAll();
      if (stale.isEmpty) return 0;
      return isar.cardCollections.deleteAll(
        stale.map((card) => card.id).toList(growable: false),
      );
    });
  }

  /// يحفظ أو يحدث بروفايلات Hotspot التي قرئت من RouterOS.
  static Future<int> cacheHotspotProfiles(
    List<Map<String, dynamic>> profiles,
  ) async {
    if (profiles.isEmpty) return 0;

    final isar = await IsarProvider().instance;
    return isar.writeTxn(() async {
      var count = 0;
      for (final raw in profiles) {
        final name = raw['name']?.toString().trim() ?? '';
        if (name.isEmpty) continue;

        final existing =
            await isar.profileCollections.where().nameEqualTo(name).findFirst();
        final profile = existing ??
            ProfileCollection.fromData(
              name: name,
              createdAt: DateTime.now(),
            );
        profile.mikrotikId = raw['.id']?.toString();
        profile.rateLimit = raw['rate-limit']?.toString();
        profile.sharedUsers = _parsePositiveInt(
          raw['shared-users'],
          fallback: profile.sharedUsers,
        );
        profile.lastSyncedAt = DateTime.now();
        await isar.profileCollections.put(profile);
        count++;
      }
      return count;
    });
  }

  /// يحجز الكروت محلياً قبل الاتصال بالراوتر.
  ///
  /// الحجز ذري: إذا وُجد اسم محلياً لا يتم إدخال أي جزء من الدفعة، حتى لا
  /// تصبح العملية نصف محجوزة. أسماء الكروت المحجوزة تحمل حالة `pending`.
  static Future<CardPreparationResult> prepareGeneratedCards({
    required String profileName,
    required List<Map<String, String>> users,
    int sharedUsers = 1,
    String? generationJobId,
  }) async {
    final normalized = _normalizeUsers(users);
    if (profileName.trim().isEmpty || normalized.isEmpty) {
      return const CardPreparationResult(reservedUsers: [], conflicts: []);
    }

    final isar = await IsarProvider().instance;
    return isar.writeTxn(() async {
      final profile = await _findOrCreateProfile(
        isar,
        profileName: profileName.trim(),
        sharedUsers: sharedUsers,
      );
      final existingCards = await isar.cardCollections
          .where()
          .anyOf(normalized.keys, (query, username) {
        return query.usernameEqualTo(username);
      }).findAll();
      final existingByUsername = {
        for (final card in existingCards) card.username: card,
      };
      final conflicts = existingByUsername.keys.toList(growable: false);
      if (conflicts.isNotEmpty) {
        return CardPreparationResult(
          reservedUsers: const [],
          conflicts: conflicts,
        );
      }

      final now = DateTime.now();
      final cards = normalized.values
          .map(
            (user) => CardCollection.fromData(
              username: user['username']!,
              password: _nullablePassword(user['password']),
              profileId: profile.id,
              sharedUsers: profile.sharedUsers,
              status: 'pending',
              createdAt: now,
              mikrotikUserId: _nullableString(user['mikrotikUserId']),
              generationJobId: _nullableString(generationJobId),
            ),
          )
          .toList(growable: false);
      await isar.cardCollections.putAll(cards);
      return CardPreparationResult(
        reservedUsers: normalized.values.toList(growable: false),
        conflicts: const [],
      );
    });
  }

  /// يثبت الكروت التي أكد RouterOS إضافتها.
  static Future<int> markGeneratedCardsActive({
    required String profileName,
    required List<Map<String, String>> users,
    String? generationJobId,
  }) async {
    final normalized = _normalizeUsers(users);
    if (profileName.trim().isEmpty || normalized.isEmpty) return 0;

    final isar = await IsarProvider().instance;
    return isar.writeTxn(() async {
      final existingCards = await isar.cardCollections
          .where()
          .anyOf(normalized.keys, (query, username) {
        return query.usernameEqualTo(username);
      }).findAll();
      final byUsername = {
        for (final card in existingCards) card.username: card,
      };
      final cardsToUpdate = <CardCollection>[];
      for (final user in normalized.values) {
        final card = byUsername[user['username']!];
        if (card == null ||
            (generationJobId != null &&
                card.generationJobId != generationJobId)) {
          continue;
        }
        card.password = _nullablePassword(user['password']);
        card.mikrotikUserId = _nullableString(user['mikrotikUserId']);
        card.status = 'active';
        card.lastUsedAt = DateTime.now();
        cardsToUpdate.add(card);
      }
      if (cardsToUpdate.isNotEmpty) {
        await isar.cardCollections.putAll(cardsToUpdate);
      }
      return cardsToUpdate.length;
    });
  }

  /// يقرأ الكروت pending الخاصة بعملية توليد محددة لاستئنافها.
  static Future<List<Map<String, String>>> loadPendingGeneratedCards(
    String generationJobId,
  ) async {
    if (generationJobId.trim().isEmpty) return const [];
    final isar = await IsarProvider().instance;
    final cards = await isar.cardCollections
        .filter()
        .generationJobIdEqualTo(generationJobId)
        .statusEqualTo('pending')
        .findAll();
    return cards
        .map((card) => <String, String>{
              'username': card.username,
              'password': card.password ?? '',
            })
        .toList(growable: false);
  }

  /// يحذف الحجوزات التي لم يؤكدها الراوتر بعد فشل جزئي أو إلغاء العملية.
  static Future<int> removePendingGeneratedCards(
    List<Map<String, String>> users, {
    String? generationJobId,
  }) async {
    final normalized = _normalizeUsers(users);
    if (normalized.isEmpty) return 0;

    final isar = await IsarProvider().instance;
    return isar.writeTxn(() async {
      final existingCards = await isar.cardCollections
          .where()
          .anyOf(normalized.keys, (query, username) {
        return query.usernameEqualTo(username);
      }).findAll();
      final ids = existingCards
          .where((card) =>
              card.status == 'pending' &&
              (generationJobId == null ||
                  card.generationJobId == generationJobId))
          .map((card) => card.id)
          .toList(growable: false);
      if (ids.isEmpty) return 0;
      return isar.cardCollections.deleteAll(ids);
    });
  }

  /// مسار توافق للاستخدامات القديمة: يحفظ الكروت مباشرة بحالة active.
  static Future<int> saveGeneratedCards({
    required String profileName,
    required List<Map<String, String>> users,
    int sharedUsers = 1,
    String? generationJobId,
  }) async {
    final preparation = await prepareGeneratedCards(
      profileName: profileName,
      users: users,
      sharedUsers: sharedUsers,
      generationJobId: generationJobId,
    );
    if (!preparation.canProceed) return 0;
    return markGeneratedCardsActive(
      profileName: profileName,
      users: preparation.reservedUsers,
      generationJobId: generationJobId,
    );
  }

  static Future<ProfileCollection> _findOrCreateProfile(
    Isar isar, {
    required String profileName,
    required int sharedUsers,
  }) async {
    final existing = await isar.profileCollections
        .where()
        .nameEqualTo(profileName)
        .findFirst();
    if (existing != null) return existing;

    final profile = ProfileCollection.fromData(
      name: profileName,
      sharedUsers: sharedUsers,
      createdAt: DateTime.now(),
      lastSyncedAt: DateTime.now(),
    );
    await isar.profileCollections.put(profile);
    return profile;
  }

  static Map<String, Map<String, String>> _normalizeUsers(
    List<Map<String, String>> users,
  ) {
    final normalized = <String, Map<String, String>>{};
    for (final user in users) {
      final username = user['username']?.trim() ?? '';
      if (username.isEmpty) continue;
      normalized.putIfAbsent(
        username,
        () => {
          'username': username,
          'password': user['password']?.trim() ?? '',
          if ((user['mikrotikUserId']?.trim() ?? '').isNotEmpty)
            'mikrotikUserId': user['mikrotikUserId']!.trim(),
        },
      );
    }
    return normalized;
  }

  static String? _nullablePassword(String? password) {
    final value = password?.trim() ?? '';
    return value.isEmpty ? null : value;
  }

  static String? _nullableString(String? value) {
    final normalized = value?.trim() ?? '';
    return normalized.isEmpty ? null : normalized;
  }

  static int _parsePositiveInt(Object? value, {required int fallback}) {
    final parsed = int.tryParse(value?.toString() ?? '');
    return parsed != null && parsed > 0 ? parsed : fallback;
  }
}
