<div dir="rtl">

# 📋 تقرير حالة الميزات: الكود مقابل النص التسويقي

**آخر تحديث:** 2026-10-02 · **الفرع:** `arena/01a0fa82-mikrotikfinal007`

> هذا التقرير مبني على تدقيق فعلي للكود (118 ملف Dart + `pubspec.yaml` + قاعدة SQLite)،
> ويُحدَّث بعد كل عملية تنفيذ. **لا تُعلن أي ميزة على أنها منفّذة إلا بوجود دليل في الكود.**

---

## 🆕 ما تم تنفيذه في هذه الجولة (كان ناقصًا)

| # | الميزة | الدليل في الكود | أوامر RouterOS |
| --- | --- | --- | --- |
| 1 | **نسخة احتياطية حقيقية للراوتر** | `lib/api/router_backup_api.dart` → `createBackup` | `/system/backup/save` |
| 2 | **تصدير نصي للإعدادات (‎.rsc)** | `RouterBackupApi.createExport` | `/export file=…` |
| 3 | **تنزيل النسخ إلى الهاتف** | `RouterBackupApi.downloadFile` (خدمة الويب + قراءة مُجزّأة كبديل) + `MikrotikClient.httpDownloadFile` | `/file/print` · `/file/read` |
| 4 | **استعادة الإعدادات من الراوتر** | `restoreBackupFile` / `importExportFile` | `/system/backup/load` · `/import` |
| 5 | **رفع نسخة من الهاتف إلى الراوتر** | `uploadFile` + `lib/services/ftp_client.dart` (عميل FTP كامل) | FTP STOR |
| 6 | **إدارة الموزعين ونقاط البيع** | `lib/models/distributor_model.dart` + `lib/api/distributors_api.dart` + 3 صفحات | جداول SQLite جديدة |
| 7 | **حساب كل موزع دائن/مدين** | `DistributorSummary.balance/balanceLabel` (موجب = مدين) | محسوب محليًا |
| 8 | **الأرباح وإجماليات المبيعات** | `DistributorSummary.profit` (المبيعات − التكلفة) + بطاقة الإجماليات | محسوب محليًا |
| 9 | **كشف حساب لكل موزع PDF** | `lib/services/distributor_pdf.dart` (A4 عربي + جدول الحركات) | — |
| 10 | **أدوات الصيانة والتشخيص (لوحة تحكم الميكروتيك)** | `lib/api/maintenance_api.dart` + `lib/models/maintenance_tools.dart` + `lib/views/maintenance/*` | Ping · Traceroute · Torch · Fetch · Sniffer · Log |
| 11 | **إعدادات الشبكة وجدار الحماية وقوائم Queue** | عارض عام لأي قائمة RouterOS (`tool_list_page.dart`) مع عدّادات مباشرة | `/ip/*` · `/ip/firewall/*` · `/queue/*` · `/tool/graphing` · `/ip/neighbor/print` |
| 12 | **درجة حرارة الراوتر والحساسات** | `lib/api/router_monitor_api.dart` → `getHealth()` + تبويب الموارد | `/system/health/print` |
| 13 | **متابعة المنافذ Ports/Interfaces** | `RouterMonitorApi.getInterfaces()` | `/interface/print` |
| 14 | **مراقبة حركة البيانات لكل منفذ** | `getInterfaceTraffic()` + تحديث كل 6 ثوانٍ | `/interface/monitor-traffic` |
| 15 | **تشفير بيانات دخول الراوترات** | `lib/services/secure_store.dart` (AES-256-CBC بمفتاح على الجهاز) + ترقية تلقائية للبيانات القديمة | — |
| 16 | **إصلاح ثغرة SQL** | `lib/api/database_api.dart` → تهريب علامة الاقتباس في `quoteValue` | — |
| 17 | **حذف المستخدمين المنتهين بفحص ذكي (متوافق مع v6 و v7)** | `lib/services/mikrotik_duration.dart` (محلّل مدد) + `lib/services/expired_users_classifier.dart` (منطق نقي) + `lib/api/expired_users_api.dart` + صفحة `views/cards/expired_users_page.dart` | v6: `/tool/user-manager/user/print|remove` + `profile/limitation` · v7: `/user-manager/*` + `user-profile.state=used` |
| 18 | **التحقق الآلي من الكود (CI)** | `.github/workflows/flutter-ci.yml` → `flutter analyze` + بناء APK اختياري | GitHub Actions |

**حالة التحقق الآلي:** ✅ 17 اختبارًا لمحلّل المدد (`test/mikrotik_duration_test.dart`) + 22 لتصنيف المنتهين
بحمولات v6 الحقيقية (`test/expired_users_classifier_test.dart`) + 22 لفحص الكيبل (`test/cable_diagnostics_test.dart`)
+ 25 لمنطق Hotspot (`test/hotspot_logic_test.dart`) — تُشغَّل جميعًا في CI.

**التوافق مع RouterOS v6:** موثّق بالتفصيل في [`V6_COMPATIBILITY.md`](V6_COMPATIBILITY.md) — حقول v6
(`username`/`actual-profile`/`uptime-used`/`customer` ولا يوجد `name`)، إشارة الانتهاء الأصلية `!actual-profile`
مع استهلاك، قراءة الحد من limitation/validity (لا من المستخدم)، والحذف بـ `numbers`/`.id` مع تنظيف الجلسات.
و ✅ `flutter analyze` = **صفر أخطاء** (17 تحذيرًا متبقية كلها في الكود المستورد القديم: دوال غير مستخدمة/كود ميت، وهي غير مُفشِلة).

---

## ✅ ميزات كانت منفّذة أصلًا (قلب النظام)

إدارة User Manager (v6/v7) · إنشاء/تعديل/حذف الكروت · إدارة الباقات وقيودها · **توليد آلاف الكروت** ومزامنتها مع الراوتر · الطباعة وتصدير PDF وقوالبها · تقرير مبيعات بفلترة تاريخ + إجمالي المبيعات · مراقبة **CPU / RAM / القرص** · إعادة تشغيل الراوتر · المتصلون (Host/Active) · تسمية وحظر وتجاوز الأجهزة عبر MAC · إدارة DNS والحجب (Layer7) · واجهة عربية RTL.

---

## ❌ ما زال غير موجود (أو جزئيًا)

| الميزة | الحالة | ملاحظات/العمل المطلوب |
| --- | --- | --- |
| **صفحات Hotspot (رفع + قوالب دخول)** | ✅ | صفحة «صفحة الدخول» ترفع ملفات HTML/CSS/صور عبر FTP إلى مجلد الراوتر + `/ip/hotspot/set html-directory=` + فحص وسوم الصفحة قبل الرفع |
| **PPPoE / Broadband** | ❌ | يحتاج `/ppp/secret/print\|add\|set\|remove` + شاشة اشتراكات |
| **إشعارات وتقارير تلقائية (Telegram/غيره)** | ❌ | **أُزيل تكامل Telegram بطلب المستخدم**؛ يمكن إعادته لاحقًا كخدمة خلفية عند الحاجة |
| **مستخدم Hotspot التقليدي** | ✅ | وحدة Hotspot كاملة: مستخدمون (إضافة/تعديل/حذف/تفعيل) · توليد قسائم بضغطة · الجلسات النشطة وقطعها · الباقات · الخوادم |
| **تقارير زمنية بيانية للاستهلاك** | 🟡 | توجد قراءات لحظية (حرارة/منافذ/حركة) بلا رسوم بيانية تاريخية |
| **أجهزة غير متصلة (DHCP/ARP)** | 🟡 | تُعرض الأجهزة المتصلة حاليًا فقط |
| **المنافذ: تحديث فوري** | 🟡 | تحديث كل 6 ثوانٍ (polling) وليس بثًّا حقيقيًا |
| **فحص الكيبل (cable-test)** | ✅ | صفحة كاملة: أزواج الكيبل الأربعة + السرعة الفعلية + تشخيص وتوصيات؛ لا يعمل على SFP/CHR كما هو الحال في RouterOS نفسه |

---

## 🧭 الأولويات المقترحة للجولة القادمة

1. **صفحات Hotspot** (رفع صفحات دخول وقوالب جاهزة) — الأكثر طلبًا تجاريًا.
2. **PPPoE** (إدارة اشتراكات البرودباند).
3. **خدمة خلفية** لإرسال تقارير Telegram والإشعارات والتطبيق مغلق.
4. **رسوم بيانية تاريخية** للاستهلاك والحرارة والحركة.
5. **قراءات DHCP/ARP** لعرض الأجهزة غير المتصلة وتصنيفها.

---

## 📌 ملاحظة منهجية

كل بند في جدول «تم تنفيذه» أعلاه مرتبط بملف فعلي في المستودع وبأمر RouterOS مُنفَّذ عبر
`MikrotikClient`، ويمكن التحقق منه بتشغيل `flutter analyze` (صفر أخطاء) أو ببناء APK من
`.github/workflows/flutter-ci.yml`.

</div>
