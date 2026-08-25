# Telegram Bot — Direct MikroTik RouterOS API

Telegram Bot is the direct control-plane component. It owns the RouterOS v6 API client; no relay layer or subprocess control path is used.

Control path: Telegram -> Bot -> identity/authorization/policy -> command service -> RouterOS API -> MikroTik.
Health path: Bot -> RouterOS API -> router/WAN checks -> Telegram notifications.

Production defaults require RouterOS API-SSL (8729). Exposing plain 8728 is rejected unless `ALLOW_INSECURE_ROUTEROS_API=true` is explicitly set.

## الوظائف

الأوامر تمر عبر `RouterOSOperations` المسمى، وليس عبر مسار RouterOS خام يأتي من رسالة المستخدم. تشمل الوظائف: حالة الراوتر والإنترنت، الموارد والواجهات والسجلات، الجلسات والمستخدمين والفئات، فحص واستهلاك بطاقة، إنشاء بطاقة بعد تأكيد مسؤول، معاينة وحذف المستخدمين المنتهيين بعد تأكيد مسؤول، تقارير HTML/PDF، وتقرير تشغيلي للمخزون حسب العميل والفئة.

العمليات التغييرية (`/reboot` و`/card-create` و`/delete-expired`) تتطلب Chat ID وTelegram User ID مسموحين، وتتحقق من Admin User ID، وتستخدم nonce قصير العمر مربوطًا بالمحادثة والمستخدم. يسجل `AuditTrail` العملية والنتيجة و`operation_id` دون تسجيل Bot Token أو كلمات المرور.

تقرير `/sales` **تشغيلي عددي** مبني على metadata المتاحة في User Manager. لا يعرض إيرادًا ماليًا ما لم توجد حقول أسعار موثقة في البيانات؛ لا يُنشئ أرقامًا مالية تقديرية.

## إعداد User Manager

يُضبط `USER_MANAGER_CUSTOMER` في `bot.env`، والقيمة الافتراضية `admin`. يجب أن يملك حساب RouterOS المجموعة الأقل صلاحية اللازمة للأوامر الموجودة في قالب `deploy/routeros/telegram-bot-user-v6.rsc.example`. لا تضف `write` تلقائيًا؛ اختبر كل أمر تغييري على نسخة تجريبية أولًا.
