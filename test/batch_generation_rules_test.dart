import 'package:flutter_test/flutter_test.dart';
import 'package:mikronet/features/prints/models/batch_generation_rules.dart';

void main() {
  group('BatchGenerationRules.credentialConfigurationError', () {
    test('requires a supported username pattern', () {
      expect(
        BatchGenerationRules.credentialConfigurationError(
          usernamePattern: 'invalid',
          templateHasPassword: false,
          passwordPattern: 'invalid',
          passwordMatchesUsername: false,
          passwordLength: '',
        ),
        isNotNull,
      );
      expect(
        BatchGenerationRules.credentialConfigurationError(
          usernamePattern: 'mixedNumbers',
          templateHasPassword: false,
          passwordPattern: 'invalid',
          passwordMatchesUsername: false,
          passwordLength: '',
        ),
        isNull,
      );
    });

    test('validates password pattern and length independently', () {
      for (final length in ['', '0', '33', 'abc']) {
        expect(
          BatchGenerationRules.credentialConfigurationError(
            usernamePattern: 'numbers',
            templateHasPassword: true,
            passwordPattern: 'mixedNumbers',
            passwordMatchesUsername: false,
            passwordLength: length,
          ),
          isNotNull,
        );
      }
      expect(
        BatchGenerationRules.credentialConfigurationError(
          usernamePattern: 'lowercase',
          templateHasPassword: true,
          passwordPattern: 'uppercaseNumbers',
          passwordMatchesUsername: false,
          passwordLength: '6',
        ),
        isNull,
      );
    });

    test('matching username password needs no separate pattern or length', () {
      expect(
        BatchGenerationRules.credentialConfigurationError(
          usernamePattern: 'numbers',
          templateHasPassword: true,
          passwordPattern: 'invalid',
          passwordMatchesUsername: true,
          passwordLength: '',
        ),
        isNull,
      );
    });

    test('templates without password fields do not require password settings', () {
      expect(
        BatchGenerationRules.credentialConfigurationError(
          usernamePattern: 'uppercase',
          templateHasPassword: false,
          passwordPattern: 'invalid',
          passwordMatchesUsername: false,
          passwordLength: '',
        ),
        isNull,
      );
    });
  });
}
