import '/models/response.dart';
import '/models/users_model.dart';
import '/services/mikrotik_client.dart';

class SavedUsersApi {
  static Future<AppResponse<List<SavedUserModel>>> getAlISavedUsers({String where="=detail="})async{
    try {
      List usersData=await MikrotikClient.printData(
        commands: [
          "/ip/hotspot/ip-binding/print",
          where,
        ],
      );
      List<SavedUserModel> result = usersData.map((e) => SavedUserModel.fromMikrotik(e)).toList();
      return AppResponse<List<SavedUserModel>>(
        status: true, 
        message: "done",
        data: result
      );
    } catch (e) {
      return AppResponse<List<SavedUserModel>>(
        status: false, 
        message: e.toString(),
      );
    }
  }
  static Future<AppResponse<void>> renameSavedUser(SavedUserModel user,String newName)async{
    try{
      await MikrotikClient.fetch(
        command: [
            "/ip/hotspot/ip-binding/set", 
            "=.id=${user.id}"
        ], 
        params: {"comment": newName}
      );
    return AppResponse(status: true, message: "تمت تسمية الجهاز");

    } catch (e) {
      return AppResponse<void>(
        status: false,
        message: e.toString()
      );
    }
  }


  static Future<AppResponse<SavedUserModel>> getSavedUserByMac(String mac)async{
    try {
      List usersData=await MikrotikClient.printData(
        commands: ["/ip/hotspot/ip-binding/print",],
        conditions: ['?mac-address=$mac']

        // fields: ".id,address,to-address,mac-address,disabled,server,type,comment"
      );
      if(usersData.isEmpty){
        return AppResponse(status: false, message: "not found");
      }
      return AppResponse(status: true, message: "",data: SavedUserModel.fromMikrotik(usersData.first));
    } catch (e) {
      return AppResponse(status: false, message: e.toString());
    }
    // return {};
  }
  static Future<AppResponse> blockSavedUser(SavedUserModel user)async{
    try{
      await MikrotikClient.fetch(
        command: ["/ip/hotspot/ip-binding/set", "=.id=${user.id}"], 
        params: {"type": UserType.blocked.name}
      );
      return AppResponse(status: true, message: "تم حظر المستخدم");
    } catch (e) {
      return AppResponse(status: false,message: e.toString());
    }
  }
  static Future<AppResponse> bypassSavedUser(SavedUserModel user)async{
    try{
      await MikrotikClient.fetch(
        command: ["/ip/hotspot/ip-binding/set", "=.id=${user.id}"], 
        params: {"type": UserType.bypassed.name}
      );
      return AppResponse(status: true, message: "تم تحويل المستخدم الى مجاني بنجاح");
    } catch (e) {
      return AppResponse(status: false,message: e.toString());
    }
  }
  static Future<AppResponse> regularSavedUser(SavedUserModel user)async{
    try{
      await MikrotikClient.fetch(
        command: ["/ip/hotspot/ip-binding/set", "=.id=${user.id}"], 
        params: {"type": UserType.regular.name}
      );
      return AppResponse(status: true, message: "تم تحويل المستخدم الى عادي");
    } catch (e) {
      return AppResponse(status: false,message: e.toString());
    }
  }
  static Future<AppResponse> saveUser({
    required String macAddress,
    required String label,
    required String toAddress,
    String address="0.0.0.0",
    String server = "all",
    UserType type = UserType.regular
  })async{
    try{
      await MikrotikClient.addData(
          command: "/ip/hotspot/ip-binding/add", 
          data: {
            "mac-address":macAddress,
            "comment":label,
            "address":address,
            "to-address":toAddress,
            "server":server,
            "type":type.name,
          }
        );
      return AppResponse(status: true, message: "تم اضافة الجهاز بنجاح");
    } catch (e) {
      return AppResponse(status: false,message: e.toString());
    }
  }
  static Future<AppResponse<void>> removeSavedUser(SavedUserModel user)async{
    try {
      await MikrotikClient.removeById(
        command: "/ip/hotspot/ip-binding/remove", 
        id: user.id,
      );
      return AppResponse<void>(status: true,message: "تم حذف الجهاز بنجاح");
    } catch (e) {
      return AppResponse<void>(status: false,message: e.toString());
    }
  }
}