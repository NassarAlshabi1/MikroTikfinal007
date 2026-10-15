import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// تحميل خط Cairo الحقيقي داخل الاختبارات لعرض العربية في المعاينات.
Future<void> loadCairoFonts() async {
  final loader = FontLoader('Cairo')
    ..addFont(rootBundle.load('fonts/cairo/Cairo_400Regular.ttf'));
  await loader.load();
}
