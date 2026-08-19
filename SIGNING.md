# 🔐 تكوين توقيع Release للاستخدام الشخصي

هذا التطبيق مُعدّ للاستخدام الشخصي (غير منشور على Google Play).
التوقيع مطلوب لتحديثات APK على نفس الجهاز (نفس applicationId + نفس التوقيع).

## 📁 الملفات المُضمّنة

| الملف | الوصف |
|------|------|
| `android/app/release-keystore.jks` | ملف الـ keystore (JKS) |
| `android/key.properties` | بيانات الاعتماد (كلمات المرور، alias) |
| `android/app/build.gradle` | تكوين `signingConfigs.release` |

## 🔑 بيانات الاعتماد الافتراضية

```
storePassword: mikrotik123
keyPassword: mikrotik123
keyAlias: mikrotik-key
storeFile: release-keystore.jks
validity: 36,500 يوم (100 سنة)
```

## ⚙️ كيف يعمل التوقيع

1. عند تنفيذ `flutter build apk --release`:
   - يقرأ `build.gradle` ملف `android/key.properties`
   - يستخدم `release-keystore.jks` لتوقيع الـ APK
   - النتيجة: APK موقّع جاهز للتثبيت والتحديث

2. في GitHub Actions (`.github/workflows/flutter-apk-release.yml`):
   - يبني APK تلقائياً عند كل push
   - يتأكد من صحة التوقيع عبر `apksigner verify`
   - يرفع الـ APK كـ artifact

## ⚠️ ملاحظات أمنية مهمة

### للمستودعات الشخصية (الحالة الحالية):
- ✅ الـ keystore مرفوع في المستودع
- ✅ كلمات المرور بسيطة ومرئية
- ✅ مناسب للاستخدام الشخصي فقط

### للمستودعات العامة / التجارية:
- ❌ **لا ترفع keystore.jks ولا key.properties**
- ❌ استخدم GitHub Secrets بدلاً منها
- ❌ أنشئ keystore منفصل لكل بيئة (dev, staging, prod)

## 🔄 كيفية إنشاء keystore جديد (إن لزم)

```bash
keytool -genkey -v \
  -keystore android/app/release-keystore.jks \
  -keyalg RSA -keysize 2048 -validity 36500 \
  -alias mikrotik-key \
  -dname "CN=MikroTik Manager, OU=Personal, O=YourName, L=YourCity, ST=YourState, C=YE" \
  -storepass mikrotik123 -keypass mikrotik123
```

ثم حدّث `android/key.properties` بالقيم الجديدة.

## 📋 التحقق من التوقيع

```bash
# تحقق من توقيع APK موجود
keytool -printcert -jarfile app-arm64-v8a-release.apk

# أو عبر apksigner (يفصّل أكثر)
$ANDROID_HOME/build-tools/35.0.0/apksigner verify --verbose app-arm64-v8a-release.apk
```

## 🚫 لو نسيته أو فقدته

إذا فقدت الـ keystore:
- لن تستطيع تحديث التطبيق على الأجهزة المُثبّت عليها
- يجب تغيير `applicationId` (مثلاً `com.mikrotik.manager.v2`) لتثبيت كمستخدم جديد
- احتفظ بنسخة احتياطية من `release-keystore.jks` في مكان آمن
