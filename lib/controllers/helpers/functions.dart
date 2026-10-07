import 'dart:math';

// String type is "numbers" or "letters" or "mixed"
List<String> generateUniqueRandomStrings({
  required int count,
  int length = 7,
  String prefix = "",
  String suffix = "",
  String type = "numbers", // "numbers", "letters", "mixed"
  List<String> users=const []
}) {
  const String letters = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz";
  const String digits = "0123456789";
  const String mix = "012345678901234567890123456789";

  String characters;
  switch (type) {
    case "letters":
      characters = letters;
      break;
    case "mixed":
      characters = letters + mix;
      break;
    case "numbers":
    default:
      characters = digits;
      break;
  }

  Random random = Random();
  Set<String> uniqueValues = {};

  while (uniqueValues.length < count) {
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





