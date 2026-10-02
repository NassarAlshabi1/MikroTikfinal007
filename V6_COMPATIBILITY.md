<div dir="rtl">

# 🔍 تقرير التحقق الدقيق: التوافق مع RouterOS v6

**تاريخ التحقق:** 2026-10-02 · **الفرع:** `arena/01a0fa82-mikrotikfinal007`
**نطاق التحقق:** كل أوامر وحقول RouterOS المستخدمة في الكود، مقارنةً بوثائق/سكربتات MikroTik و v6 الحقيقية.

---

## 1) الفروق الجوهرية بين v6 و v7 في User Manager

| العنصر | **RouterOS v6** | **RouterOS v7** |
| --- | --- | --- |
| مسار المستخدمين | `/tool/user-manager/user` | `/user-manager/user` |
| حقل اسم المستخدم | **`username`** (لا يوجد `name`) | **`name`** |
| الباقة على المستخدم | **`actual-profile`** (اسم الباقة نصًّا) | `profile` عبر `user-profile` |
| المالك | **`customer`** | **`group`** |
| مدة الاستهلاك | **`uptime-used`** ✅ | غير مضمون |
| بيانات الاستهلاك | `download-used`, `upload-used` ✅ | جلسات |
| الحد الزمني | ❌ **لا يوجد `limit-uptime` على المستخدم** — يُقرأ من القيد (limitation) المرتبط بالباقة | ضمن `profile`/`limitation` |
| مسار القيود | `/tool/user-manager/profile/limitation` | `/user-manager/limitation` |
| ربط القيد بالباقة | `/tool/user-manager/profile/profile-limitation` | `/user-manager/profile-limitation` |
| جلسات | `/tool/user-manager/session` | `/user-manager/session` |
| باقات المستخدم | ❌ غير موجود | `/user-manager/user-profile` (`state=used`) |
| **إشارة انتهاء الاشتراك** | **الباقة تُزال من المستخدم** → `[find where !actual-profile and uptime-used>0s]` | `state=used` في `user-profile` |
| الحذف عبر API | `=numbers=` بقائمة `.id` **أو** `=.id=` ✅ | نفس الطريقتين ✅ |

**المصادر:** مخرجات `/tool user-manager user print` الحقيقية على إصدار 6.x (منتدى MikroTik)، وسكربتات MikroTik المعتمدة لحذف المنتهين على v6 (6.19 → 6.49) وعلى v7، وأمثلة API لحذف مستخدم User Manager عبر `.id`/`numbers`.

---

## 2) ما فعلته لضمان التوافق الدقيق مع v6

### 2.1 فصل الحقول لكل إصدار (كان خطرًا حقيقيًا)
v6 **لا يعرف** الحقل `name`. في السابق كانت قائمة الحقول موحّدة وتحوي `name` أولًا، فلو رفض الراوتر حقلًا غير معروف في `.proplist` لكان **كل الفحص قد فشل على v6**.
✅ الآن الحقول مفصولة: v6 يستخدم `username/actual-profile/customer/uptime-used`، وv7 يستخدم `name/group/profile`، مع **5 مستويات تنازلية** تبدأ بالأغنى وتنتهي بـ `.id` فقط.

### 2.2 إشارة v6 الأصلية للانتهاء (الباقة المُزالة)
في v6 لا يوجد `limit-uptime` على المستخدم، والشيء الذي يحدث فعلًا عند انتهاء الكرت هو **إزالة `actual-profile`**. أضفت هذه الإشارة:
```
profileCleared = (حقل actual-profile غائب أو فارغ) و (uptime-used > 0)
```
- الكرت **الجديد غير المستخدم** (uptime-used = 0s) → **لا يُحذف** ✅
- الكرت المنتهي بعد الاستهلاك → يُصنَّف «الباقة مُزالة (v6)» بشارة مميزة (بنفسجي) ✅
- في **v7** تُعطَّل هذه الإشارة تلقائيًا (لأنها خاصة بـ v6) ويُستخدم `state=used` بدلًا منها ✅

### 2.3 بديل مستويات المسارات (v6 ↔ v7)
إذا فشل كشف الإصدار (نادرًا ما يعطي 0)، أو كان الراوتر v7 ولم يُكتشف:
- الفحص يجرّب مسارات الإصدار المكتشف **أولًا**، ثم مسارات الإصدار الآخر تلقائيًا.
- يتوقف فورًا عن تجربة حقول أخرى عند خطأ `no such command` (توفيرًا للوقت).
- المسارات الناجحة تُخزَّن وتُستخدم لاحقًا في الحذف، وتُصفَّر عند تسجيل الدخول لراوتر جديد.

### 2.4 الحذف الكامل (كما في سكربتات MikroTik المعتمدة)
السكربت المعتمد على v6 يحذف المستخدم فقط، أما المعتمد على v7 فيحذف **الجلسات + باقات المستخدم + المستخدم**. الكود الآن يفعل الثلاثة معًا لكل إصدار:
1. حذف جلسات المستخدمين (`session/remove`).
2. حذف باقات المستخدم — **v7 فقط** (غير موجود في v6).
3. حذف المستخدمين: `=numbers=<ids>` بدفعات 50، وعند الفشل **تراجع للحذف الفردي `=.id=`** (المتحقَّق منه في v6).

---

## 3) جدول تحقق كل ميزة جديدة على v6

| الميزة | الأمر/الحقل | v6 | ملاحظات التوافق |
| --- | --- | --- | --- |
| **حذف المنتهين** | `/tool/user-manager/user/print` + `username,actual-profile,uptime-used,download-used,upload-used,last-seen,customer` | ✅ | مطابق لمخرجات v6 الحقيقية |
| | `/tool/user-manager/user/remove` + `numbers`/`.id` | ✅ | كلتا الطريقتين متحقَّق منها في v6 |
| | `/tool/user-manager/profile/print` (`name,name-for-users,validity,price,limitation`) | ✅ | |
| | `/tool/user-manager/profile/limitation/print` (`uptime-limit,transfer-limit`) | ✅ | |
| | `/tool/user-manager/profile/profile-limitation/print` (`profile,limitation`) | ✅ | مع بديل: القيد المباشر على الباقة |
| | `/tool/user-manager/session/print` + `remove` | ✅ | |
| | `/user-manager/*` | ❌ (v7) | تُستخدم فقط إذا كان الراوتر v7 |
| **نسخ الراوتر** | `/system/backup/save name=` | ✅ | |
| | `/export file=` | ✅ | `show-sensitive` يُرسل فقط عند الطلب (غير موجود في v6.43 وأقدم) |
| | `/system/backup/load name=` · `/import file-name=` | ✅ | |
| | `/file/print`, `/file/remove`, خدمة ويب للتنزيل, FTP للرفع | ✅ | `/file/read` بديل v7.9+، والكود يجرّبه ثم يرجع |
| **أدوات الصيانة** | `/ping address= count=` | ✅ | `seq/host/size/time/ttl` |
| | `/tool/traceroute address= count=` | ✅ | `address/loss/last/avg/status` |
| | `/tool/torch interface=` | ✅ | |
| | `/tool/fetch url= dst-path=` | ✅ | |
| | `/tool/sniffer/start|stop|print` | ✅ | `interface/file-name/memory-limit` |
| | `/log/print` (`time,topics,message`) | ✅ | |
| | `/system/resource/print`, `/system/routerboard/print` | ✅ | |
| | `/ip/firewall/connection/print` | ✅ | |
| | `/interface/print` (`rx-byte,tx-byte`) | ✅ | |
| | `/tool/graphing/print`, `/ip/neighbor/print` | ✅ | Neighbor يحتاج discovery مفعّلًا |
| | `/system/health/print` | ⚠️ | موجود في v6 على الأجهزة المادية؛ غير متاح على CHR/x86 → الكود يعرض رسالة واضحة ولا يفشل |
| | `/interface/monitor-traffic once=` | ✅ | `rx-bits-per-second/tx-bits-per-second` |
| **إعدادات IP / Firewall / Queue** | `/ip/address|dhcp-server|dhcp-server/lease|dhcp-client|arp|dns|firewall/*`, `/queue/simple|tree|type` | ✅ | كلها موجودة في v6 بنفس الأسماء |
| **الموزعون والمحاسبة** | تخزين محلي (SQLite) | ✅ | لا يعتمد على إصدار الراوتر |
| **التشفير** | AES-256 محلي | ✅ | لا يعتمد على الراوتر |

---

## 4) الاختبارات الآلية (تشغيل حقيقي على CI)

`test/expired_users_classifier_test.dart` يختبر **حمولات v6 الحقيقية** (مفاتيح بأسماء v6 ودون `name`):

| الاختبار | النتيجة |
| --- | --- |
| قيد مباشر على الباقة (v6) + `transfer-limit` | ✅ |
| ربط القيد عبر `profile-limitation` | ✅ |
| بديل `validity` عند غياب `uptime-limit` | ✅ |
| كرت استهلك `1w` كاملة ← مؤهل | ✅ |
| كرت بمدّة `1w2d3h4m5s` ضد حد `1w` ← مؤهل (النسبة > 100%) | ✅ |
| كرت بفارق **ثانية واحدة** (`6d23h59m59s`) ← غير مؤهل | ✅ |
| باقة `1GB` عبر القيد، استهلاك `30d` ضد `1w2d` ← مؤهل | ✅ |
| **v6: بلا `actual-profile` + استهلاك 7s ← «الباقة مُزالة (v6)»** | ✅ |
| **v6: `actual-profile` فارغ + استهلاك ← مؤهل** | ✅ |
| **v6: كرت جديد بلا باقة وبلا استهلاك ← لا يُحذف أبدًا** | ✅ |
| **v6: كرت له باقة وبلا استهلاك ← لا يُحذف** | ✅ |
| مدة غير مفهومة (`1h30`) ← يُستبعد | ✅ |
| حد مذكور غير مفهوم ← يُستبعد | ✅ |
| حد `0s` ← لا يُحذف أبدًا | ✅ |
| **v7: الباقة المُزالة لا تُستخدم كإشارة** ← لا حذف تلقائي | ✅ |
| **v7: `state=used` ← منتهٍ (سكربت MikroTik المعتمد)** | ✅ |
| `parseBytes`: `1KiB`, `1.5MiB`, `2GiB`, أرقام صحيحة | ✅ |

---

## 5) حدود معروفة (صراحةً)

1. **v6 بلا حزمة user-manager**: أوامر `/tool/user-manager/*` تفشل → تُعرض رسالة واضحة تطلب تفعيل الحزمة وصلاحيات `read/write/api`.
2. **`/system/health/print`**: غير موجود على CHR/x86 في v6 → تُعرض رسالة «لا يوفّر هذا الراوتر بيانات حساسات».
3/ **`/file/read`**: خاص بـ v7.9+ → على v6 يُعتمد على تنزيل الملف عبر خدمة الويب (وFTP للرفع)، والكود يعرض تنبيهًا بتفعيل الخدمة عند الحاجة.
4. **`show-sensitive` في التصدير**: غير موجود في v6.43 وأقدم؛ لا يُرسل إلا إذا طلب المستخدم ذلك صراحةً.
5. **Jumla v6 مع `-` في أسماء الحقول**: أي حقل غير معروف في `.proplist` يعالجه الكود بالتنازل للمحاولة التالية (لا يفشل الفحص).

</div>
