import 'dart:math';

extension ByteFormatter on String {
  
  String get formatBytes {
    // تنظيف النص وتحويله لأحرف صغيرة لتسهيل المقارنة
    String input = this.trim().toLowerCase();
    double bytes = 0;

    // استخراج الرقم والوحدة (إن وجدت) باستخدام Regex
    // يطابق الأرقام (والفواصل العشرية) ثم أي نصوص تأتي بعدها
    final regex = RegExp(r'^([\d.]+)\s*(.*)$');
    final match = regex.firstMatch(input);

    if (match != null) {
      double value = double.tryParse(match.group(1)!) ?? 0;
      String unit = match.group(2)!.trim();

      // تحويل القيمة إلى بايتات أساسية بناءً على الوحدة المدخلة
      if (['kb', 'kib', 'k'].contains(unit)) {
        bytes = value * 1024;
      } else if (['mb', 'mib', 'm'].contains(unit)) {
        bytes = value * pow(1024, 2);
      } else if (['gb', 'gib', 'g'].contains(unit)) {
        bytes = value * pow(1024, 3);
      } else if (['tb', 'tib', 't'].contains(unit)) {
        bytes = value * pow(1024, 4);
      } else {
        // إذا لم يكن هناك وحدة (بايت خام) أو الوحدة b أو byte
        bytes = value;
      }
    }

    // إذا كانت القيمة صفر أو أقل
    if (bytes <= 0) return "0 بايت";

    const suffixes = ["بايت", "كيلوبايت", "ميجابايت", "جيجابايت", "تيرابايت"];
    int i = (log(bytes) / log(1024)).floor();
    
    // حماية إضافية لمنع الخطأ إذا كان الرقم المدخل كبيراً جداً وتجاوز المصفوفة
    if (i >= suffixes.length) i = suffixes.length - 1;

    double result = bytes / pow(1024, i);
    
    // إرجاع النتيجة بالصيغة المطلوبة
    return "${result.toStringAsFixed(2)} ${suffixes[i]}";
  }
}
extension DateFormatExt on String {
  String get formatDate {
    String input = trim();
    // إذا كان النص فارغاً نرجعه كما هو
    if (input.isEmpty) return this;

    try {
      // 1. محاولة تحويل الصيغة القياسية (مثل: 2026-03-14 23:46:17)
      DateTime? parsedDate = DateTime.tryParse(input);
      
      if (parsedDate != null) {
        // استخراج الوقت (ساعات:دقائق:ثواني) وتنسيقها بإضافة صفر إذا كانت رقماً واحداً
        String time = "${parsedDate.hour.toString().padLeft(2, '0')}:${parsedDate.minute.toString().padLeft(2, '0')}:${parsedDate.second.toString().padLeft(2, '0')}";
        
        // دمج النتيجة بالشكل (وقت  يوم/شهر/سنة)
        return "$time  ${parsedDate.day}/${parsedDate.month}/${parsedDate.year}";
      }

      // 2. إذا لم تكن الصيغة قياسية، نتعامل مع الصيغة المخصصة: "jul/13/2025 13:28:46"
      var parts = input.split(' ');
      if (parts.isEmpty) return this;

      var dateParts = parts[0].split('/');
      
      // إذا لم يكن التاريخ بالصيغة المتوقعة (3 أجزاء مفصولة بـ /)، نرجع النص الأصلي
      if (dateParts.length != 3) return this;

      // خريطة لتحويل اختصارات الأشهر الإنجليزية إلى أرقام
      const months = {
        'jan': '1', 'feb': '2', 'mar': '3', 'apr': '4', 'may': '5', 'jun': '6',
        'jul': '7', 'aug': '8', 'sep': '9', 'oct': '10', 'nov': '11', 'dec': '12'
      };

      String monthStr = dateParts[0].toLowerCase();
      String month = months[monthStr] ?? monthStr; 
      String day = dateParts[1];
      String year = dateParts[2];

      // التعامل مع جزء الوقت (إن وجد)
      String time = parts.length > 1 ? parts[1] : '';

      // دمج النتيجة بالشكل المطلوب (يوم/شهر/سنة وقت)
      return "$time  $day/$month/$year".trim();
      
    } catch (e) {
      // في حال حدوث أي خطأ غير متوقع في التحويل، يتم عرض النص الأصلي لتجنب الكراش
      return this;
    }
}

}
extension UptimeFormatter on String {
  
  String get formatUptime {
    // التحقق إذا كان النص فارغاً
    if (trim().isEmpty) return "0 ثانية";

    // تعبير قياسي (Regex) لاستخراج الرقم والوحدة (w, d, h, m, s)
    final regex = RegExp(r'(\d+)([wdhms])');
    final matches = regex.allMatches(toLowerCase());

    // إذا لم يتطابق النص مع الصيغة المعروفة، يتم إرجاعه كما هو
    if (matches.isEmpty) return this; 

    int totalDays = 0;
    String hours = "";
    String minutes = "";
    String seconds = "";

    for (final match in matches) {
      final int value = int.tryParse(match.group(1) ?? "0") ?? 0;
      final String unit = match.group(2) ?? "";

      switch (unit) {
        case 'w':
          // تحويل الأسابيع إلى أيام (كل أسبوع 7 أيام)
          totalDays += value * 7;
          break;
        case 'd':
          // إضافة الأيام الموجودة إلى الإجمالي
          totalDays += value;
          break;
        case 'h':
          hours = "$value ساعة";
          break;
        case 'm':
          minutes = "$value دقيقة";
          break;
        case 's':
          seconds = "$value ثانية";
          break;
      }
    }

    List<String> formattedParts = [];

    // إضافة الأيام المجمعة (أسابيع + أيام) إذا كانت أكبر من صفر
    if (totalDays > 0) {
      formattedParts.add('$totalDays يوم');
    }
    
    // إضافة بقية الوحدات إذا كانت موجودة
    if (hours.isNotEmpty) formattedParts.add(hours);
    if (minutes.isNotEmpty) formattedParts.add(minutes);
    if (seconds.isNotEmpty) formattedParts.add(seconds);

    // دمج المخرجات بفاصل سطر جديد، وإذا كانت القائمة فارغة نرجع 0 ثانية
    return formattedParts.isNotEmpty ? formattedParts.join('\n') : "0 ثانية";
  }
}