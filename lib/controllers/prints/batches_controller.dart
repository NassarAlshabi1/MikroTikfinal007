import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mikronet/api/profiles_api.dart';
import 'package:mikronet/controllers/helpers/functions.dart';
import 'package:mikronet/models/profiles_model.dart';
import 'package:mikronet/models/response.dart';
// import 'package:mikronet/models/response.dart';
import 'package:mikronet/views/prints/batches/batch_cards_page.dart';
import 'package:mikronet/views/prints/templates/pdf_view.dart';
import '../../api/router_api.dart';
import '../dialog_helper.dart';
// import '/views/helpers/dialogs.dart';
import '/api/print_api.dart';
import '/models/print_model.dart';



class BatchesController extends GetxController{
  List<Map<String, dynamic>> passwordTypes=[
    {"id": "none", "label": "بدون \n", "icon": Icons.minimize_outlined},
    {"id": "diff", "label": "ارقام مختلفة \n", "icon": Icons.pin_outlined},
    {"id": "same", "label": "مطابقة اسم المستخدم", "icon": Icons.abc_rounded},
  ];
  Map dataInsert={};
  List<PrintBatchesModel> allBatches=[];
  List<PrintTemplatesModel> allTemplates=[];
  List<ProfilesModel> allProfiles=[];
  List<GeneratedCardsModel> generatedCards = [];
  List<String> generatedUsernames=[];
  List<String> generatedPasswords=[];
  String routerSerial = "";

  

  void getBatchCards(int id){
    try {
      var r= allBatches.firstWhere((b)=>b.id==id);
      var cards=List.generate(r.cards.length, (i){
        return GeneratedCardsModel.fromDatabase(r.cards[i]);
      });
      Get.to(GeneratedCardsView(cards));
    } catch (e) {
      showMsgDialog(message: e.toString(),type: MsgType.error);
    }
  }

  void getBatchPreview(int id){
    try {
      var r= allBatches.firstWhere((b)=>b.id==id);
      var cards=List.generate(r.cards.length, (i){
        return GeneratedCardsModel.fromDatabase(r.cards[i]);
      });
      List users=cards.map((c)=>c.username).toList();
      List passwords=cards.map((c)=>c.password).toList();
      PrintTemplatesModel m=allTemplates.firstWhere((t)=>t.id==id);
      Get.to(PdfView(
        usernames: users, 
        passwords: passwords, 
        template: m,
        saveFile: false,
      ));
    } catch (e) {
      showMsgDialog(message: e.toString(),type: MsgType.error);
    }
  }

  Future<void> getAllBatches2()async{
    try {
      List result=await PrintBatchesApi.getAllBatchesByRouter(routerSerial);
      // var cards=await PrintBatchesApi.get
      // var cards=List.generate(r.length, (i){
      //   return GeneratedCardsModel.fromDatabase(r[i]);
      // });
      
      List<PrintBatchesModel> temp=[];
      // print(result[0].toString());
      if (result.isNotEmpty) {
        for (var i in result) {
          temp.add(PrintBatchesModel.fromDatabase(i)); 
        }
        allBatches=temp;
      }
      update();
    } catch (e) {
      showMsgDialog(message: e.toString(),type: MsgType.error);
    }
  }

  Future<void> getAllTemplates()async{
    try {
      List result=await PrintTemplatesApi.getAllTemplates();
      List<PrintTemplatesModel> temp=[];
      if (result.isNotEmpty) {
        for (var i in result) {
          temp.add(PrintTemplatesModel.fromDatabase(i));
        }
        allTemplates=temp;
      }
      update();
    } catch (e) {
      showMsgDialog(message: e.toString(),type: MsgType.error);
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
  Future<void> getallProfiles()async{
    try {
      AppResponse result=await ProfilesApi.getProfiles();
      List<ProfilesModel> temp=[];
      if (result.status && result.data !=null ) {
        for (var i in result.data) {
          temp.add(ProfilesModel.fromMikrotik(i));
        }
        allProfiles=temp;
      }
      update();
    } catch (e) {
      showMsgDialog(message: e.toString(),type: MsgType.error);
    }
  }

  Future<void> generateCards()async{
    var profile=allProfiles.firstWhere((p)=>p.id==selectedProfile.value);
    generatedUsernames=generateUniqueRandomStrings(
        count: int.parse(numOfCards.text.trim()),
        length: int.parse(usernameLength.text),
        prefix: prefix.text,
        suffix: suffix.text
      );
    if(dataInsert["password_type"]=="diff"){
      generatedPasswords=generateUniqueRandomStrings(
        count: int.parse(numOfCards.text.trim()),
        length: int.tryParse(passwordLength.text)??5,
      );
    }
    else if(dataInsert["password_type"]=="same"){
      generatedPasswords=generatedUsernames;
    }
    else{
      generatedPasswords=List.generate(int.parse(numOfCards.text), (i)=>"");
    }
    generatedCards=List.generate(
      generatedUsernames.length, 
      (i){
        return GeneratedCardsModel(
          id: 0, 
          username: generatedUsernames[i], 
          batchId: 0, 
          password: generatedPasswords[i], 
          profileName: profile.name, 
          isAdd: false
        );
      }
    );
  }

  


  @override
  void onInit() {
    super.onInit();
    init();
    // getAllBatches();
    getAllBatches2();
    getAllTemplates();
    getallProfiles();
    getRouterSerial();
  }

  @override
  void update([List<Object>? ids, bool condition = true]) {
    dataInsert={
      "name":batchName.text,
      "total":numOfCards.text,
      "profile":selectedProfile.value,
      "template_id":selectedTemplate.value,
      "password_type":selectedPasswordType ,
      "card_prefix":prefix.text,
      "card_suffix":suffix.text ,
      "username_length":usernameLength.text ,
      "password_length":passwordLength.text ,
    };
    dataInsert["profile"]=selectedProfile.value;
    super.update(ids, condition);
  }

  void init(){
    usernameLength.text="7";
    passwordLength.text="5";
    update();
    // selectedTemplate=allTemplates.isEmpty?0.obs:allTemplates[0].id.obs;
    // selectedProfile=allProfiles.isEmpty?"".obs:allProfiles[0].name.obs;
  }


  // Form Variables

  TextEditingController batchName=TextEditingController();
  TextEditingController numOfCards=TextEditingController();
  TextEditingController prefix=TextEditingController();
  TextEditingController suffix=TextEditingController();
  TextEditingController usernameLength=TextEditingController();
  TextEditingController passwordLength=TextEditingController();
  RxInt selectedTemplate=0.obs;
  RxString selectedProfile="".obs;
  String selectedPasswordType="none";
  DateTime dateTime=DateTime.now();



  Future<void> addBatch2()async{
    try {
      List<Map<String, dynamic>> cards=generatedCards.map((c)=>c.toDatabase()).toList();
      Map<String, dynamic> data={
        'name':batchName.text.trim(),
        'created_at':dateTime.microsecondsSinceEpoch ,
        'template_id':selectedTemplate.value,
        'generated_cards':'cards',
        'cards_profile':selectedProfile.value,
        'card_prefix':prefix.text.trim(),
        'card_suffix':suffix.text.trim(),
      };
      var response=await PrintBatchesApi.addOneBatch(data);
      if(response>0){
        response =await PrintBatchesApi.addBatchCards(cards, response);
      }
      // var response=await PrintBatchesApi.addOneBatch2(data,cards);
      if (response>0) {
        _showSuccessDialog();
      }
    } catch (e) {
      showMsgDialog(message: e.toString(),type: MsgType.error);
    }
  }

  Future<void> handlePreview()async{
    try {
      validation();
    } catch (e) {
      showMsgDialog(message: e.toString(),type: MsgType.error);
      return;
    }

    PrintTemplatesModel template=allTemplates.firstWhere(
      (t)=>t.id==selectedTemplate.value
    );
    if(!template.withPassword && selectedPasswordType=="same"){
      bool confirm=await showConfirmDialog(
        message: "القالب بدون كلمة مرور ونمط توليد كلمة المرور مشابه لاسم المستخدم هل انت متاكد ",
        onConfirm: () {
          
        }
      );
      if(!confirm){return;}
    }
    preview();
  }
  
  Future<void> handleGenerate()async{
    try {
      validation();
    } catch (e) {
      showMsgDialog(message: e.toString(),type: MsgType.error);
      return;
    }

    PrintTemplatesModel template=allTemplates.firstWhere(
      (t)=>t.id==selectedTemplate.value
    );
    // var profile=allProfiles.firstWhere((p)=>p.id==selectedProfile.value);
    if(!template.withPassword && selectedPasswordType=="same"){
      bool confirm=await showConfirmDialog(
        message: "القالب بدون كلمة مرور ونمط توليد كلمة المرور مشابه لاسم المستخدم هل انت متاكد ",
        onConfirm :() {
          
        },
      );
      if(!confirm){return;}
    }
    generateCards();
    // List<Map<String, dynamic>> generatedCards=List.generate(
    //   generatedUsernames.length, 
    //   (i)=>{'username': generatedUsernames[i], 'password': generatedPasswords[i], 'profile': profile.name, 'isAdded': true},
    // );
    await addBatch2();
    Get.off( GeneratedCardsView(generatedCards));
  }
  
  void preview(){
    PrintTemplatesModel template=allTemplates.firstWhere(
      (t)=>t.id==selectedTemplate.value
    );
    generateCards();
    Get.to(
      PdfView(
        usernames: generatedUsernames,
        passwords: generatedPasswords, 
        template: template,
        saveFile: false,
      )
    );
  }

  void validation(){
    if(selectedTemplate.value==0){
      throw "please select template";
    }
    if(selectedProfile.value==""){throw "please select profile";}

    if(batchName.text.trim().isEmpty ||
    numOfCards.text.trim().isEmpty ||
    usernameLength.text.trim().isEmpty){
      throw "fill all fields";
    }
    var template=allTemplates.firstWhere((t)=>t.id==selectedTemplate.value);
    if(template.withPassword){
      switch (selectedPasswordType) {
        case "none":
          throw "القالب مع كلمة مرور ونمط توليد كلمة المرور بلا ";
        case "same":
          throw "القالب مع كلمة مرور ونمط توليد كلمة المرور مشابه لاسم المستخدم ";
        default:
        if(passwordLength.text.trim().isEmpty){
          throw "ادخل طول كلمة المرور ";
        }
      }
    }else{
      switch (selectedPasswordType) {
        // case "same":
        //   throw "";
        case "diff":
          throw "لايمكن ان يكون نمط كلمة المرور مختلف بينما القالب بدون كلمة مرور";
        default:
      }
    }
    
  }



void _showSuccessDialog() {
  Get.dialog(
    // context: context,
    // barrierDismissible: false,
    // builder: (ctx) => 
    AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle_rounded,
              color: Colors.green, size: 70),
          const SizedBox(height: 15),
          const Text("عملية ناجحة",
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
          const Text("تم إنشاء الدفعة. هل تطبعها الآن؟",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 25),
          Row(children: [
            Expanded(
                child: TextButton(
                    onPressed: () {
                      Get.back();
                      // Navigator.pop(ctx);
                      // Navigator.pop(context);
                    },
                    child: const Text("لاحقاً"))),
            Expanded(
                child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12))),
                    onPressed: () {
                      // Navigator.pop(ctx);
                      // controller
                      //     .printBatchToPdf(nameCtrl.text, selectedTemplate);
                      // Navigator.pop(context);
                    },
                    child: const Text("طباعة PDF"))),
          ])
        ],
      ),
    ),
  );
}


  
  
  // 2. متغير للتحكم في عملية الإرسال للسيرفر
  bool isUploading = false; 

  // ==========================================
  // 4. دوال التحكم بالرفع للسيرفر (جديدة)
  // ==========================================
  Future<void> startUploadingToServer() async {
    if (isUploading) return;
    isUploading = true;
    update();

    for (int i = 0; i < generatedCards.length; i++) {
      if (!isUploading) break; // توقف إذا ضغط المستخدم على إيقاف العملية
      
      if (!generatedCards[i].isAdd) {
        try {
          // -------------- هنا تضع كود الـ API للمايكروتك --------------
          // مثال: await MikrotikApi.addUser(generatedCards[i].username, ...);
          
          await Future.delayed(const Duration(milliseconds: 300)); // محاكاة الرفع
          // -----------------------------------------------------------

          // تحديث حالة الكرت محلياً بعد نجاح رفعه للمايكروتك
          generatedCards[i] = GeneratedCardsModel(
             id: generatedCards[i].id,
             username: generatedCards[i].username,
             batchId: generatedCards[i].batchId,
             password: generatedCards[i].password,
             profileName: generatedCards[i].profileName,
             isAdd: true, // تم الإضافة بنجاح
          );
          
          // يمكنك هنا أيضاً استدعاء دالة لتحديث is_add في SQLite لهذا الكرت
          // await DBApi.update("cards", {"is_add": 1}, "username='${generatedCards[i].username}'");

          update(); // تحديث الواجهة لكي يتحول الكرت للون الأخضر مباشرة
        } catch (e) {
          print("فشل رفع الكرت: ${generatedCards[i].username} - خطأ: $e");
          // يمكن هنا إظهار رسالة أو تجاوز الكرت للذي يليه
        }
      }
    }
    
    isUploading = false;
    update();
    Get.snackbar("ملاحظة", "توقفت عملية الإرسال", snackPosition: SnackPosition.BOTTOM);
  }

  void stopUploading() {
    isUploading = false;
    update();
  }
  void goToAddBatchPage(){
    
  }



}






