# تقرير مراجعة مشروع MikroTik Manager

## نطاق المراجعة

تمت مراجعة الفرع `feature/isar-migration` من مستودع `MikroTikfinal007` باعتباره تطبيق Flutter لإدارة **MikroTik RouterOS 6.49.19** عبر Native TCP API على المنفذ `8728` وإنشاء كروت Hotspot محلية. لم تُنفّذ أي تغييرات على Firewall أو Routes أو إعدادات شبكة الراوتر، ولم يتم إجراء إنشاء فعلي على جهاز إنتاج لأن بيانات الاتصال بالجهاز لم تُستخدم في هذه المراجعة.

## التشخيص الجذري

كان مسار إنشاء الكروت يستخدم أوامر User Manager التالية:

```text
/tool/user-manager/user/add
/tool/user-manager/user/create-and-activate-profile
```

وهذا لا ينشئ مستخدمي Hotspot المحليين. في RouterOS، المسار الصحيح للكروت المحلية هو `/ip/hotspot/user/add`، واسم الحقل هو `name`، بينما ربط المستخدم بالبروفايل يتم عبر `profile`. كما أن `shared-users` خاص ببروفايل Hotspot وليس وسيطاً في أمر إضافة المستخدم.[1] [2]

كذلك كان `HomeScreen` يعرّف نمط Hotspot لكنه يثبت الوضع على `userManager`، فتُجلب البروفايلات من `/tool/user-manager/profile/print` حتى عندما يكون التطبيق مخصصاً للكروت المحلية. وكانت طبقة المزامنة وبعض شاشات الإحصائيات تفترض أن كل RouterOS v6 يعني User Manager، وهو اقتران غير صحيح؛ رقم الإصدار لا يحدد نوع قاعدة المستخدمين.

## الإصلاحات المنفذة

| المجال | الإصلاح |
|---|---|
| إنشاء كرت فردي | إضافة `MikrotikCardCommands` واستخدام `/ip/hotspot/user/add` مع `=name` و`=profile` في وضع Hotspot. |
| إنشاء جماعي | نقل المسار الجماعي إلى Hotspot v6، مع ضمان uniqueness داخل الدفعة، والتحقق من العدد والطول والبروفايل وShared Users. |
| User Manager | إبقاؤه كخيار صريح فقط عبر `MikrotikServiceMode.userManager`، مع عدم خلطه بالمسار الافتراضي. |
| الوضع الافتراضي | تثبيت مسار التطبيق الرئيسي على `MikrotikServiceMode.hotspot`، وجلب البروفايلات من `/ip/hotspot/user/profile/print`. |
| Isar | حفظ الكروت التي تأكد إنشاؤها على الراوتر في Isar، مع upsert للبروفايل والكرت وتفادي تعارض فهرس username الفريد. |
| المزامنة | تحويل `SyncService` إلى Hotspot افتراضياً، مع تطبيع `name/profile` وإبقاء User Manager كـ mode منفصل. |
| الإحصائيات | تحويل الشاشات الحديثة والقديمة ولوحة النظام إلى Hotspot users/active، مع fallback صريح فقط عند الحاجة. |
| إدارة الاتصال | إضافة `MikrotikConnector.release` لمنع إعادة استخدام Socket مغلق داخل cache بعد انتهاء الشاشة أو العملية. |
| دورة العزل | إغلاق `ReceivePort` واشتراكه وقت الانتهاء أو dispose لمنع التسرب واستمرار العزل بعد مغادرة الشاشة. |
| الذكاء الاصطناعي | تغذية Prompt الخاص بـ Hotspot بقيود RouterOS 6.49.19، والتمييز بين `profile` و`actual-profile`، ومنع اقتراح User Manager للكروت المحلية. كما أضيف تحقق آمن من ردود OpenAI/Gemini الناقصة. |
| الاعتمادات | رفع `dartssh2` من `2.9.5` إلى `2.22.5` لحل فشل الترجمة مع Dart 3.13. |
| الاختبارات | إضافة اختبارات مباشرة لباني أوامر Hotspot، بما في ذلك التأكد من غياب `user-manager` و`shared-users` و`customer` من أمر Hotspot. |

## بنية أمر Hotspot المعتمدة

في الوضع الافتراضي أصبح الأمر الناتج من التطبيق مماثلاً للنمط التالي:

```text
/ip/hotspot/user/add
=name=100001
=password=100001
=profile=default
```

وعند نمط `username_only` لا يُرسل حقل password فارغاً. أما `shared-users` فيُقرأ من بروفايل Hotspot الموجود على الراوتر، ولا يُرسل إلى `/ip/hotspot/user/add`.

## نتائج التحقق

| الفحص | النتيجة |
|---|---:|
| `flutter analyze --no-fatal-infos` | ناجح — `No issues found!` |
| مجموعة الاختبارات المستهدفة بعد تحديث `dartssh2` | ناجحة بالكامل |
| `flutter test` كاملة | ناجحة — `338` اختباراً |
| `dart format` للملفات المعدلة | ناجح |
| `git diff --check` | ناجح |
| اختبار اتصال فعلي بجهاز RouterOS 6.49.19 | لم يُنفذ؛ يلزم جهاز اختبار أو بيانات اتصال مصرح بها |

## ملاحظات تشغيلية مهمة

> يجب أن يكون Hotspot مهيأً مسبقاً وأن يكون اسم البروفايل المرسل من التطبيق موجوداً فعلياً في `/ip/hotspot/user/profile`.

إذا لم تظهر البروفايلات، فالسبب المتوقع هو عدم تهيئة Hotspot أو عدم صلاحية حساب API لقراءة `/ip/hotspot/user/profile`. كما يجب أن تكون خدمة API مفعلة على الراوتر، وأن تكون صلاحيات الحساب كافية للقراءة والإضافة.[1]

الاختبار المحلي لا يثبت نجاح الاتصال بجهاز حقيقي ولا يثبت أن إعدادات Hotspot مثل `login-by` أو `rate-limit` مناسبة لشبكة بعينها. لذلك يلزم اختبار قبول على نسخة احتياطية أو جهاز تجريبي قبل تشغيل إنشاء دفعات كبيرة في الإنتاج.

## المراجع

[1]: https://help.mikrotik.com/docs/spaces/ROS/pages/47579160/API "MikroTik RouterOS API Documentation"

[2]: https://help.mikrotik.com/docs/spaces/ROS/pages/56459266/HotSpot+-+Captive+portal "MikroTik HotSpot - Captive portal Documentation"

[3]: https://pub.dev/documentation/router_os_client/latest/ "router_os_client Dart API Documentation"

## تحديث الثيم الداكن

بناءً على مراجعة الاستخدام الميداني، تم تعتيم الخلفيات الأساسية مع الحفاظ على فصل بصري بين مستويات الواجهة. أصبحت الخلفية الأساسية `#070B14`، والسطح العام `#0C1322`، والحقول والقوائم `#141D30`، والبطاقات `#0F1728`، مع حدود داكنة واضحة `#2A3A55`. كما تم رفع وضوح النص الثانوي والـ placeholder دون استخدام أبيض صارخ.

تم جعل `ThemeMode.dark` هو الوضع الافتراضي للتثبيتات الجديدة، مع استمرار احترام تفضيل المستخدم المحفوظ وإتاحة التبديل إلى الوضع الفاتح. وتم توحيد إعدادات `InputDecorationTheme` و`DropdownMenuTheme` و`PopupMenuTheme` و`DialogTheme` و`BottomSheetTheme` و`ProgressIndicatorTheme` على لوحة الألوان الداكنة. جميع النصوص العامة تعتمد TextTheme بخط `Tajawal`، مع الحفاظ على خط AppBar العربي.

أضيفت اختبارات ثيم تتحقق من لون الخلفية والسطح والبطاقات والحقول والقوائم والحوار وbottom sheet وخط Tajawal، وأصبح `flutter analyze` خالياً من الملاحظات، كما نجحت مجموعة الاختبارات الكاملة.

## ملاحظة بناء Web

نجح `flutter analyze` وجميع اختبارات Flutter، لكن `flutter build web --release` لا يكتمل بسبب ملفات Isar المولدة التي تحتوي على معرّفات 64-bit لا يمكن تمثيلها بدقة في JavaScript. هذا قيد معروف لمسار Web في البنية الحالية وليس خطأً في ألوان الثيم أو مكونات Material. التطبيق يستهدف Android/iOS/سطح المكتب مع Isar native؛ وإذا كان Web مطلوباً لاحقاً فيلزم فصل طبقة التخزين أو إضافة backend/web repository بديل بدلاً من استخدام Isar native مباشرة.
