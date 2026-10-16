import 'package:flutter_test/flutter_test.dart';
import 'package:mikronet/core/utils/functions.dart';

void main() {
  group('أنماط توليد أسماء الكروت (طريقة ABOTALAL)', () {
    test('ارقام فقط: كل الرموز أرقام', () {
      final cards = generateUniqueRandomStrings(count: 50, length: 8, type: "numbers");
      expect(cards.length, 50);
      expect(cards.toSet().length, 50, reason: "كل الكروت فريدة");
      expect(cards.every((c) => RegExp(r'^[0-9]+$').hasMatch(c)), isTrue);
    });

    test('احرف وارقام: أحرف كبيرة وأرقام بلا أحرف مشبهة (0/O/1/I)', () {
      final cards = generateUniqueRandomStrings(count: 50, length: 8, type: "mixed");
      expect(cards.every((c) => RegExp(r'^[23456789ABCDEFGHJKLMNPQRSTUVWXYZ]+$').hasMatch(c)), isTrue);
    });

    test('احرف صغيرة فقط و احرف كبيرة فقط', () {
      final lower = generateUniqueRandomStrings(count: 30, length: 7, type: "lower");
      final upper = generateUniqueRandomStrings(count: 30, length: 7, type: "upper");
      expect(lower.every((c) => RegExp(r'^[a-z]+$').hasMatch(c)), isTrue);
      expect(upper.every((c) => RegExp(r'^[A-Z]+$').hasMatch(c)), isTrue);
      expect(lower.every((c) => !c.contains('l')), isTrue, reason: "l مستبعدة لتشابهها مع 1");
      expect(upper.every((c) => !c.contains('O') && !c.contains('I')), isTrue);
    });

    test('البادئة واللاحقة تلحقان بالرمز', () {
      final cards = generateUniqueRandomStrings(
          count: 10, length: 5, type: "numbers", prefix: "A", suffix: "99");
      expect(cards.every((c) => c.startsWith("A") && c.endsWith("99")), isTrue);
    });

    test('سقف المحاولات يرمي خطأً بدل التعليق عند استنفاد التركيبات', () {
      expect(
        () => generateUniqueRandomStrings(count: 15, length: 1, type: "numbers",
            users: const []),
        throwsStateError,
      );
    });
  });
}
