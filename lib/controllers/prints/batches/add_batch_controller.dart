import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mikronet/api/print_api.dart';
import 'package:mikronet/api/profiles_api.dart';
import 'package:mikronet/api/cards_api.dart';
import 'package:mikronet/api/router_api.dart';
import 'package:mikronet/controllers/dialog_helper.dart';
import 'package:mikronet/controllers/helpers/functions.dart';
import 'package:mikronet/models/print_model.dart';
import 'package:mikronet/models/profiles_model.dart';
import 'package:mikronet/models/cards_model.dart'; // تم إضافة هذا الاستيراد لجلب CustomerModel
import 'package:mikronet/models/response.dart';
// import 'package:mikronet/views/helpers/dialogs.dart';
// import 'package:mikronet/views/prints/batches/generated_cards.dart';
import 'package:mikronet/views/prints/templates/pdf_view.dart';

class BatchesFormController extends GetxController {
  Map dataInsert = {};
  List<PrintTemplatesModel> allTemplates = [];
  List<ProfilesModel> allProfiles = [];
  List<CustomerModel> allCustomers = []; // قائمة العملاء
  List<String> generatedUsernames = [];
  List<String> generatedPasswords = [];
  List<GeneratedCardsModel> generatedCards = [];
  String routerSerial = "";
  String routerIdentityError = "";
  String customersLoadError = "";
  bool isLoadingRouterData = true;
  bool isPreparingPreview = false;
  String? _previewSignature;

  // Form Variables
  TextEditingController batchName = TextEditingController();
  TextEditingController numOfCards = TextEditingController();
  TextEditingController prefix = TextEditingController();
  TextEditingController suffix = TextEditingController();
  TextEditingController usernameLength = TextEditingController();
  TextEditingController passwordLength = TextEditingController();
  RxInt selectedTemplate = 0.obs;
  RxString selectedProfile = "".obs;
  RxString selectedCustomer = "".obs; // العميل المختار
  String selectedPasswordType = "none";
  DateTime dateTime = DateTime.now();

  // Progress Variables للـ Dialog
  RxDouble generationProgress = 0.0.obs;
  RxString generationStatus = "".obs;

  /// عدد القوالب التي تعذّرت قراءتها (تُعرض ملاحظة للمستخدم ولا تُفرغ القائمة).
  int skippedTemplates = 0;
  String templatesLoadError = "";

  /// جلب كل القوالب المحفوظة.
  ///
  /// إصلاح مهم: كان صف واحد تالف (صورة غير Base64 أو صف قديم بلا اسم) يُطلق
  /// استثناءً فيُفرغ القائمة بالكامل ⇒ «القالب لا يظهر». الآن كل صف يُقرأ داخل
  /// `try` مستقل، والصفوف غير المفهومة تُستبعد وتُحصى فقط.
  Future<void> getAllTemplates({bool showError = true}) async {
    try {
      List result = await PrintTemplatesApi.getAllTemplates();
      final temp = <PrintTemplatesModel>[];
      skippedTemplates = 0;

      for (final i in result) {
        try {
          if (i is! Map) {
            skippedTemplates++;
            continue;
          }
          if (!PrintTemplatesModel.isUsableRow(i)) {
            skippedTemplates++;
            continue;
          }
          temp.add(PrintTemplatesModel.fromDatabase(i));
        } catch (_) {
          skippedTemplates++;
        }
      }

      allTemplates = temp;
      templatesLoadError = "";

      // اختيار أول قالب تلقائيًا حتى يظهر القالب المطلوب مباشرة في الخانة
      if (allTemplates.isNotEmpty &&
          !allTemplates.any((t) => t.id == selectedTemplate.value)) {
        selectedTemplate.value = allTemplates.first.id;
      }
      _normalizePasswordTypeForTemplate();

      update();
    } catch (e) {
      templatesLoadError = e.toString();
      if (showError) {
        showMsgDialog(
          message: "تعذّر جلب القوالب: ${e.toString()}",
          type: MsgType.error,
        );
      }
      update();
    }
  }

  /// إعادة تحميل القوالب (زر التحديث في الشاشة).
  Future<void> reloadTemplates() => getAllTemplates(showError: false);

  void selectTemplate(int id) {
    selectedTemplate.value = id;
    _normalizePasswordTypeForTemplate();
    update();
  }

  void _normalizePasswordTypeForTemplate() {
    final template = allTemplates.firstWhereOrNull((item) => item.id == selectedTemplate.value);
    if (template == null) return;
    final matchingType = template.withPassword ? 'diff' : 'none';
    if (selectedPasswordType != matchingType) {
      selectedPasswordType = matchingType;
    }
  }

  Future<void> getallProfiles() async {
    try {
      final result = await ProfilesApi.getProfiles();
      if (!result.status || result.data == null) {
        throw Exception(!result.status && result.message.isNotEmpty
            ? result.message
            : 'لم يُرجع الراوتر قائمة باقات صالحة');
      }
      allProfiles = result.data!;
      if (allProfiles.isNotEmpty && selectedProfile.value.isEmpty) {
        selectedProfile.value = allProfiles.first.id.toString();
      }
      update();
    } catch (e) {
      allProfiles = [];
      selectedProfile.value = '';
      showMsgDialog(message: "تعذّر جلب الباقات: ${e.toString()}", type: MsgType.error);
      update();
    }
  }

  /// جلب العملاء الفعليين؛ لا نختلق حسابًا افتراضيًا إذا لم يرجع الراوتر أي عميل.
  Future<void> getAllCustomers() async {
    try {
      final result = await CardsApi.getCustomers();
      if (!result.status || result.data == null) {
        throw Exception(!result.status && result.message.isNotEmpty
            ? result.message
            : 'لم يُرجع الراوتر قائمة عملاء صالحة');
      }

      allCustomers = result.data!
          .where((customer) => customer.name.trim().isNotEmpty)
          .toList();
      selectedCustomer.value = allCustomers.isNotEmpty ? allCustomers.first.name : '';
      customersLoadError = allCustomers.isEmpty ? 'لا توجد أسماء عملاء متاحة من الراوتر.' : '';
    } catch (e) {
      allCustomers = [];
      selectedCustomer.value = '';
      customersLoadError = e.toString().replaceFirst('Exception: ', '');
    }
    update();
  }

  Future<void> getRouterSerial() async {
    try {
      final response = await RouterApi.getRouterSerial();
      routerSerial = response.status ? (response.data?.trim() ?? '') : '';
      routerIdentityError = routerSerial.isEmpty
          ? (!response.status && response.message.isNotEmpty
              ? response.message
              : 'لم يرجع الراوتر رقمًا تسلسليًا صالحًا')
          : '';
    } catch (e) {
      routerSerial = '';
      routerIdentityError = e.toString().replaceFirst('Exception: ', '');
    }
    update();
  }

  void prepareCardsData(ProfilesModel profile, {List<String> existingUsers = const []}) {
    int count = int.parse(numOfCards.text.trim());
    int uLen = int.parse(usernameLength.text.trim());
    int pLen = int.tryParse(passwordLength.text.trim()) ?? 5;

    generatedUsernames = generateUniqueRandomStrings(
      count: count,
      length: uLen,
      prefix: prefix.text.trim(),
      suffix: suffix.text.trim(),
      users: existingUsers, 
    );

    if (selectedPasswordType == "diff") {
      generatedPasswords = generateUniqueRandomStrings(
        count: count,
        length: pLen,
      );
    } else {
      generatedPasswords = List<String>.filled(count, "");
    }

    generatedCards = List.generate(
      generatedUsernames.length,
      (i) {
        return GeneratedCardsModel(
          id: 0,
          username: generatedUsernames[i],
          batchId: 0,
          password: generatedPasswords[i],
          profileName: profile.name,
          isAdd: false,
        );
      },
    );
  }

  Future<int> addBatchToDB() async {
    final profileObj = allProfiles.firstWhereOrNull((p) => p.id.toString() == selectedProfile.value.toString()) ?? 
        (allProfiles.isNotEmpty ? allProfiles.first : null);

    Map<String, dynamic> data = {
      'name': batchName.text.trim(),
      'created_at': dateTime.microsecondsSinceEpoch,
      'template_id': selectedTemplate.value,
      'generated_cards': generatedUsernames.join(","),
      'cards_profile': profileObj != null ? profileObj.name : selectedProfile.value,
      'card_prefix': prefix.text.trim(),
      'card_suffix': suffix.text.trim(),
      'customer': selectedCustomer.value, // إضافة العميل للحفظ في قاعدة البيانات
      'router_serial': routerSerial,
    };
    
    int batchId = await PrintBatchesApi.addOneBatch(data);
    
    if (batchId > 0) {
      List<Map<String, dynamic>> cardsData = generatedCards.map((c) {
        var map = c.toDatabase();
        map['batch_id'] = batchId; 
        return map;
      }).toList();
      
      await PrintBatchesApi.addBatchCards(cardsData, batchId);
    }
    return batchId;
  }

  void showProgressDialog() {
    Get.dialog(
      WillPopScope(
        onWillPop: () async => false, 
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          content: Obx(() => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 20),
              Text(
                generationStatus.value,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 15),
              LinearProgressIndicator(value: generationProgress.value),
              const SizedBox(height: 10),
              Text("${(generationProgress.value * 100).toStringAsFixed(1)} %"),
            ],
          )),
        ),
      ),
      barrierDismissible: false,
    );
  }

  Future<void> handleGenerate() async {
    try {
      validation();
    } catch (e) {
      showMsgDialog(message: e.toString(), type: MsgType.error);
      return;
    }

    final template = allTemplates.firstWhereOrNull((t) => t.id == selectedTemplate.value);
    if (template == null) {
      showMsgDialog(
        message: "يرجى إنشاء قالب طباعة صالح أو اختياره أولاً",
        type: MsgType.error,
      );
      return;
    }

    final profile = allProfiles.firstWhereOrNull(
      (p) => p.id.toString() == selectedProfile.value.toString(),
    );
    if (profile == null) {
      showMsgDialog(message: "يرجى اختيار باقة صالحة من الراوتر", type: MsgType.error);
      return;
    }

    final requestedCount = int.tryParse(numOfCards.text.trim()) ?? 0;
    if (_previewSignature != _configurationSignature() ||
        generatedCards.length != requestedCount) {
      showMsgDialog(
        message: "يجب فتح معاينة الإعدادات الحالية قبل إنشاء الدفعة. إذا غيّرت أي حقل، أعد المعاينة.",
        type: MsgType.info,
      );
      return;
    }

    generationProgress.value = 0.0;
    generationStatus.value = "يرجى الانتظار...\nإعادة التحقق من أسماء الكروت في الراوتر";
    showProgressDialog();

    try {
      final mikrotikResponse = await CardsApi.getAllCards();
      if (!mikrotikResponse.status || mikrotikResponse.data == null) {
        final message = !mikrotikResponse.status && mikrotikResponse.message.isNotEmpty
            ? mikrotikResponse.message
            : 'لم يرجع الراوتر قائمة كروت صالحة';
        throw Exception("تعذّر إعادة التحقق من الكروت: $message");
      }

      final existingUsernames = mikrotikResponse.data!
          .map((card) => card.username.trim())
          .where((username) => username.isNotEmpty)
          .toSet();
      final collisions = generatedUsernames
          .where((username) => existingUsernames.contains(username))
          .toList();
      if (collisions.isNotEmpty) {
        _previewSignature = null;
        throw Exception(
          "أصبحت بعض أسماء المعاينة مستخدمة على الراوتر. أعد المعاينة لتوليد أسماء جديدة قبل الإنشاء.",
        );
      }

      generationStatus.value = "حفظ الدفعة في قاعدة البيانات...";
      final batchId = await addBatchToDB();
      if (batchId <= 0) throw Exception("حدث خطأ أثناء الحفظ في قاعدة البيانات");

      final totalCards = generatedCards.length;
      for (int i = 0; i < totalCards; i++) {
        final card = generatedCards[i];
        generationStatus.value = "إضافة الكرت: ${card.username}\n(${i + 1} من $totalCards)";
        generationProgress.value = i / totalCards;

        final addRes = await CardsApi.addOneCard(
          customer: selectedCustomer.value,
          username: card.username,
          password: card.password,
          profile: profile.name,
        );

        if (!addRes.status) {
          throw Exception("خطأ أثناء إضافة الكرت ${card.username}: ${addRes.message}");
        }

        await PrintBatchesApi.setCardAddedStatus(
          batchId,
          username: card.username,
          isAdded: true,
        );
        generatedCards[i].isAdd = true;
        generationProgress.value = (i + 1) / totalCards;
      }

      _previewSignature = null;
      Get.back();
      Get.back();
      showSuccessDialog();
    } catch (e) {
      Get.back();
      showMsgDialog(message: e.toString(), type: MsgType.error);
    }
  }

  Future<void> handlePreview() async {
    if (isPreparingPreview) return;

    try {
      validation();
    } catch (e) {
      showMsgDialog(message: e.toString(), type: MsgType.error);
      return;
    }

    final template = allTemplates.firstWhereOrNull((t) => t.id == selectedTemplate.value);
    final profile = allProfiles.firstWhereOrNull(
      (p) => p.id.toString() == selectedProfile.value.toString(),
    );
    if (template == null || profile == null) {
      showMsgDialog(
        message: "تعذّر تحديد القالب أو الباقة المحددة من البيانات المحمّلة",
        type: MsgType.error,
      );
      return;
    }

    isPreparingPreview = true;
    _previewSignature = null;
    update();
    try {
      final response = await CardsApi.getAllCards();
      if (!response.status || response.data == null) {
        final message = !response.status && response.message.isNotEmpty
            ? response.message
            : 'لم يرجع الراوتر قائمة كروت صالحة';
        throw Exception('تعذّر جلب الكروت للتحقق من الأسماء المتاحة: $message');
      }

      final existingUsernames = response.data!
          .map((card) => card.username.trim())
          .where((username) => username.isNotEmpty)
          .toList(growable: false);
      prepareCardsData(profile, existingUsers: existingUsernames);

      final requestedCount = int.tryParse(numOfCards.text.trim()) ?? 0;
      if (generatedCards.length != requestedCount) {
        throw Exception('تعذّر توليد العدد المطلوب من أسماء المستخدمين الفريدة');
      }

      final previewSignature = _configurationSignature();
      final previewCount = generatedCards.length < 10 ? generatedCards.length : 10;
      final shouldOpenPreview = await Get.dialog<bool>(
            AlertDialog(
              title: Text('معاينة الدفعة: ${batchName.text.trim()}'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('عدد الكروت: ${generatedCards.length}'),
                  const SizedBox(height: 5),
                  Text('العميل: ${selectedCustomer.value}'),
                  Text('الباقة: ${profile.name}'),
                  Text('القالب: ${template.name}'),
                  Text(
                    'نمط الدخول: ${selectedPasswordType == 'diff' ? 'اسم مستخدم مع كلمة مرور' : 'اسم مستخدم فقط'}',
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'ستُعرض أول $previewCount كروت فقط. لن تُحفظ الدفعة أو تُرسل إلى الراوتر من شاشة المعاينة.',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Get.back(result: false),
                  child: const Text('رجوع للتعديل'),
                ),
                FilledButton.icon(
                  onPressed: () => Get.back(result: true),
                  icon: const Icon(Icons.visibility_outlined),
                  label: const Text('عرض الكروت'),
                ),
              ],
            ),
            barrierDismissible: false,
          ) ??
          false;

      if (!shouldOpenPreview) return;

      await Get.to(
        PdfView(
          usernames: generatedUsernames.take(previewCount).toList(),
          passwords: generatedPasswords.take(previewCount).toList(),
          template: template,
          saveFile: false,
        ),
      );

      // الاعتماد على نفس الأسماء التي شاهدها المستخدم عند الإنشاء، ما لم تتغير
      // الإعدادات بعد الرجوع من المعاينة.
      if (_configurationSignature() == previewSignature) {
        _previewSignature = previewSignature;
      }
    } catch (e) {
      showMsgDialog(message: 'تعذّرت معاينة الدفعة: $e', type: MsgType.error);
    } finally {
      isPreparingPreview = false;
      update();
    }
  }

  String _configurationSignature() {
    final template = allTemplates.firstWhereOrNull((t) => t.id == selectedTemplate.value);
    final profile = allProfiles.firstWhereOrNull(
      (p) => p.id.toString() == selectedProfile.value.toString(),
    );
    return jsonEncode([
      batchName.text.trim(),
      numOfCards.text.trim(),
      prefix.text.trim(),
      suffix.text.trim(),
      usernameLength.text.trim(),
      passwordLength.text.trim(),
      selectedTemplate.value,
      template?.name,
      template?.withPassword,
      profile?.name,
      selectedProfile.value,
      selectedCustomer.value.trim(),
      selectedPasswordType,
      routerSerial.trim(),
    ]);
  }

  void validation() {
    if (routerSerial.trim().isEmpty) {
      throw routerIdentityError.isNotEmpty
          ? "تعذّر التحقق من الراوتر: $routerIdentityError"
          : "انتظر قراءة هوية الراوتر قبل إنشاء الدفعة";
    }
    if (selectedCustomer.value.trim().isEmpty ||
        !allCustomers.any((customer) => customer.name == selectedCustomer.value)) {
      throw customersLoadError.isNotEmpty
          ? "تعذّر اختيار عميل فعلي من الراوتر: $customersLoadError"
          : "يرجى اختيار عميل موجود على الراوتر";
    }
    if (selectedProfile.value.trim().isEmpty ||
        !allProfiles.any((profile) => profile.id.toString() == selectedProfile.value)) {
      throw "يرجى اختيار باقة موجودة على الراوتر";
    }
    if (batchName.text.trim().isEmpty) {
      throw "يرجى إدخال اسم الدفعة";
    }

    final cardCount = int.tryParse(numOfCards.text.trim());
    if (cardCount == null || cardCount <= 0) {
      throw "عدد الكروت يجب أن يكون رقمًا أكبر من صفر";
    }
    final usernameSize = int.tryParse(usernameLength.text.trim());
    if (usernameSize == null || usernameSize <= 0) {
      throw "طول اسم المستخدم يجب أن يكون رقمًا أكبر من صفر";
    }

    final template = allTemplates.firstWhereOrNull((item) => item.id == selectedTemplate.value);
    if (template == null) {
      throw "يرجى اختيار قالب طباعة صالح";
    }

    if (template.withPassword) {
      if (selectedPasswordType != "diff") {
        throw "القالب المحدد يطبع كلمة مرور؛ اختر نمط (اسم مستخدم + كلمة مرور)";
      }
      final passwordSize = int.tryParse(passwordLength.text.trim());
      if (passwordSize == null || passwordSize <= 0) {
        throw "طول كلمة المرور يجب أن يكون رقمًا أكبر من صفر";
      }
    } else if (selectedPasswordType != "none") {
      throw "القالب المحدد لا يطبع كلمة مرور؛ اختر نمط (اسم مستخدم فقط)";
    }
  }

  void init() {
    usernameLength.text = "7";
    passwordLength.text = "5";
    update();
  }

  @override
  void onInit() {
    super.onInit();
    init();
    _getDataFromMikrotik();
  }

  @override
  void onClose() {
    batchName.dispose();
    numOfCards.dispose();
    prefix.dispose();
    suffix.dispose();
    usernameLength.dispose();
    passwordLength.dispose();
    super.onClose();
  }

  Future<void> _getDataFromMikrotik() async {
    isLoadingRouterData = true;
    update();
    try {
      await getRouterSerial();
      await getAllCustomers();
      await getAllTemplates();
      await getallProfiles();
    } finally {
      isLoadingRouterData = false;
      update();
    }
  }

  @override
  void update([List<Object>? ids, bool condition = true]) {
    dataInsert = {
      "name": batchName.text,
      "total": numOfCards.text,
      "customer": selectedCustomer.value,
      "profile": selectedProfile.value,
      "template_id": selectedTemplate.value,
      "password_type": selectedPasswordType,
      "card_prefix": prefix.text,
      "card_suffix": suffix.text,
      "username_length": usernameLength.text,
      "password_length": passwordLength.text,
    };
    super.update(ids, condition);
  }
  
  void showSuccessDialog() {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.green, size: 70),
            const SizedBox(height: 15),
            const Text("عملية ناجحة",
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
            const Text("تم إنشاء الدفعة وإضافتها للميكروتك بنجاح. هل تطبعها الآن؟",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 12)),
            const SizedBox(height: 25),
            Row(children: [
              Expanded(
                  child: TextButton(
                      onPressed: () {
                        Get.back();
                      },
                      child: const Text("لاحقاً"))),
              Expanded(
                  child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12))),
                      onPressed: () {
                        Get.back();
                        Get.to(PdfView(
                          usernames: generatedCards.map((g)=>g.username).toList(), 
                          passwords: generatedCards.map((g)=>g.password).toList(), 
                          template: allTemplates.where((t)=>t.id==selectedTemplate.value).first,
                        ));
                      },
                      child: const Text("طباعة PDF"))),
            ])
          ],
        ),
      ),
    );
  }
}
