import 'package:get/get.dart';
import 'package:mikronet/api/users/active_users_api.dart';
import '../dialog_helper.dart';
import '/models/users_model.dart';
import '/models/response.dart';

class ActiveUsersController extends GetxController {
  final RxList<ActiveUserModel> actives = <ActiveUserModel>[].obs;
  final RxBool isLoading = true.obs;
  final RxString loadError = ''.obs;

  @override
  void onInit() {
    super.onInit();
    fetchActiveSessions();
  }

  Future<void> fetchActiveSessions() async {
    isLoading.value = true;
    loadError.value = '';
    try {
      final AppResponse<List<ActiveUserModel>> response =
          await ActiveUsersApi.getAllActive();
      if (response.status && response.data != null) {
        actives.assignAll(response.data!);
      } else {
        actives.clear();
        loadError.value = response.message.trim().isEmpty
            ? 'تعذّر جلب الجلسات النشطة من الراوتر.'
            : response.message;
      }
    } catch (error) {
      actives.clear();
      loadError.value = 'تعذّر الاتصال بالراوتر: $error';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> disconnect(ActiveUserModel user) async {
    showLoadingDialog();
    final result = await ActiveUsersApi.removeOneActive(user);
    hideDialog();
    if (result.status) await fetchActiveSessions();
  }

  Future<void> rename(ActiveUserModel user, String newName) async {
    if (newName.trim().isEmpty) return;
    showLoadingDialog();
    final result = await ActiveUsersApi.renameActiveUser(user, newName.trim());
    hideDialog();
    if (result.status) await fetchActiveSessions();
  }

  Future<void> block(ActiveUserModel user) async {
    showLoadingDialog();
    final result = await ActiveUsersApi.blockActiveUser(user);
    hideDialog();
    if (result.status) {
      await ActiveUsersApi.removeOneActive(user);
      await fetchActiveSessions();
    }
  }

  Future<void> makeFree(ActiveUserModel user) async {
    showLoadingDialog();
    final result = await ActiveUsersApi.bypassActiveUser(user);
    hideDialog();
    if (result.status) await fetchActiveSessions();
  }
}
