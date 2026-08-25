from __future__ import annotations
import os
from dataclasses import dataclass
from pathlib import Path
from .common import TelegramBotError

@dataclass(frozen=True)
class Settings:
    telegram_token: str
    allowed_chat_ids: frozenset[str]
    allowed_user_ids: frozenset[str]
    admin_user_ids: frozenset[str]
    mikrotik_address: str
    mikrotik_user: str
    mikrotik_password: str
    mikrotik_port: int
    mikrotik_use_ssl: bool
    mikrotik_ca_file: Path | None
    poll_seconds: int
    offset_file: Path
    audit_file: Path
    monitor_target: str
    monitor_interval_seconds: int
    traffic_interface: str
    traffic_interval_seconds: int
    traffic_state_file: Path
    daily_report_time: str
    reboot_recovery_attempts: int
    reboot_recovery_interval_seconds: int

    @classmethod
    def from_env(cls) -> "Settings":
        token=os.getenv("TELEGRAM_BOT_TOKEN", "").strip()
        chats=frozenset(x.strip() for x in os.getenv("TELEGRAM_ALLOWED_CHAT_IDS", "").split(",") if x.strip())
        users=frozenset(x.strip() for x in os.getenv("TELEGRAM_ALLOWED_USER_IDS", "").split(",") if x.strip())
        admins=frozenset(x.strip() for x in os.getenv("TELEGRAM_ADMIN_USER_IDS", "").split(",") if x.strip())
        address=os.getenv("MIKROTIK_ADDRESS", "").strip()
        user=os.getenv("MIKROTIK_USER", "").strip()
        password=os.getenv("MIKROTIK_PASSWORD", "")
        if not token or not chats or not users or not address or not user or not password:
            raise TelegramBotError("Required environment variables are missing")
        if not admins.issubset(users):
            raise TelegramBotError("TELEGRAM_ADMIN_USER_IDS must be a subset of TELEGRAM_ALLOWED_USER_IDS")
        try:
            port=int(os.getenv("MIKROTIK_PORT", "8729"))
            poll=max(1,int(os.getenv("TELEGRAM_POLL_SECONDS", "20")))
            monitor=max(10,int(os.getenv("MONITOR_INTERVAL_SECONDS", "30")))
            traffic=max(30,int(os.getenv("TRAFFIC_INTERVAL_SECONDS", "60")))
        except ValueError as exc:
            raise TelegramBotError("Invalid numeric environment variable") from exc
        if not 1 <= port <= 65535:
            raise TelegramBotError("MIKROTIK_PORT is out of range")
        use_ssl=os.getenv("MIKROTIK_USE_SSL", "true").strip().lower() in {"1","true","yes","on"}
        if not use_ssl and os.getenv("ALLOW_INSECURE_ROUTEROS_API", "false").strip().lower() not in {"1","true","yes","on"}:
            raise TelegramBotError("RouterOS API must use TLS unless ALLOW_INSECURE_ROUTEROS_API=true is explicitly set")
        ca_raw=os.getenv("MIKROTIK_CA_FILE", "").strip()
        ca_file=Path(ca_raw) if ca_raw else None
        if ca_file is not None and not ca_file.is_file():
            raise TelegramBotError("MIKROTIK_CA_FILE does not exist or is not a regular file")
        return cls(
            token,chats,users,admins,address,user,password,port,use_ssl,ca_file,poll,
            Path(os.getenv("TELEGRAM_OFFSET_FILE", "/var/lib/mikrotik-telegram/.telegram_offset")),
            Path(os.getenv("TELEGRAM_AUDIT_FILE", "/var/lib/mikrotik-telegram/audit.jsonl")),
            os.getenv("MONITOR_TARGET", "1.1.1.1").strip() or "1.1.1.1",
            monitor,os.getenv("TRAFFIC_INTERFACE", "").strip(),traffic,
            Path(os.getenv("TRAFFIC_STATE_FILE", "/var/lib/mikrotik-telegram/traffic-state.json")),
            os.getenv("TRAFFIC_DAILY_REPORT_TIME", "23:59").strip() or "23:59",
            max(0, int(os.getenv("REBOOT_RECOVERY_ATTEMPTS", "12"))),
            max(2, int(os.getenv("REBOOT_RECOVERY_INTERVAL_SECONDS", "5"))),
        )
