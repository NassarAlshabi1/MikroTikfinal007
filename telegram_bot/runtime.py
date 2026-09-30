"""Lifecycle and dependency composition for the direct Telegram bot runtime."""

from __future__ import annotations

import logging
import threading
from collections.abc import Callable

from .commands.router import CommandRouter
from .config import Settings
from .monitoring.core import InternetMonitor, TrafficMonitor, TrafficUsageTracker
from .polling import OffsetStore, TelegramUpdatePoller
from .routeros.client import RouterOSV6Client
from .security.audit import AuditTrail
from .security.policy import TelegramPolicy
from .telegram.client import TelegramClient

LOGGER = logging.getLogger("mikrotik_telegram_bot")
RouterClientFactory = Callable[..., RouterOSV6Client]
TelegramClientFactory = Callable[[str], TelegramClient]


class BotRuntime:
    """Owns service construction, background workers, and deterministic cleanup."""

    def __init__(
        self,
        settings: Settings,
        *,
        telegram_factory: TelegramClientFactory = TelegramClient,
        router_factory: RouterClientFactory = RouterOSV6Client,
    ) -> None:
        self.settings = settings
        self.telegram = telegram_factory(settings.telegram_token)
        self.gateway = self._new_gateway(router_factory)
        self.monitor_gateway = self._new_gateway(router_factory)
        self.traffic_gateway = self._new_gateway(router_factory)
        self._gateways = (
            self.gateway,
            self.monitor_gateway,
            self.traffic_gateway,
        )

        self.usage = TrafficUsageTracker(
            self.traffic_gateway,
            settings.traffic_interface,
            settings.traffic_state_file,
        )
        self.policy = TelegramPolicy()
        self.audit = AuditTrail(settings.audit_file)
        self.router = CommandRouter(
            self.gateway,
            self.telegram,
            self.usage,
            policy=self.policy,
            audit=self.audit,
            admin_user_ids=settings.admin_user_ids,
            recovery_target=settings.monitor_target,
            recovery_attempts=settings.reboot_recovery_attempts,
            recovery_interval_seconds=settings.reboot_recovery_interval_seconds,
            user_manager_customer=settings.user_manager_customer,
        )
        self.monitor = InternetMonitor(
            self.monitor_gateway,
            self.telegram,
            settings.allowed_chat_ids,
            settings.monitor_target,
            settings.monitor_interval_seconds,
        )
        self.traffic_monitor = TrafficMonitor(
            self.usage,
            self.telegram,
            settings.allowed_chat_ids,
            settings.traffic_interval_seconds,
            settings.daily_report_time,
        )
        self.poller = TelegramUpdatePoller(
            settings,
            self.telegram,
            self.router,
            self.policy,
            OffsetStore(settings.offset_file),
        )
        self._threads: list[threading.Thread] = []
        self._close_lock = threading.Lock()
        self._stop_event = threading.Event()
        self._closed = False

    def _new_gateway(self, factory: RouterClientFactory) -> RouterOSV6Client:
        return factory(
            self.settings.mikrotik_address,
            self.settings.mikrotik_user,
            self.settings.mikrotik_password,
            self.settings.mikrotik_port,
            self.settings.mikrotik_use_ssl,
            self.settings.mikrotik_ca_file,
        )

    def run(self) -> None:
        """Start monitoring and process updates until interrupted."""
        try:
            self._start_worker("router-health", self.monitor.run_forever)
            self._start_worker("traffic-monitor", self.traffic_monitor.run_forever)
            self._announce_startup()
            LOGGER.info("Telegram Bot started in direct RouterOS API mode")
            self._poll_forever()
        finally:
            self.close()

    def _start_worker(self, name: str, target: Callable[[], None]) -> None:
        thread = threading.Thread(target=target, daemon=True, name=name)
        thread.start()
        self._threads.append(thread)

    def _announce_startup(self) -> None:
        for chat_id in self.settings.allowed_chat_ids:
            try:
                self.telegram.send_message(
                    chat_id,
                    "🟢 Telegram Bot يعمل الآن وجاهز لاستقبال الأوامر.",
                )
            except Exception as error:  # noqa: BLE001 - startup can proceed offline
                LOGGER.warning(
                    "startup notice to %s failed: %s",
                    chat_id,
                    type(error).__name__,
                )

    def _poll_forever(self) -> None:
        while not self._stop_event.is_set():
            try:
                self.poller.poll_once()
            except KeyboardInterrupt:
                return
            except Exception as error:  # noqa: BLE001 - retry transient API failures
                LOGGER.warning("telegram poll cycle failed: %s", type(error).__name__)
                self.gateway.close()
                self._stop_event.wait(self.settings.poll_seconds)

    def close(self) -> None:
        """Stop workers and close all independent RouterOS sessions exactly once."""
        with self._close_lock:
            if self._closed:
                return
            self._closed = True
            self._stop_event.set()

        self.monitor.stop()
        self.traffic_monitor.stop()
        for thread in self._threads:
            thread.join(timeout=30)

        seen: set[int] = set()
        for gateway in self._gateways:
            if id(gateway) in seen:
                continue
            seen.add(id(gateway))
            try:
                gateway.close()
            except Exception as error:  # noqa: BLE001 - continue cleaning others
                LOGGER.warning(
                    "RouterOS client cleanup failed: %s", type(error).__name__
                )
