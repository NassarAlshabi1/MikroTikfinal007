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
      AppResponse<List<ProfilesModel>> result = await ProfilesApi.getProfiles();
      allProfiles = result.data ?? [];
      if (allProfiles.isNotEmpty && selectedProfile.value.isEmpty) {
        selectedProfile.value = allProfiles.first.id.toString();
      }
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
      selectedCustomer.value = allCustomers.isNotEmpty ? allCustomers[0].name : "admin";
      update();
    } catch (e) {
      showMsgDialog(message: "Get Customers Error : ${e.toString()}",type: MsgType.error);
    }
  }
  Future<void> getRouterSerial() async {
    var res =await RouterApi.getRouterSerial();
    if(!res.status){
      await showMsgDialog(message: res.message,type: MsgType.error);
      Get.back();
    }
    routerSerial = res.data.toString();
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
      showMsgDialog(message: e.toString(),type: MsgType.error);
      return;
    }

    PrintTemplatesModel? template = allTemplates.firstWhereOrNull((t) => t.id == selectedTemplate.value);
    if (template == null) {
      if (allTemplates.isNotEmpty) {
        template = allTemplates.first;
      } else {
        showMsgDialog(message: "يرجى إنشاء قالب طباعة أولاً من قسم الطباعة", type: MsgType.error);
        return;
      }
    }

    var profile = allProfiles.firstWhereOrNull((p) => p.id.toString() == selectedProfile.value.toString());
    if (profile == null) {
      if (allProfiles.isNotEmpty) {
        profile = allProfiles.first;
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

        await PrintBatchesApi.setCardAddedStatus(
          batchId,
          username: card.username,
          isAdded: true,
        );
        generatedCards[i].isAdd = true;
        generationProgress.value = (i + 1) / totalCards;
      }

      Get.back(); 
      Get.back(); 
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

    PrintTemplatesModel? template = allTemplates.firstWhereOrNull((t) => t.id == selectedTemplate.value);
    if (template == null) {
      if (allTemplates.isNotEmpty) {
        template = allTemplates.first;
      } else {
        showMsgDialog(message: "يرجى إنشاء قالب طباعة أولاً من قسم الطباعة", type: MsgType.error);
        return;
      }
    }

    
    var profile = allProfiles.firstWhereOrNull((p) => p.id.toString() == selectedProfile.value.toString());
    if (profile == null) {
      if (allProfiles.isNotEmpty) {
        profile = allProfiles.first;
      } else {
        showMsgDialog(message: "يرجى إنشاء باقة أولاً من قسم الباقات", type: MsgType.error);
        return;
      }
    }

    prepareCardsData(profile);
    
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
    if (selectedCustomer.value.trim().isEmpty) {
      throw "يرجى اختيار العميل";
    }
    if (selectedProfile.value.trim().isEmpty) {
      throw "يرجى اختيار الباقة";
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

  void _getDataFromMikrotik() async {
    await getRouterSerial();
    await getAllCustomers(); // استدعاء دالة جلب العملاء
    await getAllTemplates();
    await getallProfiles();
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
