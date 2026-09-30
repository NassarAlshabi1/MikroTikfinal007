# بنية تطبيق MikroTik Manager

## الهدف

تقسيم التطبيق إلى ميزات مستقلة بدل ربط الشاشات والخدمات بملف `main.dart`، مع إبقاء
سلوك النسخة الحالية متوافقاً أثناء الانتقال التدريجي.

## الطبقات

```text
lib/
├── main.dart                         # bootstrap + root MaterialApp فقط
├── core/
│   ├── app_dependencies.dart         # تهيئة واعتماديات البنية التحتية
│   ├── app_messenger.dart            # قناة رسائل الخدمات الخلفية
│   ├── app_constants.dart
│   └── result.dart
├── features/
│   ├── auth/presentation/            # الدخول واكتشاف الراوتر
│   └── dashboard/presentation/       # لوحة الخدمات والتنقل
├── database/                         # Isar collections, DAOs, migrations
├── services/                         # تكاملات البنية التحتية
├── providers/                        # حالة التطبيق
├── theme/                            # design system
└── widgets/                          # مكونات مشتركة فقط
```

كل ميزة جديدة ينبغي أن تتبع عند الحاجة:

```text
features/<feature>/
├── domain/          # entities + repository contracts + use cases
├── data/            # gateways + DTOs + repository implementations
└── presentation/    # screens + controllers/providers + widgets
```

## قواعد الاعتماد

1. `main.dart` يهيئ التطبيق ولا يحتوي منطق MikroTik أو تخزيناً أو HTTP.
2. لا يجوز لأي شاشة أو خدمة استيراد `main.dart`.
3. `presentation` تعتمد على عقود `domain`، ولا تتصل بـ RouterOS أو Isar مباشرة في الكود الجديد.
4. `data` تنفذ عقود `domain`، ولا تستورد شاشات أو Widgets.
5. الأسرار تمر حصراً عبر `SecureCredentialsStorage` ولا تسجل في logs.
6. الأوامر الخطرة يجب أن تمر بخدمة صلاحيات/تأكيد قابلة للاختبار.
7. يوضع المشترك الحقيقي فقط في `core` أو `widgets`؛ ما يخص ميزة واحدة يبقى داخلها.

## حالة إعادة الهيكلة

- أصبح ملف الدخول library مستقلة تحت `features/auth/presentation`.
- أصبحت لوحة التحكم library مستقلة تحت `features/dashboard/presentation`.
- تقلص `main.dart` إلى bootstrap وإعداد حاويات الحالة والثيم فقط.
- نُقلت حركة الصفحات المشتركة إلى `core/navigation` ومؤشر التحميل إلى `widgets`.
- نُقلت ملكية Isar إلى `core/app_dependencies.dart`.
- فُصل `ScaffoldMessenger` العام عن نقطة الدخول، وأزيلت imports العكسية إلى `main.dart`.
- فُك الارتباط الدائري بين الدخول ولوحة التحكم عبر مسار تسجيل الخروج الجذري.
- أضيفت شاشة إعداد Telegram المفقودة مع تخزين آمن للرمز.
- فُصلت المصادقة إلى `domain/data/presentation`: نماذج بيانات، validator، عقد repository وتنفيذ للبنية التحتية.
- لم تعد شاشة الدخول تتعامل مباشرة مع SharedPreferences أو secure storage أو إنشاء اتصال RouterOS.
- أصبح تسجيل الخروج يغلق الاتصال المشترك ويمسح بيانات الجلسة غير المراد تذكرها.
- أصبحت مستودعات المصادقة قابلة للحقن في شاشتي الدخول ولوحة التحكم للاختبار والاستبدال.
- أزيل مسار cloud قديم غير قابل للبناء من تحليل السجلات بعد التحقق من غياب تنفيذه وحزمته من كامل تاريخ المستودع؛ بقي تحليل AI المدعوم فقط.
- فُصلت قراءة حالة لوحة التحكم والكاش وحالة الربط وفئات User Manager في `DashboardRepository` قابل للحقن.
- استُبدلت خريطة حالة الراوتر الديناميكية بنموذج `DashboardStatus` typed لمنع أخطاء المفاتيح والتحويل وقت التشغيل.
- أصبح تحميل الكاش يسبق التحديث الشبكي بشكل حتمي، لمنع الكاش القديم من الكتابة فوق نتيجة حديثة بسبب سباق async.
- أصبحت شبكة الخدمات responsive من عمودين إلى ستة أعمدة، مع بطاقات وأيقونات دلالية موحدة ودعم Semantics.
- أضيف تحليل موارد واضح (`DashboardHealth` + مؤشر استقرار موزون) يعرض الحالة الطبيعية والتحذير والضغط الحرج دون ادعاء تنبؤات غير متاحة من البيانات.

## خطوات الانتقال التالية

1. نقل ميزات cards وPDF وdiagnostics وnetwork كل واحدة إلى مجلد feature.
2. نقل بناء قائمة خدمات لوحة التحكم إلى registry مستقل لتقليل اقتران الشاشة بكل الميزات.
3. توحيد Provider وRiverpod على Riverpod لتجنب وجود حاويتَي حالة.
4. حقن RouterOS gateway وDAOs بدلاً من singletons، مع إبقاء adapters للتوافق.
5. تقسيم الشاشات الأكبر إلى controller + widgets صغيرة، وإضافة اختبارات controller.
6. إزالة الشيفرات المولدة من مراجعات الحجم وتوليدها حصراً عبر `build_runner`.

هذه الخطوات يجب تنفيذها على دفعات صغيرة مع تشغيل `flutter analyze` والاختبارات بعد كل دفعة؛
إعادة كتابة جميع الميزات دفعة واحدة ترفع مخاطر تعطيل إدارة الراوتر وبيانات المستخدمين.
