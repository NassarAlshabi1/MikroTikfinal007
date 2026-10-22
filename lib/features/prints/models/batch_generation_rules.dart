/// Validation rules for generated User Manager credentials.
class BatchGenerationRules {
  const BatchGenerationRules._();

  static const Set<String> supportedPatterns = {
    'lowercase', 'uppercase', 'mixedLetters', 'lowercaseNumbers',
    'uppercaseNumbers', 'mixedNumbers', 'numbers',
  };

  /// Returns a user-facing validation message, or null when valid.
  static String? credentialConfigurationError({
    required String usernamePattern,
    required bool templateHasPassword,
    required String passwordPattern,
    required bool passwordMatchesUsername,
    required String passwordLength,
  }) {
    if (!supportedPatterns.contains(usernamePattern)) {
      return 'اختر مجموعة أحرف واحدة على الأقل لاسم المستخدم';
    }

    if (!templateHasPassword || passwordMatchesUsername) return null;

    if (!supportedPatterns.contains(passwordPattern)) {
      return 'اختر مجموعة أحرف واحدة على الأقل لكلمة المرور';
    }

    final length = int.tryParse(passwordLength.trim());
    if (length == null || length < 1 || length > 32) {
      return 'طول كلمة المرور يجب أن يكون بين 1 و32';
    }
    return null;
  }
}
