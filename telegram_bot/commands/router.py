from __future__ import annotations
import hashlib, logging, re, time
from typing import Any
from ..common import TelegramBotError
from ..telegram.client import TelegramClient
from ..routeros.client import RouterOSV6Client
from ..monitoring.core import TrafficUsageTracker
from ..reporting.checklist import DailyChecklist
from ..reporting.pdf import _card_pdf, _safe_filename
from ..security.policy import TelegramPolicy
from ..security.audit import AuditTrail
LOGGER=logging.getLogger("mikrotik_telegram_bot")

def _rows_text(title: str, rows: list[dict[str,str]]) -> str:
    lines=[title,"="*len(title)]
    for row in rows:
        values=[f"{k}: {v}" for k,v in row.items() if k != "!type"]
        if values: lines.append(" | ".join(values))
    return "\n".join(lines) or title

class CommandRouter:
    HELP = (
        "أوامر المراقبة والتحكم الآمنة (RouterOS v6):\n"
        "/status حالة الاتصال والإصدار ومدة التشغيل\n"
        "/resources موارد الراوتر\n/uptime مدة تشغيل الراوتر\n"
        "/active الجلسات النشطة\n/profiles فئات User Manager\n/users عدد مستخدمي User Manager\n"
        "/interfaces الواجهات\n/checklist تقرير المراقبة اليومية للقراءة فقط\n/usage استهلاك اليوم منذ أول قراءة\n/logs آخر سجلات النظام\n"
        "/card username البحث عن مستخدم وطباعة PDF\n/reboot إعادة التشغيل بعد تأكيد مزدوج\n"
        "/print active|users|profiles|interfaces إرسال النتيجة كملف نصي\n"
        "/help عرض المساعدة"
    )

    def __init__(self, gateway: RouterOSV6Client, telegram: TelegramClient,
                 usage_tracker: TrafficUsageTracker | None = None,
                 checklist: DailyChecklist | None = None, policy=None, audit=None,
                 admin_user_ids: frozenset[str] = frozenset(), recovery_target: str = "1.1.1.1",
                 recovery_attempts: int = 0, recovery_interval_seconds: int = 5) -> None:
        self.gateway = gateway
        self.telegram = telegram
        self.usage_tracker = usage_tracker
        self.checklist = checklist or DailyChecklist(gateway, usage_tracker)
        self.policy = policy
        self.audit = audit
        self.admin_user_ids = admin_user_ids
        self.recovery_target = recovery_target
        self.recovery_attempts = max(0, recovery_attempts)
        self.recovery_interval_seconds = max(2, recovery_interval_seconds)
        self._pending_cards: dict[str, tuple[str, str, list[str], float]] = {}
        self._pending_reboots: dict[str, tuple[str, str, float, str]] = {}

    def _profile_names(self) -> list[str]:
        rows = self.gateway.command(
            "/tool/user-manager/profile/print",
            "=.proplist=name,rate-limit,shared-users,session-timeout",
        )
        names: list[str] = []
        for row in rows:
            name = row.get("name", "").strip()
            if name and name not in names and len(name) <= 48:
                names.append(name)
        return names[:20]

    def _begin_card_print(self, chat_id: str, username: str, user_id: str = "") -> None:
        if not re.fullmatch(r"[A-Za-z0-9_.-]{1,64}", username):
            self.telegram.send_message(chat_id, "رقم أو اسم الكرت غير صالح. أرسل قيمة مثل 554377 فقط.")
            return
        profiles = self._profile_names()
        if not profiles:
            self.telegram.send_message(chat_id, "لم يعثر User Manager v6 على فئات متاحة للطباعة.")
            return
        nonce = hashlib.sha256(f"{chat_id}:{username}:{time.time_ns()}".encode()).hexdigest()[:12]
        self._pending_cards[nonce] = (username, user_id, profiles, time.time() + 300)
        keyboard = [[{"text": name, "callback_data": f"card:{nonce}:{index}"}] for index, name in enumerate(profiles)]
        self.telegram.send_message(
            chat_id,
            f"اختر فئة User Manager للكرت {username}:",
            {"inline_keyboard": keyboard},
        )

    def _cmd_reboot(self, chat_id: str, user_id: str) -> None:
        if user_id not in self.admin_user_ids:
            self.telegram.send_message(chat_id, "ليس لديك صلاحية إعادة تشغيل MikroTik.")
            if self.audit:
                self.audit.record(source="Telegram", user_id=user_id, chat_id=chat_id, command="/reboot", risk="HIGH_RISK", authorization="DENY", confirmation="NOT_REQUESTED", device=self.gateway.address, result="DENIED", duration_ms=0, error_category="admin_required")
            return
        # The nonce binds the short-lived button to the requesting chat and user.
        nonce = hashlib.sha256(f"{chat_id}:{user_id}:{time.time_ns()}".encode()).hexdigest()[:12]
        operation_id = AuditTrail.operation_id()
        self._pending_reboots[nonce] = (chat_id, user_id, time.time() + 60, operation_id)
        keyboard = [[
            {"text": "✅ نعم، أعد التشغيل", "callback_data": f"reboot:{nonce}:confirm"},
            {"text": "❌ إلغاء", "callback_data": f"reboot:{nonce}:cancel"},
        ]]
        self.telegram.send_message(
            chat_id,
            "⚠️ تأكيد إعادة تشغيل MikroTik؟ ستنقطع الشبكة مؤقتًا.",
            {"inline_keyboard": keyboard},
        )
        LOGGER.info("reboot confirmation requested")

    def _handle_reboot_callback(self, chat_id: str, user_id: str, parts: list[str]) -> None:
        if len(parts) != 3 or parts[2] not in {"confirm", "cancel"}:
            self.telegram.send_message(chat_id, "طلب إعادة التشغيل غير صالح.")
            return
        pending = self._pending_reboots.get(parts[1])
        if pending is None or pending[0] != chat_id or pending[1] != user_id or pending[2] < time.time():
            LOGGER.warning("expired or unauthorized reboot callback for chat %s", chat_id)
            self.telegram.send_message(chat_id, "انتهت صلاحية تأكيد إعادة التشغيل. أرسل /reboot مرة أخرى.")
            return
        self._pending_reboots.pop(parts[1], None)
        operation_id = pending[3] if len(pending) > 3 else AuditTrail.operation_id()
        if parts[2] == "cancel":
            LOGGER.info("reboot cancelled for chat %s", chat_id)
            self.telegram.send_message(chat_id, "تم إلغاء إعادة تشغيل MikroTik.")
            return
        LOGGER.warning("confirmed reboot requested for chat %s", chat_id)
        started=time.monotonic()
        try:
            self.gateway.command("/system/reboot")
            if self.audit: self.audit.record(source="Telegram",user_id=user_id,chat_id=chat_id,command="/reboot",risk="HIGH_RISK",authorization="ALLOW",confirmation="CONFIRMED",device=self.gateway.address,result="UNVERIFIED_ROUTER_DISCONNECTION",duration_ms=int((time.monotonic()-started)*1000),operation_id=operation_id)
        except Exception as error:
            if self.audit: self.audit.record(source="Telegram",user_id=user_id,chat_id=chat_id,command="/reboot",risk="HIGH_RISK",authorization="ALLOW",confirmation="CONFIRMED",device=self.gateway.address,result="FAILED",duration_ms=int((time.monotonic()-started)*1000),error_category=type(error).__name__,operation_id=operation_id)
            raise
        self.telegram.send_message(chat_id, "✅ تم إرسال أمر إعادة التشغيل إلى MikroTik. النتيجة غير متحققة بعد؛ سأراقب عودة الجهاز والإنترنت.")
        if self.recovery_attempts > 0:
            import threading
            threading.Thread(target=self._recover_after_reboot, args=(chat_id, user_id, operation_id), daemon=True, name="routeros-recovery").start()

    def _recover_after_reboot(self, chat_id: str, user_id: str, operation_id: str) -> None:
        for attempt in range(1, self.recovery_attempts + 1):
            time.sleep(self.recovery_interval_seconds)
            try:
                self.gateway.close()
                rows = self.gateway.command("/system/resource/print", "=.proplist=uptime,version")
                router_online = any(row.get("!type") == "!re" for row in rows)
                if not router_online:
                    continue
                ping_rows = self.gateway.command("/ping", f"=address={self.recovery_target}", "=count=2")
                replies = [row for row in ping_rows if row.get("!type") == "!re"]
                internet_online = any(row.get("status", "").lower() != "timeout" for row in replies)
                state = "ONLINE" if internet_online else "INTERNET_DOWN"
                if self.audit:
                    self.audit.record(source="Telegram", user_id=user_id, chat_id=chat_id, command="/reboot/recovery", risk="HIGH_RISK", authorization="ALLOW", confirmation="CONFIRMED", device=self.gateway.address, result=state, duration_ms=0, operation_id=operation_id)
                self.telegram.send_message(chat_id, "✅ عاد MikroTik للعمل؛ الإنترنت متاح." if internet_online else "🟡 عاد MikroTik للعمل؛ الإنترنت ما زال غير متاح.")
                return
            except Exception:
                continue
        if self.audit:
            self.audit.record(source="Telegram", user_id=user_id, chat_id=chat_id, command="/reboot/recovery", risk="HIGH_RISK", authorization="ALLOW", confirmation="CONFIRMED", device=self.gateway.address, result="ROUTER_OFFLINE", duration_ms=0, operation_id=operation_id, error_category="recovery_timeout")
        self.telegram.send_message(chat_id, "⚠️ لم يعد MikroTik متاحًا عبر API ضمن نافذة المراقبة.")

    def handle_callback(self, chat_id: str, user_id: str, callback_id: str, data: str) -> None:
        self.telegram.answer_callback_query(callback_id)
        parts = data.split(":")
        if parts and parts[0] == "reboot":
            self._handle_reboot_callback(chat_id, user_id, parts)
            return
        if len(parts) != 3 or parts[0] != "card":
            self.telegram.send_message(chat_id, "اختيار الطباعة غير صالح أو منتهي.")
            return
        pending = self._pending_cards.get(parts[1])
        try:
            profile_index = int(parts[2])
        except ValueError:
            profile_index = -1
        if pending is None or pending[1] != user_id or pending[3] < time.time() or not 0 <= profile_index < len(pending[2]):
            self.telegram.send_message(chat_id, "انتهت صلاحية اختيار الفئة أو الحساب غير مصرح له. أرسل رقم الكرت مرة أخرى.")
            return
        self._pending_cards.pop(parts[1], None)
        username, _, profiles, _ = pending
        profile_name = profiles[profile_index]
        rows = self.gateway.command("/tool/user-manager/user/print", f"?username={username}")
        found = any(row.get("username", "") == username for row in rows)
        if not found:
            self.telegram.send_message(chat_id, f"لم يعثر User Manager على الكرت {username}.")
            return
        pdf = _card_pdf(username, profile_name)
        filename = f"card-{_safe_filename(username)}-{_safe_filename(profile_name)}.pdf"
        self.telegram.send_document(chat_id, filename, pdf)
        self.telegram.send_message(chat_id, f"تم تجهيز بطاقة {username} بفئة {profile_name} وإرسالها للطباعة.")

    def handle(self, chat_id: str, user_id: str, text: str) -> None:
        parts = text.strip().split(maxsplit=1)
        command = parts[0].lower().split("@", 1)[0] if parts else "/help"
        argument = parts[1].strip() if len(parts) > 1 else ""
        if re.fullmatch(r"[A-Za-z0-9_.-]{1,64}", text.strip()) and not text.strip().startswith("/"):
            self._begin_card_print(chat_id, text.strip(), user_id)
            return
        if self.policy is not None:
            rule=self.policy.rule_for(command)
            if rule is None:
                self.telegram.send_message(chat_id, "الأمر غير معروف. استخدم /help")
                return
        if command in {"/start", "/help"}:
            self.telegram.send_message(chat_id, self.HELP)
            return
        if command == "/status":
            rows = self.gateway.command("/system/resource/print", "=.proplist=uptime,version,cpu-load,free-memory,total-memory")
            self.telegram.send_message(chat_id, _rows_text("حالة RouterOS v6", rows))
            return
        if command == "/resources":
            rows = self.gateway.command("/system/resource/print", "=.proplist=uptime,version,cpu-load,free-memory,total-memory")
            self.telegram.send_message(chat_id, _rows_text("موارد الراوتر", rows))
            return
        if command == "/uptime":
            rows = self.gateway.command("/system/resource/print", "=.proplist=uptime")
            self.telegram.send_message(chat_id, _rows_text("مدة تشغيل MikroTik", rows))
            return
        if command == "/active":
            rows = self.gateway.command("/tool/user-manager/session/print", "=.proplist=user,session-time-left,framed-ip-address,uptime")
            self.telegram.send_message(chat_id, _rows_text("جلسات User Manager النشطة", rows))
            return
        if command == "/users":
            rows = self.gateway.command("/tool/user-manager/user/print", "=.proplist=.id")
            count = sum(1 for row in rows if row.get("!type") == "!re")
            self.telegram.send_message(chat_id, f"عدد مستخدمي User Manager: {count}")
            return
        if command == "/profiles":
            rows = self.gateway.command("/tool/user-manager/profile/print", "=.proplist=name,rate-limit,shared-users,session-timeout")
            self.telegram.send_message(chat_id, _rows_text("فئات User Manager", rows))
            return
        if command == "/interfaces":
            rows = self.gateway.command("/interface/print", "=.proplist=name,running,disabled,type")
            self.telegram.send_message(chat_id, _rows_text("واجهات MikroTik", rows))
            return
        if command == "/checklist":
            report = self.checklist.collect()
            self.telegram.send_message(chat_id, DailyChecklist.render(report))
            return
        if command == "/usage":
            if self.usage_tracker is None:
                self.telegram.send_message(chat_id, "مراقبة الاستهلاك غير مهيأة في إعدادات الجسر.")
                return
            self.telegram.send_message(chat_id, TrafficUsageTracker.report(self.usage_tracker.snapshot()))
            return
        if command == "/logs":
            rows = self.gateway.command("/log/print", "=.proplist=time,topics,message")
            self.telegram.send_message(chat_id, _rows_text("آخر سجلات MikroTik", rows[-20:]))
            return
        if command == "/reboot":
            self._cmd_reboot(chat_id, user_id)
            return
        if command == "/card":
            if not argument:
                self.telegram.send_message(chat_id, "استخدم: /card username أو أرسل رقم الكرت مباشرة مثل 554377")
                return
            self._begin_card_print(chat_id, argument, user_id)
            return
        if command == "/print":
            targets = {"active": ("جلسات User Manager", "/tool/user-manager/session/print"),
                       "users": ("مستخدمو User Manager", "/tool/user-manager/user/print"),
                       "profiles": ("فئات User Manager", "/tool/user-manager/profile/print"),
                       "interfaces": ("واجهات MikroTik", "/interface/print")}
            if argument not in targets:
                self.telegram.send_message(chat_id, "استخدم: /print active|users|profiles|interfaces")
                return
            title, path = targets[argument]
            rows = self.gateway.command(path, "=.proplist=.id,name,username,user,rate-limit,shared-users,session-time-left,framed-ip-address,uptime,running,disabled,type")
            self.telegram.send_document(chat_id, f"mikrotik-{argument}.txt", _rows_text(title, rows))
            return
        self.telegram.send_message(chat_id, "الأمر غير معروف. استخدم /help")