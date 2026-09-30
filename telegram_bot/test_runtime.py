from __future__ import annotations

import tempfile
import unittest
from pathlib import Path
from types import SimpleNamespace
from unittest.mock import patch

from telegram_bot.polling import OffsetStore, TelegramUpdatePoller
from telegram_bot.runtime import BotRuntime
from telegram_bot.security.policy import TelegramPolicy


class FakeTelegram:
    def __init__(self, updates=None):
        self.pending_updates = list(updates or [])
        self.offsets = []
        self.messages = []

    def updates(self, offset):
        self.offsets.append(offset)
        updates, self.pending_updates = self.pending_updates, []
        return updates

    def send_message(self, chat_id, text, reply_markup=None):
        self.messages.append((chat_id, text, reply_markup))


class FakeRouter:
    def __init__(self, *, fail=False):
        self.calls = []
        self.callbacks = []
        self.fail = fail

    def handle(self, chat_id, user_id, text):
        self.calls.append((chat_id, user_id, text))
        if self.fail:
            raise RuntimeError("simulated command failure")

    def handle_callback(self, chat_id, user_id, callback_id, data):
        self.callbacks.append((chat_id, user_id, callback_id, data))


class FakeGateway:
    address = "192.0.2.1"

    def __init__(self):
        self.close_count = 0

    def close(self):
        self.close_count += 1

    def command(self, *_args):
        return []


def settings_for_polling(**overrides):
    values = {
        "allowed_chat_ids": frozenset({"10"}),
        "allowed_user_ids": frozenset({"20", "21"}),
        "admin_user_ids": frozenset({"20"}),
    }
    values.update(overrides)
    return SimpleNamespace(**values)


class OffsetStoreTests(unittest.TestCase):
    def test_missing_malformed_and_negative_values_are_ignored(self):
        with tempfile.TemporaryDirectory() as temporary:
            path = Path(temporary) / "offset"
            store = OffsetStore(path)
            self.assertIsNone(store.load())

            path.write_text("not-an-offset", encoding="utf-8")
            self.assertIsNone(store.load())
            path.write_text("-1", encoding="utf-8")
            self.assertIsNone(store.load())

    def test_save_is_atomic_and_round_trips(self):
        with tempfile.TemporaryDirectory() as temporary:
            path = Path(temporary) / "state" / "offset"
            store = OffsetStore(path)
            store.save(1234)

            self.assertEqual(store.load(), 1234)
            self.assertEqual(list(path.parent.iterdir()), [path])
            with self.assertRaises(ValueError):
                store.save(-1)

    def test_failed_replace_cleans_temporary_file(self):
        with tempfile.TemporaryDirectory() as temporary:
            path = Path(temporary) / "offset"
            store = OffsetStore(path)
            with (
                patch(
                    "telegram_bot.polling.os.replace",
                    side_effect=OSError("disk"),
                ),
                self.assertRaises(OSError),
            ):
                store.save(9)
            self.assertEqual(list(Path(temporary).iterdir()), [])


class TelegramUpdatePollerTests(unittest.TestCase):
    def test_authorized_command_is_dispatched_then_checkpointed(self):
        with tempfile.TemporaryDirectory() as temporary:
            telegram = FakeTelegram(
                [
                    {
                        "update_id": 40,
                        "message": {
                            "chat": {"id": 10},
                            "from": {"id": 20},
                            "text": "/status@router_bot",
                        },
                    }
                ]
            )
            router = FakeRouter()
            store = OffsetStore(Path(temporary) / "offset")
            poller = TelegramUpdatePoller(
                settings_for_polling(), telegram, router, TelegramPolicy(), store
            )

            self.assertEqual(poller.poll_once(), 1)
            self.assertEqual(router.calls, [("10", "20", "/status@router_bot")])
            self.assertEqual(poller.offset, 41)
            self.assertEqual(store.load(), 41)

    def test_non_admin_mutation_is_denied_and_checkpointed(self):
        with tempfile.TemporaryDirectory() as temporary:
            telegram = FakeTelegram(
                [
                    {
                        "update_id": 8,
                        "message": {
                            "chat": {"id": 10},
                            "from": {"id": 21},
                            "text": "/reboot",
                        },
                    }
                ]
            )
            router = FakeRouter()
            poller = TelegramUpdatePoller(
                settings_for_polling(),
                telegram,
                router,
                TelegramPolicy(),
                OffsetStore(Path(temporary) / "offset"),
            )

            poller.poll_once()
            self.assertEqual(router.calls, [])
            self.assertIn("ليس لديك صلاحية", telegram.messages[0][1])
            self.assertEqual(poller.offset, 9)

    def test_command_failure_does_not_block_offset_progress(self):
        with tempfile.TemporaryDirectory() as temporary:
            telegram = FakeTelegram(
                [
                    {
                        "update_id": 1,
                        "message": {
                            "chat": {"id": 10},
                            "from": {"id": 20},
                            "text": "/status",
                        },
                    }
                ]
            )
            router = FakeRouter(fail=True)
            poller = TelegramUpdatePoller(
                settings_for_polling(),
                telegram,
                router,
                TelegramPolicy(),
                OffsetStore(Path(temporary) / "offset"),
            )

            poller.poll_once()
            self.assertEqual(poller.offset, 2)
            self.assertIn("تعذر تنفيذ الطلب", telegram.messages[0][1])

    def test_callback_requires_allowed_identity(self):
        with tempfile.TemporaryDirectory() as temporary:
            telegram = FakeTelegram(
                [
                    {
                        "update_id": 2,
                        "callback_query": {
                            "id": "callback-1",
                            "from": {"id": 99},
                            "data": "reboot:nonce:confirm",
                            "message": {"chat": {"id": 10}},
                        },
                    }
                ]
            )
            router = FakeRouter()
            poller = TelegramUpdatePoller(
                settings_for_polling(),
                telegram,
                router,
                TelegramPolicy(),
                OffsetStore(Path(temporary) / "offset"),
            )

            poller.poll_once()
            self.assertEqual(router.callbacks, [])
            self.assertEqual(poller.offset, 3)


class BotRuntimeLifecycleTests(unittest.TestCase):
    def test_close_is_idempotent_and_closes_each_unique_router_client_once(self):
        with tempfile.TemporaryDirectory() as temporary:
            created_gateways = []

            def gateway_factory(*_args):
                gateway = FakeGateway()
                created_gateways.append(gateway)
                return gateway

            settings = SimpleNamespace(
                telegram_token="test-token",
                mikrotik_address="192.0.2.1",
                mikrotik_user="operator",
                mikrotik_password="not-a-real-password",
                mikrotik_port=8729,
                mikrotik_use_ssl=True,
                mikrotik_ca_file=None,
                traffic_interface="",
                traffic_state_file=Path(temporary) / "traffic.json",
                allowed_chat_ids=frozenset({"10"}),
                allowed_user_ids=frozenset({"20"}),
                admin_user_ids=frozenset({"20"}),
                audit_file=Path(temporary) / "audit.jsonl",
                monitor_target="1.1.1.1",
                reboot_recovery_attempts=0,
                reboot_recovery_interval_seconds=5,
                user_manager_customer="admin",
                monitor_interval_seconds=30,
                traffic_interval_seconds=60,
                daily_report_time="23:59",
                offset_file=Path(temporary) / "offset",
                poll_seconds=1,
            )
            runtime = BotRuntime(
                settings,
                telegram_factory=FakeTelegram,
                router_factory=gateway_factory,
            )

            runtime.close()
            runtime.close()

            self.assertEqual(len(created_gateways), 3)
            self.assertEqual(
                [gateway.close_count for gateway in created_gateways], [1, 1, 1]
            )


if __name__ == "__main__":
    unittest.main()
