import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mikronet/app/theme/app_theme.dart';
import 'package:get/get.dart';
import 'package:mikronet/features/cards/data/cards_api.dart';
import 'package:mikronet/features/prints/models/print_model.dart';
import 'package:mikronet/features/cards/models/cards_model.dart'; // ضروري للتعامل مع CustomerModel و CardModel
import 'package:mikronet/core/models/app_response.dart';

class GeneratedCardsController extends GetxController {
  GeneratedCardsController(this.generatedCards);
  
  List<GeneratedCardsModel> generatedCards;
  List<CustomerModel> customers = [];
  bool isUploading = false; 
  bool isLoading = true; // متغير لمتابعة حالة المزامنة الأولية

  /// عدد الكروت التي نجح رفعها في آخر عملية.
  int uploadedCount = 0;

  /// عدد الكروت التي فشل رفعها في آخر عملية.
  int failedCount = 0;

  /// كروت ما زالت قيد الانتظار (غير موجودة على الراوتر).
  int get pendingCount => generatedCards.where((c) => !c.isAdd).length;

  /// عدد الطلبات المتزامنة على قناة الراوتر — أوامر API محمية بوسم `.tag`
  /// فيمكن تنفيذ عدة أوامر بالتوازي دون خلط الردود.
  static const int _uploadConcurrency = 4;

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
      // جلب العملاء والكروت بالتوازي — طلبتان مستقلتان على القناة نفسها.
      final results = await Future.wait([
        CardsApi.getCustomers(),
        CardsApi.getAllCards(),
      ]);

      final AppResponse<List<CustomerModel>> customersRes =
          results[0] as AppResponse<List<CustomerModel>>;
      if (customersRes.status && customersRes.data != null) {
        customers = customersRes.data!;
      }

      final AppResponse<List<CardModel>> mikrotikCardsRes =
          results[1] as AppResponse<List<CardModel>>;
      final Set<String> mikrotikUsernames =
          (mikrotikCardsRes.status && mikrotikCardsRes.data != null)
              ? mikrotikCardsRes.data!.map((e) => e.username).toSet()
              : <String>{};

      // مقارنة الكروت المولدة مع كروت الميكروتك وتحديث حالتها
      for (final card in generatedCards) {
        card.isAdd = mikrotikUsernames.contains(card.username);
      }
    } catch (e) {
      debugPrint("Error syncing cards: $e");
    }

    isLoading = false;
    update(); // تحديث الواجهة بعد انتهاء المزامنة
  }

  /// اسم العميل الذي تُضاف الكروت تحته — أول عميل متاح أو admin.
  String get _customerName => customers.isNotEmpty ? customers[0].name : "admin";
  
  Future<bool> createCard(GeneratedCardsModel card) async {
    try {
      AppResponse response = await CardsApi.addOneCard(
        customer: _customerName, 
        username: card.username, 
        password: card.password, 
        profile: card.profileName
      );

      if (response.status) {
        card.isAdd = true;
        return true;
      } else {
        debugPrint("خطأ في الكرت ${card.username}: ${response.message}");
        return false;
      }
    } catch (e) {
      debugPrint("خطأ استثنائي في الكرت ${card.username}: ${e.toString()}");
      return false; 
    }
  }

  // ==========================================
  // دوال التحكم بالرفع للسيرفر
  // ==========================================

  /// رفع الكروت الناقصة إلى الراوتر بمجموعات متوازية.
  ///
  /// بدل كرت-كرت (بطيء جداً على دفعات كبيرة)، يشغّل [_uploadConcurrency]
  /// "عمّال" يسحبون الكروت من قائمة انتظار مشتركة. زر الإيقاف يوقف سحب
  /// كروت جديدة فوراً مع ترك الجاري إنهاؤه.
  Future<void> startUploadingToServer() async {
    if (isUploading) return;
    isUploading = true;
    uploadedCount = 0;
    failedCount = 0;
    update();

    // قائمة انتظار مشتركة بفهارس الكروت المعلّقة — العمّال يسحبون منها.
    final pendingIndexes = <int>[
      for (int i = 0; i < generatedCards.length; i++)
        if (!generatedCards[i].isAdd) i,
    ];
    int cursor = 0;
    int completedSinceLastUpdate = 0;

    Future<void> worker() async {
      while (isUploading) {
        if (cursor >= pendingIndexes.length) break;
        final index = pendingIndexes[cursor++];

        final success = await createCard(generatedCards[index]);
        if (success) {
          uploadedCount++;
        } else {
          failedCount++;
        }

        // تحديث الواجهة كل بضعة كروت بدل كل كرت — أسرع بكثير على دفعات كبيرة.
        if (++completedSinceLastUpdate >= 10) {
          completedSinceLastUpdate = 0;
          update();
        }
      }
    }

    await Future.wait(
      List.generate(
        pendingIndexes.length.clamp(1, _uploadConcurrency),
        (_) => worker(),
      ),
    );

    isUploading = false;
    update();

    Get.snackbar(
      "نتيجة الإرسال", 
      "اكتملت العملية.\nنجح: $uploadedCount \nفشل: $failedCount", 
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 4),
      backgroundColor: AppColors.card,
    );
  }

  void stopUploading() {
    if(!isUploading) return;
    isUploading = false;
    update();
  }
}
