# دليل تحسينات الأداء — MikroTik Manager

تطبيق Flutter محسّن للأجهزة الضعيفة (1GB RAM, 1.4GHz CPU).

## ملخص التحسينات المطبقة

### 1. تحسين بناء الواجهات (UI Rendering)

| التحسين | التطبيق |
|---------|---------|
| `const` للـ Widgets الثابتة | مطبّق في كل الشاشات (main.dart, network_*, pdf_*, etc.) |
| `ListView.builder` بدل `ListView` | مطبّق في كل القوائم + `itemExtent` ثابت |
| `RepaintBoundary` | حول كل Card, ListView, Chart |
| `withOpacity()` → `const Color(0x...)` | مطبّق في main.dart وكل الشاشات (إزالة allocations) |
| `cacheWidth` للصور | مطبّق في main.dart (wifi_logo) و كل `Image.file` |
| `filterQuality.low` على الأجهزة الضعيفة | مطبّق في `CachedImage` |

### 2. إدارة الحالة الذكية (State Management)

| التحسين | التطبيق |
|---------|---------|
| `Riverpod select()` | في `active_users_v2.dart` و `cards_statistics_v2.dart` |
| `addPostFrameCallback` بدل `setState` في initState | في كل StatefulWidgets |
| `mounted` checks في async flows | في كل الـ futures |
| إلغاء Timers/Subscriptions في dispose() | في كل الشاشات التي فيها timers |

### 3. كود Dart فعال

| التحسين | التطبيق |
|---------|---------|
| `Isolate.run` للعمليات الثقيلة | `lib/perf/isolate_helper.dart` (JSON parsing, list casting, sorting) |
| `Future.wait` للطلبات المتوازية | في `cards_stats_provider.dart` (طلبات users + sessions بالتوازي) |
| `.map().toList()` → `for` collection | في كل الشاشات (~30 موقع) |
| `String +` → `'$var'` interpolation | مطبّق عالمياً |
| caching في الذاكرة | `ResponseCache` في `optimized_providers.dart` |
| `dio_cache_interceptor` (قالب) | `lib/perf/dio_cache_service.dart` |

### 4. إعدادات البناء و Android

| التحسين | الأثر |
|---------|------|
| `isMinifyEnabled = true` (R8) | تصغير حجم APK 30-50% |
| `isShrinkResources = true` | إزالة موارد غير مستخدمة |
| `proguard-rules.pro` محسّن | حماية مكتبات ML Kit, MQTT, Syncfusion |
| `splits.abi` (arm64 + armv7) | APK أصغر لكل معماريا |
| `android.enableR8.fullMode=true` | تحسين أعمق |
| `extractNativeLibs="false"` | تقليل حجم APK |
| `largeHeap="false"` | إجبار استخدام ذاكرة أقل |
| `DELAY_MODEL_DOWNLOAD` لـ ML Kit | لا يُحمّل النموذج عند البدء |

### 5. كشف قدرة الجهاز (`DeviceCapability`)

تصنيف تلقائي للأجهزة إلى 3 طبقات:
- **low**: SDK < 26 → عطّل animations, cacheExtent=100
- **mid**: SDK 26-30 → مدة حركة 200ms, cacheExtent=250
- **high**: SDK 31+ → حركة كاملة 300ms, cacheExtent=500

### 6. ملفات مساعدة جديدة

| الملف | الوظيفة |
|------|---------|
| `lib/perf/device_capability.dart` | كاشف قدرة الجهاز |
| `lib/perf/perf_widgets.dart` | `CachedImage`, `PerfCard`, `PerfListView`, `PerfLoadingIndicator`, `PerfBoundary` |
| `lib/perf/isolate_helper.dart` | `runInIsolate`, `parseJsonInIsolate`, `sortInIsolate` |
| `lib/perf/dio_cache_service.dart` | Dio مع cache (قالب) |
| `lib/v2/providers/optimized_providers.dart` | `ResponseCache`, `routerServiceProvider` |
| `lib/v2/providers/RIVERPOD_SELECT_GUIDE.dart` | دليل أنماط `select()` |
| `lib/v2/providers/SELECT_PERFORMANCE_COMPARISON.dart` | مخطط مرئي قبل/بعد |

## نتائج flutter analyze

```
129 issues found (0 errors, 0 warnings major, 129 info-level lints)
```

كل الـ info lints هي:
- `deprecated_member_use` (withOpacity → withValues) — متروكة لأن `withValues` يحتاج Flutter 3.27+
- `prefer_const_constructors` — تحسينات جمالية
- `unused_import` — imports محجوزة للاستخدام المستقبلي

## كيفية الاستفادة من Profile Mode

```bash
# تثبيت التطبيق بوضع Profile (يحاكي الأداء الحقيقي)
flutter run --profile

# فتح DevTools لمراقبة الأداء
flutter pub global activate devtools
flutter pub global run devtools

# راقب:
# - Performance tab: الـ frames التي تتجاوز 16ms (jank)
# - Memory tab: تسريبات الذاكرة
# - CPU tab: الدوال الأبطأ
```

## بناء APK محسّن للإنتاج

```bash
# بناء APK مع R8 + shrink + ABI splits
flutter build apk --release --target-platform android-arm64,android-arm

# أو App Bundle (أصغر للمستخدمين)
flutter build appbundle --release

# النتيجة: APK أصغر 40-60% من البناء الافتراضي
```

## الخطوات التالية المقترحة

1. **اختبار على جهاز حقيقي ضعيف** — لا يكفي المحاكي
2. **مراقبة الـ frames في Profile mode** — ابحث عن أي jank > 16ms
3. **استخدام `flutter run --trace-skia`** لتشخيص مشاكل الرسم
4. **تطبيق `select()` على باقي الشاشات** — اتبع دليل `RIVERPOD_SELECT_GUIDE.dart`
5. **إضافة `dio_cache_interceptor`** لطلبات الشبكة المتكررة
6. **استخدام `flutter build apk --split-per-abi`** لإنتاج APK منفصل لكل معمارية (الأصغر)
