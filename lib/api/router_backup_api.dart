import 'dart:convert';

import '/models/response.dart';
import '/services/mikrotik_client.dart';

/// ملف موجود في ذاكرة الراوتر.
class RouterFileModel {
  final String id;
  final String name;
  final int size;
  final String type;
  final String lastModified;

  RouterFileModel({
    required this.id,
    required this.name,
    required this.size,
    required this.type,
    required this.lastModified,
  });

  bool get isBackup => name.endsWith('.backup');
  bool get isExport => name.endsWith('.rsc');

  String get readableSize {
    if (size <= 0) return "0 KB";
    if (size < 1024) return "$size B";
    if (size < 1024 * 1024) return "${(size / 1024).toStringAsFixed(1)} KB";
    return "${(size / (1024 * 1024)).toStringAsFixed(2)} MB";
  }

  static RouterFileModel fromMikrotik(Map data) {
    return RouterFileModel(
      id: data[".id"]?.toString() ?? "",
      name: data["name"]?.toString() ?? "",
      size: _parseSize(data["size"]),
      type: data["type"]?.toString() ?? "",
      lastModified: data["last-modified"]?.toString() ?? "",
    );
  }

  static int _parseSize(dynamic raw) {
    if (raw == null) return 0;
    if (raw is int) return raw;
    if (raw is num) return raw.toInt();

    final text = raw.toString().trim();
    final direct = int.tryParse(text);
    if (direct != null) return direct;

    // صيغ مثل 1.5KiB أو 3MiB
    final match = RegExp(r'([\d.]+)\s*([KMG]?)i?B', caseSensitive: false).firstMatch(text);
    if (match == null) return 0;
    final value = double.tryParse(match.group(1) ?? "") ?? 0;
    final unit = (match.group(2) ?? "").toUpperCase();
    switch (unit) {
      case 'K':
        return (value * 1024).round();
      case 'M':
        return (value * 1024 * 1024).round();
      case 'G':
        return (value * 1024 * 1024 * 1024).round();
      default:
        return value.round();
    }
  }
}

/// النسخ الاحتياطي الحقيقي لراوتر MikroTik:
/// إنشاء ملف نسخة داخل ذاكرة الراوتر، تنزيله إلى الهاتف، رفعه، واستعادته.
class RouterBackupApi {
  static const String _filesFields = ".id,name,size,type,last-modified";

  /// قائمة ملفات النسخ والتصدير الموجودة على الراوتر.
  static Future<AppResponse<List<RouterFileModel>>> listBackupFiles() async {
    try {
      final List files = await MikrotikClient.printData(
        commands: ["/file/print"],
        fields: _filesFields,
        tag: "router_files_list",
      );

      final result = files
          .whereType<Map>()
          .map((e) => RouterFileModel.fromMikrotik(e))
          .where((f) => f.isBackup || f.isExport)
          .toList();

      return AppResponse(status: true, message: "done", data: result);
    } catch (e) {
      return AppResponse(status: false, message: e.toString());
    }
  }

  /// إنشاء نسخة إعدادات كاملة (binary backup) داخل الراوتر.
  static Future<AppResponse<void>> createBackup({required String name}) async {
    try {
      await MikrotikClient.fetch(
        command: ["/system/backup/save"],
        params: {"name": name},
        customTag: "router_backup_save",
      );
      return AppResponse(
        status: true,
        message: "تم إنشاء النسخة الاحتياطية على الراوتر: $name.backup",
      );
    } catch (e) {
      return AppResponse(status: false, message: e.toString());
    }
  }

  /// إنشاء تصدير نصي للإعدادات (‎.rsc‎) داخل الراوتر.
  static Future<AppResponse<void>> createExport({
    required String name,
    bool showSensitive = false,
  }) async {
    try {
      final params = <String, String>{"file": name};
      if (showSensitive) params["show-sensitive"] = "";

      await MikrotikClient.fetch(
        command: ["/export"],
        params: params,
        customTag: "router_backup_export",
      );
      return AppResponse(
        status: true,
        message: "تم إنشاء ملف التصدير على الراوتر: $name.rsc",
      );
    } catch (e) {
      return AppResponse(status: false, message: e.toString());
    }
  }

  /// تنزيل ملف من الراوتر إلى الهاتف.
  ///
  /// الأولوية لخدمة الويب (www) لأنها تنقل الملفات الثنائية كما هي،
  /// وعند تعطّلها نحاول القراءة النصية عبر API (مناسبة لملفات .rsc).
  static Future<AppResponse<List<int>>> downloadFile(RouterFileModel file) async {
    try {
      final httpBytes = await MikrotikClient.httpDownloadFile(file.name);
      if (httpBytes.isNotEmpty) {
        return AppResponse(status: true, message: "تم التنزيل عبر خدمة الويب", data: httpBytes);
      }
    } catch (httpError) {
      if (file.isExport) {
        try {
          final text = await _readTextFile(file);
          if (text != null && text.isNotEmpty) {
            return AppResponse(status: true, message: "تم التنزيل عبر API", data: utf8.encode(text));
          }
        } catch (_) {
          // نكمل إلى رسالة الخطأ أدناه
        }
      }
      return AppResponse(
        status: false,
        message: "تعذّر تنزيل الملف من الراوتر.\n"
            "فعّل خدمة الويب على الراوتر ثم أعد المحاولة:  /ip service enable www\n"
            "($httpError)",
      );
    }
    return AppResponse(status: false, message: "الملف الذي تم تنزيله فارغ.");
  }

  /// قراءة ملف نصي عبر API بالتقطيع (RouterOS v7.9+)، مع بديل للملفات الصغيرة.
  static Future<String?> _readTextFile(RouterFileModel file) async {
    const chunkSize = 8192;
    const maxBytes = 4 * 1024 * 1024; // حد أمان 4MB

    final buffer = StringBuffer();
    var offset = 0;

    try {
      while (offset < maxBytes) {
        final response = await MikrotikClient.fetch(
          command: ["/file/read"],
          params: {
            "file": file.name,
            "offset": "$offset",
            "chunk-size": "$chunkSize",
          },
          customTag: "router_file_read",
        );

        final chunk = _extractChunk(response);
        if (chunk == null || chunk.isEmpty) break;

        buffer.write(chunk);
        offset += chunk.length;
        if (chunk.length < chunkSize) break;
      }
    } catch (_) {
      // إصدارات قديمة لا تدعم /file/read — نجرّب القراءة المباشرة
    }

    if (buffer.isEmpty) {
      try {
        final small = await MikrotikClient.printData(
          commands: ["/file/get"],
          conditions: ["=.id=${file.id}"],
          fields: "contents",
          tag: "router_file_get",
        );
        if (small.isNotEmpty && small.first is Map) {
          final contents = (small.first as Map)["contents"];
          if (contents != null && contents.toString().isNotEmpty) {
            return contents.toString();
          }
        }
      } catch (_) {
        // لا شيء
      }
    }

    return buffer.isEmpty ? null : buffer.toString();
  }

  static String? _extractChunk(List response) {
    for (final item in response) {
      if (item is Map) {
        for (final key in ["data", "ret", "contents"]) {
          final value = item[key];
          if (value != null && value.toString().isNotEmpty) return value.toString();
        }
      } else if (item is String && item.isNotEmpty) {
        return item;
      }
    }
    return null;
  }

  /// استعادة نسخة binary موجودة على الراوتر (يعيد التشغيل غالبًا بعدها).
  static Future<AppResponse<void>> restoreBackupFile(String fileName) async {
    try {
      await MikrotikClient.fetch(
        command: ["/system/backup/load"],
        params: {"name": fileName},
        customTag: "router_backup_load",
      );
      return AppResponse(
        status: true,
        message: "تم إرسال أمر الاستعادة. قد يعيد الراوتر التشغيل تلقائيًا.",
      );
    } catch (e) {
      return AppResponse(status: false, message: e.toString());
    }
  }

  /// استيراد ملف تصدير نصي (.rsc) موجود على الراوتر.
  static Future<AppResponse<void>> importExportFile(String fileName) async {
    try {
      await MikrotikClient.fetch(
        command: ["/import"],
        params: {"file-name": fileName},
        customTag: "router_backup_import",
      );
      return AppResponse(status: true, message: "تم استيراد الإعدادات من $fileName");
    } catch (e) {
      return AppResponse(status: false, message: e.toString());
    }
  }

  /// حذف ملف من ذاكرة الراوتر.
  static Future<AppResponse<void>> deleteFile(RouterFileModel file) async {
    try {
      await MikrotikClient.removeById(command: "/file/remove", id: file.id);
      return AppResponse(status: true, message: "تم حذف الملف من الراوتر");
    } catch (e) {
      return AppResponse(status: false, message: e.toString());
    }
  }

  /// رفع ملف نسخة من الهاتف إلى الراوتر عبر FTP (لاستعادته لاحقًا).
  static Future<AppResponse<void>> uploadFile({
    required String fileName,
    required List<int> bytes,
  }) async {
    try {
      await MikrotikClient.ftpUploadFile(fileName: fileName, bytes: bytes);
      return AppResponse(status: true, message: "تم رفع الملف إلى الراوتر بنجاح");
    } catch (e) {
      return AppResponse(
        status: false,
        message: "تعذّر رفع الملف عبر FTP.\n"
            "فعّل خدمة FTP على الراوتر:  /ip service enable ftp\n"
            "($e)",
      );
    }
  }

  /// اسم مقترح يعتمد على التاريخ والوقت.
  static String suggestedName({String prefix = "mikronet"}) {
    final now = DateTime.now();
    String two(int value) => value.toString().padLeft(2, '0');
    return "${prefix}_${now.year}${two(now.month)}${two(now.day)}_${two(now.hour)}${two(now.minute)}";
  }
}
