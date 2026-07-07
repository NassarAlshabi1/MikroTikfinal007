// ============================================================
//  ProfilesDao — Data Access Object لجدول الملفات الشخصية
// ============================================================

import 'package:drift/drift.dart';
import '../app_database.dart';

part 'profiles_dao.g.dart';

@DriftAccessor(tables: [Profiles])
class ProfilesDao extends DatabaseAccessor<AppDatabase> with _$ProfilesDaoMixin {
  ProfilesDao(super.db);

  // ============================================================
  //  CRUD
  // ============================================================

  Future<int> insertProfile(ProfilesCompanion profile) =>
      into(profiles).insert(profile);

  Future<bool> updateProfile(Profile profile) =>
      update(profiles).replace(profile);

  Future<int> deleteProfile(int id) =>
      (delete(profiles)..where((p) => p.id.equals(id))).go();

  // ============================================================
  //  Queries
  // ============================================================

  Future<List<Profile>> getAllProfiles() =>
      (select(profiles)..orderBy((p) => OrderingTerm.asc(p.name))).get();

  Future<Profile?> getProfileById(int id) =>
      (select(profiles)..where((p) => p.id.equals(id)))
          .getSingleOrNull();

  Future<Profile?> getProfileByName(String name) =>
      (select(profiles)..where((p) => p.name.equals(name)))
          .getSingleOrNull();

  /// Stream للملفات الشخصية (للـ reactive UI)
  Stream<List<Profile>> watchAllProfiles() =>
      (select(profiles)..orderBy((p) => OrderingTerm.asc(p.name)))
          .watch();

  /// مزامنة الملفات الشخصية من MikroTik (upsert)
  Future<void> syncProfiles(List<Map<String, dynamic>> mikrotikProfiles) async {
    await batch((b) => b.replaceAll(profiles, [
          for (final p in mikrotikProfiles)
            ProfilesCompanion.insert(
              name: p['name'] as String,
              mikrotikId: Value(p['.id'] as String?),
              rateLimit: Value(p['rate-limit'] as String?),
              sharedUsers: Value(
                  int.tryParse(p['shared-users'] as String? ?? '1') ?? 1),
              createdAt: DateTime.now(),
            ),
        ]));
  }
}
