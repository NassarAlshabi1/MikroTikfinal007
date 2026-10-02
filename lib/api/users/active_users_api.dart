import '/models/response.dart';
import '/models/users_model.dart';
import '/services/mikrotik_client.dart';
import 'saved_users_api.dart';

class ActiveUsersApi {
  static const String _activeFields=".id,server,user,address,mac-address,uptime,session-time-left,bytes-in,bytes-out,limit-bytes-total,comment";

  static Future<AppResponse<List<ActiveUserModel>>> getAllActive({String where="=detail="})async{
    try {
      List usersData=await MikrotikClient.printData(
        commands: [
          "/ip/hotspot/active/print",
          where
        ],
        fields: _activeFields,
      );
      List<ActiveUserModel> result = usersData.map((e) => ActiveUserModel.fromMikrotik(e)).toList();
      return AppResponse<List<ActiveUserModel>>(
        status: true,
        message: "done",
        data: result
      );
    } catch (e) {
      return AppResponse<List<ActiveUserModel>>(
        status: false,
        message: e.toString(),
      );
    }
  }
  static Future<AppResponse<void>> renameActiveUser(ActiveUserModel user,String newName)async{
    try {
      var res = await SavedUsersApi.getSavedUserByMac(user.macAddress);
      if(res.status){
        await SavedUsersApi.renameSavedUser(res.data!, newName);
      }else{
        await SavedUsersApi.saveUser(macAddress: user.macAddress, label: newName, toAddress: user.address,type:UserType.regular);
    }
    return AppResponse(status: true, message: "تمت تسمية الجهاز");

    } catch (e) {
      return AppResponse<void>(
        status: false,
        message: e.toString()
      );
    }
  }
  static Future<AppResponse<void>> blockActiveUser(ActiveUserModel user)async{
    try {
      var res = await SavedUsersApi.getSavedUserByMac(user.macAddress);
      if(res.status){
        await SavedUsersApi.blockSavedUser(res.data!);
      }else{
        await SavedUsersApi.saveUser(macAddress: user.macAddress, label: user.label, toAddress: user.address,type:UserType.blocked);
    }
    return AppResponse(status: true, message: "تمت حظر الجهاز");

    } catch (e) {
      return AppResponse<void>(
        status: false,
        message: e.toString()
      );
    }
  }
  static Future<AppResponse<void>> bypassActiveUser(ActiveUserModel user)async{
    try {
      var res = await SavedUsersApi.getSavedUserByMac(user.macAddress);
      if(res.status){
        await SavedUsersApi.bypassSavedUser(res.data!);
      }else{
        await SavedUsersApi.saveUser(macAddress: user.macAddress, label: user.label, toAddress: user.address,type:UserType.bypassed);
    }
    return AppResponse(status: true, message: "تم تحويل الجهاز الى مجاني");

    } catch (e) {
      return AppResponse<void>(
        status: false,
        message: e.toString()
      );
    }
  }
  static Future<AppResponse<void>> removeOneActive(ActiveUserModel user)async{
    try {
      await MikrotikClient.deleteData(
        command: "/ip/hotspot/active/remove",
        condition: "?user=${user.username}"
      );
      return AppResponse<void>(
        status: true,
        message: "done",
      );
    } catch (e) {
      return AppResponse<void>(
        status: false,
        message: e.toString(),
      );
    }
    
  }
  // 
}