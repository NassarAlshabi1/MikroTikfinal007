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

/// كائن يمثل بيانات الكرت لطباعة الـ PDF (يدعم اسم المستخدم وكلمة المرور والفئة)
class PdfCardItem {
  final String username;
  final String? password;

  const PdfCardItem({
    required this.username,
    this.password,
  });

  Map<String, dynamic> toMap() => {
        'username': username,
        'password': password,
      };

  factory PdfCardItem.fromMap(Map<String, dynamic> map) => PdfCardItem(
        username: map['username']?.toString() ?? '',
        password: map['password']?.toString(),
      );

  factory PdfCardItem.fromString(String raw) {
    final trimmed = raw.trim();
    if (trimmed.toLowerCase().contains('username:') &&
        trimmed.toLowerCase().contains('password:')) {
      try {
        final parts = trimmed.split(',');
        String u = '';
        String p = '';
        for (final part in parts) {
          final sub = part.trim();
          if (sub.toLowerCase().startsWith('username:')) {
            u = sub.substring('username:'.length).trim();
          } else if (sub.toLowerCase().startsWith('password:')) {
            p = sub.substring('password:'.length).trim();
          }
        }
        if (u.isNotEmpty) {
          return PdfCardItem(username: u, password: p.isEmpty ? null : p);
        }
      } catch (_) {}
    }
    return PdfCardItem(username: trimmed);
  }
}

Future<Uint8List> _generatePdfInBackground(Map<String, dynamic> data) async {
  final rawCards = data['cards'] as List;
  final cards = rawCards
      .map((c) => c is Map
          ? PdfCardItem.fromMap(Map<String, dynamic>.from(c))
          : PdfCardItem(username: c.toString()))
      .toList();

  final profileName = (data['profileName'] as String?)?.trim() ?? '';
  final imagePath = data['imagePath'] as String?;
  final isDefaultLayout = (data['isDefaultLayout'] as bool?) ?? false;

  final textXRatio = ((data['textXRatio'] ?? 0.5) as num).toDouble();
  final textYRatio = ((data['textYRatio'] ?? 0.5) as num).toDouble();
  final cardsPerPage = ((data['cardsPerPage'] ?? 10) as int).clamp(1, 1000);
  final imageWidth = ((data['imageWidth'] ?? 800) as num).toDouble();
  final imageHeight = ((data['imageHeight'] ?? 500) as num).toDouble();
  final markerWidthRatio =
      ((data['markerWidthRatio'] ?? 0.5) as num).toDouble();
  final markerHeightRatio =
      ((data['markerHeightRatio'] ?? 0.2) as num).toDouble();
  final fontBytes = data['fontBytes'] as Uint8List?;

  if (cards.isEmpty) {
    throw const FormatException('لا توجد كروت لإنشاء ملف PDF.');
  }

  for (final card in cards) {
    final normalized = card.username.trim();
    if (normalized.isEmpty ||
        normalized.length > 128 ||
        normalized.contains(RegExp(r'[\r\n]'))) {
      throw const FormatException('اسم كرت غير صالح أو يتجاوز حدود قالب PDF.');
    }
  }

  final pdfFont =
      fontBytes == null ? null : pw.Font.ttf(_asByteData(fontBytes));
  final doc = pw.Document(
    theme: pdfFont == null
        ? null
        : pw.ThemeData.withFont(base: pdfFont, bold: pdfFont),
  );

  // إذا كان هناك قالب ذو صورة موجودة وصالحة
  if (!isDefaultLayout && imagePath != null && imagePath.isNotEmpty) {
    final imageFile = File(imagePath);
    if (imageFile.existsSync()) {
      final imageBytes = await imageFile.readAsBytes();
      final imageProvider = pw.MemoryImage(imageBytes);
      final columns = cardsPerPage < 3 ? cardsPerPage : 3;

      for (var start = 0; start < cards.length; start += cardsPerPage) {
        final end = (start + cardsPerPage).clamp(0, cards.length);
        final pageCards = cards.sublist(start, end);
        final rows = (pageCards.length / columns).ceil();
        final slotCount = rows * columns;
        final gridChildren = <pw.Widget>[];

        for (var index = 0; index < slotCount; index++) {
          if (index >= pageCards.length) {
            gridChildren.add(pw.SizedBox.expand());
            continue;
          }
          final card = pageCards[index];
          final hasPassword =
              card.password != null && card.password!.trim().isNotEmpty;

          gridChildren.add(
            pw.LayoutBuilder(
              builder: (context, constraints) {
                final safeConstraints = constraints;
                if (safeConstraints == null) return pw.SizedBox.shrink();
                final cellWidth = safeConstraints.maxWidth;
                final cellHeight = safeConstraints.maxHeight;
                final boxWidth = (markerWidthRatio * cellWidth)
                    .clamp(1.0, cellWidth)
                    .toDouble();
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

                final fontSize = hasPassword
                    ? (boxHeight * 0.28).clamp(6.0, 15.0).toDouble()
                    : (boxHeight * 0.42).clamp(7.0, 22.0).toDouble();

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
                          child: pw.Center(
                            child: pw.Column(
                              mainAxisAlignment: pw.MainAxisAlignment.center,
                              crossAxisAlignment: pw.CrossAxisAlignment.center,
                              children: [
                                pw.Text(
                                  card.username,
                                  maxLines: 1,
                                  overflow: pw.TextOverflow.clip,
                                  textAlign: pw.TextAlign.center,
                                  textDirection: pw.TextDirection.ltr,
                                  style: pw.TextStyle(
                                    font: pdfFont,
                                    fontSize: fontSize,
                                    fontWeight: pw.FontWeight.bold,
                                    color: PdfColors.black,
                                  ),
                                ),
                                if (hasPassword) ...[
                                  pw.SizedBox(height: 2),
                                  pw.Text(
                                    'كلمة المرور: ${card.password}',
                                    maxLines: 1,
                                    overflow: pw.TextOverflow.clip,
                                    textAlign: pw.TextAlign.center,
                                    textDirection: pw.TextDirection.rtl,
                                    style: pw.TextStyle(
                                      font: pdfFont,
                                      fontSize: (fontSize * 0.85).clamp(5.0, 12.0),
                                      color: PdfColors.black,
                                    ),
                                  ),
                                ],
                              ],
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
  }

  // --- التصميم الافتراضي المدمج (Default Layout) عند عدم وجود قالب مخصص ---
  const defaultColumns = 3;
  const defaultCardsPerPage = 12; // 3 أعمدة في 4 صفوف لورقة A4 أنيقة
  final totalCards = cards.length;

  for (var start = 0; start < totalCards; start += defaultCardsPerPage) {
    final end = (start + defaultCardsPerPage).clamp(0, totalCards);
    final pageCards = cards.sublist(start, end);
    final gridChildren = <pw.Widget>[];

    for (var index = 0; index < defaultCardsPerPage; index++) {
      if (index >= pageCards.length) {
        gridChildren.add(pw.SizedBox.expand());
        continue;
      }
      final card = pageCards[index];
      final hasPassword =
          card.password != null && card.password!.trim().isNotEmpty;

      gridChildren.add(
        pw.Container(
          padding: const pw.EdgeInsets.all(8),
          decoration: pw.BoxDecoration(
            color: PdfColors.white,
            borderRadius: pw.BorderRadius.circular(6),
            border: pw.Border.all(color: PdfColors.grey700, width: 1.0),
          ),
          child: pw.Column(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              // الهيدر (عنوان الكرت والفئة)
              pw.Container(
                padding: const pw.EdgeInsets.only(bottom: 4),
                decoration: const pw.BoxDecoration(
                  border: pw.Border(
                    bottom: pw.BorderSide(color: PdfColors.grey400, width: 0.5),
                  ),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'كرت إنترنت Wi-Fi',
                      style: pw.TextStyle(
                        font: pdfFont,
                        fontSize: 8.5,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.blue900,
                      ),
                    ),
                    if (profileName.isNotEmpty)
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(
                            horizontal: 4, vertical: 1.5),
                        decoration: pw.BoxDecoration(
                          color: PdfColors.blue50,
                          borderRadius: pw.BorderRadius.circular(3),
                        ),
                        child: pw.Text(
                          profileName,
                          style: pw.TextStyle(
                            font: pdfFont,
                            fontSize: 7.5,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.blue800,
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // منطقة الرقم التسلسلي وكلمة المرور
              pw.Expanded(
                child: pw.Center(
                  child: pw.Column(
                    mainAxisAlignment: pw.MainAxisAlignment.center,
                    children: [
                      pw.Text(
                        'اسم المستخدم (المستخدم)',
                        style: pw.TextStyle(
                          font: pdfFont,
                          fontSize: 7,
                          color: PdfColors.grey700,
                        ),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(
                            horizontal: 6, vertical: 3),
                        decoration: pw.BoxDecoration(
                          color: PdfColors.grey100,
                          borderRadius: pw.BorderRadius.circular(4),
                          border: pw.Border.all(
                              color: PdfColors.grey300, width: 0.8),
                        ),
                        child: pw.Text(
                          card.username,
                          textAlign: pw.TextAlign.center,
                          textDirection: pw.TextDirection.ltr,
                          style: pw.TextStyle(
                            font: pdfFont,
                            fontSize: 12,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.black,
                          ),
                        ),
                      ),
                      if (hasPassword) ...[
                        pw.SizedBox(height: 4),
                        pw.Text(
                          'كلمة المرور: ${card.password}',
                          style: pw.TextStyle(
                            font: pdfFont,
                            fontSize: 8,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.grey800,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              // الفوتر
              pw.Container(
                padding: const pw.EdgeInsets.only(top: 2),
                child: pw.Text(
                  'نتمنى لكم تجربة تصفح ممتعة',
                  style: pw.TextStyle(
                    font: pdfFont,
                    fontSize: 6.5,
                    color: PdfColors.grey600,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(16),
        textDirection: pw.TextDirection.rtl,
        build: (context) => pw.GridView(
          crossAxisCount: defaultColumns,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: 1.6,
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

  static Future<Map<String, dynamic>> _prepareGenerationData({
    required List<PdfCardItem> cards,
    PdfTemplate? template,
    String? profileName,
  }) async {
    if (cards.isEmpty) {
      throw const FormatException('لا توجد كروت لإنشاء ملف PDF.');
    }

    final normalizedCards = cards
        .map((c) => PdfCardItem(
              username: c.username.trim(),
              password: c.password?.trim(),
            ))
        .toList(growable: false);

    for (final card in normalizedCards) {
      if (card.username.isEmpty ||
          card.username.length > 128 ||
          card.username.contains(RegExp(r'[\r\n]'))) {
        throw const FormatException(
            'اسم كرت غير صالح أو يتجاوز حدود قالب PDF.');
      }
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

    // تحقق من القالب إن وُجد
    bool hasValidTemplate = false;
    if (template != null) {
      try {
        template.validate();
        final image = File(template.imagePath);
        if (await image.exists()) {
          final imageLength = await image.length();
          if (imageLength > 0 && imageLength <= PdfTemplate.maxImageBytes) {
            hasValidTemplate = true;
          }
        }
      } catch (_) {
        hasValidTemplate = false;
      }
    }

    if (hasValidTemplate && template != null) {
      return {
        'cards': normalizedCards.map((c) => c.toMap()).toList(),
        'profileName': template.profileName,
        'imagePath': template.imagePath,
        'isDefaultLayout': false,
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

    // الاعتماد على التنسيق الافتراضي المدمج (Fallback Default Layout)
    return {
      'cards': normalizedCards.map((c) => c.toMap()).toList(),
      'profileName': profileName ?? template?.profileName ?? 'Default',
      'imagePath': null,
      'isDefaultLayout': true,
      'textXRatio': 0.5,
      'textYRatio': 0.5,
      'cardsPerPage': 12,
      'imageWidth': 800,
      'imageHeight': 500,
      'markerWidthRatio': 0.5,
      'markerHeightRatio': 0.2,
      'fontBytes': fontBytes,
    };
  }

  /// دالة متوافقة مع الكود القديم والاختبارات
  static Future<Uint8List> generatePdfBytes({
    required List<String> cardUsernames,
    PdfTemplate? template,
    String? profileName,
  }) async {
    final cardItems =
        cardUsernames.map((u) => PdfCardItem.fromString(u)).toList();
    return generatePdfBytesWithItems(
      cards: cardItems,
      template: template,
      profileName: profileName,
    );
  }

  static Future<Uint8List> generatePdfBytesWithItems({
    required List<PdfCardItem> cards,
    PdfTemplate? template,
    String? profileName,
  }) async {
    final data = await _prepareGenerationData(
      cards: cards,
      template: template,
      profileName: profileName,
    );
    return compute(_generatePdfInBackground, data);
  }

  /// طباعة مباشرة عبر مشغل طابعات النظام
  static Future<void> printPdf(
    BuildContext context, {
    required List<dynamic> cards,
    PdfTemplate? template,
    String? profileName,
  }) async {
    final items = _normalizeToCardItems(cards);
    if (items.isEmpty) {
      showErrorSnackBar(context, 'لا توجد كروت لطباعتها.');
      return;
    }
    _showProgressDialog(context);
    try {
      final pdfBytes = await generatePdfBytesWithItems(
        cards: items,
        template: template,
        profileName: profileName,
      );
      if (context.mounted) _closeProgressDialog(context);
      final pName = profileName ?? template?.profileName ?? 'cards';
      await Printing.layoutPdf(
        name: _fileName(pName),
        onLayout: (_) async => pdfBytes,
      );
    } catch (e) {
      if (context.mounted) {
        _closeProgressDialog(context);
        showErrorSnackBar(context, 'فشل تشغيل نافذة الطباعة: $e');
      }
    }
  }

  /// معاينة الـ PDF
  static Future<void> previewPdf(
    BuildContext context, {
    required List<dynamic> cardUsernames,
    PdfTemplate? template,
    String? profileName,
  }) async {
    await printPdf(
      context,
      cards: cardUsernames,
      template: template,
      profileName: profileName,
    );
  }

  /// مشاركة الـ PDF عبر التطبيقات
  static Future<void> sharePdf(
    BuildContext context, {
    required List<dynamic> cardUsernames,
    PdfTemplate? template,
    String? profileName,
  }) async {
    final items = _normalizeToCardItems(cardUsernames);
    if (items.isEmpty) {
      showErrorSnackBar(context, 'لا توجد كروت لمشاركتها.');
      return;
    }
    _showProgressDialog(context);
    try {
      final pdfBytes = await generatePdfBytesWithItems(
        cards: items,
        template: template,
        profileName: profileName,
      );
      if (context.mounted) _closeProgressDialog(context);
      final pName = profileName ?? template?.profileName ?? 'cards';
      await Printing.sharePdf(
        bytes: pdfBytes,
        filename: _fileName(pName),
      );
    } catch (e) {
      if (context.mounted) {
        _closeProgressDialog(context);
        showErrorSnackBar(context, 'فشل إنشاء ملف PDF: $e');
      }
    }
  }

  /// حفظ الـ PDF في ذاكرة الجهاز
  static Future<String?> savePdf(
    BuildContext context, {
    required List<dynamic> cardUsernames,
    PdfTemplate? template,
    String? profileName,
  }) async {
    final items = _normalizeToCardItems(cardUsernames);
    if (items.isEmpty) {
      showErrorSnackBar(context, 'لا توجد كروت لحفظها.');
      return null;
    }
    _showProgressDialog(context);
    try {
      final pdfBytes = await generatePdfBytesWithItems(
        cards: items,
        template: template,
        profileName: profileName,
      );
      final docsDir = await getApplicationDocumentsDirectory();
      final exportsDir = Directory('${docsDir.path}/pdf_exports');
      await exportsDir.create(recursive: true);
      final pName = profileName ?? template?.profileName ?? 'cards';
      final savePath = '${exportsDir.path}/${_fileName(pName)}';
      await File(savePath).writeAsBytes(pdfBytes, flush: true);

      if (!context.mounted) return savePath;
      _closeProgressDialog(context);
      showSuccessSnackBar(context, 'تم حفظ PDF بنجاح في: $savePath');
      return savePath;
    } catch (e) {
      if (context.mounted) {
        _closeProgressDialog(context);
        showErrorSnackBar(context, 'فشل حفظ PDF: $e');
      }
      return null;
    }
  }

  static List<PdfCardItem> _normalizeToCardItems(List<dynamic> list) {
    return list.map((item) {
      if (item is PdfCardItem) return item;
      if (item is Map) {
        return PdfCardItem(
          username: (item['username'] ?? item['name'] ?? '').toString(),
          password: item['password']?.toString(),
        );
      }
      return PdfCardItem.fromString(item.toString());
    }).toList();
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
