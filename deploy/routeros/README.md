# Telegram مباشر من MikroTik RouterOS v6

الملف `telegram-direct-v6.rsc` يضيف سكريبتات RouterOS v6 لإرسال إشعارات Telegram مباشرة من MikroTik `192.168.1.100` إلى `chat_id=5944227208`. يتضمن الإعداد اختباراً يدوياً ومراقبة اتصال إلى `1.1.1.1` كل 30 ثانية، مع إشعار واحد عند الانتقال إلى الانقطاع وإشعار واحد عند العودة.

## قبل الاستيراد

أنشئ Bot Token جديداً من BotFather إذا ظهر الرمز السابق في محادثة أو سجل، ثم انسخ الملف إلى جهازك المحلي. افتح نسخة محلية فقط واستبدل النص:

```text
REPLACE_WITH_NEW_BOT_TOKEN
```

بالرمز الجديد. لا ترفع النسخة المعدلة إلى GitHub ولا ترسلها إلى أي شخص.

## الاستيراد عبر Terminal

بعد رفع الملف إلى **Files** في MikroTik، نفّذ:

```routeros
/import file-name=telegram-direct-v6.rsc
```

إذا كان اسم الملف مختلفاً، استخدم الاسم الظاهر في `/file print`.

بعد الاستيراد، نفّذ اختبار Telegram:

```routeros
/system script run telegram-v6-test
```

ثم راقب السجل:

```routeros
/log print where message~"telegram-v6"
```

## التحقق من العناصر

```routeros
/system script print where name~"telegram-v6"
/system scheduler print where name="telegram-internet-monitor-v6"
```

اختبر فحص الإنترنت يدوياً:

```routeros
/system script run telegram-v6-monitor
```

## تغيير هدف الفحص

يستخدم السكريبت `1.1.1.1` افتراضياً. لتغيير الهدف إلى `8.8.8.8`، عدّل سطر `telegramMonitorTarget` في السكريبت أو أضف قيمة عالمية من Terminal:

```routeros
:global telegramMonitorTarget "8.8.8.8"
```

## ملاحظات تشغيلية وأمنية

يستخدم الإرسال المباشر `/tool fetch` إلى Telegram HTTPS، ولذلك يجب أن يكون MikroTik قادراً على الوصول إلى الإنترنت وDNS مضبوطاً. في بعض إصدارات RouterOS v6 قد تحتاج إلى إبقاء `check-certificate=no` بسبب مخزن الشهادات القديم؛ لا تفتح أي منفذ وارد لهذا السكريبت.

السكريبت لا ينفذ SSH ولا يقبل أوامر نصية من Telegram، ولا ينشئ أو يحذف مستخدمي Hotspot أو User Manager. إنشاء البطاقات وملفات PDF واختيار الفئة يبقى من اختصاص جسر Linux، لأن RouterOS ليس بيئة مناسبة لإنشاء PDF وإرسال ملفات Telegram المعقدة.

## إزالة الإعداد

الأوامر التالية تزيل العناصر التي أنشأها هذا التكامل فقط:

```routeros
/system scheduler remove [find name="telegram-internet-monitor-v6"]
/system script remove [find name="telegram-v6-send"]
/system script remove [find name="telegram-v6-test"]
/system script remove [find name="telegram-v6-monitor"]
```
