# إصلاح إنشاء الكروت الجماعية — تحليل وحلول احترافية

## الملخص التنفيذالي

تم تشخيص السبب الجذري لبطء إنشاء الكروت الجماعية في `lib/bulk_add_isolate.dart`
وتطبيق تصحيح شامل يعتمد على الأبحاث الرسمية لمكتبة `router_os_client`
والوثائق المنصية لميكروتيك.

---

## التشخيض: الكود الأصلي (من مستودع GitHub الأصلي)

الكود الأصلي (مؤكد من `m777042661m/mikrotik_manager` on GitHub) كان يعمل
**تسلسلياً تماماً**:

```dart
client = await MikrotikConnector.connect();

for (int i = 0; i < data.count; i++) {
  // 2 round-trips لكل كرت — تسلسلي، على اتصال واحد
  await client.talk(addUserCommand);      // ← round-trip #1
  await client.talk(activateCommand);     // ← round-trip #2
  sendPort.send({'type': 'progress', ...}); // ← رسالة Progress لكل كرت!
}
```

### الأسباب الثلاثة

**السبب 1 — تسلسل تام بدون أي توازيات:**
- اتصال واحد، كرت واحد في كل مرة
- `await client.talk(...)` ينتظر الاستجابة بالكامل قبل الكرت التالي
- مع 1000 كرت = 2000 round-trip تسلسلي على اتصال واحد

**السبب 2 — 2 round-trip لكل كرت (غير ضروري):**
- `user/add` ثم `create-and-activate-profile` — كلاهما استدعاء API منفصل
- بدلاً من دمج الـ add+activate في أمر واحد، يتم 2 مرة

**السبب 3 — تضخم الرسائل:**
- `sendPort.send(...)` يُرسل لكل كرت → 1000 رسالة Progress على قناة Isolate
- هذا يعلق الواجهة ويستهلك الذاكرة

---

## الأدلة المستندة إلى المصدر

### 1. روابط API الرسمية لميكروتيك
من [MikroTik API Documentation](https://wiki.mikrotik.com/wiki/Manual:API):
> "When sending several commands with a tag, all commands are sent
> without waiting for a reply. Then the replies come back in any order,
> but each reply has the tag of the corresponding command."

هذا يعني أن الـ tags تسمح بـ **pipelining** — إرسال أوامر متعددة قبل استلام
أي استجابة، مما يزيل الـ latency بين الـ round-trips.

### 2. مصدر `router_os_client` 2.0.x (مؤكد من صفحة pub.dev والـ source)

من [الوثائق الرسمية لـ router_os_client 2.0.1](https://pub.dev/documentation/router_os_client/2.0.1/)
و[المستودع الأصلي على GitHub](https://github.com/ShafiqSadat/RouterOSClient):

**a) `TaggedCommand` والـ `talkMultiple`:**
```dart
Stream<TaggedResponse> talkMultiple(List<TaggedCommand> commands)
```
يُرسل كل الأوامر في القائمة عبر الـ socket ثم يبثّ الاستجابات
عبر `Stream<TaggedResponse>` — يستفيد من pipelining الـ socket.

**b) الـ `TaggedCommand` يقبل `command: List<String>`:**
```dart
// _buildSentence handles both String and List<String> as `command`:
if (command is List<String>) {
  sentence.addAll(command);  // ← يضيف كل العناصر مباشرة
}
```
بما أن `_sendTaggedCommand` يستخدم `_writeSentence(socket, ...)` (كتابة
socket غير مسدودة)، فإن إرسال موجة بـ 100 أمر يكتمل في جزئية زمنية واحدة.

**c) إصلاحات 2.0.1 الحرجة:**
وفقاً لـ [CHANGELOG.md الرسمي](https://github.com/ShafiqSadat/RouterOSClient/blob/master/CHANGELOG.md):
- **TCP fragmentation framing**: parser مؤقت يعيد تجميع الجمل المتكسورة
- **Tag collisions**: العلامات مولدة من عداد تكراري (ليس ميللي ثواني)
- **Reconnection after `close()`**: stream controller يعاد إنشاؤه

هذه الإصلاحات مهمة جداً للـ bulk operations — إصلاحات 2.0.0 تُفقد
الردود في الموجات الكبيرة.

---

## التصحيح المطبق

### `lib/bulk_add_isolate.dart`

| الجزء | قبل | بعد |
|-------|-----|-----|
| عدد الاتصالات | 1 (تسلسلي) | 4 (بالتوازي عبر `Future.wait`) |
| إرسال الأوامر | `talk()` لكل كرت (2×N round-trips) | `talkMultiple()` بـ tags في موجات |
| حجم الموجة | كل الكروت مرة واحدة | `_waveSize = 50` كرت/موجة |
| المهلة | لا واحدة per-card | `min(max(30, waveSize*4), 1800)` لكل موجة |
| رسائل Progress | N رسائل (لكل كرت) | كل 25 كرت فقط (`_progressReportCardInterval`) |
| الفشول الجزئية | توقف كل الدفعة | تمثيل `failedAdds` + استكمال الباقي |
| تنظيف الاتصالات | في `finally` واحد | `finally` يغلق الاتصالات + `cleanUp` في `Future.wait` |

### الإستراتيجية الجديدة — 3 طبقات توازي

```
طبقة 1: 4 اتصالات بالتوازي (Future.wait)          ← يوفر 3× login-latency
طبقة 2: كل شاردة ترسل موجات (waves) بـ talkMultiple  ← יציאת socket pipelining
طبقة 3: كل موجة ≤ 50 كرت × 2 أوامر = 100 أمر/mwave  ← يمنع تجميع آلاف الأوامر
```

### `pubspec.yaml`
```
router_os_client: ^2.0.1   # ↑ من ^2.0.0 — يحصل على إصلاحات TCP framing + tag collisions
```

### `lib/bulk_add_screen.dart`
- قراءة `failedCount` من رسالة `success` وعرضها في الـ dialog

---

## التوصيات للمستقبل

1. **RouterOS V7**: استخدام `/rest/user-manager/user/add-batch-users` (REST endpoint) بدلاً من binary API — يدعم الدُفء الكبير بطبيعة الواجهة.
2. **ترقية إلى router_os_client 3.x**: يحتوي إصلاحات إضافية للبروتوكول وتحسينات على `talkMultiple`.
3. **اختبار Integration**: اختبار ضد راوتر حقيقي أو [mikrotik-simulator](https://github.com/mikrotik-lib/routeros-sim) للـ CI.
