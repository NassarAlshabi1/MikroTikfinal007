import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mikronet/api/cards_api.dart';
import 'package:mikronet/core/app_pages.dart';
import 'package:mikronet/models/cards_model.dart';
import '/controllers/dialog_helper.dart';
import '/api/profiles_api.dart';
import '/models/profiles_model.dart';

class ProfilesListController extends GetxController {
  final RxList<ProfilesModel> packages = <ProfilesModel>[].obs;
  final RxBool isLoading = true.obs;
  final RxString loadError = ''.obs;
  final RxString cardCountError = ''.obs;
  final RxMap<String, int> linkedCardCounts = <String, int>{}.obs;
  final RxBool cardCountsLoaded = false.obs;
  int _requestCounter = 0;

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

  Future<void> init() async {
    await getCustomers();
    await fetchPackages();
  }

  Future<void> getCustomers() async {
    try {
      final response = await CardsApi.getCustomers();
      if (response.status) {
        customers = response.data ?? <CustomerModel>[];
      } else {
        showMsgDialog(message: response.message, type: MsgType.error);
      }
    } catch (e) {
      showMsgDialog(message: 'تعذّر جلب العملاء: $e', type: MsgType.error);
    }
  }

  int? linkedCardCountFor(String profileName) {
    if (!cardCountsLoaded.value) return null;
    return linkedCardCounts[profileName] ?? 0;
  }

  void prepareSheet({ProfilesModel? item}) {
    if (item != null) {
      nameCtrl.text = item.name;
      priceCtrl.text = item.price;
      speedCtrl.text = item.speed;
      final validity = MikrotikTimeHelper.fromString(item.validity);
      daysCtrl.text = validity.days.toString();
      hoursCtrl.text = validity.hours.toString();
      final uptime = MikrotikTimeHelper.fromString(item.uptime);
      uptimeDaysCtrl.text = uptime.days.toString();
      uptimeHoursCtrl.text = uptime.hours.toString();
      final data = MikrotikDataHelper.fromString(item.palance);
      gigasCtrl.text = data.gigas.toString();
      megasCtrl.text = data.megas.toString();
    } else {
      _clearAll();
    }
  }

  void _clearAll() {
    nameCtrl.clear();
    priceCtrl.clear();
    daysCtrl.clear();
    hoursCtrl.clear();
    uptimeDaysCtrl.clear();
    uptimeHoursCtrl.clear();
    gigasCtrl.clear();
    megasCtrl.clear();
    speedCtrl.clear();
  }

  Future<void> executeSave({int? index}) async {
    if (nameCtrl.text.trim().isEmpty) {
      showMsgDialog(message: 'اسم الباقة مطلوب', type: MsgType.warning);
      return;
    }

    final validity = MikrotikTimeHelper(
      days: int.tryParse(daysCtrl.text) ?? 0,
      hours: int.tryParse(hoursCtrl.text) ?? 0,
    ).toMikrotikString();
    final uptime = MikrotikTimeHelper(
      days: int.tryParse(uptimeDaysCtrl.text) ?? 0,
      hours: int.tryParse(uptimeHoursCtrl.text) ?? 0,
    ).toMikrotikString();
    final balance = MikrotikDataHelper(
      gigas: int.tryParse(gigasCtrl.text) ?? 0,
      megas: int.tryParse(megasCtrl.text) ?? 0,
    ).toMikrotikString();

    final data = {
      'name': nameCtrl.text.trim(),
      'price': priceCtrl.text.trim().isEmpty ? '0' : priceCtrl.text.trim(),
      'validity': validity,
      'uptime': uptime,
      'palance': balance,
      'speed': speedCtrl.text.trim().isEmpty ? '0/0' : speedCtrl.text.toUpperCase().trim(),
      'customer': customers.isNotEmpty ? customers.first.name : 'admin',
      'users': '1',
    };

    Get.back();
    showLoadingDialog();
    try {
      final response = index != null
          ? await ProfilesApi.profileEdit(packages[index].name, data)
          : await ProfilesApi.addOneProfile(data);
      hideDialog();
      if (response.status) {
        await fetchPackages();
        showMsgDialog(message: 'تم حفظ الباقة بنجاح', type: MsgType.success);
      } else {
        showMsgDialog(message: response.message, type: MsgType.error);
      }
    } catch (e) {
      hideDialog();
      showMsgDialog(message: 'تعذّر حفظ الباقة: $e', type: MsgType.error);
    }
  }

  Future<void> fetchPackages() async {
    final requestId = ++_requestCounter;
    isLoading.value = true;
    loadError.value = '';
    cardCountError.value = '';
    cardCountsLoaded.value = false;

    try {
      final response = await ProfilesApi.getProfiles();
      if (requestId != _requestCounter) return;
      if (!response.status || response.data == null) {
        packages.clear();
        linkedCardCounts.clear();
        loadError.value = response.message.isEmpty
            ? 'تعذّر جلب باقات الراوتر'
            : response.message;
        return;
      }

      packages.assignAll(response.data!);

      // أعداد الكروت من بيانات الراوتر الفعلية؛ لا نعرض قيمة افتراضية عند الفشل.
      try {
        final cardsResponse = await CardsApi.getAllCards();
        if (requestId != _requestCounter) return;
        if (cardsResponse.status && cardsResponse.data != null) {
          final counts = <String, int>{};
          for (final card in cardsResponse.data!) {
            final profileName = card.profile.trim();
            if (profileName.isEmpty || profileName == 'unknown') continue;
            counts[profileName] = (counts[profileName] ?? 0) + 1;
          }
          linkedCardCounts.assignAll(counts);
          cardCountsLoaded.value = true;
        } else {
          cardCountError.value = cardsResponse.message.isEmpty
              ? 'تعذّر قراءة عدد الكروت المرتبطة'
              : cardsResponse.message;
        }
      } catch (e) {
        if (requestId == _requestCounter) {
          cardCountError.value = 'تعذّر قراءة عدد الكروت المرتبطة: $e';
        }
      }
    } catch (e) {
      if (requestId == _requestCounter) {
        packages.clear();
        linkedCardCounts.clear();
        loadError.value = 'تعذّر جلب الباقات: $e';
      }
    } finally {
      if (requestId == _requestCounter) isLoading.value = false;
    }
  }

  void confirmDelete(int index) {
    if (index < 0 || index >= packages.length) return;
    showConfirmDialog(
      message: 'حذف الباقة (${packages[index].name}) من الراوتر؟',
      onConfirm: () => _executeDelete(index),
    );
  }

  Future<void> _executeDelete(int index) async {
    if (index < 0 || index >= packages.length) return;
    showLoadingDialog();
    try {
      final response = await ProfilesApi.deleteProfile(packages[index].name);
      hideDialog();
      if (response.status) {
        packages.removeAt(index);
        showMsgDialog(message: response.message, type: MsgType.success);
      } else {
        showMsgDialog(message: response.message, type: MsgType.error);
      }
    } catch (e) {
      hideDialog();
      showMsgDialog(message: 'تعذّر حذف الباقة: $e', type: MsgType.error);
    }
  }

  Future<void> goToAddProfile() async {
    final result = await Get.toNamed(AppRoutes.addProfile);
    if (result == true) await fetchPackages();
  }

  Future<void> goToEditProfile(ProfilesModel profile) async {
    final result = await Get.toNamed(AppRoutes.editProfile, arguments: profile);
    if (result == true) await fetchPackages();
  }

  @override
  void onClose() {
    nameCtrl.dispose();
    priceCtrl.dispose();
    daysCtrl.dispose();
    hoursCtrl.dispose();
    uptimeDaysCtrl.dispose();
    uptimeHoursCtrl.dispose();
    gigasCtrl.dispose();
    megasCtrl.dispose();
    speedCtrl.dispose();
    super.onClose();
  }
}
