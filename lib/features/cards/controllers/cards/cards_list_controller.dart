import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mikronet/core/mikrotik/mikrotik_client.dart';
import 'package:mikronet/core/ui/dialogs/dialog_helper.dart';
import 'package:mikronet/app/routes/app_routes.dart';
import 'package:mikronet/features/cards/models/cards_model.dart';
import 'package:mikronet/core/models/app_response.dart';
import 'package:mikronet/features/cards/data/cards_api.dart';

class CardsListController extends GetxController {
  final RxString filter = "الكل".obs;
  final RxString searchQuery = "".obs;
  
  final RxList<CardModel> allCards = <CardModel>[].obs;
  final RxList<CardModel> filteredCards = <CardModel>[].obs;

  final cardCounts = {
    "الكل": 0.obs,
    "جديدة": 0.obs,
    "نشطة": 0.obs,
    "منتهية": 0.obs,
  };
  
  final RxBool isLoading = true.obs;
  final RxBool isRefreshing = false.obs;
  final RxBool isBulkActionRunning = false.obs;

  /// أسماء الكروت المحددة للإجراءات الجماعية (وضع التحديد).
  final RxSet<String> selectedUsernames = <String>{}.obs;

  int _requestCounter = 0;
  Timer? _debounceTimer;

  // متحكمات الحقول
  final searchCtrl = TextEditingController();
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
    _debounceTimer?.cancel();
    searchCtrl.dispose();
    userCtrl.dispose();
    passCtrl.dispose();
    pkgCtrl.dispose();
    close();
    super.onClose();
  }

  Future<void> close() async {
    if (isLoading.value) {
      MikrotikClient.cancelCommand('users_profiles');
      MikrotikClient.cancelCommand('users');
      MikrotikClient.cancelCommand('cards');
    }
  }

  void goBack() {
    Get.back();
  }

  void setFilter(String newFilter) {
    if (filter.value == newFilter) return;
    filter.value = newFilter;
    _applyFilters();
  }

  void setSearch(String query) {
    _debounceTimer?.cancel();
    if (query.isEmpty) {
      searchQuery.value = "";
      _applyFilters();
    } else {
      _debounceTimer = Timer(const Duration(milliseconds: 150), () {
        searchQuery.value = query;
        _applyFilters();
      });
    }
  }

  void clearSearch() {
    searchCtrl.clear();
    searchQuery.value = "";
    _debounceTimer?.cancel();
    _applyFilters();
  }

  /// حساب الإحصائيات في دورة واحدة O(N) فائقة السرعة
  void _updateCardCounts() {
    int total = allCards.length;
    int countNew = 0;
    int countActive = 0;
    int countExpired = 0;

    for (int i = 0; i < total; i++) {
      final status = allCards[i].status;
      if (status == "active") {
        countActive++;
      } else if (status == "normal") {
        countNew++;
      } else {
        countExpired++;
      }
    }

    cardCounts["الكل"]!.value = total;
    cardCounts["جديدة"]!.value = countNew;
    cardCounts["نشطة"]!.value = countActive;
    cardCounts["منتهية"]!.value = countExpired;
  }

  /// تطبيق الفلاتر والبحث بسرعة قياسية باستخدام مفاتيح البحث المحسوبة مسبقاً
  void _applyFilters() {
    final currentFilter = filter.value;
    final query = searchQuery.value.trim().toLowerCase();

    List<CardModel> result = allCards.toList();

    if (currentFilter != "الكل") {
      if (currentFilter == "نشطة") {
        result = result.where((c) => c.status == "active").toList();
      } else if (currentFilter == "جديدة") {
        result = result.where((c) => c.status == "normal").toList();
      } else if (currentFilter == "منتهية") {
        result = result.where((c) => c.status != "active" && c.status != "normal").toList();
      }
    }

    if (query.isNotEmpty) {
      result = result.where((c) => c.searchKey.contains(query)).toList();
    }

    filteredCards.assignAll(result);
  }

  Future<void> refreshCards() async {
    isRefreshing.value = true;
    await _fetchCards(isPullRefresh: true);
    isRefreshing.value = false;
  }

  Future<void> _fetchCards({bool isPullRefresh = false}) async {
    final currentId = ++_requestCounter;
    if (!isPullRefresh) {
      isLoading.value = true;
    }
    
    try {
      AppResponse<List<CardModel>> response = await CardsApi.getAllCards();

      if (currentId != _requestCounter) return;

      if (response.status && response.data != null) {
        allCards.assignAll(response.data!);
        _updateCardCounts();
        _applyFilters();
      } else {
        showMsgDialog(message: response.message, type: MsgType.error);
      }
    } catch (e) {
      if (currentId == _requestCounter) {
        showMsgDialog(message: "خطأ في مزامنة الكروت: $e", type: MsgType.error);
      }
    } finally {
      if (currentId == _requestCounter) {
        isLoading.value = false;
      }
    }
  }

  // ============ وضع التحديد والإجراءات الجماعية (مثل ABOTALAL) ============

  bool get selectionMode => selectedUsernames.isNotEmpty;

  void toggleSelect(CardModel card) {
    if (selectedUsernames.contains(card.username)) {
      selectedUsernames.remove(card.username);
    } else {
      selectedUsernames.add(card.username);
    }
  }

  void selectAllVisible() {
    selectedUsernames.addAll(filteredCards.map((c) => c.username));
  }

  void clearSelection() => selectedUsernames.clear();

  /// حذف جماعي: جلب المعرفات الداخلية ثم حذفها دفعة واحدة من الراوتر.
  Future<void> bulkDelete() async {
    if (isBulkActionRunning.value || selectedUsernames.isEmpty) return;
    isBulkActionRunning.value = true;
    try {
      final idsRes = await CardsApi.getIdsByUsernames(selectedUsernames.toList());
      if (idsRes.status && (idsRes.data?.isNotEmpty ?? false)) {
        await CardsApi.deleteCardsBatch(idsRes.data!);
        allCards.removeWhere((c) => selectedUsernames.contains(c.username));
        showMsgDialog(
            message: "تم حذف ${idsRes.data!.length} كرت من الراوتر",
            type: MsgType.success);
      } else {
        throw Exception(idsRes.message);
      }
      clearSelection();
      _updateCardCounts();
      _applyFilters();
    } catch (e) {
      showMsgDialog(message: "فشل الحذف الجماعي: $e", type: MsgType.error);
    } finally {
      isBulkActionRunning.value = false;
    }
  }

  /// تفعيل جماعي: إعادة تفعيل باقة كل كرت محدد (create-and-activate-profile).
  Future<void> bulkActivate() async {
    if (isBulkActionRunning.value || selectedUsernames.isEmpty) return;
    isBulkActionRunning.value = true;
    int ok = 0, failed = 0;
    try {
      final targets = allCards
          .where((c) => selectedUsernames.contains(c.username))
          .toList();
      // تشغيل متوازٍ محدود (4) — قناة API تحمي الردود بوسم .tag
      int cursor = 0;
      Future<void> worker() async {
        while (cursor < targets.length && isBulkActionRunning.value) {
          final card = targets[cursor++];
          final res = await CardsApi.addCardProfile(
            customer: card.customer.isEmpty ? "admin" : card.customer,
            username: card.username,
            profile: card.profile,
          );
          if (res.status) {
            ok++;
          } else {
            failed++;
          }
        }
      }
      await Future.wait(List.generate(
          targets.length.clamp(1, 4), (_) => worker()));
      showMsgDialog(
          message: "تم تفعيل $ok كرت${failed > 0 ? ' — فشل $failed' : ''}",
          type: failed == 0 ? MsgType.success : MsgType.warning);
      clearSelection();
      refreshCards();
    } catch (e) {
      showMsgDialog(message: "فشل التفعيل الجماعي: $e", type: MsgType.error);
    } finally {
      isBulkActionRunning.value = false;
    }
  }

  void goToCardDetails(CardModel card) async {
    var res = await Get.toNamed(AppRoutes.cardDetails, arguments: card);
    if (res != null && res is AppResponse && res.status) {
      var updatedCard = res.data as CardModel;
      var i = allCards.indexWhere((c) => c.id == card.id);
      if (res.message == "delete") {
        if (i != -1) allCards.removeAt(i);
      } else {
        if (i != -1) {
          allCards[i] = updatedCard;
        } else {
          allCards.add(updatedCard);
        }
      }
      _updateCardCounts();
      _applyFilters();
    }
  }

  void goToCardSessions(CardModel card) {
    if (card.status == "normal") {
      showMsgDialog(message: "لا توجد جلسات، لم يتم استخدام الكرت بعد", type: MsgType.info);
      return;
    }
    Get.toNamed(AppRoutes.cardSessions, arguments: card.username);
  }

  void goToAddSingleCard() async {
    var res = await Get.toNamed(AppRoutes.addSingleCard);
    if (res == true) {
      refreshCards();
    }
  }
}

extension CardModelExt on CardModel {
  String get package => profile;
  
  String get statusDisplay {
    if (status == "active") return "نشطة";
    if (status == "normal") return "جديدة";
    return "منتهية";
  }
}
