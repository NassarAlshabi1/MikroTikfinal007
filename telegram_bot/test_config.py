from __future__ import annotations

import os
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

from telegram_bot.common import TelegramBotError
from telegram_bot.config import Settings, load_env_file

BASE_ENV = {
    "TELEGRAM_BOT_TOKEN": "test-token",
    "TELEGRAM_ALLOWED_CHAT_IDS": "10, 11",
    "TELEGRAM_ALLOWED_USER_IDS": "20, 21",
    "TELEGRAM_ADMIN_USER_IDS": "20",
    "MIKROTIK_ADDRESS": "192.0.2.1",
    "MIKROTIK_USER": "operator",
    "MIKROTIK_PASSWORD": "test-password",
}


class SettingsTests(unittest.TestCase):
    def test_defaults_keep_tls_and_parse_allowlists(self):
        with patch.dict(os.environ, BASE_ENV, clear=True):
            settings = Settings.from_env()

        self.assertTrue(settings.mikrotik_use_ssl)
        self.assertEqual(settings.mikrotik_port, 8729)
        self.assertEqual(settings.allowed_chat_ids, frozenset({"10", "11"}))
        self.assertEqual(settings.admin_user_ids, frozenset({"20"}))

    def test_bad_optional_numeric_value_is_reported_as_configuration_error(self):
        with (
            patch.dict(
                os.environ,
                {**BASE_ENV, "REBOOT_RECOVERY_ATTEMPTS": "many"},
                clear=True,
            ),
            self.assertRaisesRegex(TelegramBotError, "REBOOT_RECOVERY_ATTEMPTS"),
        ):
            Settings.from_env()

    def test_router_port_is_rejected_instead_of_silently_clamped(self):
        with (
            patch.dict(
                os.environ,
                {**BASE_ENV, "MIKROTIK_PORT": "0"},
                clear=True,
            ),
            self.assertRaisesRegex(TelegramBotError, "out of range"),
        ):
            Settings.from_env()

    def test_plain_routeros_api_requires_explicit_opt_in(self):
        insecure_env = {**BASE_ENV, "MIKROTIK_USE_SSL": "false"}
        with (
            patch.dict(os.environ, insecure_env, clear=True),
            self.assertRaisesRegex(TelegramBotError, "must use TLS"),
        ):
            Settings.from_env()

        with patch.dict(
            os.environ,
            {**insecure_env, "ALLOW_INSECURE_ROUTEROS_API": "true"},
            clear=True,
        ):
            self.assertFalse(Settings.from_env().mikrotik_use_ssl)

    def test_admins_must_be_in_the_allowed_user_set(self):
        with (
            patch.dict(
                os.environ,
                {**BASE_ENV, "TELEGRAM_ADMIN_USER_IDS": "99"},
                clear=True,
            ),
            self.assertRaisesRegex(TelegramBotError, "subset"),
        ):
            Settings.from_env()

    def test_environment_file_never_overrides_explicit_environment(self):
        with tempfile.TemporaryDirectory() as temporary:
            env_file = Path(temporary) / "bot.env"
            env_file.write_text(
                "TELEGRAM_BOT_TOKEN=file-token\nEXTRA_SETTING=from-file\n",
                encoding="utf-8",
            )
            with patch.dict(
                os.environ, {"TELEGRAM_BOT_TOKEN": "shell-token"}, clear=True
            ):
                load_env_file(env_file)
                self.assertEqual(os.environ["TELEGRAM_BOT_TOKEN"], "shell-token")
                self.assertEqual(os.environ["EXTRA_SETTING"], "from-file")


if __name__ == "__main__":
    unittest.main()
