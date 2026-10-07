import 'package:get/get.dart';

import '../../api/expired_users_api.dart';
import '../../controllers/dialog_helper.dart';
import '../helpers/confirm_dialog.dart';

/// متحكم "المستخدمون المنتهون": فحص ذكي (uptime ضد limit-uptime) وحذف المؤهلين فقط.
class ExpiredUsersController extends GetxController {
  final Rx<ExpiredUsersScanResult?> scanResult = Rx<ExpiredUsersScanResult?>(null);
  final RxBool isLoading = true.obs;
  final RxBool isDeleting = false.obs;
  final RxString errorMessage = "".obs;

  /// إضافة من انتهى رصيد بياناته فقط (مع بقاء مدة صالحة) — مُعطّل افتراضيًا.
  final RxBool includeBytesOnly = false.obs;

  /// تحديد المستخدمين: معرّف المستخدم ← مُحدد؟
  final RxMap<String, bool> selection = <String, bool>{}.obs;

  @override
  void onInit() {
    super.onInit();
    scan();
  }

  Future<void> scan() async {
    isLoading.value = true;
    errorMessage.value = "";
    selection.clear();

    final response = await ExpiredUsersApi.scan();

    isLoading.value = false;

    if (!response.status || response.data == null) {
      errorMessage.value = response.message;
      scanResult.value = null;
      return;
    }

    scanResult.value = response.data;
    for (final user in displayed) {
      selection[user.id] = true; // المُحدد افتراضيًا: من استهلك مدته كاملة
    }
  }

  /// من انتهى رصيده فقط (يظهر عند تفعيل الخيار).
  List<ExpiredUserCandidate> get bytesOnlyUsers {
    final result = scanResult.value;
    if (result == null) return const [];
    return result.stillRunning.where((user) => user.bytesExhausted).toList();
  }

  /// القائمة المعروضة حاليًا.
  List<ExpiredUserCandidate> get displayed {
    final result = scanResult.value;
    if (result == null) return const [];
    return [
      ...result.exhausted,
      if (includeBytesOnly.value) ...bytesOnlyUsers,
    ];
  }

  List<ExpiredUserCandidate> get selectedUsers =>
      displayed.where((user) => selection[user.id] == true).toList();

  int get selectedCount => selectedUsers.length;

  void toggleUser(String id, bool? value) {
    selection[id] = value ?? false;
  }

  void toggleAll(bool? value) {
    final flag = value ?? false;
    for (final user in displayed) {
      selection[user.id] = flag;
    }
  }

  bool get isAllSelected {
    final list = displayed;
    if (list.isEmpty) return false;
    return list.every((user) => selection[user.id] == true);
  }

  void setIncludeBytesOnly(bool value) {
    includeBytesOnly.value = value;
    // تحديث التحديد للعناصر الجديدة
    for (final user in displayed) {
      selection.putIfAbsent(user.id, () => true);
    }
  }

  /// حذف المحددين فقط (بعد تأكيد).
  Future<void> deleteSelected() async {
    final users = selectedUsers;
    if (users.isEmpty) {
      await showMsgDialog(message: "لم تحدد أي مستخدم للحذف", type: MsgType.warning);
      return;
    }

    final confirmed = await _confirmDelete(users.length);
    if (!confirmed) return;

    isDeleting.value = true;
    showLoadingDialog();

    final response = await ExpiredUsersApi.deleteUsers(users);

    hideDialog();
    isDeleting.value = false;

    await showMsgDialog(
      message: response.message,
      type: response.status ? MsgType.success : MsgType.error,
    );

    if (response.status) await scan();
  }

  Future<bool> _confirmDelete(int count) {
    return confirmAction(
      "سيتم حذف $count مستخدمًا استهلكوا مدتهم كاملة من User Manager.\n\n"
      "لا يمكن التراجع عن العملية. متابعة؟",
    );
  }
}
