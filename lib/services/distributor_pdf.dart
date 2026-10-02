import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/distributor_model.dart';

/// تصدير كشف حساب الموزع كملف PDF ومشاركته/طباعته.
class DistributorPdf {
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

  static String _money(double value) => value.toStringAsFixed(2);

  static Future<bool> exportStatement({
    required DistributorSummary summary,
    required List<DistributorTransactionModel> transactions,
  }) async {
    final font = await _loadArabicFont();
    final doc = pw.Document();

    pw.TextStyle style({double size = 10, bool bold = false, PdfColor? color}) {
      return pw.TextStyle(
        font: font,
        fontSize: size,
        fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
        color: color ?? PdfColors.black,
      );
    }

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        textDirection: pw.TextDirection.rtl,
        margin: const pw.EdgeInsets.all(28),
        footer: (context) => pw.Align(
          alignment: pw.Alignment.centerLeft,
          child: pw.Text(
            "MikroNet - ${DateTime.now().toString().split('.').first}",
            style: style(size: 8, color: PdfColors.grey600),
          ),
        ),
        build: (context) => [
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.all(14),
            decoration: pw.BoxDecoration(
              color: PdfColor.fromHex('#1E3A8A'),
              borderRadius: pw.BorderRadius.circular(10),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text("كشف حساب موزع", style: style(size: 18, bold: true, color: PdfColors.white)),
                pw.SizedBox(height: 4),
                pw.Text("MikroNet - إدارة الشبكة والمبيعات",
                    style: style(size: 10, color: PdfColors.white)),
              ],
            ),
          ),
          pw.SizedBox(height: 14),
          _infoTable(summary, style),
          pw.SizedBox(height: 14),
          pw.Text("الحركات", style: style(size: 13, bold: true)),
          pw.SizedBox(height: 6),
          _transactionsTable(transactions, style),
        ],
      ),
    );

    final bytes = await doc.save();
    final safeName = summary.distributor.name.replaceAll(RegExp(r'[^\w\u0600-\u06FF]+'), '_');
    return Printing.sharePdf(bytes: bytes, filename: 'kashf_$safeName.pdf');
  }

  static pw.Widget _infoTable(DistributorSummary summary, pw.TextStyle Function({double size, bool bold, PdfColor? color}) style) {
    final rows = <List<String>>[
      ["الموزع", summary.distributor.name],
      ["الهاتف", summary.distributor.phone.isEmpty ? "-" : summary.distributor.phone],
      ["إجمالي المبيعات", _money(summary.totalSales)],
      ["إجمالي التكلفة", _money(summary.totalCost)],
      ["إجمالي الأرباح", _money(summary.profit)],
      ["إجمالي الدفعات", _money(summary.totalPayments)],
      ["المرتجعات", _money(summary.totalRefunds)],
      ["الرصيد (${summary.balanceLabel})", _money(summary.balance.abs())],
      ["عدد الحركات", "${summary.salesCount} عملية بيع / ${summary.cardsCount} كرت"],
    ];

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
      columnWidths: {0: pw.FlexColumnWidth(2), 1: pw.FlexColumnWidth(3)},
      children: rows
          .map(
            (row) => pw.TableRow(
              children: [
                pw.Container(
                  color: PdfColors.grey200,
                  padding: const pw.EdgeInsets.all(6),
                  child: pw.Text(row[0], style: style(size: 10, bold: true)),
                ),
                pw.Container(
                  padding: const pw.EdgeInsets.all(6),
                  child: pw.Text(row[1], style: style(size: 10)),
                ),
              ],
            ),
          )
          .toList(),
    );
  }

  static pw.Widget _transactionsTable(
    List<DistributorTransactionModel> transactions,
    pw.TextStyle Function({double size, bool bold, PdfColor? color}) style,
  ) {
    if (transactions.isEmpty) {
      return pw.Text("لا توجد حركات مسجلة.", style: style(size: 11, color: PdfColors.grey700));
    }

    final headers = ["التاريخ", "النوع", "المبلغ", "التكلفة", "الكروت", "ملاحظة"];
    final rows = transactions
        .map((tx) => [
              tx.txDate,
              tx.type.arabicLabel,
              _money(tx.amount),
              tx.type == DistributorTxType.sale ? _money(tx.cost) : "-",
              tx.cardsCount.toString(),
              tx.note.isEmpty ? "-" : tx.note,
            ])
        .toList();

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.blueGrey100),
          children: headers
              .map(
                (header) => pw.Container(
                  padding: const pw.EdgeInsets.all(5),
                  child: pw.Text(header, style: style(size: 9, bold: true)),
                ),
              )
              .toList(),
        ),
        ...rows.map(
          (row) => pw.TableRow(
            children: row
                .map(
                  (cell) => pw.Container(
                    padding: const pw.EdgeInsets.all(5),
                    child: pw.Text(cell, style: style(size: 9)),
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );
  }
}
