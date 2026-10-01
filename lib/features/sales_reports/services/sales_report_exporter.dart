import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import '../../../services/um_cards_sync_service.dart';
import '../domain/card_usage_report.dart';

class SalesReportExporter {
  SalesReportExporter._();

  /// Builds an Excel-friendly UTF-8 CSV. Passwords, comments and router IDs
  /// are intentionally excluded from this report.
  static String buildCsv({
    required List<UmSyncedCard> cards,
    required CardUsageReportFilter filter,
    required DateTime lastSyncedAt,
  }) {
    final buffer = StringBuffer('\uFEFF');
    buffer.writeln([
      'username',
      'profile',
      'uptime_used',
      'uptime_limit',
      'status',
      'last_synced_at',
    ].map(_csvCell).join(','));

    final syncedAt = lastSyncedAt.toLocal().toIso8601String();
    for (final card in cards) {
      buffer.writeln([
        card.name,
        card.profile,
        card.uptimeUsed,
        card.limitUptime,
        cardUsageReportStatus(card, filter),
        syncedAt,
      ].map(_csvCell).join(','));
    }
    return buffer.toString();
  }

  static Future<void> shareCsv({
    required List<UmSyncedCard> cards,
    required CardUsageReportFilter filter,
    required DateTime lastSyncedAt,
  }) async {
    final appDirectory = await getApplicationDocumentsDirectory();
    final exportDirectory = Directory('${appDirectory.path}/exports');
    await exportDirectory.create(recursive: true);

    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final file = File(
      '${exportDirectory.path}/cards_${filter.fileSuffix}_$timestamp.csv',
    );
    await file.writeAsBytes(
      utf8.encode(buildCsv(
        cards: cards,
        filter: filter,
        lastSyncedAt: lastSyncedAt,
      )),
      flush: true,
    );

    await SharePlus.instance.share(ShareParams(
      files: [XFile(file.path)],
      subject: filter.title,
      text: 'تقرير حالة كروت User Manager، دون كلمات مرور أو بيانات بيع.',
    ));
  }

  static Future<void> sharePdf({
    required List<UmSyncedCard> cards,
    required CardUsageReportFilter filter,
    required DateTime lastSyncedAt,
    required int totalCount,
    required int usedCount,
    required int expiredCount,
    required int overlappingCount,
  }) async {
    final fontData = await rootBundle.load('fonts/Tajawal-Regular.ttf');
    final font = pw.Font.ttf(fontData);
    final document = pw.Document(
      theme: pw.ThemeData.withFont(base: font, bold: font),
    );
    final generatedAt = DateTime.now();

    document.addPage(pw.MultiPage(
      maxPages: 500,
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(28),
      build: (context) => [
        _rtlText(
          filter.title,
          style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 8),
        _rtlText('وقت إنشاء التقرير: ${_formatDate(generatedAt)}'),
        _rtlText('آخر مزامنة مع الراوتر: ${_formatDate(lastSyncedAt)}'),
        _rtlText('إجمالي سجلات User Manager: $totalCount'),
        _rtlText('عدد الصفوف المصدّرة حسب التصفية الحالية: ${cards.length}'),
        _rtlText(
          'الكروت المستخدمة: $usedCount  |  المنتهية/المعطّلة: $expiredCount',
        ),
        _rtlText('المستخدمة والمنتهية معاً: $overlappingCount'),
        _rtlText(
          'التقرير يعرض حالة الاستخدام فقط؛ لا يتضمن أسعاراً أو إيرادات.',
          style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
        ),
        pw.SizedBox(height: 12),
        _pdfRow(
          const ['اسم الكرت', 'الفئة', 'الاستخدام', 'حد الوقت', 'الحالة'],
          isHeader: true,
        ),
        for (final card in cards)
          _pdfRow([
            card.name,
            card.profile.isEmpty ? 'غير محدد' : card.profile,
            card.uptimeUsed.isEmpty ? 'غير متاح' : card.uptimeUsed,
            card.limitUptime.isEmpty ? 'غير محدد' : card.limitUptime,
            cardUsageReportStatus(card, filter),
          ]),
      ],
    ));

    await Printing.sharePdf(
      bytes: await document.save(),
      filename:
          'cards_${filter.fileSuffix}_${DateFormat('yyyyMMdd_HHmmss').format(generatedAt)}.pdf',
    );
  }

  static pw.Widget _rtlText(String text, {pw.TextStyle? style}) {
    return pw.Directionality(
      textDirection: pw.TextDirection.rtl,
      child: pw.Container(
        width: double.infinity,
        margin: const pw.EdgeInsets.only(bottom: 4),
        child: pw.Text(
          text,
          textAlign: pw.TextAlign.right,
          style: style,
        ),
      ),
    );
  }

  static pw.Widget _pdfRow(List<String> cells, {bool isHeader = false}) {
    final cellStyle = pw.TextStyle(
      fontSize: isHeader ? 9 : 8,
      fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
    );
    return pw.Directionality(
      textDirection: pw.TextDirection.rtl,
      child: pw.Container(
        width: double.infinity,
        padding: const pw.EdgeInsets.symmetric(vertical: 5, horizontal: 2),
        decoration: pw.BoxDecoration(
          color: isHeader ? PdfColors.blueGrey100 : null,
          border: const pw.Border(
            bottom: pw.BorderSide(color: PdfColors.grey400, width: 0.4),
          ),
        ),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            for (var index = 0; index < cells.length; index++)
              pw.Expanded(
                flex: index == 0 ? 3 : 2,
                child: pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 2),
                  child: pw.Text(
                    cells[index],
                    textAlign: pw.TextAlign.right,
                    style: cellStyle,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  static String _formatDate(DateTime value) =>
      DateFormat('yyyy-MM-dd HH:mm').format(value.toLocal());

  static String _csvCell(String value) {
    // Avoid spreadsheet formula execution for router-supplied values.
    final safeValue = RegExp(r'^[\t\r\n ]*[=+\-@]').hasMatch(value)
        ? "'$value"
        : value;
    final escapedValue = safeValue.replaceAll('"', '""');
    return '"$escapedValue"';
  }
}
