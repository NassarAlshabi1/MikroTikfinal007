from __future__ import annotations

from collections import Counter
from datetime import datetime, timezone
from decimal import Decimal, InvalidOperation
import re
from typing import Any

from .client import RouterOSV6Client


_SAFE_USERNAME = re.compile(r"[A-Za-z0-9_.-]{1,64}\Z")
_SENSITIVE_KEYS = {"password", "pass", "secret", "token", "ret", "response"}
_EXPIRY_KEYS = ("end-time", "expires", "expiration", "valid-until")


def rows_only(rows: list[dict[str, str]]) -> list[dict[str, str]]:
    return [row for row in rows if row.get("!type") == "!re"]


def validate_username(value: str) -> str:
    value = value.strip()
    if not _SAFE_USERNAME.fullmatch(value):
        raise ValueError("invalid username")
    return value


def public_row(row: dict[str, str]) -> dict[str, str]:
    """Return RouterOS data safe for Telegram output and reports."""
    return {
        key: str(value)[:240]
        for key, value in row.items()
        if key not in _SENSITIVE_KEYS and not any(secret in key.lower() for secret in _SENSITIVE_KEYS)
    }


class RouterOSOperations:
    """Read/write use cases for the direct Telegram Bot control plane.

    This class is the only layer used by CommandRouter to issue RouterOS commands.
    It deliberately exposes named operations instead of accepting arbitrary paths
    or arguments from Telegram input.
    """

    USER_PROPS = (
        ".id,username,customer,disabled,actual-profile,profile,comment,created-at,"
        "end-time,expires,expiration,valid-until,uptime-used,download-used,upload-used,last-seen"
    )
    SESSION_PROPS = "user,uptime,session-time-left,framed-ip-address,download,upload,bytes-in,bytes-out"

    def __init__(self, gateway: RouterOSV6Client, customer: str = "admin") -> None:
        self.gateway = gateway
        self.customer = customer.strip() or "admin"

    def _read(self, path: str, *arguments: str) -> list[dict[str, str]]:
        return rows_only(self.gateway.command(path, *arguments))

    def status(self) -> dict[str, Any]:
        resources = self._read(
            "/system/resource/print",
            "=.proplist=uptime,version,cpu-load,free-memory,total-memory,architecture-name,board-name",
        )
        services = self._read(
            "/ip/service/print",
            "=.proplist=name,disabled,port,address",
        )
        return {
            "resource": public_row(resources[0]) if resources else {},
            "api_services": [public_row(row) for row in services if row.get("name", "").lower() in {"api", "api-ssl"}],
        }

    def internet(self, target: str = "1.1.1.1") -> str:
        try:
            self._read("/system/resource/print", "=.proplist=uptime,version")
            replies = self._read("/ping", f"=address={target}", "=count=2")
        except Exception:
            return "ROUTER_OFFLINE"
        return "ONLINE" if any(row.get("status", "").lower() not in {"timeout", "failed"} for row in replies) else "INTERNET_DOWN"

    def active_sessions(self) -> list[dict[str, str]]:
        return [public_row(row) for row in self._read("/tool/user-manager/session/print", f"=.proplist={self.SESSION_PROPS}")]

    def sessions_for_user(self, username: str) -> list[dict[str, str]]:
        username = validate_username(username)
        return [
            public_row(row)
            for row in self._read(
                "/tool/user-manager/session/print",
                f"?user={username}",
                f"=.proplist={self.SESSION_PROPS}",
            )
        ]

    def users(self) -> list[dict[str, str]]:
        return [public_row(row) for row in self._read("/tool/user-manager/user/print", f"=.proplist={self.USER_PROPS}")]

    def user(self, username: str) -> dict[str, str] | None:
        username = validate_username(username)
        rows = self._read(
            "/tool/user-manager/user/print",
            f"?username={username}",
            "=.proplist=username,customer,disabled,actual-profile,profile,comment,created-at,end-time,expires,expiration,valid-until,uptime-used,download-used,upload-used,last-seen",
        )
        return next((row for row in rows if row.get("username") == username), None)

    def profiles(self) -> list[dict[str, str]]:
        rows = self._read(
            "/tool/user-manager/profile/print",
            "=.proplist=name,rate-limit,shared-users,session-timeout,validity,price",
        )
        return [public_row(row) for row in rows]

    def interfaces(self) -> list[dict[str, str]]:
        return [
            public_row(row)
            for row in self._read(
                "/interface/print",
                "=.proplist=name,running,disabled,type,rx-byte,tx-byte,comment",
            )
        ]

    def logs(self, limit: int = 30) -> list[dict[str, str]]:
        return [
            public_row(row)
            for row in self._read("/log/print", "=.proplist=time,topics,message")[-max(1, min(limit, 100)) :]
        ]

    def card_usage(self, username: str) -> dict[str, Any]:
        username = validate_username(username)
        user = self.user(username)
        return {"user": user, "sessions": self.sessions_for_user(username)}

    def user_manager_summary(self) -> dict[str, int]:
        return {
            "users": len(self.users()),
            "profiles": len(self.profiles()),
            "active_sessions": len(self.active_sessions()),
        }

    def create_card(self, username: str, password: str, profile: str, customer: str | None = None) -> dict[str, str]:
        username = validate_username(username)
        profile = validate_username(profile)
        if not 4 <= len(password) <= 128 or any(char.isspace() for char in password):
            raise ValueError("invalid password")
        selected_customer = (customer or self.customer).strip()
        if not selected_customer or len(selected_customer) > 64:
            raise ValueError("invalid customer")
        existing = self.user(username)
        if existing is not None:
            raise ValueError("user already exists")
        self.gateway.command(
            "/tool/user-manager/user/add",
            f"=customer={selected_customer}",
            f"=username={username}",
            f"=password={password}",
        )
        self.gateway.command(
            "/tool/user-manager/user/create-and-activate-profile",
            f"=customer={selected_customer}",
            f"=profile={profile}",
            f"=user={username}",
        )
        return {"username": username, "profile": profile, "customer": selected_customer}

    @staticmethod
    def _parse_expiry(value: str) -> datetime | None:
        value = value.strip()
        if not value or value in {"never", "none", "-"}:
            return None
        candidate = value.replace("Z", "+00:00")
        try:
            parsed = datetime.fromisoformat(candidate)
            return parsed if parsed.tzinfo else parsed.replace(tzinfo=timezone.utc)
        except ValueError:
            # RouterOS commonly returns dates such as jan/02/2025 12:30:00.
            for date_format in ("%b/%d/%Y %H:%M:%S", "%b/%d/%Y", "%Y-%m-%d %H:%M:%S", "%Y-%m-%d"):
                try:
                    return datetime.strptime(value.lower(), date_format).replace(tzinfo=timezone.utc)
                except ValueError:
                    continue
            # Do not guess ambiguous formats; such users remain protected from mass deletion.
            return None

    def expired_users(self) -> list[dict[str, str]]:
        expired: list[dict[str, str]] = []
        now = datetime.now(timezone.utc)
        for row in self.users():
            expiry = next((row.get(key, "") for key in _EXPIRY_KEYS if row.get(key)), "")
            parsed = self._parse_expiry(expiry)
            if parsed is not None and parsed <= now and row.get(".id"):
                expired.append(row)
        return expired

    def delete_users(self, users: list[dict[str, str]]) -> int:
        count = 0
        for row in users:
            identifier = row.get(".id", "").strip()
            if not identifier or not row.get("username"):
                continue
            self.gateway.command("/tool/user-manager/user/remove", f"=.id={identifier}")
            count += 1
        return count

    def payments(self) -> list[dict[str, str]]:
        rows = self._read(
            "/tool/user-manager/payment/print",
            "=.proplist=user,profile,price,currency,trans-status,trans-start,trans-end",
        )
        return [public_row(row) for row in rows]

    def sales_summary(self) -> dict[str, Any]:
        """Return payment-backed sales data plus inventory counts, never fabricated revenue."""
        users = self.users()
        customers = Counter(row.get("customer", "unknown") for row in users)
        profiles = Counter(row.get("actual-profile") or row.get("profile") or "unknown" for row in users)
        created = Counter(row.get("created-at", "unknown")[:10] for row in users if row.get("created-at"))
        try:
            payments = self.payments()
        except Exception:
            payments = []
        approved = [row for row in payments if row.get("trans-status", "").lower() in {"approved", "user approved"}]
        revenue_by_currency: dict[str, str] = {}
        for row in approved:
            currency = row.get("currency", "UNKNOWN") or "UNKNOWN"
            try:
                amount = Decimal(row.get("price", "0"))
            except InvalidOperation:
                continue
            revenue_by_currency[currency] = str(Decimal(revenue_by_currency.get(currency, "0")) + amount)
        return {
            "total_cards": len(users),
            "by_customer": dict(customers),
            "by_profile": dict(profiles),
            "by_created_date": dict(created),
            "approved_payments": len(approved),
            "revenue_by_currency": revenue_by_currency,
            "revenue_available": bool(revenue_by_currency),
        }
