# RouterOS API-SSL preparation for the direct Telegram Bot

يتصل Telegram Bot من جهاز Linux مباشرةً إلى MikroTik عبر RouterOS API-SSL. لا يرسل MikroTik Bot Token إلى Telegram، ولا يحتوي هذا المشروع على RouterOS script أو scheduler لمسار Telegram مباشر.

## الصلاحيات الأقل

الأوامر الحالية تشمل القراءة والفحوص وإدارة User Manager المحدودة: إنشاء مستخدم وتفعيل profile، وحذف مستخدمين انتهت صلاحيتهم بعد معاينة وتأكيد مسؤول، إضافة إلى `/system/reboot`. وفق توثيق MikroTik، تمنح `read` القراءة، و`api` الوصول إلى API، و`test` أوامر الفحص، و`reboot` إعادة التشغيل؛ أما إدارة المستخدمين فتحتاج `write` مع `policy`. لذلك يضم القالب `read,write,policy,api,reboot,test`، ولا يضم صلاحيات الدخول التفاعلي أو الملفات أو المعلومات الحساسة.

القالب `telegram-bot-user-v6.rsc.example` يترك عنوان الخادم وكلمة المرور كقيم بديلة. استبدلهما محليًا فقط، وقيّد خدمة API-SSL بعنوان خادم البوت. لا تستخدم عنوانًا افتراضيًا ولا تفتح المنفذ 8729 على الإنترنت العام.

```routeros
/user group add name=telegram-bot-policy policy=read,write,policy,api,reboot,test comment="Dedicated direct Telegram Bot API account"
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

يجب أن تكون `TELEGRAM_ADMIN_USER_IDS` في إعداد البوت مجموعة فرعية من `TELEGRAM_ALLOWED_USER_IDS`. هذه القائمة تتحكم في `/reboot` و`/card-create` و`/delete-expired`، ولا يغني امتلاك حساب RouterOS لصلاحية عن التحقق من هوية Telegram. لا تضع Bot Token أو كلمة مرور RouterOS في RouterOS أو Git.

المراجع الرسمية: [User](https://help.mikrotik.com/docs/spaces/ROS/pages/8978504/User) و[API](https://help.mikrotik.com/docs/spaces/ROS/pages/47579160/API).
