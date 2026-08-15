import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mikrotik_manager/models/pdf_template.dart';
import 'package:mikrotik_manager/pdf_generator.dart';
import 'package:mikrotik_manager/services/pdf_template_storage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory temporaryDirectory;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    temporaryDirectory =
        await Directory.systemTemp.createTemp('mikrotik_pdf_template_');
  });

  tearDown(() async {
    if (temporaryDirectory.existsSync()) {
      await temporaryDirectory.delete(recursive: true);
    }
  });

  test('يقرأ القالب القديم ويطبق القيم الافتراضية مع تحقق كامل', () {
    final template = PdfTemplate.fromJson({
      'profileName': 'default',
      'imagePath': '/tmp/card.png',
      'cardsPerPage': 6,
      'imageWidth': 800,
      'imageHeight': 500,
    });

    expect(template.schemaVersion, 1);
    expect(template.textXRatio, 0.5);
    expect(template.markerWidthRatio, 0.3);
    expect(template.cardsPerPage, 6);
  });

  test('يرفض النسب وعدد الصفحات غير الصالحين', () {
    expect(
      () => PdfTemplate(
        profileName: 'default',
        imagePath: '/tmp/card.png',
        textXRatio: 1.2,
        textYRatio: 0.5,
        cardsPerPage: 1,
        imageWidth: 800,
        imageHeight: 500,
        markerWidthRatio: 0.3,
        markerHeightRatio: 0.1,
      ).validate(),
      throwsFormatException,
    );
    expect(
      () => PdfTemplate(
        profileName: 'default',
        imagePath: '/tmp/card.png',
        textXRatio: 0.5,
        textYRatio: 0.5,
        cardsPerPage: 0,
        imageWidth: 800,
        imageHeight: 500,
        markerWidthRatio: 0.3,
        markerHeightRatio: 0.1,
      ).validate(),
      throwsFormatException,
    );
  });

  test('ينظف JSON التالف ويستبدل قالب البروفايل بشكل ذري', () async {
    final image = File('${temporaryDirectory.path}/card.png')
      ..writeAsBytesSync([1, 2, 3]);
    final first = _template(image.path, cardsPerPage: 4);
    SharedPreferences.setMockInitialValues({
      PdfTemplateStorage.storageKey: [
        jsonEncode(first.toJson()),
        '{invalid-json',
      ],
    });

    final loaded = await PdfTemplateStorage.load();
    expect(loaded, hasLength(1));

    final second = _template(image.path, cardsPerPage: 8);
    await PdfTemplateStorage.save(second);
    final replaced = await PdfTemplateStorage.load();
    expect(replaced, hasLength(1));
    expect(replaced.single.cardsPerPage, 8);
  });

  test('يتوفر خط Tajawal داخل حزمة Flutter', () async {
    final fontData = await rootBundle.load('fonts/Tajawal-Regular.ttf');
    expect(fontData.lengthInBytes, greaterThan(1000));
  });

  test('يولد PDF صالحاً بخط عربي وبأكثر من صفحة', () async {
    final template = _template('assets/images/wifi_logo.png', cardsPerPage: 2);
    final bytes = await PdfGenerator.generatePdfBytes(
      cardUsernames: const ['كرت-001', 'كرت-002', 'كرت-003'],
      template: template,
    );

    expect(bytes.length, greaterThan(100));
    expect(utf8.decode(bytes.sublist(0, 4)), '%PDF');
  });

  test('يرفض إنشاء PDF عند عدم وجود كروت', () async {
    final template = _template('assets/images/wifi_logo.png');
    expect(
      () => PdfGenerator.generatePdfBytes(
        cardUsernames: const [],
        template: template,
      ),
      throwsFormatException,
    );
  });
}

PdfTemplate _template(String imagePath, {int cardsPerPage = 6}) {
  return PdfTemplate(
    profileName: 'default',
    imagePath: imagePath,
    textXRatio: 0.5,
    textYRatio: 0.5,
    cardsPerPage: cardsPerPage,
    imageWidth: 800,
    imageHeight: 500,
    markerWidthRatio: 0.3,
    markerHeightRatio: 0.1,
  )..validate();
}
