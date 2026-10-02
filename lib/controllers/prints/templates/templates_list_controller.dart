import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
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
  late ImageProvider<Object> templateImage;
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





  Future<void> getAll()async{
    try {
      List result=await PrintTemplatesApi.getAllTemplates();
      List<PrintTemplatesModel> temp=[];

      if(result.isNotEmpty){
        for (var i in result) {
          temp.add(
            PrintTemplatesModel.fromDatabase(i)
          );
        }
      }
      allTemplates=temp;
      update();
    } catch (e) {
      showErrorDialog(content: e.toString());
    }
  }


  Future<void> delete(int id)async{
    try {
      await PrintTemplatesApi.deleteTemplate(id);
      getAll();
      showErrorDialog(title: "done", content: "done",titleColor: Colors.green);
    } catch (e) {
      showErrorDialog(content: e.toString());
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
      "image": _imageBytes??_getImageAsBytes()
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
      List myUsers=List.generate(73, (i)=>usernameText.text);
      List myPasswords=List.generate(73, (i)=>passwordText.text);
      
      
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
      Map temp = getLayoutData();
      PrintTemplatesModel model=PrintTemplatesModel.fromDataForm(temp);
      int r= await PrintTemplatesApi.addOneTemplate(model.toDatabase());
      getAll();
      showErrorDialog(title: "add",content: r.toString());
    } catch (e) {
      showErrorDialog(content: e.toString());
    }
  }

  Future<void> editOne()async{
    try {
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