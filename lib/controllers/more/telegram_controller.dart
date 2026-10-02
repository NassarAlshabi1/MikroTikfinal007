import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/dialog_helper.dart';
import '../../models/telegram_settings.dart';
import '../../services/telegram_client.dart';
import '../../services/telegram_report_service.dart';

class TelegramController extends GetxController {
  final tokenCtrl = TextEditingController();
  final chatCtrl = TextEditingController();
  final intervalCtrl = TextEditingController(text: "60");

  final RxBool enabled = false.obs;
  final RxBool sendSales = true.obs;
  final RxBool sendRouter = true.obs;
  final RxBool sendUsers = true.obs;
  final RxBool isLoading = true.obs;
  final RxBool isBusy = false.obs;

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
    sendSales.value = settings.sendSalesReport;
    sendRouter.value = settings.sendRouterStatus;
    sendUsers.value = settings.sendActiveUsers;
  }

  TelegramSettings _currentSettings() => TelegramSettings(
        enabled: enabled.value,
        botToken: tokenCtrl.text.trim(),
        chatId: chatCtrl.text.trim(),
        intervalMinutes: int.tryParse(intervalCtrl.text.trim()) ?? 60,
        sendSalesReport: sendSales.value,
        sendRouterStatus: sendRouter.value,
        sendActiveUsers: sendUsers.value,
      );

  Future<void> save() async {
    final settings = _currentSettings();

    if (settings.enabled && !settings.isConfigured) {
      await showMsgDialog(
        message: "أدخل توكن البوت ومعرّف المحادثة لتشغيل الإرسال الدوري",
        type: MsgType.warning,
      );
      return;
    }

    isBusy.value = true;
    await TelegramSettingsStore.save(settings);
    await TelegramReportService.restart();
    isBusy.value = false;

    await showMsgDialog(
      message: settings.enabled
          ? "تم الحفظ. سيُرسل تقرير كل ${settings.intervalMinutes} دقيقة أثناء تشغيل التطبيق."
          : "تم حفظ الإعدادات (الإرسال الدوري متوقف)",
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

    await showMsgDialog(
      message: response.status
          ? "تم الاتصال بالبوت: @${response.data}\nأرسل /start للبوت من Telegram لتفعيل المحادثة."
          : response.message,
      type: response.status ? MsgType.success : MsgType.error,
    );
  }

  Future<void> sendNow() async {
    isBusy.value = true;
    showLoadingDialog();

    final response = await TelegramReportService.sendReport(_currentSettings());

    hideDialog();
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
