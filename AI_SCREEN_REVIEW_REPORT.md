# تقرير مراجعة وإصلاح شاشة الذكاء الاصطناعي (AI)

**المشروع:** تطبيق إدارة شبكات MikroTik (Flutter + Riverpod)
**النطاق:** مجلد `lib/` مع تركيز على وحدة `lib/ai/` وشاشة `lib/ai_diagnostics_screen.dart`
**التاريخ:** 2026-07-08

---

## 1. ملخص تنفيذي

تمت مراجعة وحدة الذكاء الاصطناعي بالكامل من منظور هندسي محترف. الوحدة مبنية بشكل جيد
(فصل واضح للطبقات، تخزين آمن لمفتاح API، تصنيف خطورة الأوامر، واجهة عربية RTL، وتحسينات
أداء مثل `RepaintBoundary` و`cacheExtent`). لكن وُجدت **أربع علل وظيفية حقيقية** كانت تؤثر
على عمل الشاشة، بالإضافة إلى **مشكلة أداء**. تم إصلاحها جميعاً.

| # | الخطورة | الوصف | الحالة |
|---|---------|-------|--------|
| 1 | 🔴 عالية | مخرجات SSH كانت `"Instance of 'SSHSession'"` بدل النص الفعلي | ✅ أُصلحت |
| 2 | 🔴 عالية | تنفيذ الأوامر عبر RouterOS API معطّل (تقسيم المسار بمسافات) | ✅ أُصلح |
| 3 | 🟠 متوسطة | حلقة إعادة بناء مستمرة في `build()` تستنزف الأداء/البطارية | ✅ أُصلحت |
| 4 | 🟡 منخفضة | عدم وجود `==`/`hashCode` على `AiSettings` → إعادة بناء زائدة | ✅ أُصلح |
| 5 | 🟡 منخفضة | غموض أسبقية العوامل في `classifyRisk` | ✅ حُسِّن |

---

## 2. العلل التي تم إصلاحها

### 2.1 🔴 مخرجات SSH خاطئة (`.toString()` على `SSHSession`)

**الملفات:** `lib/ai/mikrotik_data_collector.dart`، `lib/ai/command_executor.dart`

كان الكود يستدعي:
```dart
final result = await client.execute(command);
return result.toString(); // ← "Instance of 'SSHSession'"
```
في `dartssh2 2.11.0` تُرجع `SSHClient.execute()` كائن `SSHSession`، واستدعاء `.toString()`
عليه يُنتج نصاً وصفياً وليس مخرجات الأمر. النتيجة: **كل جمع بيانات وتنفيذ أوامر عبر SSH
كان يُرسل نصاً عديم الفائدة إلى الـ AI**.

**الإصلاح:** استخدام `client.run()` الذي يُرجع `Uint8List` للمخرجات الفعلية ثم فك ترميزها:
```dart
final result = await client.run(command);
return utf8.decode(result, allowMalformed: true).trim();
```

### 2.2 🔴 تنفيذ الأوامر عبر RouterOS API معطّل

**الملف:** `lib/ai/command_executor.dart`

كان الأمر يُقسَّم بالمسافات: `"/interface print"` → `['/interface', 'print']`،
بينما يتطلب RouterOS API المسار ككلمة واحدة بشرطات مائلة `'/interface/print'`
(كما يفعل `MikrotikDataCollector` نفسه فعلياً). النتيجة: **زر "تنفيذ" لا يعمل تقريباً
لأي أمر عبر الـ API.**

**الإصلاح:** إضافة محوّل `_toApiSentence()` يدمج مكوّنات المسار والفعل بشرطة مائلة،
ويُمرّر وسائط `key=value` مسبوقة بـ `=`:
```
"/ip dns set servers=8.8.8.8" → ["/ip/dns/set", "=servers=8.8.8.8"]
```

### 2.3 🟠 حلقة إعادة بناء مستمرة في `build()`

**الملف:** `lib/ai_diagnostics_screen.dart`

كان `build()` يحتوي على تأثير جانبي:
```dart
settingsAsync.whenData((settings) {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    ref.read(diagnosticsProvider.notifier).updateSettings(settings);
  });
});
```
بما أن `AiSettings` لم يكن يملك `==`، كان `updateSettings` يُنشئ حالة جديدة في كل مرة
→ إعادة بناء → callback جديد → `updateSettings` → ... **حلقة تعمل كل إطار** طوال بقاء
الشاشة مفتوحة.

**الإصلاح:** نقل المزامنة إلى `ref.listen` (تُطلَق فقط عند تغيّر الإعدادات فعلياً)
مع حماية `updateSettings` بمقارنة `==`.

### 2.4 🟡 غياب `==`/`hashCode` على `AiSettings`

**الملف:** `lib/ai/diagnostics_models.dart` — أُضيفت مقارنة بنيوية كاملة، مما يمنع
إعادة البناء الزائدة ويجعل حماية `updateSettings` فعّالة.

### 2.5 🟡 وضوح `classifyRisk`

**الملف:** `lib/ai/command_executor.dart` — أُضيفت أقواس صريحة حول شروط `&&` الممزوجة
مع `||` لمنع الأخطاء المستقبلية (السلوك كان صحيحاً لكن هشّاً).

---

## 3. اقتراحات وتحسينات مستقبلية (لم تُنفّذ — للنقاش)

### 3.1 معماريّة الحالة (State)
- يوجد **ثلاثة مصادر للحقيقة** للإعدادات: `aiSettingsProvider` (FutureProvider) +
  `aiSettingsNotifierProvider` + `diagnosticsProvider.settings`. يُفضَّل توحيدها في
  `Notifier` واحد، وأن يقرأ `diagnosticsProvider` منه مباشرةً عبر `ref.watch` بدل
  المزامنة اليدوية.
- الترقية إلى `Notifier`/`AsyncNotifier` (Riverpod 2) بدل `StateNotifier` القديم.

### 3.2 الأمان
- **كلمة مرور MikroTik** تُخزَّن في `SharedPreferences` كنص صريح، بينما مفتاح الـ AI
  فقط يُخزَّن في `flutter_secure_storage`. يُنصح بنقل بيانات الاعتماد كلها إلى التخزين الآمن.
- `_extractCommands` قد يلتقط نصوصاً ليست أوامر؛ يُفضَّل قائمة سماح لبادئات المسارات
  المعروفة قبل عرض زر "تنفيذ".
- إخفاء رسائل الاستثناء الخام عن المستخدم (قد تسرّب تفاصيل)، مع رسائل ودّية.

### 3.3 موثوقية التنفيذ
- الأوامر ذات **الوسائط الموضعية** (مثل تحديد اسم واجهة بدون `key=`) أدق عبر SSH؛
  صيغة RouterOS API مناسبة أساساً لأوامر القراءة والإعداد بالمفاتيح.
- أوامر SSH يُفضَّل أن تبدأ بـ `/` لضمان التنفيذ غير التفاعلي في RouterOS.

### 3.4 الشبكة والأداء
- إنشاء `Dio()` جديد لكل طلب — لا إعادة استخدام للاتصال. يوجد `perf/dio_cache_service.dart`
  يمكن الاستفادة منه.
- لا يوجد **إلغاء** للطلب الجاري ولا **إعادة محاولة/backoff** عند فشل الشبكة.
- إضافة `timeout` أوضح ومعالجة أكواد HTTP (401/429) برسائل مخصّصة.

### 3.5 النماذج (Models)
- قوائم النماذج (`gpt-4o`, `gemini-1.5-*`) قد تكون قديمة؛ يُنصح بمراجعتها دورياً.

### 3.6 الواجهة (UI/UX)
- ألوان ثابتة مثل `Colors.white70` تفترض الوضع الداكن فقط — لن تتكيّف مع الثيم الفاتح.
  يُفضَّل الاعتماد على `Theme.of(context).colorScheme`.
- عرض تكلفة/عدد الـ tokens التقديري قبل الإرسال.

### 3.7 الاختبارات
- لا توجد اختبارات وحدة لوحدة `ai/`. مرشّحات ممتازة للاختبار: `_toApiSentence`،
  `_extractCommands`، `classifyRisk`، و`AiSettingsService` (serialize/deserialize).

---

## 4. الملفات المعدّلة

| الملف | التغيير |
|-------|---------|
| `lib/ai_diagnostics_screen.dart` | إزالة التأثير الجانبي من `build()` واستخدام `ref.listen` |
| `lib/ai/diagnostics_provider.dart` | حماية `updateSettings` بمقارنة `==` |
| `lib/ai/diagnostics_models.dart` | إضافة `==`/`hashCode` لـ `AiSettings` |
| `lib/ai/command_executor.dart` | إصلاح SSH (`run`) + محوّل `_toApiSentence` + وضوح `classifyRisk` |
| `lib/ai/mikrotik_data_collector.dart` | إصلاح جمع بيانات SSH (`run` + فك ترميز UTF-8) |

---

## 5. ملاحظة حول التحقق

بيئة المراجعة لا تحتوي على Flutter SDK، لذا اعتمدت المراجعة على تحليل ثابت يدوي دقيق
لواجهات الحزم (`dartssh2 2.11.0`, `router_os_client`) ومنطق Riverpod. يُنصح بتشغيل
`flutter analyze` و`flutter test` على بيئة مطوّر قبل الدمج للتأكيد النهائي.
