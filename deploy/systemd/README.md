# Telegram Bot — Direct MikroTik RouterOS API

هذه الخدمة تشغّل `telegram_bot` مباشرة. لا توجد طبقة relay أو subprocess ولا مسار تحكم عكسي من MikroTik إلى Telegram.

المسار:

`Telegram -> Telegram Bot -> Authentication/Policy -> RouterOS API Client -> MikroTik`

## التشغيل

```bash
sudo ./scripts/setup_telegram_bot_local.sh
sudo systemctl status mikrotik-telegram --no-pager
sudo journalctl -u mikrotik-telegram -f
```

## متطلبات الشبكة

يجب أن يستطيع جهاز تشغيل البوت الوصول إلى عنوان MikroTik عبر RouterOS API. في سيناريو منزل/عمل، الأفضل أن يكون الوصول عبر VPN مثل WireGuard، أو تقييد API-SSL في MikroTik على عنوان IP الخاص بخادم البوت. لا تفتح API على الإنترنت العام.

الافتراضي هو API-SSL على 8729 مع TLS verification. إذا كانت شهادة RouterOS خاصة، ضع CA الخاص بها في `MIKROTIK_CA_FILE`.

## صلاحيات Telegram

يجب ضبط الاثنين معًا:

- `TELEGRAM_ALLOWED_CHAT_IDS`
- `TELEGRAM_ALLOWED_USER_IDS`

ويجب أن يطابق الطلب Chat ID وTelegram User ID معًا. هذا مهم خصوصًا لـ `/reboot`.

## الأوامر

- `/status`
- `/resources`
- `/uptime`
- `/active`
- `/profiles`
- `/users`
- `/interfaces`
- `/checklist`
- `/usage`
- `/logs`
- `/card username` و`/card-check username`
- `/card-usage username` و`/sessions [username]`
- `/card-create username profile` بعد تأكيد Admin
- `/delete-expired` معاينة ثم تأكيد Admin
- `/print active|users|profiles|interfaces`
- `/report html|pdf`
- `/sales` تقرير تشغيلي، وليس إيرادات إلا عند توفر payment records موثقة
- `/reboot` مع تأكيد صريح وAdmin

بعد `/reboot` يراقب البوت حالتي RouterOS API وWAN ويرسل إشعارًا عند عودة الراوتر والإنترنت.

## مراقبة الإنترنت

`INTERNET_DOWN` تعني أن RouterOS API متاح لكن فحص WAN من الراوتر يفشل. `ROUTER_OFFLINE` تعني أن API نفسه غير متاح. لا يتم الخلط بين الحالتين.

## Audit

كل عملية تغيير مثل `/reboot` و`/card-create` و`/delete-expired` تسجل في `TELEGRAM_AUDIT_FILE` مع operation ID وuser/chat وrisk وauthorization وconfirmation والنتيجة والمدة، دون تسجيل الأسرار. الحذف لا يتم إلا بعد معاينة قائمة ذات تواريخ قابلة للتحقق.
