# MikroTik Manager

تطبيق Flutter لإدارة بطاقات ومستخدمي MikroTik RouterOS، مع مكوّن Telegram Bot مستقل للقراءة والمراقبة وتنفيذ الأوامر المصرّح بها. البوت يتصل مباشرةً بـRouterOS API/API-SSL ولا يعتمد على Cloudflare Worker أو تشغيل أوامر shell كوسيط.

## مكوّنات المستودع

- **تطبيق Flutter** — شاشات الاتصال والبطاقات والتقارير والتشخيص وإدارة الراوتر.
- **Telegram Bot (`telegram_bot/`)** — تطبيق Python منفصل له سياسة صلاحيات وسجل تدقيق ومراقبة اتصال.
- **إعدادات الراوتر والنشر (`deploy/`)** — أمثلة إعدادات فقط؛ لا ترفع ملفات تشغيل أو أسرار فعلية.
- **التوثيق (`docs/`)** — البنية، الأداء، النسخ الاحتياطي، التوقيع وملاحظات التشغيل.

## تشغيل تطبيق Flutter

يتطلب Flutter `3.44.0` أو أحدث وDart `3.6.0` أو أحدث، إضافة إلى أدوات المنصة التي تستهدفها.

```bash
flutter pub get
flutter analyze
flutter test
flutter run
```

تُحمّل أسرار التطبيق من التخزين الآمن على الجهاز. لا تضع كلمات مرور الراوتر أو مفاتيح API في الكود أو في ملفات تُرفع إلى Git. للمساعدة في بناء نسخة إنتاجية راجع [SIGNING.md](SIGNING.md) وملفات سير العمل في `.github/workflows/`.

## تشغيل Telegram Bot

يتطلب Python `3.12` للإنتاج. أنشئ بيئة افتراضية محلية، ثم انسخ نموذج الإعدادات واملأ القيم في الملف المحلي فقط:

```bash
python3 -m venv .venv
. .venv/bin/activate
python -m pip install -r telegram_bot/requirements.txt
cp deploy/systemd/bot.env.example bot.env
# عدّل bot.env محليًا؛ لا تضف أسرارًا حقيقية إلى Git.
BOT_ENV_FILE=./bot.env python -m telegram_bot --selftest
BOT_ENV_FILE=./bot.env python -m telegram_bot
```

الافتراضي الإنتاجي هو RouterOS API-SSL على المنفذ `8729`. لا يُسمح بالاتصال غير المشفر على `8728` إلا بتفعيل صريح لـ`ALLOW_INSECURE_ROUTEROS_API=true`. راجع [دليل البوت](telegram_bot/README.md) و[تعليمات systemd](deploy/systemd/README.md) قبل النشر.

## الاختبارات والتحقق

```bash
# اختبارات البوت — دون اتصال فعلي بتيليغرام أو الراوتر
.venv/bin/python -m unittest discover -s . -p 'test_*.py' -v

# فحوص Flutter
flutter analyze
flutter test
```

تُشغّل GitHub Actions اختبارات Python وتحليل واختبارات Flutter وبناء APK تجريبيًا. اختبارات الاتصال الحقيقية بالراوتر أو حساب Telegram تحتاج إعدادًا اختباريًا منفصلًا ولا تُشغّل ضمن مجموعة الاختبارات الوحدوية.

## البنية وإعادة الهيكلة

نقطة الدخول صغيرة، وتركيب التطبيق في `lib/app.dart`، والتهيئة المشتركة في `lib/core/`، بينما توجد شاشتا الدخول ولوحة المعلومات تحت `lib/features/`. يبقى `lib/main.dart` واجهة توافق للتكاملات القديمة؛ أي ميزة جديدة يُفضّل أن تعتمد مباشرة على ملفها المالك بدل استيراد نقطة الدخول. يحتفظ البوت بمسارات منفصلة للإعدادات والتشغيل والاستقصاء والمراقبة والصلاحيات.

للتفاصيل والحدود المعمارية ومراحل الفصل التالية، راجع [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md).
