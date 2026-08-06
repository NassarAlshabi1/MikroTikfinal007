// ============================================================
//  ProfilesDao (Isar) — Data Access Object لجدول الملفات الشخصية
//
//  يحل محل Drift ProfilesDao القديم.
// ============================================================

import 'package:isar/isar.dart';

import '../isar/profile_collection.dart';

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
    return await _isar.writeTxn(() => _isar.profileCollections.delete(id));
  }

  // ============================================================
  //  Queries
  // ============================================================

  Future<List<ProfileCollection>> getAllProfiles() async {
    return await _isar.profileCollections
        .where()
        .sortByName()
        .findAll();
  }

  Future<ProfileCollection?> getProfileById(int id) async {
    return await _isar.profileCollections.get(id);
  }

  Future<ProfileCollection?> getProfileByName(String name) async {
    return await _isar.profileCollections
        .where()
        .nameEqualTo(name)
        .findFirst();
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
      // حذف الملفات غير الموجودة في القائمة الجديدة
      final existingNames = mikrotikProfiles.map((p) => p['name'] as String).toSet();
      final allExisting = await _isar.profileCollections.where().findAll();
      for (final profile in allExisting) {
        if (!existingNames.contains(profile.name)) {
          await _isar.profileCollections.delete(profile.id);
        }
      }

      // إضافة/تحديث الملفات الجديدة
      for (final p in mikrotikProfiles) {
        final name = p['name'] as String;
        final existing = await _isar.profileCollections
            .where()
            .nameEqualTo(name)
            .findFirst();

        if (existing != null) {
          existing.mikrotikId = p['.id'] as String?;
          existing.rateLimit = p['rate-limit'] as String?;
          existing.sharedUsers =
              int.tryParse(p['shared-users'] as String? ?? '1') ?? 1;
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
