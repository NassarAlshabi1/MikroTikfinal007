import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import 'hotspot_logic.dart';

/// طباعة **قسائم Hotspot** كملف PDF جاهز للقص (شبكة 3 أعمدة في صفحة A4).
///
/// يُستخدم نفس خط الواجهة العربية (`fonts/myfont.otf`) لضمان ظهور النصوص صحيحة.
class HotspotVoucherPdf {
  static pw.Font? _cachedFont;

  static Future<pw.Font?> _loadArabicFont() async {
    if (_cachedFont != null) return _cachedFont;
    try {
      final data = await rootBundle.load('fonts/myfont.otf');
      _cachedFont = pw.Font.ttf(data);
      return _cachedFont;
    } catch (_) {
      return null;
    }
  }

  /// إنشاء الملف ومشاركته/طباعته، وإرجاع عدد الصفحات.
  static Future<int> export({
    required List<VoucherPrintItem> vouchers,
    String title = "MikroNet Hotspot",
    String subtitle = "",
    String footer = "اتصل بشبكة الواي فاي ثم أدخل بيانات الكرت",
  }) async {
    final font = await _loadArabicFont();
    final doc = pw.Document();

    const perRow = 3;
    final rows = <List<VoucherPrintItem>>[];
    for (var i = 0; i < vouchers.length; i += perRow) {
      rows.add(vouchers.sublist(
        i,
        (i + perRow) > vouchers.length ? vouchers.length : i + perRow,
      ));
    }

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        textDirection: pw.TextDirection.rtl,
        margin: const pw.EdgeInsets.all(18),
        header: (context) => context.pageNumber == 1
            ? pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                margin: const pw.EdgeInsets.only(bottom: 12),
                decoration: pw.BoxDecoration(
                  color: PdfColor.fromHex('#1E3A8A'),
                  borderRadius: pw.BorderRadius.circular(10),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(title, style: _style(font, size: 14, bold: true, color: PdfColors.white)),
                    if (subtitle.isNotEmpty)
                      pw.Text(subtitle, style: _style(font, size: 9, color: PdfColors.blueGrey100)),
                  ],
                ),
              )
            : pw.SizedBox(height: 4),
        footer: (context) => pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(footer, style: _style(font, size: 8, color: PdfColors.grey700)),
            pw.Text(
              "${context.pageNumber} / ${context.pagesCount}",
              style: _style(font, size: 8, color: PdfColors.grey600),
            ),
          ],
        ),
        build: (context) => [
          for (final row in rows)
            pw.Container(
              margin: const pw.EdgeInsets.only(bottom: 10),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  for (final item in row) pw.Expanded(child: _cell(item, font, title)),
                  for (var i = row.length; i < perRow; i++)
                    pw.Expanded(child: pw.SizedBox()),
                ],
              ),
            ),
        ],
      ),
    );

    final bytes = await doc.save();
    await Printing.sharePdf(bytes: bytes, filename: 'hotspot_vouchers.pdf');
    return doc.document.pdfPageList.pages.length;
  }

  /// خلية قسيمة واحدة (بحدود قطع + بيانات الدخول).
  static pw.Widget _cell(VoucherPrintItem item, pw.Font? font, String title) {
    return pw.Container(
      margin: const pw.EdgeInsets.all(4),
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColor.fromHex('#94A3B8'), width: 0.7, style: pw.BorderStyle.dashed),
        borderRadius: pw.BorderRadius.circular(8),
        color: PdfColors.white,
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(vertical: 3, horizontal: 6),
            decoration: pw.BoxDecoration(
              color: PdfColor.fromHex('#0F172A'),
              borderRadius: pw.BorderRadius.circular(5),
            ),
            child: pw.Text(
              title,
              textAlign: pw.TextAlign.center,
              style: _style(font, size: 8, bold: true, color: PdfColors.white),
            ),
          ),
          pw.SizedBox(height: 6),
          _field("المستخدم", item.username, font, big: true),
          pw.SizedBox(height: 4),
          _field("كلمة المرور", item.password, font, big: true),
          pw.SizedBox(height: 6),
          if (item.profile.isNotEmpty) _line("الباقة: ${item.profile}", font),
          if (item.validity.isNotEmpty) _line("الصلاحية: ${item.validity}", font),
          if (item.dataLimit.isNotEmpty) _line("حجم البيانات: ${item.dataLimit}", font),
          if (item.note.isNotEmpty) _line(item.note, font, color: PdfColors.grey700),
          pw.SizedBox(height: 6),
          pw.Text("✂ ────────────────", style: _style(font, size: 7, color: PdfColors.grey500)),
        ],
      ),
    );
  }

  static pw.Widget _field(String label, String value, pw.Font? font, {bool big = false}) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(label, style: _style(font, size: 7, color: PdfColors.grey700)),
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.symmetric(vertical: 3, horizontal: 6),
          decoration: pw.BoxDecoration(
            color: PdfColor.fromHex('#F1F5F9'),
            borderRadius: pw.BorderRadius.circular(4),
          ),
          child: pw.Text(
            value,
            textAlign: pw.TextAlign.center,
            style: _style(font, size: big ? 13 : 9, bold: true, color: PdfColor.fromHex('#0F172A')),
          ),
        ),
      ],
    );
  }

  static pw.Widget _line(String text, pw.Font? font, {PdfColor? color}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 2),
      child: pw.Text(text, style: _style(font, size: 8, color: color ?? PdfColors.blueGrey800)),
    );
  }

  static pw.TextStyle _style(
    pw.Font? font, {
    double size = 10,
    bool bold = false,
    PdfColor color = PdfColors.black,
  }) {
    return pw.TextStyle(
      font: font,
      fontSize: size,
      fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
      color: color,
    );
  }
}
