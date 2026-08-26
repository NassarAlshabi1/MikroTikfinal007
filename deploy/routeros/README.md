# RouterOS API-SSL and optional direct Telegram mode

يدعم المشروع مسارين منفصلين: المسار المفضل Telegram Bot على Linux إلى MikroTik عبر RouterOS API-SSL، ومسار مباشر اختياري موثق لاحقًا يجعل MikroTik يتصل بـ Telegram. لا تُستخدم المساران معًا لنفس Bot Token.

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

يجب أن تكون `TELEGRAM_ADMIN_USER_IDS` في إعداد Linux Bot مجموعة فرعية من `TELEGRAM_ALLOWED_USER_IDS`. هذه القائمة تتحكم في `/reboot` و`/card-create` و`/delete-expired`، ولا يغني امتلاك حساب RouterOS لصلاحية عن التحقق من هوية Telegram. في مسار Linux Bot لا تضع Bot Token أو كلمة مرور RouterOS في RouterOS أو Git؛ أما الوضع المباشر الاختياري فيستخدم placeholder محليًا داخل RouterOS ولا يرفع النسخة المملوءة إلى Git.

المراجع الرسمية: [User](https://help.mikrotik.com/docs/spaces/ROS/pages/8978504/User) و[API](https://help.mikrotik.com/docs/spaces/ROS/pages/47579160/API).

## الوضع المباشر من MikroTik إلى Telegram

بناءً على طلب صريح، يوفّر المشروع الآن قالبًا اختياريًا للمسار المباشر في `telegram-direct-bot-v6.rsc.example`. هذا الوضع يجعل MikroTik يستدعي Telegram Bot API عبر `/tool fetch` ويستقبل الأوامر باستخدام `getUpdates` من خلال Scheduler. القالب لا ينفّذ السكربت المرفق القديم كما هو؛ بل يحصر الأوامر في `/status` و`/users` و`/check_card` و`/c200` و`/clean` و`/reboot`، ويتحقق من `chat_id` و`user_id`، ويضع تأكيدًا قصير العمر قبل العمليات التغييرية.

هذا المسار المباشر يضع Bot Token داخل RouterOS، ولذلك يجب اعتباره أقل أمانًا من تشغيل Python Bot على Linux. لا ترفع النسخة المملوءة إلى Git، ولا تستخدم الرمز الذي ظهر في المحادثة؛ أصدر رمزًا جديدًا من BotFather قبل وضعه على الراوتر. لا تشغّل الوضع المباشر وخدمة Linux Bot معًا لنفس Bot Token، لأن كلاهما سيستدعي `getUpdates` وقد يستهلك التحديثات من الطرف الآخر.

للاستخدام، انسخ القالب إلى مكان خاص، واستبدل `REPLACE_WITH_*` محليًا فقط، ثم استورده في MikroTik. يجب أن يكون `api-ssl` أو `/tool fetch` قادرًا على التحقق من شهادة HTTPS الخاصة بـ Telegram، ويجب تقييد وصول الإدارة إلى الشبكة الموثوقة. اختبر أولًا الأمر `/status` ثم `/users`، ولا تفعل أوامر الإنشاء أو التنظيف أو إعادة التشغيل إلا بعد مراجعة القالب.

إذا اخترت المسار الأكثر أمانًا، استخدم بدلًا منه خدمة Linux Bot وإعدادات API-SSL التالية في `bot.env`:

```dotenv
MIKROTIK_PORT=8729
MIKROTIK_USE_SSL=true
MONITOR_TARGET=1.1.1.1
MONITOR_INTERVAL_SECONDS=30
```

القالب القديم ذي parsing اليدوي الواسع لا يُستورد كما هو؛ القالب الجديد هو النسخة المقيدة المقصودة للوضع المباشر، بينما يبقى `telegram-bot-user-v6.rsc.example` مخصصًا لمسار Linux Bot عبر RouterOS API-SSL.
