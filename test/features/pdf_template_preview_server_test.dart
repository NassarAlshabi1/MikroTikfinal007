import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:mikrotik_manager/models/pdf_template.dart';
import 'package:mikrotik_manager/services/pdf_template_preview_server.dart';

void main() {
  final server = PdfTemplatePreviewServer.instance;

  tearDown(() async {
    await server.stop();
  });

  test('يستضيف HTML والخلفية محلياً ويعرض الأرقام ASCII', () async {
    final template = PdfTemplate(
      profileName: 'default',
      imagePath: 'assets/images/wifi_logo.png',
      textXRatio: 0.5,
      textYRatio: 0.5,
      cardsPerPage: 4,
      imageWidth: 800,
      imageHeight: 500,
      markerWidthRatio: 0.3,
      markerHeightRatio: 0.1,
    )..validate();

    final uri = await server.start(
      template: template,
      sampleCards: const ['١٢٣٤', '5678'],
    );
    final client = HttpClient();
    try {
      final htmlRequest = await client.getUrl(uri);
      final htmlResponse = await htmlRequest.close();
      final html = await htmlResponse.transform(utf8.decoder).join();
      expect(htmlResponse.statusCode, HttpStatus.ok);

      expect(html, contains('1234'));
      expect(html, contains('5678'));
      expect(html, contains('/background'));
      expect(html, contains('direction:ltr'));

      final backgroundUri = uri.replace(path: '/background');
      final imageRequest = await client.getUrl(backgroundUri);
      final imageResponse = await imageRequest.close();
      final image = await imageResponse
          .fold<List<int>>(<int>[], (bytes, chunk) => bytes..addAll(chunk));
      expect(imageResponse.statusCode, HttpStatus.ok);
      expect(image.length, greaterThan(20));
    } finally {
      client.close(force: true);
    }
  });
}
