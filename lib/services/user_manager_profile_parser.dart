/// Utilities for normalizing User Manager profile rows returned by RouterOS v6.
///
/// The native RouterOS API client normally returns keys without the leading
/// `=`, but keeping the aliases here makes the UI tolerant of older wrappers
/// and mocked responses without changing the RouterOS command itself.
class UserManagerProfileParser {
  const UserManagerProfileParser._();

  static const nameKeys = <String>[
    'name',
    '=name',
    'profile',
    'profile-name',
    'profile_name',
  ];

  static List<Map<String, dynamic>> parse(
    Iterable<Map<String, dynamic>> rows,
  ) {
    final profiles = <Map<String, dynamic>>[];
    final seen = <String>{};

    for (final source in rows) {
      final profile = Map<String, dynamic>.from(source);
      final name = _readName(profile);
      if (name == null || !seen.add(name)) continue;
      profile['name'] = name;
      profiles.add(profile);
    }

    return List<Map<String, dynamic>>.unmodifiable(profiles);
  }

  static String? _readName(Map<String, dynamic> profile) {
    for (final key in nameKeys) {
      final value = profile[key]?.toString().trim();
      if (value != null && value.isNotEmpty) return value;
    }
    return null;
  }
}
