import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mikronet/features/cards/data/profiles_api.dart';
import 'package:mikronet/features/cards/models/profiles_model.dart';
import 'package:mikronet/core/ui/dialogs/dialog_helper.dart';
import 'package:mikronet/features/cards/data/cards_api.dart';
import 'package:mikronet/features/cards/models/cards_model.dart';
import 'package:mikronet/core/models/app_response.dart';
import 'package:mikronet/features/cards/controllers/cards/cards_list_controller.dart';
import 'package:mikronet/features/distributors/data/distributors_api.dart';

class CardInfoController extends GetxController {
  CardModel card;
  List<ProfilesModel>profiles=[];
  Rxn<ProfilesModel> selectedProfile = Rxn<ProfilesModel>();

  CardInfoController({required this.card});

  late TextEditingController userCtrl;
  late TextEditingController passCtrl;
  late TextEditingController packageCtrl;
  
  RxString status = "".obs; 
  var isChanged = false;
  @override
  void onInit() {
    getProfiles();
    super.onInit();
    userCtrl = TextEditingController(text: card.username);
    passCtrl = TextEditingController(text: card.password);
    packageCtrl = TextEditingController(text: card.package);
    status.value = card.statusDisplay;
  }

  @override
  void onClose() {
    userCtrl.dispose();
    passCtrl.dispose();
    packageCtrl.dispose();
    super.onClose();
  }


  Future<void> saveChanges() async {
    if(card.username == userCtrl.text && card.password == passCtrl.text) return;
    showConfirmDialog(
      message: "هل انت متاكد من تعديل البيانات",
       onConfirm: _saveChanges
    );
  }
  
  void _saveChanges() async {
    showLoadingDialog();
    
    try {
      AppResponse<void> response = await CardsApi.cardEdit(
        username: card.username, 
        data: {
          "username": userCtrl.text,
          "password": passCtrl.text,
        }
      );
      hideDialog();

      if (response.status) {
        card = CardModel(id: card.id, username: userCtrl.text, password: passCtrl.text, profile: card.profile, status: card.status, customer: card.customer);
        isChanged = true;
        showMsgDialog(message: response.message,type: MsgType.success);
        
      } else {
        showMsgDialog(message: response.message);
      }
    } catch (e) {
      hideDialog();
      showMsgDialog(message: "Error saving changes: $e");
    }
  }

  Future<void> updateProfile()async{
    showLoadingDialog();
    
    try {
      AppResponse<void> response = await CardsApi.addCardProfile(customer: card.customer, username: card.username, profile: selectedProfile.value?.name??'');
      hideDialog();

      if (response.status) {
        card = CardModel(id: card.id, username: userCtrl.text, password: passCtrl.text, profile: selectedProfile.value?.name??card.profile, status: card.status, customer: card.customer);
        isChanged = true;
        Get.back();
        showMsgDialog(message: response.message,type: MsgType.success);
        
      } else {
        showMsgDialog(message: response.message);
      }
    } catch (e) {
      hideDialog();
      showMsgDialog(message: "Error saving changes: $e");
    }
    // var response=await CardsApi.addCardProfile(customer: card.customer, username: card.username, profile: selectedProfile.value?.name??'');
    // if (!response.status) {
    //   showMsgDialog(message: response.message);
    //   return;
    // }
    // card = CardModel(id: card.id, username: userCtrl.text, password: passCtrl.text, profile: selectedProfile.value?.name??card.profile, status: card.status, customer: card.customer);
    // isChanged = true;
    // showMsgDialog(message: 'تم تجديد الكرت');
  }

  Future<void> getProfiles()async{
    var response = await ProfilesApi.getProfiles();
    if(!response.status){
      showMsgDialog(message: response.message);
      return;
    }
    profiles=response.data!;
    selectedProfile.value=profiles.firstWhereOrNull((p)=>p.name==card.package)??profiles.first;
    // if(card.package!="unknown"){
    //   selectedProfile=profiles
    // }
    // update();
    // showMsgDialog(message: message)
  }


  Future<void> changeStatus(String newStatus) async {
    showMsgDialog(message: "تغيير الحالة مباشرة غير مدعوم حالياً");
  }

  Future<void> _deleteCard() async {
    showLoadingDialog();
    
    try {
      final deletionReady = await DistributorsApi.prepareCardDeletion([card.username]);
      if (!deletionReady.status || deletionReady.data != true) {
        hideDialog();
        await showMsgDialog(message: deletionReady.message, type: MsgType.warning);
        return;
      }
      AppResponse<void> response = await CardsApi.deleteCard(card.username);
      hideDialog();

      if (response.status) {
        Get.back(result: AppResponse(status: true, message: "delete",data: card));
        showMsgDialog(message: "تم حذف الكرت بنجاح");
      } else {
        showMsgDialog(message: response.message);
      }
    } catch (e) {
      hideDialog();
      showMsgDialog(message: "Error deleting card: $e");
    }
  }
  
  void goBack() {
    
    Get.back(result: AppResponse(status: isChanged, message: "",data: card));
  }

void showDeleteConfirm() {
  showConfirmDialog(
    message: "هذا الإجراء سيقوم بإزالة الكرت من السيرفر بشكل دائم. هل أنت متأكد؟",
    onConfirm: () async {
      _deleteCard(); 
    },
  );
}

  }
