import 'package:get/get.dart';

import 'package:mikronet/features/sites/models/sites_model.dart';
import 'package:mikronet/features/cards/models/profiles_model.dart';
import 'package:mikronet/core/mikrotik/mikrotik_client.dart';
import 'package:mikronet/core/models/app_response.dart';
import 'package:mikronet/features/cards/models/cards_model.dart';


class ProfilesApi7 {
  
  static Future<List> _getProfileData(String profileName)async{
    String where=profileName.isNotEmpty?'?name=$profileName':'=detail=';
    return await MikrotikClient.printData(
      commands: ['/user-manager/profile/print',],
      conditions: [where]
    );
  }

  static Future<List> _getLimitations({String name=""})async{
    String where=name.isNotEmpty?'?name=$name':'=detail=';
    return await MikrotikClient.printData(
      commands: ['/user-manager/limitation/print',],
      conditions: [where]
    );
  }

  static Future<List> _getLinks(String profileName)async{
    String where=profileName.isNotEmpty?'?profile=$profileName':'=detail=';
    return await MikrotikClient.printData(
      commands: ['/user-manager/profile-limitation/print',],
      conditions: [where]
    );
  }

  static Future<AppResponse<List<ProfilesModel>>> getProfiles({String profileName=""}) async {
  try {

    List profiles=await _getProfileData(profileName);

    List links=await _getLinks(profileName);

    List limitations=await _getLimitations();
    
    List<ProfilesModel> result=[];

    for (var item in profiles) {
      Map link=links.firstWhereOrNull((l)=>l['profile']==item['name'])??{};
      Map limit=limitations.firstWhereOrNull((li)=>li['name']==link['limitation'])??{};

      if (link.isNotEmpty) {
        ProfilesModel profile= ProfilesModel(
          customer: 'default',
          id: item['.id'],
          name: item['name'],
          price: item['price'],
          validity: item['validity'],
          palance: limit['transfer-limit']??'unlimited',
          speed: ("${limit['rate-limit-rx']??"0"}/${limit['rate-limit-tx']??"0"}"),
          uptime: limit['uptime-limit']??'unlimited',
          users: '1'
        );
        result.add(profile);
      }
    }
    return AppResponse<List<ProfilesModel>>(
      status: true, 
      message: "done",
      data: result
    );
    
    } catch (e) {
      return AppResponse<List<ProfilesModel>>(
        status: false, 
        message: e.toString(),
      );
    }
  }

  
  static Future<String>_addLimit({
    required String name,
    required String palance,
    required String uptime,
    required String rateLimit,
  })async{
    try {
      await MikrotikClient.addData(
        command: "/user-manager/limitation/add", 
        data: {
          "name": 'MikroNet_${name}_limit' ,
          "transfer-limit": palance ,
          "uptime-limit": uptime ,
          "rate-limit-rx": rateLimit.split('/').first ,
          "rate-limit-tx": rateLimit.split('/').last ,
        }
      );
      return "done";
    } catch (e) {
      throw e.toString();
    }
  }

  static Future<String>_addProfile({
    required String name,
    required String validity,
    required String price,
  })async{
    try {
      await MikrotikClient.addData(
        command: "/user-manager/profile/add", 
        data: {
          "name": name ,
          "name-for-users": name ,
          "validity": validity ,
          "price": price ,
          "override-shared-users":"off",
          "starts-when": "first-auth"
        }
      );
      return "done";
    } catch (e) {
      return e.toString();
    }
  }

  static Future<String>_linkProfileLimits({
    required String profile,
    required String limitation,
  })async{
    try {
      await MikrotikClient.addData(
        command: "/user-manager/profile-limitation/add", 
        data: {
          "profile": profile ,
          "limitation": limitation ,
        }
      );
      return "done";
    } catch (e) {
      throw e.toString();
    }
  }
  
  static Future<AppResponse<void>>addOneProfile(Map data)async{
    try {

      // add limit
      await _addLimit(
        name: data["name"], 
        palance: data["palance"],
        uptime: data["uptime"],
        rateLimit: data["speed"],
      );

      // add profile
      await _addProfile(
        name: data["name"], 
        validity: data["validity"],
        price: data["price"],
      );

      // link
      await _linkProfileLimits(
        profile: data["name"], 
        limitation: "MikroNet_${data["name"]}_limit"
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

  static Future<AppResponse<void>>profileEdit(String name,Map<String, String> data)async{
    try {
      var profileResponse=await getProfiles(profileName: name);
      if(!profileResponse.status || profileResponse.data == null || profileResponse.data!.isEmpty){
        return AppResponse<void>(status: false, message: "Profile not found=${profileResponse.message}");
      }
      
      ProfilesModel profile = profileResponse.data![0];
      // {name: 7500, price: 7000, validity: 10d12h, uptime: 7d7h, palance: 4288M, speed: 1024000/2000000, customer: default, users: 1}
      // String newProfileName='MikroNet_${data["name"]??profile.name}_profile';
      String newLimitName='MikroNet_${data["name"]??profile.name}_limit';

      // edit limit
      await MikrotikClient.editData(
        command: "/user-manager/limitation/set",
        data: {
          "name": newLimitName ,
          // "owner": data["customer"]??profile.customer ,
          "transfer-limit": data["palance"]??profile.palance ,
          "uptime-limit": data["uptime"]??profile.uptime ,
          "rate-limit-rx": (data["speed"]??profile.speed).split('/').first, 
          "rate-limit-tx": (data["speed"]??profile.speed).split('/').last, 
          // "group-name": newProfileName ,
        },
        condition: "?name=MikroNet_${name}_limit"
      );
      
      // print('\n');print('\n');print('\n');print('\n');print('\n');
      // print("profileResponse.data!.first.toMap()");
      // print('\n');print('\n');print('\n');print('\n');print('\n');
      // edit profile
      await MikrotikClient.editData(
        command: "/user-manager/profile/set",
        data: {
          "name": data["name"]??profile.name ,
          // "owner": data["customer"]??profile.customer ,
          "name-for-users": data["name"]??profile.name ,
          "validity": data["validity"]??profile.validity ,
          "price": data["price"]??profile.price ,
          // "starts-at": "logon"
        },
        condition: "?name=$name"
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


  static Future<AppResponse<void>>deleteProfile(String name)async{
    
    try {
      
      // String newProfileName='MikroNet_${name}_profile';
      String newLimitName='MikroNet_${name}_limit';

      
      // remove link
      await MikrotikClient.deleteData(
        command: "/user-manager/profile-limitation/remove",
        condition: "?profile=$name"
      );
      
      // remove profile
      await MikrotikClient.deleteData(
        command: "/user-manager/profile/remove",
        condition: "?name=$name"
      );

      // remove limit
      await MikrotikClient.deleteData(
        command: "/user-manager/limitation/remove",
        condition: "?name=$newLimitName"
      );


      // remove hotspot profile
      // await MikrotikClient.deleteData(
      //   command: "/ip/hotspot/user/profile/remove",
      //   condition: "?name=$newProfileName"
      // );
      


      
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

  

}










