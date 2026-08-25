from __future__ import annotations

from pathlib import Path
import tempfile
import time
import unittest

from telegram_bot import CommandRouter
from telegram_bot.reporting.export import report_html, report_pdf
from telegram_bot.security.audit import AuditTrail
from telegram_bot.security.policy import TelegramPolicy


class FakeTelegram:
    def __init__(self):
        self.messages = []
        self.documents = []
        self.callback_answers = []

    def send_message(self, chat_id, text, reply_markup=None):
        self.messages.append((chat_id, text, reply_markup))

    def answer_callback_query(self, callback_id):
        self.callback_answers.append(callback_id)

    def send_document(self, chat_id, filename, content):
        self.documents.append((chat_id, filename, content))


class FakeGateway:
    address = "10.0.0.1"

    def __init__(self):
        self.calls = []

    def close(self):
        return None

    def command(self, path, *args):
        self.calls.append((path, args))
        if path == "/tool/user-manager/profile/print":
            return [{"!type": "!re", "name": "basic", "price": "10"}, {"!type": "!done"}]
        if path == "/tool/user-manager/user/print":
            if any("?username=old-card" == arg for arg in args):
                return [{"!type": "!re", "username": "old-card", "end-time": "2000-01-01T00:00:00+00:00"}, {"!type": "!done"}]
            if any("?username=new-card" == arg for arg in args):
                return [{"!type": "!done"}]
            if any("=.proplist=.id" in arg for arg in args):
                return [{"!type": "!re", ".id": "*1", "username": "old-card", "end-time": "2000-01-01T00:00:00+00:00"}, {"!type": "!done"}]
            return [{"!type": "!re", "username": "old-card", "end-time": "2000-01-01T00:00:00+00:00"}, {"!type": "!done"}]
        if path == "/tool/user-manager/session/print":
            return [{"!type": "!re", "user": "old-card", "download": "42"}, {"!type": "!done"}]
        if path == "/system/resource/print":
            return [{"!type": "!re", "version": "6.49.10", "uptime": "1d"}, {"!type": "!done"}]
        if path == "/ip/service/print":
            return [{"!type": "!re", "name": "api-ssl", "port": "8729", "disabled": "no"}, {"!type": "!done"}]
        if path == "/interface/print":
            return [{"!type": "!re", "name": "ether1", "running": "yes"}, {"!type": "!done"}]
        return [{"!type": "!done"}]


class ExtendedTests(unittest.TestCase):
    def make_router(self, gateway=None, audit=None):
        return CommandRouter(
            gateway or FakeGateway(),
            FakeTelegram(),
            policy=TelegramPolicy(),
            audit=audit,
            admin_user_ids=frozenset({"9"}),
            recovery_attempts=0,
        )

    def test_policy_marks_mutations_admin_only(self):
        policy = TelegramPolicy()
        for command in ("/reboot", "/card-create", "/delete-expired"):
            rule = policy.rule_for(command)
            self.assertTrue(rule and rule.mutating and rule.admin_only and rule.confirmation)

    def test_create_card_requires_bound_confirmation(self):
        gateway = FakeGateway()
        telegram = FakeTelegram()
        router = CommandRouter(gateway, telegram, policy=TelegramPolicy(), admin_user_ids=frozenset({"9"}))
        router.handle("1", "9", "/card-create new-card basic")
        data = telegram.messages[-1][2]["inline_keyboard"][0][0]["callback_data"]
        router.handle_callback("1", "8", "wrong", data)
        self.assertFalse(any(path.endswith("/add") for path, _ in gateway.calls))
        router.handle_callback("1", "9", "right", data)
        self.assertTrue(any(path.endswith("/add") for path, _ in gateway.calls))
        self.assertTrue(any(path.endswith("create-and-activate-profile") for path, _ in gateway.calls))
        self.assertNotIn("password", " ".join(str(message) for message in telegram.messages[:-1]).lower())

    def test_delete_expired_is_preview_then_confirmation(self):
        gateway = FakeGateway()
        telegram = FakeTelegram()
        router = CommandRouter(gateway, telegram, policy=TelegramPolicy(), admin_user_ids=frozenset({"9"}))
        router.handle("1", "9", "/delete-expired")
        data = telegram.messages[-1][2]["inline_keyboard"][0][0]["callback_data"]
        self.assertFalse(any(path.endswith("/remove") for path, _ in gateway.calls))
        router.handle_callback("1", "9", "confirm", data)
        self.assertTrue(any(path.endswith("/remove") for path, _ in gateway.calls))

    def test_report_exports_are_nonempty_and_escaped(self):
        sections = [("x", [{"message": "<secret>"}])]
        html = report_html("Report", sections)
        self.assertIn("&lt;secret&gt;", html)
        self.assertNotIn("<secret>", html)
        self.assertTrue(report_pdf("Report", sections).startswith(b"%PDF"))


if __name__ == "__main__":
    unittest.main()
