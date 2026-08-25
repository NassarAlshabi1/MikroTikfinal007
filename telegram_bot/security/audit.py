from __future__ import annotations
import json, os, secrets, threading
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

class AuditTrail:
    def __init__(self, path: Path):
        self.path=path
        self._lock=threading.Lock()

    @staticmethod
    def operation_id() -> str:
        return secrets.token_hex(12)

    def record(self, *, source: str, user_id: str, chat_id: str, command: str,
               risk: str, authorization: str, confirmation: str, device: str,
               result: str, duration_ms: int, error_category: str | None=None,
               operation_id: str | None=None) -> str:
        op=operation_id or self.operation_id()
        event={
          "timestamp": datetime.now(timezone.utc).isoformat(),
          "operation_id": op, "source": source, "user_id": user_id, "chat_id": chat_id,
          "command": command, "risk": risk, "authorization": authorization,
          "confirmation": confirmation, "device": device, "result": result,
          "duration_ms": max(0,duration_ms),
        }
        if error_category: event["error_category"]=error_category
        self.path.parent.mkdir(parents=True, exist_ok=True)
        with self._lock:
            with self.path.open("a", encoding="utf-8") as f:
                f.write(json.dumps(event, ensure_ascii=False, separators=(",",":"))+"\n")
        try: os.chmod(self.path,0o640)
        except OSError: pass
        return op
