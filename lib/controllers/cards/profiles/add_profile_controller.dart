import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mikronet/api/profiles_api.dart';
import 'package:mikronet/models/profiles_model.dart';
import '../../../api/cards_api.dart';
import '../../../models/cards_model.dart';
import '/controllers/dialog_helper.dart';

class AddProfileController extends GetxController {
  final nameCtrl = TextEditingController();
  final priceCtrl = TextEditingController();
  final daysCtrl = TextEditingController();
  final hoursCtrl = TextEditingController();
  final uptimeDaysCtrl = TextEditingController();
  final uptimeHoursCtrl = TextEditingController();
  final gigasCtrl = TextEditingController();
  final megasCtrl = TextEditingController();
  final speedCtrl = TextEditingController();
  List<CustomerModel> customers = <CustomerModel>[];

  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    getCustomers();
  }
  bool _isEmptyFields() {

    final allOthers = [nameCtrl,priceCtrl, daysCtrl, hoursCtrl, uptimeDaysCtrl, uptimeHoursCtrl, gigasCtrl, megasCtrl];
    if (allOthers.any((ctrl) => ctrl.text.trim().isEmpty)) {
      return true;
    }

    return false;
  }
  Future<void> getCustomers()async{
    var response=await CardsApi.getCustomers();
    if (response.status) {
      customers=response.data!;

    }
    else{ showMsgDialog(message: response.message); }
  }
  Future<void> executeAdd() async {
    if (_isEmptyFields()) {
      showMsgDialog(message: "يرجى تعبنة كل الحقول");
      return;
    }

    String validity = MikrotikTimeHelper(
      days: int.tryParse(daysCtrl.text) ?? 0,
      hours: int.tryParse(hoursCtrl.text) ?? 0
    ).toMikrotikString();

    String uptime = MikrotikTimeHelper(
      days: int.tryParse(uptimeDaysCtrl.text) ?? 0,
      hours: int.tryParse(uptimeHoursCtrl.text) ?? 0
    ).toMikrotikString();

    String palance = MikrotikDataHelper(
      gigas: int.tryParse(gigasCtrl.text) ?? 0,
      megas: int.tryParse(megasCtrl.text) ?? 0
    ).toMikrotikString();

    final data = {
      "name": nameCtrl.text, 
      "price": priceCtrl.text.isEmpty ? '0' : priceCtrl.text,
      "validity": validity, 
      "uptime": uptime,
      "palance": palance, 
      "speed": speedCtrl.text.trim().isEmpty ? '0/0' : speedCtrl.text.toUpperCase().trim(),
      "customer": customers.first.name , 
      "users": "1",
    };

    showLoadingDialog();
    var response = await ProfilesApi.addOneProfile(data);

    hideDialog();

    if (response.status) { 
      showMsgDialog(message: response.message); 
      Get.back(result: true); 
    } else { 
      showMsgDialog(message: response.message); 
    }
  }


  @override
  void onClose() {
    nameCtrl.dispose(); priceCtrl.dispose(); daysCtrl.dispose(); hoursCtrl.dispose();
    uptimeDaysCtrl.dispose(); uptimeHoursCtrl.dispose(); gigasCtrl.dispose();
    megasCtrl.dispose(); speedCtrl.dispose();
    super.onClose();
  }
}