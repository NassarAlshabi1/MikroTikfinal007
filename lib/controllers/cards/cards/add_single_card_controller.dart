import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '/api/cards_api.dart'; 
import '/api/profiles_api.dart'; 
import '/models/profiles_model.dart'; 
import '/models/cards_model.dart'; // استيراد مودل العملاء
import '/models/response.dart';
import '/controllers/dialog_helper.dart';

class AddSingleCardController extends GetxController {
  final usernameCtrl = TextEditingController();
  final passwordCtrl = TextEditingController();

  RxBool isLoading = false.obs;
  RxBool isProfilesLoading = true.obs;
  RxBool isCustomersLoading = true.obs; // حالة تحميل العملاء
  
  RxList<ProfilesModel> profiles = <ProfilesModel>[].obs;
  Rxn<ProfilesModel> selectedProfile = Rxn<ProfilesModel>();

  // 🔹 قائمة العملاء والمتغير المختار
  RxList<CustomerModel> customers = <CustomerModel>[].obs;
  Rxn<CustomerModel> selectedCustomer = Rxn<CustomerModel>();

  @override
  void onInit() {
    super.onInit();
    fetch();
     // 🔹 جلب العملاء عند التشغيل
  }
  void fetch()async{
    await fetchProfiles(); 
    await fetchCustomers();
  }
  @override
  void onClose() {
    usernameCtrl.dispose();
    passwordCtrl.dispose();
    super.onClose();
  }

  Future<void> fetchProfiles() async {
    isProfilesLoading.value = true;
    try {
      AppResponse<List<ProfilesModel>> response = await ProfilesApi.getProfiles();
      if (response.status && response.data != null) {
        profiles.assignAll(response.data!);
        if (profiles.isNotEmpty) selectedProfile.value = profiles.first;
      } else {
        showMsgDialog(message: "فشل جلب الباقات: ${response.message}");
      }
    } catch (e) {
      showMsgDialog(message: "خطأ في الاتصال: $e");
    } finally {
      isProfilesLoading.value = false;
    }
  }

  // 🔹 دالة جلب العملاء من CardsApi
  Future<void> fetchCustomers() async {
    isCustomersLoading.value = true;
    try {
      AppResponse<List<CustomerModel>> response = await CardsApi.getCustomers();
      if (response.status && response.data != null) {
        customers.assignAll(response.data!);
        
        // 🔹 تأكد من أن القائمة تحتوي على بيانات قبل التعيين
        if (customers.isNotEmpty) {
          selectedCustomer.value = customers.first;
        } else {
          selectedCustomer.value = null; // تصفير القيمة إذا كانت القائمة فارغة
        }
      } else {
        // لا تظهر دايالوج هنا إذا كانت البيانات فارغة فقط، يكفي التنبيه
        print("تنبيه: لا يوجد عملاء في السيرفر");
      }
    } catch (e) {
      print("خطأ في جلب العملاء: $e");
    } finally {
      isCustomersLoading.value = false;
    }
  }

  Future<void> saveCard() async {
    // 🔹 إضافة التحقق من اختيار العميل
    if (usernameCtrl.text.isEmpty || selectedProfile.value == null || selectedCustomer.value == null) {
      showMsgDialog(message: "يرجى إدخال اسم المستخدم واختيار الباقة والعميل");
      return;
    }

    isLoading.value = true;
    try {
      // 🔹 إرسال الطلب مع العميل المختار
      AppResponse<void> response = await CardsApi.addOneCard(
        customer: selectedCustomer.value!.name, 
        username: usernameCtrl.text,
        password: passwordCtrl.text,
        profile: selectedProfile.value!.name,
      );

      if (response.status) {
        Get.back();
        showMsgDialog(message: "تم إضافة الكرت بنجاح");
      } else {
        showMsgDialog(message: response.message);
      }
    } catch (e) {
      showMsgDialog(message: "خطأ أثناء الحفظ: $e");
    } finally {
      isLoading.value = false;
    }
  }
}