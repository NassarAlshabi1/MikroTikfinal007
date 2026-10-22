import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mikronet/core/ui/dialogs/dialog_helper.dart';
// تأكد من استيراد ملف الـ API الخاص بك هنا
import 'package:mikronet/features/sites/data/sites_api.dart'; 

class DnsSettingsController extends GetxController {
  // متغيرات لمراقبة حالة التحميل والسويتش
  var isLoading = true.obs;
  var allowRemoteRequest = false.obs;

  // تعريف TextControllers داخل المتحكم لضمان عدم تسريب الذاكرة
  late TextEditingController primaryCtrl;
  late TextEditingController secondaryCtrl;

  @override
  void onInit() {
    super.onInit();
    primaryCtrl = TextEditingController();
    secondaryCtrl = TextEditingController();
    // جلب البيانات عند فتح الصفحة
    fetchDnsData();
  }
  bool _isEmptyFields() {
    if (primaryCtrl.text.trim().isEmpty) {
      showMsgDialog(message: "يرجى إدخال خادم DNS الأساسي", type: MsgType.warning);
      return true;
    }
    return false;
  }

  @override
  void onClose() {
    primaryCtrl.dispose();
    secondaryCtrl.dispose();
    super.onClose();
  }

  // الدالة الأولى: جلب بيانات الـ DNS من المايكروتك
  Future<void> fetchDnsData() async {
    isLoading.value = true;
    try {
      final response = await SitesApi.getDnsData();
      final rows = response.data;
      if (!response.status || rows is! List || rows.isEmpty || rows.first is! Map) {
        showMsgDialog(
          message: response.status
              ? "لم يُرجع الراوتر إعدادات DNS صالحة"
              : "فشل في جلب إعدادات DNS الحالية: ${response.message}",
          type: MsgType.error,
        );
        return;
      }

      final data = rows.first as Map;
      allowRemoteRequest.value =
          data['allow-remote-requests']?.toString().toLowerCase() == 'yes' ||
          data['allow-remote-requests']?.toString().toLowerCase() == 'true';

      final servers = (data['servers']?.toString() ?? '')
          .split(',')
          .map((server) => server.trim())
          .where((server) => server.isNotEmpty)
          .toList();
      // امسح الحقول أولاً حتى لا تبقى قيمة DNS ثانوية قديمة عند وجود خادم واحد.
      primaryCtrl.text = servers.isNotEmpty ? servers.first : '';
      secondaryCtrl.text = servers.length > 1 ? servers[1] : '';
    } catch (error) {
      showMsgDialog(
        message: "تعذّر تحميل إعدادات DNS: $error",
        type: MsgType.error,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // الدالة الثانية: حفظ البيانات الجديدة
  Future<void> saveDnsSettings() async {
    if(_isEmptyFields()) return;
    isLoading.value = true;
    var response = await SitesApi.setDns(
      main: primaryCtrl.text.trim(),
      secondary: secondaryCtrl.text.trim(),
      allowRemoteRequests: allowRemoteRequest.value,
    );

    isLoading.value = false;
    
    showMsgDialog(message: response.message ,type: response.status?MsgType.success:MsgType.error);
    
  }
}