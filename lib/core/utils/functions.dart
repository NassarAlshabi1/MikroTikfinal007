import 'dart:math';

// أنماط الأحرف — نفس تجمعات تطبيق ABOTALAL مع استبعاد الأحرف المشبهة
// (بلا 0/O و 1/l/I) لتقليل أخطاء قراءة الكروت المطبوعة.
const Map<String, String> kCardCharPools = {
  "numbers": "0123456789",
  "mixed": "23456789ABCDEFGHJKLMNPQRSTUVWXYZ",
  "lower": "abcdefghijkmnopqrstuvwxyz",
  "upper": "ABCDEFGHJKLMNPQRSTUVWXYZ",
  // توافق مع القيم القديمة إن استخدمت
  "letters": "ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz",
};

// String type is "numbers" or "letters" or "mixed" or "lower" or "upper"
List<String> generateUniqueRandomStrings({
  required int count,
  int length = 7,
  String prefix = "",
  String suffix = "",
  String type = "numbers", // "numbers", "mixed", "lower", "upper", "letters"
  Set<String> excludedChars = const {},
  List<String> users=const []
}) {
  String characters = kCardCharPools[type] ?? kCardCharPools["numbers"]!;
  // استبعاد أحرف يدوياً (مثل ABOTALAL) — إن استُبعدت التجمع كلها نرجع للأصل.
  if (excludedChars.isNotEmpty) {
    final filtered = characters
        .split("")
        .where((c) => !excludedChars.contains(c))
        .join();
    if (filtered.isNotEmpty) characters = filtered;
  }

  Random random = Random();
  Set<String> uniqueValues = {};

  // سقف محاولات يمنع التعليق اللانهائي عند استنفاد فضاء التركيبات
  // (مثلاً طول قصير جداً + بادئة/لاحقة تلتهمانه + عدد كبير).
  final int maxAttempts = count * 500 + 1000;
  int attempts = 0;

  while (uniqueValues.length < count) {
    if (++attempts > maxAttempts) {
      throw StateError(
          "تعذّر توليد $count كرتاً فريداً بهذه المواصفات — زد طول الرمز أو غيّر النمط");
    }
    String randomString = List.generate(
      length,
      (index) => characters[random.nextInt(characters.length)],
    ).join();
    String cardText="$prefix$randomString$suffix";

    if (!users.contains(cardText)) {
      uniqueValues.add(cardText);
    }
  }

  return uniqueValues.toList();
}



String formatBytes(int bytes) {
  // إذا كان الحجم أقل من كيلو بايت واحد
  if (bytes < 1024) return "${bytes}B"; 

  // تعريف ثوابت الأحجام (نستخدم 1024 لأنها الحسبة البرمجية الدقيقة)
  const int kb = 1024;
  const int mb = kb * 1024;
  const int gb = mb * 1024;

  // استخراج الجيجا بايت والباقي
  int g = bytes ~/ gb;
  int remainder = bytes % gb;

  // استخراج الميجا بايت من الباقي
  int m = remainder ~/ mb;
  remainder = remainder % mb;

  // استخراج الكيلو بايت من الباقي
  int k = remainder ~/ kb;
  
  // إذا كنت تريد إظهار البايتات المتبقية أيضاً يمكنك تفعيل هذا السطر
  // int b = remainder % kb; 

  // تجميع النص النهائي
  List<String> parts = [];
  if (g > 0) parts.add("${g}G");
  if (m > 0) parts.add("${m}M");
  if (k > 0) parts.add("${k}K");
  // if (b > 0) parts.add("${b}B");

  // دمج القيم بفاصلة، أو إرجاع 0K إذا كانت النتيجة فارغة بطريقة ما
  return parts.isEmpty ? "0K" : parts.join(",");
}



dynamic getAttrFromQuery(List items, var feature, var key, var value) {
  List<dynamic> ids = [];
  List<dynamic> names = [];
  for (var item in items) {
    ids.add(item[feature]);
    names.add(item[key]);
  }
  Map x = {
    feature: ids,
    key: names,
  };
  int index = x[key].indexOf(value);
  return x[feature][index];
}





