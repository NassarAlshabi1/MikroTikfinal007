import '/models/response.dart';
import '/models/login_model.dart';
import '/services/mikrotik_client.dart';
import '/services/secure_store.dart';
import 'database_api.dart';
import 'expired_users_api.dart';


class LoginApi {

  static Future<AppResponse<List<LoginModel>>> getSavedLoginData()async{

    var result = await DBApi.select("saved_logins");

    var response = AppResponse(status: true, message: "",data: <LoginModel>[]);
    if(result.isEmpty){
      return response;
    }
    
    for (var m in result) {
      final storedModel = LoginModel.fromDatabase(m);
      response.data?.add(await _decrypt(storedModel));

      // ترقية تلقائية: تشفير أي بيانات قديمة غير مشفّرة وإعادة حفظها.
      if (!SecureStore.isEncrypted(storedModel.password) ||
          !SecureStore.isEncrypted(storedModel.hostAddress)) {
        await _encryptAndUpdate(storedModel.id, storedModel);
      }
    }
    return response;
  }

  /// فك تشفير حقول الراوتر المحفوظ.
  static Future<LoginModel> _decrypt(LoginModel model) async {
    return LoginModel(
      id: model.id,
      hostAddress: await SecureStore.decryptText(model.hostAddress),
      username: await SecureStore.decryptText(model.username),
      password: await SecureStore.decryptText(model.password),
      port: model.port,
      networkName: await SecureStore.decryptText(model.networkName),
    );
  }

  /// تجهيز الحقول الحساسة للتخزين (مشفّرة).
  static Future<Map<String, dynamic>> _encryptedRow(LoginModel model) async {
    return <String, dynamic>{
      "host": await SecureStore.encryptText(model.hostAddress),
      "username": await SecureStore.encryptText(model.username),
      "password": await SecureStore.encryptText(model.password),
      "port": model.port,
      "name": await SecureStore.encryptText(model.networkName),
    };
  }

  static Future<void> _encryptAndUpdate(int id, LoginModel model) async {
    try {
      await DBApi.update("saved_logins", await _encryptedRow(model), "id=$id");
    } catch (_) {
      // لا نُفشل القراءة بسبب فشل الترقية
    }
  }

  static Future<AppResponse<LoginModel>> getOneLogin(int id)async{
    try {
      List data =await DBApi.select("saved_logins","id=$id");
      if(data.isEmpty){
        return AppResponse(status: false, message: "not found");
      }
      return AppResponse(status: true, message: "done", data: LoginModel.fromDatabase(data[0]));
    } catch (e) {
      return AppResponse(status: false, message: e.toString());
    }
  }

  static Future<AppResponse<void>> saveLoginData(LoginModel data)async{
    try {
      await DBApi.insert("saved_logins", await _encryptedRow(data));
      return AppResponse(status: true, message: "inserted",);
    } catch (e) {
      return AppResponse(status: false, message: e.toString());
    }
  }

  static Future<AppResponse<int>> editLoginData(int id,Map<String,dynamic> data)async{
    try {
      final secured = Map<String, dynamic>.from(data);
      const sensitiveKeys = ["host", "username", "password", "name"];
      for (final key in sensitiveKeys) {
        final value = secured[key];
        if (value != null && !SecureStore.isEncrypted(value.toString())) {
          secured[key] = await SecureStore.encryptText(value.toString());
        }
      }
      int result = await DBApi.update("saved_logins", secured,"id=$id");
      return AppResponse(status: true, message: "updated", data: result);
    } catch (e) {
      return AppResponse(status: false, message: e.toString());
    }
  }

  static Future<AppResponse<void>> deleteLoginData(int id)async{
    try {
      await DBApi.delete("saved_logins", "id=$id");
      return AppResponse(status: true, message: "deleted",);
    } catch (e) {
      return AppResponse(status: false, message: e.toString());
    }
  }
  static Future<AppResponse> loginToMikrotik(LoginModel router) async{
    MikrotikClient.init(address: router.hostAddress, user: router.username, password: router.password, port: router.port,useSsl: false);
    //MikrotikClient.init(address: "127.0.0.1", user: "admin", password: "admin", port: 8727,useSsl: false);
    // راوتر جديد = إصدار قد يختلف (v6/v7) ← نُصفّر المسارات المخزّنة
    ExpiredUsersApi.resetPaths();

    try {  
      var result= await MikrotikClient.login();
      return AppResponse(status: result, message: "");
    } catch (e) {
      return AppResponse(status: false, message: e.toString());
    }
  }
}