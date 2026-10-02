
import 'database_api.dart';

class LoginDataApi {

  static Future<List> getSavedLoginData()async{
    return await DBApi.select("saved_logins");
  }

  static Future<Map<String,dynamic>> getOneLogin(int id)async{
    List data =await DBApi.select("saved_logins","id=$id");
    Map<String,dynamic> result=data[0];
    return result;
  }

  static Future<int> saveLoginData(Map<String,dynamic> data)async{
    return await DBApi.insert("saved_logins", data);
  }

  static Future<int> editLoginData(int id,Map<String,dynamic> data)async{
    return await DBApi.update("saved_logins", data,"id=$id");
  }

  static Future<int> deleteLoginData(int id)async{
    return await DBApi.delete("saved_logins", "id=$id");
  }
}