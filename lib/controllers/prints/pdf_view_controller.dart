import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '/controllers/helpers/permissions.dart';
import '/models/print_model.dart';
import '/views/helpers/dialogs.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:image/image.dart' as img;


class PdfViewController extends GetxController {
  final PrintTemplatesModel template;
  final List usernames;
  final List passwords;
  final bool saveFile;
  PdfViewController({
    required this.template,
    required this.usernames,
    required this.passwords,
    required this.saveFile,
  });
  Future<Uint8List>? pdfFuture;
  String myLogo="Created By MikroNet";

  @override
  void onInit() {
    super.onInit();
    myLogo += "  ${getParseDate()}";

    pdfFuture = _generatePdf(
      PdfPageFormat.a4,
      !saveFile ? 'preview' : 'print_done',
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (saveFile) {
        // loadInterstitialAd();
        saveToStorage();
      }
    });
  }

  String getParseDate(){
    DateTime date=DateTime.now().toLocal();
    return "${date.year}-${date.month}-${date.day} ${date.hour}:${date.minute}:${date.second}";
  }

  Uint8List _compressImageBytes(Uint8List imageBytes) {
    const int maxWidth = 800;

    img.Image? image;

    // نحاول JPG أولاً لأنه أخف وأسرع
    image = img.decodeJpg(imageBytes);

    // لو فشل، نجرب PNG
    image ??= img.decodePng(imageBytes);

    // لو فشل الاثنين، نرجع الصورة الأصلية
    if (image == null) return imageBytes;

    if (image.width > maxWidth) {
      image = img.copyResize(image, width: maxWidth);
    }

    return Uint8List.fromList(
      img.encodeJpg(image, quality: 60),
    );
  }

  

  Future<Uint8List> _generatePdf(PdfPageFormat format, String title) async {
    final pdf = pw.Document(version: PdfVersion.pdf_1_5, compress: true);
    // final pdfWidth = PdfPageFormat.a4.width ;
    // final pdfHiegth = PdfPageFormat.a4.height;
    final pdfWidth = format.width;
    final pdfHiegth = format.height;
    
    Uint8List? myImg = template.image; // base64Decode(template.image.toString());
    myImg = _compressImageBytes(myImg);
    final pw.MemoryImage cachedImage = pw.MemoryImage(myImg);

    int numOfCardsToPrint = usernames.length;

    
    double padding = 5;
    double marginitems = 1;
    double borderitems = 1;
    int numOfRows = template.numOfRows; 
    int numOfColumns = template.numOfColumns; 
    int counterForCards = 0;
    int pagesCount = (numOfCardsToPrint / (numOfRows * numOfColumns)).ceil();

    double itemWidth = (((pdfWidth -
            ((2 * borderitems * numOfColumns) + (2 * marginitems * numOfColumns)) -
            (2 * padding)) /
        numOfColumns));
    double itemHeight = (((pdfHiegth -
            ((2 * borderitems * numOfRows) + (2 * marginitems * numOfRows)) -
            (4 * padding)) /
        numOfRows));

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.zero,
        build: (context) {
          return List.generate(pagesCount, (i) {
              return pw.Padding(
                padding: pw.EdgeInsets.symmetric(horizontal: (2 * padding)),
                child: pw.Container(
                    //padding:pw.EdgeInsets.only(top: 1, left: 5, right: 5, bottom: 1),
                    width: pdfWidth,
                    margin: pw.EdgeInsets.zero,
                    height: pdfHiegth,
                    //decoration: pw.BoxDecoration(border: pw.Border.all()),
                    child: pw.Column(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Container(
                            margin: const pw.EdgeInsets.all(0),
                            width: (pdfWidth - 20),
                            height: (3 * padding),
                            alignment: pw.Alignment.center,
                            decoration: const pw.BoxDecoration(
                                border: pw.Border(bottom: pw.BorderSide())),
                            child: pw.Text(
                              myLogo,
                              style: pw.TextStyle(
                                  fontSize: 10, fontWeight: pw.FontWeight.bold),
                            ),
                          ),
                          //pw.SizedBox(height: 5,),
                          pw.Column(
                            mainAxisAlignment: pw.MainAxisAlignment.start,
                            children: List.generate(numOfRows, (i) {
                              return pw.Row(
                                mainAxisAlignment: pw.MainAxisAlignment.start,
                                children: List.generate(numOfColumns, (j) {
                                  if (counterForCards < numOfCardsToPrint) {
                                    counterForCards++;
                                    return pw.Container(
                                      margin: pw.EdgeInsets.all(marginitems),
                                      width: itemWidth,
                                      height: itemHeight,
                                      decoration: pw.BoxDecoration(
                                          border: pw.Border.all(),
                                          image: pw.DecorationImage(
                                              image: cachedImage, //pw.MemoryImage(myImg!),
                                              fit: pw.BoxFit.fill)),
                                      child: pw.Stack(children: [
                                        true
                                            ? pw.Positioned(
                                                // أزلنا الزيادة + 1.5 لتكون القسمة دقيقة
                                                top: (template.usernameLocation.y / 2)+1.5, 
                                                left: (template.usernameLocation.x / 2)+1.5,
                                                child: pw.Container(
                                                    child: pw.Text(
                                                      "${usernames.isEmpty ? '' : usernames[(counterForCards - 1)]}",
                                                        style: pw.TextStyle(
                                                            // أزلنا الزيادة + 1 لحجم الخط
                                                            fontSize: (template.usernameFontSize / 2),
                                                            fontWeight: pw.FontWeight.bold))))
                                            : pw.Positioned(
                                                top: -1,
                                                left: -1,
                                                child: pw.Text("")),
                                                
                                        template.withPassword
                                            ? pw.Positioned(
                                                // أزلنا الزيادة + 1.5 لتكون القسمة دقيقة
                                                top: (template.passwordLocation.y / 2),
                                                left: (template.passwordLocation.x / 2),
                                                child: pw.Container(
                                                    child: pw.Text(
                                                      "${passwords.isEmpty ? '' : passwords[(counterForCards - 1)]}",
                                                        style: pw.TextStyle(
                                                            // أزلنا الزيادة + 1 لحجم الخط
                                                            fontSize: (template.passwordFontSize / 2),
                                                            fontWeight: pw.FontWeight.bold))))
                                            : pw.Positioned(
                                                top: -1,
                                                left: -1,
                                                child: pw.Text(""))
                                      ])
                                    );
                                  }
                                  return pw.SizedBox();
                                }),
                              );
                            }),
                          ),
                          pw.Container(
                            height: (3 * padding),
                            width: (pdfWidth - 20),
                            alignment: pw.Alignment.center,
                            decoration: const pw.BoxDecoration(
                                border: pw.Border(top: pw.BorderSide())),
                            // page number
                            child: pw.Text(
                              "( ${i+1} )",
                              style: const pw.TextStyle(fontSize: 10),
                            ),
                          ),
                        ])),
              );
    

    });
        },
      ),
    );

    return pdf.save();
  }


  
  

  void saveToStorage() async {
    try {
      if (saveFile) {
        if (!await requestStoragePermission()) {
          Get.snackbar(
            'storage_permission_required', 
            'storage_permission_required'
          );
          // ScaffoldMessenger.of(context).showSnackBar(
          //   SnackBar(content: Text(dictionary['storage_permission_required'])),
          // );
          return;
        }

        final directory = Directory("/sdcard/PrintNet/الكروت");
        if (!await directory.exists()) {
          await directory.create(recursive: true);
        }
        String filePath = "/sdcard/PrintNet/الكروت/cards_${getParseDate()}.pdf";
        File pdfFile = File(filePath);

        pdfFile.writeAsBytes(await pdfFuture!);
        
        // pdfFile.writeAsBytes(await _generatePdf(PdfPageFormat.a4,
        //     !isTest ? dictionary['preview'] : dictionary['print_done']));

        Get.snackbar(
          "تم الحفظ في المسار $filePath", 
          "تم الحفظ في المسار $filePath"
        );
        // ScaffoldMessenger.of(context).showSnackBar(
        //   SnackBar(content: Text("تم الحفظ في المسار $filePath")),
        // );
      }
    } catch (e) {
      showErrorDialog(content: 'storage_permission_required');
      // showDialog(context: context, 
      //     builder: (context){
      //       return AlertDialog(
      //         content: Text(dictionary['storage_permission_required']),
      //         actions: [
      //           Center(
      //             child: TextButton(onPressed: (){Navigator.pop(context);}, child: Text(dictionary['done'])),
      //           )
      //         ],
      //       );
      //     });
    }
  }

 


}
