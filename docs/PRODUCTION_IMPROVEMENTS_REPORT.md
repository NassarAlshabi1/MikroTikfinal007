# تقرير التحسينات الهندسية الإنتاجية لتطبيق MikroTik

## الملخص التنفيذي

تم تنفيذ حزمة تحسينات إنتاجية مركزة لمسار إنشاء كروت Hotspot الجماعية مع الحفاظ على RouterOS v6.49.19، وعلى استخدام Hotspot المحلي فقط. أصبح منطق التوليد منفصلاً عن واجهة Flutter في خدمة typed، وأصبحت دورة العملية قابلة للتتبع والاستئناف والإلغاء، مع قفل تزامن وبصمة تمنع استئناف العملية على راوتر أو إعدادات مختلفة.

تمت إضافة فحص صلاحيات قراءة فقط قبل بدء العملية، وGateway قابل للمحاكاة لإضافة الكروت والتحقق من وجودها فعلياً على RouterOS. كما تم تقوية PDF بحدود لحجم وأبعاد صور القوالب والتحقق من أسماء الكروت قبل التصدير. لم تتم إضافة أوامر Firewall أو Routes أو NAT أو أي تعديل حساس على إعدادات الشبكة.

## التحسينات المنفذة

| المجال | التنفيذ والنتيجة |
|---|---|
| الخدمة typed | إضافة `BulkCardGenerationService` مع `BulkGenerationRequest`, `GeneratedCard`, `GenerationEvent`, و`BulkGenerationSession`، ونقل إنشاء Job والقفل وIsolate وإدارة الموارد خارج Widget. |
| إدارة الدفعة | استمرار استخدام `CardGenerationJob` في Isar مع حالات `preparing`, `ready`, `running`, `partial`, `completed`, `failed`, و`cancelled`. |
| الاستئناف الآمن | الاستئناف يقرأ كروت `pending` المرتبطة بـ`generationJobId` فقط، ولا يولد أسماء جديدة ولا يعيد حجز الأسماء. كما أصبح الاستئناف يدوياً من الواجهة. |
| بصمة Job | إضافة SHA-256 مرتبة المفاتيح تشمل عنوان الراوتر والبروفايل ونوع الخدمة وإعدادات التوليد، دون تضمين كلمات المرور. يمنع ذلك استئناف Job على إعدادات مختلفة. |
| التزامن | إضافة `GenerationLockToken` وقفل محلي idempotent يمنع تشغيل دفعتين متوازيتين أو الضغط المكرر. |
| الإلغاء | زر إلغاء يضع Job بحالة `cancelled`، يوقف جلسة التوليد، وينظف حجوزات `pending` الخاصة بالدفعة فقط. |
| الفشل الجزئي | الكروت التي أكدها RouterOS تثبت `active`، والكروت غير المؤكدة تبقى `pending` وتظهر كعملية قابلة للاستئناف. |
| RouterOS Gateway | إضافة `RouterOsCardGateway` وواجهة `RouterOsTalker` لتسهيل الفصل والمحاكاة والاختبار. |
| التحقق بعد الإنشاء | قراءة `/ip/hotspot/user/print` لكل اسم بعد الإضافة، وعدم إعلان النجاح قبل التحقق الفعلي. |
| إعادة المحاولة | إعادة محاولة محدودة لقراءات التحقق عند أخطاء الشبكة المؤقتة فقط. لا يعاد تنفيذ أمر `add` تلقائياً بعد timeout لتجنب إنشاء كرت مكرر. |
| فحص الصلاحيات | إضافة `RouterOsPermissionService` يقرأ `/user/print` و`/user/group/print` ويتأكد من `read` و`write` قبل بدء BulkAdd، دون تنفيذ أي أمر تعديل. |
| سجل العمليات | إضافة `CardGenerationJobsScreen` لعرض الحالة والعدادات وآخر تحديث ورسالة الخطأ باللغة العربية. |
| PDF | إضافة معاينة PDF نهائية باستخدام نفس bytes الخاصة بالتصدير، مع الإبقاء على المعاينة المحلية عبر المتصفح. |
| حماية الصور | رفض الصور الفارغة أو الأكبر من 12 ميغابايت أو التي تتجاوز 6000×6000 بكسل قبل الحفظ أو المعاينة أو التصدير. |
| حماية النص | رفض أسماء الكروت الفارغة أو متعددة الأسطر أو التي تتجاوز 128 محرفاً قبل إنشاء PDF. |
| الأمان | لا تُحفظ كلمات مرور اتصال MikroTik ضمن Job أو fingerprint، ولا تتم إضافة سجلات جديدة تطبع الأسرار. |

## دورة العملية الجديدة

يبدأ `BulkCardGenerationService` بفحص صلاحيات الحساب ثم ينشئ Job بحالة `preparing`، ويحسب fingerprint، ويستحوذ على قفل التزامن. بعد توليد الأسماء في Isolate تُحجز الكروت محلياً في Isar بحالة `pending` وترتبط بالـJob. تحفظ خطة الأسماء دون كلمات مرور مكررة داخل Job، ثم ينتقل Job إلى `ready` وتُرسل الموافقة إلى Isolate.

ينتقل Job إلى `running` عند بدء الإرسال. ينفذ RouterOS Gateway أوامر الإضافة المتسلسلة ثم قراءة تحقق لكل اسم. عند اكتمال التحقق تثبت الكروت `active` وينتقل Job إلى `completed`. عند انقطاع الاتصال أو تحقق جزئي تثبت الكروت المؤكدة فقط، وتبقى بقية الكروت `pending`، وينتقل Job إلى `partial` مع إمكانية الاستئناف.

عند فتح BulkAdd لاحقاً، تُنظف الحجوزات القديمة وتظهر Jobs القابلة للاستئناف. قبل الاستئناف يُقرأ عنوان الراوتر الحالي وتُقارن البصمة؛ إذا تغير الراوتر أو البروفايل أو إعدادات التوليد ترفض العملية بدلاً من إرسال كروت إلى وجهة خاطئة.

## الاختبارات والتحقق

| الفحص | النتيجة |
|---|---:|
| `flutter analyze --fatal-infos` | ناجح دون أخطاء أو معلومات |
| اختبارات Job وIsar والقفل والاستئناف | ناجحة |
| اختبارات بصمة Job وترتيب JSON | ناجحة |
| اختبارات فحص صلاحيات RouterOS القراءة فقط | ناجحة |
| اختبارات RouterOS Gateway الوهمية | ناجحة، وتشمل الإضافة والتحقق والفشل الجزئي وإعادة المحاولة |
| اختبارات عزل `generationJobId` في CardPersistence | ناجحة |
| اختبارات BulkAdd الحالية | ناجحة |
| اختبارات PDF والمعاينة المحلية وحماية القالب | ناجحة |
| مجموعة Flutter الكاملة | **368 اختباراً ناجحاً** |
| `git diff --check` | سيُعاد تشغيله قبل commit النهائي |

## الملفات الرئيسية

| الملف | المسؤولية |
|---|---|
| [`lib/services/bulk_card_generation_service.dart`](../lib/services/bulk_card_generation_service.dart) | الطلب typed، جلسة التوليد، الاستئناف، الإلغاء، وإدارة Isolate. |
| [`lib/database/isar/card_generation_job.dart`](../lib/database/isar/card_generation_job.dart) | نموذج Job والبصمة وحالات دورة الحياة. |
| [`lib/services/card_generation_job_service.dart`](../lib/services/card_generation_job_service.dart) | إنشاء وتحديث واستئناف وإلغاء وتنظيف Jobs وحساب fingerprint. |
| [`lib/services/router_os_card_gateway.dart`](../lib/services/router_os_card_gateway.dart) | إضافة والتحقق من كروت RouterOS وقابلية المحاكاة. |
| [`lib/services/router_os_permission_service.dart`](../lib/services/router_os_permission_service.dart) | فحص صلاحيات read/write من RouterOS قبل التوليد. |
| [`lib/services/card_persistence_service.dart`](../lib/services/card_persistence_service.dart) | حجز وتثبيت وتنظيف الكروت مع generationJobId. |
| [`lib/bulk_add_isolate.dart`](../lib/bulk_add_isolate.dart) | التوليد والإرسال والتحقق وإرجاع النتائج الجزئية. |
| [`lib/bulk_add_screen.dart`](../lib/bulk_add_screen.dart) | العرض، الموافقة، التقدم، الإلغاء، والاستئناف دون إدارة Isolate مباشرة. |
| [`lib/card_generation_jobs_screen.dart`](../lib/card_generation_jobs_screen.dart) | عرض تاريخ دفعات التوليد وحالاتها. |
| [`lib/pdf_generator.dart`](../lib/pdf_generator.dart) | معاينة PDF النهائية والتصدير والتحقق من الصورة والنص. |
| [`lib/models/pdf_template.dart`](../lib/models/pdf_template.dart) | حدود حجم وأبعاد الصورة والتحقق المركزي للقالب. |
| [`test/features/production_guards_test.dart`](../test/features/production_guards_test.dart) | اختبارات fingerprint وفحص صلاحيات RouterOS. |

## الحدود المقصودة

جميع أوامر فحص الصلاحيات والتحقق بعد الإنشاء قراءة فقط. الإرسال إلى RouterOS يبقى متسلسلاً ومحافظاً، لأن إعادة محاولة أمر `add` بعد timeout قد تنشئ نسخة مكررة إذا كان الراوتر قد نفذ الأمر ولم تصل الاستجابة.

الاختبارات الآلية تستخدم Gateway وهمياً ولا تتصل براوتر خارجي. يلزم اختبار قبول ميداني منفصل على RouterOS 6.49.19 داخل شبكة معزولة وبحساب محدود الصلاحيات قبل اعتماد الإصدار في بيئة إنتاجية. كما أن قفل التزامن الحالي يمنع التوازي داخل عملية التطبيق نفسها، وليس بين أجهزة مختلفة.

## المراجع الداخلية

[1]: ../lib/services/bulk_card_generation_service.dart "خدمة التوليد typed"

[2]: ../lib/database/isar/card_generation_job.dart "نموذج CardGenerationJob والبصمة"

[3]: ../lib/services/router_os_card_gateway.dart "Gateway RouterOS قابل للمحاكاة"

[4]: ../lib/services/router_os_permission_service.dart "فحص صلاحيات RouterOS"

[5]: ../lib/pdf_generator.dart "مولد PDF والتحقق من الصور والنصوص"
