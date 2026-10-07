import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../api/distributors_api.dart';
import '../../controllers/dialog_helper.dart';
import '../../models/distributor_model.dart';

class DistributorFormController extends GetxController {
  DistributorFormController(this.distributor);

  final DistributorModel? distributor;

  final nameCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();
  final noteCtrl = TextEditingController();

  bool get isEdit => distributor != null;
  final RxBool isActive = true.obs;
  final RxBool isSaving = false.obs;

  @override
  void onInit() {
    super.onInit();
    if (distributor != null) {
      nameCtrl.text = distributor!.name;
      phoneCtrl.text = distributor!.phone;
      noteCtrl.text = distributor!.note;
      isActive.value = distributor!.isActive;
    }
  }

  Future<void> save() async {
    if (nameCtrl.text.trim().isEmpty) {
      await showMsgDialog(message: "يرجى إدخال اسم الموزع", type: MsgType.warning);
      return;
    }
    if (isSaving.value) return;

    isSaving.value = true;
    final response = isEdit
        ? await DistributorsApi.updateDistributor(
            id: distributor!.id,
            name: nameCtrl.text.trim(),
            phone: phoneCtrl.text.trim(),
            note: noteCtrl.text.trim(),
            isActive: isActive.value,
          )
        : await DistributorsApi.insert(
            name: nameCtrl.text.trim(),
            phone: phoneCtrl.text.trim(),
            note: noteCtrl.text.trim(),
          );
    isSaving.value = false;

    await showMsgDialog(
      message: response.message,
      type: response.status ? MsgType.success : MsgType.error,
    );

    if (response.status) Get.back();
  }

  @override
  void onClose() {
    nameCtrl.dispose();
    phoneCtrl.dispose();
    noteCtrl.dispose();
    super.onClose();
  }
}
