from __future__ import annotations

import hashlib
import logging
import secrets
import string
import threading
import time
from typing import Any, Callable

from ..monitoring.core import TrafficUsageTracker
from ..reporting.checklist import DailyChecklist
from ..reporting.export import report_html, report_pdf
from ..reporting.pdf import _card_pdf, _safe_filename
from ..routeros.operations import RouterOSOperations, validate_username
from ..routeros.client import RouterOSV6Client
from ..security.audit import AuditTrail
from ..security.policy import TelegramPolicy
from ..telegram.client import TelegramClient

LOGGER = logging.getLogger("mikrotik_telegram_bot")


def _rows_text(title: str, rows: list[dict[str, Any]]) -> str:
    lines = [title, "=" * len(title)]
    for row in rows[:200]:
        values = [f"{key}: {value}" for key, value in row.items() if key != "!type"]
        if values:
            lines.append(" | ".join(values))
    return "\n".join(lines) or title


def _dict_text(title: str, values: dict[str, Any]) -> str:
    lines = [title, "=" * len(title)]
    for key, value in values.items():
        if isinstance(value, dict):
            value = ", ".join(f"{k}={v}" for k, v in value.items())
        lines.append(f"{key}: {value}")
    return "\n".join(lines)


class CommandRouter:
    HELP = (
        "أوامر Telegram Bot المباشر عبر RouterOS API/API-SSL:\n"
        "/status حالة الراوتر والموارد\n/internet حالة الراوتر والإنترنت\n"
        "/resources و /uptime موارد ومدة التشغيل\n/interfaces الواجهات\n"
        "/active الجلسات النشطة\n/sessions [username] جلسات مستخدم\n"
        "/users و /profiles مستخدمو وفئات User Manager\n/user-manager ملخص User Manager\n"
        "/card username و /check username فحص بطاقة\n/card-create username profile إنشاء بطاقة بعد تأكيد Admin\n/c200 [profile] إنشاء بطاقة تلقائية بعد تأكيد Admin\n/delete-expired و /clean معاينة ثم حذف المنتهية بعد تأكيد Admin\n"
        "/usage استهلاك الواجهة\n/logs آخر سجلات النظام\n"
        "/report html|pdf تقرير قابل للإرسال\n/sales تقرير تشغيلي للمخزون حسب العميل والفئة\n"
        "/print active|users|profiles|interfaces إرسال بيانات محدودة\n/reboot إعادة التشغيل بعد تأكيد Admin\n/help عرض هذه المساعدة"
    )

    def __init__(
        self,
        gateway: RouterOSV6Client,
        telegram: TelegramClient,
        usage_tracker: TrafficUsageTracker | None = None,
        checklist: DailyChecklist | None = None,
        policy: TelegramPolicy | None = None,
        audit: AuditTrail | None = None,
        admin_user_ids: frozenset[str] = frozenset(),
        recovery_target: str = "1.1.1.1",
        recovery_attempts: int = 0,
        recovery_interval_seconds: int = 5,
        user_manager_customer: str = "admin",
    ) -> None:
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
        self.operations = RouterOSOperations(gateway, user_manager_customer)
        self._pending_cards: dict[str, tuple[str, str, list[str], float]] = {}
        self._pending_reboots: dict[str, tuple[str, str, float, str]] = {}
        self._pending_creates: dict[str, tuple[str, str, str, str, str, float, str]] = {}
        self._pending_deletes: dict[str, tuple[str, str, list[dict[str, str]], float, str]] = {}

    def _audit(self, **values: Any) -> None:
        if self.audit is not None:
            self.audit.record(**values)

    def _read_or_report(self, chat_id: str, title: str, operation: Callable[[], Any]) -> Any | None:
        try:
            return operation()
        except Exception as error:
            LOGGER.warning("read operation failed for %s: %s", title, type(error).__name__)
            self.telegram.send_message(chat_id, f"تعذر قراءة {title} بأمان.")
            return None

    @staticmethod
    def _nonce(*parts: str) -> str:
        return hashlib.sha256(":".join(parts + (str(time.time_ns()),)).encode()).hexdigest()[:12]

    @staticmethod
    def _generated_password() -> str:
        alphabet = string.ascii_letters + string.digits
        return "".join(secrets.choice(alphabet) for _ in range(12))

    @staticmethod
    def _generated_username() -> str:
        alphabet = string.ascii_lowercase + string.digits
        return "c" + "".join(secrets.choice(alphabet) for _ in range(8))

    def _begin_card_print(self, chat_id: str, username: str, user_id: str = "") -> None:
        try:
            username = validate_username(username)
        except ValueError:
            self.telegram.send_message(chat_id, "اسم الكرت غير صالح. استخدم أحرفًا وأرقامًا و._- فقط.")
            return
        profiles = self._read_or_report(chat_id, "فئات User Manager", self.operations.profiles)
        if not profiles:
            self.telegram.send_message(chat_id, "لم يعثر User Manager على فئات متاحة للطباعة.")
            return
        profile_names = [str(row.get("name", "")).strip() for row in profiles if row.get("name")]
        profile_names = [name for name in profile_names if len(name) <= 48][:20]
        if not profile_names:
            self.telegram.send_message(chat_id, "لا توجد فئات صالحة للطباعة.")
            return
        nonce = self._nonce(chat_id, username, user_id)
        self._pending_cards[nonce] = (username, user_id, profile_names, time.time() + 300)
        keyboard = [[{"text": name, "callback_data": f"card:{nonce}:{index}"}] for index, name in enumerate(profile_names)]
        self.telegram.send_message(chat_id, f"اختر فئة User Manager للكرت {username}:", {"inline_keyboard": keyboard})

    def _begin_create(self, chat_id: str, user_id: str, argument: str, command_name: str = "/card-create") -> None:
        fields = argument.split()
        if len(fields) != 2:
            self.telegram.send_message(chat_id, "الاستخدام الآمن: /card-create username profile\nسيولد البوت كلمة مرور عشوائية بعد التأكيد.")
            return
        try:
            username = validate_username(fields[0])
            profile = validate_username(fields[1])
        except ValueError:
            self.telegram.send_message(chat_id, "اسم المستخدم والفئة يجب أن يستخدما أحرفًا وأرقامًا و._- فقط.")
            return
        operation_id = AuditTrail.operation_id()
        nonce = self._nonce(chat_id, user_id, username, operation_id)
        self._pending_creates[nonce] = (chat_id, user_id, username, profile, self._generated_password(), time.time() + 120, operation_id)
        self._audit(source="Telegram", user_id=user_id, chat_id=chat_id,             command=command_name, risk="HIGH_RISK", authorization="ALLOW", confirmation="PENDING", device=self.gateway.address, result="AWAITING_CONFIRMATION", duration_ms=0, operation_id=operation_id)

        keyboard = [[
            {"text": "✅ إنشاء البطاقة", "callback_data": f"create-card:{nonce}:confirm"},
            {"text": "❌ إلغاء", "callback_data": f"create-card:{nonce}:cancel"},
        ]]
        self.telegram.send_message(chat_id, f"تأكيد إنشاء البطاقة {username} بالفئة {profile}؟ سيولد البوت كلمة مرور عشوائية.", {"inline_keyboard": keyboard})

    def _begin_delete_expired(self, chat_id: str, user_id: str, command_name: str = "/delete-expired") -> None:
        try:
            expired = self.operations.expired_users()
        except Exception as error:
            LOGGER.warning("expired-user preview failed: %s", type(error).__name__)
            self.telegram.send_message(chat_id, "تعذر إنشاء معاينة الحذف بأمان.")
            return
        if not expired:
            self.telegram.send_message(chat_id, "لم يعثر البوت على مستخدمين منتهيين بتاريخ قابل للتحقق. لم يُحذف شيء.")
            return
        operation_id = AuditTrail.operation_id()
        nonce = self._nonce(chat_id, user_id, operation_id)
        self._pending_deletes[nonce] = (chat_id, user_id, expired[:100], time.time() + 120, operation_id)
        names = ", ".join(row.get("username", "?") for row in expired[:20])
        more = " …" if len(expired) > 20 else ""
        self._audit(source="Telegram", user_id=user_id, chat_id=chat_id,             command=command_name, risk="HIGH_RISK", authorization="ALLOW", confirmation="PENDING", device=self.gateway.address, result="AWAITING_CONFIRMATION", duration_ms=0, operation_id=operation_id)

        keyboard = [[
            {"text": "✅ حذف القائمة", "callback_data": f"delete-expired:{nonce}:confirm"},
            {"text": "❌ إلغاء", "callback_data": f"delete-expired:{nonce}:cancel"},
        ]]
        self.telegram.send_message(chat_id, f"معاينة: {len(expired)} مستخدم منتهٍ ({names}{more}). هل تريد الحذف؟", {"inline_keyboard": keyboard})

    def _cmd_reboot(self, chat_id: str, user_id: str) -> None:
        if user_id not in self.admin_user_ids:
            self.telegram.send_message(chat_id, "ليس لديك صلاحية إعادة تشغيل MikroTik.")
            self._audit(source="Telegram", user_id=user_id, chat_id=chat_id, command="/reboot", risk="HIGH_RISK", authorization="DENY", confirmation="NOT_REQUESTED", device=self.gateway.address, result="DENIED", duration_ms=0, error_category="admin_required")
            return
        nonce = self._nonce(chat_id, user_id)
        operation_id = AuditTrail.operation_id()
        self._pending_reboots[nonce] = (chat_id, user_id, time.time() + 60, operation_id)
        self._audit(source="Telegram", user_id=user_id, chat_id=chat_id, command="/reboot", risk="HIGH_RISK", authorization="ALLOW", confirmation="PENDING", device=self.gateway.address, result="AWAITING_CONFIRMATION", duration_ms=0, operation_id=operation_id)
        keyboard = [[
            {"text": "✅ نعم، أعد التشغيل", "callback_data": f"reboot:{nonce}:confirm"},
            {"text": "❌ إلغاء", "callback_data": f"reboot:{nonce}:cancel"},
        ]]
        self.telegram.send_message(chat_id, "تأكيد إعادة تشغيل MikroTik؟ ستنقطع الشبكة مؤقتًا.", {"inline_keyboard": keyboard})

    def _handle_reboot_callback(self, chat_id: str, user_id: str, parts: list[str]) -> None:
        if len(parts) != 3 or parts[2] not in {"confirm", "cancel"}:
            self.telegram.send_message(chat_id, "طلب إعادة التشغيل غير صالح.")
            return
        pending = self._pending_reboots.get(parts[1])
        if pending is None or pending[0] != chat_id or pending[1] != user_id or pending[2] < time.time() or user_id not in self.admin_user_ids:
            self.telegram.send_message(chat_id, "انتهت صلاحية تأكيد إعادة التشغيل أو لا يطابق المستخدم المصرح له.")
            return
        self._pending_reboots.pop(parts[1], None)
        operation_id = pending[3]
        if parts[2] == "cancel":
            self._audit(source="Telegram", user_id=user_id, chat_id=chat_id, command="/reboot", risk="HIGH_RISK", authorization="ALLOW", confirmation="CANCELLED", device=self.gateway.address, result="CANCELLED", duration_ms=0, operation_id=operation_id)
            self.telegram.send_message(chat_id, "تم إلغاء إعادة تشغيل MikroTik.")
            return
        started = time.monotonic()
        try:
            self.operations.reboot()
            self._audit(source="Telegram", user_id=user_id, chat_id=chat_id, command="/reboot", risk="HIGH_RISK", authorization="ALLOW", confirmation="CONFIRMED", device=self.gateway.address, result="UNVERIFIED_ROUTER_DISCONNECTION", duration_ms=int((time.monotonic() - started) * 1000), operation_id=operation_id)
        except Exception as error:
            self._audit(source="Telegram", user_id=user_id, chat_id=chat_id, command="/reboot", risk="HIGH_RISK", authorization="ALLOW", confirmation="CONFIRMED", device=self.gateway.address, result="FAILED", duration_ms=int((time.monotonic() - started) * 1000), error_category=type(error).__name__, operation_id=operation_id)
            raise
        self.telegram.send_message(chat_id, "تم إرسال أمر إعادة التشغيل. النتيجة غير متحققة بعد؛ ستصل حالة العودة والإنترنت عند انتهاء المراقبة.")
        if self.recovery_attempts > 0:
            threading.Thread(target=self._recover_after_reboot, args=(chat_id, user_id, operation_id), daemon=True, name="routeros-recovery").start()

    def _handle_create_callback(self, chat_id: str, user_id: str, parts: list[str]) -> None:
        pending = self._pending_creates.get(parts[1]) if len(parts) == 3 else None
        if pending is None or pending[0] != chat_id or pending[1] != user_id or pending[5] < time.time() or parts[2] not in {"confirm", "cancel"}:
            self.telegram.send_message(chat_id, "انتهت صلاحية إنشاء البطاقة أو لا يطابق المستخدم المصرح له.")
            return
        self._pending_creates.pop(parts[1], None)
        _, _, username, profile, password, _, operation_id = pending
        if parts[2] == "cancel":
            self._audit(source="Telegram", user_id=user_id, chat_id=chat_id, command="/card-create", risk="HIGH_RISK", authorization="ALLOW", confirmation="CANCELLED", device=self.gateway.address, result="CANCELLED", duration_ms=0, operation_id=operation_id)
            self.telegram.send_message(chat_id, "تم إلغاء إنشاء البطاقة.")
            return
        started = time.monotonic()
        try:
            created = self.operations.create_card(username, password, profile)
            self._audit(source="Telegram", user_id=user_id, chat_id=chat_id, command="/card-create", risk="HIGH_RISK", authorization="ALLOW", confirmation="CONFIRMED", device=self.gateway.address, result="SUCCESS", duration_ms=int((time.monotonic() - started) * 1000), operation_id=operation_id)
        except Exception as error:
            self._audit(source="Telegram", user_id=user_id, chat_id=chat_id, command="/card-create", risk="HIGH_RISK", authorization="ALLOW", confirmation="CONFIRMED", device=self.gateway.address, result="FAILED", duration_ms=int((time.monotonic() - started) * 1000), error_category=type(error).__name__, operation_id=operation_id)
            raise
        self.telegram.send_message(chat_id, f"تم إنشاء البطاقة {created['username']} بالفئة {created['profile']}.\nكلمة المرور المؤقتة: {password}\nاحفظها بأمان؛ لا تُسجل في Audit.")

    def _handle_delete_callback(self, chat_id: str, user_id: str, parts: list[str]) -> None:
        pending = self._pending_deletes.get(parts[1]) if len(parts) == 3 else None
        if pending is None or pending[0] != chat_id or pending[1] != user_id or pending[3] < time.time() or parts[2] not in {"confirm", "cancel"}:
            self.telegram.send_message(chat_id, "انتهت صلاحية الحذف أو لا يطابق المستخدم المصرح له.")
            return
        self._pending_deletes.pop(parts[1], None)
        _, _, users, _, operation_id = pending
        if parts[2] == "cancel":
            self._audit(source="Telegram", user_id=user_id, chat_id=chat_id, command="/delete-expired", risk="HIGH_RISK", authorization="ALLOW", confirmation="CANCELLED", device=self.gateway.address, result="CANCELLED", duration_ms=0, operation_id=operation_id)
            self.telegram.send_message(chat_id, "تم إلغاء حذف البطاقات المنتهية.")
            return
        started = time.monotonic()
        try:
            deleted = self.operations.delete_users(users)
            self._audit(source="Telegram", user_id=user_id, chat_id=chat_id, command="/delete-expired", risk="HIGH_RISK", authorization="ALLOW", confirmation="CONFIRMED", device=self.gateway.address, result=f"DELETED_{deleted}", duration_ms=int((time.monotonic() - started) * 1000), operation_id=operation_id)
        except Exception as error:
            self._audit(source="Telegram", user_id=user_id, chat_id=chat_id, command="/delete-expired", risk="HIGH_RISK", authorization="ALLOW", confirmation="CONFIRMED", device=self.gateway.address, result="FAILED", duration_ms=int((time.monotonic() - started) * 1000), error_category=type(error).__name__, operation_id=operation_id)
            raise
        self.telegram.send_message(chat_id, f"تم حذف {deleted} بطاقة منتهية بعد التأكيد.")

    def _recover_after_reboot(self, chat_id: str, user_id: str, operation_id: str) -> None:
        for _ in range(1, self.recovery_attempts + 1):
            time.sleep(self.recovery_interval_seconds)
            try:
                self.gateway.close()
                state = self.operations.internet(self.recovery_target)
                if state == "ROUTER_OFFLINE":
                    continue
                self._audit(source="Telegram", user_id=user_id, chat_id=chat_id, command="/reboot/recovery", risk="HIGH_RISK", authorization="ALLOW", confirmation="CONFIRMED", device=self.gateway.address, result=state, duration_ms=0, operation_id=operation_id)
                self.telegram.send_message(chat_id, "عاد MikroTik للعمل؛ الإنترنت متاح." if state == "ONLINE" else "عاد MikroTik للعمل؛ الإنترنت ما زال غير متاح.")
                return
            except Exception:
                continue
        self._audit(source="Telegram", user_id=user_id, chat_id=chat_id, command="/reboot/recovery", risk="HIGH_RISK", authorization="ALLOW", confirmation="CONFIRMED", device=self.gateway.address, result="ROUTER_OFFLINE", duration_ms=0, error_category="recovery_timeout", operation_id=operation_id)
        self.telegram.send_message(chat_id, "لم يعد MikroTik متاحًا عبر API ضمن نافذة المراقبة.")

    def handle_callback(self, chat_id: str, user_id: str, callback_id: str, data: str) -> None:
        self.telegram.answer_callback_query(callback_id)
        parts = data.split(":")
        if parts and parts[0] == "reboot":
            self._handle_reboot_callback(chat_id, user_id, parts)
            return
        if parts and parts[0] == "create-card":
            self._handle_create_callback(chat_id, user_id, parts)
            return
        if parts and parts[0] == "delete-expired":
            self._handle_delete_callback(chat_id, user_id, parts)
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
            self.telegram.send_message(chat_id, "انتهت صلاحية اختيار الفئة أو الحساب غير مصرح له.")
            return
        self._pending_cards.pop(parts[1], None)
        username, _, profiles, _ = pending
        profile_name = profiles[profile_index]
        user = self._read_or_report(chat_id, "البطاقة", lambda: self.operations.user(username))
        if user is None:
            self.telegram.send_message(chat_id, f"لم يعثر User Manager على الكرت {username}.")
            return
        pdf = _card_pdf(username, profile_name)
        filename = f"card-{_safe_filename(username)}-{_safe_filename(profile_name)}.pdf"
        self.telegram.send_document(chat_id, filename, pdf)
        self.telegram.send_message(chat_id, f"تم تجهيز بطاقة {username} بالفئة {profile_name} وإرسالها للطباعة.")

    def _send_report(self, chat_id: str, fmt: str) -> None:
        data = {
            "الحالة": self.operations.status(),
            "ملخص User Manager": self.operations.user_manager_summary(),
            "الجلسات النشطة": self.operations.active_sessions(),
            "الواجهات": self.operations.interfaces(),
            "المبيعات التشغيلية": self.operations.sales_summary(),
        }
        sections = list(data.items())
        if fmt == "html":
            self.telegram.send_document(chat_id, "mikrotik-report.html", report_html("تقرير MikroTik", sections))
        else:
            self.telegram.send_document(chat_id, "mikrotik-report.pdf", report_pdf("تقرير MikroTik", sections))

    def handle(self, chat_id: str, user_id: str, text: str) -> None:
        parts = text.strip().split(maxsplit=1)
        command = parts[0].lower().split("@", 1)[0] if parts else "/help"
        argument = parts[1].strip() if len(parts) > 1 else ""
        if text.strip() and not text.strip().startswith("/"):
            self._begin_card_print(chat_id, text.strip(), user_id)
            return
        if self.policy is not None and self.policy.rule_for(command) is None:
            self.telegram.send_message(chat_id, "الأمر غير معروف. استخدم /help")
            return
        if command in {"/start", "/help"}:
            self.telegram.send_message(chat_id, self.HELP)
        elif command == "/status":
            result = self._read_or_report(chat_id, "حالة الراوتر", self.operations.status)
            if result is not None:
                self.telegram.send_message(chat_id, _dict_text("حالة RouterOS", result))
        elif command == "/internet":
            state = self._read_or_report(chat_id, "حالة الإنترنت", lambda: self.operations.internet(self.recovery_target))
            if state is not None:
                self.telegram.send_message(chat_id, f"حالة الاتصال: {state}")
        elif command in {"/resources", "/uptime"}:
            status = self._read_or_report(chat_id, "موارد الراوتر", self.operations.status)
            if status is not None:
                resource = status.get("resource", {})
                if command == "/uptime":
                    resource = {"uptime": resource.get("uptime", "غير متاح")}
                self.telegram.send_message(chat_id, _dict_text("موارد MikroTik", resource))
        elif command == "/active":
            rows = self._read_or_report(chat_id, "الجلسات النشطة", self.operations.active_sessions)
            if rows is not None:
                self.telegram.send_message(chat_id, _rows_text("جلسات User Manager النشطة", rows))
        elif command == "/sessions":
            rows = self._read_or_report(chat_id, "الجلسات", lambda: self.operations.sessions_for_user(argument) if argument else self.operations.active_sessions())
            if rows is not None:
                self.telegram.send_message(chat_id, _rows_text("جلسات المستخدم" if argument else "الجلسات النشطة", rows))
        elif command == "/users":
            rows = self._read_or_report(chat_id, "المستخدمين", self.operations.users)
            if rows is not None:
                self.telegram.send_message(chat_id, f"عدد مستخدمي User Manager: {len(rows)}")
        elif command == "/profiles":
            rows = self._read_or_report(chat_id, "الفئات", self.operations.profiles)
            if rows is not None:
                self.telegram.send_message(chat_id, _rows_text("فئات User Manager", rows))
        elif command == "/user-manager":
            result = self._read_or_report(chat_id, "ملخص User Manager", self.operations.user_manager_summary)
            if result is not None:
                self.telegram.send_message(chat_id, _dict_text("ملخص User Manager", result))
        elif command == "/interfaces":
            rows = self._read_or_report(chat_id, "الواجهات", self.operations.interfaces)
            if rows is not None:
                self.telegram.send_message(chat_id, _rows_text("واجهات MikroTik", rows))
        elif command == "/checklist":
            report = self._read_or_report(chat_id, "قائمة الفحص", self.checklist.collect)
            if report is not None:
                self.telegram.send_message(chat_id, DailyChecklist.render(report))
        elif command == "/usage":
            if self.usage_tracker is None:
                self.telegram.send_message(chat_id, "مراقبة الاستهلاك غير مهيأة.")
            else:
                self.telegram.send_message(chat_id, TrafficUsageTracker.report(self.usage_tracker.snapshot()))
        elif command == "/logs":
            rows = self._read_or_report(chat_id, "السجلات", self.operations.logs)
            if rows is not None:
                self.telegram.send_message(chat_id, _rows_text("آخر سجلات MikroTik", rows))
        elif command in {"/card", "/card-check", "/check"}:
            if not argument:
                self.telegram.send_message(chat_id, "استخدم: /card username أو /card-check username")
            elif command in {"/card-check", "/check"}:
                user = self._read_or_report(chat_id, "البطاقة", lambda: self.operations.user(argument))
                self.telegram.send_message(chat_id, _dict_text("فحص البطاقة", user) if user else "لم يعثر User Manager على البطاقة.")
            else:
                self._begin_card_print(chat_id, argument, user_id)
        elif command == "/card-usage":
            if not argument:
                self.telegram.send_message(chat_id, "استخدم: /card-usage username")
            else:
                result = self._read_or_report(chat_id, "استهلاك البطاقة", lambda: self.operations.card_usage(argument))
                if result is not None:
                    self.telegram.send_message(chat_id, _dict_text("استهلاك وجلسات البطاقة", result))
        elif command in {"/card-create", "/c200"}:
            if user_id not in self.admin_user_ids:
                self.telegram.send_message(chat_id, "إنشاء البطاقات متاح للمسؤولين فقط.")
                return
            if command == "/c200":
                fields = argument.split()
                if len(fields) > 1:
                    self.telegram.send_message(chat_id, "استخدم: /c200 أو /c200 profile")
                    return
                profile = fields[0] if fields else "default"
                self._begin_create(chat_id, user_id, f"{self._generated_username()} {profile}", "/c200")
            else:
                self._begin_create(chat_id, user_id, argument)
        elif command in {"/delete-expired", "/clean"}:
            if user_id not in self.admin_user_ids:
                self.telegram.send_message(chat_id, "حذف البطاقات متاح للمسؤولين فقط.")
                return
            self._begin_delete_expired(chat_id, user_id, command)
        elif command == "/reboot":
            self._cmd_reboot(chat_id, user_id)
        elif command == "/print":
            targets = {
                "active": ("جلسات User Manager", self.operations.active_sessions),
                "users": ("مستخدمو User Manager", self.operations.users),
                "profiles": ("فئات User Manager", self.operations.profiles),
                "interfaces": ("واجهات MikroTik", self.operations.interfaces),
            }
            if argument not in targets:
                self.telegram.send_message(chat_id, "استخدم: /print active|users|profiles|interfaces")
            else:
                title, operation = targets[argument]
                rows = self._read_or_report(chat_id, title, operation)
                if rows is not None:
                    self.telegram.send_document(chat_id, f"mikrotik-{argument}.txt", _rows_text(title, rows))
        elif command == "/report":
            fmt = (argument or "pdf").lower()
            if fmt not in {"html", "pdf"}:
                self.telegram.send_message(chat_id, "استخدم: /report html أو /report pdf")
            else:
                self._send_report(chat_id, fmt)
        elif command == "/sales":
            result = self._read_or_report(chat_id, "تقرير المبيعات التشغيلي", self.operations.sales_summary)
            if result is not None:
                note = "تتوفر أسعار في البيانات." if result.get("revenue_available") else "لا توجد أسعار موثقة؛ التقرير عددي تشغيلي وليس تقرير إيرادات."
                self.telegram.send_message(chat_id, _dict_text("تقرير المبيعات التشغيلي", {**result, "ملاحظة": note}))
        else:
            self.telegram.send_message(chat_id, "الأمر غير معروف. استخدم /help")
