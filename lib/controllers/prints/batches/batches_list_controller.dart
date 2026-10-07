// import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:mikronet/views/prints/batches/batch_cards_page.dart';
import 'package:mikronet/views/prints/templates/pdf_view.dart';
import '../../../api/router_api.dart';
import '../../dialog_helper.dart';
import '/views/helpers/dialogs.dart';
import '/api/print_api.dart';
import '/models/print_model.dart';

// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// ... (نفس الاستيرادات السابقة)



class BatchesListController extends GetxController{

  
  List<PrintBatchesModel> allBatches=[];
  bool isLoading=false;
  bool isDeleteLoading=false;
  var routerSerial = "";
  // TextEditingController batchName=TextEditingController();
  
  // List<GeneratedCardsModel> generatedCards = [];
  Future<void> getRouterSerial() async {
    var res =await RouterApi.getRouterSerial();
    if(!res.status){
      await showMsgDialog(message: res.message,type: MsgType.error);
      Get.back();
    }
    routerSerial = res.data.toString();
  }

  Future<void> deleteBatch(PrintBatchesModel batch,int deleteOption)async{
    isDeleteLoading=true;
    update();
    try {
      // int r=-1;
      String response="";
      if (deleteOption==1) {
        // الحذف من المايكروتك فقط
        response=(await PrintBatchesApi.deleteFromServer(batch.id))=="done"?"1":"0";
        // showErrorDialog(content: rr);
      }
      else if (deleteOption==2) {
        // الحذف من sqflite فقط
        response=(await PrintBatchesApi.deleteFromLocal(batch.id))>0?"2":"0";
      }
      else if (deleteOption==3) {
        // كود الحذف من الاثنين معاً
        response=(await PrintBatchesApi.deleteBatch(batch.id))=="done"?"3":"0";
        // showErrorDialog(content: rr);
      }
      if (response=="1") {
        Get.back();
        update();
      }
      else if (response=="2") {
        allBatches.remove(batch);
        Get.back();
        update();
      }
      else if (response=="3") {
        allBatches.remove(batch);
        Get.back();
        update();
      }
    } catch (e) {
      showErrorDialog(content: e.toString());
    }
    finally{
      isDeleteLoading=false;
      update();
    }
  }
  
  Future<void> editBatch(PrintBatchesModel batch,String name,DateTime date)async{
    try {
      if (name.trim().isNotEmpty) {
        int r=await PrintBatchesApi.batchEdit(
          batch.id, 
          {
            'name':name.trim(),
            'created_at':date.microsecondsSinceEpoch,
          }
        );
        if (r>0) {
          batch.name=name.trim();
          batch.createdAt = date;
          Get.back();
          update();
        }
      }
    } catch (e) {
      showErrorDialog(content: e.toString());
    }
  }

  Future<void> getBatchCards(int id)async{
    try {
      await getAllBatches2();
      var r= allBatches.firstWhere((b)=>b.id==id);
      var cards=List.generate(r.cards.length, (i){
        return GeneratedCardsModel.fromDatabase(r.cards[i]);
      });
      Get.to(GeneratedCardsView(cards));
    } catch (e) {
      showErrorDialog(content: e.toString());
    }
  }

  Future<void> getBatchPreview(int batchId)async{
    try {
      var batch = allBatches.firstWhere((b)=>b.id==batchId);
      var response=await PrintTemplatesApi.getTemplateData(batch.templateId);
      PrintTemplatesModel template=PrintTemplatesModel.fromDatabase(response);
      
      var cards=List.generate(batch.cards.length, (i){
        return GeneratedCardsModel.fromDatabase(batch.cards[i]);
      });
      List usernames=cards.map((c)=>c.username).toList();
      List passwords=cards.map((c)=>c.password).toList();
      Get.to(PdfView(
        usernames: usernames, 
        passwords: passwords, 
        template: template,
        saveFile: false,
      ));
      // showErrorDialog(content: passwords.toString());
      // Get.to(GeneratedCardsView(cards));
    } catch (e) {
      showErrorDialog(content: e.toString());
    }
  }

  Future<void> getAllBatches2()async{
    try {
      var serial =await RouterApi.getRouterSerial();
      List result=await PrintBatchesApi.getAllBatchesByRouter(serial.data.toString());
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
      showErrorDialog(title: "error in get batches2",content: e.toString());
    }
  }

  
  

  


  @override
  void onInit() {
    super.onInit();
    // getAllBatches();
    getAllBatches2();
  }

  

  


  



  




  
  
  



}






