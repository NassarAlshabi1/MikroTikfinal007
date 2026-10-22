import 'package:flutter_test/flutter_test.dart';
import 'package:mikronet/core/utils/functions.dart';

void main() {
  group('RouterOS User Manager character categories', () {
    test('numbers only generates ASCII digits', () {
      final values = generateUniqueRandomStrings(
        count: 100,
        length: 8,
        characterSets: const {'numbers'},
      );
      expect(values.toSet(), hasLength(100));
      expect(values.every((value) => RegExp(r'^[0-9]{8}$').hasMatch(value)), isTrue);
    });

    test('lowercase and uppercase can be selected together', () {
      final values = generateUniqueRandomStrings(
        count: 100,
        length: 10,
        characterSets: const {'lowercase', 'uppercase'},
      );
      expect(
        values.every((value) => RegExp(r'^[a-zA-Z]{10}$').hasMatch(value)),
        isTrue,
      );
    });

    test('all three official categories can be mixed', () {
      final values = generateUniqueRandomStrings(
        count: 100,
        length: 10,
        characterSets: const {'lowercase', 'uppercase', 'numbers'},
      );
      expect(
        values.every((value) => RegExp(r'^[a-zA-Z0-9]{10}$').hasMatch(value)),
        isTrue,
      );
    });

    test('unsupported or empty categories fail instead of silently using digits', () {
      expect(
        () => generateUniqueRandomStrings(
          count: 1,
          length: 5,
          characterSets: const {},
        ),
        throwsArgumentError,
      );
    });

    test('selected pattern pool generates only lowercase letters and digits', () {
      final values = generateUniqueRandomStrings(
        count: 100,
        length: 8,
        characterPool: 'abcdefghijklmnopqrstuvwxyz0123456789',
      );
      expect(values.toSet(), hasLength(100));
      expect(values.every((value) => RegExp(r'^[a-z0-9]{8}$').hasMatch(value)), isTrue);
    });

    test('uppercase-only pattern generates uppercase characters', () {
      final values = generateUniqueRandomStrings(
        count: 40,
        length: 6,
        characterPool: 'ABCDEFGHIJKLMNOPQRSTUVWXYZ',
      );
      expect(values.every((value) => RegExp(r'^[A-Z]{6}$').hasMatch(value)), isTrue);
    });

  });
}
