import 'package:get/get.dart';

import '../models/sites_model.dart';
import '/models/profiles_model.dart';
import '/services/mikrotik_client.dart';
import '../models/response.dart';
import '../models/cards_model.dart';

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










class CardsApi7 {

  static CardModel fromMikrotik7(Map card){
    String tempStatus="normal";

    if(card["profile"].isNotEmpty && (card["profile"]["state"]=="used" || card["profile"]["state"]=="running")){
      tempStatus="expired";
    }
    else if(card["profile"].isNotEmpty && card["profile"]["state"]=="running-active"){
      tempStatus="active";
    }
    else{
      tempStatus="normal";
    }
    return CardModel(
      id: card[".id"]??'0',
      username: card["name"]??'name', 
      password: card["password"]??'', 
      profile: (card["profile"]["profile"]??"profile").toString(), 
      status: tempStatus, 
      customer: card["group"]??'default',
    );
  }

  

  static Future<List> _getAllCards({List where = const ["=detail="]}) async {
    try {
      List myCardsProfiles = await MikrotikClient.printData(
          commands: ["/user-manager/user-profile/print"], 
          fields: '.id,user,profile,state',
          tag: 'cards_profiles'
        );

      List myCards = await MikrotikClient.printData(
          commands: ["/user-manager/user/print"],
          fields: '.id,name,group,password',
          tag: 'cards'
        );
      
      List result=[];
      for (var card in myCards) {
        var link=myCardsProfiles.where((profile)=>profile['user']==card['name']).toList();
        Map temp=Map.from(card);
        temp['profile']=link.isNotEmpty?link.last:{};
        result.add(temp);  
      }
      return result;
    } catch (e) {
      throw e.toString();
    }
  }

  static Future<AppResponse<List<CardModel>>> getAllCards({List where = const ["=detail="]}) async {
    try {
      List myCards = await _getAllCards(where: where);


      List<CardModel> cards =
          myCards.map((e) => 
          // CardModel(
          //   id: e[".id"]??'0',
          //   username: e["name"]??'nnn', 
          //   password: e["password"]??'', 
          //   profile: (e["profile"]["profile"]??"unknown").toString(), 
          //   status: e, 
          //   customer: e["group"]??'default',
          // )).toList();
          
          fromMikrotik7(e)).toList();

      return AppResponse<List<CardModel>>(
          status: true, message: "done", data: cards);
    } catch (e) {
      return AppResponse<List<CardModel>>(
        status: false,
        message: e.toString(),
      );
    }
  }
  

  static Future<AppResponse<void>> addCardProfile({
    // required String customer,
    required String username,
    required String profile,
  }) async {
    try {
      await MikrotikClient.addData(
          command: "/user-manager/user-profile/add",
          data: {
            // "customer": customer,
            "user": username,
            "profile": profile,
          });
      return AppResponse<void>(status: true, message: "done", data: null);
    } catch (e) {
      return AppResponse<void>(status: false, message: e.toString(), data: null);
    }
  }

  static Future<AppResponse<void>> addOneCard({
    required String group,
    required String username,
    String password = "",
    required String profile,
  }) async {
    try {
      await MikrotikClient.addData(command: "/user-manager/user/add", data: {
        "name": username,
        "group": group,
        "password": password,
        "shared-users": '',
      });

      await MikrotikClient.addData(
          command: "/user-manager/user-profile/add",
          data: {
            "user": username,
            "profile": profile,
          });
      return AppResponse<void>(
        status: true,
        message: "done",
      );
    } on Exception catch (e) {
      return AppResponse<void>(
        status: false,
        message: e.toString(),
      );
    }
  }



  static Future<AppResponse<List<CustomerModel>>> getGroups() async {
    try {
      List myCustomers = await MikrotikClient.printData(
          commands: ["/user-manager/user/group/print"],
          // conditions: ["?disabled=no"]
        );
      List<CustomerModel> result =
          myCustomers.map((e) => 
          CustomerModel(
            id: e['attributes'],
            name: e['name'],
          )).toList();
          // CustomerModel.fromMikrotik(e)).toList();
      return AppResponse<List<CustomerModel>>(
          status: true, message: "done", data: result);
    } catch (e) {
      return AppResponse<List<CustomerModel>>(
        status: false,
        message: e.toString(),
      );
    }
  }

  static Future<AppResponse<void>> cardEdit({
    required String username,
    required Map<String, String> data,
  }) async {
    try {
      data['name']=data['username']!;
      data.remove('username');
      await MikrotikClient.editData(
          command: "/user-manager/user/set",
          data: data,
          condition: "?name=$username");
      return AppResponse<void>(
        status: true,
        message: "done",
      );
    } on Exception catch (e) {
      return AppResponse<void>(
        status: false,
        message: e.toString(),
      );
    }
  }

  static Future<AppResponse<void>> deleteCard(String username) async {
    try {
      await MikrotikClient.deleteData(
          command: "/user-manager/user/remove",
          condition: "?name=$username");
      return AppResponse<void>(
        status: true,
        message: "done",
      );
    } on Exception catch (e) {
      return AppResponse<void>(
        status: false,
        message: e.toString(),
      );
    }
  }

  static Future<AppResponse<void>> deleteCardsBatch(List idsList) async {
    try {
      String ids = idsList.join(',');
      await MikrotikClient.fetch(
        command: ["/user-manager/user/remove", '=numbers=$ids'],
      );
      return AppResponse<void>(
        status: true,
        message: "done",
      );
    } on Exception catch (e) {
      return AppResponse<void>(
        status: false,
        message: e.toString(),
      );
    }
  }

  static Future<AppResponse<List<String>>> getIdsByUsernames(List usernames) async {
    List<String> extractedIds = [];

    try {
      // 1. جلب المعرفات والأسماء فقط من الراوتر (سريع جداً)
      var allUsers = await MikrotikClient.printData(
          commands: [
            '/user-manager/user/print',
          ],
          fields: ".id,name");

      // 2. المرور على الناتج واستخراج الـ id للكروت المطابقة
      for (var user in allUsers) {
        if (usernames.contains(user['name'])) {
          extractedIds.add(user['.id']!);
        }
      }

      return AppResponse<List<String>>(status: true, message: "done", data: extractedIds);
    } catch (e) {
      return AppResponse<List<String>>(status: false, message: e.toString());
    }
  }

  static Future<AppResponse<List<CardSessionModel>>> getCardSessions(
      String username) async {
    try {
      List sessions = await MikrotikClient.printData(
          commands: ["/user-manager/session/print"],
          conditions: ["?user=$username"],
          fields: '.id,user,started,ended,calling-station-id,user-address,uptime,nas-port-id,download,upload,last-accounting-packet',
          tag: 'cards_sessions'
        );
      List<CardSessionModel> result = sessions
          .map((session) => 
          CardSessionModel(
            id: session['.id']??'0', 
            username: session['user']??'unknown', 
            fromTime: session['started']??'1999-01-01 00:00:00', 
            toTime: (session['ended']??session['last-accounting-packet'])??'1999-01-01 00:00:00',  
            macAddress: session['calling-station-id'], 
            ip: session['user-address'], 
            uptime: session['uptime'], 
            port: session['nas-port-id'], 
            download: session['download'], 
            upload: session['upload']) )
          // CardSessionModel.fromMikrotik(session))
          .toList();
      return AppResponse<List<CardSessionModel>>(
          status: true, message: "done", data: result);
    } catch (e) {
      return AppResponse<List<CardSessionModel>>(
        status: false,
        message: e.toString(),
      );
    }
  }
  

  // Future<List> getCustomers()async{
  //   return await mikrotik.getAllProperties(command: commands[version]['user_customers']);
  // }

  // // 1. البحث عن الكروت المنتهية التي تم استخدامها مسبقاً
  // var expiredUsers = await client.talk([
  //   '/tool/user-manager/user/print',
  //   '?-actual-profile', 
  //   '?>uptime-used=0s'  
  // ]);

  // if (expiredUsers.isEmpty) {
  //   print('ممتاز! لا يوجد كروت منتهية لحذفها.');
  //   return; // إنهاء العملية إذا لم يكن هناك بيانات
  // }

  // // 2. استخراج المعرفات الداخلية (.id) من النتائج
  // List<String> idsToDelete = [];
  // for (var user in expiredUsers) {
  //   if (user.containsKey('.id')) {
  //     idsToDelete.add(user['.id']!);
  //   }
  // }

  // print('تم العثور على ${idsToDelete.length} كارت منتهي. جاري الحذف...');

  // // 3. تقسيم المعرفات إلى دفعات (50 كارت في كل دفعة) للحفاظ على استقرار الراوتر
  // int batchSize = 50;
  // for (var i = 0; i < idsToDelete.length; i += batchSize) {
  //   // تحديد بداية ونهاية الدفعة الحالية
  //   var end = (i + batchSize < idsToDelete.length) ? i + batchSize : idsToDelete.length;
  //   var batch = idsToDelete.sublist(i, end);

  //   // دمج المعرفات بفاصلة (مثال: *1,*2,*3A)
  //   String numbers = batch.join(',');

  //   try {
  //     // 4. إرسال أمر الحذف للدفعة الحالية
  //     await client.talk([
  //       '/tool/user-manager/user/remove',
  //       '=numbers=$numbers'
  //     ]);
      
  //     print('تم حذف الدفعة من ${i + 1} إلى $end بنجاح.');
  //   } catch (e) {
  //     print('حدث خطأ أثناء حذف الدفعة ${i + 1} إلى $end: $e');
  //     // الكود سيستمر في محاولة حذف الدفعات الأخرى حتى لو فشلت إحداها
  //   }
  // }

  // print('تم الانتهاء من تنظيف قاعدة البيانات بالكامل!');


}






class SitesApi7 {

  
    // ==========================================
  // Layer7 Methods (RouterOS v7)
  // ==========================================

  static Future<AppResponse> addBlockByLayer7(BlockedSiteModel site) async {
    try {
      String comment = "MikroNet_Block_${site.name}_[v7]";
      
      var layer7 = await MikrotikClient.addData(
        command: "/ip/firewall/layer7-protocol/add",
        data: {'name': site.name, 'regexp': site.blockValue, 'comment': comment}
      );

      var filter = await MikrotikClient.addData(
        command: "/ip/firewall/filter/add",
        data: {
          'action': 'drop',
          'chain': 'forward',
          'layer7-protocol': site.name,
          'out-interface': site.interface.isEmpty ? "all-ethernet" : site.interface,
          'comment': comment
        }
      );
      return AppResponse(status: true, message: "${layer7.toString()} , ${filter.toString()}");
    } catch (e) {
      return AppResponse(status: false, message: e.toString());
    }
  }

  static Future<AppResponse> editBlockByLayer7(BlockedSiteModel site) async {
    try {
      String comment = "MikroNet_Block_${site.name}_[v7]";
      
      await MikrotikClient.addData(
        command: "/ip/firewall/layer7-protocol/set",
        data: {
          '.id': site.layer7Id,
          'name': site.name,
          'regexp': site.blockValue,
          'comment': comment
        }
      );

      await MikrotikClient.addData(
        command: "/ip/firewall/filter/set",
        data: {
          '.id': site.filterId,
          'layer7-protocol': site.name,
          'out-interface': site.interface,
          'comment': comment
        }
      );
      
      return AppResponse(status: true, message: "تم التعديل بنجاح");
    } catch (e) {
      return AppResponse(status: false, message: e.toString());
    }
  }

  // ==========================================
  // SSL Methods
  // ==========================================
  // ==========================================
  // SSL Methods (RouterOS v7)
  // ==========================================

  static Future<AppResponse> _addSSLMangleV7(String name, String domain, String comment) async {
    try {
      var response = await MikrotikClient.addData(
        command: "/ip/firewall/mangle/add",
        data: {
          'action': 'add-dst-to-address-list',
          'address-list': name,
          'address-list-timeout': '1d',
          'chain': 'prerouting',
          'protocol': 'tcp',
          'dst-port': '443', // إضافة مخصصة لـ V7
          'tls-host': '*$domain*',
          'comment': comment,
        }
      );
      return AppResponse(status: true, message: "done", data: response);
    } catch (e) {
      return AppResponse(status: false, message: e.toString());
    }
  }

  static Future<AppResponse> _addSSLFilterTlsV7(String outInterface, String domain, String comment) async {
    try {
      var response = await MikrotikClient.addData(
        command: "/ip/firewall/filter/add",
        data: {
          'action': 'drop',
          'chain': 'forward',
          'protocol': 'tcp',
          'dst-port': '443', // إضافة مخصصة لـ V7
          'tls-host': '*$domain*',
          'out-interface': outInterface,
          'comment': comment,
        }
      );
      return AppResponse(status: true, message: "done", data: response);
    } catch (e) {
      return AppResponse(status: false, message: e.toString());
    }
  }

  static Future<AppResponse> _linkFilterWithMangleV7(String name, String outInterface, String comment) async {
    try {
      var response = await MikrotikClient.addData(
        command: "/ip/firewall/filter/add",
        data: {
          'action': 'drop',
          'chain': 'forward',
          // الانتباه هنا: لا نضيف dst-port بناءً على السكربت الذي أرسلته لفلتر الـ IP
          'dst-address-list': name,
          'out-interface': outInterface,
          'comment': comment,
        }
      );
      return AppResponse(status: true, message: "done", data: response);
    } catch (e) {
      return AppResponse(status: false, message: e.toString());
    }
  }

  static Future<AppResponse> addBlockBySSL(BlockedSiteModel site) async {
    try {
      String comment = "MikroNet_Block_${site.name}_[v7]"; // تمييز التعليق بـ v7
      String outInterface = site.interface.isEmpty ? "all-ethernet" : site.interface;

      var mangle = await _addSSLMangleV7(site.name, site.blockValue, comment);
      var tls = await _addSSLFilterTlsV7(outInterface, site.blockValue, comment);
      var link = await _linkFilterWithMangleV7(site.name, outInterface, comment);
      
      var response = [mangle, tls, link];
      return AppResponse(status: true, message: "${mangle.message} , ${tls.message} , ${link.message}", data: response);
      
    } catch (e) {
      return AppResponse(status: false, message: e.toString());
    }
  }

  static Future<AppResponse> editBlockBySSL(BlockedSiteModel site) async {
    try {
      String comment = "MikroNet_Block_${site.name}_[v7]";

      // 1. تعديل المانجل
      await MikrotikClient.addData(
        command: "/ip/firewall/mangle/set",
        data: {
          '.id': site.id, 
          'address-list': site.name,
          'protocol': 'tcp',
          'dst-port': '443', // تأكيد وجود البورت عند التعديل
          'tls-host': '*${site.blockValue}*',
          'comment': comment,
        }
      );

      // 2. تعديل فلتر الـ TLS
      await MikrotikClient.addData(
        command: "/ip/firewall/filter/set",
        data: {
          '.id': site.filterId,
          'protocol': 'tcp',
          'dst-port': '443', // تأكيد وجود البورت عند التعديل
          'tls-host': '*${site.blockValue}*',
          'out-interface': site.interface,
          'comment': comment,
        }
      );

      // 3. تعديل فلتر الربط
      await MikrotikClient.addData(
        command: "/ip/firewall/filter/set",
        data: {
          '.id': site.linkId,
          'dst-address-list': site.name,
          'out-interface': site.interface,
          'comment': comment,
        }
      );

      return AppResponse(status: true, message: "تم التعديل بنجاح");
    } catch (e) {
      return AppResponse(status: false, message: e.toString());
    }
  }

  

}