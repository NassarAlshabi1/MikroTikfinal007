import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/dialog_helper.dart';
import '../../models/telegram_settings.dart';
import '../../services/telegram_client.dart';
import '../../services/telegram_features.dart';
import '../../services/telegram_report_service.dart';

/// متحكم **ضبط البوت** (Token و Chat ID والفاصل الزمني).
class TelegramSetupController extends GetxController {
  final tokenCtrl = TextEditingController();
  final chatCtrl = TextEditingController();
  final intervalCtrl = TextEditingController(text: "60");

  final RxBool enabled = false.obs;
  final RxInt dailyHour = 23.obs;
  final RxBool isLoading = true.obs;
  final RxBool isBusy = false.obs;
  final RxString botUsername = "".obs;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    isLoading.value = true;
    final settings = await TelegramSettingsStore.load();
    isLoading.value = false;

    enabled.value = settings.enabled;
    tokenCtrl.text = settings.botToken;
    chatCtrl.text = settings.chatId;
    intervalCtrl.text = settings.intervalMinutes.toString();
    dailyHour.value = settings.dailySummaryHour;
  }

  Future<void> save() async {
    final token = tokenCtrl.text.trim();
    final chat = chatCtrl.text.trim();

    if (enabled.value && (token.isEmpty || chat.isEmpty)) {
      await showMsgDialog(
        message: "أدخل توكن البوت ومعرّف المحادثة لتشغيل الإشعارات",
        type: MsgType.warning,
      );
      return;
    }

    isBusy.value = true;
    final previous = await TelegramSettingsStore.load();
    await TelegramSettingsStore.save(previous.copyWith(
      enabled: enabled.value,
      botToken: token,
      chatId: chat,
      intervalMinutes: int.tryParse(intervalCtrl.text.trim()) ?? 60,
      dailySummaryHour: dailyHour.value,
    ));
    await TelegramReportService.restart();
    isBusy.value = false;

    await showMsgDialog(
      message: enabled.value
          ? "تم الحفظ ✅ سيُرسل التقرير كل ${intervalCtrl.text.trim()} دقيقة أثناء فتح التطبيق."
          : "تم الحفظ (الإشعارات متوقفة)",
      type: MsgType.success,
    );
  }

  Future<void> testConnection() async {
    if (tokenCtrl.text.trim().isEmpty) {
      await showMsgDialog(message: "أدخل توكن البوت أولًا", type: MsgType.warning);
      return;
    }

    isBusy.value = true;
    final response = await TelegramClient.testConnection(tokenCtrl.text.trim());
    isBusy.value = false;

    if (response.status) botUsername.value = response.data ?? "";

    await showMsgDialog(
      message: response.status
          ? "تم الاتصال بالبوت: @${response.data}\nأرسل /start للبوت من Telegram لتفعيل المحادثة."
          : response.message,
      type: response.status ? MsgType.success : MsgType.error,
    );
  }

  /// إرسال رسالة تجريبية سريعة للتأكد من وصول الإشعارات.
  Future<void> sendTest() async {
    if (!enabled.value) {
      enabled.value = true;
    }
    isBusy.value = true;
    final previous = await TelegramSettingsStore.load();
    await TelegramSettingsStore.save(previous.copyWith(
      enabled: true,
      botToken: tokenCtrl.text.trim(),
      chatId: chatCtrl.text.trim(),
      intervalMinutes: int.tryParse(intervalCtrl.text.trim()) ?? 60,
    ));
    final response = await TelegramReportService.sendFeatureTest('router_status');
    isBusy.value = false;

    await showMsgDialog(
      message: response.message,
      type: response.status ? MsgType.success : MsgType.error,
    );
  }

  @override
  void onClose() {
    tokenCtrl.dispose();
    chatCtrl.dispose();
    intervalCtrl.dispose();
    super.onClose();
  }
}

/// متحكم **تفعيل المميزات** (سبع ميزات + تفعيل/تعطيل الكل + تجربة كل ميزة).
class TelegramFeaturesController extends GetxController {
  final RxMap<String, bool> features = <String, bool>{}.obs;
  final RxBool isLoading = true.obs;
  final RxString busyFeature = "".obs;
  final RxInt dailyHour = 23.obs;
  final RxInt intervalMinutes = 60.obs;

  List<TelegramFeature> get all => TelegramFeatureCatalog.all;

  int get enabledCount => TelegramFeatureCatalog.enabledCount(features);

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    isLoading.value = true;
    final settings = await TelegramSettingsStore.load();
    features.assignAll(TelegramFeatureCatalog.normalize(settings.features));
    dailyHour.value = settings.dailySummaryHour;
    intervalMinutes.value = settings.intervalMinutes;
    isLoading.value = false;
  }

  bool isEnabled(String id) => features[id] == true;

  Future<void> toggle(String id) async {
    features.assignAll(TelegramFeatureCatalog.toggle(features, id));
    await _persist();
  }

  Future<void> setAll(bool value) async {
    features.assignAll(TelegramFeatureCatalog.setAll(features, value));
    await _persist();
  }

  Future<void> setDailyHour(int hour) async {
    dailyHour.value = hour;
    await _persist();
  }

  Future<void> setInterval(int minutes) async {
    intervalMinutes.value = minutes;
    await _persist();
  }

  Future<void> _persist() async {
    final current = await TelegramSettingsStore.load();
    await TelegramSettingsStore.save(current.copyWith(
      features: Map<String, bool>.from(features),
      dailySummaryHour: dailyHour.value,
      intervalMinutes: intervalMinutes.value,
    ));
    await TelegramReportService.restart();
  }

  /// 🚀 إرسال تجربة ميزة محدّدة.
  Future<void> testFeature(String id) async {
    busyFeature.value = id;
    final response = await TelegramReportService.sendFeatureTest(id);
    busyFeature.value = "";

    await showMsgDialog(
      message: response.message,
      type: response.status ? MsgType.success : MsgType.error,
    );
  }
}
