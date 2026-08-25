# RouterOS API-SSL preparation for the direct Telegram Bot

يتصل Telegram Bot من جهاز Linux مباشرةً إلى MikroTik عبر RouterOS API-SSL. لا يرسل MikroTik Bot Token إلى Telegram، ولا يحتوي هذا المشروع على RouterOS script أو scheduler لمسار Telegram مباشر.

## الصلاحيات الأقل

الأوامر الحالية في `telegram_bot/commands/router.py` هي أوامر قراءة، و`/ping`، و`/system/reboot`. وفق توثيق MikroTik، يحتاج الحساب المخصص إلى `read,api,reboot,test`؛ لا تُضاف `write` ما لم يُثبت لاحقًا وجود أمر تغييري آخر. راجع الأمر الفعلي في الكود قبل توسيع المجموعة.

القالب `telegram-bot-user-v6.rsc.example` يترك عنوان الخادم وكلمة المرور كقيم بديلة. استبدلهما محليًا فقط، وقيّد خدمة API-SSL بعنوان خادم البوت. لا تستخدم عنوانًا افتراضيًا ولا تفتح المنفذ 8729 على الإنترنت العام.

```routeros
/user group add name=telegram-bot-policy policy=read,api,reboot,test comment="Dedicated direct Telegram Bot API account"
/user add name=telegram-bot group=telegram-bot-policy password="REPLACE_WITH_LONG_RANDOM_PASSWORD" address="REPLACE_BOT_SERVER_CIDR"
/ip service set [find name="api"] disabled=yes
/ip service set [find name="api-ssl"] disabled=no port=8729 address="REPLACE_BOT_SERVER_CIDR"
```

إذا استُخدم جدار ناري، اسمح باتصالات TCP إلى 8729 من عنوان خادم البوت فقط قبل قواعد الإسقاط العامة. تحقق بعد التطبيق:

```routeros
/user group print detail where name="telegram-bot-policy"
/user print detail where name="telegram-bot"
/ip service print detail where name="api"
/ip service print detail where name="api-ssl"
```

يجب أن تكون `TELEGRAM_ADMIN_USER_IDS` في إعداد البوت مجموعة فرعية من `TELEGRAM_ALLOWED_USER_IDS`؛ تركها فارغة يعطل `/reboot`، حتى لو كان حساب RouterOS يملك سياسة `reboot`. لا تضع Bot Token في RouterOS أو في Git.

المراجع الرسمية: [User](https://help.mikrotik.com/docs/spaces/ROS/pages/8978504/User) و[API](https://help.mikrotik.com/docs/spaces/ROS/pages/47579160/API).
