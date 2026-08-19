import 'package:flutter_test/flutter_test.dart';
import 'package:mikrotik_manager/pdf_templates_screen.dart';

void main() {
  group('PdfTemplate serialization', () {
    test('serializes every template property to JSON', () {
      final template = PdfTemplate(
        profileName: 'خمس ساعات',
        imagePath: '/tmp/card.png',
        textXRatio: 0.25,
        textYRatio: 0.75,
        cardsPerPage: 6,
        imageWidth: 1200,
        imageHeight: 800,
        markerWidthRatio: 0.4,
        markerHeightRatio: 0.15,
      );

      expect(template.toJson(), {
        'schemaVersion': PdfTemplate.currentSchemaVersion,
        'id': template.id,
        'profileName': 'خمس ساعات',
        'imagePath': '/tmp/card.png',
        'textXRatio': 0.25,
        'textYRatio': 0.75,
        'cardsPerPage': 6,
        'imageWidth': 1200.0,
        'imageHeight': 800.0,
        'markerWidthRatio': 0.4,
        'markerHeightRatio': 0.15,
      });
    });

    test('restores numeric JSON values as doubles', () {
      final template = PdfTemplate.fromJson({
        'profileName': 'Daily',
        'imagePath': '/assets/daily.png',
        'textXRatio': 1,
        'textYRatio': 0.2,
        'cardsPerPage': 9,
        'imageWidth': 1000,
        'imageHeight': 600,
        'markerWidthRatio': 0.33,
        'markerHeightRatio': 1,
      });

      expect(template.profileName, 'Daily');
      expect(template.imagePath, '/assets/daily.png');
      expect(template.textXRatio, 1.0);
      expect(template.textYRatio, 0.2);
      expect(template.cardsPerPage, 9);
      expect(template.imageWidth, 1000.0);
      expect(template.imageHeight, 600.0);
      expect(template.markerWidthRatio, 0.33);
      expect(template.markerHeightRatio, 1.0);
    });

    test('uses stable placement defaults for older template JSON', () {
      final template = PdfTemplate.fromJson({
        'profileName': 'Legacy',
        'imagePath': '/assets/legacy.png',
        'cardsPerPage': 3,
      });

      expect(template.textXRatio, 0.5);
      expect(template.textYRatio, 0.5);
      expect(template.imageWidth, 1.0);
      expect(template.imageHeight, 1.0);
      expect(template.markerWidthRatio, 0.3);
      expect(template.markerHeightRatio, 0.1);
    });

    test('preserves values through a JSON round trip', () {
      final original = PdfTemplate(
        profileName: 'Office',
        imagePath: '/images/office.png',
        textXRatio: 0.6,
        textYRatio: 0.4,
        cardsPerPage: 12,
        imageWidth: 1920,
        imageHeight: 1080,
        markerWidthRatio: 0.22,
        markerHeightRatio: 0.11,
      );
      final restored = PdfTemplate.fromJson(original.toJson());

      expect(restored.toJson(), original.toJson());
    });
  });
}
