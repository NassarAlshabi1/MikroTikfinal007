import '/models/response.dart';
import '/models/users_model.dart';
import '/services/mikrotik_client.dart';
import 'saved_users_api.dart';

class HostUsersApi {
  static const String _hostsFields=".id,mac-address,address,to-address,server,uptime,bytes-in,bytes-out,authorized,bypassed,comment";

  static Future<AppResponse<List<HostUserModel>>> getAllHosts({String where="=detail="})async{
    try {
      List usersData=await MikrotikClient.printData(
        commands: [
          "/ip/hotspot/host/print",
          where
        ],
        fields: _hostsFields
      );
      List<HostUserModel> result = usersData.map((e) => HostUserModel.fromMikrotik(e)).toList();
      return AppResponse<List<HostUserModel>>(
        status: true,
        message: "done",
        data: result
      );
    } catch (e) {
      return AppResponse<List<HostUserModel>>(
        status: false,
        message: e.toString(),
      );
    }
  }
  static Future<AppResponse<void>> renameHostUser(HostUserModel user,String newName)async{
    try {
      var res = await SavedUsersApi.getSavedUserByMac(user.macAddress);
      if(res.status){
        await SavedUsersApi.renameSavedUser(res.data!, newName);
      }else{
        await SavedUsersApi.saveUser(macAddress: user.macAddress, label: newName, toAddress: user.dstAddress,type:user.type);
    }
    return AppResponse(status: true, message: "تمت تسمية الجهاز");

    } catch (e) {
      return AppResponse<void>(
        status: false,
        message: e.toString()
      );
    }
  }
  static Future<AppResponse<void>> blockHostUser(HostUserModel user)async{
    try {
      var res = await SavedUsersApi.getSavedUserByMac(user.macAddress);
      if(res.status){
        await SavedUsersApi.blockSavedUser(res.data!);
      }else{
        await SavedUsersApi.saveUser(macAddress: user.macAddress, label: user.label, toAddress: user.dstAddress,type:UserType.blocked);
    }
    return AppResponse(status: true, message: "تمت حظر الجهاز");

    } catch (e) {
      return AppResponse<void>(
        status: false,
        message: e.toString()
      );
    }
  }
  static Future<AppResponse<void>> bypasskHostUser(HostUserModel user)async{
    try {
      var res = await SavedUsersApi.getSavedUserByMac(user.macAddress);
      if(res.status){
        await SavedUsersApi.bypassSavedUser(res.data!);
      }else{
        await SavedUsersApi.saveUser(macAddress: user.macAddress, label: user.label, toAddress: user.dstAddress,type:UserType.bypassed);
    }
    return AppResponse(status: true, message: "تم تحويل الجهاز الى مجاني");

    } catch (e) {
      return AppResponse<void>(
        status: false,
        message: e.toString()
      );
    }
  }
  static Future<AppResponse<void>> regularHostUser(HostUserModel user)async{
    try {
      var res = await SavedUsersApi.getSavedUserByMac(user.macAddress);
      if(res.status){
        await SavedUsersApi.regularSavedUser(res.data!);
      }else{
        await SavedUsersApi.saveUser(macAddress: user.macAddress, label: user.label, toAddress: user.dstAddress,type:UserType.regular);
    }
    return AppResponse(status: true, message: "تم تحويل الجهاز الى عادي");

    } catch (e) {
      return AppResponse<void>(
        status: false,
        message: e.toString()
      );
    }
  }
  static Future<AppResponse<void>> removeOneHost(HostUserModel user)async{
    try {
      await MikrotikClient.deleteData(
        command: "/ip/hotspot/host/remove",
        condition: "?address=${user.srcAddress}"
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
}