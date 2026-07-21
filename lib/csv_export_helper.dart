// ============================================================
//  CsvExportHelper — تصدير بيانات MikroTik إلى CSV
//
//  مستوحى من smartconnect-app/lib/export_helper.dart
//  يصدّر البيانات إلى CSV + يشاركها عبر Share.shareXFiles
//  + زر فتح الملف (Open) — مستوحى من smartconnect-app
// ============================================================

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

/// يساعد في تصدير البيانات إلى CSV
class CsvExportHelper {
  CsvExportHelper._();

  /// يصدّر قائمة من الكروت إلى CSV
  ///
  /// [cards] قائمة الكروت (كل كرت = Map<String, dynamic>)
  /// [filename] اسم الملف بدون امتداد
  /// [context]BuildContext لعرض bottom sheet
  static Future<void> exportCardsToCSV({
    required List<Map<String, dynamic>> cards,
    required String filename,
    required BuildContext context,
  }) async {
    if (cards.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لا توجد بيانات للتصدير')),
      );
      return;
    }

    // بناء CSV
    final csvBuffer = StringBuffer();

    // الرأس
    csvBuffer.writeln('Username,Password,Profile,Comment,Disabled,Expires');

    // الصفوف
    for (final card in cards) {
      final username = _escapeCsv(card['username'] ?? '');
      final password = _escapeCsv(card['password'] ?? '');
      final profile = _escapeCsv(card['profile'] ?? '');
      final comment = _escapeCsv(card['comment'] ?? '');
      final disabled = card['disabled'] ?? false;
      final expires = card['expires-after'] ?? '';

      csvBuffer.writeln(
          '$username,$password,$profile,$comment,$disabled,$expires');
    }

    // حفظ الملف
    final appDir = await getApplicationDocumentsDirectory();
    final exportDir = Directory('${appDir.path}/exports');
    if (!await exportDir.exists()) {
      await exportDir.create(recursive: true);
    }

    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final path = '${exportDir.path}/${filename}_$timestamp.csv';
    final file = File(path);
    await file.writeAsString(csvBuffer.toString());

    // عرض bottom sheet للفتح/المشاركة
    if (context.mounted) {
      _showExportResult(context, path, filename);
    }
  }

  /// يصدّر بيانات DHCP leases إلى CSV
  static Future<void> exportDhcpLeasesToCSV({
    required List<Map<String, dynamic>> leases,
    required BuildContext context,
  }) async {
    if (leases.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لا توجد بيانات للتصدير')),
      );
      return;
    }

    final csvBuffer = StringBuffer();
    csvBuffer.writeln('IP,MAC,Hostname,Status,Server');

    for (final lease in leases) {
      final ip = _escapeCsv(lease['address'] ?? '');
      final mac = _escapeCsv(lease['mac-address'] ?? '');
      final hostname = _escapeCsv(lease['host-name'] ?? '');
      final status = _escapeCsv(lease['status'] ?? '');
      final server = _escapeCsv(lease['server'] ?? '');

      csvBuffer.writeln('$ip,$mac,$hostname,$status,$server');
    }

    final appDir = await getApplicationDocumentsDirectory();
    final exportDir = Directory('${appDir.path}/exports');
    if (!await exportDir.exists()) {
      await exportDir.create(recursive: true);
    }

    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final path = '${exportDir.path}/dhcp_leases_$timestamp.csv';
    final file = File(path);
    await file.writeAsString(csvBuffer.toString());

    if (context.mounted) {
      _showExportResult(context, path, 'DHCP Leases');
    }
  }

  /// يصدّر سجل التشخيصات إلى CSV
  static Future<void> exportDiagnosticsToCSV({
    required List<Map<String, dynamic>> diagnostics,
    required BuildContext context,
  }) async {
    if (diagnostics.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لا توجد بيانات للتصدير')),
      );
      return;
    }

    final csvBuffer = StringBuffer();
    csvBuffer.writeln('Timestamp,Type,Content,Commands');

    for (final diag in diagnostics) {
      final timestamp = _escapeCsv(
          diag['timestamp'] ?? DateTime.now().toIso8601String());
      final type = _escapeCsv(diag['type'] ?? '');
      final content = _escapeCsv(diag['content'] ?? '');
      final commands = _escapeCsv((diag['commands'] as List?)?.join(';') ?? '');

      csvBuffer.writeln('$timestamp,$type,$content,$commands');
    }

    final appDir = await getApplicationDocumentsDirectory();
    final exportDir = Directory('${appDir.path}/exports');
    if (!await exportDir.exists()) {
      await exportDir.create(recursive: true);
    }

    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final path = '${exportDir.path}/diagnostics_$timestamp.csv';
    final file = File(path);
    await file.writeAsString(csvBuffer.toString());

    if (context.mounted) {
      _showExportResult(context, path, 'Diagnostics');
    }
  }

  // ===== Helpers =====

  /// يهرب القيمة لـ CSV (يضع علامات اقتباس إن لزم)
  static String _escapeCsv(dynamic value) {
    final str = value.toString();
    if (str.contains(',') || str.contains('"') || str.contains('\n')) {
      return '"${str.replaceAll('"', '""')}"';
    }
    return str;
  }

  /// يعرض نتيجة التصدير مع أزرار فتح/مشاركة
  static void _showExportResult(
      BuildContext context, String path, String title) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '✅ تم تصدير $title!',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              path,
              style: const TextStyle(fontSize: 11, color: Colors.grey),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // 🔧 مستوحى من smartconnect-app: زر فتح الملف
                ElevatedButton.icon(
                  icon: const Icon(Icons.open_in_new),
                  label: const Text('فتح'),
                  onPressed: () {
                    Navigator.of(context).pop();
                    _openFile(path);
                  },
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.share),
                  label: const Text('مشاركة'),
                  onPressed: () {
                    Navigator.of(context).pop();
                    Share.share(
                      path,
                      subject: 'MikroTik Manager - $title Export',
                    );
                  },
                ),
                TextButton.icon(
                  icon: const Icon(Icons.close),
                  label: const Text('إغلاق'),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// يفتح ملفاً عبر التطبيق الافتراضي للنظام
  /// 🔧 مستوحى من smartconnect-app/lib/export_helper.dart (OpenFile.open)
  static Future<void> _openFile(String path) async {
    final uri = Uri.file(path);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }
}
