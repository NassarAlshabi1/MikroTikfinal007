import '/models/users_model.dart';

import '/services/mikrotik_client.dart';
import '../models/response.dart';
import 'users/saved_users_api.dart';
class UsersApi {
  // UsersApi({});


  

  

  
  
  

  static Future<AppResponse<void>> insertCardToOne({
    required String username,
    String password="",
    required String loginIp,
    required String mac,
  })async{
    try {
      Map<String, String> userData={
        "user": username,
        "password":password ,
        "ip":loginIp,
        "mac-address":mac,
      };
      await MikrotikClient.addData(
        command: "/ip/hotspot/active/login", 
        data: userData
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
  
  
  
  static Future<AppResponse<List<SavedUserModel>>> getBlockedDevices()async{
    return await SavedUsersApi.getAlISavedUsers(where: "?type=blocked");
  }

  static Future<AppResponse<List<SavedUserModel>>> getBypassedDevices()async{
    return await SavedUsersApi.getAlISavedUsers(where: "?type=bypassed");
  }

  static Future<AppResponse<void>> labelDevice({
    required String macAddress,
    required String label,
    })async{
   
    try {
      var user = await SavedUsersApi.getSavedUserByMac(macAddress);
      if(user.status){
        await MikrotikClient.fetch(
          command: [
            "/ip/hotspot/ip-binding/set", 
            "=.id=${user.data!.id}"
          ], 
          params: {"comment": label}
        );
      }else{
        await MikrotikClient.addData(
          command: "/ip/hotspot/ip-binding/add", 
          data: {
            "mac-address":macAddress,
            "comment":label,
            "address":"0.0.0.0",
            "to-address":"0.0.0.0",
            "server":"all",
            "type":"regular",
          }
        );
    }
    return AppResponse(status: true, message: "تمت تسمية الجهاز");

    } catch (e) {
      return AppResponse<void>(
        status: false,
        message: e.toString()
      );
    }
  }

  static Future<AppResponse<void>> bypassDevice({
    required String macAddress,
    String srcAddress="0.0.0.0",
    String dstAddress="0.0.0.0",
    String label="bypassed device",
    String server="all",
  })async{
    try {
      await MikrotikClient.addData(
        command: "/ip/hotspot/ip-binding/add", 
        data: {
          "address":srcAddress,
          "to-address":dstAddress,
          "mac-address":macAddress,
          "server":server,
          "comment":label,
          "type":"bypassed",
        }
      );
      return AppResponse<void>(
        status: true,
        message: "done"
      );
    } catch (e) {
      return AppResponse<void>(
        status: false,
        message: e.toString()
      );
    }
  }

  static Future<AppResponse<void>> blockDevice({
    required String macAddress,
    String srcAddress="0.0.0.0",
    String dstAddress="0.0.0.0",
    String label="blocked device",
    String server="all",
  })async{
    try {
      await MikrotikClient.addData(
        command: "/ip/hotspot/ip-binding/add", 
        data: {
          "address":srcAddress,
          "to-address":dstAddress,
          "mac-address":macAddress,
          "server":server,
          "comment":label,
          "type":"blocked",
        }
      );
      return AppResponse<void>(
        status: true,
        message: "done"
      );
    } catch (e) {
      return AppResponse<void>(
        status: false,
        message: e.toString()
      );
    }
  }

  static Future<AppResponse<void>> removeDevice({
    required String id,
  })async{
    try {
      await MikrotikClient.removeById(
        command: "/ip/hotspot/ip-binding/remove", 
        id: id,
      );
      return AppResponse<void>(
        status: true,
        message: "done"
      );
    } catch (e) {
      return AppResponse<void>(
        status: false,
        message: e.toString()
      );
    }
  }

  static Future<AppResponse<void>> editDevice(String id,{
    String macAddress="",
    String srcAddress="",
    String dstAddress="",
    String label="",
    String server="",
    String type="regular",
  })async{
    try {
      var response = await SavedUsersApi.getAlISavedUsers(where: "?.id=$id");
      if(!response.status || response.data == null || response.data!.isEmpty){
        return AppResponse<void>(status: false, message: "Device not found");
      }
      SavedUserModel result = response.data![0];
      await MikrotikClient.fetch(
        command: [
          "/ip/hotspot/ip-binding/set", 
          "=.id=$id"
        ], 
        params: {
          "mac-address": macAddress==""?result.macAddress:macAddress,
          "address": srcAddress=="" ? result.srcAddress : srcAddress,
          "to-address": dstAddress==""?result.dstAddress:dstAddress,
          "comment": label==""?result.label:label,
          "server": server==""?result.server:server,
          "type": type==""?result.type.name:type,
        }
      );
      return AppResponse<void>(
        status: true,
        message: "done"
      );
    } catch (e) {
      return AppResponse<void>(
        status: false,
        message: e.toString()
      );
    }
  }

  static Future<AppResponse<String>> getUserId(Map user)async{
    try {
      List usersData=await MikrotikClient.printData(
        commands: [
          "/ip/hotspot/ip-binding/print",
        ],
        conditions: [
          // '?address=${user["address"]}',
          // '?to-address=${user["to-address"]}',
          '?mac-address=${user["mac-address"]}',
          // '?server=${user["server"]}',
          //'?comment=${user["comment"]}',
        ]

        // fields: ".id,address,to-address,mac-address,disabled,server,type,comment"
      );
      if(usersData.isEmpty){
        return AppResponse(status: false, message: "",data: "empty");
      }
      return AppResponse(status: true, message: "",data: usersData.first[".id"]);
    } catch (e) {
      return AppResponse(status: false, message: e.toString());
    }
    // return {};
  }
  static Future<AppResponse<List> > saveDevice({

    required String macAddress,
    String srcAddress="0.0.0.0",
    String dstAddress="0.0.0.0",
    String label="saved device",
    String server="all",
    String type="regular"
  })async{
    try {
      await MikrotikClient.addData(
        command: "/ip/hotspot/ip-binding/add", 
        data: {
          "address":srcAddress,
          "to-address":dstAddress,
          "mac-address":macAddress,
          "server":server,
          "comment":label,
          "type":type,
        }
      );
      return AppResponse(
        status: true,
        message: "done"
      );
    } catch (e) {
      return AppResponse(
        status: false,
        message: e.toString()
      );
    }
  }
   
}



