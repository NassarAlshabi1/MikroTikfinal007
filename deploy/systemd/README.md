# تشغيل جسر Telegram كخدمة systemd

هذا الدليل يثبت جسر Telegram الموجود في `telegram_bridge/telegram_bridge.py` كخدمة Linux دائمة. يعاد تشغيل الخدمة تلقائياً بعد إقلاع الجهاز أو توقف العملية، وتُحفظ الأسرار في `/etc/mikrotik-telegram/bridge.env` خارج المستودع.

## الوظائف المدعومة

الخدمة تدعم مراقبة RouterOS v6، قراءة موارد الراوتر وواجهاته وجلسات User Manager، جلب فئات User Manager من `/tool/user-manager/profile/print`، واستقبال رقم كرت مثل `554377` ثم عرض الفئات كأزرار وإنشاء ملف PDF قياسي وإرساله إلى Telegram.

هذا الإصدار لا ينفذ أوامر SSH عشوائية ولا ينشئ مستخدمي Hotspot أو User Manager؛ فهو يستخدم حساب MikroTik محدود القراءة ويتحقق من وجود المستخدم قبل إنشاء PDF. توليد المستخدمين أو تغييرهم يحتاج إلى طبقة أوامر منفصلة بقائمة سماح وتأكيد مزدوج.

## المتطلبات

يحتاج جهاز التشغيل إلى Linux مع `systemd` وPython 3، ووصول TCP إلى MikroTik على RouterOS API port `8728`. يجب تثبيت دعم PDF:

```bash
sudo apt update
sudo apt install -y python3 python3-reportlab
```

يُفضّل استخدام جهاز دائم التشغيل خارج شبكة MikroTik إذا كان مطلوباً وصول تنبيه فوري عند انقطاع الإنترنت؛ لأن الجسر داخل الشبكة لن يستطيع الوصول إلى Telegram أثناء الانقطاع نفسه.

## تثبيت الملفات

نفّذ الأوامر من جذر المستودع:

```bash
sudo useradd --system --home /opt/mikrotik-telegram --shell /usr/sbin/nologin mikrotik-telegram 2>/dev/null || true
sudo mkdir -p /opt/mikrotik-telegram /etc/mikrotik-telegram /var/lib/mikrotik-telegram
sudo install -m 0750 telegram_bridge/telegram_bridge.py /opt/mikrotik-telegram/telegram_bridge.py
sudo chown -R mikrotik-telegram:mikrotik-telegram /opt/mikrotik-telegram /var/lib/mikrotik-telegram
sudo install -m 0644 deploy/systemd/mikrotik-telegram.service /etc/systemd/system/mikrotik-telegram.service
sudo install -m 0640 -o root -g mikrotik-telegram deploy/systemd/bridge.env.example /etc/mikrotik-telegram/bridge.env
```

افتح ملف البيئة، ثم أدخل Bot Token الجديد محلياً وكلمة مرور مستخدم MikroTik:

```bash
sudo nano /etc/mikrotik-telegram/bridge.env
sudo chown root:mikrotik-telegram /etc/mikrotik-telegram/bridge.env
sudo chmod 640 /etc/mikrotik-telegram/bridge.env
```

القيم الأساسية هي:

```ini
TELEGRAM_BOT_TOKEN=ضع_الرمز_الجديد_محلياً
TELEGRAM_ALLOWED_CHAT_IDS=5944227208
MIKROTIK_ADDRESS=192.168.1.100
MIKROTIK_USER=telegram-monitor
MIKROTIK_PASSWORD=كلمة_مرور_المستخدم
MIKROTIK_PORT=8728
MIKROTIK_USE_SSL=false
TELEGRAM_POLL_SECONDS=20
TELEGRAM_OFFSET_FILE=/var/lib/mikrotik-telegram/.telegram_offset
MONITOR_TARGET=1.1.1.1
MONITOR_INTERVAL_SECONDS=30
```

## إعداد MikroTik RouterOS v6

عنوان MikroTik المستخدم في هذا المشروع هو `192.168.1.100`. أنشئ مستخدم API للقراءة فقط من Terminal MikroTik، واستبدل كلمة المرور:

```routeros
/user group add name=telegram-monitor policy=read,api,test comment="Telegram RouterOS v6 monitoring"
/user add name=telegram-monitor group=telegram-monitor password="<كلمة-مرور-قوية>" comment="Telegram bridge API user"
```

يجب تقييد خدمة API على عنوان جهاز تشغيل الجسر، وليس على عنوان MikroTik. إذا كان جهاز الجسر مثلاً `192.168.1.50`:

```routeros
/ip service set [find name=api] disabled=no port=8728 address=192.168.1.50/32
/ip firewall filter add chain=input action=accept protocol=tcp dst-port=8728 src-address=192.168.1.50/32 place-before=0 comment="Allow Telegram bridge API"
```

لا تستخدم `0.0.0.0/0` ولا تفتح منفذ `8728` على الإنترنت العام.

## تفعيل الخدمة

```bash
sudo systemctl daemon-reload
sudo systemctl enable --now mikrotik-telegram.service
sudo systemctl status mikrotik-telegram.service --no-pager
```

تابع السجل:

```bash
sudo journalctl -u mikrotik-telegram.service -f
```

أوامر الإدارة الأساسية:

```bash
sudo systemctl restart mikrotik-telegram.service
sudo systemctl stop mikrotik-telegram.service
sudo systemctl start mikrotik-telegram.service
sudo systemctl disable mikrotik-telegram.service
```

## الاختبار

اختبر الوصول إلى API قبل تشغيل الخدمة:

```bash
nc -vz 192.168.1.100 8728
```

ثم أرسل إلى البوت من الحساب ذي `chat_id=5944227208`:

```text
/status
/resources
/profiles
554377
```

عند إرسال `554377`، يجلب الجسر الفئات من User Manager v6، يعرضها للاختيار، ثم يتحقق من المستخدم عبر `/tool/user-manager/user/print` ويرسل PDF قياسياً إلى Telegram.

## تحديث الكود

بعد سحب تحديث جديد من الفرع:

```bash
sudo install -m 0750 telegram_bridge/telegram_bridge.py /opt/mikrotik-telegram/telegram_bridge.py
sudo chown mikrotik-telegram:mikrotik-telegram /opt/mikrotik-telegram/telegram_bridge.py
sudo systemctl restart mikrotik-telegram.service
sudo journalctl -u mikrotik-telegram.service -n 50 --no-pager
```

لا تنسخ ملف البيئة من Git فوق `/etc/mikrotik-telegram/bridge.env` بعد أن أدخلت الأسرار، ولا تضع Bot Token أو كلمة مرور MikroTik في GitHub.
