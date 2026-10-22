
import 'package:mikronet/core/mikrotik/mikrotik_client.dart';
import 'package:mikronet/core/models/app_response.dart';
import 'package:mikronet/features/cards/models/cards_model.dart';


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
      
      // بناء جدول مطابقة O(1) لتسريع المزامنة بشكل هائل
      final Map<String, Map> profilesByUser = {};
      for (var profile in myCardsProfiles) {
        if (profile is Map) {
          final user = profile['user']?.toString();
          if (user != null && user.isNotEmpty) {
            profilesByUser[user] = profile;
          }
        }
      }

      List result = [];
      for (var card in myCards) {
        if (card is Map) {
          final name = card['name']?.toString() ?? '';
          Map temp = Map.from(card);
          temp['profile'] = profilesByUser[name] ?? {};
          result.add(temp);
        }
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
        // RouterOS User Manager requires a positive integer (default is 1).
        // Sending an empty string can reject every generated user.
        "shared-users": '1',
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
  //   debugPrint('ممتاز! لا يوجد كروت منتهية لحذفها.');
  //   return; // إنهاء العملية إذا لم يكن هناك بيانات
  // }

  // // 2. استخراج المعرفات الداخلية (.id) من النتائج
  // List<String> idsToDelete = [];
  // for (var user in expiredUsers) {
  //   if (user.containsKey('.id')) {
  //     idsToDelete.add(user['.id']!);
  //   }
  // }

  // debugPrint('تم العثور على ${idsToDelete.length} كارت منتهي. جاري الحذف...');

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
      
  //     debugPrint('تم حذف الدفعة من ${i + 1} إلى $end بنجاح.');
  //   } catch (e) {
  //     debugPrint('حدث خطأ أثناء حذف الدفعة ${i + 1} إلى $end: $e');
  //     // الكود سيستمر في محاولة حذف الدفعات الأخرى حتى لو فشلت إحداها
  //   }
  // }

  // debugPrint('تم الانتهاء من تنظيف قاعدة البيانات بالكامل!');


}






