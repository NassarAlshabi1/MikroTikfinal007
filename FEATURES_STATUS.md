<div dir="rtl">

# 📋 تقرير تدقيق: هل يحتوي الكود على ميزات ميكرونت المعلنة؟

**تاريخ التدقيق:** 2026-10-02 · **الفرع:** `arena/01a0fa82-mikrotikfinal007` · **المصدر:** فرع `controller` من `zaidaburas/MikroNet`

**نطاق الفحص:** 118 ملف Dart (~19,800 سطر) + `pubspec.yaml` + قاعدة SQLite المحلية.

---

## 🎯 الخلاصة السريعة

| التصنيف | العدد | النسبة |
| --- | --- | --- |
| ✅ **منفّذة فعليًا في الكود** | 24 | 44% |
| 🟡 **منفّذة جزئيًا / بمفهوم مختلف** | 9 | 16% |
| ❌ **غير موجودة إطلاقًا** | 22 | 40% |
| **المجموع** | **55** | 100% |

> **الإجابة المباشرة:** لا، التطبيق **لا يحتوي** على كل الميزات المذكورة في النص التسويقي. الموجود فعلًا هو **قلب النظام**: إدارة User Manager (المستخدمون، الكروت، الباقات)، التوليد الجماعي، الطباعة وقوالبها، تقرير المبيعات، مراقبة CPU/RAM/القرص، التحكم بالأجهزة عبر MAC، وإدارة DNS والحجب. أما **Telegram، الموزعون والمحاسبة، صفحات الهوتسبوت، حرارة الراوتر، المنافذ، PPpoE، والنسخ الاحتياطي للراوتر فغير موجودة إطلاقًا**.

---

## ✅ 1) ميزات منفّذة فعليًا (24)

| الميزة | الدليل في الكود | الأمر على الراوتر |
| --- | --- | --- |
| إدارة User Manager (حسابات/باقات/مستخدمين) | `api/cards_api.dart` (خرائط v6/v7) + `api/profiles_api.dart` | `/tool/user-manager/*` و `/user-manager/*` |
| إنشاء مستخدم/كرت | `CardsApi.addOneCard` | `/tool/user-manager/user/add` |
| تعديل بيانات الكرت | `views/cards/cards/card_info_page.dart` (حفظ التعديلات) | `/tool/user-manager/user/set` |
| حذف كرت / حذف جماعي | `CardsApi.deleteCard` · `deleteCardsBatch` | `/tool/user-manager/user/remove` |
| إنشاء باقة (بروفايل + قيد + مجموعة سرعة) | `ProfilesApi.addOneProfile` | `/ip/hotspot/user/profile/add` + `/tool/user-manager/profile/*` |
| تعديل باقة | `ProfilesApi.profileEdit` | `.../profile/set` + `limitation/set` |
| حذف باقة (مع الروابط والقيود) | `ProfilesApi.deleteProfile` | `…/remove` ×4 |
| التحكم المباشر بالراوتر عبر API | `services/router_os_client.dart` · `services/mikrotik_client.dart` | اتصال API مباشر |
| إنشاء كرت واحد | `controllers/cards/cards/add_single_card_controller.dart` | user-manager |
| **إنشاء آلاف الكروت** | `add_batch_controller.dart` → `int count = int.parse(numOfCards.text)` ثم رفع ومزامنة مع الراوتر (`batch_cards_controller.dart`) | إضافة جماعية + مقارنة الموجود |
| طباعة/تصدير الكروت PDF | `controllers/prints/pdf_view_controller.dart` → حفظ في `/sdcard/PrintNet/الكروت` + `Printing` | — |
| تصميم قوالب خاصة للكروت | جدول `templates` في `services/database.dart` (خطوط، صفوف، أعمدة، مواضع، صورة) | — |
| إضافة صور/شعارات للقالب | `templateImage` + `image_picker` في `base_template_controller.dart` | — |
| تقرير مبيعات حسب الفترة | `ReportsApi.getPaymentsBetweenDates` (فلترة بالتاريخ) | `/tool/user-manager/payment/print` |
| إجمالي المبيعات + ملخص بالباقة | `SalesReportController.totalRevenue/totalCards/summaryByProfile` | — |
| مراقبة CPU | `HomeController.cpuPercent` (تحديث كل 10 ثوان) | `/system/resource/print` |
| مراقبة RAM | `HomeController.ramPercent` (المستخدم/الإجمالي) | `/system/resource/print` |
| مراقبة القرص والتخزين | `diskSpacePercent/diskSpaceDetails` (إضافة غير مذكورة أصلًا) | `total-hdd-space` / `free-hdd-space` |
| إعادة تشغيل الراوتر | `RouterApi.rebootSystem` | `/system/reboot` |
| الأجهزة المتصلة | `HostUsersApi.getAllHosts` + `ActiveUsersApi.getAllActive` | `/ip/hotspot/host/print` · `/ip/hotspot/active/print` |
| تسمية/حظر/تجاوز/حذف الجهاز | `SavedUsersApi` + `UsersApi` (ip-binding) | `/ip/hotspot/ip-binding/*` |
| تصنيف المستخدمين (نشط/جديدة/منتهية) | `CardsListController.cardCounts` = `{الكل, جديدة, نشطة, منتهية}` | حالة البروفايل v7: `used/running/running-active` |
| إدارة المواقع: DNS + الحجب | `SitesApi` (Layer7 + mangle + filter) | `/ip/dns/*` · `/ip/firewall/*` |
| واجهة عربية RTL | `Directionality(textDirection: rtl)` في كل الصفحات | — |

---

## 🟡 2) ميزات منفّذة جزئيًا (9)

| الميزة المعلنة | الواقع في الكود | الفجوة |
| --- | --- | --- |
| إدارة مستخدمي **Hotspot** | لا يوجد أي استدعاء لـ `/ip/hotspot/user/*` — كل الإنشاء والتعديل يمرّ عبر **User Manager** | لا إدارة لمستخدمي Hotspot التقليديين |
| معرفة غير المرتبطين بالباقات | يُستنتج من فلتر **«جديدة»** (`status == "normal"`) | لا حقل/تقارير صريحة |
| متابعة استهلاك المستخدم ومدة الاتصال | حقول `uptime-used` و`download-used` و`upload-used` في `CardModel` | حقول عرضية، لا تقارير استهلاك/رسوم بيانية تاريخية |
| قوالب طباعة **جاهزة** | يوجد إنشاء/تعديل قوالب + قيمة layout افتراضية (`getLayoutData(49)`) | لا مكتبة قوالب مصممة مسبقًا للاختيار |
| مراقبة الراوتر **لحظة بلحظة** | مؤقّت كل **10 ثوانٍ** (`Timer.periodic(Duration(seconds: 10))`) | ليس بثًّا حيًّا (polling) + لا رسوم بيانية زمنية |
| مراقبة حركة البيانات | بايتات الجلسة (`bytes-in/out`) على مستوى الكرت | لا مراقبة لكل واجهة/منفذ ولا استهلاك كلي |
| الأجهزة **غير** المتصلة | قائمة `host` تُظهر المتصلين حاليًا فقط | لا قراءة DHCP Leases/ARP لعرض غير المتصلين |
| النسخ الاحتياطي | `BackupApi` ينسخ/يستعيد **قاعدة بيانات التطبيق** (`mikrotik.db`) عبر `file_picker` | ⚠️ **ليس** نسخة للراوتر — رغم أن نص الزر يقول «حفظ نسخة من إعدادات المايكروتك» |
| حماية بيانات الاتصال والحسابات | `LoginApi.saveLoginData` يخزّن الراوترات في SQLite | ⚠️ **لا تشفير**: حزمة `encrypt` موجودة في `pubspec.yaml` لكن **لا تُستخدم في أي ملف** |

---

## ❌ 3) ميزات غير موجودة إطلاقًا (20)

### 💰 المحاسبة والموزعون (6)
| الميزة | التحقق |
| --- | --- |
| حساب الأرباح | لا وجود لكلمة `profit`/`ربح` في الكود — فقط `price` للبيع |
| إدارة نقاط البيع والموزعين | لا `dealer` ولا `distributor` ولا `POS` — يوجد فقط «customer» كثيمة على الكرت |
| حساب الموزع دائن/مدين | لا أرصدة ولا `balance`/`credit`/`debit` |
| تنظيم الحسابات بدون دفاتر | لا كيان «دفتر/فاتورة» في قاعدة البيانات المحلية (الجداول المحلية: `templates`, `batches`, `cards`, `saved_logins`) |
| تقارير مالية مفصلة | لا سجلات مالية، فقط مبيعات (`payment/print`) |
| تصدير PDF لكل موزع/نقطة بيع | لا يوجد — الـ PDF للكروت فقط |

### 🌐 صفحات الهوتسبوت (6)
لا يوجد أي استدعاء لـ `/ip/hotspot/set` أو `/file` أو رفع ملفات:

| الميزة | التحقق |
| --- | --- |
| رفع صفحات Hotspot للراوتر | ❌ (لا `/file/add` ولا FTP) |
| قوالب تسجيل دخول جاهزة | ❌ |
| تعديل اسم الشبكة | ❌ (لا `/ip/hotspot/set name`) |
| الباقات والأسعار داخل الصفحة | ❌ |
| نقاط البيع وأرقام التواصل | ❌ |
| تخصيص صفحة الهوتسبوت | ❌ |

### 📊 المراقبة المتقدمة (3)
| الميزة | ما ينقص تقنيًا |
| --- | --- |
| درجة حرارة الراوتر | يحتاج `/system/health/print` — لا يوجد |
| المنافذ Ports / Interfaces | يحتاج `/interface/print` + `/interface/monitor-traffic` — لا يوجد |
| التنبيه الذكي على الحالة | لا منطق تنبيهات/عتبات |

### 🤖 Telegram والإشعارات (4)
| الميزة | التحقق |
| --- | --- |
| ربط الشبكة مع Telegram | ❌ لا ذكر لكلمة `telegram` في أي ملف |
| تقارير مبيعات عبر Telegram | ❌ |
| تقارير شبكة/راوتر عبر Telegram | ❌ |
| إشعارات وتنبيهات فورية | ❌ لا `firebase`، لا `flutter_local_notifications`، لا `mqtt` في `pubspec.yaml` |

### 🔌 PPPoE ونسخ احتياطي الراوتر (3)
| الميزة | ما ينقص تقنيًا |
| --- | --- |
| نسخة احتياطية للراوتر | `/system/backup/save` + `/file` + تنزيل الملف — غير موجود |
| استعادة إعدادات الشبكة على الراوتر | `/system/backup/load` — غير موجود |
| **PPPoE / Broadband** | لا `ppp` ولا `pppoe` ولا `/ppp/secret` في الكود كله |

---

## ⚠️ 4) ملاحظات يجب تصحيحها في النص التسويقي

1. **«إنشاء وتعديل وحذف المستخدمين»** — يخص مستخدمي **User Manager (الكروت)**، وليس مستخدمي Hotspot التقليديين.
2. **«النسخ الاحتياطي»** — احتياطي **لبيانات التطبيق** لا لراوتر. نص الزر في `more_unit.dart` مضلّل ويجب تعديله أو تنفيذ النسخة الفعلية.
3. **«الأرباح»** — لا يوجد أي حساب للأرباح (لا تكلفة ولا هامش)، فقط إجمالي مبيعات.
4. **«إدارة اشتراكات PPPoE»** — غير موجودة نهائيًا.
5. **«حماية بيانات الاتصال»** — كلمات مرور الراوترات مخزّنة في SQLite **بدون تشفير**؛ خطوة أولى مقترحة: استخدام حزمة `encrypt` المضافة أصلًا.
6. **«الإشعارات على Telegram»** — لا وجود لأي نظام إشعارات.

---

## 🛠️ 5) خطة تنفيذ مقترحة للفجوات (عند الطلب)

| الأولوية | الميزة | العمل التقني المطلوب |
| --- | --- | --- |
| 1 | **نسخة احتياطية حقيقية للراوتر** | `/system/backup/save` + `/export` ثم تنزيل الملف وعرضه في `backup_restore_page` |
| 2 | **إدارة الموزعين والمحاسبة** | جداول SQLite (موزعون، حركات، أرصدة) + ربط `customer` من user-manager + تقارير PDF |
| 3 | **تكامل Telegram** | حزمة `http` + `Bot API`، إعدادات توكن/معرّف، مُرسِل تقارير دوري عبر Timer |
| 4 | **المراقبة المتقدمة** | `/system/health/print` (الحرارة) + `/interface/print` + `/interface/monitor-traffic` ورسوم بيانية |
| 5 | **صفحات الهوتسبوت** | رفع ملفات عبر FTP أو `/tool/fetch` + `/ip/hotspot/set` + محرّر قوالب HTML |
| 6 | **PPPoE** | `/ppp/secret/print|add|set|remove` + صفحة اشتراكات |
| 7 | **تشفير بيانات الاتصال** | تفعيل `encrypt` على `hostAddress/username/password` في `LoginApi` |

---

## 📌 ملاحظة منهجية

التدقيق مبني على **بحث نصي شامل** في كل ملفات `lib/` عن أوامر RouterOS المستخدمة فعليًا، وعن كلمات مفتاحية (`telegram`, `ppp`, `temperature`, `profit`, `dealer`, `interface`, `backup`) ونتائجها. ما لم يظهر في الأوامر أو الحقول أعلاه = غير موجود، وليس «مخفيًا في مكان آخر».

</div>
