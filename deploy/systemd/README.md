# تشغيل جسر Telegram كخدمة systemd

هذا الدليل يثبت جسر Telegram الموجود في `telegram_bridge/telegram_bridge.py` كخدمة Linux دائمة. يعاد تشغيل الخدمة تلقائياً بعد إقلاع الجهاز أو توقف العملية، وتُحفظ الأسرار في `/etc/mikrotik-telegram/bridge.env` خارج المستودع.

## الوظائف المدعومة

الخدمة تدعم مراقبة RouterOS v6، قراءة موارد الراوتر وواجهاته وجلسات User Manager، جلب فئات User Manager من `/tool/user-manager/profile/print`، واستقبال رقم كرت مثل `554377` ثم عرض الفئات كأزرار وإنشاء ملف PDF قياسي وإرساله إلى Telegram. كما تعرض `/usage` استهلاك واجهة WAN منذ أول قراءة في اليوم، وترسل تقريراً يومياً، وتعرض `/uptime` و`/users` و`/logs`.

يسمح الجسر بأمر تحكم واحد فقط هو `/reboot`. لا ينفذ إعادة التشغيل مباشرة؛ بل يرسل زري تأكيد وإلغاء، ويتحقق من chat ID وnonce صالح لمدة 60 ثانية قبل إرسال `/system/reboot`. لا ينفذ أوامر SSH عشوائية ولا ينشئ مستخدمي Hotspot أو User Manager.

## المتطلبات

يحتاج جهاز التشغيل إلى Linux مع `systemd` وPython 3، ووصول TCP إلى MikroTik على RouterOS API port `8728`. يجب تثبيت دعم PDF:

```bash
sudo apt update
sudo apt install -y python3 python3-reportlab
```

يُفضّل استخدام جهاز دائم التشغيل خارج شبكة MikroTik إذا كان مطلوباً وصول تنبيه فوري عند انقطاع الإنترنت؛ لأن الجسر داخل الشبكة لن يستطيع الوصول إلى Telegram أثناء الانقطاع نفسه.

## التثبيت المحلي الموصى به

من جذر المستودع شغّل المثبت التفاعلي؛ سيطلب Bot Token وكلمة مرور MikroTik دون إظهار كلمة المرور، وينشئ virtual environment وملف البيئة وخدمة systemd تلقائياً:

```bash
sudo ./scripts/setup_telegram_bridge_local.sh
```

بعد التشغيل:

```bash
sudo systemctl status mikrotik-telegram --no-pager
sudo journalctl -u mikrotik-telegram -f
```

## التثبيت اليدوي

نفّذ الأوامر التالية من جذر المستودع إذا كنت لا تريد استخدام المثبت:

```bash
sudo useradd --system --home /opt/mikrotik-telegram --shell /usr/sbin/nologin mikrotik-telegram 2>/dev/null || true
sudo mkdir -p /opt/mikrotik-telegram /etc/mikrotik-telegram /var/lib/mikrotik-telegram
sudo install -m 0750 telegram_bridge/telegram_bridge.py /opt/mikrotik-telegram/telegram_bridge.py
sudo chown -R mikrotik-telegram:mikrotik-telegram /opt/mikrotik-telegram /var/lib/mikrotik-telegram
sudo install -m 0644 deploy/systemd/mikrotik-telegram.service /etc/systemd/system/mikrotik-telegram.service
sudo install -m 0640 -o root -g mikrotik-telegram deploy/systemd/bridge.env.example /etc/mikrotik-telegram/bridge.env
# عند استخدام Python virtual environment، أنشئ البيئة وثبّت المتطلبات:
sudo python3 -m venv /opt/mikrotik-telegram/.venv
sudo /opt/mikrotik-telegram/.venv/bin/pip install -r telegram_bridge/requirements.txt
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
TRAFFIC_INTERFACE=ether1
TRAFFIC_INTERVAL_SECONDS=60
TRAFFIC_STATE_FILE=/var/lib/mikrotik-telegram/traffic-state.json
TRAFFIC_DAILY_REPORT_TIME=23:59
```

## إعداد MikroTik RouterOS v6

عنوان MikroTik المستخدم في هذا المشروع هو `192.168.1.100`. أنشئ مستخدم API مخصصاً للجسر من Terminal MikroTik، بصلاحيات `read,api,test,write` فقط حتى يعمل أمر إعادة التشغيل المسموح، واستبدل كلمة المرور:

```routeros
/user group add name=telegram-bridge policy=read,api,test,write comment="Telegram RouterOS v6 bridge"
/user add name=telegram-monitor group=telegram-bridge password="<كلمة-مرور-قوية>" comment="Telegram bridge API user"
```

يجب تقييد خدمة API على عنوان جهاز تشغيل الجسر، وليس على عنوان MikroTik. إذا كان جهاز الجسر مثلاً `192.168.1.50`:

```routeros
/ip service set [find name=api] disabled=no port=8728 address=192.168.1.50/32
/ip firewall filter add chain=input action=accept protocol=tcp dst-port=8728 src-address=192.168.1.50/32 place-before=0 comment="Allow Telegram bridge API"
```

لا تستخدم `0.0.0.0/0` ولا تفتح منفذ `8728` على الإنترنت العام. صلاحية `write` مطلوبة فقط لأن `/reboot` أمر تغيير؛ لا تمنح `ssh` أو `policy` كاملة، واختبر الحساب من جهاز الجسر قبل تفعيل الخدمة.

تقرير الاستهلاك يعتمد على عدادات `rx-byte` و`tx-byte` التراكمية من RouterOS v6. عيّن `TRAFFIC_INTERFACE` إلى واجهة WAN واحدة مثل `ether1`; إذا تركتها فارغة سيجمع الجسر كل الواجهات المفعلة وقد يكرر المرور في bridge أو VLAN. يُحفظ ملف الحالة في `/var/lib/mikrotik-telegram` لأن وحدة systemd تسمح بالكتابة هناك فقط.

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
sudo chown root:mikrotik-telegram /opt/mikrotik-telegram/telegram_bridge.py
sudo systemctl restart mikrotik-telegram.service
sudo journalctl -u mikrotik-telegram.service -n 50 --no-pager
```

لا تنسخ ملف البيئة من Git فوق `/etc/mikrotik-telegram/bridge.env` بعد أن أدخلت الأسرار، ولا تضع Bot Token أو كلمة مرور MikroTik في GitHub.
