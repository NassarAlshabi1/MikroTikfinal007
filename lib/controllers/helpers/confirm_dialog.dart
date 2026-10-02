import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// نافذة تأكيد بسيطة تُعيد `true` عند ضغط المستخدم على «تأكيد».
///
/// (مستقلة عن `showConfirmDialog` الموجود في dialog_helper لأن ذاك يتطلب onConfirm).
Future<bool> confirmAction(String message) async {
  final result = await Get.dialog<bool>(
    Directionality(
      textDirection: TextDirection.rtl,
      child: AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: const Row(
          children: [
            Icon(Icons.help_outline_rounded, color: Color(0xFFF59E0B)),
            SizedBox(width: 10),
            Text(
              "تأكيد العملية",
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17),
            ),
          ],
        ),
        content: Text(
          message,
          style: const TextStyle(color: Color(0xFF475569), height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text(
              "إلغاء",
              style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
            ),
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E3A8A),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text("تأكيد", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    ),
  );

  return result == true;
}
