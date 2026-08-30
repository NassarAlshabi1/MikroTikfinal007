import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';

import 'models/pdf_template.dart';
import 'snackbar_helpers.dart';

Future<Uint8List> _generatePdfInBackground(Map<String, dynamic> data) async {
  final cardUsernames = List<String>.from(data['cardUsernames'] as List);
  final imagePath = data['imagePath'] as String;
  final textXRatio = (data['textXRatio'] as num).toDouble();
  final textYRatio = (data['textYRatio'] as num).toDouble();
  final cardsPerPage = data['cardsPerPage'] as int;
  final imageWidth = (data['imageWidth'] as num).toDouble();
  final imageHeight = (data['imageHeight'] as num).toDouble();
  final markerWidthRatio = (data['markerWidthRatio'] as num).toDouble();
  final markerHeightRatio = (data['markerHeightRatio'] as num).toDouble();
  final fontBytes = data['fontBytes'] as Uint8List?;

  if (cardUsernames.isEmpty) {
    throw const FormatException('لا توجد كروت لإنشاء ملف PDF.');
  }
  for (final username in cardUsernames) {
    final normalized = username.trim();
    if (normalized.isEmpty ||
        normalized.length > 128 ||
        normalized.contains(RegExp(r'[\r\n]'))) {
      throw const FormatException('اسم كرت غير صالح أو يتجاوز حدود قالب PDF.');
    }
  }
  if (cardsPerPage < 1 || cardsPerPage > 1000) {
    throw const FormatException('عدد الكروت في الصفحة غير صالح.');
  }
  final imageFile = File(imagePath);
  if (!imageFile.existsSync()) {
    throw const FileSystemException('صورة قالب PDF غير موجودة.');
  }
  final imageLength = imageFile.lengthSync();
  if (imageLength <= 0 || imageLength > PdfTemplate.maxImageBytes) {
    throw const FileSystemException('حجم صورة قالب PDF غير مسموح به.');
  }
  _validateRatio(textXRatio, 'موضع النص الأفقي');
  _validateRatio(textYRatio, 'موضع النص العمودي');
  _validateRatio(markerWidthRatio, 'عرض منطقة النص');
  _validateRatio(markerHeightRatio, 'ارتفاع منطقة النص');

  final pdfFont =
      fontBytes == null ? null : pw.Font.ttf(_asByteData(fontBytes));
  final doc = pw.Document(
    theme: pdfFont == null
        ? null
        : pw.ThemeData.withFont(base: pdfFont, bold: pdfFont),
  );
  final imageBytes = await imageFile.readAsBytes();
  final imageProvider = pw.MemoryImage(imageBytes);
  final columns = cardsPerPage < 3 ? cardsPerPage : 3;

  for (var start = 0; start < cardUsernames.length; start += cardsPerPage) {
    final end = (start + cardsPerPage).clamp(0, cardUsernames.length);
    final pageCards = cardUsernames.sublist(start, end);
    final rows = (pageCards.length / columns).ceil();
    final slotCount = rows * columns;
    final gridChildren = <pw.Widget>[];

    for (var index = 0; index < slotCount; index++) {
      if (index >= pageCards.length) {
        gridChildren.add(pw.SizedBox.expand());
        continue;
      }
      final username = pageCards[index];
      gridChildren.add(
        pw.LayoutBuilder(
          builder: (context, constraints) {
            final safeConstraints = constraints;
            if (safeConstraints == null) return pw.SizedBox.shrink();
            final cellWidth = safeConstraints.maxWidth;
            final cellHeight = safeConstraints.maxHeight;
            final boxWidth =
                (markerWidthRatio * cellWidth).clamp(1.0, cellWidth).toDouble();
            final boxHeight = (markerHeightRatio * cellHeight)
                .clamp(1.0, cellHeight)
                .toDouble();
            final centerX = textXRatio * cellWidth;
            final centerY = textYRatio * cellHeight;
            final boxLeft = (centerX - boxWidth / 2)
                .clamp(0.0, (cellWidth - boxWidth).clamp(0.0, cellWidth))
                .toDouble();
            final boxTop = (centerY - boxHeight / 2)
                .clamp(0.0, (cellHeight - boxHeight).clamp(0.0, cellHeight))
                .toDouble();
            final fontSize = (boxHeight * 0.42).clamp(7.0, 22.0).toDouble();

            return pw.Container(
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.black, width: 1.2),
              ),
              child: pw.Stack(
                fit: pw.StackFit.expand,
                children: [
                  pw.Image(imageProvider, fit: pw.BoxFit.fill),
                  pw.Positioned(
                    left: boxLeft,
                    top: boxTop,
                    child: pw.SizedBox(
                      width: boxWidth,
                      height: boxHeight,
                      // scaleDown بدلاً من clip: إذا كان الرقم أعرض من
                      // منطقة النص يُصغَّر ليلائم الصندوق كاملاً — لا
                      // يُقتطع آخر خانة أبداً (1234567891 لا تظهر 123456789).
                      child: pw.FittedBox(
                        fit: pw.BoxFit.scaleDown,
                        alignment: pw.Alignment.center,
                        child: pw.Text(
                          username,
                          maxLines: 1,
                          softWrap: false,
                          textAlign: pw.TextAlign.center,
                          textDirection: pw.TextDirection.ltr,
                          style: pw.TextStyle(
                            font: pdfFont,
                            fontSize: fontSize,
                            color: PdfColors.black,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      );
    }

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(20),
        textDirection: pw.TextDirection.rtl,
        build: (context) => pw.GridView(
          crossAxisCount: columns,
          crossAxisSpacing: 5,
          mainAxisSpacing: 5,
          childAspectRatio: imageWidth / imageHeight,
          children: gridChildren,
        ),
      ),
    );
  }

  return doc.save();
}

ByteData _asByteData(Uint8List bytes) {
  return ByteData.view(
    bytes.buffer,
    bytes.offsetInBytes,
    bytes.lengthInBytes,
  );
}

void _validateRatio(double value, String label) {
  if (!value.isFinite || value < 0 || value > 1) {
    throw FormatException('$label يجب أن يكون بين 0 و1.');
  }
}

class PdfGenerator {
  static const _fontAsset = 'fonts/Tajawal-Regular.ttf';

  static Future<Map<String, dynamic>> _generationData({
    required List<String> cardUsernames,
    required PdfTemplate template,
  }) async {
    template.validate();
    if (cardUsernames.isEmpty) {
      throw const FormatException('لا توجد كروت لإنشاء ملف PDF.');
    }
    final image = File(template.imagePath);
    if (!await image.exists()) {
      throw const FileSystemException('صورة قالب PDF غير موجودة.');
    }
    final imageLength = await image.length();
    if (imageLength <= 0 || imageLength > PdfTemplate.maxImageBytes) {
      throw const FileSystemException('حجم صورة قالب PDF غير مسموح به.');
    }

    late final Uint8List fontBytes;
    try {
      final fontData = await rootBundle.load(_fontAsset);
      fontBytes = fontData.buffer.asUint8List(
        fontData.offsetInBytes,
        fontData.lengthInBytes,
      );
    } catch (error) {
      throw StateError('تعذر تحميل خط Tajawal المضمّن لقالب PDF: $error');
    }

    final normalizedUsernames = cardUsernames
        .map((username) => username.trim())
        .toList(growable: false);
    for (final username in normalizedUsernames) {
      if (username.isEmpty ||
          username.length > 128 ||
          username.contains(RegExp(r'[\r\n]'))) {
        throw const FormatException(
            'اسم كرت غير صالح أو يتجاوز حدود قالب PDF.');
      }
    }

    return {
      'cardUsernames': normalizedUsernames,
      'imagePath': template.imagePath,
      'textXRatio': template.textXRatio,
      'textYRatio': template.textYRatio,
      'cardsPerPage': template.cardsPerPage,
      'imageWidth': template.imageWidth,
      'imageHeight': template.imageHeight,
      'markerWidthRatio': template.markerWidthRatio,
      'markerHeightRatio': template.markerHeightRatio,
      'fontBytes': fontBytes,
    };
  }

  static Future<Uint8List> generatePdfBytes({
    required List<String> cardUsernames,
    required PdfTemplate template,
  }) async {
    final data = await _generationData(
      cardUsernames: cardUsernames,
      template: template,
    );
    return compute(_generatePdfInBackground, data);
  }

  static Future<void> previewPdf(
    BuildContext context, {
    required List<String> cardUsernames,
    required PdfTemplate template,
  }) async {
    if (cardUsernames.isEmpty) {
      showErrorSnackBar(context, 'لا توجد كروت لمعاينتها.');
      return;
    }
    _showProgressDialog(context);
    try {
      final pdfBytes = await generatePdfBytes(
        cardUsernames: cardUsernames,
        template: template,
      );
      if (context.mounted) _closeProgressDialog(context);
      await Printing.layoutPdf(
        name: _fileName(template.profileName),
        onLayout: (_) async => pdfBytes,
      );
    } catch (e) {
      if (context.mounted) {
        _closeProgressDialog(context);
        showErrorSnackBar(context, 'فشل فتح معاينة PDF: $e');
      }
    }
  }

  static Future<void> sharePdf(
    BuildContext context, {
    required List<String> cardUsernames,
    required PdfTemplate template,
  }) async {
    if (cardUsernames.isEmpty) {
      showErrorSnackBar(context, 'لا توجد كروت لمشاركتها.');
      return;
    }
    _showProgressDialog(context);
    try {
      final pdfBytes = await generatePdfBytes(
        cardUsernames: cardUsernames,
        template: template,
      );
      if (context.mounted) _closeProgressDialog(context);
      await Printing.sharePdf(
        bytes: pdfBytes,
        filename: _fileName(template.profileName),
      );
    } catch (e) {
      if (context.mounted) {
        _closeProgressDialog(context);
        showErrorSnackBar(context, 'فشل إنشاء ملف PDF: $e');
      }
    }
  }

  static Future<String?> savePdf(
    BuildContext context, {
    required List<String> cardUsernames,
    required PdfTemplate template,
  }) async {
    if (cardUsernames.isEmpty) {
      showErrorSnackBar(context, 'لا توجد كروت لحفظها.');
      return null;
    }
    _showProgressDialog(context);
    try {
      final pdfBytes = await generatePdfBytes(
        cardUsernames: cardUsernames,
        template: template,
      );
      final docsDir = await getApplicationDocumentsDirectory();
      final exportsDir = Directory('${docsDir.path}/pdf_exports');
      await exportsDir.create(recursive: true);
      final savePath = '${exportsDir.path}/${_fileName(template.profileName)}';
      await File(savePath).writeAsBytes(pdfBytes, flush: true);

      if (!context.mounted) return savePath;
      _closeProgressDialog(context);
      showSuccessSnackBar(context, 'تم حفظ PDF في: $savePath');
      return savePath;
    } catch (e) {
      if (context.mounted) {
        _closeProgressDialog(context);
        showErrorSnackBar(context, 'فشل حفظ PDF: $e');
      }
      return null;
    }
  }

  static void _showProgressDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
  }

  static void _closeProgressDialog(BuildContext context) {
    Navigator.of(context, rootNavigator: true).pop();
  }

  static String _fileName(String profileName) {
    final safeProfile = profileName
        .trim()
        .replaceAll(RegExp(r'[^a-zA-Z0-9\u0600-\u06FF_-]+'), '_');
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return 'wifi-cards-${safeProfile.isEmpty ? 'cards' : safeProfile}-$timestamp.pdf';
  }
}
