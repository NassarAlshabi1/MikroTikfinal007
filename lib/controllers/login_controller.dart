import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../core/app_pages.dart';
import '/models/login_model.dart';
import '/models/response.dart';
import '/api/login_api.dart';
import 'dialog_helper.dart';

class LoginController extends GetxController {
  final TextEditingController hostController = TextEditingController();
  final TextEditingController userController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController portController = TextEditingController();
  final TextEditingController nameController = TextEditingController();

  RxBool hidePassword = true.obs;
  RxList<LoginModel> savedRouters = <LoginModel>[].obs;
  bool _isOperationCancelled = false;

  @override
  void onInit() {
    super.onInit();
    _initSavedData();
  }

  Future<void> _initSavedData() async {
    try {
      AppResponse<List<LoginModel>> response = await LoginApi.getSavedLoginData();
      savedRouters.assignAll(response.data ?? []);
      
    } catch (e) {
      showMsgDialog(message:  "حدث خطا اثناء جلب المحفوظات");
    }
  }

  @override
  void onClose() {
    hostController.dispose();
    userController.dispose();
    passwordController.dispose();
    portController.dispose();
    nameController.dispose();
    super.onClose();
  }

 
  Future<void> connectToRouter() async {
    if (!_validateInputs()) return;

    // 2. تجهيز المودل
    final router = LoginModel(
      id: 1,
      hostAddress: hostController.text.trim(),
      username: userController.text.trim(),
      password: passwordController.text.trim(),
      port: int.parse(portController.text.trim()),
      networkName: (nameController.text.trim().isEmpty ? null : nameController.text.trim()).toString(),
    );

    _showLoadingDialog("جاري الاتصال بالراوتر...");
    var response =  await LoginApi.loginToMikrotik(router);
    
    if (_isOperationCancelled) {
      _showSnackbar("تم الإلغاء", "تمت مقاطعة عملية تسجيل الدخول بناءً على طلبك.", isError: true);
      return;
    }

    if (Get.isOverlaysOpen) Get.back();

    if (response.status) {
      Get.toNamed(AppRoutes.home);
    } else {
      _showSnackbar("خطأ", response.message, isError: true);
    }

  }

  Future<void> addRouterData() async {
    if (!_validateInputs()) return;
    
    final router = LoginModel(
      id: 1,
      hostAddress: hostController.text.trim(),
      username: userController.text.trim(),
      password: passwordController.text.trim(),
      port: int.parse(portController.text.trim()),
      networkName: (nameController.text.trim().isEmpty ? null : nameController.text.trim()).toString(),
    );

    _showLoadingDialog("جاري حفظ الإعدادات...");
    AppResponse response = await LoginApi.saveLoginData(router);

    if (_isOperationCancelled) {
      return;
    }

    if (Get.isDialogOpen ?? false) Get.back();


    if (response.status) {
      savedRouters.add(router); // تحديث القائمة المحلية
      _showSnackbar("تم الحفظ", response.message);
    } else {
      _showSnackbar("فشل الحفظ", response.message, isError: true);
    }
  }

  bool _validateInputs() {
    if (hostController.text.trim().isEmpty ||
        userController.text.trim().isEmpty ||
        passwordController.text.trim().isEmpty ||
        portController.text.trim().isEmpty) {
      _showSnackbar("تنبيه", "يرجى تعبئة جميع الحقول الإجبارية (الـ IP، المستخدم، كلمة المرور، المنفذ)", isError: true);
      return false;
    }
    return true;
  }


  void showSavedData() {
    if (savedRouters.isEmpty) {
      _showSnackbar("تنبيه", "لا توجد بيانات محفوظة حالياً", isError: true);
      return;
    }
    if (Get.isOverlaysOpen) {
      Get.closeAllSnackbars();
    }
    Get.dialog(
      AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text("البيانات المحفوظة", style: TextStyle(color: Colors.white)),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: savedRouters.length,
            itemBuilder: (context, index) {
              final item = savedRouters[index];
              return ListTile(
                leading: const Icon(Icons.router, color: Color(0xFF38BDF8)),
                title: Text(item.networkName , style: const TextStyle(color: Colors.white)),
                subtitle: Text("User: ${item.username}", style: const TextStyle(color: Colors.white70)),
                trailing: IconButton(onPressed: (){
                  showConfirmDialog(message: "confirm", onConfirm: ()async{
                    var result = await LoginApi.deleteLoginData(savedRouters[index].id);
                    if(result.status) savedRouters.removeAt(index);
                    Get.back();
                    showMsgDialog(message: result.message);
                  });
                }, icon:const Icon(Icons.delete)),
                onTap: () {
                  // تعبئة الحقول بالبيانات المختارة
                  hostController.text = item.hostAddress;
                  userController.text = item.username;
                  passwordController.text = item.password;
                  portController.text = item.port.toString();
                  nameController.text = item.networkName ;
                  if (Get.isSnackbarOpen) {
                    Get.closeAllSnackbars();
                  }
                  Get.back(); 
                  
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text("إغلاق", style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  /// نافذة التحميل مع زر المقاطعة
  void _showLoadingDialog(String message) {
    _isOperationCancelled = false; // إعادة تعيين العلم
    if (Get.isSnackbarOpen) {
      Get.closeAllSnackbars();
    }
    Get.dialog(
      AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        content: Row(
          children: [
            const CircularProgressIndicator(color: Color(0xFF38BDF8)),
            const SizedBox(width: 20),
            Expanded(child: Text(message, style: const TextStyle(color: Colors.white))),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              _isOperationCancelled = true;
              Get.back(); // إغلاق النافذة فوراً
            },
            child: const Text("مقاطعة / إلغاء", style: TextStyle(color: Colors.redAccent)),
          )
        ],
      ),
      barrierDismissible: false, // منع الإغلاق بالنقر خارج النافذة
    );
  }

  void _showSnackbar(String title, String message, {bool isError = false}) {
    showMsgDialog(message: message);
  }
  
}

