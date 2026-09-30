"""Explicit startup self-test for Telegram and the configured RouterOS router."""

from __future__ import annotations

import logging

from .config import Settings
from .routeros.client import RouterOSV6Client
from .telegram.client import TelegramClient

LOGGER = logging.getLogger("mikrotik_telegram_bot")


def _failure_label(error: Exception) -> str:
    status = getattr(error, "code", None)
    if isinstance(status, int):
        return f"HTTP {status}"
    return type(error).__name__


def run_selftest(settings: Settings) -> int:
    """Verify Telegram credentials and RouterOS access; notify allowed chats."""
    telegram = TelegramClient(settings.telegram_token)
    try:
        bot = telegram.call("getMe", {})
        LOGGER.info("Telegram token OK: bot @%s", (bot or {}).get("username", "?"))
    except Exception as error:  # noqa: BLE001 - report a concise actionable failure
        LOGGER.error("Telegram token check FAILED: %s", _failure_label(error))
        return 2

    gateway = RouterOSV6Client(
        settings.mikrotik_address,
        settings.mikrotik_user,
        settings.mikrotik_password,
        settings.mikrotik_port,
        settings.mikrotik_use_ssl,
        settings.mikrotik_ca_file,
    )
    router_ok = True
    try:
        rows = gateway.command(
            "/system/resource/print",
            "=.proplist=uptime,version",
        )
        info = next((row for row in rows if row.get("!type") == "!re"), {})
        LOGGER.info(
            "RouterOS login OK: version=%s uptime=%s",
            info.get("version", "?"),
            info.get("uptime", "?"),
        )
    except Exception as error:  # noqa: BLE001 - report a concise actionable failure
        LOGGER.error("RouterOS connection FAILED: %s", _failure_label(error))
        router_ok = False
    finally:
        gateway.close()

    message = (
        "✅ فحص Telegram Bot ناجح: التوكن والاتصال بـ MikroTik يعملان."
        if router_ok
        else "⚠️ فحص Telegram Bot: التوكن يعمل لكن الاتصال بـ MikroTik فشل. "
        "راجع العنوان/المنفذ/TLS."
    )
    delivery_ok = True
    for chat_id in settings.allowed_chat_ids:
        try:
            telegram.send_message(chat_id, message)
        except Exception as error:  # noqa: BLE001 - check all configured recipients
            LOGGER.warning(
                "could not send selftest message to %s: %s",
                chat_id,
                type(error).__name__,
            )
            delivery_ok = False

    return 0 if router_ok and delivery_ok else 2
