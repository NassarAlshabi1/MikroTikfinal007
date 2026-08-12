import 'dart:io';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';

class ExcelExportService {
  static Future<File> exportUsersToExcel(List<Map<String, dynamic>> users) async {
    final excel = Excel.createExcel();
    final sheet = excel['Users'];

    sheet.appendRow([
      const TextCellValue('Username'),
      const TextCellValue('Profile'),
      const TextCellValue('Status'),
      const TextCellValue('Download (MB)'),
      const TextCellValue('Upload (MB)'),
      const TextCellValue('Total (MB)'),
    ]);

    for (final user in users) {
      final download = double.tryParse(user['download-used']?.toString() ?? '0') ?? 0.0;
      final upload = double.tryParse(user['upload-used']?.toString() ?? '0') ?? 0.0;
      final total = (download + upload) / (1024 * 1024);

      sheet.appendRow([
        TextCellValue(user['username']?.toString() ?? ''),
        TextCellValue(user['actual-profile']?.toString() ?? ''),
        TextCellValue(user['disabled'] == 'true' ? 'Disabled' : 'Active'),
        DoubleCellValue(download / (1024 * 1024)),
        DoubleCellValue(upload / (1024 * 1024)),
        DoubleCellValue(total),
      ]);
    }

    for (var i = 0; i < sheet.columns.length; i++) {
      sheet.setColumnWidth(i, 20);
    }

    final directory = await getTemporaryDirectory();
    final dateStr = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final file = File('${directory.path}/users_$dateStr.xlsx');
    await file.writeAsBytes(excel.encode()!);

    return file;
  }

  static Future<File> exportSessionsToExcel(List<Map<String, dynamic>> sessions) async {
    final excel = Excel.createExcel();
    final sheet = excel['Sessions'];

    sheet.appendRow([
      const TextCellValue('User'),
      const TextCellValue('IP Address'),
      const TextCellValue('Uptime'),
      const TextCellValue('Download (MB)'),
      const TextCellValue('Upload (MB)'),
    ]);

    for (final session in sessions) {
      final download = double.tryParse(session['download']?.toString() ?? '0') ?? 0.0;
      final upload = double.tryParse(session['upload']?.toString() ?? '0') ?? 0.0;

      sheet.appendRow([
        TextCellValue(session['user']?.toString() ?? ''),
        TextCellValue(session['address']?.toString() ?? session['framed-ip-address']?.toString() ?? ''),
        TextCellValue(session['uptime']?.toString() ?? ''),
        DoubleCellValue(download / (1024 * 1024)),
        DoubleCellValue(upload / (1024 * 1024)),
      ]);
    }

    for (var i = 0; i < sheet.columns.length; i++) {
      sheet.setColumnWidth(i, 20);
    }

    final directory = await getTemporaryDirectory();
    final dateStr = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final file = File('${directory.path}/sessions_$dateStr.xlsx');
    await file.writeAsBytes(excel.encode()!);

    return file;
  }

  static Future<void> shareExcel(File file, String filename) async {
    await Share.shareXFiles(
      [XFile(file.path)],
      text: 'Excel Report - $filename',
      subject: 'Excel Report - $filename',
    );
  }
}
