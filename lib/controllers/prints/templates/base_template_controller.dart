import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mikronet/controllers/dialog_helper.dart';
import 'package:pdf/pdf.dart';
import '../../../views/prints/templates/pdf_view.dart';
import '/models/print_model.dart';

abstract class BaseTemplateController extends GetxController {
  TextEditingController profileName = TextEditingController();
  TextEditingController usernameText = TextEditingController();
  TextEditingController passwordText = TextEditingController();
  
  RxInt numrows = 18.obs;
  RxInt numcolumns = 4.obs;
  RxInt usernameFontSize = 14.obs;
  RxInt passwordFontSize = 14.obs;
  
  late ImageProvider<Object> templateImage;
  bool password = false;
  bool username = true;

  // PDF & Dimensions
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

  Uint8List? imageBytes;

  @override
  void onInit() {
    super.onInit();
    usernameText.text = "username_text";
    passwordText.text = "password_text";
  }

  void isWithPassword2(bool value){
    password = value;
    update(); // مهم لتحديث الـ GetBuilder
  }

  Future<Uint8List> getImageAsBytes({String img='images/100.jpg'}) async {
    final ByteData data = await rootBundle.load(img);
    return data.buffer.asUint8List();
  }

  void setItemDimensions() {
    itemWidth = ((pdfWidth - ((2 * borderitems * numcolumns.value) + (2 * marginitems * numcolumns.value)) - (2 * padding)) / numcolumns.value);
    itemHeight = (((pdfHiegth - ((2 * borderitems * numrows.value) + (2 * marginitems * numrows.value)) - (4 * padding)) / numrows.value));
  }

  void setDefaultImage() async {
    Uint8List x = await getImageAsBytes();
    imageBytes = x;
    templateImage = MemoryImage(x);
    update();
  }

  Future<void> pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      Uint8List bytes;
      if (kIsWeb) {
        bytes = await pickedFile.readAsBytes();
      } else {
        File file = File(pickedFile.path);
        bytes = await file.readAsBytes();
      }
      imageBytes = bytes;
      templateImage = MemoryImage(imageBytes!);
      update();
    }
  }

  Map getLayoutData(int id) {
    return {
      "id": id, 
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
      "image": imageBytes ?? getImageAsBytes() // ملاحظة: يفضل معالجة الـ Future هنا، سأتركها كما هي لتطابق الكود الأصلي
    };
  }

  Future<void> preview([PrintTemplatesModel? modelFromApi]) async {
    try {
      Map temp = getLayoutData(49);
      PrintTemplatesModel model = PrintTemplatesModel.fromDataForm(temp);
      
      if(modelFromApi != null) {
        model = modelFromApi;
      }

      List myUsers = List.generate(73, (i) => usernameText.text);
      List myPasswords = List.generate(73, (i) => passwordText.text);
      
      Get.to(() => PdfView(
        usernames: myUsers,
        passwords: myPasswords,
        saveFile: false,
        template: model,
      ));
    } catch (e) {
      showMsgDialog(message: e.toString(),type: MsgType.error);
    }
  }

  @override
  void update([List<Object>? ids, bool condition = true]) {
    setItemDimensions();
    super.update(ids, condition);
  }

  // هذه الدالة سيتم تطبيقها في الإضافة والتعديل كلٌ على حدة
  Future<void> saveAction(); 
}