import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:file_picker/file_picker.dart';

import '/api/backup_api.dart';
import '/controllers/dialog_helper.dart';

class BackupRestoreController extends GetxController {
  final nameCtrl = TextEditingController();

  // حالة حقول الاختيار (Checkboxes)
  RxBool isLoginsChecked = true.obs;
  RxBool isTemplatesChecked = true.obs;
  RxBool isBatchesChecked = true.obs;

  @override
  void onInit() {
    super.onInit();
    nameCtrl.text = "MikroNet_${DateTime.now().year}_${DateTime.now().month}_${DateTime.now().day}";
  }

  Future<void> createBackup() async {
    if (nameCtrl.text.trim().isEmpty) {
      showMsgDialog(message: "يرجى إدخال اسم النسخة الاحتياطية");
      return;
    }

    showLoadingDialog();
    
    var response = await BackupApi.backup();
    hideDialog();

    if (response.status && response.data != null) {
      try {
        Uint8List dbBytes = response.data as Uint8List;
        
        String? outputFile = await FilePicker.platform.saveFile(
          dialogTitle: 'حفظ النسخة الاحتياطية',
          fileName: '${nameCtrl.text.trim()}.db', // حفظ بصيغة db
          type: FileType.custom,
          allowedExtensions: ['db'],
          bytes: dbBytes, 
        );

        if (outputFile != null) {
          showMsgDialog(message: "تم حفظ النسخة الاحتياطية بنجاح!");
        }
      } catch (e) {
        showMsgDialog(message: "حدث خطأ أثناء الحفظ:\n${e.toString()}");
      }
    } else {
      showMsgDialog(message: response.message);
    }
  }

  Future<void> restoreBackup() async {
    try {
      
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        withData: true, 
      );

      if (result != null && result.files.single.bytes != null && result.files.single.name.endsWith(".db")) {
        showLoadingDialog();

        Uint8List backupBytes = result.files.single.bytes!;
        var response = await BackupApi.restore(backupBytes);
        
        hideDialog();
        showMsgDialog(message: response.message);
        
      }else {
      showMsgDialog(message: "حدث خطأ أثناء استعادة الملف:\n ملف غير صالح",type: MsgType.error);

      }
    } catch (e) {
      hideDialog();
      showMsgDialog(message: "حدث خطأ أثناء استعادة الملف:\n${e.toString()}",type: MsgType.success);
    }
  }

  @override
  void onClose() {
    nameCtrl.dispose();
    super.onClose();
  }
}