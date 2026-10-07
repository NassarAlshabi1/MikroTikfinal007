import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '/api/users/host_users_api.dart';
import '../dialog_helper.dart'; // تأكد من المسار
import '/models/users_model.dart';
import '/models/response.dart';

class HostUsersController extends GetxController {
  RxList<HostUserModel> hosts = <HostUserModel>[].obs;
  RxBool isLoading = true.obs;

  @override
  void onInit() {
    super.onInit();
    fetchHosts();
  }

  Future<void> fetchHosts() async {
    isLoading.value = true;
    try {
      var response = await HostUsersApi.getAllHosts();
      isLoading.value = false;
      if (response.status) {
        hosts.assignAll(response.data ?? []);
      } else {
        showMsgDialog(message: response.message);
      }
    } catch (e) {
      showMsgDialog(message: "خطأ في الاتصال: $e");
    } 
  }

  // --- العمليات الأساسية ---

  // 1. تسمية الجهاز (Labeling)
  Future<void> renameDevice(HostUserModel host, String newName) async {
    if (newName.isEmpty) return;
    showLoadingDialog();
    var res = await HostUsersApi.renameHostUser(host,newName);
    if(Get.isDialogOpen ?? false) Get.back();
    if (res.status) fetchHosts();
  }

  // 2. حظر الجهاز (Blocking)
  Future<void> toggleBlock(HostUserModel host) async {
    bool isBlocked = host.type == UserType.blocked;
    showLoadingDialog();
    AppResponse<void> res;
    if (isBlocked) {
      res = await HostUsersApi.regularHostUser(host); // إزالة الحظر من IP-Binding
    } else {
      res = await HostUsersApi.blockHostUser(host);
    }
    if(Get.isDialogOpen ?? false) Get.back();
    if (res.status) fetchHosts();
  }

  // 3. التحويل لوصول مجاني (Bypass)
  Future<void> makeBypass(HostUserModel host) async {
    showLoadingDialog();
    var res = await HostUsersApi.bypasskHostUser(host);
    _hideLoading();
    if (res.status) fetchHosts();
  }

  // ميثودات مساعدة لواجهة المستخدم
  void _showLoading() => Get.dialog(const Center(child: CircularProgressIndicator()), barrierDismissible: false);
  void _hideLoading() { if (Get.isDialogOpen ?? false) Get.back(); }
}