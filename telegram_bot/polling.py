"""Telegram update handling and durable polling-offset persistence."""

from __future__ import annotations

import logging
import os
import tempfile
from pathlib import Path
from typing import Any

from .config import Settings
from .security.policy import TelegramPolicy

LOGGER = logging.getLogger("mikrotik_telegram_bot")


class OffsetStore:
    """Persist Telegram's next update id using an atomic same-filesystem replace."""

    def __init__(self, path: Path) -> None:
        self.path = path

    def load(self) -> int | None:
        try:
            value = int(self.path.read_text(encoding="utf-8").strip())
        except (FileNotFoundError, OSError, ValueError):
            return None
        return value if value >= 0 else None

    def save(self, offset: int) -> None:
        if offset < 0:
            raise ValueError("Telegram offset must not be negative")

        self.path.parent.mkdir(parents=True, exist_ok=True)
        temporary_path: Path | None = None
        try:
            with tempfile.NamedTemporaryFile(
                mode="w",
                encoding="utf-8",
                dir=self.path.parent,
                prefix=f".{self.path.name}.",
                suffix=".tmp",
                delete=False,
            ) as temporary:
                temporary_path = Path(temporary.name)
                temporary.write(str(offset))
                temporary.flush()
                os.fsync(temporary.fileno())

            os.replace(temporary_path, self.path)
            temporary_path = None
            try:
                directory_fd = os.open(self.path.parent, os.O_RDONLY)
                try:
                    os.fsync(directory_fd)
                finally:
                    os.close(directory_fd)
            except OSError:
                # Directory fsync is not supported on every platform/filesystem.
                pass
        finally:
            if temporary_path is not None:
                try:
                    temporary_path.unlink()
                except FileNotFoundError:
                    pass


class TelegramUpdatePoller:
    """Poll updates, enforce identity policy, dispatch commands, and checkpoint."""

    def __init__(
        self,
        settings: Settings,
        telegram: Any,
        router: Any,
        policy: TelegramPolicy,
        offset_store: OffsetStore,
    ) -> None:
        self.settings = settings
        self.telegram = telegram
        self.router = router
        self.policy = policy
        self.offset_store = offset_store
        self.offset = offset_store.load()

    def poll_once(self) -> int:
        updates = self.telegram.updates(self.offset)
        processed = 0
        for update in updates:
            update_id = int(update["update_id"])
            self._dispatch(update)
            next_offset = update_id + 1
            # Only checkpoint after dispatch has completed. Command-level
            # failures are contained in _dispatch, so one bad update cannot
            # block later updates indefinitely.
            self.offset_store.save(next_offset)
            self.offset = next_offset
            processed += 1
        return processed

    def _dispatch(self, update: dict[str, Any]) -> None:
        callback = update.get("callback_query")
        if callback:
            self._dispatch_callback(callback)
            return

        message = update.get("message") or {}
        chat = message.get("chat") or {}
        sender = message.get("from") or {}
        chat_id = str(chat.get("id", ""))
        user_id = str(sender.get("id", ""))
        text = str(message.get("text", "")).strip()
        if not text:
            return

        command = text.split(maxsplit=1)[0].lower().split("@", 1)[0]
        authorized = self.policy.authorize(
            chat_id=chat_id,
            user_id=user_id,
            allowed_chats=self.settings.allowed_chat_ids,
            allowed_users=self.settings.allowed_user_ids,
            command=command,
            admin_users=self.settings.admin_user_ids,
        )
        if authorized:
            try:
                self.router.handle(chat_id, user_id, text)
            except Exception as error:  # noqa: BLE001 - isolate a bad update
                LOGGER.warning("command failed: %s", type(error).__name__)
                self._send_safely(
                    chat_id,
                    f"تعذر تنفيذ الطلب بأمان: {type(error).__name__}",
                )
        elif (
            chat_id in self.settings.allowed_chat_ids
            and user_id in self.settings.allowed_user_ids
        ):
            self._send_safely(chat_id, "ليس لديك صلاحية تنفيذ هذا الأمر.")

    def _dispatch_callback(self, callback: dict[str, Any]) -> None:
        message = callback.get("message") or {}
        chat = message.get("chat") or {}
        sender = callback.get("from") or {}
        chat_id = str(chat.get("id", ""))
        user_id = str(sender.get("id", ""))
        if not self.policy.authorize(
            chat_id=chat_id,
            user_id=user_id,
            allowed_chats=self.settings.allowed_chat_ids,
            allowed_users=self.settings.allowed_user_ids,
        ):
            return

        try:
            self.router.handle_callback(
                chat_id,
                user_id,
                str(callback.get("id", "")),
                str(callback.get("data", "")),
            )
        except Exception as error:  # noqa: BLE001 - isolate a bad callback
            LOGGER.warning("callback failed: %s", type(error).__name__)
            self._send_safely(chat_id, "تعذر تنفيذ التأكيد بأمان.")

    def _send_safely(self, chat_id: str, text: str) -> None:
        try:
            self.telegram.send_message(chat_id, text)
        except Exception as error:  # noqa: BLE001 - network failure is recoverable
            LOGGER.warning("Telegram response failed: %s", type(error).__name__)
