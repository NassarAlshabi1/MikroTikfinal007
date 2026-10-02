import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '/api/router_backup_api.dart';
import '/controllers/dialog_helper.dart';
import '../helpers/confirm_dialog.dart';

/// متحكم النسخ الاحتياطي الحقيقي للراوتر.
class RouterBackupController extends GetxController {
  final nameCtrl = TextEditingController();
  final fileCtrl = TextEditingController();

  final RxList<RouterFileModel> files = <RouterFileModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool isBusy = false.obs;
  final RxString statusMessage = "".obs;

  @override
  void onInit() {
    super.onInit();
    nameCtrl.text = RouterBackupApi.suggestedName();
    loadFiles();
  }

  Future<void> loadFiles() async {
    isLoading.value = true;
    final response = await RouterBackupApi.listBackupFiles();
    isLoading.value = false;

    if (response.status && response.data != null) {
      files.assignAll(response.data!);
      statusMessage.value = files.isEmpty
          ? "لا توجد نسخ على الراوتر بعد."
          : "عدد الملفات: ${files.length}";
    } else {
      statusMessage.value = response.message;
    }
  }

  String get _safeName {
    final raw = nameCtrl.text.trim().isEmpty
        ? RouterBackupApi.suggestedName()
        : nameCtrl.text.trim();
    // أسماء الملفات على الراوتر آمنة بـ ASCII فقط
    return raw.replaceAll(RegExp(r'[^A-Za-z0-9_\-]'), '_');
  }

  Future<void> createBackup() async {
    if (isBusy.value) return;
    isBusy.value = true;
    showLoadingDialog();

    final response = await RouterBackupApi.createBackup(name: _safeName);

    hideDialog();
    isBusy.value = false;

    await showMsgDialog(
      message: response.message,
      type: response.status ? MsgType.success : MsgType.error,
    );
    if (response.status) loadFiles();
  }

  Future<void> createExport() async {
    if (isBusy.value) return;
    isBusy.value = true;
    showLoadingDialog();

    final response = await RouterBackupApi.createExport(name: _safeName);

    hideDialog();
    isBusy.value = false;

    await showMsgDialog(
      message: response.message,
      type: response.status ? MsgType.success : MsgType.error,
    );
    if (response.status) loadFiles();
  }

  Future<void> downloadFile(RouterFileModel file) async {
    if (isBusy.value) return;
    isBusy.value = true;
    showLoadingDialog();

    final response = await RouterBackupApi.downloadFile(file);

    hideDialog();
    isBusy.value = false;

    if (!response.status || response.data == null) {
      await showMsgDialog(message: response.message, type: MsgType.error);
      return;
    }

    try {
      final bytes = Uint8List.fromList(response.data!);
      final savedPath = await FilePicker.platform.saveFile(
        dialogTitle: 'حفظ نسخة الراوتر',
        fileName: file.name,
        type: FileType.any,
        bytes: bytes,
      );

      if (savedPath != null) {
        await showMsgDialog(
          message: "تم حفظ ${file.name} في: $savedPath",
          type: MsgType.success,
        );
      }
    } catch (e) {
      await showMsgDialog(
        message: "تم التنزيل لكن فشل الحفظ:\n$e",
        type: MsgType.error,
      );
    }
  }

  Future<void> restoreFile(RouterFileModel file) async {
    final confirmed = await confirmAction(
      file.isBackup
          ? "سيتم استعادة الإعدادات من:\n${file.name}\n\nقد يعيد الراوتر التشغيل تلقائيًا. متابعة؟"
          : "سيتم استيراد الإعدادات من:\n${file.name}\n\nمتابعة؟",
    );
    if (!confirmed) return;

    isBusy.value = true;
    showLoadingDialog();

    final response = file.isBackup
        ? await RouterBackupApi.restoreBackupFile(file.name)
        : await RouterBackupApi.importExportFile(file.name);

    hideDialog();
    isBusy.value = false;

    await showMsgDialog(
      message: response.message,
      type: response.status ? MsgType.success : MsgType.error,
    );
  }

  Future<void> deleteFile(RouterFileModel file) async {
    final confirmed = await confirmAction(
      "حذف الملف من ذاكرة الراوتر؟\n${file.name}",
    );
    if (!confirmed) return;

    isBusy.value = true;
    final response = await RouterBackupApi.deleteFile(file);
    isBusy.value = false;

    await showMsgDialog(
      message: response.message,
      type: response.status ? MsgType.success : MsgType.error,
    );
    if (response.status) loadFiles();
  }

  /// رفع ملف نسخة من الهاتف إلى الراوتر عبر FTP ثم استعادته لاحقًا.
  Future<void> uploadFromPhone() async {
    if (isBusy.value) return;

    try {
      final picked = await FilePicker.platform.pickFiles(
        type: FileType.any,
        withData: true,
      );

      final pickedFile = picked?.files.single;
      final bytes = pickedFile?.bytes;
      if (pickedFile == null || bytes == null) return;

      isBusy.value = true;
      showLoadingDialog();

      final response = await RouterBackupApi.uploadFile(
        fileName: pickedFile.name,
        bytes: bytes,
      );

      hideDialog();
      isBusy.value = false;

      await showMsgDialog(
        message: response.message,
        type: response.status ? MsgType.success : MsgType.error,
      );
      if (response.status) loadFiles();
    } catch (e) {
      hideDialog();
      isBusy.value = false;
      await showMsgDialog(message: e.toString(), type: MsgType.error);
    }
  }

  @override
  void onClose() {
    nameCtrl.dispose();
    fileCtrl.dispose();
    super.onClose();
  }
}
