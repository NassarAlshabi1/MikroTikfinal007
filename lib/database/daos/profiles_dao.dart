// ============================================================
//  ProfilesDao (Isar) — Data Access Object لجدول الملفات الشخصية
//
//  يحل محل قاعدة البيانات السابقة ProfilesDao القديم.
// ============================================================

import 'package:isar/isar.dart';

import '../isar/profile_collection.dart';
import '../isar/card_collection.dart';

class ProfilesDao {
  final Isar _isar;
  ProfilesDao(this._isar);

  // ============================================================
  //  CRUD
  // ============================================================

  Future<int> insertProfile(ProfileCollection profile) async {
    await _isar.writeTxn(() => _isar.profileCollections.put(profile));
    return profile.id;
  }

  Future<bool> updateProfile(ProfileCollection profile) async {
    await _isar.writeTxn(() => _isar.profileCollections.put(profile));
    return true;
  }

  Future<bool> deleteProfile(int id) async {
    return await _isar.writeTxn(() async {
      // Isar has no relational FK cascade. Delete dependent cards first so
      // no CardCollection keeps a dangling profileId.
      await _isar.cardCollections.filter().profileIdEqualTo(id).deleteAll();
      return _isar.profileCollections.delete(id);
    });
  }

  // ============================================================
  //  Queries
  // ============================================================

  Future<List<ProfileCollection>> getAllProfiles() async {
    return await _isar.profileCollections.where().sortByName().findAll();
  }

  Future<ProfileCollection?> getProfileById(int id) async {
    return await _isar.profileCollections.get(id);
  }

  Future<ProfileCollection?> getProfileByName(String name) async {
    return await _isar.profileCollections.where().nameEqualTo(name).findFirst();
  }

  /// Stream للملفات الشخصية
  Stream<List<ProfileCollection>> watchAllProfiles() {
    return _isar.profileCollections
        .where()
        .sortByName()
        .watch(fireImmediately: true);
  }

  /// مزامنة الملفات الشخصية من MikroTik (upsert)
  Future<void> syncProfiles(List<Map<String, dynamic>> mikrotikProfiles) async {
    await _isar.writeTxn(() async {
      // Sync is intentionally upsert-only. An empty/partial RouterOS response
      // must never be interpreted as a deletion command and must not orphan
      // locally cached cards. Explicit pruning is a separate operation.
      // إضافة/تحديث الملفات الجديدة
      for (final p in mikrotikProfiles) {
        final name = p['name']?.toString().trim() ?? '';
        if (name.isEmpty) continue;
        final existing = await _isar.profileCollections
            .where()
            .nameEqualTo(name)
            .findFirst();

        if (existing != null) {
          existing.mikrotikId = p['.id']?.toString();
          existing.rateLimit = p['rate-limit']?.toString();
          existing.sharedUsers =
              int.tryParse(p['shared-users']?.toString() ?? '') ?? 1;
          existing.lastSyncedAt = DateTime.now();
          await _isar.profileCollections.put(existing);
        } else {
          final newProfile = ProfileCollection.fromMikrotikData(p);
          await _isar.profileCollections.put(newProfile);
        }
      }
    });
  }
}
