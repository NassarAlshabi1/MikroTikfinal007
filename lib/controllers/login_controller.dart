import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../core/app_pages.dart';
import '/models/login_model.dart';
import '/services/connection_errors.dart';
import '/services/settings_store.dart';
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

  /// اتصال مشفّر (api-ssl) — يعمل مع **أي منفذ** وليس 8729 فقط.
  RxBool useSsl = false.obs;

  /// هل اختار المستخدم وضع SSL يدويًا؟ (لعدم تجاوز اختياره عند تغيير المنفذ)
  bool _sslManuallySet = false;
  static const String _sslPrefKey = 'login_use_ssl';

  @override

  RxList<LoginModel> savedRouters = <LoginModel>[].obs;
  bool _isOperationCancelled = false;

  @override
  void onInit() {
    super.onInit();
    // منفذ API الافتراضي في RouterOS — ويمكن كتابة أي منفذ آخر (مثل 1300)
    if (portController.text.trim().isEmpty) {
      portController.text = ConnectionErrors.defaultPort.toString();
    }

    // تفضيل SSL المحفوظ من آخر استخدام
    SettingsStore.get(_sslPrefKey).then((value) {
      if (value == null) return;
      // احترام اختيار المستخدم المحفوظ (تشغيلًا أو إيقافًا)
      useSsl.value = value == '1';
      _sslManuallySet = true;
    });

    // المنفذ 8729 ⇒ نقترح التشفير تلقائيًا (ما لم يختر المستخدم بنفسه)
    portController.addListener(() {
      if (_sslManuallySet) return;
      useSsl.value = ConnectionErrors.isSecurePort(
        ConnectionErrors.parsePort(portController.text) ?? 0,
      );
    });

    _initSavedData();
  }

  /// تبديل وضع SSL يدويًا (يُحفظ للاستخدام القادم).
  void toggleSsl(bool value) {
    useSsl.value = value;
    _sslManuallySet = true;
    SettingsStore.set(_sslPrefKey, value ? '1' : '0');
  }

  /// استخراج المضيف والمنفذ من خانة العنوان (تدعم `192.168.88.1:1300`).
  ///
  /// إن كُتب المنفذ داخل خانة العنوان نُسخ إلى خانة المنفذ تلقائيًا.
  _ResolvedTarget? _resolveTarget() {
    final entry = ConnectionErrors.splitHostPort(hostController.text);
    final host = entry.host.trim();

    if (host.isEmpty) {
      _showSnackbar("تنبيه", "اكتب عنوان IP أو اسم المضيف للراوتر", isError: true);
      return null;
    }

    int? port = entry.port;
    if (port != null) {
      // المستخدم كتب IP:PORT ⇒ نعكسه في خانة المنفذ ونعتمد منفذه
      portController.text = port.toString();
    } else {
      port = ConnectionErrors.parsePort(portController.text);
    }

    if (port == null) {
      _showSnackbar("تنبيه",
          "المنفذ غير صالح — اكتب رقمًا بين 1 و 65535 (الافتراضي 8728، ويمكن استخدام أي منفذ)",
          isError: true);
      return null;
    }

    return _ResolvedTarget(host: host, port: port);
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

    // 2. تجهيز المودل (منفذ حر 1..65535 + دعم صيغة IP:PORT + الأرقام العربية)
    final target = _resolveTarget();
    if (target == null) return;

    final router = LoginModel(
      id: 1,
      hostAddress: target.host,
      username: userController.text.trim(),
      password: passwordController.text.trim(),
      port: target.port,
      networkName: nameController.text.trim(),
    );

    _showLoadingDialog("جاري الاتصال بالراوتر...");
    var response = await LoginApi.loginToMikrotik(router, useSsl: useSsl.value);
    
    if (_isOperationCancelled) {
      _showSnackbar("تم الإلغاء", "تمت مقاطعة عملية تسجيل الدخول بناءً على طلبك.", isError: true);
      return;
    }

    if (Get.isOverlaysOpen) Get.back();

    if (response.status) {
      // حفظ تفضيل SSL لهذا الراوتر (مفيد للمنافذ المخصّصة مثل 1300)
      SettingsStore.set(_sslPrefKey, useSsl.value ? '1' : '0');
      Get.toNamed(AppRoutes.home);
    } else {
      _showSnackbar("خطأ", response.message, isError: true);
    }

  }

  Future<void> addRouterData() async {
    if (!_validateInputs()) return;
    
    final target = _resolveTarget();
    if (target == null) return;

    final router = LoginModel(
      id: 1,
      hostAddress: target.host,
      username: userController.text.trim(),
      password: passwordController.text.trim(),
      port: target.port,
      networkName: nameController.text.trim(),
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
                title: Text(
                  item.networkName.trim().isEmpty ? 'بدون اسم' : item.networkName,
                  style: const TextStyle(color: Colors.white),
                ),
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
                  // نحترم المنفذ المحفوظ كما هو (أي منفذ مخصّص مثل 1300)
                  portController.text = item.port.toString();
                  useSsl.value = ConnectionErrors.isSecurePort(item.port);
                  _sslManuallySet = false;
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

/// هدف الاتصال بعد تحليل خانة العنوان والمنفذ.
class _ResolvedTarget {
  final String host;
  final int port;
  const _ResolvedTarget({required this.host, required this.port});
}
