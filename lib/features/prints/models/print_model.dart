
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/services.dart';

class LocationData{
  double x;
  double y;
  LocationData({
    required this.x,
    required this.y,
  });
}


  String templates="""
    CREATE TABLE templates (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      password INTEGER,
      serial INTEGER DEFAULT 0,
      image BLOB NOT NULL,
      rows INTEGER,
      columns INTEGER,
      username_fontsize REAL,
      password_fontsize REAL,
      username_location_x REAL,
      username_location_y REAL,
      password_location_x REAL,
      password_location_y REAL
    );
  """;
class PrintTemplatesModel {
  int id;
  String name;
  Uint8List image;
  bool withPassword;
  int numOfRows;
  int numOfColumns;
  double usernameFontSize;
  double passwordFontSize;
  LocationData usernameLocation;
  LocationData passwordLocation;

  PrintTemplatesModel({
    required this.id,
    required this.name,
    required this.image,
    required this.withPassword,
    required this.numOfRows,
    required this.numOfColumns,
    required this.usernameFontSize,
    required this.passwordFontSize,
    required this.usernameLocation,
    required this.passwordLocation,
  });

  static PrintTemplatesModel fromDataForm(Map data){
    // Uint8List image=data["image"]??await getDefaultImage();
    return PrintTemplatesModel(
      id: data["id"], 
      name: data["name"], 
      image: decodeImage(data["image"]),
      withPassword: (data["password"]==1), 
      numOfRows: data["rows"], 
      numOfColumns: data["columns"], 
      usernameFontSize: data["username_fontsize"], 
      passwordFontSize: data["password_fontsize"], 
      usernameLocation: LocationData(
        x: data["username_location_x"], 
        y: data["username_location_y"]
      ),
      // {
      //   "x":data["usernamelocationx"],
      //   "y":data["usernamelocationy"],
      // }, 
      passwordLocation: LocationData(
        x: data["password_location_x"], 
        y: data["password_location_y"]
      ),
      // {
      //   "x":data["passwordlocationx"],
      //   "y":data["passwordlocationy"],
      // },
    );

    
  }

  /// فك ترميز صورة القالب من قاعدة البيانات بشكل **آمن تمامًا**.
  ///
  /// يدعم كل الصيغ الممكنة (لا يُسقط التطبيق في أي حالة):
  /// - نص Base64 (الصيغة الحالية عند الحفظ)
  /// - بايتات خام `Uint8List` / `List<int>` (قوالب قديمة خُزّنت كـBLOB)
  /// - فارغ أو تالف ⇒ صورة فارغة (يُطبع القالب بدون خلفية) بدل الانهيار
  static Uint8List decodeImage(dynamic raw) {
    if (raw == null) return Uint8List(0);
    if (raw is Uint8List) return raw;
    if (raw is List<int>) return Uint8List.fromList(raw);

    final text = raw.toString().trim();
    if (text.isEmpty) return Uint8List(0);
    // أي كائن غير نصي (مثل Future) أو نص غير Base64 ⇒ صورة فارغة
    if (text.startsWith('Instance of') || text.startsWith('[')) return Uint8List(0);

    try {
      return base64Decode(text);
    } catch (_) {
      return Uint8List(0);
    }
  }

  /// قراءة رقم بشكل آمن (يدعم int/double/String/null) مع قيمة افتراضية.
  static double _toDouble(dynamic value, {double fallback = 0}) {
    if (value == null) return fallback;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? fallback;
  }

  static int _toInt(dynamic value, {int fallback = 0}) {
    if (value == null) return fallback;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString()) ?? fallback;
  }

  /// هل هذا الصف يصلح كقالب قابل للاستخدام؟ (غير المفهوم يُستبعد بلا تخمين)
  static bool isUsableRow(Map data) {
    final name = (data["name"] ?? '').toString().trim();
    return name.isNotEmpty;
  }

  static PrintTemplatesModel fromDatabase(Map data){
    return PrintTemplatesModel(
      id: _toInt(data["id"]),
      name: (data["name"] ?? '').toString(),
      image: decodeImage(data["image"]),
      withPassword: _toInt(data["password"]) == 1,
      numOfRows: _toInt(data["rows"], fallback: 18),
      numOfColumns: _toInt(data["columns"], fallback: 4),
      usernameFontSize: _toDouble(data["username_fontsize"], fallback: 14),
      passwordFontSize: _toDouble(data["password_fontsize"], fallback: 14),
      usernameLocation: LocationData(
        x: _toDouble(data["username_location_x"], fallback: 100),
        y: _toDouble(data["username_location_y"], fallback: 100),
      ),
      passwordLocation: LocationData(
        x: _toDouble(data["password_location_x"], fallback: 101),
        y: _toDouble(data["password_location_y"], fallback: 101),
      ),
    );
  }


  Map<String, dynamic> toDatabase(){
    String base64Image = base64Encode(image); 
    return {
      "name": name, 
      "password": withPassword?1:0, 
      "image": base64Image, 
      "rows": numOfRows, 
      "columns": numOfColumns, 
      "username_fontsize": usernameFontSize , 
      "password_fontsize": passwordFontSize, 
      "username_location_x":usernameLocation.x,
      "username_location_y":usernameLocation.y,
      "password_location_x":passwordLocation.x,
      "password_location_y":passwordLocation.y,
    };
  }


  Future<Uint8List> fetchImage(String img) async {
    return base64Decode(img);
  }


  
}



class PrintBatchesModel {
  int id;
  String name;
  DateTime createdAt;
  int templateId;
  List<String> generatedCards;
  String cardsProfile;
  String cardPrefix;
  String cardSuffix;
  List cards;
  String customer; // <-- الحقل الجديد
  String routerSerial;

  PrintBatchesModel({
    required this.id,
    required this.name,
    required this.createdAt,
    this.templateId=0,
    required this.generatedCards,
    required this.cardsProfile,
    this.cardPrefix="",
    this.cardSuffix="",
    this.cards=const [],
    this.customer="", // <-- قيمة افتراضية للحقل الجديد
    this.routerSerial = ""

  });

  static PrintBatchesModel fromDatabase0(Map data){
    List<String> parsedCards = [];
    if (data['generated_cards'] != null && data['generated_cards'].toString().isNotEmpty) {
      parsedCards = data['generated_cards'].toString().split(',');
    }
    return PrintBatchesModel(
      id: data["id"], 
      name: data["name"], 
      createdAt: DateTime.fromMicrosecondsSinceEpoch(data["created_at"]) , 
      templateId: data["template_id"], 
      generatedCards: parsedCards , 
      cardsProfile: data["cards_profile"], 
      cardPrefix: data["card_prefix"], 
      cardSuffix: data["card_suffix"], 
      customer: data["customer"] ?? "", // <-- قراءة الحقل
      routerSerial: data["router_serial"] ?? "", // <-- قراءة الحقل
    );
  }

  static PrintBatchesModel fromDatabase(Map data){
    List<String> parsedCards = [];
    if (data['generated_cards'] != null && data['generated_cards'].toString().isNotEmpty) {
      parsedCards = data['generated_cards'].toString().split(',');
    }
    return PrintBatchesModel(
      id: data["id"], 
      name: data["name"], 
      createdAt: DateTime.fromMicrosecondsSinceEpoch(data["created_at"]) , 
      templateId: data["template_id"], 
      generatedCards: parsedCards , 
      cardsProfile: data["cards_profile"], 
      cardPrefix: data["card_prefix"], 
      cardSuffix: data["card_suffix"], 
      cards: data["cards"] ?? [],
      customer: data["customer"] ?? "", // <-- قراءة الحقل
      routerSerial: data["router_serial"] ?? "",
    );
  }

  static List<GeneratedCardsModel> getCardsFromList(List cards){
    List<GeneratedCardsModel> result=[];
    for (var i in cards) {
      result.add(GeneratedCardsModel.fromDatabase(i));
    }
    return result;
  }

  Map<String,dynamic> toDatabase(){
    return <String,dynamic>{
      "name": name, 
      "created_at": createdAt.microsecondsSinceEpoch, 
      "template_id": templateId, 
      "generated_cards": generatedCards.join(","), 
      "cards_profile": cardsProfile, 
      "card_prefix": cardPrefix , 
      "card_suffix": cardSuffix,
      "customer": customer, // <-- إضافة الحقل عند الحفظ
      "cards": cards,
    };
  }
}


class GeneratedCardsModel {
  int id;
  String username;
  String password;
  String profileName;
  int batchId;
  bool isAdd;

  GeneratedCardsModel({
    required this.id,
    required this.username,
    required this.batchId,
    required this.password,
    required this.profileName,
    required this.isAdd,
  });

  static GeneratedCardsModel fromDatabase(Map data){
    return GeneratedCardsModel(
      id: data["id"], 
      username: data["username"], 
      batchId: data["batch_id"], 
      password: data["password"], 
      profileName: data["profile_name"], 
      isAdd: data["is_add"]==1
    );
  }


  Map<String, dynamic> toDatabase(){
    return {
      "username": username, 
      "batch_id": batchId, 
      "password": password, 
      "profile_name": profileName , 
      "is_add": isAdd, 
    };
  }
 

}



