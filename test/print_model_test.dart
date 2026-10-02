import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:mikronet/models/print_model.dart';

/// اختبارات **قراءة القوالب** — منطق نقي بلا قاعدة بيانات ولا اتصال.
///
/// سبب وجودها: كان صف واحد تالف في جدول `templates` (صورة غير Base64 أو صف
/// قديم بلا اسم) يُطلق استثناءً فيُفرغ قائمة القوالب بالكامل ⇒ «القالب لا يظهر»
/// في شاشة إنشاء الدفعة. هذه الاختبارات تمنع رجوع العطل.
void main() {
  group('فك ترميز صورة القالب (PrintTemplatesModel.decodeImage)', () {
    test('نص Base64 صحيح ← يُفكّ لبايتات مطابقة', () {
      final original = Uint8List.fromList([1, 2, 3, 4, 250, 251, 252]);
      final encoded = base64Encode(original);

      final decoded = PrintTemplatesModel.decodeImage(encoded);

      expect(decoded, equals(original));
    });

    test('بايتات خام (Uint8List) ← تُعاد كما هي (قوالب قديمة كـBLOB)', () {
      final raw = Uint8List.fromList([9, 8, 7]);
      expect(PrintTemplatesModel.decodeImage(raw), equals(raw));
    });

    test('قائمة أرقام (List<int>) ← تُحوَّل إلى Uint8List', () {
      expect(
        PrintTemplatesModel.decodeImage(<int>[5, 6, 7]),
        equals(Uint8List.fromList([5, 6, 7])),
      );
    });

    test('null ← صورة فارغة (لا انهيار)', () {
      expect(PrintTemplatesModel.decodeImage(null), isEmpty);
    });

    test('نص فارغ ← صورة فارغة', () {
      expect(PrintTemplatesModel.decodeImage('   '), isEmpty);
    });

    test('نص غير Base64 ← صورة فارغة بدل الاستثناء', () {
      expect(PrintTemplatesModel.decodeImage('هذا ليس Base64!!'), isEmpty);
    });

    test('Future (خطأ الحفظ القديم) ← صورة فارغة لا انهيار', () {
      expect(
        PrintTemplatesModel.decodeImage(Future.value(Uint8List(4))),
        isEmpty,
      );
    });

    test('كائن نصي غريب ← صورة فارغة', () {
      expect(PrintTemplatesModel.decodeImage('[1, 2, 3]'), isEmpty);
    });
  });

  group('مسار يصلح كقالب (isUsableRow)', () {
    test('اسم غير فارغ ← صالح', () {
      expect(PrintTemplatesModel.isUsableRow({'name': 'قالب الشتاء'}), isTrue);
    });

    test('اسم فارغ أو مسافات أو null ← غير صالح (يُستبعد)', () {
      expect(PrintTemplatesModel.isUsableRow({'name': ''}), isFalse);
      expect(PrintTemplatesModel.isUsableRow({'name': '   '}), isFalse);
      expect(PrintTemplatesModel.isUsableRow({'name': null}), isFalse);
      expect(PrintTemplatesModel.isUsableRow({}), isFalse);
    });
  });

  group('القراءة من قاعدة البيانات (fromDatabase)', () {
    test('صف كامل بقيم صحيحة', () {
      final image = base64Encode(Uint8List.fromList([10, 20, 30]));
      final model = PrintTemplatesModel.fromDatabase({
        'id': 7,
        'name': 'قالب الشتاء',
        'password': 1,
        'image': image,
        'rows': 18,
        'columns': 4,
        'username_fontsize': 14.0,
        'password_fontsize': 12.5,
        'username_location_x': 120.5,
        'username_location_y': 80.0,
        'password_location_x': 121.0,
        'password_location_y': 81.0,
      });

      expect(model.id, 7);
      expect(model.name, 'قالب الشتاء');
      expect(model.withPassword, isTrue);
      expect(model.image, equals(Uint8List.fromList([10, 20, 30])));
      expect(model.numOfRows, 18);
      expect(model.numOfColumns, 4);
      expect(model.usernameFontSize, 14.0);
      expect(model.passwordFontSize, 12.5);
      expect(model.usernameLocation.x, 120.5);
      expect(model.passwordLocation.y, 81.0);
    });

    test('صف كامل بصورة تالفة ← يُقرأ بنجاح بصورة فارغة (لا استثناء)', () {
      final model = PrintTemplatesModel.fromDatabase({
        'id': 1,
        'name': 'قالب قديم',
        'image': 'غير صالح',
      });

      expect(model.name, 'قالب قديم');
      expect(model.image, isEmpty);
      expect(model.withPassword, isFalse);
    });

    test('قيم ناقصة ← قيم افتراضية معقولة بلا انهيار', () {
      final model = PrintTemplatesModel.fromDatabase({'name': 'قالب بسيط'});

      expect(model.id, 0);
      expect(model.image, isEmpty);
      expect(model.numOfRows, 18);
      expect(model.numOfColumns, 4);
      expect(model.usernameFontSize, 14);
      expect(model.usernameLocation.x, 100);
      expect(model.passwordLocation.y, 101);
    });

    test('أرقام مخزّنة كنصوص (SQLite TEXT) تُقرأ صحيحة', () {
      final model = PrintTemplatesModel.fromDatabase({
        'id': '12',
        'name': 'قالب',
        'password': '1',
        'rows': '9',
        'columns': '3',
        'username_fontsize': '11.5',
      });

      expect(model.id, 12);
      expect(model.withPassword, isTrue);
      expect(model.numOfRows, 9);
      expect(model.numOfColumns, 3);
      expect(model.usernameFontSize, 11.5);
    });

    test('صورة بصيغة BLOB قديمة تُقرأ كما هي', () {
      final blob = Uint8List.fromList([255, 216, 255, 224]);
      final model = PrintTemplatesModel.fromDatabase({
        'id': 3,
        'name': 'قالب قديم BLOB',
        'image': blob,
      });

      expect(model.image, equals(blob));
    });
  });

  group('الحفظ (toDatabase)', () {
    test('الصورة تُشفَّر Base64 وتعود كما هي عند القراءة (دورة كاملة)', () {
      final model = PrintTemplatesModel(
        id: 5,
        name: 'قالب دورة',
        image: Uint8List.fromList([1, 2, 3, 4, 5]),
        withPassword: true,
        numOfRows: 10,
        numOfColumns: 2,
        usernameFontSize: 12,
        passwordFontSize: 13,
        usernameLocation: LocationData(x: 10, y: 20),
        passwordLocation: LocationData(x: 11, y: 21),
      );

      final row = model.toDatabase();
      expect(row['name'], 'قالب دورة');
      expect(row['password'], 1);
      expect(row['image'], isA<String>());

      final restored = PrintTemplatesModel.fromDatabase({'id': 5, ...row});
      expect(restored.image, equals(model.image));
      expect(restored.withPassword, isTrue);
      expect(restored.numOfRows, 10);
    });
  });
}
