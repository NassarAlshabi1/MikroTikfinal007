from __future__ import annotations
import json, logging, re, threading
from datetime import datetime
from pathlib import Path
from typing import Any
from ..routeros.client import RouterOSV6Client
from ..telegram.client import TelegramClient
from ..common import TelegramBotError
LOGGER=logging.getLogger("mikrotik_telegram_bot")

def _format_bytes(value: int) -> str:
    amount = float(max(0, value))
    for unit in ("B", "KB", "MB", "GB", "TB"):
        if amount < 1024 or unit == "TB":
            return f"{amount:.2f} {unit}"
        amount /= 1024
    return f"{amount:.2f} TB"

class TrafficUsageTracker:
    """Track daily deltas from RouterOS cumulative interface counters."""

    def __init__(self, gateway: RouterOSV6Client, interface_name: str, state_file: Path) -> None:
        self.gateway = gateway
        self.interface_name = interface_name.strip()
        self.state_file = state_file
        self._lock = threading.Lock()
        self._state: dict[str, Any] | None = None

    def _load_state(self) -> dict[str, Any]:
        if self._state is not None:
            return self._state
        try:
            loaded = json.loads(self.state_file.read_text(encoding="utf-8"))
            self._state = loaded if isinstance(loaded, dict) else {}
        except (FileNotFoundError, OSError, ValueError):
            self._state = {}
        return self._state

    def _save_state(self, state: dict[str, Any]) -> None:
        self.state_file.parent.mkdir(parents=True, exist_ok=True)
        temporary = self.state_file.with_suffix(self.state_file.suffix + ".tmp")
        temporary.write_text(json.dumps(state, ensure_ascii=False), encoding="utf-8")
        temporary.replace(self.state_file)
        self._state = state

    def _interface_counters(self) -> tuple[int, int, str]:
        rows = self.gateway.command(
            "/interface/print",
            "=.proplist=name,rx-byte,tx-byte,running,disabled",
        )
        selected: list[dict[str, str]] = []
        for row in rows:
            name = row.get("name", "").strip()
            if not name or row.get("!type") != "!re":
                continue
            if row.get("disabled", "no").lower() == "yes":
                continue
            if self.interface_name and name != self.interface_name:
                continue
            selected.append(row)
        if not selected:
            target = self.interface_name or "الواجهات المفعلة"
            raise TelegramBotError(f"لم يعثر على واجهة حركة بيانات: {target}")

        def counter(row: dict[str, str], key: str) -> int:
            try:
                return max(0, int(row.get(key, "0")))
            except (TypeError, ValueError):
                return 0

        rx = sum(counter(row, "rx-byte") for row in selected)
        tx = sum(counter(row, "tx-byte") for row in selected)
        label = self.interface_name or "المجموع"
        return rx, tx, label

    def snapshot(self) -> dict[str, Any]:
        with self._lock:
            rx, tx, label = self._interface_counters()
            today = datetime.now().astimezone().date().isoformat()
            state = self._load_state()
            if state.get("date") != today:
                state = {"date": today, "base_rx": rx, "base_tx": tx}
            base_rx = int(state.get("base_rx", rx))
            base_tx = int(state.get("base_tx", tx))
            # RouterOS counters reset after reboot or interface reset.
            if rx < base_rx or tx < base_tx:
                base_rx, base_tx = rx, tx
            state.update({"date": today, "base_rx": base_rx, "base_tx": base_tx,
                          "last_rx": rx, "last_tx": tx, "interface": label})
            self._save_state(state)
            return {"date": today, "interface": label, "rx": rx - base_rx,
                    "tx": tx - base_tx, "total": (rx - base_rx) + (tx - base_tx)}

    @staticmethod
    def report(snapshot: dict[str, Any]) -> str:
        return (
            f"استهلاك الإنترنت اليومي ({snapshot['date']})\n"
            f"الواجهة: {snapshot['interface']}\n"
            f"الوارد: {_format_bytes(int(snapshot['rx']))}\n"
            f"الصادر: {_format_bytes(int(snapshot['tx']))}\n"
            f"الإجمالي: {_format_bytes(int(snapshot['total']))}\n"
            "ملاحظة: الحساب منذ أول قراءة اليوم، لأن عدادات RouterOS v6 تراكمية."
        )

class TrafficMonitor:
    def __init__(self, tracker: TrafficUsageTracker, telegram: TelegramClient,
                 chat_ids: frozenset[str], interval_seconds: int, report_time: str) -> None:
        self.tracker = tracker
        self.telegram = telegram
        self.chat_ids = chat_ids
        self.interval_seconds = interval_seconds
        self.report_time = report_time if re.fullmatch(r"(?:[01]\d|2[0-3]):[0-5]\d", report_time) else "23:59"
        self._last_report_date: str | None = None
        self._stop = threading.Event()

    def observe_once(self) -> dict[str, Any]:
        snapshot = self.tracker.snapshot()
        now = datetime.now().astimezone()
        today = now.date().isoformat()
        if now.strftime("%H:%M") >= self.report_time and self._last_report_date != today:
            message = TrafficUsageTracker.report(snapshot)
            for chat_id in self.chat_ids:
                try:
                    self.telegram.send_message(chat_id, message)
                except Exception:
                    pass
            self._last_report_date = today
        return snapshot

    def run_forever(self) -> None:
        while not self._stop.is_set():
            try:
                self.observe_once()
            except Exception as error:
                LOGGER.warning("traffic monitor failed: %s", type(error).__name__)
            self._stop.wait(self.interval_seconds)

    def stop(self) -> None:
        self._stop.set()

class InternetMonitor:
    ROUTER_OFFLINE="ROUTER_OFFLINE"
    INTERNET_DOWN="INTERNET_DOWN"
    ONLINE="ONLINE"
    def __init__(self,gateway,telegram,chat_ids,target,interval_seconds):
        self.gateway=gateway; self.telegram=telegram; self.chat_ids=chat_ids; self.target=target
        self.interval_seconds=interval_seconds; self._last_state=None; self._stop=threading.Event()
    def _state_once(self):
        try:
            self.gateway.command("/system/resource/print", "=.proplist=uptime")
        except Exception:
            self.gateway.close(); return self.ROUTER_OFFLINE
        try:
            rows=self.gateway.command("/ping",f"=address={self.target}","=count=2")
            replies=[r for r in rows if r.get("!type")=="!re"]
            ok=any(r.get("status","").lower()!="timeout" for r in replies) or (bool(replies) and not any("status" in r for r in replies))
            return self.ONLINE if ok else self.INTERNET_DOWN
        except Exception:
            return self.INTERNET_DOWN
    def observe_once(self):
        state=self._state_once()
        if self._last_state is None:
            self._last_state=state
            if state!=self.ONLINE: self._notify(self._message(None,state))
            return state
        if state!=self._last_state:
            previous=self._last_state; self._last_state=state; self._notify(self._message(previous,state))
        return state
    def _message(self,previous,state):
        table={
          (None,self.INTERNET_DOWN):"⚠️ انقطع اتصال الإنترنت: MikroTik ما زال متاحًا عبر API.",
          (None,self.ROUTER_OFFLINE):"🔴 تعذر الوصول إلى MikroTik عبر RouterOS API.",
          (self.ONLINE,self.INTERNET_DOWN):"⚠️ انقطع اتصال الإنترنت: MikroTik ما زال متاحًا عبر API.",
          (self.INTERNET_DOWN,self.ONLINE):"✅ عاد اتصال الإنترنت.",
          (self.ONLINE,self.ROUTER_OFFLINE):"🔴 أصبح MikroTik غير متاح عبر RouterOS API.",
          (self.INTERNET_DOWN,self.ROUTER_OFFLINE):"🔴 أصبح MikroTik غير متاح عبر RouterOS API أثناء انقطاع الإنترنت.",
          (self.ROUTER_OFFLINE,self.ONLINE):"🟢 عاد MikroTik والإنترنت يعمل.",
          (self.ROUTER_OFFLINE,self.INTERNET_DOWN):"🟡 عاد MikroTik لكن الإنترنت ما زال غير متاح.",
        }
        return table[(previous,state)]
    def _notify(self,message):
        for chat in self.chat_ids:
            try:self.telegram.send_message(chat,message)
            except Exception:pass
    def run_forever(self):
        while not self._stop.is_set():
            try:self.observe_once()
            except Exception as e:LOGGER.warning("health monitor failed: %s",type(e).__name__)
            self._stop.wait(self.interval_seconds)
    def stop(self):self._stop.set()
