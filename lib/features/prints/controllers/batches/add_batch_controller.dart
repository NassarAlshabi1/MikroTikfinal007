import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mikronet/features/prints/data/print_api.dart';
import 'package:mikronet/features/cards/data/profiles_api.dart';
import 'package:mikronet/features/cards/data/cards_api.dart';
import 'package:mikronet/core/mikrotik/router_api.dart';
import 'package:mikronet/core/mikrotik/mikrotik_client.dart';
import 'package:mikronet/core/ui/dialogs/dialog_helper.dart';
import 'package:mikronet/core/utils/functions.dart';
import 'package:mikronet/features/prints/models/print_model.dart';
import 'package:mikronet/features/prints/models/batch_generation_rules.dart';
import 'package:mikronet/features/cards/models/profiles_model.dart';
import 'package:mikronet/features/cards/models/cards_model.dart'; // تم إضافة هذا الاستيراد لجلب CustomerModel
import 'package:mikronet/core/models/app_response.dart';
// import 'package:mikronet/views/helpers/dialogs.dart';
// import 'package:mikronet/views/prints/batches/generated_cards.dart';
import 'package:mikronet/features/prints/views/templates/pdf_view.dart';
import 'package:mikronet/features/prints/controllers/batches/batches_list_controller.dart';

class BatchesFormController extends GetxController {
  /// أنماط كروت شائعة في تطبيقات MikroTik، مع اختيار نمط واحد لكل حقل.
  static const Map<String, String> characterPatternLabels = {
    "lowercase": "أحرف صغيرة (abcd)",
    "uppercase": "أحرف كبيرة (ABCD)",
    "mixedLetters": "مزيج أحجام (aBcD)",
    "lowercaseNumbers": "صغيرة وأرقام (abcd1234)",
    "uppercaseNumbers": "كبيرة وأرقام (ABCD1234)",
    "mixedNumbers": "مزيج أحجام وأرقام (aBcD1234)",
    "numbers": "أرقام فقط (1234)",
  };
  static const Map<String, String> characterPatternPools = {
    "lowercase": "abcdefghijklmnopqrstuvwxyz",
    "uppercase": "ABCDEFGHIJKLMNOPQRSTUVWXYZ",
    "mixedLetters": "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ",
    "lowercaseNumbers": "abcdefghijklmnopqrstuvwxyz0123456789",
    "uppercaseNumbers": "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789",
    "mixedNumbers": "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789",
    "numbers": "0123456789",
  };
  String selectedUsernamePattern = "numbers";
  String selectedPasswordPattern = "numbers";
  bool passwordMatchesUsername = false;
  List<PrintTemplatesModel> allTemplates = [];
  List<ProfilesModel> allProfiles = [];
  List<CustomerModel> allCustomers = []; // قائمة العملاء
  List<String> generatedUsernames = [];
  List<String> generatedPasswords = [];
  List<GeneratedCardsModel> generatedCards = [];
  String routerSerial = "";

  // Form Variables
  TextEditingController batchName = TextEditingController();
  TextEditingController numOfCards = TextEditingController();
  TextEditingController numOfPages = TextEditingController();
  TextEditingController prefix = TextEditingController();
  TextEditingController suffix = TextEditingController();
  TextEditingController usernameLength = TextEditingController();
  TextEditingController passwordLength = TextEditingController();
  TextEditingController excludedCharsCtrl = TextEditingController();
  bool excludeCharEnabled = false;
  RxInt selectedTemplate = 0.obs;
  RxString selectedProfile = "".obs;
  RxString selectedCustomer = "".obs; // العميل المختار
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

      _selectCompatibleTemplate();
      syncCardsFromPages();

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


  Future<void> getallProfiles() async {
    try {
      AppResponse<List<ProfilesModel>> result = await ProfilesApi.getProfiles();
      allProfiles = result.data ?? [];
      final choices = availableProfiles;
      if (choices.isNotEmpty &&
          !choices.any((profile) => profile.id == selectedProfile.value)) {
        selectedProfile.value = choices.first.id;
      }
      _selectCompatibleTemplate();
      update();
    } catch (e) {
      showMsgDialog(message: "Get Profiles Error : ${e.toString()}",type: MsgType.error);
    }
  }

  // دالة لجلب العملاء من ميكروتك
  Future<void> getAllCustomers() async {
    try {
      AppResponse<List<CustomerModel>> result = await CardsApi.getCustomers();
      allCustomers = result.data ?? [];
      selectedCustomer.value = allCustomers.isNotEmpty ? allCustomers.first.name : "";
      update();
    } catch (e) {
      showMsgDialog(message: "Get Customers Error : ${e.toString()}",type: MsgType.error);
    }
  }
  Future<void> getRouterSerial() async {
    try {
      final response = await RouterApi.getRouterSerial();
      routerSerial = response.status ? response.data?.toString() ?? "" : "";
    } catch (_) {
      routerSerial = "";
    }
  }

  /// يختلف الاسم بحسب إصدار User Manager: عميل في RouterOS 6 ومجموعة في 7.
  String get customerFieldLabel => "عميل User Manager";

  String get customerFieldHint => "اختر العميل";

  /// RouterOS 6 profiles are owned by a User Manager customer. Keep the
  /// selected package list scoped to that same customer; v7 uses groups and
  /// has no equivalent profile owner field in this model.
  List<ProfilesModel> get availableProfiles => allProfiles
      .where((profile) => profile.customer == selectedCustomer.value)
      .toList();

  void selectCustomer(String customer) {
    selectedCustomer.value = customer;
    final choices = availableProfiles;
    selectedProfile.value = choices.isNotEmpty ? choices.first.id : "";
    _selectCompatibleTemplate();
    syncCardsFromPages();
    update();
  }

  ProfilesModel? get selectedProfileModel =>
      allProfiles.firstWhereOrNull((profile) => profile.id == selectedProfile.value);

  List<PrintTemplatesModel> get compatibleTemplates {
    final profileName = selectedProfileModel?.name;
    return allTemplates.where((template) =>
      template.linkedProfileName.isEmpty || template.linkedProfileName == profileName
    ).toList();
  }

  void _selectCompatibleTemplate() {
    final choices = compatibleTemplates;
    final selectedName = selectedProfileModel?.name;
    final specific = choices.firstWhereOrNull(
      (template) => template.linkedProfileName == selectedName && selectedName != null,
    );
    final current = choices.firstWhereOrNull(
      (template) => template.id == selectedTemplate.value,
    );
    final fallback = current != null && (specific == null || current.linkedProfileName.isNotEmpty)
        ? current
        : (specific ?? current ?? (choices.isEmpty ? null : choices.first));
    selectedTemplate.value = fallback?.id ?? 0;
  }

  void selectProfile(String id) {
    selectedProfile.value = id;
    _selectCompatibleTemplate();
    syncCardsFromPages();
    update();
  }

  PrintTemplatesModel? get selectedPrintTemplate =>
      compatibleTemplates.firstWhereOrNull((x) => x.id == selectedTemplate.value);

  void selectTemplate(int id) {
    selectedTemplate.value = id;
    syncCardsFromPages();
    update();
  }

  /// عدد الكروت في الصفحة الواحدة حسب القالب المختار (صفوف × أعمدة).
  int get cardsPerPage {
    final t = selectedPrintTemplate;
    final perPage = (t?.numOfRows ?? 0) * (t?.numOfColumns ?? 0);
    return perPage > 0 ? perPage : 51;
  }

  /// ربط عدد الصفحات بعدد الكروت مثل ABOTALAL — كتابة أحدهما تحسب الآخر.
  void syncPagesFromCards() {
    final count = int.tryParse(numOfCards.text.trim()) ?? 0;
    numOfPages.text = count > 0
        ? ((count + cardsPerPage - 1) ~/ cardsPerPage).toString()
        : "";
  }

  void syncCardsFromPages() {
    final pages = int.tryParse(numOfPages.text.trim()) ?? 0;
    numOfCards.text = pages > 0 ? (pages * cardsPerPage).toString() : "";
  }

  void prepareCardsData(ProfilesModel profile, {List<String> existingUsers = const []}) {
    final count = int.parse(numOfCards.text.trim());
    final uLen = int.parse(usernameLength.text.trim());
    final pLen = int.tryParse(passwordLength.text.trim()) ?? 5;

    // أحرف يدوية مستبعدة (خيار استبعاد حرف/رقم — مثل ABOTALAL)
    final excluded = excludeCharEnabled
        ? excludedCharsCtrl.text.trim().split("").toSet()
        : const <String>{};

    generatedUsernames = generateUniqueRandomStrings(
      count: count,
      length: uLen,
      prefix: prefix.text.trim(),
      suffix: suffix.text.trim(),
      characterPool: characterPatternPools[selectedUsernamePattern],
      excludedChars: excluded,
      users: existingUsers, 
    );

    final templateHasPassword = selectedPrintTemplate?.withPassword ?? false;
    if (!templateHasPassword) {
      generatedPasswords = List.generate(count, (_) => "");
    } else if (passwordMatchesUsername) {
      generatedPasswords = List<String>.from(generatedUsernames);
    } else {
      generatedPasswords = generateUniqueRandomStrings(
        count: count,
        length: pLen,
        characterPool: characterPatternPools[selectedPasswordPattern],
        excludedChars: excluded,
      );
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
      PopScope(
        canPop: false, 
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
      showMsgDialog(message: e.toString(),type: MsgType.error);
      return;
    }

    final PrintTemplatesModel? template = selectedPrintTemplate;
    if (template == null) {
      showMsgDialog(
        message: allTemplates.isEmpty
            ? "يرجى إنشاء قالب طباعة أولاً من قسم الطباعة"
            : "لا يوجد قالب مرتبط بهذه الباقة أو قالب عام؛ اربط قالبًا بها من إعدادات القوالب.",
        type: MsgType.error,
      );
      return;
    }

    var profile = availableProfiles.firstWhereOrNull((p) => p.id == selectedProfile.value);
    if (profile == null) {
      if (availableProfiles.isNotEmpty) {
        profile = availableProfiles.first;
      } else {
        showMsgDialog(message: "يرجى إنشاء باقة أولاً من قسم الباقات", type: MsgType.error);
        return;
      }
    }

    generationProgress.value = 0.0;
    generationStatus.value = "يرجى الانتظار...\nجلب الكروت من ميكروتك";
    showProgressDialog();

    try {
      var mikrotikResponse = await CardsApi.getAllCards();
      List<String> existingUsernames = [];
      if (mikrotikResponse.status && mikrotikResponse.data != null) {
        existingUsernames = mikrotikResponse.data!.map((e) => e.username).toList();
      } else {
        throw Exception("فشل في جلب الكروت: ${mikrotikResponse.message}");
      }

      generationStatus.value = "جاري توليد كروت فريدة...";
      prepareCardsData(profile, existingUsers: existingUsernames);

      generationStatus.value = "حفظ الدفعة في قاعدة البيانات...";
      int batchId = await addBatchToDB();
      if (batchId <= 0) throw Exception("حدث خطأ أثناء الحفظ في قاعدة البيانات");

      int totalCards = generatedCards.length;
      for (int i = 0; i < totalCards; i++) {
        var card = generatedCards[i];
        
        generationStatus.value = "إضافة الكرت: ${card.username}\n(${i + 1} من $totalCards)";
        generationProgress.value = (i) / totalCards;

        var addRes = await CardsApi.addOneCard(
          customer: selectedCustomer.value, // استخدام العميل المحدد بدلاً من profile.customer
          username: card.username,
          password: card.password,
          profile: profile.name,
        );

        if (!addRes.status) {
          throw Exception("خطأ أثناء إضافة الكرت ${card.username}: ${addRes.message}");
        }

        generatedCards[i].isAdd = true; 
        generationProgress.value = (i + 1) / totalCards;
      }

      Get.back();
      Get.back();
      if (Get.isRegistered<BatchesListController>()) {
        Get.find<BatchesListController>().getAllBatches2();
      }
      showSuccessDialog();

    } catch (e) {
      Get.back(); 
      showMsgDialog(message: e.toString(),type: MsgType.error);
    }
  }

  Future<void> handlePreview() async {
    try {
      validation();
    } catch (e) {
      showMsgDialog(message: e.toString(),type: MsgType.error);
      return;
    }

    final PrintTemplatesModel? template = selectedPrintTemplate;
    if (template == null) {
      showMsgDialog(
        message: allTemplates.isEmpty
            ? "يرجى إنشاء قالب طباعة أولاً من قسم الطباعة"
            : "لا يوجد قالب مرتبط بهذه الباقة أو قالب عام؛ اربط قالبًا بها من إعدادات القوالب.",
        type: MsgType.error,
      );
      return;
    }

    var profile = availableProfiles.firstWhereOrNull((p) => p.id == selectedProfile.value);
    if (profile == null) {
      if (availableProfiles.isNotEmpty) {
        profile = availableProfiles.first;
      } else {
        showMsgDialog(message: "يرجى إنشاء باقة أولاً من قسم الباقات", type: MsgType.error);
        return;
      }
    }

    try {
      prepareCardsData(profile);
    } catch (error) {
      showMsgDialog(message: error.toString(), type: MsgType.error);
      return;
    }

    Get.to(
      PdfView(
        usernames: generatedUsernames,
        passwords: generatedPasswords,
        template: template,
        saveFile: false,
      ),
    );
  }

  void validation() {
    if (routerSerial.trim().isEmpty) {
      throw "تعذّر تحديد الراوتر؛ تحقق من الاتصال ثم أعد فتح شاشة إنشاء الدفعة";
    }
    if (selectedCustomer.value.trim().isEmpty ||
        !allCustomers.any((customer) => customer.name == selectedCustomer.value)) {
      throw "لا توجد ${customerFieldLabel} صالحة على الراوتر؛ أنشئها أو تحقق من صلاحيات User Manager";
    }
    if (selectedProfile.value.trim().isEmpty ||
        !availableProfiles.any((p) => p.id == selectedProfile.value)) {
      throw "اختر باقة User Manager مملوكة للعميل المحدد";
    }
    final template = selectedPrintTemplate;
    if (template == null) {
      throw "يرجى اختيار قالب طباعة صالح";
    }
    if (batchName.text.trim().isEmpty) {
      throw "يرجى إدخال اسم الدفعة";
    }

    final count = int.tryParse(numOfCards.text.trim());
    if (count == null || count < 1 || count > 10000) {
      throw "عدد الكروت يجب أن يكون بين 1 و10000";
    }
    final usernameSize = int.tryParse(usernameLength.text.trim());
    if (usernameSize == null || usernameSize < 1 || usernameSize > 32) {
      throw "طول الجزء العشوائي لاسم المستخدم يجب أن يكون بين 1 و32";
    }
    if (prefix.text.length + usernameSize + suffix.text.length > 255) {
      throw "اسم المستخدم أطول من الحد المسموح به بعد إضافة البداية والنهاية";
    }

    final credentialError = BatchGenerationRules.credentialConfigurationError(
      usernamePattern: selectedUsernamePattern,
      templateHasPassword: template.withPassword,
      passwordPattern: selectedPasswordPattern,
      passwordMatchesUsername: passwordMatchesUsername,
      passwordLength: passwordLength.text,
    );
    if (credentialError != null) throw credentialError;
  }

  void init() {
    usernameLength.text = "7";
    passwordLength.text = "5";
    numOfPages.text = "1";
    syncCardsFromPages();
    update();
  }

  @override
  void onClose() {
    batchName.dispose();
    numOfCards.dispose();
    numOfPages.dispose();
    prefix.dispose();
    suffix.dispose();
    usernameLength.dispose();
    passwordLength.dispose();
    excludedCharsCtrl.dispose();
    super.onClose();
  }

  @override
  void onInit() {
    init();
    _getDataFromMikrotik();
    super.onInit();
  }
  void _getDataFromMikrotik()async{
    await getRouterSerial();
    await getAllCustomers(); // استدعاء دالة جلب العملاء
    await getallProfiles();
    await getAllTemplates();
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
                          template: selectedPrintTemplate!,
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
