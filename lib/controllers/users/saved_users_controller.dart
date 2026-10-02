import 'package:get/get.dart';
import 'package:mikronet/api/users/saved_users_api.dart';
import '../dialog_helper.dart';
import '/models/users_model.dart';
import '/models/response.dart';

class SavedUsersController extends GetxController {
  RxString filter = "ALL".obs;
  
  RxList<SavedUserModel> allDevices = <SavedUserModel>[].obs;
  RxList<SavedUserModel> filteredDevices = <SavedUserModel>[].obs;
  RxString searchQuery = "".obs;

  RxBool isLoading = true.obs;

  @override
  void onInit() {
    super.onInit();
    fetchDevices();
  }

  void goBack() {
    Get.back();
  }

  void setFilter(String key) {
    filter.value = key;
    _applyFilter();
  }
  void setSearch(String query) {
    searchQuery.value = query;
    _applyFilter();
  }

  void _applyFilter() {
    var result =
      switch (filter.value) {
        "SAVED"   => allDevices.where((d) => d.label.isNotEmpty).toList(),
        "UNSAVED"    => allDevices.where((d) => d.label == "Unknown").toList(),
        "BLOCKED" => allDevices.where((d) => d.type == UserType.blocked).toList(),
        "FREE"    => allDevices.where((d) => d.type == UserType.bypassed).toList(),
        _         => allDevices, 
      }
    ;
    if (searchQuery.value.isNotEmpty) {
      String query = searchQuery.value.toLowerCase();
      result = result.where((d) => 
        d.label.toLowerCase().contains(query) || 
        d.srcAddress.toLowerCase().contains(query) ||
        d.macAddress.toLowerCase().contains(query)
        
      ).toList();
    }

    filteredDevices.assignAll(result);
  }


  /// تأكيد الحظر
  void confirmBlock(SavedUserModel device) {
    showConfirmDialog(
      message: "هل أنت متأكد من حظر هذا الجهاز؟ لن يتمكن من الوصول للشبكة.",
      onConfirm: () {
        _executeBlock(device);
      },
    );
  }

  /// تأكيد فك الحظر
  void confirmUnblock(SavedUserModel device) {
    showConfirmDialog(
      message: "هل تريد فك الحظر عن هذا الجهاز والسماح له بالاتصال مجدداً؟",
      onConfirm: () {
        _executeRegular(device);
      },
    );
  }

  /// تأكيد تحويل لمجاني
  void confirmMakeFree(SavedUserModel device) {
    showConfirmDialog(
      message: "هل أنت متأكد من منح هذا الجهاز وصولاً مجانياً للشبكة؟",
      onConfirm: () {
        _executeBypass(device);
      },
    );
  }

  /// تأكيد الحذف
  void confirmDelete(SavedUserModel device) {
    showConfirmDialog(
      message: "هل أنت متأكد من حذف هذا الجهاز من النظام نهائياً؟",
      onConfirm: () {
        _executeDelete(device);
      },
    );
  }

  /// إضافة جهاز يدوياً
  Future<void> addManualDevice({required String name, required String ip, required String mac, required UserType status}) async {
    showLoadingDialog();
    var response = await SavedUsersApi.saveUser(macAddress: mac, label: name, toAddress: ip,type: status);

    if (Get.isDialogOpen ?? false) Get.back();

    if (response.status) {
      fetchDevices(); 
      showMsgDialog(message: response.message,type: MsgType.success);
    } else {
      showMsgDialog(message: response.message,type: MsgType.error);
    }
  }

  /// جلب البيانات
  Future<void> fetchDevices() async {
    isLoading.value = true;
    try {
      AppResponse<List<SavedUserModel>> response = await SavedUsersApi.getAlISavedUsers();
      isLoading.value = false;
      if (response.status && response.data != null) {
        allDevices.assignAll(response.data!);
        _applyFilter();
      } else {
        showMsgDialog(message: response.message);
      }
    } catch (e) {
        showMsgDialog(message: "Error fetching devices: $e");
    } 

  }

  Future<void> executeRename(SavedUserModel device, String newName) async {
    if (newName.isEmpty || newName == device.label) return;
    showLoadingDialog();
    AppResponse<void> response = await SavedUsersApi.renameSavedUser(device, newName);
    
    if (Get.isDialogOpen ?? false) Get.back();

    if (response.status) {
      int index = allDevices.indexWhere((e) => e.id == device.id);
      if (index != -1) {
        allDevices[index] = SavedUserModel(
          id: device.id, srcAddress: device.srcAddress, dstAddress: device.dstAddress,
          macAddress: device.macAddress, server: device.server, type: device.type, label: newName
        );
      }
      allDevices.refresh();
      _applyFilter();
      showMsgDialog(message: response.message,type: MsgType.msg);
    } else {
      showMsgDialog(message: response.message,type: MsgType.error);
    }
  }

  
  Future<void> _executeBlock(SavedUserModel device) async {
    
    AppResponse<void> response = await SavedUsersApi.blockSavedUser(device);
    if (Get.isDialogOpen ?? false) Get.back();
    if (response.status) {
      fetchDevices(); 
      showMsgDialog(message: response.message,type: MsgType.success);
    } else {
      showMsgDialog(message: response.message);
    }
  }
  Future<void> _executeBypass(SavedUserModel device) async {
    //showLoadingDialog();
    AppResponse<void> response = await SavedUsersApi.bypassSavedUser(device);
    if (Get.isDialogOpen ?? false) Get.back();
    if (response.status) {
      fetchDevices(); 
      showMsgDialog(message: response.message,type: MsgType.success);
    } else {
      showMsgDialog(message: response.message);
    }
  }
  Future<void> _executeRegular(SavedUserModel device) async {
    showLoadingDialog();
    AppResponse<void> response = await SavedUsersApi.regularSavedUser(device);
    if (Get.isDialogOpen ?? false) Get.back();
    if (response.status) {
      fetchDevices(); 
      showMsgDialog(message: response.message,type: MsgType.success);
    } else {
      showMsgDialog(message: response.message);
    }
  }
  
  Future<void> _executeDelete(SavedUserModel device) async {
    showLoadingDialog();
    AppResponse<void> response = await SavedUsersApi.removeSavedUser(device);
    
    if (Get.isDialogOpen ?? false) Get.back();

    if (response.status) {
      fetchDevices();
      showMsgDialog(message: response.message,type: MsgType.success);
    } else {
      showMsgDialog(message: response.message,type: MsgType.error);
    }
  }


}