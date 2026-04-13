// ملف: pdf_generator.dart

import 'dart:io';
// --- ✨ إصلاح: تم تصحيح الأخطاء الإملائية في الـ import ---
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'snackbar_helpers.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'pdf_templates_screen.dart';


Future<Uint8List> _generatePdfInBackground(Map<String, dynamic> data) async {
  final cardUsernames = data['cardUsernames'] as List<String>;
  final imagePath = data['imagePath'] as String;
  final textXRatio = data['textXRatio'] as double;
  final textYRatio = data['textYRatio'] as double;
  final cardsPerPage = data['cardsPerPage'] as int;
  final imageWidth = data['imageWidth'] as double;
  final imageHeight = data['imageHeight'] as double;
  final markerWidthRatio = data['markerWidthRatio'] as double;
  final markerHeightRatio = data['markerHeightRatio'] as double;
  final String documentTitle = data['documentTitle'] as String;
  final String profileName = data['profileName'] as String;
  final String exportDate = data['exportDate'] as String;


  final doc = pw.Document();
  final imageBytes = await File(imagePath).readAsBytes();
  final imageProvider = pw.MemoryImage(imageBytes);

  int step = cardsPerPage;
  for (var i = 0; i < cardUsernames.length || i == 0; i += step) {
     if (i > cardUsernames.length && i!=0) break;

    final pageCards = cardUsernames.sublist(
        i, i + step > cardUsernames.length ? cardUsernames.length : i + step);

    doc.addPage(
      pw.Page(
        margin: const pw.EdgeInsets.all(20),
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {

          // --- ترويسة المستند: تسمية المستند، فئة الكرت، تاريخ التصدير ---
          final List<pw.Widget> headerChildren = [
            pw.Container(
              padding: const pw.EdgeInsets.only(bottom: 12),
              decoration: const pw.BoxDecoration(
                border: pw.Border(
                  bottom: pw.BorderSide(color: PdfColors.grey400, width: 1.5),
                ),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // تسمية المستند
                  pw.Text(
                    documentTitle,
                    style: pw.TextStyle(
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.black,
                    ),
                  ),
                  pw.SizedBox(height: 6),
                  // فئة الكرت + تاريخ التصدير
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        'فئة الكرت: $profileName',
                        style: const pw.TextStyle(
                          fontSize: 12,
                          color: PdfColors.grey700,
                        ),
                      ),
                      pw.Text(
                        'تاريخ التصدير: $exportDate',
                        style: const pw.TextStyle(
                          fontSize: 12,
                          color: PdfColors.grey700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 8),
          ];
          // --- نهاية الترويسة ---

          final List<pw.Widget> gridChildren = [];

          for (var user in pageCards) {
            gridChildren.add(
              pw.LayoutBuilder(builder: (ctx, constraints) {
                // --- ✨ إصلاح: إضافة علامة التعجب (!) للتعامل مع Null Safety ---
                final cellWidth = constraints!.maxWidth;
                final cellHeight = constraints.maxHeight;

                final boxWidth = markerWidthRatio * cellWidth;
                final boxHeight = markerHeightRatio * cellHeight;
                final boxLeft = (textXRatio * cellWidth) - (boxWidth / 2);
                final boxTop = (textYRatio * cellHeight) - (boxHeight / 2);

                return pw.Container(
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.black, width: 1.5),
                  ),
                  child: pw.Stack(
                    fit: pw.StackFit.expand,
                    children: [
                      pw.Image(imageProvider, fit: pw.BoxFit.fill),
                      // --- ✨ إصلاح: استخدام pw.Container داخل pw.Positioned لتحديد الأبعاد ---
                      pw.Positioned(
                        left: boxLeft,
                        top: boxTop,
                        child: pw.Container(
                          width: boxWidth,
                          height: boxHeight,
                          child: pw.Center(
                            child: pw.Text(
                              user,
                              textAlign: pw.TextAlign.center,
                              style: const pw.TextStyle(
                                color: PdfColors.black,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            );
          }

          int remainingSlots = cardsPerPage - pageCards.length;
          for (var j = 0; j < remainingSlots; j++) {
            gridChildren.add(pw.SizedBox.shrink());
          }


          return pw.Column(
            children: [
              ...headerChildren,
              pw.Expanded(
                child: pw.GridView(
                  crossAxisSpacing: 5,
                  mainAxisSpacing: 5,
                  crossAxisCount: 3,
                  childAspectRatio: imageWidth / imageHeight,
                  children: gridChildren,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  return doc.save();
}


class PdfGenerator {
  static Future<void> sharePdf(
    BuildContext context, {
    required List<String> cardUsernames,
    required PdfTemplate template,
    String? documentTitle,
    String? profileName,
    String? exportDate,
  }) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final now = DateTime.now();
      final Map<String, dynamic> generationData = {
        'cardUsernames': cardUsernames,
        'imagePath': template.imagePath,
        'textXRatio': template.textXRatio,
        'textYRatio': template.textYRatio,
        'cardsPerPage': template.cardsPerPage,
        'imageWidth': template.imageWidth,
        'imageHeight': template.imageHeight,
        'markerWidthRatio': template.markerWidthRatio,
        'markerHeightRatio': template.markerHeightRatio,
        'documentTitle': documentTitle ?? 'كروت Wi-Fi',
        'profileName': profileName ?? template.profileName,
        'exportDate': exportDate ?? '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}  ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}',
      };

      final pdfBytes = await compute(_generatePdfInBackground, generationData);

      if(context.mounted) Navigator.of(context).pop();
      await Printing.sharePdf(bytes: pdfBytes, filename: 'wifi-cards.pdf');
    } catch (e) {
      if(context.mounted) {
        Navigator.of(context).pop();
        showErrorSnackBar(context, 'فشل إنشاء ملف PDF. تأكد من القالب وصلاحية الصورة.');
      }
    }
  }

  static Future<String?> savePdf(
    BuildContext context, {
    required List<String> cardUsernames,
    required PdfTemplate template,
    String? documentTitle,
    String? profileName,
    String? exportDate,
  }) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final now = DateTime.now();
      final Map<String, dynamic> generationData = {
        'cardUsernames': cardUsernames,
        'imagePath': template.imagePath,
        'textXRatio': template.textXRatio,
        'textYRatio': template.textYRatio,
        'cardsPerPage': template.cardsPerPage,
        'imageWidth': template.imageWidth,
        'imageHeight': template.imageHeight,
        'markerWidthRatio': template.markerWidthRatio,
        'markerHeightRatio': template.markerHeightRatio,
        'documentTitle': documentTitle ?? 'كروت Wi-Fi',
        'profileName': profileName ?? template.profileName,
        'exportDate': exportDate ?? '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}  ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}',
      };

      final pdfBytes = await compute(_generatePdfInBackground, generationData);

      final docsDir = await getApplicationDocumentsDirectory();
      final now = DateTime.now();
      final filename = 'wifi-cards-${now.millisecondsSinceEpoch}.pdf';
      final savePath = '${docsDir.path}/$filename';
      final file = File(savePath);
      await file.writeAsBytes(pdfBytes, flush: true);

      if (context.mounted) Navigator.of(context).pop();
      showSuccessSnackBar(context, 'تم حفظ PDF في: $savePath');
      return savePath;
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop();
        showErrorSnackBar(context, 'فشل حفظ PDF.');
      }
      return null;
    }
  }
}