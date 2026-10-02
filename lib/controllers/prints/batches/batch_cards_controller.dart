import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mikronet/api/cards_api.dart';
import 'package:mikronet/models/print_model.dart';
import 'package:mikronet/models/cards_model.dart'; // ضروري للتعامل مع CustomerModel و CardModel
import 'package:mikronet/models/response.dart';
import 'package:mikronet/views/helpers/dialogs.dart';

class GeneratedCardsController extends GetxController {
  GeneratedCardsController(this.generatedCards);
  
  List<GeneratedCardsModel> generatedCards;
  List<CustomerModel> customers = [];
  bool isUploading = false; 
  bool isLoading = true; // متغير لمتابعة حالة المزامنة الأولية

  @override
  void onInit() {
    super.onInit();
    syncCardsWithMikrotik();
  }

  // دالة المزامنة وجلب البيانات من ميكروتك والمقارنة
  Future<void> syncCardsWithMikrotik() async {
    isLoading = true;
    update();

    try {
      // 1. جلب العملاء (customers) أولاً لاستخدامهم لاحقاً في الرفع
      AppResponse<List<CustomerModel>> customersRes = await CardsApi.getCustomers();
      if (customersRes.status && customersRes.data != null) {
        customers = customersRes.data!;
      }

      // 2. جلب جميع الكروت الموجودة في الميكروتك
      AppResponse<List<CardModel>> mikrotikCardsRes = await CardsApi.getAllCards();
      Set<String> mikrotikUsernames = {};
      
      if (mikrotikCardsRes.status && mikrotikCardsRes.data != null) {
        // تخزين أسماء المستخدمين في Set لسرعة البحث والمقارنة
        mikrotikUsernames = mikrotikCardsRes.data!.map((e) => e.username).toSet();
      }

      // 3. مقارنة الكروت المولدة مع كروت الميكروتك وتحديث حالتها
      for (int i = 0; i < generatedCards.length; i++) {
        if (mikrotikUsernames.contains(generatedCards[i].username)) {
          generatedCards[i].isAdd = true; // موجودة مسبقاً (جاهزة)
        } else {
          generatedCards[i].isAdd = false; // غير موجودة (قيد الانتظار)
        }
      }

    } catch (e) {
      print("Error syncing cards: $e");
    }

    isLoading = false;
    update(); // تحديث الواجهة بعد انتهاء المزامنة
  }
  
  Future<bool> createCard(int index, GeneratedCardsModel card) async {
    try {
      if (customers.isEmpty) {
        throw "قائمة العملاء فارغة. يرجى التحقق من الاتصال.";
      }

      // أخذ اسم أول عميل متوفر في الميكروتك (تقدر تعدلها لاختيار عميل معين إذا أردت)
      String customerName = customers[0].name;

      AppResponse response = await CardsApi.addOneCard(
        customer: customerName, 
        username: card.username, 
        password: card.password, 
        profile: card.profileName
      );

      if (response.status) {
        // تحديث حالة الكرت في واجهة المستخدم
        generatedCards[index].isAdd = true;
        update(); 
        return true;
      } else {
        print("خطأ في الكرت ${card.username}: ${response.message}");
        return false;
      }
    } catch (e) {
      print("خطأ استثنائي في الكرت ${card.username}: ${e.toString()}");
      return false; 
    }
  }

  // ==========================================
  // دوال التحكم بالرفع للسيرفر
  // ==========================================
  Future<void> startUploadingToServer() async {
    if (customers.isEmpty) {
       showErrorDialog(content: "لا يمكن بدء الإرسال، لم يتم التعرف على العملاء من المايكروتك بعد.");
       return;
    }

    if (isUploading) return;
    isUploading = true;
    update();

    int successCount = 0;
    int failCount = 0;

    for (int i = 0; i < generatedCards.length; i++) {
      if (!isUploading) break; // توقف فوري إذا ضغط المستخدم زر الإيقاف
      
      // لا نرفع إلا الكروت التي هي قيد الانتظار (isAdd == false)
      if (!generatedCards[i].isAdd) {
        bool isSuccess = await createCard(i, generatedCards[i]);
        
        if (isSuccess) {
          successCount++;
        } else {
          failCount++;
        }
      }
    }
    
    isUploading = false;
    update();

    Get.snackbar(
      "نتيجة الإرسال", 
      "اكتملت العملية.\nنجح: $successCount \nفشل: $failCount", 
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 4),
      backgroundColor: Colors.white,
    );
  }

  void stopUploading() {
    if(!isUploading) return;
    isUploading = false;
    update();
  }
}