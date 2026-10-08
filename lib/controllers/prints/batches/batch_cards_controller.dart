import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mikronet/api/cards_api.dart';
import 'package:mikronet/api/print_api.dart';
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
      final mikrotikCardsRes = await CardsApi.getAllCards();
      if (!mikrotikCardsRes.status || mikrotikCardsRes.data == null) {
        throw Exception(mikrotikCardsRes.message);
      }
      final mikrotikUsernames =
          mikrotikCardsRes.data!.map((card) => card.username).toSet();

      // 3. مقارنة الكروت المولدة مع كروت الميكروتك وتخزين الحالة الفعلية.
      for (final card in generatedCards) {
        final isAdded = mikrotikUsernames.contains(card.username);
        if (card.isAdd != isAdded) {
          card.isAdd = isAdded;
          await _persistCardStatus(card, isAdded);
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
      String customerName = customers.isNotEmpty ? customers[0].name : "admin";

      AppResponse response = await CardsApi.addOneCard(
        customer: customerName, 
        username: card.username, 
        password: card.password, 
        profile: card.profileName
      );

      if (response.status) {
        // تحديث حالة الكرت في الواجهة وقاعدة بيانات الدفعة.
        generatedCards[index].isAdd = true;
        await _persistCardStatus(card, true);
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

  Future<void> _persistCardStatus(
    GeneratedCardsModel card,
    bool isAdded,
  ) async {
    if (card.batchId <= 0) return;
    try {
      await PrintBatchesApi.setCardAddedStatus(
        card.batchId,
        username: card.username,
        isAdded: isAdded,
      );
    } catch (e) {
      print("تعذّر حفظ حالة الكرت ${card.username}: $e");
    }
  }

  // ==========================================
  // دوال التحكم بالرفع للسيرفر
  // ==========================================
  Future<void> startUploadingToServer() async {
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
      backgroundColor: const Color(0xFF16213A),
    );
  }

  void stopUploading() {
    if(!isUploading) return;
    isUploading = false;
    update();
  }
}