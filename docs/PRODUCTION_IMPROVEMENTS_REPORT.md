# تقرير التحسينات الإنتاجية لتطبيق MikroTik

## الملخص التنفيذي

تم تنفيذ مجموعة التحسينات الإنتاجية المقترحة لمسار إنشاء كروت Hotspot الجماعية، مع الحفاظ على RouterOS v6.49.19 وعلى أوامر Hotspot المحلية فقط. أصبحت العملية ممثلة كسجل Job مستقل في Isar، ويمكن استئنافها بعد إغلاق التطبيق أو انقطاع الاتصال، وإلغاؤها من الواجهة، وعرض تاريخها، مع منع تشغيل دفعتين متزامنتين داخل التطبيق.

تم كذلك فصل التفاعل مع RouterOS في Gateway قابل للمحاكاة، وإضافة تحقق قرائي بعد الإضافة عبر `/ip/hotspot/user/print`، مع إعادة محاولة محدودة لقراءات الشبكة المؤقتة فقط. لا توجد في هذه التغييرات أوامر Firewall أو Routes أو NAT أو تعديل لإعدادات الشبكة الحساسة.

## التحسينات المنفذة

| المجال | التنفيذ والنتيجة |
|---|---|
| إدارة الدفعة | إضافة `CardGenerationJob` في Isar مع حالات `preparing`, `ready`, `running`, `partial`, `completed`, `failed`, و`cancelled`. |
| الاستئناف | حفظ خطة الأسماء، مع تخزين أسماء المستخدمين فقط داخل Job وعدم تكرار كلمات المرور في `plannedUsersJson`. كلمات المرور تُستعاد من كروت `pending` المرتبطة بـ `generationJobId`. |
| التزامن | إضافة `GenerationLockToken` وقفل محلي يمنع تشغيل عمليتي توليد متوازيتين أو ضغط زر الإنشاء مرتين. القفل idempotent ويمكن تحريره بأمان. |
| الإلغاء | زر إلغاء يقتل Isolate، يضع Job بحالة `cancelled`، ويحذف حجوزات `pending` الخاصة بالدفعة فقط. |
| الفشل الجزئي | الكروت التي أكدها RouterOS تثبت `active`، والكروت غير المؤكدة تبقى `pending` وتظهر كعملية قابلة للاستئناف بدلاً من حذفها عشوائياً. |
| الربط المحلي | إضافة `generationJobId` إلى `CardCollection` لعزل الحجز والتثبيت والتنظيف بين الدفعات. |
| RouterOS Gateway | إضافة `RouterOsCardGateway` وواجهة `RouterOsTalker`، ما يسمح بمحاكاة الإضافة والتحقق والانقطاع في الاختبارات دون راوتر حقيقي. |
| التحقق بعد الإنشاء | بعد إضافة الكروت، ينفذ التطبيق قراءة `print` لكل اسم ويتحقق من وجوده فعلياً قبل إعلان النجاح. تتم معالجة النتيجة الجزئية بدقة. |
| إعادة المحاولة | إعادة المحاولة ثلاث مرات بانتظار تدريجي لقراءات التحقق عند `SocketException` أو `TimeoutException` أو أخطاء الاتصال. لا يعاد تنفيذ أمر `add` تلقائياً لتجنب إنشاء نسخة مكررة عند وجود استجابة غامضة. |
| سجل العمليات | إضافة `CardGenerationJobsScreen` لعرض البروفايل، الحالة العربية، عدد المطلوب والمحجوز والمؤكد والفاشل، آخر تحديث، ورسالة الخطأ. |
| PDF | إضافة معاينة PDF نهائية باستخدام `Printing.layoutPdf` لنفس bytes التي تستخدمها المشاركة والحفظ، إلى جانب المعاينة المحلية HTML السابقة. |
| الأمان | عنوان الراوتر يُحفظ في Job للتشخيص فقط؛ لا تُحفظ كلمات مرور اتصال MikroTik داخل Job، ولا توجد سجلات جديدة تطبع الأسرار. |

## دورة Job الجديدة

تبدأ العملية بإنشاء Job بحالة `preparing` وقفل التزامن. بعد توليد الأسماء في Isolate، تُحجز الكروت محلياً في Isar بحالة `pending` وترتبط بالـ Job. تُحفظ خطة الأسماء، ثم ينتقل Job إلى `ready` وتُرسل الموافقة إلى Isolate.

بعد الاتصال، ينتقل Job إلى `running`. كل تقدم يحدّث `nextIndex` و`lastUsername`، بينما يرسل RouterOS Gateway أوامر الإضافة المتسلسلة ثم يتحقق من كل مستخدم بقراءة آمنة. عند اكتمال التحقق تثبت الكروت `active` وينتقل Job إلى `completed`. عند انقطاع الاتصال أو تحقق جزئي تبقى الكروت غير المؤكدة `pending` وينتقل Job إلى `partial`، ثم يمكن استئنافها من البطاقة الظاهرة في BulkAdd.

إذا أغلق المستخدم الشاشة أو التطبيق أثناء العملية، يبقى Job وخطة الأسماء والحجز المحلي في Isar. عند فتح BulkAdd تُنظف الحجوزات القديمة، وتُحمّل Jobs القابلة للاستئناف. يستخدم الاستئناف الكروت `pending` المرتبطة بالـ Job فقط، ولا يولد أسماء جديدة ولا يعيد حجز الأسماء.

## اختبارات التحقق

| الفحص | النتيجة |
|---|---:|
| `flutter analyze --no-fatal-infos` | ناجح دون مشاكل |
| اختبارات Job وIsar والقفل والاستئناف | ناجحة |
| اختبارات عزل generationJobId في CardPersistence | ناجحة |
| اختبارات RouterOS Gateway الوهمية | ناجحة، وتشمل الإضافة والتحقق والفشل الجزئي وإعادة المحاولة |
| اختبارات BulkAdd الحالية | ناجحة |
| اختبارات PDF والمعاينة المحلية | ناجحة |
| مجموعة Flutter الكاملة | **364 اختباراً ناجحاً** |
| `git diff --check` | ناجح قبل الحفظ |

## الملفات الرئيسية

| الملف | المسؤولية |
|---|---|
| [`lib/database/isar/card_generation_job.dart`](../lib/database/isar/card_generation_job.dart) | نموذج Job وحالات دورة الحياة. |
| [`lib/services/card_generation_job_service.dart`](../lib/services/card_generation_job_service.dart) | إنشاء وتحديث واستئناف وإلغاء وتنظيف Jobs وقفل التزامن. |
| [`lib/services/router_os_card_gateway.dart`](../lib/services/router_os_card_gateway.dart) | Gateway إضافة والتحقق من كروت RouterOS وقابلية المحاكاة. |
| [`lib/services/card_persistence_service.dart`](../lib/services/card_persistence_service.dart) | حجز وتثبيت وتنظيف الكروت مع generationJobId. |
| [`lib/bulk_add_isolate.dart`](../lib/bulk_add_isolate.dart) | التوليد والإرسال والتحقق وإرجاع النتائج الجزئية. |
| [`lib/bulk_add_screen.dart`](../lib/bulk_add_screen.dart) | القفل والإلغاء والاستئناف وسجل العمليات وواجهة التقدم. |
| [`lib/card_generation_jobs_screen.dart`](../lib/card_generation_jobs_screen.dart) | عرض تاريخ دفعات التوليد وحالاتها. |
| [`lib/pdf_generator.dart`](../lib/pdf_generator.dart) | معاينة PDF النهائية والتصدير بخط Tajawal وRTL. |
| [`test/features/card_generation_job_service_test.dart`](../test/features/card_generation_job_service_test.dart) | اختبارات Job والقفل والحالات. |
| [`test/features/router_os_card_gateway_test.dart`](../test/features/router_os_card_gateway_test.dart) | اختبارات Mock لمسار RouterOS. |

## الحدود المقصودة

التحقق بعد الإنشاء يستخدم أوامر قراءة فقط ولا يغير أي إعداد على الراوتر. تم إبقاء الإرسال متسلسلاً لأن RouterOS v6 على المنفذ 8728 يحتاج سلوكاً محافظاً، ولأن إعادة محاولة أمر الإضافة بعد timeout قد تنشئ كرتاً مكرراً إذا كان الراوتر قد نفذ الأمر ولم تصل الاستجابة.

التحقق الفعلي على جهاز MikroTik يحتاج اختبار قبول ميداني بعنوان الجهاز وبيانات اعتماد صحيحة؛ الاختبارات الآلية تستخدم Gateway وهمياً ولا تتصل براوتر خارجي. كما أن القفل الحالي على مستوى عملية التطبيق، وهو مناسب لمنع التزامن داخل التطبيق نفسه، بينما منع التزامن بين أجهزة مختلفة يحتاج قيداً أو آلية تنسيق على الراوتر.

## المراجع الداخلية

[1]: ../lib/database/isar/card_generation_job.dart "نموذج CardGenerationJob"

[2]: ../lib/services/card_generation_job_service.dart "خدمة دورة حياة Job"

[3]: ../lib/services/router_os_card_gateway.dart "Gateway RouterOS قابل للمحاكاة"

[4]: ../lib/bulk_add_screen.dart "واجهة BulkAdd والاستئناف والإلغاء"
