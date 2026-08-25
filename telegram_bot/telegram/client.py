from __future__ import annotations
import json, urllib.parse, urllib.request
from typing import Any
from ..common import TelegramBotError

class TelegramClient:
    def __init__(self, token: str) -> None:
        self.base = f"https://api.telegram.org/bot{token}"

    def call(self, method: str, payload: dict[str, Any]) -> Any:
        data = urllib.parse.urlencode(payload).encode()
        request = urllib.request.Request(f"{self.base}/{method}", data=data, method="POST")
        with urllib.request.urlopen(request, timeout=25) as response:
            body = json.loads(response.read().decode("utf-8"))
        if not body.get("ok"):
            raise TelegramBotError(f"Telegram API error: {body.get('description', 'unknown')}")
        return body.get("result")

    def send_message(self, chat_id: str, text: str, reply_markup: dict[str, Any] | None = None) -> None:
        payload: dict[str, Any] = {"chat_id": chat_id, "text": text[:3900]}
        if reply_markup is not None:
            payload["reply_markup"] = json.dumps(reply_markup, ensure_ascii=False)
        self.call("sendMessage", payload)

    def answer_callback_query(self, callback_id: str) -> None:
        self.call("answerCallbackQuery", {"callback_query_id": callback_id})

    def send_document(self, chat_id: str, filename: str, content: bytes | str) -> None:
        boundary = "----MikroTikTelegramBoundary"
        raw_content = content.encode("utf-8") if isinstance(content, str) else content
        content_type = "application/pdf" if filename.lower().endswith(".pdf") else "text/plain; charset=utf-8"
        body = (
            f"--{boundary}\r\nContent-Disposition: form-data; name=\"chat_id\"\r\n\r\n{chat_id}\r\n"
            f"--{boundary}\r\nContent-Disposition: form-data; name=\"document\"; filename=\"{filename}\"\r\n"
            f"Content-Type: {content_type}\r\n\r\n"
        ).encode() + raw_content + f"\r\n--{boundary}--\r\n".encode()
        request = urllib.request.Request(
            f"{self.base}/sendDocument", data=body, method="POST",
            headers={"Content-Type": f"multipart/form-data; boundary={boundary}"})
        with urllib.request.urlopen(request, timeout=30) as response:
            result = json.loads(response.read().decode("utf-8"))
        if not result.get("ok"):
            raise TelegramBotError(f"Telegram document error: {result.get('description', 'unknown')}")

    def updates(self, offset: int | None) -> list[dict[str, Any]]:
        payload: dict[str, Any] = {"timeout": 25, "allowed_updates": json.dumps(["message", "callback_query"])}
        if offset is not None:
            payload["offset"] = offset
        return self.call("getUpdates", payload) or []