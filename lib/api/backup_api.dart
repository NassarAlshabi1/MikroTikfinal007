import 'dart:io';
import 'dart:typed_data';
import 'package:sqflite/sqflite.dart';

import '../models/response.dart';

// (هذا الكلاس للتوضيح فقط، افترض أنه موجود لديك مسبقاً في مشروعك)
class BackupApi {
  // اسم قاعدة البيانات كما ورد في الكود الخاص بك
  static const String _dbName = 'mikrotik.db';

  // ==========================================
  // 1. دالة التصدير (Backup)
  // تقوم بقراءة ملف قاعدة البيانات بالكامل وإرجاعه كـ Uint8List
  // ==========================================
  static Future<AppResponse<Uint8List>> backup() async {
    try {
      // الحصول على مسار قاعدة البيانات الأساسية
      final dbPath = await getDatabasesPath();
      final dbFile = File('$dbPath/$_dbName');

      // التأكد من وجود القاعدة أصلاً
      if (!await dbFile.exists()) {
        return AppResponse(
          status: false, 
          message: 'قاعدة البيانات غير موجودة لنسخها.'
        );
      }

      // قراءة الملف بالكامل كـ Bytes (بنفس فكرة dbFile.copy لكن للذاكرة)
      Uint8List dbBytes = await dbFile.readAsBytes();

      return AppResponse(
        status: true,
        message: 'تم تجهيز بيانات النسخة الاحتياطية بنجاح.',
        data: dbBytes, // إرجاع البيانات هنا
      );
    } catch (e) {
      return AppResponse(
        status: false, 
        message: 'حدث خطأ أثناء قراءة قاعدة البيانات: ${e.toString()}'
      );
    }
  }

  static Future<AppResponse<void>> restore(Uint8List backupBytes) async {
    try {
      // الحصول على مسار قاعدة البيانات الأساسية
      final dbPath = await getDatabasesPath();
      final dbFile = File('$dbPath/$_dbName');
      
      await dbFile.writeAsBytes(backupBytes, flush: true);

      return AppResponse(
        status: true,
        message: 'تمت استعادة قاعدة البيانات بنجاح.',
      );
    } catch (e) {
      return AppResponse(
        status: false, 
        message: 'حدث خطأ أثناء استعادة قاعدة البيانات: ${e.toString()}'
      );
    }
  }
}