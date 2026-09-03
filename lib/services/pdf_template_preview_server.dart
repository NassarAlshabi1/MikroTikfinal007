import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:path/path.dart' as p;

import '../models/pdf_template.dart';
import 'card_number_policy.dart';

class PdfTemplatePreviewServer {
  PdfTemplatePreviewServer._();

  static final PdfTemplatePreviewServer instance = PdfTemplatePreviewServer._();

  HttpServer? _server;
  PdfTemplate? _template;
  String? _imagePath;
  List<String> _sampleCards = const [];

  bool get isRunning => _server != null;
  int? get port => _server?.port;

  Future<Uri> start({
    required PdfTemplate template,
    List<String> sampleCards = const [],
  }) async {
    template.validate();
    final image = File(template.imagePath);
    if (!await image.exists()) {
      throw const FileSystemException('صورة قالب PDF غير موجودة.');
    }

    await stop();
    final server = await HttpServer.bind(
      InternetAddress.loopbackIPv4,
      0,
      shared: false,
    );
    _server = server;
    _template = template;
    _imagePath = image.absolute.path;
    _sampleCards = _normalizeSampleCards(sampleCards);
    unawaited(server.forEach(_handleRequest));

    return Uri.parse(
      'http://127.0.0.1:${server.port}/preview?v=${DateTime.now().millisecondsSinceEpoch}',
    );
  }

  Future<void> stop() async {
    final server = _server;
    _server = null;
    _template = null;
    _imagePath = null;
    _sampleCards = const [];
    await server?.close(force: true);
  }

  Future<void> _handleRequest(HttpRequest request) async {
    final response = request.response;
    response.headers.set('cache-control', 'no-store');
    response.headers.set('x-content-type-options', 'nosniff');

    try {
      switch (request.uri.path) {
        case '/preview':
        case '/':
          response.headers.contentType = ContentType.html;
          response.write(_buildHtml());
          break;
        case '/background':
          await _writeBackground(response);
          return;
        case '/health':
          response.headers.contentType = ContentType.json;
          response.write(jsonEncode({'status': 'ok'}));
          break;
        default:
          response.statusCode = HttpStatus.notFound;
          response.write('Not found');
      }
    } catch (error) {
      response.statusCode = HttpStatus.internalServerError;
      response.headers.contentType = ContentType.text;
      response.write('Preview error: ${_escapeHtml(error.toString())}');
    } finally {
      await response.close();
    }
  }

  Future<void> _writeBackground(HttpResponse response) async {
    final path = _imagePath;
    if (path == null || !await File(path).exists()) {
      response.statusCode = HttpStatus.notFound;
      await response.close();
      return;
    }
    final extension = p.extension(path).toLowerCase();
    final contentType = switch (extension) {
      '.jpg' || '.jpeg' => ContentType('image', 'jpeg'),
      '.webp' => ContentType('image', 'webp'),
      _ => ContentType('image', 'png'),
    };
    response.headers.contentType = contentType;
    await response.addStream(File(path).openRead());
    await response.close();
  }

  String _buildHtml() {
    final template = _template;
    if (template == null) {
      return '<!doctype html><html lang="ar" dir="rtl"><body>لا توجد معاينة نشطة.</body></html>';
    }

    final columns = template.cardsPerPage < 3 ? template.cardsPerPage : 3;
    final previewCount = math.min(template.cardsPerPage, 12);
    final cards = List<String>.generate(
      previewCount,
      (index) => index < _sampleCards.length
          ? _sampleCards[index]
          : CardNumberPolicy.toAsciiDigits(
              (10000001 + index).toString(),
            ),
    );
    final cardMarkup = cards.map((card) {
      return '''<div class="card" style="background-image:url('/background?v=${DateTime.now().millisecondsSinceEpoch}')"><div class="number">${_escapeHtml(card)}</div></div>''';
    }).join();
    final emptyCount = math.max(0, previewCount - cards.length);
    final emptyMarkup = List<String>.filled(
      emptyCount,
      '<div class="card empty"></div>',
    ).join();
    final profileName = _escapeHtml(template.profileName);

    return '''<!doctype html>
<html lang="ar" dir="rtl">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>معاينة قالب $profileName</title>
<style>
:root { color-scheme: dark; font-family: Tajawal, Arial, sans-serif; }
* { box-sizing: border-box; }
body { margin:0; padding:24px; background:#070b14; color:#f5f7ff; }
.toolbar { max-width:1100px; margin:0 auto 18px; display:flex; gap:12px; align-items:center; justify-content:space-between; flex-wrap:wrap; }
h1 { font-size:20px; margin:0; }
.meta { color:#b8c2d9; font-size:13px; }
.page { max-width:1100px; margin:0 auto; background:#fff; padding:20px; border-radius:12px; box-shadow:0 16px 48px rgba(0,0,0,.35); direction:rtl; }
.grid { display:grid; grid-template-columns:repeat($columns,minmax(0,1fr)); gap:8px; }
.card { position:relative; aspect-ratio:${template.imageWidth}/${template.imageHeight}; min-height:80px; background-size:100% 100%; background-position:center; background-repeat:no-repeat; border:1px solid #17233a; overflow:hidden; }
.card.empty { background:#eef1f7; }
.number { position:absolute; left:${template.textXRatio * 100}%; top:${template.textYRatio * 100}%; width:${template.markerWidthRatio * 100}%; height:${template.markerHeightRatio * 100}%; transform:translate(-50%,-50%); display:flex; align-items:center; justify-content:center; text-align:center; white-space:nowrap; overflow:hidden; color:#000; font:700 clamp(10px,2vw,24px) Tajawal,Arial,sans-serif; direction:ltr; unicode-bidi:plaintext; }
.note { max-width:1100px; margin:12px auto 0; color:#aeb9d0; font-size:13px; }
@media(max-width:700px) { body { padding:12px; } .page { padding:10px; } .grid { gap:4px; } }
</style>
</head>
<body>
<div class="toolbar"><h1>معاينة قالب: $profileName</h1><div class="meta">$previewCount من ${template.cardsPerPage} كرتاً تجريبياً · الأرقام 0-9 بالإنجليزية</div></div>
<div class="page"><div class="grid">$cardMarkup$emptyMarkup</div></div>
<div class="note">هذه معاينة محلية على الجهاز. إذا اختلفت النتيجة عن PDF، اضبط موضع وحجم مربع الرقم ثم أعد الحفظ.</div>
</body>
</html>''';
  }

  List<String> _normalizeSampleCards(List<String> cards) {
    final normalized = <String>[];
    for (final card in cards) {
      final value = CardNumberPolicy.toAsciiDigits(card.trim());
      if (value.isNotEmpty) normalized.add(value);
    }
    return normalized.take(100).toList(growable: false);
  }

  String _escapeHtml(String value) {
    return value
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#39;');
  }
}
