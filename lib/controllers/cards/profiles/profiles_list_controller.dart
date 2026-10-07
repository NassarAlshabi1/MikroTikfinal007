import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mikronet/api/cards_api.dart';
import 'package:mikronet/core/app_pages.dart';
import 'package:mikronet/models/cards_model.dart';
import '/controllers/dialog_helper.dart';
import '/api/profiles_api.dart';
import '/models/profiles_model.dart';


class ProfilesListController extends GetxController {
  RxList<ProfilesModel> packages = <ProfilesModel>[].obs;
  RxBool isLoading = true.obs;
  int _requestCounter = 0;

  // الحقول
  final nameCtrl = TextEditingController();
  final priceCtrl = TextEditingController();
  final daysCtrl = TextEditingController();
  final hoursCtrl = TextEditingController();
  final uptimeDaysCtrl = TextEditingController();
  final uptimeHoursCtrl = TextEditingController();
  final gigasCtrl = TextEditingController();
  final megasCtrl = TextEditingController();
  final speedCtrl = TextEditingController();

  List<CustomerModel> customers = <CustomerModel>[];

  @override
  void onInit() {
    super.onInit();
    init();
  }

  Future<void> init()async{
    await getCustomers();
    await fetchPackages();
  }

  Future<void> getCustomers()async{
    var response=await CardsApi.getCustomers();
    if (response.status) {
      customers=response.data!;
    }
    else{ showMsgDialog(message: response.message); }
  }

  // دالة تجهيز الحقول عند الإضافة أو التعديل
  void prepareSheet({ProfilesModel? item}) {
    if (item != null) {
      nameCtrl.text = item.name;
      priceCtrl.text = item.price;
      speedCtrl.text = item.speed;

      // 1. معالجة الصلاحية
      var vTime = MikrotikTimeHelper.fromString(item.validity);
      daysCtrl.text = vTime.days.toString();
      hoursCtrl.text = vTime.hours.toString();

      // 2. معالجة الـ Uptime
      var uTime = MikrotikTimeHelper.fromString(item.uptime);
      uptimeDaysCtrl.text = uTime.days.toString();
      uptimeHoursCtrl.text = uTime.hours.toString();

      // 3. معالجة الرصيد (الحل الجديد)
      var dataInfo = MikrotikDataHelper.fromString(item.palance);
      gigasCtrl.text = dataInfo.gigas.toString();
      megasCtrl.text = dataInfo.megas.toString();
      
    } else {
      _clearAll();
    }
  }

  void _clearAll() {
    nameCtrl.clear(); priceCtrl.clear(); daysCtrl.clear(); hoursCtrl.clear();
    uptimeDaysCtrl.clear(); uptimeHoursCtrl.clear();
    gigasCtrl.clear(); megasCtrl.clear(); speedCtrl.clear();
  }

  Future<void> executeSave({int? index}) async {
    if (nameCtrl.text.isEmpty) {
      showMsgDialog(message: "اسم الباقة مطلوب");
      return;
    }

    // تجميع البيانات باستخدام المساعدات
    String validity = MikrotikTimeHelper(
      days: int.tryParse(daysCtrl.text) ?? 0,
      hours: int.tryParse(hoursCtrl.text) ?? 0
    ).toMikrotikString();

    String uptime = MikrotikTimeHelper(
      days: int.tryParse(uptimeDaysCtrl.text) ?? 0,
      hours: int.tryParse(uptimeHoursCtrl.text) ?? 0
    ).toMikrotikString();

    // تجميع الرصيد
    String palance = MikrotikDataHelper(
      gigas: int.tryParse(gigasCtrl.text) ?? 0,
      megas: int.tryParse(megasCtrl.text) ?? 0
    ).toMikrotikString();

    final data = {
      "name": nameCtrl.text, 
      "price": priceCtrl.text.isEmpty?'0':priceCtrl.text,
      "validity": validity, 
      "uptime": uptime,
      "palance": palance, 
      "speed": speedCtrl.text.trim().isEmpty?'0/0':speedCtrl.text.toUpperCase().trim().toUpperCase(),
      "customer": customers.first.name, 
      "users": "1",
    };
    // print('\n');print('\n');print('\n');print('\n');print('\n');
    // print(data);
    // print('\n');print('\n');print('\n');print('\n');print('\n');

    Get.back();
    Get.dialog(const Center(child: CircularProgressIndicator()), barrierDismissible: false);

    var response = (index != null )
        ? await ProfilesApi.profileEdit(packages[index].name, data)
        : await ProfilesApi.addOneProfile(data);

    if (Get.isDialogOpen ?? false) Get.back();
    if (response.status) { fetchPackages(); showMsgDialog(message: "تم الحفظ بنجاح"); }
    else { showMsgDialog(message: response.message); }
  }

  // ... (fetchPackages و confirmDelete تبقى كما هي)
  Future<void> fetchPackages() async {
    final currentId = ++_requestCounter;
    isLoading.value = true;
    try {
      var response = await ProfilesApi.getProfiles();
      if (currentId == _requestCounter && response.status) {
        packages.assignAll(response.data!);
      }
    } finally {
      if (currentId == _requestCounter) isLoading.value = false;
    }
  }

  void confirmDelete(int index) {
    showConfirmDialog(message: "حذف (${packages[index].name})؟", onConfirm: () {
      _executeDelete(index);
    });
  }
  void _executeDelete(int index)async{
    
    showLoadingDialog();
    var response = await ProfilesApi.deleteProfile(packages[index].name);
    hideDialog();
    if (response.status) {
        packages.removeAt(index);
        showMsgDialog(message: response.message,type: MsgType.success);
    }else{
        showMsgDialog(message: response.message,type: MsgType.error);
    }
  }
  void goToAddProfile()async{
    var result =await Get.toNamed(AppRoutes.addProfile);
    if(result != null && result) fetchPackages();
  }
  void goToEditProfile(ProfilesModel profile)async{
     var result =await Get.toNamed(AppRoutes.editProfile,arguments: profile);
    if(result != null && result) fetchPackages();
    
  }
}