"""Command-line entrypoint for the direct Telegram-to-RouterOS bot."""

from __future__ import annotations

import logging
import os
import sys

from .common import TelegramBotError
from .config import Settings, load_env_file
from .healthcheck import run_selftest
from .runtime import BotRuntime

LOGGER = logging.getLogger("mikrotik_telegram_bot")


def _configure_logging() -> None:
    if logging.getLogger().handlers:
        return
    level_name = os.getenv("LOG_LEVEL", "INFO").strip().upper()
    level = getattr(logging, level_name, logging.INFO)
    logging.basicConfig(
        level=level,
        format="%(asctime)s %(levelname)s %(name)s: %(message)s",
        stream=sys.stdout,
    )


def main(argv: list[str] | None = None) -> int:
    _configure_logging()
    arguments = list(sys.argv[1:] if argv is None else argv)
    load_env_file()

    try:
        settings = Settings.from_env()
    except TelegramBotError as error:
        LOGGER.error("startup failed: %s", error)
        return 2

    if "--selftest" in arguments:
        return run_selftest(settings)

    try:
        BotRuntime(settings).run()
        return 0
    except KeyboardInterrupt:
        return 0
    except TelegramBotError as error:
        # Configuration/safety errors are intentionally secret-free.
        LOGGER.error("startup failed: %s", error)
        return 2
    except Exception as error:  # noqa: BLE001 - never print credential-bearing errors
        LOGGER.error("startup failed: %s", type(error).__name__)
        return 2


if __name__ == "__main__":
    raise SystemExit(main())
