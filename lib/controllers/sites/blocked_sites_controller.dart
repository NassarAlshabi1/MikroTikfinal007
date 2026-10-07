import 'package:flutter/material.dart';
import 'package:get/get.dart';

// تأكد من صحة مسارات الاستيراد لمشروعك
import '/models/sites_model.dart';
import '/api/sites_api.dart'; 
import '/models/response.dart'; 

// مسار ملف dialog_helper
import '/controllers/dialog_helper.dart'; 

class BlockedSitesController extends GetxController {
  String blockType = 'Domain'; 

  RxList<BlockedSiteModel> blockedList = <BlockedSiteModel>[].obs;
  RxBool isLoading = true.obs;

  // إضافة حقول الإدخال هنا
  final nameCtrl = TextEditingController();
  final valueCtrl = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    if (Get.arguments != null) {
      blockType = Get.arguments.toString();
    }
    fetchBlockedData();
  }

  @override
  void onClose() {
    // التخلص من الحقول عند إغلاق الصفحة لتفريغ الذاكرة
    nameCtrl.dispose();
    valueCtrl.dispose();
    super.onClose();
  }

  // ================= 1. خريطة النصوص والواجهة =================
  late final Map<String, Map<String, String>> uiConfig = {
    'Domain': {
      'title': "حظر النطاقات (Domain / SSL)",
      'subtitle': "إدارة المواقع المحظورة باستخدام SSL المتقدم",
      'hint': "مثال: facebook.com",
    },
    'Content': {
      'title': "حظر المحتوى (Layer7)",
      'subtitle': "إسقاط الحزم بناءً على الكلمات أو المحتوى",
      'hint': "مثال: netflix أو pubg",
    },
  };

  String get pageTitle => uiConfig[blockType]?['title'] ?? "";
  String get pageSubtitle => uiConfig[blockType]?['subtitle'] ?? "";
  String get inputHint => uiConfig[blockType]?['hint'] ?? "";

  // ================= 2. خرائط دوال الـ API =================
  late final Map<String, Future<AppResponse<List<BlockedSiteModel>>> Function()> fetchActions = {
    'Domain': SitesApi.getSSLBlockedSites,
    'Content': SitesApi.getLayer7BlockedSites,
  };

  late final Map<String, Future<AppResponse> Function(BlockedSiteModel)> addActions = {
    'Domain': SitesApi.addBlockBySSL,
    'Content': SitesApi.addBlockByLayer7,
  };

  late final Map<String, Future<AppResponse> Function(BlockedSiteModel)> removeActions = {
    'Domain': SitesApi.deleteBlockBySSL,
    'Content': SitesApi.deleteBlockByLayer7,
  };

  // ================= 3. الدوال الرئيسية =================

  Future<void> fetchBlockedData() async {
    isLoading.value = true;
    try {
      final action = fetchActions[blockType];
      if (action != null) {
        final response = await action();
        if (response.status == true && response.data != null) {
          blockedList.value = response.data!;
        } else {
          showMsgDialog(message: response.message,type: MsgType.error);
        }
      }
    } finally {
      isLoading.value = false;
    }
  }

  // دالة الإضافة تم تعديلها لتقرأ من الـ Controllers مباشرة
  Future<void> addBlock({String interface = "all-ethernet"}) async {
    String name = nameCtrl.text.trim();
    String value = valueCtrl.text.trim();

    if (value.isEmpty || name.isEmpty) {
      showMsgDialog(message: "يرجى إدخال القيمة المراد حظرها",type: MsgType.warning);
      return;
    }

    Get.dialog(const Center(child: CircularProgressIndicator()), barrierDismissible: false);
    
    // إنشاء اسم تلقائي إذا تُرك حقل الاسم فارغاً
    String cleanName = name.isNotEmpty 
        ? name 
        : "Block_${value.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_')}";

    BlockedSiteModel newSite = BlockedSiteModel(
      id: "", 
      name: cleanName,
      blockType: blockType,
      blockValue: value,
      interface: interface,
      filterId: "",
      linkId: "",
      layer7Id: "",
    );

    final action = addActions[blockType];
    if (action != null) {
      final response = await action(newSite);
      
      Get.back(); // إغلاق دائرة التحميل
      
      if (response.status == true) {
        Get.back(); // إغلاق نافذة الإضافة
        
        // تصفير الحقول بعد الإضافة الناجحة
        nameCtrl.clear();
        valueCtrl.clear();
        
        fetchBlockedData();
        showMsgDialog(message: "تمت إضافة الحظر بنجاح",type: MsgType.success);
      } else {
        showMsgDialog(message: response.message,type: MsgType.error);      }
    }
  }

  void removeBlock(BlockedSiteModel site) {
    showConfirmDialog(
      message: "هل أنت متأكد من رغبتك في فك الحظر؟ لا يمكن التراجع عن هذه الخطوة.",
      onConfirm: () async {
        await Future.delayed(const Duration(milliseconds: 150));
        Get.dialog(const Center(child: CircularProgressIndicator()), barrierDismissible: false);
        
        final action = removeActions[blockType];
        if (action != null) {
          final response = await action(site);
          
          Get.back();
          
          if (response.status == true) {
            fetchBlockedData();
            showMsgDialog(message: "تم فك الحظر بنجاح",type: MsgType.success);
          } else {
            showMsgDialog(message: response.message,type: MsgType.error);
          }
        }
      },
    );
  }
}