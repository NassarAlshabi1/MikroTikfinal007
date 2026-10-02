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
| 10 | **تكامل Telegram** | `lib/services/telegram_client.dart` (Bot API) + `telegram_report_service.dart` + صفحة إعدادات | SendMessage / getMe |
| 11 | **تقارير المبيعات وحالة الشبكة عبر Telegram** | `TelegramReportService.buildReport` (مبيعات اليوم + CPU/ذاكرة/إصدار + عدد المتصلين) | — |
| 12 | **درجة حرارة الراوتر والحساسات** | `lib/api/router_monitor_api.dart` → `getHealth()` + تبويب الموارد | `/system/health/print` |
| 13 | **متابعة المنافذ Ports/Interfaces** | `RouterMonitorApi.getInterfaces()` | `/interface/print` |
| 14 | **مراقبة حركة البيانات لكل منفذ** | `getInterfaceTraffic()` + تحديث كل 6 ثوانٍ | `/interface/monitor-traffic` |
| 15 | **تشفير بيانات دخول الراوترات** | `lib/services/secure_store.dart` (AES-256-CBC بمفتاح على الجهاز) + ترقية تلقائية للبيانات القديمة | — |
| 16 | **إصلاح ثغرة SQL** | `lib/api/database_api.dart` → تهريب علامة الاقتباس في `quoteValue` | — |
| 17 | **التحقق الآلي من الكود (CI)** | `.github/workflows/flutter-ci.yml` → `flutter analyze` + بناء APK اختياري | GitHub Actions |

**حالة التحقق الآلي:** ✅ `flutter analyze` = **صفر أخطاء** (17 تحذيرًا متبقية كلها في الكود المستورد القديم: دوال غير مستخدمة/كود ميت، وهي غير مُفشِلة).

---

## ✅ ميزات كانت منفّذة أصلًا (قلب النظام)

إدارة User Manager (v6/v7) · إنشاء/تعديل/حذف الكروت · إدارة الباقات وقيودها · **توليد آلاف الكروت** ومزامنتها مع الراوتر · الطباعة وتصدير PDF وقوالبها · تقرير مبيعات بفلترة تاريخ + إجمالي المبيعات · مراقبة **CPU / RAM / القرص** · إعادة تشغيل الراوتر · المتصلون (Host/Active) · تسمية وحظر وتجاوز الأجهزة عبر MAC · إدارة DNS والحجب (Layer7) · واجهة عربية RTL.

---

## ❌ ما زال غير موجود (أو جزئيًا)

| الميزة | الحالة | ملاحظات/العمل المطلوب |
| --- | --- | --- |
| **صفحات Hotspot (رفع + قوالب دخول)** | ❌ | يحتاج `/file/add` أو FTP لرفع حزمة HTML + `/ip/hotspot/set` لتغيير اسم الشبكة |
| **PPPoE / Broadband** | ❌ | يحتاج `/ppp/secret/print\|add\|set\|remove` + شاشة اشتراكات |
| **إشعارات Telegram مع إغلاق التطبيق** | 🟡 | الإرسال الدوري يعمل الآن **أثناء تشغيل التطبيق** فقط (Timer)؛ الإرسال الدائم يحتاج خدمة خلفية (Foreground Service / WorkManager) أو سكربت على الراوتر |
| **مستخدم Hotspot التقليدي** | 🟡 | النظام يدير مستخدمي User Manager؛ لا إدارة لمستخدمي `/ip/hotspot/user` |
| **تقارير زمنية بيانية للاستهلاك** | 🟡 | توجد قراءات لحظية (حرارة/منافذ/حركة) بلا رسوم بيانية تاريخية |
| **أجهزة غير متصلة (DHCP/ARP)** | 🟡 | تُعرض الأجهزة المتصلة حاليًا فقط |
| **المنافذ: تحديث فوري** | 🟡 | تحديث كل 6 ثوانٍ (polling) وليس بثًّا حقيقيًا |

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
