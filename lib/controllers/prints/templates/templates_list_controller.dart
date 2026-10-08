import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mikronet/controllers/dialog_helper.dart';
import '/api/print_api.dart';
import '/models/print_model.dart';
import '/views/helpers/dialogs.dart';
import '../../../views/prints/templates/templates_form.dart';
import '../../../views/prints/templates/pdf_view.dart';
import 'package:pdf/pdf.dart';

class TemplatesListController extends GetxController {
  List<PrintTemplatesModel> allTemplates=[];
  late PrintTemplatesModel editedTemplate;
  int editId=0;

  TextEditingController profileName = TextEditingController();
  TextEditingController usernameText= TextEditingController();
  TextEditingController passwordText = TextEditingController();
  RxInt numrows=18.obs;
  RxInt numcolumns=4.obs;
  // RxInt usernameLength = 9.obs;
  // RxInt passwordLength = 5.obs;
  RxInt usernameFontSize = 14.obs;
  RxInt passwordFontSize = 14.obs;
  ImageProvider<Object> templateImage = const AssetImage('images/100.jpg');
  bool password = false;
  bool username = true;

  //Get Pdf Style and default values
  double padding = 5;
  double marginitems = 1;
  double pdfWidth = PdfPageFormat.a4.width;
  double pdfHiegth = PdfPageFormat.a4.height;
  double borderitems = 1;
  late double itemWidth;
  late double itemHeight;
  RxDouble x = 100.0.obs;
  RxDouble y = 100.0.obs;
  RxDouble x2 = 101.0.obs;
  RxDouble y2 = 101.0.obs;
  // int numcards = 9;

  // int profileId = 0;
  // int myId = 0;

  Uint8List? _imageBytes;





  /// عدد الصفوف التي تعذّرت قراءتها (تُعرض ملاحظة ولا تُفرغ القائمة كلها).
  int skippedTemplates = 0;
  bool isLoading = true;
  String loadError = '';
  int _requestCounter = 0;

  Future<void> getAll() async {
    final requestId = ++_requestCounter;
    isLoading = true;
    loadError = '';
    update();

    try {
      final result = await PrintTemplatesApi.getAllTemplates();
      if (requestId != _requestCounter) return;
      final temp = <PrintTemplatesModel>[];
      skippedTemplates = 0;

      for (final row in result) {
        // صف تالف واحد لا يُخفي بقية القوالب.
        try {
          if (row is! Map || !PrintTemplatesModel.isUsableRow(row)) {
            skippedTemplates++;
            continue;
          }
          temp.add(PrintTemplatesModel.fromDatabase(row));
        } catch (_) {
          skippedTemplates++;
        }
      }

      allTemplates = temp;
    } catch (e) {
      if (requestId == _requestCounter) {
        loadError = 'تعذّر تحميل تصاميم الكروت: $e';
      }
    } finally {
      if (requestId == _requestCounter) {
        isLoading = false;
        update();
      }
    }
  }

  /// ضمان تحميل صورة القالب قبل الحفظ (كان `_imageBytes` قد يكون null
  /// فيُحفظ Future داخل حقل الصورة ⇒ قالب تالف لا يظهر لاحقًا).
  Future<void> ensureImageLoaded() async {
    if (_imageBytes != null && _imageBytes!.isNotEmpty) return;
    try {
      _imageBytes = await _getImageAsBytes();
    } catch (_) {}
  }


  Future<void> delete(int id) async {
    try {
      final result = await PrintTemplatesApi.deleteTemplate(id);
      if (result <= 0) {
        showMsgDialog(message: 'لم يتم حذف القالب. أعد المحاولة.', type: MsgType.error);
        return;
      }
      await getAll();
      await showMsgDialog(message: 'تم حذف تصميم الكرت بنجاح', type: MsgType.success);
    } catch (e) {
      await showMsgDialog(message: 'تعذّر حذف التصميم: $e', type: MsgType.error);
    }
  }







  void isWithPassword(){
    password = (!password);
    update();
  }

  void isWithPassword2(bool value){
    password = value;
    update();
  }

  Future<Uint8List> _getImageAsBytes({String img='images/100.jpg'}) async {
    final ByteData data = await rootBundle.load(img);
    return data.buffer.asUint8List();
  }

  Map getLayoutData(){
    return {
      "id": editId!=0?editId: 49, 
      "name": profileName.text,
      "password": password ? 1 : 0,
      "rows": numrows.value,
      "columns": numcolumns.value,
      "username_fontsize": usernameFontSize.value.toDouble(),
      "password_fontsize": passwordFontSize.value.toDouble(),
      "username_location_x": x.value,
      "username_location_y": y.value,
      "password_location_x": x2.value,
      "password_location_y": y2.value,
      // لا نُرجع Future هنا أبدًا: إما بايتات محمّلة أو مصفوفة فارغة
      "image": _imageBytes ?? Uint8List(0)
    };
  }

  Future<void> preview([int id=0])async{
    try {
      Map temp = getLayoutData();
      PrintTemplatesModel model=PrintTemplatesModel.fromDataForm(temp);
      if(id!=0){
        temp=await PrintTemplatesApi.getTemplateData(id);
        model=PrintTemplatesModel.fromDatabase(temp);
      }
      final cardsPerPage = model.numOfRows * model.numOfColumns;
      List myUsers=List.generate(cardsPerPage, (i)=>usernameText.text);
      List myPasswords=List.generate(cardsPerPage, (i)=>passwordText.text);
      
      
        Get.to(PdfView(
          usernames: myUsers,
          passwords: myPasswords,
          saveFile: false,
          template: model,
        ));
    } catch (e) {
      showErrorDialog(content: e.toString());
    }
  }

  Future<void> addOne()async{
    try {
      await ensureImageLoaded();
      if (profileName.text.trim().isEmpty) {
        showErrorDialog(content: "اكتب اسم القالب أولًا");
        return;
      }
      Map temp = getLayoutData();
      PrintTemplatesModel model=PrintTemplatesModel.fromDataForm(temp);
      final int r = await PrintTemplatesApi.addOneTemplate(model.toDatabase());
      if (r <= 0) {
        showErrorDialog(content: "لم يتم حفظ القالب — تحقق من المساحة المتاحة");
        return;
      }
      await getAll();
      showErrorDialog(title: "تم الحفظ", content: "القالب \"${profileName.text.trim()}\" جاهز للاستخدام في الدفعات");
    } catch (e) {
      showErrorDialog(content: "تعذّر حفظ القالب: ${e.toString()}");
    }
  }

  Future<void> editOne()async{
    try {
      await ensureImageLoaded();
      Map temp = getLayoutData();
      PrintTemplatesModel model=PrintTemplatesModel.fromDataForm(temp);
      int r= await PrintTemplatesApi.templateEdit(editId,model.toDatabase());
      // isEdit=false;
      getAll();
      showErrorDialog(title: "edit",content: r.toString());
    } catch (e) {
      showErrorDialog(content: e.toString());
    }
  }

  // Future<void> saveOne()async{
  //   if (isEdit) {
  //     editOne();
  //   }
  //   else{
  //     addOne();
  //   }
  // }
  
  void setItemDimensions(){
    itemWidth = (
      (
        pdfWidth - (
          ( 2 * borderitems * numcolumns.value )
          + 
          ( 2 * marginitems * numcolumns.value )
        ) 
        -
        ( 2 * padding )
      ) / numcolumns.value
    );
      itemHeight = (((pdfHiegth -
              ((2 * borderitems * numrows.value) + (2 * marginitems * numrows.value)) -
              (4 * padding)) /
          numrows.value));
  }

  void setDefaultImage() async {
    Uint8List x = await _getImageAsBytes();
    _imageBytes = x;
    templateImage = MemoryImage(x);
    update();
  }

  
  @override
  void onInit() {
    super.onInit();
    getAll();
    initialSettings();
    usernameText.text = "username_text";
    passwordText.text = "password_text";
  }

  Future<void> openAddForm()async{
    initialSettings();
    Get.to(PrintTemplatesDesignView(
      designerController: this,
      isEdit: false,
    ));
  }

  Future<void> openEditForm(int index)async {
    try {
      // isEdit=true;
      editedTemplate=allTemplates[index];
      profileName.text = editedTemplate.name;
      _imageBytes=editedTemplate.image;
      templateImage=MemoryImage(editedTemplate.image);
      numcolumns=editedTemplate.numOfColumns.obs;
      numrows.value=editedTemplate.numOfRows;
      password=editedTemplate.withPassword;
      usernameFontSize.value=editedTemplate.usernameFontSize.toInt();
      passwordFontSize.value=editedTemplate.passwordFontSize.toInt();
      x.value=editedTemplate.usernameLocation.x;
      y.value=editedTemplate.usernameLocation.y;
      x2.value=editedTemplate.passwordLocation.x;
      y2.value=editedTemplate.passwordLocation.y;
      editId=editedTemplate.id;
      
      setItemDimensions();
      update();
      Get.to(PrintTemplatesDesignView(designerController: this,isEdit: true,));
    } catch (e) {
      showErrorDialog(content: e.toString());
    }
    
    
    // initialSettings();
    // usernameText.text = "username_text";
    // passwordText.text = "password_text";
  }

  @override
  void update([List<Object>? ids, bool condition = true]) {
    setItemDimensions();
    super.update(ids, condition);
  }

  void initialSettings() {
    profileName.text = "";
    setDefaultImage();
    setItemDimensions();
    x.value = itemWidth + 10;
    y.value = itemHeight + 10;
    x2.value = itemWidth + 11;
    y2.value = itemHeight + 11;
    update();
  }

  @override
  void onClose() {
    profileName.dispose();
    usernameText.dispose();
    passwordText.dispose();
    super.onClose();
  }

  Future<void> pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedFile =
        await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      Uint8List bytes;
      if (kIsWeb) {
        bytes = await pickedFile.readAsBytes();
      } else {
        File file = File(pickedFile.path);
        bytes = await file.readAsBytes();
      }
      _imageBytes = bytes;
      templateImage = MemoryImage(_imageBytes!);
      update();
    }
  }

  
}