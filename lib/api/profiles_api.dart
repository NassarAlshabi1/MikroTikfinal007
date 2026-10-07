import 'package:mikronet/api/version7_api.dart';

import '/models/profiles_model.dart';
import '/services/mikrotik_client.dart';
import '../models/response.dart';

class ProfilesApi {
  int version;
  ProfilesApi({this.version=6});
  
  // final String _props="""username,password,actual-profile,uptime-used,download-used,upload-used,last-seen""";


  static Future<List> _getHotspotProfiles({String whereName="=detail="})async{
    String props="name,shared-users,rate-limit";
    return await MikrotikClient.printData(
      commands: [
        "/ip/hotspot/user/profile/print",
        // "=detail="
      ],
      conditions: [whereName],
      fields: props
    );
  }

  static Future<List> _getLimitations({String whereNane="=detail="})async{
    String props="name,owner,transfer-limit,uptime-limit,group-name";
    return await MikrotikClient.printData(
      commands: [
        "/tool/user-manager/profile/limitation/print",
        // "=detail="
      ],
      conditions: [whereNane],
      fields: props
    );
  }

  static Future<List> _getProfilesNames({String whereName="=detail="})async{
    String props= ".id,name,owner,name-for-users,validity,price";
    return await MikrotikClient.printData(
      commands: [
        "/tool/user-manager/profile/print",
        // "=detail="
      ],
      conditions: [whereName],
      fields: props,
    );
  }

  static Future<List> _getLimitationsLinks({String whereProfile="=detail="})async{
    String props= "profile,limitation";
    return await MikrotikClient.printData(
      commands: [
        "/tool/user-manager/profile/profile-limitation/print",
        // "=detail="
        ],
      conditions: [whereProfile],
      fields: props,
    );
  }

  static Future<List> _getProfilesData({String profileName=""})async{
    List<dynamic> results = [];

    if(profileName!=""){
      List links = await _getLimitationsLinks(whereProfile: "?profile=$profileName");
      Map link=links[0];

      List limits = await _getLimitations(whereNane: "?name=${link["limitation"]}");
      Map limit=limits[0];

      List hotspot = await _getHotspotProfiles(whereName: "?name=${limit["group-name"]}");
      Map hots=hotspot[0];

      List profiles = await _getProfilesNames(whereName: "?name=$profileName");
      Map profile=profiles[0];

      results.addAll([[hots],[limit],[profile],[link]]);
      return results;
    }

    List hotspot = await _getHotspotProfiles();
    List limits = await _getLimitations();
    List profiles = await _getProfilesNames();
    List links = await _getLimitationsLinks();

    results.addAll([hotspot,limits,profiles,links]);
    return results;
  }

  static Future<AppResponse<List<ProfilesModel>>> getProfiles({String profileName=""}) async {
  try {
    if(MikrotikClient.version==7){
      return await ProfilesApi7.getProfiles(profileName: profileName);
    }
    List results=await _getProfilesData(profileName: profileName);

    List hotspot = results[0];
    List limits = results[1];
    List profiles = results[2];
    List links = results[3];

    // القائمة النهائية التي سنرجعها
    List<Map<String, dynamic>> finalProfiles = [];

    // 2. المرور على كل بروفايل في اليوزر منجر لدمج بياناته
    for (var profile in profiles) {
      // إنشاء نسخة جديدة قابلة للتعديل من البروفايل
      Map<String, dynamic> mergedProfile = Map<String, dynamic>.from(profile);

      // --- أ: دمج القيود (Limitations) ---
      var profileLinks = links.where((link) => link['profile'] == profile['name']).toList();
      List<Map<String, dynamic>> profileLimits = [];

      for (var link in profileLinks) {
        // جلب بيانات القيد (Limitation) الفعلي بناءً على اسمه في الرابط
        var limitData = limits.cast<Map<String, dynamic>?>().firstWhere(
          (l) => l != null && l['name'] == link['limitation'],
          orElse: () => null,
        );

        if (limitData != null) {
          profileLimits.add(limitData);
        }
      }
      
      // إضافة قائمة القيود داخل البروفايل
      mergedProfile['limitations'] = profileLimits;

      // --- ب: دمج خصائص الهوتسبوت (Hotspot Settings) ---
      // عادةً اسم البروفايل في اليوزر منجر يطابق اسم بروفايل الهوتسبوت، أو يتم تحديده عبر name-for-users
      String targetHotspotName = profile['name-for-users'] ?? profile['name'];
      
      var hotspotData = hotspot.cast<Map<String, dynamic>?>().firstWhere(
        (h) => h != null && h['name'] == targetHotspotName,
        orElse: () => null,
      );

      // إذا لم نجده بالاسم، أحياناً يكون مربوطاً عبر group-name داخل الـ limitation
      if (hotspotData == null && profileLimits.isNotEmpty) {
        String? groupName = profileLimits.first['group-name'];
        if (groupName != null) {
          hotspotData = hotspot.cast<Map<String, dynamic>?>().firstWhere(
            (h) => h != null && h['name'] == groupName,
            orElse: () => null,
          );
        }
      }

      // إضافة خصائص الهوتسبوت إذا وجدت
      mergedProfile['hotspot_settings'] = hotspotData ?? {};

      // 3. إضافة البروفايل المدمج للقائمة النهائية
      finalProfiles.add(mergedProfile);
    }

    List<ProfilesModel> finalResult = finalProfiles.map((e) => ProfilesModel.fromMikrotik(e)).toList();
    
    return AppResponse<List<ProfilesModel>>(
      status: true, 
      message: "done",
      data: finalResult
    );
    
    } catch (e) {
      return AppResponse<List<ProfilesModel>>(
        status: false, 
        message: e.toString(),
      );
    }
  }

  
  static Future<String>_addOneHotspotProfile({
    required String name,
    required String users,
    required String speed,
  })async{
    try {
      await MikrotikClient.addData(
        command: "/ip/hotspot/user/profile/add", 
        data: {
          "name": 'MikroNet_${name}_profile' ,
          "shared-users": users ,
          "rate-limit": speed 
        }
      );
      return "done";
    } catch (e) {
      return e.toString();
    }
  }

  static Future<String>_addLimit({
    required String name,
    required String customer,
    required String palance,
    required String uptime,
    required String hotspotProfile,
  })async{
    try {
      await MikrotikClient.addData(
        command: "/tool/user-manager/profile/limitation/add", 
        data: {
          "name": 'MikroNet_${name}_limit' ,
          "owner": customer ,
          "transfer-limit": palance ,
          "uptime-limit": uptime ,
          "group-name": hotspotProfile ,
        }
      );
      return "done";
    } catch (e) {
      return e.toString();
    }
  }

  static Future<String>_addProfile({
    required String name,
    required String customer,
    required String validity,
    required String price,
  })async{
    try {
      await MikrotikClient.addData(
        command: "/tool/user-manager/profile/add", 
        data: {
          "name": name ,
          "owner": customer ,
          "name-for-users": name ,
          "validity": validity ,
          "price": price ,
          "starts-at": "logon"
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
        command: "/tool/user-manager/profile/profile-limitation/add", 
        data: {
          "profile": profile ,
          "limitation": limitation ,
        }
      );
      return "done";
    } catch (e) {
      return e.toString();
    }
  }
  
  static Future<AppResponse<void>>addOneProfile(Map data)async{
    try {
      if(MikrotikClient.version==7){
      return await ProfilesApi7.addOneProfile(data);
    }
      // add hotspot profile
      await _addOneHotspotProfile(
        name: data["name"], 
        users: data["users"], 
        speed: data["speed"]
      );

      // add limit
      await _addLimit(
        name: data["name"], 
        customer: data["customer"], 
        palance: data["palance"],
        uptime: data["uptime"],
        hotspotProfile: "MikroNet_${data["name"]}_profile"
      );

      // add profile
      await _addProfile(
        name: data["name"], 
        customer: data["customer"], 
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
      if(MikrotikClient.version==7){
        return await ProfilesApi7.profileEdit(name, data);
      }
      var profileResponse=await getProfiles(profileName: name);
      if(!profileResponse.status || profileResponse.data == null || profileResponse.data!.isEmpty){
        return AppResponse<void>(status: false, message: "Profile not found");
      }
      ProfilesModel profile = profileResponse.data![0];
      
      String newProfileName='MikroNet_${data["name"]??profile.name}_profile';
      String newLimitName='MikroNet_${data["name"]??profile.name}_limit';

      // edit hotspot profile
      await MikrotikClient.editData(
        command: "/ip/hotspot/user/profile/set",
        data: {
          "name": newProfileName.toString() ,
          "shared-users": data["users"]??profile.users ,
          "rate-limit": data["speed"]??profile.speed 
        },
        condition: "?name=MikroNet_${name}_profile"
      );

      // edit limit
      await MikrotikClient.editData(
        command: "/tool/user-manager/profile/limitation/set",
        data: {
          "name": newLimitName ,
          "owner": data["customer"]??profile.customer ,
          "transfer-limit": data["palance"]??profile.palance ,
          "uptime-limit": data["uptime"]??profile.uptime ,
          "group-name": newProfileName ,
        },
        condition: "?name=MikroNet_${name}_limit"
      );
      

      // edit profile
      await MikrotikClient.editData(
        command: "/tool/user-manager/profile/set",
        data: {
          "name": data["name"]??profile.name ,
          "owner": data["customer"]??profile.customer ,
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
      if(MikrotikClient.version==7){
        return await ProfilesApi7.deleteProfile(name);
      }
      String newProfileName='MikroNet_${name}_profile';
      String newLimitName='MikroNet_${name}_limit';

      
      // remove link
      await MikrotikClient.deleteData(
        command: "/tool/user-manager/profile/profile-limitation/remove",
        condition: "?profile=$name"
      );
      
      // remove profile
      await MikrotikClient.deleteData(
        command: "/tool/user-manager/profile/remove",
        condition: "?name=$name"
      );

      // remove limit
      await MikrotikClient.deleteData(
        command: "/tool/user-manager/profile/limitation/remove",
        condition: "?name=$newLimitName"
      );


      // remove hotspot profile
      await MikrotikClient.deleteData(
        command: "/ip/hotspot/user/profile/remove",
        condition: "?name=$newProfileName"
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

  

}