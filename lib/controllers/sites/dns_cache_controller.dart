import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '/models/sites_model.dart'; 
import '/api/sites_api.dart'; 
import '../dialog_helper.dart';

class DnsCacheController extends GetxController {
  final RxList<DNSCacheModel> dnsCacheList = <DNSCacheModel>[].obs;
  final RxBool isLoading = true.obs;
  final RxBool isFlushing = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchDnsCache();
  }

  // دالة جلب البيانات من المايكروتك
  Future<void> fetchDnsCache() async {
    isLoading.value = true;
    try {
      var response = await SitesApi.getDnsCache();
      if (response.status && response.data != null) {
        dnsCacheList.assignAll(response.data!);
      } else {
        showMsgDialog(message: response.message, type: MsgType.error);
      }
    } catch (e) {
      showMsgDialog(message: "خطأ في جلب سجلات DNS: $e", type: MsgType.error);
    } finally {
      isLoading.value = false;
    }
  }

  // دالة مسح كل التخزين المؤقت مع التأكيد
  void confirmClearCache() {
    showConfirmDialog(
      message: "هل أنت متأكد من مسح كافة سجلات DNS المؤقتة (DNS Cache Flush) من الراوتر؟",
      onConfirm: _executeClearCache,
    );
  }

  Future<void> _executeClearCache() async {
    showLoadingDialog(message: "جاري مسح الذاكرة المؤقتة للراوتر...");
    isFlushing.value = true;

    try {
      var response = await SitesApi.flushDnsCache();
      hideDialog();

      if (response.status) {
        dnsCacheList.clear();
        showMsgDialog(message: response.message, type: MsgType.success);
      } else {
        showMsgDialog(message: response.message, type: MsgType.error);
      }
    } catch (e) {
      hideDialog();
      showMsgDialog(message: "حدث خطأ: $e", type: MsgType.error);
    } finally {
      isFlushing.value = false;
    }
  }

  // دالة حذف سجل محدد مع التأكيد
  void confirmDeleteSite(DNSCacheModel site) {
    showConfirmDialog(
      message: "هل تريد حذف السجل «${site.name}» من ذاكرة الراوتر؟",
      onConfirm: () => _executeDeleteSite(site),
    );
  }

  Future<void> _executeDeleteSite(DNSCacheModel site) async {
    showLoadingDialog(message: "جاري حذف السجل...");
    try {
      var response = await SitesApi.removeDnsCache(site.id);
      hideDialog();

      if (response.status) {
        dnsCacheList.removeWhere((item) => item.id == site.id);
        showMsgDialog(message: response.message, type: MsgType.success);
      } else {
        showMsgDialog(message: response.message, type: MsgType.error);
      }
    } catch (e) {
      hideDialog();
      showMsgDialog(message: "حدث خطأ: $e", type: MsgType.error);
    }
  }
}
