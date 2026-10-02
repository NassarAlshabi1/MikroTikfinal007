
import 'package:mikronet/api/version7_api.dart';

import '../models/cards_model.dart';
import '../services/mikrotik_client.dart';
import '../models/response.dart';

class CardsApi {
  int version;
  CardsApi({this.version=6});
  Map commands={
    6:
    {
      'user_profiles':'/tool/user-manager/profile/print',
      'user_customers':'/tool/user-manager/customer/print',
      'user_adduser':'/tool/user-manager/user/add',
      'user_addprofile':'/tool/user-manager/user/create-and-activate-profile',
    },
    7:
    {
      'user_profiles':'/user-manager/profile/print',
      'user_customers':'/user-manager/user/group/print',
      'user_adduser':'/user-manager/user/add',
      'user_addprofile':'/user-manager/user-profile/add',
    },
  };
  static const String _props=""".id,username,password,actual-profile,uptime-used,download-used,upload-used,last-seen,customer""";
  // List cards=[];

  


  static Future<AppResponse<List<CardModel>>> getAllCards({List where = const ["=detail="]}) async {
    try {
      if(MikrotikClient.version==7){
        return await CardsApi7.getAllCards(where: where);
      }
      List myCards = await MikrotikClient.printData(
          commands: ["/tool/user-manager/user/print"], fields: _props,tag: 'cards');

      List<CardModel> cards =
          myCards.map((e) => CardModel.fromMikrotik(e)).toList();

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
    required String customer,
    required String username,
    required String profile,
  }) async {
    try {
      if(MikrotikClient.version==7){
        return await CardsApi7.addCardProfile(
          username: username,
          profile: profile
        );
      }
      await MikrotikClient.addData(
          command: "/tool/user-manager/user/create-and-activate-profile",
          data: {
            "customer": customer,
            "numbers": username,
            "profile": profile,
          });
      return AppResponse<void>(status: true, message: "done", data: null);
    } catch (e) {
      return AppResponse<void>(status: false, message: e.toString(), data: null);
    }
  }

  static Future<AppResponse<void>> addOneCard({
    required String customer,
    required String username,
    String password = "",
    required String profile,
  }) async {
    try {
      if(MikrotikClient.version==7){
        return await CardsApi7.addOneCard(
          group: customer, 
          username: username, 
          password: password,
          profile: profile
        );
      }
      await MikrotikClient.addData(command: "/tool/user-manager/user/add", data: {
        "customer": customer,
        "username": username,
        "password": password,
      });

      await MikrotikClient.addData(
          command: "/tool/user-manager/user/create-and-activate-profile",
          data: {
            "customer": customer,
            "numbers": username,
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

  static Future<AppResponse<List<CustomerModel>>> getCustomers() async {
    try {
      if(MikrotikClient.version==7){
        return await CardsApi7.getGroups();
      }
      List myCustomers = await MikrotikClient.printData(
          commands: ["/tool/user-manager/customer/print"],
          conditions: ["?disabled=no"]);
      List<CustomerModel> result =
          myCustomers.map((e) => CustomerModel.fromMikrotik(e)).toList();
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
      if(MikrotikClient.version==7){
        return await CardsApi7.cardEdit(username: username,data: data);
      }
      await MikrotikClient.editData(
          command: "/tool/user-manager/user/set",
          data: data,
          condition: "?username=$username");
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
      if(MikrotikClient.version==7){
        return await CardsApi7.deleteCard(username);
      }
      await MikrotikClient.deleteData(
          command: "/tool/user-manager/user/remove",
          condition: "?username=$username");
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
      if(MikrotikClient.version==7){
        return await CardsApi7.deleteCardsBatch(idsList);
      }
      String ids = idsList.join(',');
      await MikrotikClient.fetch(
        command: ["/tool/user-manager/user/remove", '=numbers=$ids'],
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
      if(MikrotikClient.version==7){
        return await CardsApi7.getIdsByUsernames(usernames);
      }
      // 1. جلب المعرفات والأسماء فقط من الراوتر (سريع جداً)
      var allUsers = await MikrotikClient.printData(
          commands: [
            '/tool/user-manager/user/print',
          ],
          fields: ".id,username");

      // 2. المرور على الناتج واستخراج الـ id للكروت المطابقة
      for (var user in allUsers) {
        if (usernames.contains(user['username'])) {
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
      if(MikrotikClient.version==7){
        return await CardsApi7.getCardSessions(username);
      }
      List sessions = await MikrotikClient.printData(
          commands: ["/tool/user-manager/session/print"],
          conditions: ["?user=$username"],tag: 'cards_sessions');
      List<CardSessionModel> result = sessions
          .map((session) => CardSessionModel.fromMikrotik(session))
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





