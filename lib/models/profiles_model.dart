
import 'dart:convert';

import 'package:charset/charset.dart';

class ProfilesModel {
  final String id;
  final String name;
  final String price;
  final String palance;
  final String validity;
  final String speed;
  final String customer;
  final String uptime;
  final String users;

  ProfilesModel({
    required this.id,
    required this.name,
    required this.price,
    required this.palance,
    required this.validity,
    required this.speed,
    required this.customer,
    required this.uptime,
    required this.users,
  });
  static String decode(String text) {
    // String word = utf8.decode(
    //     _buffer.sublist(offset + bytesUsedForLength, offset + bytesUsedForLength + length),allowMalformed: true
    //   );
    // String word = windows1256.decode(
    //     _buffer.sublist(offset + bytesUsedForLength, offset + bytesUsedForLength + length),allowInvalid: true
    //   );
    try {
      // نحول النص الغريب إلى بايتات بترميز latin1 ثم نعيد قراءته كـ utf8
      return utf8.decode(windows1256.encode(text), allowMalformed: true);
    } catch (e) {
      return text; // إذا فشل التحويل يرجع النص كما هو
    }
  }

  static ProfilesModel fromMikrotik(Map profile){
    return ProfilesModel(
      id: profile[".id"],
      name: (profile["name"] ?? ""), 
      price: profile["price"]??"", 
      palance: profile["limitations"][0]["transfer-limit"]??"",
      validity: profile["validity"]??"", 
      speed: profile["hotspot_settings"]["rate-limit"]??"",
      customer: profile["owner"], 
      uptime: profile["limitations"][0]["uptime-limit"]??"",
      users: profile["hotspot_settings"]["shared-users"]??"",
    );
  }

  Map toMap(){
    return {
      "id":id,
      "name":name,
      "price":price,
      "palance":palance,
      "validity":validity,
      "speed":speed,
      "customer":customer,
      "uptime":uptime,
      "users":users,
    };
  }
}




class MikrotikTimeHelper {
  int days;
  int hours;

  MikrotikTimeHelper({this.days = 0, this.hours = 0});

  // تحويل نص ميكروتك إلى كائن
  static MikrotikTimeHelper fromString(String timeStr) {
    int d = 0;
    int h = 0;

    // استخراج الأسابيع وتحويلها لأيام (1w = 7d)
    final weekMatch = RegExp(r'(\d+)w').firstMatch(timeStr);
    if (weekMatch != null) d += int.parse(weekMatch.group(1)!) * 7;

    // استخراج الأيام
    final dayMatch = RegExp(r'(\d+)d').firstMatch(timeStr);
    if (dayMatch != null) d += int.parse(dayMatch.group(1)!);

    // استخراج الساعات
    final hourMatch = RegExp(r'(\d+)h').firstMatch(timeStr);
    if (hourMatch != null) h = int.parse(hourMatch.group(1)!);

    return MikrotikTimeHelper(days: d, hours: h);
  }

  // تحويل الكائن إلى نص ميكروتك
  String toMikrotikString() {
    if (days == 0 && hours == 0) return "0s";
    String result = "";
    if (days > 0) result += "${days}d";
    if (hours > 0) result += "${hours}h";
    return result;
  }
}
class MikrotikDataHelper {
  int gigas;
  int megas;

  MikrotikDataHelper({this.gigas = 0, this.megas = 0});

  // تحويل نص ميكروتك (الرصيد) إلى كائن يحتوي جيجا وميجا
  static MikrotikDataHelper fromString(String dataStr) {
    if (dataStr == "" || dataStr == "0") return MikrotikDataHelper();

    double totalMegas = 0;
    // تنظيف النص من المسافات وتحويله لحروف كبيرة
    String cleanStr = dataStr.toUpperCase().trim();

    if (cleanStr.contains('G')) {
      totalMegas = double.tryParse(cleanStr.replaceAll('G', ''))! * 1024;
    } else if (cleanStr.contains('M')) {
      totalMegas = double.tryParse(cleanStr.replaceAll('M', ''))!;
    } else if (cleanStr.contains('K')) {
      totalMegas = double.tryParse(cleanStr.replaceAll('K', ''))! / 1024;
    } else {
      // إذا كان رقماً فقط نعتبره بايت ونحوله لميجا
      totalMegas = (double.tryParse(cleanStr) ?? 0) / (1024 * 1024);
    }

    int g = totalMegas ~/ 1024; // القسم الصحيح هو الجيجا
    int m = (totalMegas % 1024).round(); // الباقي هو الميجا

    return MikrotikDataHelper(gigas: g, megas: m);
  }

  // تحويل الكائن إلى نص ميكروتك (يفضل دائماً الإرسال بالميجا أو الجيجا)
  String toMikrotikString() {
    if (gigas == 0 && megas == 0) return "0";
    // إذا كان هناك جيجا فقط نرسلها بلاحقة G، وإلا نجمع الكل ونرسله بلاحقة M
    if (gigas > 0 && megas == 0) return "${gigas * 1024 * 1024 * 1024}";
    return "${(gigas * 1024 * 1024 * 1024) + (megas *1024*1024)}";
  }
}