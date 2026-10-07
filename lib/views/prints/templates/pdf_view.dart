import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/prints/pdf_view_controller.dart';
import '/models/print_model.dart';
import 'package:printing/printing.dart';


class PdfView extends StatelessWidget {
  final PrintTemplatesModel template;
  final List usernames;
  final List? passwords;
  final bool saveFile;
  const PdfView({
    super.key,
    required this.usernames,
    this.passwords,
    this.saveFile = true,
    required this.template
    });
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: pdfBuilder(
        PdfViewController(
          template: template, 
          usernames: usernames, 
          passwords: passwords??usernames, 
          saveFile: saveFile
        )
      ),
    );
  }
}

GetBuilder<PdfViewController> pdfBuilder(PdfViewController controller){
  return
  GetBuilder<PdfViewController>(
    init: controller,
    builder: (pdfController) {
      return PdfPreview(
        build: (format) async => await pdfController.pdfFuture!,
        // useActions: false,
      );
    }
  );
}

