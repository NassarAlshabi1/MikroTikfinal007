import '/models/response.dart';
import '/models/login_model.dart';
import '/services/mikrotik_client.dart';
import 'database_api.dart';


class LoginApi {

  static Future<AppResponse<List<LoginModel>>> getSavedLoginData()async{

    var result = await DBApi.select("saved_logins");

    var response = AppResponse(status: true, message: "",data: <LoginModel>[]);
    if(result.isEmpty){
      return response;
    }
    
    for (var m in result) {
      response.data?.add(LoginModel.fromDatabase(m));
    }
    return response;
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
      await DBApi.insert("saved_logins", data.toDatabase());
      return AppResponse(status: true, message: "inserted",);
    } catch (e) {
      return AppResponse(status: false, message: e.toString());
    }
  }

  static Future<AppResponse<int>> editLoginData(int id,Map<String,dynamic> data)async{
    try {
      int result = await DBApi.update("saved_logins", data,"id=$id");
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
    try {  
      var result= await MikrotikClient.login();
      return AppResponse(status: result, message: "");
    } catch (e) {
      return AppResponse(status: false, message: e.toString());
    }
  }
}