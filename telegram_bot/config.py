from __future__ import annotations

import os
from dataclasses import dataclass
from pathlib import Path

from .common import TelegramBotError


def load_env_file(path: Path | None = None) -> None:
    """Load a local bot.env without overriding explicitly exported variables.

    Resolution order: an explicit path, BOT_ENV_FILE, ./bot.env. Missing or
    unreadable candidates are ignored so systemd EnvironmentFile remains valid.
    """
    candidates: list[Path] = []
    if path is not None:
        candidates.append(path)

    env_override = os.getenv("BOT_ENV_FILE", "").strip()
    if env_override:
        candidates.append(Path(env_override))
    candidates.append(Path.cwd() / "bot.env")

    for candidate in candidates:
        try:
            if not candidate.is_file():
                continue
            for raw_line in candidate.read_text(encoding="utf-8").splitlines():
                line = raw_line.strip()
                if not line or line.startswith("#") or "=" not in line:
                    continue
                key, value = line.split("=", 1)
                key = key.strip()
                value = value.strip().strip('"').strip("'")
                if key and key not in os.environ:
                    os.environ[key] = value
            return
        except OSError:
            continue


def _env_integer(
    name: str,
    default: int,
    *,
    minimum: int | None = None,
) -> int:
    raw_value = os.getenv(name, str(default)).strip()
    try:
        value = int(raw_value)
    except ValueError as error:
        raise TelegramBotError(
            f"Invalid numeric environment variable: {name}"
        ) from error
    return max(minimum, value) if minimum is not None else value


def _env_bool(name: str, default: bool) -> bool:
    raw_value = os.getenv(name, "true" if default else "false").strip().lower()
    return raw_value in {"1", "true", "yes", "on"}


def _env_set(name: str) -> frozenset[str]:
    return frozenset(
        item.strip() for item in os.getenv(name, "").split(",") if item.strip()
    )


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
    user_manager_customer: str

    @classmethod
    def from_env(cls) -> Settings:
        telegram_token = os.getenv("TELEGRAM_BOT_TOKEN", "").strip()
        allowed_chat_ids = _env_set("TELEGRAM_ALLOWED_CHAT_IDS")
        allowed_user_ids = _env_set("TELEGRAM_ALLOWED_USER_IDS")
        admin_user_ids = _env_set("TELEGRAM_ADMIN_USER_IDS")
        mikrotik_address = os.getenv("MIKROTIK_ADDRESS", "").strip()
        mikrotik_user = os.getenv("MIKROTIK_USER", "").strip()
        mikrotik_password = os.getenv("MIKROTIK_PASSWORD", "")

        if not all(
            (
                telegram_token,
                allowed_chat_ids,
                allowed_user_ids,
                mikrotik_address,
                mikrotik_user,
                mikrotik_password,
            )
        ):
            raise TelegramBotError("Required environment variables are missing")
        if not admin_user_ids.issubset(allowed_user_ids):
            raise TelegramBotError(
                "TELEGRAM_ADMIN_USER_IDS must be a subset of TELEGRAM_ALLOWED_USER_IDS"
            )

        mikrotik_port = _env_integer("MIKROTIK_PORT", 8729)
        if not 1 <= mikrotik_port <= 65535:
            raise TelegramBotError("MIKROTIK_PORT is out of range")

        use_ssl = _env_bool("MIKROTIK_USE_SSL", True)
        if not use_ssl and not _env_bool("ALLOW_INSECURE_ROUTEROS_API", False):
            raise TelegramBotError(
                "RouterOS API must use TLS unless "
                "ALLOW_INSECURE_ROUTEROS_API=true is explicitly set"
            )

        ca_file_value = os.getenv("MIKROTIK_CA_FILE", "").strip()
        ca_file = Path(ca_file_value) if ca_file_value else None
        if ca_file is not None and not ca_file.is_file():
            raise TelegramBotError(
                "MIKROTIK_CA_FILE does not exist or is not a regular file"
            )

        return cls(
            telegram_token=telegram_token,
            allowed_chat_ids=allowed_chat_ids,
            allowed_user_ids=allowed_user_ids,
            admin_user_ids=admin_user_ids,
            mikrotik_address=mikrotik_address,
            mikrotik_user=mikrotik_user,
            mikrotik_password=mikrotik_password,
            mikrotik_port=mikrotik_port,
            mikrotik_use_ssl=use_ssl,
            mikrotik_ca_file=ca_file,
            poll_seconds=_env_integer("TELEGRAM_POLL_SECONDS", 20, minimum=1),
            offset_file=Path(
                os.getenv(
                    "TELEGRAM_OFFSET_FILE",
                    "/var/lib/mikrotik-telegram/.telegram_offset",
                )
            ),
            audit_file=Path(
                os.getenv(
                    "TELEGRAM_AUDIT_FILE",
                    "/var/lib/mikrotik-telegram/audit.jsonl",
                )
            ),
            monitor_target=os.getenv("MONITOR_TARGET", "1.1.1.1").strip() or "1.1.1.1",
            monitor_interval_seconds=_env_integer(
                "MONITOR_INTERVAL_SECONDS", 30, minimum=10
            ),
            traffic_interface=os.getenv("TRAFFIC_INTERFACE", "").strip(),
            traffic_interval_seconds=_env_integer(
                "TRAFFIC_INTERVAL_SECONDS", 60, minimum=30
            ),
            traffic_state_file=Path(
                os.getenv(
                    "TRAFFIC_STATE_FILE",
                    "/var/lib/mikrotik-telegram/traffic-state.json",
                )
            ),
            daily_report_time=(
                os.getenv("TRAFFIC_DAILY_REPORT_TIME", "23:59").strip() or "23:59"
            ),
            reboot_recovery_attempts=_env_integer(
                "REBOOT_RECOVERY_ATTEMPTS", 12, minimum=0
            ),
            reboot_recovery_interval_seconds=_env_integer(
                "REBOOT_RECOVERY_INTERVAL_SECONDS", 5, minimum=2
            ),
            user_manager_customer=(
                os.getenv("USER_MANAGER_CUSTOMER", "admin").strip() or "admin"
            ),
        )
