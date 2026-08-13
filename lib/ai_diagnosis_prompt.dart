import 'dart:convert';

/// تمثيل محايد لنتيجة فحص تُرسل إلى أي مزوّد ذكاء اصطناعي يختاره المستخدم.
/// لا يتضمن هذا النموذج أي بيانات اعتماد أو إعدادات حساسة للراوتر.
class AIDiagnosticTestResult {
  const AIDiagnosticTestResult({
    required this.id,
    required this.title,
    required this.status,
    required this.message,
    this.latencyMs,
    this.downloadSpeedMbps,
    this.uploadSpeedMbps,
  });

  final String id;
  final String title;
  final String status;
  final String message;
  final double? latencyMs;
  final double? downloadSpeedMbps;
  final double? uploadSpeedMbps;

  Map<String, Object?> toJson() => {
        'id': id,
        'title': title,
        'status': status,
        'message': message,
        if (latencyMs != null) 'latency_ms': latencyMs,
        if (downloadSpeedMbps != null) 'download_mbps': downloadSpeedMbps,
        if (uploadSpeedMbps != null) 'upload_mbps': uploadSpeedMbps,
      };
}

/// يبني prompt عربياً منضبطاً لتفسير نتائج الفحوص، دون ربط التطبيق بمزوّد AI
/// أو تمرير أي كلمات مرور أو مفاتيح API من الجهاز.
class AIDiagnosisPrompt {
  const AIDiagnosisPrompt._();

  static String build({
    required String? gatewayIp,
    required List<AIDiagnosticTestResult> tests,
  }) {
    final payload = <String, Object?>{
      'gateway_ip': gatewayIp?.trim().isNotEmpty == true ? gatewayIp : null,
      'tests': tests.map((test) => test.toJson()).toList(growable: false),
      'measurement_notes': const [
        'فحص البوابة يعتمد على محاولتي ping.',
        'قياس زمن الاستجابة يعتمد على أربع محاولات إلى 1.1.1.1.',
        'اختبار السرعة اختياري، ويقيس اتصال الجهاز وقت الاختبار فقط.',
        'لا تتوفر في هذه البيانات سرعة الباقة المتعاقد عليها أو نسبة فقد الحزم أو سجلات RouterOS.',
      ],
    };

    const encoder = JsonEncoder.withIndent('  ');
    final diagnosisData = encoder.convert(payload);

    return '''أنت مهندس دعم شبكات محترف وخبير MikroTik RouterOS. حلّل تقرير القياس أدناه لتقديم تشخيص عملي ودقيق باللغة العربية الفصحى.

قواعد إلزامية:
1. استند حصراً إلى البيانات المتاحة. لا تخترع عنواناً أو سرعة باقة أو نسبة فقد حزم أو إعدادات RouterOS أو سبباً مؤكداً غير مقاس.
2. اربط النتائج قبل إصدار الحكم: فشل البوابة يجعل فشل الإنترنت وDNS نتيجةً غير كافية لإثبات عطل خارجي؛ نجاح الإنترنت مع فشل DNS يرجّح خلل DNS؛ وفشل الإنترنت وDNS مع نجاح البوابة يرجّح مشكلة في المسار الخارجي أو WAN قبل اتهام DNS وحده.
3. لا تصنّف السرعة بأنها بطيئة مقارنةً بالباقة ما لم تُذكر سرعة الباقة. صفها كقياس حالي فقط، واطلب سرعة الباقة عند الحاجة.
4. ميّز دائماً بين: «سبب مرجّح»، و«احتمال يحتاج تحققاً»، و«بيانات غير كافية»؛ ولا تقدّم حكماً قطعياً عند نقص القياسات.
5. لا تطلب أو تعرض كلمات مرور أو مفاتيح API أو بيانات عملاء. لا تقترح تعطيل جدار الحماية أو NAT أو تحديث RouterOS أو تشغيل أوامر تغيّر الإعدادات قبل إنشاء نسخة احتياطية وموافقة مسؤول الشبكة.
6. اجعل الخطوات آمنة، مرتبة من الأقل تأثيراً إلى الأعلى، وقابلة للتنفيذ. عند الحاجة إلى فحص RouterOS، اذكر اسم القسم أو المعلومة المطلوبة بدلاً من افتراض أوامر أو قيم غير موجودة.
7. لا تكرر نفس الإجراء، ولا تتجاوز خمس خطوات رئيسية، ولا تُدرج نصائح عامة غير مرتبطة بنتائج القياس.

أخرج النتيجة بهذا التنسيق حصراً:
## ملخص الحالة
جملتان كحد أقصى تشرحان أثر المشكلة على المستخدم ودرجة الأولوية: حرج، مرتفع، متوسط، أو منخفض.

## الأدلة المرصودة
جدول Markdown بالأعمدة: الفحص | النتيجة | ماذا تعني | درجة الثقة. اذكر القياسات الرقمية كما وردت.

## التشخيص المرجّح
اذكر سبباً مرجحاً واحداً فقط، ثم احتمالات بديلة مرتبة عند اللزوم، مع توضيح ما الذي يمنع الجزم.

## خطة العمل الآمنة
قائمة مرقمة من 3 إلى 5 خطوات، تبدأ بالتحقق غير المؤثر ثم العزل، وتوضح نتيجة التحقق المتوقعة من كل خطوة.

## بيانات مطلوبة لاستكمال التشخيص
اكتب «لا شيء» إن كانت البيانات كافية؛ وإلا اطلب أقل قدر ممكن من البيانات غير الحساسة، مثل سرعة الباقة، فقد الحزم، حالة واجهة WAN، أو سجل خطأ مختصر بعد إخفاء العناوين العامة والبيانات الشخصية.

## تنبيه تشغيلي
سطر واحد فقط يوضح أن نتائج اختبار السرعة والكمون لحظية ومن الجهاز الحالي.

تقرير القياس (JSON):
$diagnosisData''';
  }
}
