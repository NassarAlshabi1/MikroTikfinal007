import 'package:flutter_test/flutter_test.dart';
import 'package:mikronet/controllers/helpers/functions.dart';

void main() {
  group('خيارات توليد أسماء الكروت', () {
    test('يولد أرقاماً فقط مع البادئة واللاحقة', () {
      final values = generateUniqueRandomStrings(
        count: 40,
        length: 6,
        prefix: 'A-',
        suffix: '-X',
        type: 'numbers',
      );

      expect(values, hasLength(40));
      expect(values.toSet(), hasLength(40));
      for (final value in values) {
        expect(value, matches(RegExp(r'^A-[0-9]{6}-X$')));
      }
    });

    test('يدعم الحروف فقط', () {
      final values = generateUniqueRandomStrings(count: 30, length: 8, type: 'letters');

      expect(values, hasLength(30));
      expect(values.every((value) => RegExp(r'^[A-Za-z]{8}$').hasMatch(value)), isTrue);
    });

    test('يدعم الخليط بين الحروف والأرقام', () {
      final values = generateUniqueRandomStrings(count: 30, length: 8, type: 'mixed');

      expect(values, hasLength(30));
      expect(values.every((value) => RegExp(r'^[A-Za-z0-9]{8}$').hasMatch(value)), isTrue);
    });

    test('العدد صفر يعيد قائمة فارغة بدون دوران', () {
      expect(generateUniqueRandomStrings(count: 0), isEmpty);
    });
  });
}
