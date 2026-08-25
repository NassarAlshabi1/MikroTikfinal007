from __future__ import annotations
import logging
from typing import Any
from ..routeros.client import RouterOSV6Client
from ..monitoring.core import TrafficUsageTracker
from ..common import TelegramBotError
LOGGER=logging.getLogger("mikrotik_telegram_bot")

class DailyChecklist:
    """Collect a bounded, read-only health report for RouterOS v6."""

    def __init__(self, gateway: RouterOSV6Client,
                 usage_tracker: TrafficUsageTracker | None = None) -> None:
        self.gateway = gateway
        self.usage_tracker = usage_tracker

    def _read(self, label: str, path: str, *arguments: str,
              errors: list[str]) -> list[dict[str, str]]:
        try:
            rows = self.gateway.command(path, *arguments)
            return [row for row in rows if row.get("!type") == "!re"]
        except Exception as error:
            LOGGER.warning("checklist read failed for %s: %s", label, type(error).__name__)
            errors.append(label)
            return []

    def collect(self) -> dict[str, Any]:
        errors: list[str] = []
        resources = self._read(
            "الموارد", "/system/resource/print",
            "=.proplist=uptime,version,cpu-load,free-memory,total-memory",
            errors=errors,
        )
        interfaces = self._read(
            "الواجهات", "/interface/print",
            "=.proplist=name,running,disabled,type",
            errors=errors,
        )
        leases = self._read(
            "أجهزة DHCP", "/ip/dhcp-server/lease/print",
            "=.proplist=address,mac-address,status,host-name",
            errors=errors,
        )
        sessions = self._read(
            "جلسات User Manager", "/tool/user-manager/session/print",
            "=.proplist=user,uptime,session-time-left,framed-ip-address",
            errors=errors,
        )
        users = self._read(
            "مستخدمو User Manager", "/tool/user-manager/user/print",
            "=.proplist=.id",
            errors=errors,
        )
        services = self._read(
            "خدمات API", "/ip/service/print",
            "=.proplist=name,disabled,port,address",
            errors=errors,
        )
        logs = self._read(
            "السجلات", "/log/print",
            "=.proplist=time,topics,message",
            errors=errors,
        )[-5:]
        usage: dict[str, Any] | None = None
        if self.usage_tracker is not None:
            try:
                usage = self.usage_tracker.snapshot()
            except Exception as error:
                LOGGER.warning("checklist usage read failed: %s", type(error).__name__)
                errors.append("الاستهلاك")
        running_interfaces = [
            row for row in interfaces
            if row.get("disabled", "no").lower() != "yes"
            and row.get("running", "no").lower() == "yes"
        ]
        bound_leases = [row for row in leases if row.get("status", "").lower() == "bound"]
        enabled_api_services = [
            row for row in services
            if row.get("name", "").lower() in {"api", "api-ssl"}
            and row.get("disabled", "no").lower() != "yes"
        ]
        return {
            "resources": resources[0] if resources else {},
            "interfaces_total": len(interfaces),
            "interfaces_running": len(running_interfaces),
            "dhcp_total": len(leases),
            "dhcp_bound": len(bound_leases),
            "sessions": len(sessions),
            "users": len(users),
            "api_services": enabled_api_services,
            "logs": logs,
            "usage": usage,
            "errors": errors,
        }

    @staticmethod
    def render(report: dict[str, Any]) -> str:
        resources = report.get("resources", {})
        lines = [
            "Daily Checklist — MikroTik RouterOS v6",
            "=" * 38,
            f"الإصدار: {resources.get('version', 'غير متاح')}",
            f"مدة التشغيل: {resources.get('uptime', 'غير متاح')}",
            f"المعالج: {resources.get('cpu-load', 'غير متاح')}%",
            f"الذاكرة: {resources.get('free-memory', 'غير متاح')} متاحة من {resources.get('total-memory', 'غير متاح')}",
            "",
            "المؤشرات:",
            f"- الواجهات: {report.get('interfaces_running', 0)} نشطة من {report.get('interfaces_total', 0)}",
            f"- DHCP: {report.get('dhcp_bound', 0)} جهازاً مرتبطاً من {report.get('dhcp_total', 0)}",
            f"- جلسات User Manager النشطة: {report.get('sessions', 0)}",
            f"- مستخدمو User Manager: {report.get('users', 0)}",
        ]
        api_services = report.get("api_services", [])
        if api_services:
            api_text = ", ".join(
                f"{row.get('name', 'api')}:{row.get('port', '?')}"
                for row in api_services
            )
        else:
            api_text = "لا توجد خدمة API مفعلة ظاهرة"
        lines.append(f"- خدمات API المفعلة: {api_text}")

        usage = report.get("usage")
        if usage is not None:
            lines.extend(["", TrafficUsageTracker.report(usage)])
        else:
            lines.extend(["", "الاستهلاك: غير مهيأ في إعدادات الجسر."])

        logs = report.get("logs", [])
        lines.extend(["", "آخر السجلات:"])
        if logs:
            for row in logs:
                message = " ".join(row.get("message", "").split())[:180]
                topics = row.get("topics", "")
                timestamp = row.get("time", "")
                lines.append(f"- {timestamp} [{topics}] {message}".rstrip())
        else:
            lines.append("- لا توجد سجلات متاحة أو تعذر قراءتها")

        errors = report.get("errors", [])
        if errors:
            lines.extend(["", "تعذر قراءة: " + ", ".join(dict.fromkeys(errors))])
        lines.extend(["", "هذا التقرير للقراءة فقط؛ لا ينفذ أوامر تغيير أو إعادة تشغيل."])
        return "\n".join(lines)[:3900]