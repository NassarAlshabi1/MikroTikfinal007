import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mikronet/services/mikrotik_client.dart';
import '../../dialog_helper.dart';
import '../../../core/app_pages.dart';
import '../../../models/cards_model.dart';
import '../../../models/response.dart';
import '../../../api/cards_api.dart';

class CardsListController extends GetxController {
  RxString filter = "الكل".obs;
  RxString searchQuery = "".obs;
  
  RxList<CardModel> allCards = <CardModel>[].obs;
  RxList<CardModel> filteredCards = <CardModel>[].obs;

  var cardCounts = {
        "الكل": 0.obs,
        "جديدة":0.obs,
        "نشطة":0.obs,
        "منتهية":0.obs
  };
  
  RxBool isLoading = true.obs;
  int _requestCounter = 0;

  // متحكمات الحقول لإضافة كرت جديد
  final userCtrl = TextEditingController();
  final passCtrl = TextEditingController();
  final pkgCtrl = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    _fetchCards(); // جلب البيانات عند فتح الشاشة
  }

  @override
  void onClose() {
    close();
    userCtrl.dispose();
    passCtrl.dispose();
    pkgCtrl.dispose();
    super.onClose();
  }

  Future<void> close()async{
    // await MikrotikClient.cancel();
    if(isLoading.value){
      MikrotikClient.cancelCommand('users_profiles');
      print('\n \n \n \n \n \n \n \n \n \n');
      print('users_profiles');
      print('\n \n \n \n \n \n \n \n \n \n');
      MikrotikClient.cancelCommand('users');
      print('\n \n \n \n \n \n \n \n \n \n');
      print('users');
      print('\n \n \n \n \n \n \n \n \n \n');
    }
  }

  void goBack() {
    Get.back();
  }

  void setFilter(String newFilter) {
    filter.value = newFilter;
    _applyFilters();
  }

  void setSearch(String query) {
    searchQuery.value = query;
    _applyFilters();
  }

  // التعديل الرئيسي لفصل الحالات
  void _applyFilters() {
    var result = allCards.toList();
    cardCounts["جديدة"]!.value = allCards.where((c)=>c.status=="normal").length;
    cardCounts["نشطة"]!.value = allCards.where((c)=>c.status=="active").length;
    cardCounts["منتهية"]!.value = allCards.where((c)=>c.status != "active" && c.status != "normal").length;
    cardCounts["الكل"]!.value = allCards.length;
    if (filter.value != "الكل") {
      result = result.where((c) {
        if (filter.value == "نشطة") return c.status == "active";
        if (filter.value == "جديدة") return c.status == "normal";
        // افتراض أن أي حالة غير active أو normal تعتبر منتهية
        if (filter.value == "منتهية") return c.status != "active" && c.status != "normal"; 
        return false;
      }).toList();
    }

    if (searchQuery.value.isNotEmpty) {
      String query = searchQuery.value.toLowerCase();
      result = result.where((c) => 
        c.username.toLowerCase().contains(query) || 
        c.profile.toLowerCase().contains(query)
      ).toList();
    }

    filteredCards.assignAll(result);
  }

  void goToCardDetails(CardModel card)async {
   
    var res = await Get.toNamed(AppRoutes.cardDetails, arguments: card);
    if(res != null && res is AppResponse && res.status){
      var updatedCard = res.data as CardModel;
      var i = allCards.indexWhere((c)=> c.id == card.id);
      if(res.message == "delete") {
        allCards.removeAt(i);
      } else {
        allCards[i]= updatedCard;
      }
      _applyFilters();
        
    }
  }

  void goToCardSessions(CardModel card) {
     if(card.status == "normal"){
      showMsgDialog(message: "لا توجد جلسات لم يتم استخدام الكرت",type: MsgType.info);
      return;
    }
    Get.toNamed(AppRoutes.cardSessions, arguments: card.username);
  }

  

  Future<void> _fetchCards() async {
    final currentId = ++_requestCounter;
    isLoading.value = true;
    
    try {
      AppResponse<List<CardModel>> response = await CardsApi.getAllCards();

      if (currentId != _requestCounter) return;

      if (response.status && response.data != null) {
        allCards.assignAll(response.data!);
        _applyFilters();
      } else {
        showMsgDialog(message: response.message);
      }
    } catch (e) {
      if (currentId == _requestCounter) {
        showMsgDialog(message: "Error fetching cards: $e");
      }
    } finally {
      if (currentId == _requestCounter) {
        isLoading.value = false;
      }
    }
  }

  Future<void> _addNewCard() async {
    if (userCtrl.text.isEmpty || pkgCtrl.text.isEmpty) {
      showMsgDialog(message: "يرجى تعبئة اسم المستخدم والباقة على الأقل");
      return;
    }

    Get.back(); 
    Get.dialog(const Center(child: CircularProgressIndicator(color: Color(0xFF1E3A8A))), barrierDismissible: false);

    try {
      AppResponse<void> response = await CardsApi.addOneCard(
        customer: "admin", 
        username: userCtrl.text,
        password: passCtrl.text,
        profile: pkgCtrl.text,
      );
      
      if (Get.isDialogOpen ?? false) Get.back();

      if (response.status) {
        showMsgDialog(message: "تم إضافة الكرت بنجاح");
        _fetchCards(); // إعادة جلب البيانات لتحديث القائمة
      } else {
        showMsgDialog(message: response.message);
      }
    } catch (e) {
      if (Get.isDialogOpen ?? false) Get.back();
      showMsgDialog(message: "Error adding card: $e");
    }
  }
  void goToAddSingleCard ()=> Get.toNamed(AppRoutes.addSingleCard);
}

extension CardModelExt on CardModel {
  String get package => profile;
  
  // التعديل هنا ليعكس الحالات الثلاث
  String get statusDisplay {
    if (status == "active") return "نشطة";
    if (status == "normal") return "جديدة";
    return "منتهية";
  }
}