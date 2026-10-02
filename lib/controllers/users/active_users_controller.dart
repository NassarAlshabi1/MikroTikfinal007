import 'package:get/get.dart';
import 'package:mikronet/api/users/active_users_api.dart';
import '../dialog_helper.dart'; 
import '/models/users_model.dart';
import '/models/response.dart';

class ActiveUsersController extends GetxController {
  RxList<ActiveUserModel> actives = <ActiveUserModel>[].obs;
  RxBool isLoading = true.obs;

  @override
  void onInit() {
    super.onInit();
    fetchActiveSessions();
  }

  // جلب البيانات من السيرفر
  Future<void> fetchActiveSessions() async {
    isLoading.value = true;
    try {
      AppResponse<List<ActiveUserModel>> response = await ActiveUsersApi.getAllActive();
      isLoading.value = false;
      if (response.status) {
        actives.assignAll(response.data ?? []);
      } else {
        showMsgDialog(message: response.message);
      }
    } catch (e) {
      showMsgDialog(message: "خطأ في الاتصال: $e");
    }
  }

  /* ---------------- الاجراءات والعمليات ---------------- */

  Future<void> disconnect(ActiveUserModel user) async {
    showLoadingDialog();
    var res = await ActiveUsersApi.removeOneActive(user);
    hideDialog();
    if (res.status) fetchActiveSessions();
  }

  Future<void> rename(ActiveUserModel user, String newName) async {
    if (newName.isEmpty) return;
    showLoadingDialog();
    var res = await ActiveUsersApi.renameActiveUser(user,newName);
   
    hideDialog();
    if (res.status) fetchActiveSessions();
  }

  Future<void> block(ActiveUserModel user) async {
    showLoadingDialog();
    var res = await ActiveUsersApi.blockActiveUser(user);
    hideDialog();
    if (res.status) {
      await ActiveUsersApi.removeOneActive(user);
      fetchActiveSessions();
    }
  }

  Future<void> makeFree(ActiveUserModel user) async {
    showLoadingDialog();
    var res = await ActiveUsersApi.bypassActiveUser(user);
    hideDialog();
    if (res.status) fetchActiveSessions();
  }

  }